# tools.pl - This module provides various tools for Sympa
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package tools;

use strict;

use Digest::MD5;
use Encode::Guess; ## Usefull when encoding should be guessed
use Encode::MIME::Header;
use File::Copy::Recursive;
use File::Find;
use HTML::StripScripts::Parser;
use Mail::Header;
use MIME::Lite::HTML;
use POSIX qw(strftime mkfifo strtod);
use Proc::ProcessTable;
use Sys::Hostname;
use Text::LineFold;
use Time::Local;

use Language;
use Log;
use Sympa::Constants;

## RCS identification.
#my $id = '@(#)$Id$';

## global var to store a CipherSaber object 
my $cipher;

my $separator="------- CUT --- CUT --- CUT --- CUT --- CUT --- CUT --- CUT -------";

## Regexps for list params
## Caution : if this regexp changes (more/less parenthesis), then regexp using it should 
## also be changed
my $time_regexp = '[012]?[0-9](?:\:[0-5][0-9])?';
my $time_range_regexp = $time_regexp.'-'.$time_regexp;
my %regexp = ('email' => '([\w\-\_\.\/\+\=\'\&]+|\".*\")\@[\w\-]+(\.[\w\-]+)+',
	      'family_name' => '[a-z0-9][a-z0-9\-\.\+_]*', 
	      'template_name' => '[a-zA-Z0-9][a-zA-Z0-9\-\.\+_\s]*', ## Allow \s
	      'host' => '[\w\.\-]+',
	      'multiple_host_with_port' => '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*',
	      'listname' => '[a-z0-9][a-z0-9\-\.\+_]{0,49}',
	      'sql_query' => '(SELECT|select).*',
	      'scenario' => '[\w,\.\-]+',
	      'task' => '\w+',
	      'datasource' => '[\w-]+',
	      'uid' => '[\w\-\.\+]+',
	      'time' => $time_regexp,
	      'time_range' => $time_range_regexp,
	      'time_ranges' => $time_range_regexp.'(?:\s+'.$time_range_regexp.')*',
	      're' => '(?i)(?:AW|(?:\xD0\x9D|\xD0\xBD)(?:\xD0\x90|\xD0\xB0)|Re(?:\^\d+|\*\d+|\*\*\d+|\[\d+\])?|Rif|SV|VS)\s*:',
	      );

## Sets owner and/or access rights on a file.
sub set_file_rights {
    my %param = @_;
    my ($uid, $gid);

    if ($param{'user'}){
	unless ($uid = (getpwnam($param{'user'}))[2]) {
	    &Log::do_log('err', "User %s can't be found in passwd file",$param{'user'});
	    return undef;
	}
    }else {
	$uid = -1;# "A value of -1 is interpreted by most systems to leave that value unchanged".
    }
    if ($param{'group'}) {
	unless ($gid = (getgrnam($param{'group'}))[2]) {
	    &Log::do_log('err', "Group %s can't be found",$param{'group'});
	    return undef;
	}
    }else {
	$gid = -1;# "A value of -1 is interpreted by most systems to leave that value unchanged".
    }
    unless (chown($uid,$gid, $param{'file'})){
	&Log::do_log('err', "Can't give ownership of file %s to %s.%s: %s",$param{'file'},$param{'user'},$param{'group'}, $!);
	return undef;
    }
    if ($param{'mode'}){
	unless (chmod($param{'mode'}, $param{'file'})){
	    &Log::do_log('err', "Can't change rights of file %s: %s",$param{'file'}, $!);
	    return undef;
	}
    }
    return 1;
}

## Returns an HTML::StripScripts::Parser object built with  the parameters provided as arguments.
sub _create_xss_parser {
    my %parameters = @_;
    &Log::do_log('debug3','tools::_create_xss_parser(%s)',$parameters{'robot'});
    my $hss = HTML::StripScripts::Parser->new({ Context => 'Document',
						AllowSrc        => 1,
						Rules => {
						    '*' => {
							src => '^http://'. $parameters{'host'},
						    },
						},
					    });
    return $hss;
}

#*******************************************
# Function : pictures_filename
# Description : return the type of a pictures
#               according to the user
## IN : email, list, path
#*******************************************
sub pictures_filename {
    my %parameters = @_;
    
    my $login = &md5_fingerprint($parameters{'email'});
    my ($listname, $robot) = ($parameters{'list'}{'name'}, $parameters{'list'}{'domain'});
    
    my $filetype;
    my $filename = undef;
    foreach my $ext ('.gif','.jpg','.jpeg','.png') {
 	if (-f $parameters{'path'}.'/'.$listname.'@'.$robot.'/'.$login.$ext) {
 	    my $file = $login.$ext;
 	    $filename = $file;
 	    last;
 	}
    }
    return $filename;
}

## Creation of pictures url
## IN : url, email, list, path
sub make_pictures_url {
    my %parameters = @_;

    my ($listname, $robot) = ($parameters{'list'}{'name'}, $parameters{'list'}{'domain'});

    my $filename = pictures_filename(%parameters);
    return $filename ?
 	$parameters{'url'}.$listname.'@'.$robot.'/'.$filename : undef;
}

## Returns sanitized version (using StripScripts) of the string provided as argument.
sub sanitize_html {
    my %parameters = @_;
    &Log::do_log('debug3','tools::sanitize_html(%s,%s,%s)',$parameters{'string'},$parameters{'robot'},$parameters{'host'});

    unless (defined $parameters{'string'}) {
	&Log::do_log('err',"No string provided.");
	return undef;
    }

    my $hss = &_create_xss_parser('robot' => $parameters{'robot'}, 'host' => $parameters{'host'});
    unless (defined $hss) {
	&Log::do_log('err',"Can't create StripScript parser.");
	return undef;
    }
    my $string = $hss -> filter_html($parameters{'string'});
    return $string;
}

## Returns sanitized version (using StripScripts) of the content of the file whose path is provided as argument.
sub sanitize_html_file {
    my %parameters = @_;
    &Log::do_log('debug3','tools::sanitize_html_file(%s,%s)',$parameters{'robot'},$parameters{'host'});

    unless (defined $parameters{'file'}) {
	&Log::do_log('err',"No path to file provided.");
	return undef;
    }

    my $hss = &_create_xss_parser('robot' => $parameters{'robot'}, 'host' => $parameters{'host'});
    unless (defined $hss) {
	&Log::do_log('err',"Can't create StripScript parser.");
	return undef;
    }
    $hss -> parse_file($parameters{'file'});
    return $hss -> filtered_document;
}

## Sanitize all values in the hash $var, starting from $level
sub sanitize_var {
    my %parameters = @_;
    &Log::do_log('debug3','tools::sanitize_var(%s,%s,%s)',$parameters{'var'},$parameters{'level'},$parameters{'robot'});
    unless (defined $parameters{'var'}){
	&Log::do_log('err','Missing var to sanitize.');
	return undef;
    }
    unless (defined $parameters{'htmlAllowedParam'} && $parameters{'htmlToFilter'}){
	&Log::do_log('err','Missing var *** %s *** %s *** to ignore.',$parameters{'htmlAllowedParam'},$parameters{'htmlToFilter'});
	return undef;
    }
    my $level = $parameters{'level'};
    $level |= 0;
    
    if(ref($parameters{'var'})) {
	if(ref($parameters{'var'}) eq 'ARRAY') {
	    foreach my $index (0..$#{$parameters{'var'}}) {
		if ((ref($parameters{'var'}->[$index]) eq 'ARRAY') || (ref($parameters{'var'}->[$index]) eq 'HASH')) {
		    &sanitize_var('var' => $parameters{'var'}->[$index],
				  'level' => $level+1,
				  'robot' => $parameters{'robot'},
				  'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
				  'htmlToFilter' => $parameters{'htmlToFilter'},
				  );
		}
		else {
		    if (defined $parameters{'var'}->[$index]) {
			$parameters{'var'}->[$index] = &escape_html($parameters{'var'}->[$index]);
		    }
		}
	    }
	}
	elsif(ref($parameters{'var'}) eq 'HASH') {
	    foreach my $key (keys %{$parameters{'var'}}) {
		if ((ref($parameters{'var'}->{$key}) eq 'ARRAY') || (ref($parameters{'var'}->{$key}) eq 'HASH')) {
		    &sanitize_var('var' => $parameters{'var'}->{$key},
				  'level' => $level+1,
				  'robot' => $parameters{'robot'},
				  'htmlAllowedParam' => $parameters{'htmlAllowedParam'},
				  'htmlToFilter' => $parameters{'htmlToFilter'},
				  );
		}
		else {
		    if (defined $parameters{'var'}->{$key}) {
			unless ($parameters{'htmlAllowedParam'}{$key}||$parameters{'htmlToFilter'}{$key}) {
			    $parameters{'var'}->{$key} = &escape_html($parameters{'var'}->{$key});
			}
			if ($parameters{'htmlToFilter'}{$key}) {
			    $parameters{'var'}->{$key} = &sanitize_html('string' => $parameters{'var'}->{$key},
									'robot' =>$parameters{'robot'} );
			}
		    }
		}
		
	    }
	}
    }
    else {
	&Log::do_log('err','Variable is neither a hash nor an array.');
	return undef;
    }
    return 1;
}

## Sorts the list of adresses by domain name
## Input : users hash
## Sort by domain.
sub sortbydomain {
   my($x, $y) = @_;
   $x = join('.', reverse(split(/[@\.]/, $x)));
   $y = join('.', reverse(split(/[@\.]/, $y)));
   #print "$x $y\n";
   $x cmp $y;
}

## Sort subroutine to order files in sympa spool by date
sub by_date {
    my @a_tokens = split /\./, $a;
    my @b_tokens = split /\./, $b;

    ## File format : list@dom.date.pid
    my $a_time = $a_tokens[$#a_tokens -1];
    my $b_time = $b_tokens[$#b_tokens -1];

    return $a_time <=> $b_time;

}

## Safefork does several tries before it gives up.
## Do 3 trials and wait 10 seconds * $i between each.
## Exit with a fatal error is fork failed after all
## tests have been exhausted.
sub safefork {
   my($i, $pid);
   
   for ($i = 1; $i < 4; $i++) {
      my($pid) = fork;
      return $pid if (defined($pid));
      &Log::do_log ('warning', "Can't create new process in safefork: %m");
      ## should send a mail to the listmaster
      sleep(10 * $i);
   }
   &Log::fatal_err("Can't create new process in safefork: %m");
   ## No return.
}

####################################################
# checkcommand                              
####################################################
# Checks for no command in the body of the message.
# If there are some command in it, it return true 
# and send a message to $sender
# 
# IN : -$msg (+): ref(MIME::Entity) - message to check
#      -$sender (+): the sender of $msg
#      -$robot (+) : robot
#
# OUT : -1 if there are some command in $msg
#       -0 else
#
###################################################### 
sub checkcommand {
   my($msg, $sender, $robot, $regexp) = @_;

   my($avoid, $i);

   my $hdr = $msg->head;

   ## Check for commands in the subject.
   my $subject = $msg->head->get('Subject');

   &Log::do_log('debug3', 'tools::checkcommand(msg->head->get(subject): %s,%s)', $subject, $sender);

   if ($subject) {
       if ($regexp && ($subject =~ /^$regexp\b/im)) {
	   return 1;
       }
   }

   return 0 if ($#{$msg->body} >= 5);  ## More than 5 lines in the text.

   foreach $i (@{$msg->body}) {
       if ($regexp && ($i =~ /^$regexp\b/im)) {
	   return 1;
       }

       ## Control is only applied to first non-blank line
       last unless $i =~ /^\s*$/;
   }
   return 0;
}



## return a hash from the edit_list_conf file
sub load_edit_list_conf {
    my $robot = shift;
    my $list = shift;
    my $basedir = shift;
    &Log::do_log('debug2', 'tools::load_edit_list_conf (%s, %s, %s)',$robot, $list, $basedir);

    my $file;
    my $conf ;
    
    return undef 
	unless ($file = &tools::get_filename('etc',{},'edit_list.conf',$robot,$list,$basedir));

    unless (open (FILE, $file)) {
	&Log::do_log('info','Unable to open config file %s', $file);
	return undef;
    }

    my $error_in_conf;
    my $roles_regexp = 'listmaster|privileged_owner|owner|editor|subscriber|default';
    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*(\S+)\s+(($roles_regexp)\s*(,\s*($roles_regexp))*)\s+(read|write|hidden)\s*$/i) {
	    my ($param, $role, $priv) = ($1, $2, $6);
	    my @roles = split /,/, $role;
	    foreach my $r (@roles) {
		$r =~ s/^\s*(\S+)\s*$/$1/;
		if ($r eq 'default') {
		    $error_in_conf = 1;
		    &Log::do_log('notice', '"default" is no more recognised');
		    foreach my $set ('owner','privileged_owner','listmaster') {
			$conf->{$param}{$set} = $priv;
		    }
		    next;
		}
		$conf->{$param}{$r} = $priv;
	    }
	}else{
	    &Log::do_log ('info', 'unknown parameter in %s  (Ignored) %s', "$basedir/edit_list.conf",$_ );
	    next;
	}
    }

    if ($error_in_conf) {
	unless (&List::send_notify_to_listmaster('edit_list_error', $robot, [$file])) {
	    &Log::do_log('notice',"Unable to send notify 'edit_list_error' to listmaster");
	}
    }
    
    close FILE;
    return $conf;
}


## return a hash from the edit_list_conf file
sub load_create_list_conf {
    my $robot = shift;
    my $basedir = shift;

    my $file;
    my $conf ;
    
    $file = &tools::get_filename('etc',{}, 'create_list.conf', $robot,undef,$basedir);
    unless ($file) {
	&Log::do_log('info', 'unable to read %s', Sympa::Constants::DEFAULTDIR . '/create_list.conf');
	return undef;
    }

    unless (open (FILE, $file)) {
	&Log::do_log('info','Unable to open config file %s', $file);
	return undef;
    }

    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*(\S+)\s+(read|hidden)\s*$/i) {
	    $conf->{$1} = lc($2);
	}else{
	    &Log::do_log ('info', 'unknown parameter in %s  (Ignored) %s', $file,$_ );
	    next;
	}
    }
    
    close FILE;
    return $conf;
}

sub _add_topic {
    my ($name, $title) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
	return {'title' => $title};
    }else {
	$topic->{'sub'}{$name} = &_add_topic(join ('/', @tree[1..$#tree]), $title);
	return $topic;
    }
}

sub get_list_list_tpl {
    my $robot = shift;
    my $directory = shift;

    my $list_conf;
    my $list_templates ;
    unless ($list_conf = &load_create_list_conf($robot)) {
	return undef;
    }
    
    foreach my $dir (
        Sympa::Constants::DEFAULTDIR . '/create_list_templates',
        "$directory/create_list_templates",
        "$directory/$robot/create_list_templates"
    ) {
	if (opendir(DIR, $dir)) {
	    foreach my $template ( sort grep (!/^\./,readdir(DIR))) {

		my $status = $list_conf->{$template} || $list_conf->{'default'};

		next if ($status eq 'hidden') ;

		$list_templates->{$template}{'path'} = $dir;

		my $locale = &Language::Lang2Locale( &Language::GetLang());
		## Look for a comment.tt2 in the appropriate locale first
		if (-r $dir.'/'.$template.'/'.$locale.'/comment.tt2') {
		    $list_templates->{$template}{'comment'} = $dir.'/'.$template.'/'.$locale.'/comment.tt2';
		}elsif (-r $dir.'/'.$template.'/comment.tt2') {
		    $list_templates->{$template}{'comment'} = $dir.'/'.$template.'/comment.tt2';
		}
	    }
	    closedir(DIR);
	}
    }

    return ($list_templates);
}


#copy a directory and its content
sub copy_dir {
    my $dir1 = shift;
    my $dir2 = shift;
    &Log::do_log('debug','Copy directory %s to %s',$dir1,$dir2);

    unless (-d $dir1){
	&Log::do_log('err',"Directory source '%s' doesn't exist. Copy impossible",$dir1);
	return undef;
    }
    return (&File::Copy::Recursive::dircopy($dir1,$dir2)) ;
}

#delete a directory and its content
sub del_dir {
    my $dir = shift;
    &Log::do_log('debug','del_dir %s',$dir);
    
    if(opendir DIR, $dir){
	for (readdir DIR) {
	    next if /^\.{1,2}$/;
	    my $path = "$dir/$_";
	    unlink $path if -f $path;
	    del_dir($path) if -d $path;
	}
	closedir DIR;
	unless(rmdir $dir) {&Log::do_log('err','Unable to delete directory %s: $!',$dir);}
    }else{
	&Log::do_log('err','Unable to open directory %s to delete the files it contains: $!',$dir);
    }
}

#to be used before creating a file in a directory that may not exist already. 
sub mk_parent_dir {
    my $file = shift;
    $file =~ /^(.*)\/([^\/])*$/ ;
    my $dir = $1;

    return 1 if (-d $dir);
    &mkdir_all($dir, 0755);
}

## Recursively create directory and all parent directories
sub mkdir_all {
    my ($path, $mode) = @_;
    my $status = 1;

    ## Change umask to fully apply modes of mkdir()
    my $saved_mask = umask;
    umask 0000;

    return undef if ($path eq '');
    return 1 if (-d $path);

    ## Compute parent path
    my @token = split /\//, $path;
    pop @token;
    my $parent_path = join '/', @token;

    unless (-d $parent_path) {
	unless (&mkdir_all($parent_path, $mode)) {
	    $status = undef;
	}
    }

    if (defined $status) { ## Don't try if parent dir could not be created
	unless (mkdir ($path, $mode)) {
	    $status = undef;
	}
    }

    ## Restore umask
    umask $saved_mask;

    return $status;
}

# shift file renaming it with date. If count is defined, keep $count file and unlink others
sub shift_file {
    my $file = shift;
    my $count = shift;
    &Log::do_log('debug', "shift_file ($file,$count)");

    unless (-f $file) {
	&Log::do_log('info', "shift_file : unknown file $file");
	return undef;
    }
    
    my @date = localtime (time);
    my $file_extention = strftime("%Y:%m:%d:%H:%M:%S", @date);
    
    unless (rename ($file,$file.'.'.$file_extention)) {
	&Log::do_log('err', "shift_file : Cannot rename file $file to $file.$file_extention" );
	return undef;
    }
    if ($count) {
	$file =~ /^(.*)\/([^\/])*$/ ;
	my $dir = $1;

	unless (opendir(DIR, $dir)) {
	    &Log::do_log('err', "shift_file : Cannot read dir $dir" );
	    return ($file.'.'.$file_extention);
	}
	my $i = 0 ;
	foreach my $oldfile (reverse (sort (grep (/^$file\./,readdir(DIR))))) {
	    $i ++;
	    if ($count lt $i) {
		if (unlink ($oldfile)) { 
		    &Log::do_log('info', "shift_file : unlink $oldfile");
		}else{
		    &Log::do_log('info', "shift_file : unable to unlink $oldfile");
		}
	    }
	}
    }
    return ($file.'.'.$file_extention);
}

sub get_templates_list {

    my $type = shift;
    my $robot = shift;
    my $list = shift;
    my $options = shift;
    my $basedir = shift;

    my $listdir;

    &Log::do_log('debug', "get_templates_list ($type, $robot, $list)");
    unless (($type eq 'web')||($type eq 'mail')) {
	&Log::do_log('info', 'get_templates_list () : internal error incorrect parameter');
    }

    my $distrib_dir = Sympa::Constants::DEFAULTDIR . '/'.$type.'_tt2';
    my $site_dir = $basedir.'/'.$type.'_tt2';
    my $robot_dir = $basedir.'/'.$robot.'/'.$type.'_tt2';

    my @try;

    ## The 'ignore_global' option allows to look for files at list level only
    unless ($options->{'ignore_global'}) {
	push @try, $distrib_dir ;
	push @try, $site_dir ;
	push @try, $robot_dir;
    }    

    if (defined $list) {
	$listdir = $list->{'dir'}.'/'.$type.'_tt2';	
	push @try, $listdir ;
    }

    my $i = 0 ;
    my $tpl;

    foreach my $dir (@try) {
	next unless opendir (DIR, $dir);
	foreach my $file ( grep (!/^\./,readdir(DIR))) {	    
	    ## Subdirectory for a lang
	    if (-d $dir.'/'.$file) {
		my $lang = $file;
		next unless opendir (LANGDIR, $dir.'/'.$lang);
		foreach my $file (grep (!/^\./,readdir(LANGDIR))) {
		    next unless ($file =~ /\.tt2$/);
		    if ($dir eq $distrib_dir){$tpl->{$file}{'distrib'}{$lang} = $dir.'/'.$lang.'/'.$file;}
		    if ($dir eq $site_dir)   {$tpl->{$file}{'site'}{$lang} =  $dir.'/'.$lang.'/'.$file;}
		    if ($dir eq $robot_dir)  {$tpl->{$file}{'robot'}{$lang} = $dir.'/'.$lang.'/'.$file;}
		    if ($dir eq $listdir)    {$tpl->{$file}{'list'}{$lang} = $dir.'/'.$lang.'/'.$file;}
		}
		closedir LANGDIR;

	    }else {
		next unless ($file =~ /\.tt2$/);
		if ($dir eq $distrib_dir){$tpl->{$file}{'distrib'}{'default'} = $dir.'/'.$file;}
		if ($dir eq $site_dir)   {$tpl->{$file}{'site'}{'default'} =  $dir.'/'.$file;}
		if ($dir eq $robot_dir)  {$tpl->{$file}{'robot'}{'default'} = $dir.'/'.$file;}
		if ($dir eq $listdir)    {$tpl->{$file}{'list'}{'default'}= $dir.'/'.$file;}
	    }
	}
	closedir DIR;
    }
    return ($tpl);

}


# return the path for a specific template
sub get_template_path {

    my $type = shift;
    my $robot = shift;
    my $scope = shift;
    my $tpl = shift;
    my $lang = shift || 'default';
    my $list = shift;
    my $basedir = shift;

    &Log::do_log('debug', "get_templates_path ($type,$robot,$scope,$tpl,$lang,%s)", $list->{'name'});

    my $listdir;
    if (defined $list) {
	$listdir = $list->{'dir'};
    }

    unless (($type == 'web')||($type == 'mail')) {
	&Log::do_log('info', 'get_templates_path () : internal error incorrect parameter');
    }

    my $distrib_dir = Sympa::Constants::DEFAULTDIR . '/'.$type.'_tt2';
    my $site_dir = $basedir.'/'.$type.'_tt2';
    $site_dir .= '/'.$lang unless ($lang eq 'default');
    my $robot_dir = $basedir.'/'.$robot.'/'.$type.'_tt2';
    $robot_dir .= '/'.$lang unless ($lang eq 'default');    

    if ($scope eq 'list')  {
	my $dir = $listdir.'/'.$type.'_tt2';
	$dir .= '/'.$lang unless ($lang eq 'default');
	return $dir.'/'.$tpl ;

    }elsif ($scope eq 'robot')  {
	return $robot_dir.'/'.$tpl;

    }elsif ($scope eq 'site') {
	return $site_dir.'/'.$tpl;

    }elsif ($scope eq 'distrib') {
	return $distrib_dir.'/'.$tpl;

    }

    return undef;
}


## Make a multipart/alternative, a singlepart
sub as_singlepart {
    &Log::do_log('debug2', 'tools::as_singlepart()');
    my ($msg, $preferred_type, $loops) = @_;
    my $done = 0;
    $loops++;
    
    unless (defined $msg) {
	&Log::do_log('err', "Undefined message parameter");
	return undef;
    }

    if ($loops > 4) {
	&Log::do_log('err', 'Could not change multipart to singlepart');
	return undef;
    }

    if ($msg->effective_type() =~ /^$preferred_type$/) {
	$done = 1;
    }elsif ($msg->effective_type() =~ /^multipart\/alternative/) {
	foreach my $part ($msg->parts) {
	    if (($part->effective_type() =~ /^$preferred_type$/) ||
		(
		 ($part->effective_type() =~ /^multipart\/related$/) &&
		 $part->parts &&
		 ($part->parts(0)->effective_type() =~ /^$preferred_type$/))) {
		## Only keep the first matching part
		$msg->parts([$part]);
		$msg->make_singlepart();
		$done = 1;
		last;
	    }
	}
    }elsif ($msg->effective_type() =~ /multipart\/signed/) {
	my @parts = $msg->parts();
	## Only keep the first part
	$msg->parts([$parts[0]]);
	$msg->make_singlepart();       

	$done ||= &as_singlepart($msg, $preferred_type, $loops);

    }elsif ($msg->effective_type() =~ /^multipart/) {
	foreach my $part ($msg->parts) {
            
            next unless (defined $part); ## Skip empty parts
 
	    if ($part->effective_type() =~ /^multipart\/alternative/) {
		if (&as_singlepart($part, $preferred_type, $loops)) {
		    $msg->parts([$part]);
		    $msg->make_singlepart();
		    $done = 1;
		}
	    }
	}    
    }

    return $done;
}

## Escape characters before using a string within a regexp parameter
## Escaped characters are : @ $ [ ] ( ) ' ! '\' * . + ?
sub escape_regexp {
    my $s = shift;
    my @escaped = ("\\",'@','$','[',']','(',')',"'",'!','*','.','+','?');
    my $backslash = "\\"; ## required in regexp

    foreach my $escaped_char (@escaped) {
	$s =~ s/$backslash$escaped_char/\\$escaped_char/g;
    }

    return $s;
}

## Escape weird characters
sub escape_chars {
    my $s = shift;    
    my $except = shift; ## Exceptions
    my $ord_except = ord($except) if (defined $except);

    ## Escape chars
    ##  !"#$%&'()+,:;<=>?[] AND accented chars
    ## escape % first
    foreach my $i (0x25,0x20..0x24,0x26..0x2c,0x3a..0x3f,0x5b,0x5d,0x80..0x9f,0xa0..0xff) {
	next if ($i == $ord_except);
	my $hex_i = sprintf "%lx", $i;
	$s =~ s/\x$hex_i/%$hex_i/g;
    }
    $s =~ s/\//%a5/g unless ($except eq '/');  ## Special traetment for '/'

    return $s;
}

## Escape shared document file name
## Q-decode it first
sub escape_docname {
    my $filename = shift;
    my $except = shift; ## Exceptions

    ## Q-decode
    $filename = MIME::EncWords::decode_mimewords($filename);

    ## Decode from FS encoding to utf-8
    #$filename = &Encode::decode($Conf::Conf{'filesystem_encoding'}, $filename);

    ## escapesome chars for use in URL
    return &escape_chars($filename, $except);
}

## Convert from Perl unicode encoding to UTF8
sub unicode_to_utf8 {
    my $s = shift;
    
    if (&Encode::is_utf8($s)) {
	return &Encode::encode_utf8($s);
    }

    return $s;
}

## This applies recursively to a data structure
## The transformation subroutine is passed as a ref
sub recursive_transformation {
    my ($var, $subref) = @_;
    
    return unless (ref($var));

    if (ref($var) eq 'ARRAY') {
	foreach my $index (0..$#{$var}) {
	    if (ref($var->[$index])) {
		&recursive_transformation($var->[$index], $subref);
	    }else {
		$var->[$index] = &{$subref}($var->[$index]);
	    }
	}
    }elsif (ref($var) eq 'HASH') {
	foreach my $key (sort keys %{$var}) {
	    if (ref($var->{$key})) {
		&recursive_transformation($var->{$key}, $subref);
	    }else {
		$var->{$key} = &{$subref}($var->{$key});
	    }
	}    
    }
    
    return;
}

## Q-Encode web file name
sub qencode_filename {
    my $filename = shift;

    ## We don't use MIME::Words here because it does not encode properly Unicode
    ## Check if string is already Q-encoded first
    ## Also check if the string contains 8bit chars
    unless ($filename =~ /\=\?UTF-8\?/ ||
	    $filename =~ /^[\x00-\x7f]*$/) {

	## Don't encode elements such as .desc. or .url or .moderate or .extension
	my $part = $filename;
	my ($leading, $trailing);
	$leading = $1 if ($part =~ s/^(\.desc\.)//); ## leading .desc
	$trailing = $1 if ($part =~ s/((\.\w+)+)$//); ## trailing .xx

	my $encoded_part = MIME::EncWords::encode_mimewords($part, Charset => 'utf8', Encoding => 'q', MaxLineLen => 1000, Minimal => 'NO');
	

	$filename = $leading.$encoded_part.$trailing;
    }
    
    return $filename;
}

## Q-Decode web file name
sub qdecode_filename {
    my $filename = shift;
    
    ## We don't use MIME::Words here because it does not encode properly Unicode
    ## Check if string is already Q-encoded first
    #if ($filename =~ /\=\?UTF-8\?/) {
    $filename = Encode::encode_utf8(&Encode::decode('MIME-Q', $filename));
    #}
    
    return $filename;
}

## Unescape weird characters
sub unescape_chars {
    my $s = shift;

    $s =~ s/%a5/\//g;  ## Special traetment for '/'
    foreach my $i (0x20..0x2c,0x3a..0x3f,0x5b,0x5d,0x80..0x9f,0xa0..0xff) {
	my $hex_i = sprintf "%lx", $i;
	my $hex_s = sprintf "%c", $i;
	$s =~ s/%$hex_i/$hex_s/g;
    }

    return $s;
}

sub escape_html {
    my $s = shift;

    $s =~ s/\"/\&quot\;/gm;
    $s =~ s/\</&lt\;/gm;
    $s =~ s/\>/&gt\;/gm;
    
    return $s;
}

sub unescape_html {
    my $s = shift;

    $s =~ s/\&quot\;/\"/g;
    $s =~ s/&lt\;/\</g;
    $s =~ s/&gt\;/\>/g;
    
    return $s;
}

sub tmp_passwd {
    my $email = shift;
    my $cookie = shift;

    return ('init'.substr(Digest::MD5::md5_hex(join('/', $cookie, $email)), -8)) ;
}

# Check sum used to authenticate communication from wwsympa to sympa
sub sympa_checksum {
    my $rcpt = shift;
    my $cookie = shift;
    return (substr(Digest::MD5::md5_hex(join('/', $cookie, $rcpt)), -10)) ;
}

# create a cipher
sub ciphersaber_installed {
    my $cookie = shift;

    my $is_installed;
    foreach my $dir (@INC) {
	if (-f "$dir/Crypt/CipherSaber.pm") {
	    $is_installed = 1;
	    last;
	}
    }

    if ($is_installed) {
	require Crypt::CipherSaber;
	$cipher = Crypt::CipherSaber->new($cookie);
    }else{
	$cipher = 'no_cipher';
    }
}

# create a cipher
sub cookie_changed {
    my $current=shift;
    my $basedir = shift;

    my $changed = 1 ;
    if (-f "$basedir/cookies.history") {
	unless (open COOK, "$basedir/cookies.history") {
	    &Log::do_log('err', "Unable to read $basedir/cookies.history") ;
	    return undef ; 
	}
	my $oldcook = <COOK>;
	close COOK;

	my @cookies = split(/\s+/,$oldcook );
	

	if ($cookies[$#cookies] eq $current) {
	    &Log::do_log('debug2', "cookie is stable") ;
	    $changed = 0;
#	}else{
#	    push @cookies, $current ;
#	    unless (open COOK, ">$basedir/cookies.history") {
#		&Log::do_log('err', "Unable to create $basedir/cookies.history") ;
#		return undef ; 
#	    }
#	    printf COOK "%s",join(" ",@cookies) ;
#	    
#	    close COOK;
	}
	return $changed ;
    }else{
	my $umask = umask 037;
	unless (open COOK, ">$basedir/cookies.history") {
	    umask $umask;
	    &Log::do_log('err', "Unable to create $basedir/cookies.history") ;
	    return undef ; 
	}
	umask $umask;
	chown [getpwnam(Sympa::Constants::USER)]->[2], [getgrnam(Sympa::Constants::GROUP)]->[2], "$basedir/cookies.history";
	print COOK "$current ";
	close COOK;
	return(0);
    }
}

## encrypt a password
sub crypt_password {
    my $inpasswd = shift ;
    my $cookie = shift;

    unless (defined($cipher)){
	$cipher = ciphersaber_installed($cookie);
    }
    return $inpasswd if ($cipher eq 'no_cipher') ;
    return ("crypt.".&MIME::Base64::encode($cipher->encrypt ($inpasswd))) ;
}

## decrypt a password
sub decrypt_password {
    my $inpasswd = shift ;
    my $cookie = shift;
    Log::do_log('debug2', 'tools::decrypt_password (%s,%s)', $inpasswd, $cookie);

    return $inpasswd unless ($inpasswd =~ /^crypt\.(.*)$/) ;
    $inpasswd = $1;

    unless (defined($cipher)){
	$cipher = ciphersaber_installed($cookie);
    }
    if ($cipher eq 'no_cipher') {
	&Log::do_log('info','password seems crypted while CipherSaber is not installed !');
	return $inpasswd ;
    }
    return ($cipher->decrypt(&MIME::Base64::decode($inpasswd)));
}

sub load_mime_types {
    my $types = {};

    my @localisation = ('/etc/mime.types',
			'/usr/local/apache/conf/mime.types',
			'/etc/httpd/conf/mime.types','mime.types');

    foreach my $loc (@localisation) {
        next unless (-r $loc);

        unless(open (CONF, $loc)) {
            print STDERR "load_mime_types: unable to open $loc\n";
            return undef;
        }
    }
    
    while (<CONF>) {
        next if /^\s*\#/;
        
        if (/^(\S+)\s+(.+)\s*$/i) {
            my ($k, $v) = ($1, $2);
            
            my @extensions = split / /, $v;
        
            ## provides file extention, given the content-type
            if ($#extensions >= 0) {
                $types->{$k} = $extensions[0];
            }
    
            foreach my $ext (@extensions) {
                $types->{$ext} = $k;
            }
            next;
        }
    }
    
    close FILE;
    return $types;
}

sub split_mail {
    my $message = shift ; 
    my $pathname = shift ;
    my $dir = shift ;

    my $head = $message->head ;
    my $body = $message->body ;
    my $encoding = $head->mime_encoding ;

    if ($message->is_multipart
	|| ($message->mime_type eq 'message/rfc822')) {

        for (my $i=0 ; $i < $message->parts ; $i++) {
            &split_mail ($message->parts ($i), $pathname.'.'.$i, $dir) ;
        }
    }
    else { 
	    my $fileExt ;

	    if ($head->mime_attr("content_type.name") =~ /\.(\w+)\s*\"*$/) {
		$fileExt = $1 ;
	    }
	    elsif ($head->recommended_filename =~ /\.(\w+)\s*\"*$/) {
		$fileExt = $1 ;
	    }
	    else {
		my $mime_types = &load_mime_types();

		$fileExt=$mime_types->{$head->mime_type};
		my $var=$head->mime_type;
	    }
	
	    

	    ## Store body in file 
	    unless (open OFILE, ">$dir/$pathname.$fileExt") {
		&Log::do_log('err', "Unable to create $dir/$pathname.$fileExt : $!") ;
		return undef ; 
	    }
	    
	    if ($encoding =~ /^(binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64)$/ ) {
		open TMP, ">$dir/$pathname.$fileExt.$encoding";
		$message->print_body (\*TMP);
		close TMP;

		open BODY, "$dir/$pathname.$fileExt.$encoding";

		my $decoder = new MIME::Decoder $encoding;
		unless (defined $decoder) {
		    &Log::do_log('err', 'Cannot create decoder for %s', $encoding);
		    return undef;
		}
		$decoder->decode(\*BODY, \*OFILE);
		close BODY;
		unlink "$dir/$pathname.$fileExt.$encoding";
	    }else {
		$message->print_body (\*OFILE) ;
	    }
	    close (OFILE);
	    printf "\t-------\t Create file %s\n", $pathname.'.'.$fileExt ;
	    
	    ## Delete files created twice or more (with Content-Type.name and Content-Disposition.filename)
	    $message->purge ;	
    }
    
    return 1;
}

sub virus_infected {
    my $mail = shift ;
    my $path = shift;
    my $args = shift;
    my $tmpdir = shift;
    my $domain = shift;

    my $file = int(rand(time)) ; # in, version previous from db spools, $file was the filename of the message 
    &Log::do_log('debug2', 'Scan virus in %s', $file);
    
    unless ($path) {
        &Log::do_log('debug', 'Sympa not configured to scan virus in message');
	return 0;
    }
    my @name = split(/\//,$file);
    my $work_dir = $tmpdir.'/antivirus';
    
    unless ((-d $work_dir) ||( mkdir $work_dir, 0755)) {
	&Log::do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return undef;
    }

    $work_dir = $tmpdir.'/antivirus/'.$name[$#name];
    
    unless ( (-d $work_dir) || mkdir ($work_dir, 0755)) {
	&Log::do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return undef;
    }

    #$mail->dump_skeleton;

    ## Call the procedure of spliting mail
    unless (&split_mail ($mail,'msg', $work_dir)) {
	&Log::do_log('err', 'Could not split mail %s', $mail);
	return undef;
    }

    my $virusfound = 0; 
    my $error_msg;
    my $result;

    ## McAfee
    if ($path =~  /\/uvscan$/) {

	# impossible to look for viruses with no option set
	unless ($args) {
	    &Log::do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
	open (ANTIVIR,"$path $args $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    $result .= $_; chomp $result;
	    if ((/^\s*Found the\s+(.*)\s*virus.*$/i) ||
		(/^\s*Found application\s+(.*)\.\s*$/i)){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $? / 256 ; # /

        ## uvscan status =12 or 13 (*256) => virus
        if (( $status == 13) || ($status == 12)) { 
	    $virusfound ||= "unknown";
	}

	## Meaning of the codes
	##  12 : The program tried to clean a file, and that clean failed for some reason and the file is still infected.
	##  13 : One or more viruses or hostile objects (such as a Trojan horse, joke program,  or  a  test file) were found.
	##  15 : The programs self-check failed; the program might be infected or damaged.
	##  19 : The program succeeded in cleaning all infected files.

	$error_msg = $result
	    if ($status != 0 && $status != 12 && $status != 13 && $status != 19);

    ## Trend Micro
    }elsif ($path =~  /\/vscan$/) {

	open (ANTIVIR,"$path $args $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    if (/Found virus (\S+) /i){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status = 1 | 2 (*256) => virus
        if ((( $status == 1) or ( $status == 2)) and not($virusfound)) { 
	    $virusfound = "unknown";
	}

    ## F-Secure
    } elsif($path =~  /\/fsav$/) {
	my $dbdir=$` ;

	# impossible to look for viruses with no option set
	unless ($args) {
	    &Log::do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}

	open (ANTIVIR,"$path --databasedirectory $dbdir $args $work_dir |") ;

	while (<ANTIVIR>) {

	    if (/infection:\s+(.*)/){
		$virusfound = $1;
	    }
	}
	
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## fsecure status =3 (*256) => virus
        if (( $status == 3) and not($virusfound)) { 
	    $virusfound = "unknown";
	}    
    }elsif($path =~ /f-prot\.sh$/) {

        &Log::do_log('debug2', 'f-prot is running');    

        open (ANTIVIR,"$path $args $work_dir |") ;
        
        while (<ANTIVIR>) {
        
            if (/Infection:\s+(.*)/){
                $virusfound = $1;
            }
        }
        
        close ANTIVIR;
        
        my $status = $?/256 ;
        
        &Log::do_log('debug2', 'Status: '.$status);    
        
        ## f-prot status =3 (*256) => virus
        if (( $status == 3) and not($virusfound)) { 
            $virusfound = "unknown";
        }    
    }elsif ($path =~ /kavscanner/) {

	# impossible to look for viruses with no option set
	unless ($args) {
	    &Log::do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
	open (ANTIVIR,"$path $args $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    if (/infected:\s+(.*)/){
		$virusfound = $1;
	    }
	    elsif (/suspicion:\s+(.*)/i){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status =3 (*256) => virus
        if (( $status >= 3) and not($virusfound)) { 
	    $virusfound = "unknown";
	}

        ## Sophos Antivirus... by liuk@publinet.it
    }elsif ($path =~ /\/sweep$/) {
	
        # impossible to look for viruses with no option set
	unless ($args) {
	    &Log::do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
        open (ANTIVIR,"$path $args $work_dir |") ;
	
	while (<ANTIVIR>) {
	    if (/Virus\s+(.*)/) {
		$virusfound = $1;
	    }
	}       
	close ANTIVIR;
        
	my $status = $?/256 ;
        
	## sweep status =3 (*256) => virus
	if (( $status == 3) and not($virusfound)) {
	    $virusfound = "unknown";
	}

	## Clam antivirus
    }elsif ($path =~ /\/clamd?scan$/) {
	
        open (ANTIVIR,"$path $args $work_dir |") ;
	
	my $result;
	while (<ANTIVIR>) {
	    $result .= $_; chomp $result;
	    if (/^\S+:\s(.*)\sFOUND$/) {
		$virusfound = $1;
	    }
	}       
	close ANTIVIR;
        
	my $status = $?/256 ;
        
	## Clamscan status =1 (*256) => virus
	if (( $status == 1) and not($virusfound)) {
	    $virusfound = "unknown";
	}

	$error_msg = $result
	    if ($status != 0 && $status != 1);

    }         

    ## Error while running antivir, notify listmaster
    if ($error_msg) {
	unless (&List::send_notify_to_listmaster('virus_scan_failed', $domain,
						 {'filename' => $file,
						  'error_msg' => $error_msg})) {
	    &Log::do_log('notice',"Unable to send notify 'virus_scan_failed' to listmaster");
	}

    }

    ## if debug mode is active, the working directory is kept
    unless ($main::options{'debug'}) {
	opendir (DIR, ${work_dir});
	my @list = readdir(DIR);
	closedir (DIR);
        foreach (@list) {
	    my $nbre = unlink ("$work_dir/$_")  ;
	}
	rmdir ($work_dir) ;
    }
   
    return $virusfound;
   
}

## subroutines for epoch and human format date processings


## convert an epoch date into a readable date scalar
sub epoch2yyyymmjj_hhmmss {

    my $epoch = $_[0];
    my @date = localtime ($epoch);
    my $date = strftime ("%Y-%m-%d  %H:%M:%S", @date);
    
    return $date;
}

## convert an epoch date into a readable date scalar
sub adate {

    my $epoch = $_[0];
    my @date = localtime ($epoch);
    my $date = strftime ("%e %a %b %Y  %H h %M min %S s", @date);
    
    return $date;
}

## Return the epoch date corresponding to the last midnight before date given as argument.
sub get_midnight_time {

    my $epoch = $_[0];
    &Log::do_log('debug3','Getting midnight time for: %s',$epoch);
    my @date = localtime ($epoch);
    return $epoch - $date[0] - $date[1]*60 - $date[2]*3600;
}

## convert a human format date into an epoch date
sub epoch_conv {

    my $arg = $_[0]; # argument date to convert
    my $time = $_[1] || time; # the epoch current date

    &Log::do_log('debug3','tools::epoch_conv(%s, %d)', $arg, $time);

    my $result;
    
     # decomposition of the argument date
    my $date;
    my $duration;
    my $op;

    if ($arg =~ /^(.+)(\+|\-)(.+)$/) {
	$date = $1;
	$duration = $3;
	$op = $2;
    } else {
	$date = $arg;
	$duration = '';
	$op = '+';
	}

     #conversion
    $date = date_conv ($date, $time);
    $duration = duration_conv ($duration, $date);

    if ($op eq '+') {$result = $date + $duration;}
    else {$result = $date - $duration;}

    return $result;
}

sub date_conv {
   
    my $arg = $_[0];
    my $time = $_[1];

    if ( ($arg eq 'execution_date') ){ # execution date
	return time;
    }

    if ($arg =~ /^\d+$/) { # already an epoch date
	return $arg;
    }
	
    if ($arg =~ /^(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/) { # absolute date

	my @date = ("$6", "$5", "$4", "$3", "$2", "$1");
	for (my $i = 0; $i < 6; $i++) {
	    chop ($date[$i]);
	    if (($i == 1) || ($i== 2)) {chop ($date[$i]); chop ($date[$i]);}
	    $date[$i] = 0 unless ($date[$i]);
	}
	$date[3] = 1 if ($date[3] == 0);
	$date[4]-- if ($date[4] != 0);
	$date[5] -= 1900;
	
	return timelocal (@date);
    }
    
    return time;
}

sub duration_conv {
    
    my $arg = $_[0];
    my $start_date = $_[1];

    return 0 unless $arg;
  
    $arg =~ /(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/i ;
    my @date = ("$1", "$2", "$3", "$4", "$5", "$6", "$7");
    for (my $i = 0; $i < 7; $i++) {
      $date[$i] =~ s/[a-z]+$//; ## Remove trailing units
    }
    
    my $duration = $date[6]+60*($date[5]+60*($date[4]+24*($date[3]+7*$date[2]+365*$date[0])));
	
    # specific processing for the months because their duration varies
    my @months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
		  31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    my $start  = (localtime ($start_date))[4];
    for (my $i = 0; $i < $date[1]; $i++) {
	$duration += $months[$start + $i] * 60 * 60 * 24;
    }
	
    return $duration;
}

## Look for a file in the list > robot > server > default locations
## Possible values for $options : order=all
sub get_filename {
    my ($type, $options, $name, $robot, $object,$basedir) = @_;
    my $list;
    my $family;
    &Log::do_log('debug3','tools::get_filename(%s,%s,%s,%s,%s,%s)', $type,  join('/',keys %$options), $name, $robot, $object->{'name'},$basedir);

    
    if (ref($object) eq 'List') {
 	$list = $object;
 	if ($list->{'admin'}{'family_name'}) {
 	    unless ($family = $list->get_family()) {
 		&Log::do_log('err', 'Impossible to get list %s family : %s. The list is set in status error_config',$list->{'name'},$list->{'admin'}{'family_name'});
 		$list->set_status_error_config('no_list_family',$list->{'name'}, $list->{'admin'}{'family_name'});
 		return undef;
 	    }  
 	}
    }elsif (ref($object) eq 'Family') {
 	$family = $object;
    }
    
    if ($type eq 'etc') {
	my (@try, $default_name);
	
	## template refers to a language
	## => extend search to default tpls
	if ($name =~ /^(\S+)\.([^\s\/]+)\.tt2$/) {
	    $default_name = $1.'.tt2';
	    
	    @try = (
            $basedir . "/$robot/$name",
		    $basedir . "/$robot/$default_name",
		    $basedir . "/$name",
		    $basedir . "/$default_name",
		    Sympa::Constants::DEFAULTDIR . "/$name",
		    Sympa::Constants::DEFAULTDIR . "/$default_name");
	}else {
	    @try = (
            $basedir . "/$robot/$name",
		    $basedir . "/$name",
		    Sympa::Constants::DEFAULTDIR . "/$name"
        );
	}
	
	if ($family) {
 	    ## Default tpl
 	    if ($default_name) {
		unshift @try, $family->{'dir'}.'/'.$default_name;
	    }
	}
	
	unshift @try, $family->{'dir'}.'/'.$name;
    
	if ($list->{'name'}) {
	    ## Default tpl
	    if ($default_name) {
		unshift @try, $list->{'dir'}.'/'.$default_name;
	    }
	    
	    unshift @try, $list->{'dir'}.'/'.$name;
	}
	my @result;
	foreach my $f (@try) {
	    &Log::do_log('debug3','get_filename : name: %s ; dir %s', $name, $f  );
	    if (-r $f) {
		if ($options->{'order'} eq 'all') {
		    push @result, $f;
		}else {
		    return $f;
		}
	    }
	}
	if ($options->{'order'} eq 'all') {
	    return @result ;
	}
    }
    
    #&Log::do_log('notice','tools::get_filename: Cannot find %s in %s', $name, join(',',@try));
    return undef;
}
####################################################
# make_tt2_include_path
####################################################
# make an array of include path for tt2 parsing
# 
# IN -$robot(+) : robot
#    -$dir : directory ending each path
#    -$lang : lang
#    -$list : ref(List)
#
# OUT : ref(ARRAY) of tt2 include path
#
######################################################
sub make_tt2_include_path {
    my ($robot,$dir,$lang,$list,$basedir,$viewmaildir,$domain) = @_;

    my $listname;
    if (ref $list eq 'List') {
	$listname = $list->{'name'};
    } else {
	$listname = $list;
    }
    &Log::do_log('debug3', 'tools::make_tt2_include_path(%s,%s,%s,%s,%s,%s,%s)', $robot, $dir, $lang, $listname, $basedir,$viewmaildir,$domain);

    my @include_path;

    my $path_etcbindir;
    my $path_etcdir;
    my $path_robot;  ## optional
    my $path_list;   ## optional
    my $path_family; ## optional

    if ($dir) {
	$path_etcbindir = Sympa::Constants::DEFAULTDIR . "/$dir";
	$path_etcdir = "$basedir/".$dir;
	$path_robot = "$basedir/".$robot.'/'.$dir if (lc($robot) ne lc($domain));
	if (ref($list) eq 'List'){
	    $path_list = $list->{'dir'}.'/'.$dir;
	    if (defined $list->{'admin'}{'family_name'}) {
		my $family = $list->get_family();
	        $path_family = $family->{'dir'}.'/'.$dir;
	    }
	} 
    }else {
	$path_etcbindir = Sympa::Constants::DEFAULTDIR;
	$path_etcdir = $basedir;
	$path_robot = "$basedir/".$robot if (lc($robot) ne lc($domain));
	if (ref($list) eq 'List') {
	    $path_list = $list->{'dir'} ;
	    if (defined $list->{'admin'}{'family_name'}) {
		my $family = $list->get_family();
	        $path_family = $family->{'dir'};
	    }
	}
    }
    if ($lang) {
	@include_path = ($path_etcdir.'/'.$lang,
			 $path_etcdir,
			 $path_etcbindir.'/'.$lang,
			 $path_etcbindir);
	if ($path_robot) {
	    unshift @include_path,$path_robot;
	    unshift @include_path,$path_robot.'/'.$lang;
	}
	if ($path_list) {
	    unshift @include_path,$path_list;
	    unshift @include_path,$path_list.'/'.$lang;

	    if ($path_family) {
		unshift @include_path,$path_family;
		unshift @include_path,$path_family.'/'.$lang;
	    }	
	    
	}
    }else {
	@include_path = ($path_etcdir,
			 $path_etcbindir);

	if ($path_robot) {
	    unshift @include_path,$path_robot;
	}
	if ($path_list) {
	    unshift @include_path,$path_list;
	   
	    if ($path_family) {
		unshift @include_path,$path_family;
	    }
	}
    }

    unshift @include_path,$viewmaildir;
    return \@include_path;

}

## Find a file in an ordered list of directories
sub find_file {
    my ($filename, @directories) = @_;
    &Log::do_log('debug3','tools::find_file(%s,%s)', $filename, join(':',@directories));

    foreach my $d (@directories) {
	if (-f "$d/$filename") {
	    return "$d/$filename";
	}
    }
    
    return undef;
}

## Recursively list the content of a directory
## Return an array of hash, each entry with directory + filename + encoding
sub list_dir {
    my $dir = shift;
    my $all = shift;
    my $original_encoding = shift; ## Suspected original encoding of filenames

    my $size=0;

    if (opendir(DIR, $dir)) {
	foreach my $file ( sort grep (!/^\.\.?$/,readdir(DIR))) {

	    ## Guess filename encoding
	    my ($encoding, $guess);
	    my $decoder = &Encode::Guess::guess_encoding($file, $original_encoding, 'utf-8');
	    if (ref $decoder) {
		$encoding = $decoder->name;
	    }else {
		$guess = $decoder;
	    }

	    push @$all, {'directory' => $dir,
			 'filename' => $file,
			 'encoding' => $encoding,
			 'guess' => $guess};
	    if (-d "$dir/$file") {
		&list_dir($dir.'/'.$file, $all, $original_encoding);
	    }
	}
        closedir DIR;
    }

    return 1;
}

## Q-encode a complete file hierarchy
## Usefull to Q-encode subshared documents
sub qencode_hierarchy {
    my $dir = shift; ## Root directory
    my $original_encoding = shift; ## Suspected original encoding of filenames

    my $count;
    my @all_files;
    &tools::list_dir($dir, \@all_files, $original_encoding);

    foreach my $f_struct (reverse @all_files) {
    
	next unless ($f_struct->{'filename'} =~ /[^\x00-\x7f]/); ## At least one 8bit char

	my $new_filename = $f_struct->{'filename'};
	my $encoding = $f_struct->{'encoding'};
	Encode::from_to($new_filename, $encoding, 'utf8') if $encoding;
    
	## Q-encode filename to escape chars with accents
	$new_filename = &tools::qencode_filename($new_filename);
    
	my $orig_f = $f_struct->{'directory'}.'/'.$f_struct->{'filename'};
	my $new_f = $f_struct->{'directory'}.'/'.$new_filename;

	## Rename the file using utf8
	&Log::do_log('notice', "Renaming %s to %s", $orig_f, $new_f);
	unless (rename $orig_f, $new_f) {
	    &Log::do_log('err', "Failed to rename %s to %s : %s", $orig_f, $new_f, $!);
	    next;
	}
	$count++;
    }

    return $count;
}

## Dumps the value of each character of the inuput string
sub dump_encoding {
    my $out = shift;

    $out =~ s/./sprintf('%02x', ord($&)).' '/eg;
    return $out;
}

## Remove PID file and STDERR output
sub remove_pid {
	my ($pidfile, $pid, $options, $tmpdir) = @_;
	
	## If in multi_process mode (bulk.pl for instance can have child processes)
	## Then the pidfile contains a list of space-separated PIDs on a single line
	if($options->{'multiple_process'}) {
		unless(open(PFILE, $pidfile)) {
			# fatal_err('Could not open %s, exiting', $pidfile);
			&Log::do_log('err','Could not open %s to remove pid %s', $pidfile, $pid);
			return undef;
		}
		my $l = <PFILE>;
		close PFILE;	
		my @pids = grep {/[0-9]+/} split(/\s+/, $l);
		@pids = grep {!/^$pid$/} @pids;
		
		## If no PID left, then remove the file
		if($#pids < 0) {
			## Release the lock
			unless(unlink $pidfile) {
				&Log::do_log('err', "Failed to remove $pidfile: %s", $!);
				return undef;
			}
		}else{
			if(-f $pidfile) {
				unless(open(PFILE, '> '.$pidfile)) {
					&Log::do_log('err', "Failed to open $pidfile: %s", $!);
					return undef;
				}
				print PFILE join(' ', @pids)."\n";
				close(PFILE);
			}else{
				&Log::do_log('notice', 'pidfile %s does not exist. Nothing to do.', $pidfile);
			}
		}
	}else{
		unless(unlink $pidfile) {
			&Log::do_log('err', "Failed to remove $pidfile: %s", $!);
			return undef;
		}
		my $err_file = $tmpdir.'/'.$pid.'.stderr';
		if(-f $err_file) {
			unless(unlink $err_file) {
				&Log::do_log('err', "Failed to remove $err_file: %s", $!);
				return undef;
			}
		}
	}
	return 1;
}

sub write_pid {
    my ($pidfile, $pid, $options) = @_;

    my $piddir = $pidfile;
    $piddir =~ s/\/[^\/]+$//;

    ## Create piddir
    mkdir($piddir, 0755) unless(-d $piddir);

    unless(&tools::set_file_rights(
	file => $piddir,
	user  => Sympa::Constants::USER,
	group => Sympa::Constants::GROUP,
    )) {
	&Log::fatal_err('Unable to set rights on %s. Exiting.', $piddir);
    }

    my @pids;

    # Lock pid file
    my $lock = new Lock ($pidfile);
    unless (defined $lock) {
	&Log::fatal_err('Lock could not be created. Exiting.');
    }
    $lock->set_timeout(5); 
    unless ($lock->lock('write')) {
	&Log::fatal_err('Unable to lock %s file in write mode. Exiting.',$pidfile);
    }
    ## If pidfile exists, read the PIDs
    if(-f $pidfile) {
	# Read pid file
	open(PFILE, $pidfile);
	my $l = <PFILE>;
	close PFILE;	
	@pids = grep {/[0-9]+/} split(/\s+/, $l);
    }

    ## If we can have multiple instances for the process.
    ## Print other pids + this one
    if($options->{'multiple_process'}) {
	unless(open(PIDFILE, '> '.$pidfile)) {
	    ## Unlock pid file
	    $lock->unlock();
	    &Log::fatal_err('Could not open %s, exiting: %s', $pidfile,$!);
	}
	## Print other pids + this one
	push(@pids, $pid);
	print PIDFILE join(' ', @pids)."\n";
	close(PIDFILE);
    }else{
	## Create and write the pidfile
	unless(open(PIDFILE, '+>> '.$pidfile)) {
	    ## Unlock pid file
	    $lock->unlock();
	    &Log::fatal_err('Could not open %s, exiting: %s', $pidfile);
	}
	## The previous process died suddenly, without pidfile cleanup
	## Send a notice to listmaster with STDERR of the previous process
	if($#pids >= 0) {
	    my $other_pid = $pids[0];
	    &Log::do_log('notice', "Previous process %s died suddenly ; notifying listmaster", $other_pid);
	    my $pname = $0;
	    $pname =~ s/.*\/(\w+)/$1/;
	    &send_crash_report(('pid'=>$other_pid,'pname'=>$pname));
	}
	
	unless(open(PIDFILE, '> '.$pidfile)) {
	    ## Unlock pid file
	    $lock->unlock();
	    &Log::fatal_err('Could not open %s, exiting', $pidfile);
	}
	unless(truncate(PIDFILE, 0)) {
	    ## Unlock pid file
	    $lock->unlock();
	    &Log::fatal_err('Could not truncate %s, exiting.', $pidfile);
	}
	
	print PIDFILE $pid."\n";
	close(PIDFILE);
    }

    unless(&tools::set_file_rights(
	file => $pidfile,
	user  => Sympa::Constants::USER,
	group => Sympa::Constants::GROUP,
    )) {
	## Unlock pid file
	$lock->unlock();
	&Log::fatal_err('Unable to set rights on %s', $pidfile);
    }
    ## Unlock pid file
    $lock->unlock();

    return 1;
}

sub direct_stderr_to_file {
    my %data = @_;
    ## Error output is stored in a file with PID-based name
    ## Usefull if process crashes
    open(STDERR, '>>', $data{'tmpdir'}.'/'.$data{'pid'}.'.stderr');
    unless(&tools::set_file_rights(
	file => $data{'tmpdir'}.'/'.$data{'pid'}.'.stderr',
	user  => Sympa::Constants::USER,
	group => Sympa::Constants::GROUP,
    )) {
	&Log::do_log('err','Unable to set rights on %s', $data{'tmpdir'}.'/'.$data{'pid'}.'.stderr');
	return undef;
    }
    return 1;
}

# Send content of $pid.stderr to listmaster for process whose pid is $pid.
sub send_crash_report {
    my %data = @_;
    &Log::do_log('debug','Sending crash report for process %s',$data{'pid'}),
    my $err_file = $data{'tmpdir'}.'/'.$data{'pid'}.'.stderr';
    my (@err_output, $err_date);
    if(-f $err_file) {
	open(ERR, $err_file);
	@err_output = <ERR>;
	close ERR;
	$err_date = strftime("%d %b %Y  %H:%M", localtime((stat($err_file))[9]));
    }
    &List::send_notify_to_listmaster('crash', $data{'domain'}, {'crashed_process' => $data{'pname'}, 'crash_err' => \@err_output, 'crash_date' => $err_date, 'pid' => $data{'pid'}});
}

sub get_message_id {
    my $robot = shift;

    my $id = sprintf '<sympa.%d.%d.%d@%s>', time, $$, int(rand(999)), $robot;

    return $id;
}


sub get_dir_size {
    my $dir =shift;
    
    my $size=0;

    if (opendir(DIR, $dir)) {
	foreach my $file ( sort grep (!/^\./,readdir(DIR))) {
	    if (-d "$dir/$file") {
		$size += get_dir_size("$dir/$file");
	    }
	    else{
		my @info = stat "$dir/$file" ;
		$size += $info[7];
	    }
	}
        closedir DIR;
    }

    return $size;
}

## Basic check of an email address
sub valid_email {
    my $email = shift;
    
    unless ($email =~ /^$regexp{'email'}$/) {
	&Log::do_log('err', "Invalid email address '%s'", $email);
	return undef;
    }
    
    ## Forbidden characters
    if ($email =~ /[\|\$\*\?\!]/) {
	&Log::do_log('err', "Invalid email address '%s'", $email);
	return undef;
    }

    return 1;
}

## Clean email address
sub clean_email {
    my $email = shift;

    ## Lower-case
    $email = lc($email);

    ## remove leading and trailing spaces
    $email =~ s/^\s*//;
    $email =~ s/\s*$//;

    return $email;
}

## Return canonical email address (lower-cased + space cleanup)
## It could also support alternate email
sub get_canonical_email {
    my $email = shift;

    ## Remove leading and trailing white spaces
    $email =~ s/^\s*(\S.*\S)\s*$/$1/;

    ## Lower-case
    $email = lc($email);

    return $email;
}

## Function for Removing a non-empty directory
## It takes a variale number of arguments : 
## it can be a list of directory
## or few direcoty paths
sub remove_dir {
    
    &Log::do_log('debug2','remove_dir()');
    
    foreach my $current_dir (@_){
	finddepth({wanted => \&del, no_chdir => 1},$current_dir);
    }
    sub del {
	my $name = $File::Find::name;

	if (!-l && -d _) {
	    unless (rmdir($name)) {
		&Log::do_log('err','Error while removing dir %s',$name);
	    }
	}else{
	    unless (unlink($name)) {
		&Log::do_log('err','Error while removing file  %s',$name);
	    }
	}
    }
    return 1;
}

## Dump a variable's content
sub dump_var {
    my ($var, $level, $fd) = @_;

    return undef unless ($fd);

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    foreach my $index (0..$#{$var}) {
		print $fd "\t"x$level.$index."\n";
		&dump_var($var->[$index], $level+1, $fd);
	    }
	}elsif (ref($var) eq 'HASH' || ref($var) eq 'Scenario' || ref($var) eq 'List' || ref($var) eq 'CGI::Fast') {
	    foreach my $key (sort keys %{$var}) {
		print $fd "\t"x$level.'_'.$key.'_'."\n";
		&dump_var($var->{$key}, $level+1, $fd);
	    }    
	}else {
	    printf $fd "\t"x$level."'%s'"."\n", ref($var);
	}
    }else {
	if (defined $var) {
	    print $fd "\t"x$level."'$var'"."\n";
	}else {
	    print $fd "\t"x$level."UNDEF\n";
	}
    }
}

## Dump a variable's content
sub dump_html_var {
    my ($var) = shift;
	my $html = '';

    
    if (ref($var)) {

	if (ref($var) eq 'ARRAY') {
	    $html .= '<ul>';
	    foreach my $index (0..$#{$var}) {
		$html .= '<li> '.$index.':';
		$html .= &dump_html_var($var->[$index]);
		$html .= '</li>';
	    }
	    $html .= '</ul>';
	}elsif (ref($var) eq 'HASH' || ref($var) eq 'Scenario' || ref($var) eq 'List') {
	    $html .= '<ul>';
	    foreach my $key (sort keys %{$var}) {
		$html .= '<li>'.$key.'=' ;
		$html .=  &dump_html_var($var->{$key});
		$html .= '</li>';
	    }
	    $html .= '</ul>';
	}else {
	    $html .= 'EEEEEEEEEEEEEEEEEEEEE'.ref($var);
	}
    }else{
	if (defined $var) {
	    $html .= &escape_html($var);
	}else {
	    $html .= 'UNDEF';
	}
    }
    return $html;
}

## Dump a variable's content
sub dump_html_var2 {
    my ($var) = shift;

    my $html = '' ;
    
    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    $html .= 'ARRAY <ul>';
	    foreach my $index (0..$#{$var}) {
		$html .= '<li> '.$index;
		$html .= &dump_html_var($var->[$index]);
		$html .= '</li>'
	    }
	    $html .= '</ul>';
	}elsif (ref($var) eq 'HASH' || ref($var) eq 'Scenario' || ref($var) eq 'List') {
	    #$html .= " (".ref($var).') <ul>';
	    $html .= '<ul>';
	    foreach my $key (sort keys %{$var}) {
		$html .= '<li>'.$key.'=' ;
		$html .=  &dump_html_var($var->{$key});
		$html .= '</li>'
	    }    
	    $html .= '</ul>';
	}else {
	    $html .= sprintf "<li>'%s'</li>", ref($var);
	}
    }else{
	if (defined $var) {
	    $html .= '<li>'.$var.'</li>';
	}else {
	    $html .= '<li>UNDEF</li>';
	}
    }
    return $html;
}

sub remove_empty_entries {
    my ($var) = @_;    
    my $not_empty = 0;

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    foreach my $index (0..$#{$var}) {
		my $status = &remove_empty_entries($var->[$index]);
		$var->[$index] = undef unless ($status);
		$not_empty ||= $status
	    }	    
	}elsif (ref($var) eq 'HASH') {
	    foreach my $key (sort keys %{$var}) {
		my $status = &remove_empty_entries($var->{$key});
		$var->{$key} = undef unless ($status);
		$not_empty ||= $status;
	    }    
	}
    }else {
	if (defined $var && $var) {
	    $not_empty = 1
	}
    }
    
    return $not_empty;
}

## Duplictate a complex variable
sub dup_var {
    my ($var) = @_;    

    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    my $new_var = [];
	    foreach my $index (0..$#{$var}) {
		$new_var->[$index] = &dup_var($var->[$index]);
	    }	    
	    return $new_var;
	}elsif (ref($var) eq 'HASH') {
	    my $new_var = {};
	    foreach my $key (sort keys %{$var}) {
		$new_var->{$key} = &dup_var($var->{$key});
	    }    
	    return $new_var;
	}
    }
    
    return $var; 
}

####################################################
# get_array_from_splitted_string                          
####################################################
# return an array made on a string splited by ','.
# It removes spaces.
#
# 
# IN : -$string (+): string to split 
#
# OUT : -ref(ARRAY)
#
######################################################
sub get_array_from_splitted_string {
    my ($string) = @_;
    my @array;

    foreach my $word (split /,/,$string) {
	$word =~ s/^\s+//;
	$word =~ s/\s+$//;
	push @array, $word;
    }

    return \@array;
}


####################################################
# diff_on_arrays                     
####################################################
# Makes set operation on arrays (seen as set, with no double) :
#  - deleted : A \ B
#  - added : B \ A
#  - intersection : A /\ B
#  - union : A \/ B
# 
# IN : -$setA : ref(ARRAY) - set
#      -$setB : ref(ARRAY) - set
#
# OUT : -ref(HASH) with keys :  
#          deleted, added, intersection, union
#
#######################################################    
sub diff_on_arrays {
    my ($setA,$setB) = @_;
    my $result = {'intersection' => [],
	          'union' => [],
	          'added' => [],
	          'deleted' => []};
    my %deleted;
    my %added;
    my %intersection;
    my %union;
    
    my %hashA;
    my %hashB;
    
    foreach my $eltA (@$setA) {
	$hashA{$eltA} = 1;
	$deleted{$eltA} = 1;
	$union{$eltA} = 1;
    }
    
    foreach my $eltB (@$setB) {
	$hashB{$eltB} = 1;
	$added{$eltB} = 1;
	
	if ($hashA{$eltB}) {
	    $intersection{$eltB} = 1;
	    $deleted{$eltB} = 0;
	}else {
	    $union{$eltB} = 1;
	}
    }
    
    foreach my $eltA (@$setA) {
	if ($hashB{$eltA}) {
	    $added{$eltA} = 0; 
	}
    }
    
    foreach my $elt (keys %deleted) {
	next unless $elt;
	push @{$result->{'deleted'}},$elt if ($deleted{$elt});
    }
    foreach my $elt (keys %added) {
	next unless $elt;
	push @{$result->{'added'}},$elt if ($added{$elt});
    }
    foreach my $elt (keys %intersection) {
	next unless $elt;
	push @{$result->{'intersection'}},$elt if ($intersection{$elt});
    }
    foreach my $elt (keys %union) {
	next unless $elt;
	push @{$result->{'union'}},$elt if ($union{$elt});
    } 
    
    return $result;
    
} 

####################################################
# is_on_array                     
####################################################
# Test if a value is on an array
# 
# IN : -$setA : ref(ARRAY) - set
#      -$value : a serached value
#
# OUT : boolean
#######################################################    
sub is_in_array {
    my ($set,$value) = @_;
    
    foreach my $elt (@$set) {
	return 1 if ($elt eq $value);
    }
    return undef;
}

####################################################
# a_is_older_than_b
####################################################
# Compares the last modifications date of two files
# 
# IN : - a hash with two entries:
#
#        * a_file : the full path to a file
#        * b_file : the full path to a file
#
# OUT : string: 'true' if the last modification date of "a_file" is older than "b_file"'s, 'false' otherwise.
#       return undef if the comparison could not be carried on.
#######################################################    
sub a_is_older_than_b {
    my $param = shift;
    my ($a_file_readable, $b_file_readable) = (0,0);
    my $answer = undef;
    if (-r $param->{'a_file'}) {
	$a_file_readable = 1;
    }else{
	&Log::do_log('err', 'Could not read file "%s". Comparison impossible', $param->{'a_file'});
    }
    if (-r $param->{'b_file'}) {
	$b_file_readable = 1;
    }else{
	&Log::do_log('err', 'Could not read file "%s". Comparison impossible', $param->{'b_file'});
    }
    if ($a_file_readable && $b_file_readable) {
	my @a_stats = stat ($param->{'a_file'});
	my @b_stats = stat ($param->{'b_file'});
	if($a_stats[9] < $b_stats[9]){
	    $answer = 1;
	}else{
	    $answer = 0;
	}
    }
    return $answer;
}

####################################################
# clean_msg_id
####################################################
# clean msg_id to use it without  \n, \s or <,>
# 
# IN : -$msg_id (+) : the msg_id
#
# OUT : -$msg_id : the clean msg_id
#
######################################################
sub clean_msg_id {
    my $msg_id = shift;
    
    chomp $msg_id;

    if ($msg_id =~ /\<(.+)\>/) {
	$msg_id = $1;
    }

    return $msg_id;
}



## Change X-Sympa-To: header field in the message
sub change_x_sympa_to {
    my ($file, $value) = @_;
    
    ## Change X-Sympa-To
    unless (open FILE, $file) {
	&Log::do_log('err', "Unable to open '%s' : %s", $file, $!);
	next;
    }	 
    my @content = <FILE>;
    close FILE;
    
    unless (open FILE, ">$file") {
	&Log::do_log('err', "Unable to open '%s' : %s", "$file", $!);
	next;
    }	 
    foreach (@content) {
	if (/^X-Sympa-To:/i) {
	    $_ = "X-Sympa-To: $value\n";
	}
	print FILE;
    }
    close FILE;
    
    return 1;
}

## Compare 2 versions of Sympa
sub higher_version {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./,$v1;
    my @tab2 = split /\./,$v2;
    
    
    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for my $i (0..$max) {
    
        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        }elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        }elsif ($tab2[0] =~ /^(\d*)b$/) {
            $tab2[0] = $1 - 0.25;
        }

        if ($tab1[0] eq $tab2[0]) {
            #printf "\t%s = %s\n",$tab1[0],$tab2[0];
            shift @tab1;
            shift @tab2;
            next;
        }
        return ($tab1[0] > $tab2[0]);
    }

    return 0;
}

## Compare 2 versions of Sympa
sub lower_version {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./,$v1;
    my @tab2 = split /\./,$v2;
    
    
    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for my $i (0..$max) {
    
        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        }elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        }elsif ($tab2[0] =~ /^(\d*)b$/) {
            $tab2[0] = $1 - 0.25;
        }

        if ($tab1[0] eq $tab2[0]) {
            #printf "\t%s = %s\n",$tab1[0],$tab2[0];
            shift @tab1;
            shift @tab2;
            next;
        }
        return ($tab1[0] < $tab2[0]);
    }

    return 0;
}

sub add_in_blacklist {
    my $entry = shift;
    my $robot = shift;
    my $list =shift;

    &Log::do_log('info',"tools::add_in_blacklist(%s,%s,%s)",$entry,$robot,$list->{'name'});
    $entry = lc($entry);
    chomp $entry;

    # robot blacklist not yet availible 
    unless ($list) {
	 &Log::do_log('info',"tools::add_in_blacklist: robot blacklist not yet availible, missing list parameter");
	 return undef;
    }
    unless (($entry)&&($robot)) {
	 &Log::do_log('info',"tools::add_in_blacklist:  missing parameters");
	 return undef;
    }
    if ($entry =~ /\*.*\*/) {
	&Log::do_log('info',"tools::add_in_blacklist: incorrect parameter $entry");
	return undef;
    }
    my $dir = $list->{'dir'}.'/search_filters';
    unless ((-d $dir) || mkdir ($dir, 0755)) {
	&Log::do_log('info','do_blacklist : unable to create dir %s',$dir);
	return undef;
    }
    my $file = $dir.'/blacklist.txt';
    
    if (open BLACKLIST, "$file"){
	while(<BLACKLIST>) {
	    next if (/^\s*$/o || /^[\#\;]/o);
	    my $regexp= $_ ;
	    chomp $regexp;
	    $regexp =~ s/\*/.*/ ; 
	    $regexp = '^'.$regexp.'$';
	    if ($entry =~ /$regexp/i) { 
		&Log::do_log('notice','do_blacklist : %s already in blacklist(%s)',$entry,$_);
		return 0;
	    }	
	}
	close BLACKLIST;
    }   
    unless (open BLACKLIST, ">> $file"){
	&Log::do_log('info','do_blacklist : append to file %s',$file);
	return undef;
    }
    print BLACKLIST "$entry\n";
    close BLACKLIST;

}

sub LOCK_SH {1};
sub LOCK_EX {2};
sub LOCK_NB {4};
sub LOCK_UN {8};

## lock a file 
sub lock {
    my $lock_file = shift;
    my $mode = shift; ## read or write
    
    my $operation; # 
    my $open_mode;

    if ($mode eq 'read') {
	$operation = LOCK_SH;
    }else {
	$operation = LOCK_EX;
	$open_mode = '>>';
    }
    
    ## Read access to prevent "Bad file number" error on Solaris
    unless (open FH, $open_mode.$lock_file) {
	&Log::do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	return undef;
    }
    
    my $got_lock = 1;
    unless (flock (FH, $operation | LOCK_NB)) {
	&Log::do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);

	## If lock was obtained more than 20 minutes ago, then force the lock
	if ( (time - (stat($lock_file))[9] ) >= 60*20) {
	    &Log::do_log('notice','Removing lock file %s', $lock_file);
	    unless (unlink $lock_file) {
		&Log::do_log('err', 'Cannot remove %s: %s', $lock_file, $!);
		return undef;	    		
	    }
	    
	    unless (open FH, ">$lock_file") {
		&Log::do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		return undef;	    
	    }
	}

	$got_lock = undef;
	my $max = 10;
	$max = 2 if ($ENV{'HTTP_HOST'}); ## Web context
	for (my $i = 1; $i < $max; $i++) {
	    sleep (10 * $i);
	    if (flock (FH, $operation | LOCK_NB)) {
		$got_lock = 1;
		last;
	    }
	    &Log::do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);
	}
    }
	
    if ($got_lock) {
	&Log::do_log('debug2', 'Got lock for %s on %s', $mode, $lock_file);

	## Keep track of the locking PID
	if ($mode eq 'write') {
	    print FH "$$\n";
	}
    }else {
	&Log::do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	return undef;
    }

    return \*FH;
}

## unlock a file 
sub unlock {
    my $lock_file = shift;
    my $fh = shift;
    
    unless (flock($fh,LOCK_UN)) {
	&Log::do_log('err', 'Failed UNlocking %s: %s', $lock_file, $!);
	return undef;
    }
    close $fh;
    &Log::do_log('debug2', 'Release lock on %s', $lock_file);
    
    return 1;
}

############################################################
#  get_fingerprint                                         #
############################################################
#  Used in 2 cases :                                       #
#  - check the md5 in the url                              #
#  - create an md5 to put in a url                         #
#                                                          #
#  Use : get_db_random()                                   #
#        init_db_random()                                  #
#        md5_fingerprint()                                 #
#                                                          #  
# IN : $email : email of the subscriber                    #
#      $fingerprint : the fingerprint in the url (1st case)#
#                                                          # 
# OUT : $fingerprint : a md5 for create an url             #
#     | 1 : if the md5 in the url is true                  #
#     | undef                                              #
#                                                          #
############################################################
sub get_fingerprint {
    
    my $email = shift;
    my $fingerprint = shift;
    my $random = shift;
    my $random_email;
     
    $random_email = ($random.$email);
 
    if( $fingerprint ) { #si on veut vérifier le fingerprint dans l'url

	if($fingerprint eq &md5_fingerprint($random_email)){
	    return 1;
	}else{
	    return undef;
	}

    }else{ #si on veut créer une url de type http://.../sympa/unsub/$list/$email/&get_fingerprint($email)

	$fingerprint = &md5_fingerprint($random_email);
	return $fingerprint;

    }
}

############################################################
#  md5_fingerprint                                         #
############################################################
#  The algorithm MD5 (Message Digest 5) is a cryptographic #
#  hash function which permit to obtain                    #
#  the fingerprint of a file/data                          #
#                                                          #
# IN : a string                                            #
#                                                          #
# OUT : md5 digest                                         #
#     | undef                                              #
#                                                          #
############################################################
sub md5_fingerprint {
    
    my $input_string = shift;
    return undef unless (defined $input_string);
    chomp $input_string;
    
    my $digestmd5 = new Digest::MD5;
    $digestmd5->reset;
    $digestmd5->add($input_string);
    return (unpack("H*", $digestmd5->digest));
}

sub get_separator {
    return $separator;
}

## Return the Sympa regexp corresponding to the input param
sub get_regexp {
    my $type = shift;

    if (defined $regexp{$type}) {
	return $regexp{$type};
    }else {
	return '\w+'; ## default is a very strict regexp
    }

}

## convert a string formated as var1="value1";var2="value2"; into a hash.
## Used when extracting from session table some session properties or when extracting users preference from user table
## Current encoding is NOT compatible with encoding of values with '"'
##
sub string_2_hash {
    my $data = shift;
    my %hash ;
    
    pos($data) = 0;
    while ($data =~ /\G;?(\w+)\=\"((\\[\"\\]|[^\"])*)\"(?=(;|\z))/g) {
	my ($var, $val) = ($1, $2);
	$val =~ s/\\([\"\\])/$1/g;
	$hash{$var} = $val; 
    }    

    return (%hash);

}
## convert a hash into a string formated as var1="value1";var2="value2"; into a hash
sub hash_2_string { 
    my $refhash = shift;

    return undef unless ((ref($refhash))&& (ref($refhash) eq 'HASH')) ;

    my $data_string ;
    foreach my $var (keys %$refhash ) {
	next unless ($var);
	my $val = $refhash->{$var};
	$val =~ s/([\"\\])/\\$1/g;
	$data_string .= ';'.$var.'="'.$val.'"';
    }
    return ($data_string);
}

=pod 

=head2 sub save_to_bad(HASH $param)

Saves a message file to the "bad/" spool of a given queue. Creates this directory if not found.

=head3 Arguments 

=over 

=item * I<param> : a hash containing all the arguments, which means:

=over 4

=item * I<file> : the characters string of the path to the file to copy to bad;

=item * I<hostname> : the characters string of the name of the virtual host concerned;

=item * I<queue> : the characters string of the name of the queue.

=back

=back 

=head3 Return 

=over

=item * 1 if the file was correctly saved to the "bad/" directory;

=item * undef if something went wrong.

=back 

=head3 Calls 

=over 

=item * List::send_notify_to_listmaster

=back 

=cut 

sub save_to_bad {

    my $param = shift;
    
    my $file = $param->{'file'};
    my $hostname = $param->{'hostname'};
    my $queue = $param->{'queue'};

    if (! -d $queue.'/bad') {
	unless (mkdir $queue.'/bad', 0775) {
	    &Log::do_log('notice','Unable to create %s/bad/ directory.',$queue);
	    unless (&List::send_notify_to_listmaster('unable_to_create_dir',$hostname),{'dir' => "$queue/bad"}) {
		&Log::do_log('notice',"Unable to send notify 'unable_to_create_dir' to listmaster");
	    }
	    return undef;
	}
	&Log::do_log('debug',"mkdir $queue/bad");
    }
    &Log::do_log('notice',"Saving file %s to %s", $queue.'/'.$file, $queue.'/bad/'.$file);
    unless (rename($queue.'/'.$file ,$queue.'/bad/'.$file) ) {
	&Log::do_log('notice', 'Could not rename %s to %s: %s', $queue.'/'.$file, $queue.'/bad/'.$file, $!);
	return undef;
    }
    
    return 1;
}

=pod 

=head2 sub CleanSpool(STRING $spool_dir, INT $clean_delay)

Clean all messages in spool $spool_dir older than $clean_delay.

=head3 Arguments 

=over 

=item * I<spool_dir> : a string corresponding to the path to the spool to clean;

=item * I<clean_delay> : the delay between the moment we try to clean spool and the last modification date of a file.

=back

=back 

=head3 Return 

=over

=item * 1 if the spool was cleaned withou troubles.

=item * undef if something went wrong.

=back 

=head3 Calls 

=over 

=item * tools::remove_dir

=back 

=cut 

############################################################
#  CleanDir
############################################################
#  Cleans files older than $clean_delay from spool $spool_dir
#  
# IN : -$dir (+): the spool directory
#      -$clean_delay (+): delay in days 
#
# OUT : 1
#
############################################################## 
sub CleanDir {
    my ($dir, $clean_delay) = @_;
    &Log::do_log('debug', 'CleanSpool(%s,%s)', $dir, $clean_delay);

    unless (opendir(DIR, $dir)) {
	&Log::do_log('err', "Unable to open '%s' spool : %s", $dir, $!);
	return undef;
    }

    my @qfile = sort grep (!/^\.+$/,readdir(DIR));
    closedir DIR;
    
    my ($curlist,$moddelay);
    foreach my $f (sort @qfile) {

	if ((stat "$dir/$f")[9] < (time - $clean_delay * 60 * 60 * 24)) {
	    if (-f "$dir/$f") {
		unlink ("$dir/$f") ;
		&Log::do_log('notice', 'Deleting old file %s', "$dir/$f");
	    }elsif (-d "$dir/$f") {
		unless (&tools::remove_dir("$dir/$f")) {
		    &Log::do_log('err', 'Cannot remove old directory %s : %s', "$dir/$f", $!);
		    next;
		}
		&Log::do_log('notice', 'Deleting old directory %s', "$dir/$f");
	    }
	}
    }
    return 1;
}


# return a lockname that is a uniq id of a processus (hostname + pid) ; hostname (20) and pid(10) are truncated in order to store lockname in database varchar(30)
sub get_lockname (){
    return substr(substr(hostname(), 0, 20).$$,0,30);   
}

## compare 2 scalars, string/numeric independant
sub smart_lessthan {
    my ($stra, $strb) = @_;
    $stra =~ s/^\s+//; $stra =~ s/\s+$//;
    $strb =~ s/^\s+//; $strb =~ s/\s+$//;
    $! = 0;
    my($numa, $unparsed) = strtod($stra);
    my $numb;
    $numb = strtod($strb)
    	unless ($! || $unparsed !=0);
    if (($stra eq '') || ($strb eq '') || ($unparsed != 0) || $!) {
	return $stra lt $strb;
    } else {
        return $stra < $strb;
    } 
}

## Returns the list of pid identifiers in the pid file.
sub get_pids_in_pid_file {
	my $pidfile = shift;
	unless (open(PFILE, $pidfile)) {
		&Log::do_log('err', "unable to open pidfile %s:%s",$pidfile,$!);
		return undef;
	}
	my $l = <PFILE>;
	close PFILE;
	my @pids = grep {/[0-9]+/} split(/\s+/, $l);
	return \@pids;
}

## Returns the counf of numbers found in the string given as argument.
sub count_numbers_in_string {
    my $str = shift;
    my $count = 0;
    $count++ while $str =~ /(\d+\s+)/g;
    return $count;
}

#*******************************************
# Function : wrap_text
# Description : return line-wrapped text.
## IN : text, init, subs, cols
#*******************************************
sub wrap_text {
    my $text = shift;
    my $init = shift;
    my $subs = shift;
    my $cols = shift;
    $cols = 78 unless defined $cols;
    return $text unless $cols;

    $text = Text::LineFold->new(
	    Language => &Language::GetLang(),
	    OutputCharset => (&Encode::is_utf8($text)? '_UNICODE_': 'utf8'),
	    Prep => 'NONBREAKURI',
	    ColumnsMax => $cols
	)->fold($init, $subs, $text);

    return $text;
}

#*******************************************
# Function : addrencode
# Description : return formatted (and encoded) name-addr as RFC5322 3.4.
## IN : addr, [phrase, [charset]]
#*******************************************
sub addrencode {
    my $addr = shift;
    my $phrase = (shift || '');
    my $charset = (shift || 'utf8');

    return undef unless $addr =~ /\S/;

    if ($phrase =~ /[^\s\x21-\x7E]/) {
	# Minimal encoding leaves special characters unencoded.
	# In this case do maximal encoding for workaround.
	my $minimal =
	    ($phrase =~ /(\A|\s)[\x21-\x7E]*[\"(),:;<>\@\\][\x21-\x7E]*(\s|\z)/)?
	    'NO': 'YES';
	$phrase = MIME::EncWords::encode_mimewords(
	    Encode::decode('utf8', $phrase),
	    'Encoding' => 'A', 'Charset' => $charset,
	    'Replacement' => 'FALLBACK',
	    'Field' => 'Resent-Sender', # almost longest
	    'Minimal' => $minimal
            );
	return "$phrase <$addr>";
    } elsif ($phrase =~ /\S/) {
	$phrase =~ s/([\\\"])/\\$1/g;
	return "\"$phrase\" <$addr>";
    } else {
	return "<$addr>";
    }
}

# Generate a newsletter from an HTML URL or a file path.
sub create_html_part_from_web_page {
    my $param = shift;
    &Log::do_log('debug',"Creating HTML MIME part. Source: %s",$param->{'source'});
    my $mailHTML = new MIME::Lite::HTML(
					{
					    From => $param->{'From'},
					    To => $param->{'To'},
					    Headers => $param->{'Headers'},
					    Subject => $param->{'Subject'},
					    HTMLCharset => 'utf-8',
					    TextCharset => 'utf-8',
					    TextEncoding => '8bit',
					    HTMLEncoding => '8bit',
					    remove_jscript => '1', #delete the scripts in the html
					}
					);
    # parse return the MIME::Lite part to send
    my $part = $mailHTML->parse($param->{'source'});
    unless (defined($part)) {
	&Log::do_log('err', 'Unable to convert file %s to a MIME part',$param->{'source'});
	return undef;
    }
    return $part->as_string;
}

sub get_children_processes_list {
    &Log::do_log('debug3','');
    my @children;
    for my $p (@{new Proc::ProcessTable->table}){
	if($p->ppid == $$) {
	    push @children, $p->pid;
	}
    }
    return @children;
}

#*******************************************
# Function : decode_header
# Description : return header value decoded to UTF-8 or undef.
#               trailing newline will be removed.
#               If sep is given, return all occurrances joined by it.
## IN : msg, tag, [sep]
#*******************************************
sub decode_header {
    my $msg = shift;
    my $tag = shift;
    my $sep = shift || undef;

    my $head;
    if (ref $msg eq 'Message') {
	$head = $msg->{'msg'}->head;
    } elsif (ref $msg eq 'MIME::Entity') {
	$head = $msg->head;
    } elsif (ref $msg eq 'MIME::Head' or ref $msg eq 'Mail::Header') {
	$head = $msg;
    }
    if (defined $sep) {
	my @values = $head->get($tag);
	return undef unless scalar @values;
	foreach my $val (@values) {
	    $val = MIME::EncWords::decode_mimewords($val, Charset => 'UTF-8');
	    chomp $val;
	}
	return join $sep, @values;
    } else {
	my $val = $head->get($tag);
	return undef unless defined $val;
	$val = MIME::EncWords::decode_mimewords($val, Charset => 'UTF-8');
	chomp $val;
	return $val;
    }
}

sub fix_children {
}
1;
