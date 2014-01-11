# admin.pm - This module includes administrative function for the lists
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod 

=head1 NAME 

I<admin.pm> - This module includes administrative function for the lists.

=head1 DESCRIPTION 

Central module for creating and editing lists.

=cut 

package admin;

use strict;

use List;
use Conf;
use Language;
use Log;
use tools;
use Sympa::Constants;
use File::Copy;
use Data::Dumper;

=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by admin.pm 

=cut 

=pod 

=head2 sub create_list_old(HASHRef,STRING,STRING)

Creates a list. Used by the create_list() sub in sympa.pl and the do_create_list() sub in wwsympa.fcgi.

=head3 Arguments 

=over 

=item * I<$param>, a ref on a hash containing parameters of the config list. The following keys are mandatory:

=over 4

=item - I<$param-E<gt>{'listname'}>,

=item - I<$param-E<gt>{'subject'}>,

=item - I<$param-E<gt>{'owner'}>, (or owner_include): array of hashes, with key email mandatory

=item - I<$param-E<gt>{'owner_include'}>, array of hashes, with key source mandatory

=back

=item * I<$template>, a string containing the list creation template

=item * I<$robot>, a string containing the name of the robot the list will be hosted by.

=back 

=head3 Return 

=over 

=item * I<undef>, if something prevents the list creation

=item * I<a reference to a hash>, if the list is normally created. This hash contains two keys:

=over 4

=item - I<list>, the list object corresponding to the list just created

=item - I<aliases>, undef if not applicable; 1 (if ok) or $aliases : concatenated string of aliases if they are not installed or 1 (in status open)

=back

=back 

=head3 Calls 

=item * check_owner_defined

=item * check_topics

=item * install_aliases

=item * list_check_smtp

=item * Conf::get_robot_conf

=item * Language::gettext_strftime

=item * List::create_shared

=item * List::has_include_data_sources

=item * List::sync_includetools::get_filename

=item * Log::do_log

=item * tools::get_regexp

=item * tools::make_tt2_include_path

=item * tt2::parse_tt2 

=back 

=cut 

########################################################
# create_list_old                                       
########################################################  
# Create a list : used by sympa.pl--create_list and 
#                 wwsympa.fcgi--do_create_list
# without family concept
# 
# IN  : - $param : ref on parameters of the config list
#         with obligatory :
#         $param->{'listname'}
#         $param->{'subject'}
#         $param->{'owner'} (or owner_include): 
#          array of hash,with key email obligatory
#         $param->{'owner_include'} array of hash :
#              with key source obligatory
#       - $template : the create list template 
#       - $robot : the list's robot       
#       - $origin : the source of the command : web, soap or command_line  
#              no longer used
# OUT : - hash with keys :
#          -list :$list
#          -aliases : undef if not applicable; 1 (if ok) or
#           $aliases : concated string of alias if they 
#           are not installed or 1(in status open)
#######################################################
sub create_list_old{
    my ($param,$template,$robot,$origin, $user_mail) = @_;
    &Log::do_log('debug', 'admin::create_list_old(%s,%s)',$param->{'listname'},$robot,$origin);

     ## obligatory list parameters 
    foreach my $arg ('listname','subject') {
	unless ($param->{$arg}) {
	    &Log::do_log('err','admin::create_list_old : missing list param %s', $arg);
	    return undef;
	}
    }
    # owner.email || owner_include.source
    unless (&check_owner_defined($param->{'owner'},$param->{'owner_include'})) {
	&Log::do_log('err','admin::create_list_old : problem in owner definition in this list creation');
	return undef;
    }


    # template
    unless ($template) {
	&Log::do_log('err','admin::create_list_old : missing param "template"', $template);
	return undef;
    }
    # robot
    unless ($robot) {
	&Log::do_log('err','admin::create_list_old : missing param "robot"', $robot);
	return undef;
    }
   
    ## check listname
    $param->{'listname'} = lc ($param->{'listname'});
    my $listname_regexp = &tools::get_regexp('listname');

    unless ($param->{'listname'} =~ /^$listname_regexp$/i) {
	&Log::do_log('err','admin::create_list_old : incorrect listname %s', $param->{'listname'});
	return undef;
    }

    my $regx = &Conf::get_robot_conf($robot,'list_check_regexp');
    if( $regx ) {
	if ($param->{'listname'} =~ /^(\S+)-($regx)$/) {
	    &Log::do_log('err','admin::create_list_old : incorrect listname %s matches one of service aliases', $param->{'listname'});
	    return undef;
	}
    }    

    if ($param->{'listname'} eq &Conf::get_robot_conf($robot,'email')) {
	Log::do_log('err','admin::create_list : incorrect listname %s matches one of service aliases', $param->{'listname'});
	return undef;
    }

    ## Check listname on SMTP server
    my $res = &list_check_smtp($param->{'listname'}, $robot);
    unless (defined $res) {
	&Log::do_log('err', "admin::create_list_old : can't check list %.128s on %s",
		$param->{'listname'}, $robot);
	return undef;
    }
    
    ## Check this listname doesn't exist already.
    if( $res || new List ($param->{'listname'}, $robot, {'just_try' => 1})) {
	&Log::do_log('err', 'admin::create_list_old : could not create already existing list %s on %s for ', 
		$param->{'listname'}, $robot);
	foreach my $o (@{$param->{'owner'}}){
	    &Log::do_log('err',$o->{'email'});
	}
	return undef;
    }


    ## Check the template supposed to be used exist.
    my $template_file = &tools::get_filename('etc',{},'create_list_templates/'.$template.'/config.tt2', $robot);
    unless (defined $template_file) {
	&Log::do_log('err', 'no template %s found',$template);
	return undef;
    }

     ## Create the list directory
     my $list_dir;

     # a virtual robot
     if (-d "$Conf::Conf{'home'}/$robot") {
	 unless (-d $Conf::Conf{'home'}.'/'.$robot) {
	     unless (mkdir ($Conf::Conf{'home'}.'/'.$robot,0777)) {
		 &Log::do_log('err', 'admin::create_list_old : unable to create %s/%s : %s',$Conf::Conf{'home'},$robot,$?);
		 return undef;
	     }    
	 }
	 $list_dir = $Conf::Conf{'home'}.'/'.$robot.'/'.$param->{'listname'};
     }else {
	 $list_dir = $Conf::Conf{'home'}.'/'.$param->{'listname'};
     }

    ## Check the privileges on the list directory
     unless (mkdir ($list_dir,0777)) {
	 &Log::do_log('err', 'admin::create_list_old : unable to create %s : %s',$list_dir,$?);
	 return undef;
     }    
    
    ## Check topics
    if ($param->{'topics'}){
	unless (&check_topics($param->{'topics'},$robot)){
	    &Log::do_log('err', 'admin::create_list_old : topics param %s not defined in topics.conf',$param->{'topics'});
	}
    }
      
    ## Creation of the config file
    my $host = &Conf::get_robot_conf($robot, 'host');
    $param->{'creation'}{'date'} = gettext_strftime "%d %b %Y at %H:%M:%S", localtime(time);
    $param->{'creation'}{'date_epoch'} = time;
    $param->{'creation_email'} = "listmaster\@$host" unless ($param->{'creation_email'});
    $param->{'status'} = 'open'  unless ($param->{'status'});
       
    my $tt2_include_path = &tools::make_tt2_include_path($robot,'create_list_templates/'.$template,'','');

    ## Lock config before openning the config file
    my $lock = new Lock ($list_dir.'/config');
    unless (defined $lock) {
	&Log::do_log('err','Lock could not be created');
	return undef;
    }
    $lock->set_timeout(5); 
    unless ($lock->lock('write')) {
	return undef;
    }
    unless (open CONFIG, '>', "$list_dir/config") {
	Log::do_log('err','Impossible to create %s/config : %s', $list_dir, $!);
	$lock->unlock();
	return undef;
    }
    ## Use an intermediate handler to encode to filesystem_encoding
    my $config = '';
    my $fd = new IO::Scalar \$config;    
    &tt2::parse_tt2($param, 'config.tt2', $fd, $tt2_include_path);
#    Encode::from_to($config, 'utf8', $Conf::Conf{'filesystem_encoding'});
    print CONFIG $config;

    close CONFIG;
    
    ## Unlock config file
    $lock->unlock();

    ## Creation of the info file 
    # remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
    $param->{'description'} =~ s/\r\n|\r/\n/g;

    ## info file creation.
    unless (open INFO, '>', "$list_dir/info") {
	&Log::do_log('err','Impossible to create %s/info : %s',$list_dir,$!);
    }
    if (defined $param->{'description'}) {
	Encode::from_to($param->{'description'}, 'utf8', $Conf::Conf{'filesystem_encoding'});
	print INFO $param->{'description'};
    }
    close INFO;
    
    ## Create list object
    my $list;
    unless ($list = new List ($param->{'listname'}, $robot)) {
	&Log::do_log('err','admin::create_list_old : unable to create list %s', $param->{'listname'});
	return undef;
    }

    ## Create shared if required
    if (defined $list->{'admin'}{'shared_doc'}) {
	$list->create_shared();
    }

    #log in stat_table to make statistics

    if($origin eq "web"){
	&Log::db_stat_log({'robot' => $robot, 'list' => $param->{'listname'}, 'operation' => 'create list', 'parameter' => '', 'mail' => $user_mail, 'client' => '', 'daemon' => 'wwsympa.fcgi'});
    }

    my $return = {};
    $return->{'list'} = $list;

    if ($list->{'admin'}{'status'} eq 'open') {
	$return->{'aliases'} = &install_aliases($list,$robot);
    }else{
    $return->{'aliases'} = 1;
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
	&Log::do_log('notice', "Synchronizing list members...");
	$list->sync_include();
    }
    
    $list->save_config($param->{'creation_email'});
   return $return;
}

########################################################
# create_list                                      
########################################################  
# Create a list : used by sympa.pl--instantiate_family 
# with family concept
# 
# IN  : - $param : ref on parameters of the config list
#         with obligatory :
#         $param->{'listname'}
#         $param->{'subject'}
#         $param->{'owner'} (or owner_include): 
#          array of hash,with key email obligatory
#         $param->{'owner_include'} array of hash :
#              with key source obligatory
#       - $family : the family object 
#       - $robot : the list's robot         
#       - $abort_on_error : won't create the list directory on
#          tt2 process error (usefull for dynamic lists that
#          throw exceptions)
# OUT : - hash with keys :
#          -list :$list
#          -aliases : undef if not applicable; 1 (if ok) or
#           $aliases : concated string of alias if they 
#           are not installed or 1(in status open)
#######################################################
sub create_list{
    my ($param,$family,$robot, $abort_on_error) = @_;
    &Log::do_log('info', 'admin::create_list(%s,%s,%s)',$param->{'listname'},$family->{'name'},$param->{'subject'});

    ## mandatory list parameters 
    foreach my $arg ('listname') {
	unless ($param->{$arg}) {
	    &Log::do_log('err','admin::create_list : missing list param %s', $arg);
	    return undef;
	}
    }

    unless ($family) {
	&Log::do_log('err','admin::create_list : missing param "family"');
	return undef;
    }

    #robot
    unless ($robot) {
	&Log::do_log('err','admin::create_list : missing param "robot"', $robot);
	return undef;
    }
   
    ## check listname
    $param->{'listname'} = lc ($param->{'listname'});
    my $listname_regexp = &tools::get_regexp('listname');

    unless ($param->{'listname'} =~ /^$listname_regexp$/i) {
	&Log::do_log('err','admin::create_list : incorrect listname %s', $param->{'listname'});
	return undef;
    }

    my $regx = &Conf::get_robot_conf($robot,'list_check_regexp');
    if( $regx ) {
	if ($param->{'listname'} =~ /^(\S+)-($regx)$/) {
	    &Log::do_log('err','admin::create_list : incorrect listname %s matches one of service aliases', $param->{'listname'});
	    return undef;
	}
    }    
    if ($param->{'listname'} eq &Conf::get_robot_conf($robot,'email')) {
	Log::do_log('err','admin::create_list : incorrect listname %s matches one of service aliases', $param->{'listname'});
	return undef;
    }

    ## Check listname on SMTP server
    my $res = &list_check_smtp($param->{'listname'}, $robot);
    unless (defined $res) {
	&Log::do_log('err', "admin::create_list : can't check list %.128s on %s",
		$param->{'listname'}, $robot);
	return undef;
    }

    if ($res) {
	&Log::do_log('err', 'admin::create_list : could not create already existing list %s on %s for ', $param->{'listname'}, $robot);
	foreach my $o (@{$param->{'owner'}}){
	    &Log::do_log('err',$o->{'email'});
	}
	return undef;
    }

    ## template file
    my $template_file = &tools::get_filename('etc',{},'config.tt2', $robot,$family);
    unless (defined $template_file) {
	&Log::do_log('err', 'admin::create_list : no config template from family %s@%s',$family->{'name'},$robot);
	return undef;
    }

    my $family_config = &Conf::get_robot_conf($robot,'automatic_list_families');
    $param->{'family_config'} = $family_config->{$family->{'name'}};
    my $conf;
    my $tt_result = &tt2::parse_tt2($param, 'config.tt2', \$conf, [$family->{'dir'}]);
    unless (defined $tt_result || !$abort_on_error) {
      &Log::do_log('err', 'admin::create_list : abort on tt2 error. List %s from family %s@%s',
                $param->{'listname'}, $family->{'name'},$robot);
      return undef;
    }
    
     ## Create the list directory
     my $list_dir;

    if (-d "$Conf::Conf{'home'}/$robot") {
	unless (-d $Conf::Conf{'home'}.'/'.$robot) {
	    unless (mkdir ($Conf::Conf{'home'}.'/'.$robot,0777)) {
		&Log::do_log('err', 'admin::create_list : unable to create %s/%s : %s',$Conf::Conf{'home'},$robot,$?);
		return undef;
	    }    
	}
	$list_dir = $Conf::Conf{'home'}.'/'.$robot.'/'.$param->{'listname'};
    }else {
	$list_dir = $Conf::Conf{'home'}.'/'.$param->{'listname'};
    }

     unless (-r $list_dir || mkdir ($list_dir,0777)) {
	 &Log::do_log('err', 'admin::create_list : unable to create %s : %s',$list_dir,$?);
	 return undef;
     }    
    
    ## Check topics
    if (defined $param->{'topics'}){
	unless (&check_topics($param->{'topics'},$robot)){
	    &Log::do_log('err', 'admin::create_list : topics param %s not defined in topics.conf',$param->{'topics'});
	}
    }
      
    ## Lock config before openning the config file
    my $lock = new Lock ($list_dir.'/config');
    unless (defined $lock) {
	&Log::do_log('err','Lock could not be created');
	return undef;
    }
    $lock->set_timeout(5); 
    unless ($lock->lock('write')) {
	return undef;
    }

    ## Creation of the config file
    unless (open CONFIG, '>', "$list_dir/config") {
	Log::do_log('err','Impossible to create %s/config : %s', $list_dir, $!);
	$lock->unlock();
	return undef;
    }
    #&tt2::parse_tt2($param, 'config.tt2', \*CONFIG, [$family->{'dir'}]);
    print CONFIG $conf;
    close CONFIG;
    
    ## Unlock config file
    $lock->unlock();

    ## Creation of the info file 
    # remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
    $param->{'description'} =~ s/\r\n|\r/\n/g;

    unless (open INFO, '>', "$list_dir/info") {
	&Log::do_log('err','Impossible to create %s/info : %s', $list_dir, $!);
    }
    if (defined $param->{'description'}) {
	print INFO $param->{'description'};
    }
    close INFO;

    ## Create associated files if a template was given.
    for my $file ('message.footer','message.header','message.footer.mime','message.header.mime','info') {
	my $template_file = &tools::get_filename('etc',{},$file.".tt2", $robot,$family);
	if (defined $template_file) {
	    my $file_content;
	    my $tt_result = &tt2::parse_tt2($param, $file.".tt2", \$file_content, [$family->{'dir'}]);
	    unless (defined $tt_result) {
		&Log::do_log('err', 'admin::create_list : tt2 error. List %s from family %s@%s, file %s',
			$param->{'listname'}, $family->{'name'},$robot,$file);
	    }
	    unless (open FILE, '>', "$list_dir/$file") {
		&Log::do_log('err','Impossible to create %s/%s : %s',$list_dir,$file,$!);
	    }
	    print FILE $file_content;
	    close FILE;
	}
    }

    ## Create list object
    my $list;
    unless ($list = new List ($param->{'listname'}, $robot)) {
	&Log::do_log('err','admin::create_list : unable to create list %s', $param->{'listname'});
	return undef;
    }

    ## Create shared if required
    if (defined $list->{'admin'}{'shared_doc'}) {
	$list->create_shared();
    }   
    
    $list->{'admin'}{'creation'}{'date'} = gettext_strftime "%d %b %Y at %H:%M:%S", localtime(time);
    $list->{'admin'}{'creation'}{'date_epoch'} = time;
    if ($param->{'creation_email'}) {
	$list->{'admin'}{'creation'}{'email'} = $param->{'creation_email'};
    } else {
	my $host = &Conf::get_robot_conf($robot, 'host');
	$list->{'admin'}{'creation'}{'email'} = "listmaster\@$host";
    }
    if ($param->{'status'}) {
	$list->{'admin'}{'status'} = $param->{'status'};
    } else {
	$list->{'admin'}{'status'} = 'open';
    }
    $list->{'admin'}{'family_name'} = $family->{'name'};

    my $return = {};
    $return->{'list'} = $list;

    if ($list->{'admin'}{'status'} eq 'open') {
	$return->{'aliases'} = &install_aliases($list,$robot);
    }else{
    $return->{'aliases'} = 1;
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
	&Log::do_log('notice', "Synchronizing list members...");
	$list->sync_include();
    }

    return $return;
}

########################################################
# update_list                                      
########################################################  
# update a list : used by sympa.pl--instantiate_family 
# with family concept when the list already exists
# 
# IN  : - $list : the list to update
#       - $param : ref on parameters of the new 
#          config list with obligatory :
#         $param->{'listname'}
#         $param->{'subject'}
#         $param->{'owner'} (or owner_include): 
#          array of hash,with key email obligatory
#         $param->{'owner_include'} array of hash :
#              with key source obligatory
#       - $family : the family object 
#       - $robot : the list's robot         
#
# OUT : - $list : the updated list or undef
#######################################################
sub update_list{
    my ($list,$param,$family,$robot) = @_;
    &Log::do_log('info', 'admin::update_list(%s,%s,%s)',$param->{'listname'},$family->{'name'},$param->{'subject'});

    ## mandatory list parameters
    foreach my $arg ('listname') {
	unless ($param->{$arg}) {
	    &Log::do_log('err','admin::update_list : missing list param %s', $arg);
	    return undef;
	}
    }

    ## template file
    my $template_file = &tools::get_filename('etc',{}, 'config.tt2', $robot,$family);
    unless (defined $template_file) {
	&Log::do_log('err', 'admin::update_list : no config template from family %s@%s',$family->{'name'},$robot);
	return undef;
    }

    ## Check topics
    if (defined $param->{'topics'}){
	unless (&check_topics($param->{'topics'},$robot)){
	    &Log::do_log('err', 'admin::update_list : topics param %s not defined in topics.conf',$param->{'topics'});
	}
    }

    ## Lock config before openning the config file
    my $lock = new Lock ($list->{'dir'}.'/config');
    unless (defined $lock) {
	&Log::do_log('err','Lock could not be created');
	return undef;
    }
    $lock->set_timeout(5); 
    unless ($lock->lock('write')) {
	return undef;
    }

    ## Creation of the config file
    unless (open CONFIG, '>', "$list->{'dir'}/config") {
	Log::do_log('err','Impossible to create %s/config : %s', $list->{'dir'}, $!);
	$lock->unlock();
	return undef;
    }
    &tt2::parse_tt2($param, 'config.tt2', \*CONFIG, [$family->{'dir'}]);
    close CONFIG;

    ## Unlock config file
    $lock->unlock();

    ## Create list object
    unless ($list = new List ($param->{'listname'}, $robot)) {
	&Log::do_log('err','admin::create_list : unable to create list %s', $param->{'listname'});
	return undef;
    }
############## ? update
    $list->{'admin'}{'creation'}{'date'} = gettext_strftime "%d %b %Y at %H:%M:%S", localtime(time);
    $list->{'admin'}{'creation'}{'date_epoch'} = time;
    if ($param->{'creation_email'}) {
	$list->{'admin'}{'creation'}{'email'} = $param->{'creation_email'};
    } else {
	my $host = &Conf::get_robot_conf($robot, 'host');
	$list->{'admin'}{'creation'}{'email'} = "listmaster\@$host";
    }

    if ($param->{'status'}) {
	$list->{'admin'}{'status'} = $param->{'status'};
    } else {
	$list->{'admin'}{'status'} = 'open';
    }
    $list->{'admin'}{'family_name'} = $family->{'name'};

   ## Create associated files if a template was given.
    for my $file ('message.footer','message.header','message.footer.mime','message.header.mime','info') {
	my $template_file = &tools::get_filename('etc',{},$file.".tt2", $robot,$family);
	if (defined $template_file) {
	    my $file_content;
	    my $tt_result = &tt2::parse_tt2($param, $file.".tt2", \$file_content, [$family->{'dir'}]);
	    unless (defined $tt_result) {
		Log::do_log('err', 'admin::create_list : tt2 error. List %s from family %s@%s, file %s',
			$param->{'listname'}, $family->{'name'},$robot,$file);
	    }
	    unless (open FILE, '>', "$list->{'dir'}/$file") {
		Log::do_log('err','Impossible to create %s/%s : %s',$list->{'dir'},$file,$!);
	    }
	    print FILE $file_content;
	    close FILE;
	}
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
	&Log::do_log('notice', "Synchronizing list members...");
	$list->sync_include();
    }

    return $list;
}

########################################################
# rename_list                                      
########################################################  
# Rename a list or move a list to another virtual host
# 
# IN  : - list
#       - new_listname
#       - new_robot
#       - mode  : 'copy' 
#       - auth_method
#       - user_email
#       - remote_host
#       - remote_addr
#       - options : 'skip_authz' to skip authorization scenarios eval
#       
# OUT via reference :
#       - aliases
#       - status : 'pending'
#
# OUT : - scalar
#           undef  : error
#           1      : success
#           string : error code
#######################################################
sub rename_list{
    my (%param) = @_;
    &Log::do_log('info', '',);

    my $list = $param{'list'};
    my $robot = $list->{'domain'};
    my $old_listname = $list->{'name'};

    # check new listname syntax
    my $new_listname = lc ($param{'new_listname'});
    my $listname_regexp = &tools::get_regexp('listname');
    
    unless ($new_listname =~ /^$listname_regexp$/i) {
      &Log::do_log('err','incorrect listname %s', $new_listname);
      return 'incorrect_listname';
    }
    
    ## Evaluate authorization scenario unless run as listmaster (sympa.pl)
    my ($result, $r_action, $reason); 
    unless ($param{'options'}{'skip_authz'}) {
      $result = &Scenario::request_action ('create_list',$param{'auth_method'},$param{'new_robot'},
					   {'sender' => $param{'user_email'},
					    'remote_host' => $param{'remote_host'},
					    'remote_addr' => $param{'remote_addr'}});
      
      if (ref($result) eq 'HASH') {
	$r_action = $result->{'action'};
	$reason = $result->{'reason'};
      }
      
      unless ($r_action =~ /do_it|listmaster/) {
	&Log::do_log('err','authorization error');
	return 'authorization';
      }
    }

    ## Check listname on SMTP server
    my $res = list_check_smtp($param{'new_listname'}, $param{'new_robot'});
    unless ( defined($res) ) {
      &Log::do_log('err', "can't check list %.128s on %.128s",
	      $param{'new_listname'}, $param{'new_robot'});
      return 'internal';
    }

    if( $res || 
	($list->{'name'} ne $param{'new_listname'}) && ## Do not test if listname did not change
	(new List ($param{'new_listname'}, $param{'new_robot'}, {'just_try' => 1}))) {
      &Log::do_log('err', 'Could not rename list %s on %s: new list %s on %s already existing list', $list->{'name'}, $robot, $param{'new_listname'}, 	$param{'new_robot'});
      return 'list_already_exists';
    }
    
    my $regx = &Conf::get_robot_conf($param{'new_robot'},'list_check_regexp');
    if( $regx ) {
      if ($param{'new_listname'} =~ /^(\S+)-($regx)$/) {
	&Log::do_log('err','Incorrect listname %s matches one of service aliases', $param{'new_listname'});
	return 'incorrect_listname';
      }
    }

     unless ($param{'mode'} eq 'copy') {
         $list->savestats();
	 
	 ## Dump subscribers
	 $list->_save_list_members_file("$list->{'dir'}/subscribers.closed.dump");
	 
	 $param{'aliases'} = &remove_aliases($list, $list->{'domain'});
     }

     ## Rename or create this list directory itself
     my $new_dir;
     ## Default robot
     if (-d "$Conf::Conf{'home'}/$param{'new_robot'}") {
	 $new_dir = $Conf::Conf{'home'}.'/'.$param{'new_robot'}.'/'.$param{'new_listname'};
     }elsif ($param{'new_robot'} eq $Conf::Conf{'domain'}) {
	 $new_dir = $Conf::Conf{'home'}.'/'.$param{'new_listname'};
     }else {
	 &Log::do_log('err',"Unknown robot $param{'new_robot'}");
	 return 'unknown_robot';
     }

    ## If we are in 'copy' mode, create en new list
    if ($param{'mode'} eq 'copy') {	 
	 unless ( $list = &admin::clone_list_as_empty($list->{'name'},$list->{'domain'},$param{'new_listname'},$param{'new_robot'},$param{'user_email'})){
	     &Log::do_log('err',"Unable to load $param{'new_listname'} while renaming");
	     return 'internal';
	 }	 
     }

    # set list status to pending if creation list is moderated
    if ($r_action =~ /listmaster/) {
      $list->{'admin'}{'status'} = 'pending' ;
      &List::send_notify_to_listmaster('request_list_renaming',$list->{'domain'}, 
				       {'list' => $list,
					'new_listname' => $param{'new_listname'},
					'old_listname' => $old_listname,
					'email' => $param{'user_email'},
					'mode' => $param{'mode'}});
      $param{'status'} = 'pending';
    }
     
    ## Save config file for the new() later to reload it
    $list->save_config($param{'user_email'});
     
    ## This code should be in List::rename()
    unless ($param{'mode'} eq 'copy') {     
	 unless (move ($list->{'dir'}, $new_dir )){
	     &Log::do_log('err',"Unable to rename $list->{'dir'} to $new_dir : $!");
	     return 'internal';
	 }
     
	 ## Rename archive
	 my $arc_dir = &Conf::get_robot_conf($robot, 'arc_path').'/'.$list->get_list_id();
	 my $new_arc_dir = &Conf::get_robot_conf($param{'new_robot'}, 'arc_path').'/'.$param{'new_listname'}.'@'.$param{'new_robot'};
	 if (-d $arc_dir && $arc_dir ne $new_arc_dir) {
	     unless (move ($arc_dir,$new_arc_dir)) {
		 &Log::do_log('err',"Unable to rename archive $arc_dir");
		 # continue even if there is some troubles with archives
		 # return undef;
	     }
	 }

	 ## Rename bounces
	 my $bounce_dir = $list->get_bounce_dir();
	 my $new_bounce_dir = &Conf::get_robot_conf($param{'new_robot'}, 'bounce_path').'/'.$param{'new_listname'}.'@'.$param{'new_robot'};
	 if (-d $bounce_dir && $bounce_dir ne $new_bounce_dir) {
	     unless (move ($bounce_dir,$new_bounce_dir)) {
		 &Log::do_log('err',"Unable to rename bounces from $bounce_dir to $new_bounce_dir");
	     }
	 }
	 
	 # if subscribtion are stored in database rewrite the database
	 &List::rename_list_db($list, $param{'new_listname'},
			       $param{'new_robot'});
     }
     ## Move stats
    unless (&SDM::do_query("UPDATE stat_table SET list_stat=%s, robot_stat=%s WHERE (list_stat = %s AND robot_stat = %s )", 
    &SDM::quote($param{'new_listname'}), 
    &SDM::quote($param{'new_robot'}), 
    &SDM::quote($list->{'name'}), 
    &SDM::quote($robot)
    )) {
	&Log::do_log('err','Unable to transfer stats from list %s@%s to list %s@%s',$param{'new_listname'}, $param{'new_robot'}, $list->{'name'}, $robot);
    }

     ## Move stat counters
    unless (&SDM::do_query("UPDATE stat_counter_table SET list_counter=%s, robot_counter=%s WHERE (list_counter = %s AND robot_counter = %s )", 
    &SDM::quote($param{'new_listname'}), 
    &SDM::quote($param{'new_robot'}), 
    &SDM::quote($list->{'name'}), 
    &SDM::quote($robot)
    )) {
	&Log::do_log('err','Unable to transfer stat counter from list %s@%s to list %s@%s',$param{'new_listname'}, $param{'new_robot'}, $list->{'name'}, $robot);
    }

     ## Install new aliases
     $param{'listname'} = $param{'new_listname'};
     
     unless ($list = new List ($param{'new_listname'}, $param{'new_robot'},{'reload_config' => 1})) {
	 &Log::do_log('err',"Unable to load $param{'new_listname'} while renaming");
	 return 'internal';
     }
     
     ## Check custom_subject
     if (defined $list->{'admin'}{'custom_subject'} &&
	 $list->{'admin'}{'custom_subject'} =~ /$old_listname/) {
	 $list->{'admin'}{'custom_subject'} =~ s/$old_listname/$param{'new_listname'}/g;

	 $list->save_config($param{'user_email'});	
     }

     if ($list->{'admin'}{'status'} eq 'open') {
      	 $param{'aliases'} = &admin::install_aliases($list,$robot);
     } 
     
     unless ($param{'mode'} eq 'copy') {

	 ## Rename files in spools
	 ## Auth & Mod  spools
	 foreach my $spool ('queueauth','queuemod','queuetask','queuebounce',
			'queue','queueoutgoing','queuesubscribe','queueautomatic') {
	     unless (opendir(DIR, $Conf::Conf{$spool})) {
		 &Log::do_log('err', "Unable to open '%s' spool : %s", $Conf::Conf{$spool}, $!);
	     }
	     
	     foreach my $file (sort readdir(DIR)) {
		 next unless ($file =~ /^$old_listname\_/ ||
			      $file =~ /^$old_listname\./ ||
			      $file =~ /^$old_listname\@$robot\./ ||
			      $file =~ /^\.$old_listname\@$robot\_/ ||
			      $file =~ /^$old_listname\@$robot\_/ ||
			      $file =~ /\.$old_listname$/);
		 
		 my $newfile = $file;
		 if ($file =~ /^$old_listname\_/) {
		     $newfile =~ s/^$old_listname\_/$param{'new_listname'}\_/;
		 }elsif ($file =~ /^$old_listname\./) {
		     $newfile =~ s/^$old_listname\./$param{'new_listname'}\./;
		 }elsif ($file =~ /^$old_listname\@$robot\./) {
		     $newfile =~ s/^$old_listname\@$robot\./$param{'new_listname'}\@$param{'new_robot'}\./;
		 }elsif ($file =~ /^$old_listname\@$robot\_/) {
		     $newfile =~ s/^$old_listname\@$robot\_/$param{'new_listname'}\@$param{'new_robot'}\_/;
		 }elsif ($file =~ /^\.$old_listname\@$robot\_/) {
		     $newfile =~ s/^\.$old_listname\@$robot\_/\.$param{'new_listname'}\@$param{'new_robot'}\_/;
		 }elsif ($file =~ /\.$old_listname$/) {
		     $newfile =~ s/\.$old_listname$/\.$param{'new_listname'}/;
		 }
		 
		 ## Rename file
		 unless (move "$Conf::Conf{$spool}/$file", "$Conf::Conf{$spool}/$newfile") {
		     &Log::do_log('err', "Unable to rename %s to %s : %s", "$Conf::Conf{$spool}/$newfile", "$Conf::Conf{$spool}/$newfile", $!);
		     next;
		 }
		 
		 ## Change X-Sympa-To
		 &tools::change_x_sympa_to("$Conf::Conf{$spool}/$newfile", "$param{'new_listname'}\@$param{'new_robot'}");
	     }
	     
	     close DIR;
	 } 
	 ## Digest spool
	 if (-f "$Conf::Conf{'queuedigest'}/$old_listname") {
	     unless (move "$Conf::Conf{'queuedigest'}/$old_listname", "$Conf::Conf{'queuedigest'}/$param{'new_listname'}") {
		 &Log::do_log('err', "Unable to rename %s to %s : %s", "$Conf::Conf{'queuedigest'}/$old_listname", "$Conf::Conf{'queuedigest'}/$param{'new_listname'}", $!);
		 next;
	     }
	 }elsif (-f "$Conf::Conf{'queuedigest'}/$old_listname\@$robot") {
	     unless (move "$Conf::Conf{'queuedigest'}/$old_listname\@$robot", "$Conf::Conf{'queuedigest'}/$param{'new_listname'}\@$param{'new_robot'}") {
		 &Log::do_log('err', "Unable to rename %s to %s : %s", "$Conf::Conf{'queuedigest'}/$old_listname\@$robot", "$Conf::Conf{'queuedigest'}/$param{'new_listname'}\@$param{'new_robot'}", $!);
		 next;
	     }
	 }     
     }

    return 1;
  }

########################################################
# clone_list_as_empty {                          
########################################################  
# Clone a list config including customization, templates, scenario config
# but without archives, subscribers and shared
# 
# IN  : - $source_list_name : the list to clone
#       - $source_robot : robot of the list to clone
#       - $new_listname : the target listname         
#       - $new_robot : the target list's robot
#       - $email : the email of the requestor : used in config as admin->last_update->email         
#
# OUT : - $list : the updated list or undef
##
sub clone_list_as_empty {
    
    my $source_list_name =shift;
    my $source_robot =shift;
    my $new_listname = shift;
    my $new_robot = shift;
    my $email = shift;

    my $list;
    unless ($list = new List ($source_list_name, $source_robot)) {
	&Log::do_log('err','Admin::clone_list_as_empty : new list failed %s %s',$source_list_name, $source_robot);
	return undef;;
    }    
    
    &Log::do_log('info',"Admin::clone_list_as_empty ($source_list_name, $source_robot,$new_listname,$new_robot,$email)");
    
    my $new_dir;
    if (-d $Conf::Conf{'home'}.'/'.$new_robot) {
	$new_dir = $Conf::Conf{'home'}.'/'.$new_robot.'/'.$new_listname;
    }elsif ($new_robot eq $Conf::Conf{'domain'}) {
	$new_dir = $Conf::Conf{'home'}.'/'.$new_listname;
    }else {
	&Log::do_log('err',"Admin::clone_list_as_empty : unknown robot $new_robot");
	return undef;
    }
    
    unless (mkdir $new_dir, 0775) {
	&Log::do_log('err','Admin::clone_list_as_empty : failed to create directory %s : %s',$new_dir, $!);
	return undef;;
    }
    chmod 0775, $new_dir;
    foreach my $subdir ('etc','web_tt2','mail_tt2','data_sources' ) {
	if (-d $new_dir.'/'.$subdir) {
	    unless (&tools::copy_dir($list->{'dir'}.'/'.$subdir, $new_dir.'/'.$subdir)) {
		&Log::do_log('err','Admin::clone_list_as_empty :  failed to copy_directory %s : %s',$new_dir.'/'.$subdir, $!);
		return undef;
	    }
	}
    }
    # copy mandatory files
    foreach my $file ('config') {
	    unless (&File::Copy::copy ($list->{'dir'}.'/'.$file, $new_dir.'/'.$file)) {
		&Log::do_log('err','Admin::clone_list_as_empty : failed to copy %s : %s',$new_dir.'/'.$file, $!);
		return undef;
	    }
    }
    # copy optional files
    foreach my $file ('message.footer','message.header','info','homepage') {
	if (-f $list->{'dir'}.'/'.$file) {
	    unless (&File::Copy::copy ($list->{'dir'}.'/'.$file, $new_dir.'/'.$file)) {
		&Log::do_log('err','Admin::clone_list_as_empty : failed to copy %s : %s',$new_dir.'/'.$file, $!);
		return undef;
	    }
	}
    }

    my $new_list;
    # now switch List object to new list, update some values
    unless ($new_list = new List ($new_listname, $new_robot,{'reload_config' => 1})) {
	&Log::do_log('info',"Admin::clone_list_as_empty : unable to load $new_listname while renamming");
	return undef;
    }
    $new_list->{'admin'}{'serial'} = 0 ;
    $new_list->{'admin'}{'creation'}{'email'} = $email if ($email);
    $new_list->{'admin'}{'creation'}{'date_epoch'} = time;
    $new_list->{'admin'}{'creation'}{'date'} = gettext_strftime "%d %b %y at %H:%M:%S", localtime(time);
    $new_list->save_config($email);
    return $new_list;
}


########################################################
# check_owner_defined                                     
########################################################  
# verify if they are any owner defined : it must exist
# at least one param owner(in $owner) or one param 
# owner_include (in $owner_include)
# the owner param must have sub param email
# the owner_include param must have sub param source
# 
# IN  : - $owner : ref on array of hash
#                  or
#                  ref on hash
#       - $owner_include : ref on array of hash
#                          or
#                          ref on hash
# OUT : - 1 if exists owner(s)
#         or
#         undef if no owner defined
######################################################### 
sub check_owner_defined {
    my ($owner,$owner_include) = @_;
    &Log::do_log('debug2',"admin::check_owner_defined()");
    
    if (ref($owner) eq "ARRAY") {
	if (ref($owner_include) eq "ARRAY") {
	    if (($#{$owner} < 0) && ($#{$owner_include} <0)) {
		&Log::do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	} else {
	    if (($#{$owner} < 0) && !($owner_include)) {
		&Log::do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	}
    } else {
	if (ref($owner_include) eq "ARRAY") {
	    if (!($owner) && ($#{$owner_include} <0)) {
		&Log::do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	}else {
	    if (!($owner) && !($owner_include)) {
		&Log::do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	}
    }
    
    if (ref($owner) eq "ARRAY") {
	foreach my $o (@{$owner}) {
	    unless($o){ 
		&Log::do_log('err','empty param "owner"');
		return undef;
	    }
	    unless ($o->{'email'}) {
		&Log::do_log('err','missing sub param "email" for param "owner"');
		return undef;
	    }
	}
    } elsif (ref($owner) eq "HASH"){
	unless ($owner->{'email'}) {
	    &Log::do_log('err','missing sub param "email" for param "owner"');
	    return undef;
	}
    } elsif (defined $owner) {
	&Log::do_log('err','missing sub param "email" for param "owner"');
	return undef;
    }	
    
    if (ref($owner_include) eq "ARRAY") {
	foreach my $o (@{$owner_include}) {
	    unless($o){ 
		&Log::do_log('err','empty param "owner_include"');
		return undef;
	    }
	    unless ($o->{'source'}) {
		&Log::do_log('err','missing sub param "source" for param "owner_include"');
		return undef;
	    }
	} 
    }elsif (ref($owner_include) eq "HASH"){
	unless ($owner_include->{'source'}) {
	    &Log::do_log('err','missing sub param "source" for param "owner_include"');
	    return undef;
	}
    } elsif (defined $owner_include) {
	&Log::do_log('err','missing sub param "source" for param "owner_include"');
	return undef;
    }	
    return 1;
}


#####################################################
# list_check_smtp
#####################################################  
# check if the requested list exists already using 
#   smtp 'rcpt to'
#
# IN  : - $list : name of the list
#       - $robot : list's robot
# OUT : - Net::SMTP object or 0 
#####################################################
 sub list_check_smtp {
     my $list = shift;
     my $robot = shift;
     &Log::do_log('debug2', 'admin::list_check_smtp(%s,%s)',$list,$robot);

     my $conf = '';
     my $smtp;
     my (@suf, @addresses);

     my $smtp_relay = &Conf::get_robot_conf($robot, 'list_check_smtp');
     my $smtp_helo = &Conf::get_robot_conf($robot, 'list_check_helo') || $smtp_relay;
     $smtp_helo =~ s/:[-\w]+$//;
     my $suffixes = &Conf::get_robot_conf($robot, 'list_check_suffixes');
     return 0 
	 unless ($smtp_relay && $suffixes);
     my $domain = &Conf::get_robot_conf($robot, 'host');
     &Log::do_log('debug2', 'list_check_smtp(%s,%s)', $list, $robot);
     @suf = split(/,/,$suffixes);
     return 0 if ! @suf;
     for(@suf) {
	 push @addresses, $list."-$_\@".$domain;
     }
     push @addresses,"$list\@" . $domain;

     eval { require Net::SMTP; };
     if ($@) {
	 &Log::do_log ('err',"admin::list_check_smtp : Unable to use Net library, Net::SMTP required, install it (CPAN) first");
	 return undef;
     }
     if( $smtp = Net::SMTP->new($smtp_relay,
				Hello => $smtp_helo,
				Timeout => 30) ) {
	 $smtp->mail('');
	 for(@addresses) {
		 $conf = $smtp->to($_);
		 last if $conf;
	 }
	 $smtp->quit();
	 return $conf;
    }
    return undef;
 }


##########################################################
# install_aliases
##########################################################  
# Install sendmail aliases for $list
#
# IN  : - $list : object list
#       - $robot : the list's robot
# OUT : - undef if not applicable or aliases not installed
#         1 (if ok) or
##########################################################
sub install_aliases {
    my $list = shift;
    my $robot = shift;
    &Log::do_log('debug', "admin::install_aliases($list->{'name'},$robot)");

    return 1
	if Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') =~ /^none$/i;

    my $alias_manager = $Conf::Conf{'alias_manager' };
    my $output_file = $Conf::Conf{'tmpdir'}.'/aliasmanager.stdout.'.$$;
    my $error_output_file = $Conf::Conf{'tmpdir'}.'/aliasmanager.stderr.'.$$;
    &Log::do_log('debug2',"admin::install_aliases : $alias_manager add $list->{'name'} $list->{'admin'}{'host'}");
 
    unless (-x $alias_manager) {
		&Log::do_log('err','admin::install_aliases : Failed to install aliases: %s', $!);
		return undef;
	}
	 system ("$alias_manager add $list->{'name'} $list->{'admin'}{'host'} >$output_file 2>  $error_output_file") ;
	 my $status = $? / 256;
	 if ($status == 0) {
	     &Log::do_log('info','admin::install_aliases : Aliases installed successfully') ;
	     return 1;
     }

	## get error code
	my $error_output;
	open ERR, $error_output_file;
	while (<ERR>) {
		$error_output .= $_;
	}
	close ERR;
	unlink $error_output_file;

     if ($status == 1) {
		&Log::do_log('err','Configuration file %s has errors : %s', Sympa::Constants::CONFIG, $error_output);
     }elsif ($status == 2)  {
         &Log::do_log('err','admin::install_aliases : Internal error : Incorrect call to alias_manager : %s', $error_output);
     }elsif ($status == 3)  {
	     &Log::do_log('err','admin::install_aliases : Could not read sympa config file, report to httpd error_log: %s', $error_output) ;
	 }elsif ($status == 4)  {
	     &Log::do_log('err','admin::install_aliases : Could not get default domain, report to httpd error_log: %s', $error_output) ;
	 }elsif ($status == 5)  {
	     &Log::do_log('err','admin::install_aliases : Unable to append to alias file: %s', $error_output) ;
	 }elsif ($status == 6)  {
	     &Log::do_log('err','admin::install_aliases : Unable to run newaliases: %s', $error_output) ;
	 }elsif ($status == 7)  {
	     &Log::do_log('err','admin::install_aliases : Unable to read alias file, report to httpd error_log: %s', $error_output) ;
	 }elsif ($status == 8)  {
	     &Log::do_log('err','admin::install_aliases : Could not create temporay file, report to httpd error_log: %s', $error_output) ;
	 }elsif ($status == 13) {
	     &Log::do_log('info','admin::install_aliases : Some of list aliases already exist: %s', $error_output) ;
	 }elsif ($status == 14) {
	     &Log::do_log('err','admin::install_aliases : Can not open lock file, report to httpd error_log: %s', $error_output) ;
	 }elsif ($status == 15) {
	     &Log::do_log('err','The parser returned empty aliases: %s', $error_output) ;
	 }else {
	     &Log::do_log('err',"admin::install_aliases : Unknown error $status while running alias manager $alias_manager : %s", $error_output);
	 } 
    
    return undef;
}


#########################################################
# remove_aliases
#########################################################  
# Remove sendmail aliases for $list
#
# IN  : - $list : object list
#       - $robot : the list's robot
# OUT : - undef if not applicable
#         1 (if ok) or
#         $aliases : concated string of alias not removed
#########################################################

 sub remove_aliases {
     my $list = shift;
     my $robot = shift;
     &Log::do_log('info', "_remove_aliases($list->{'name'},$robot");

    return 1
	if Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') =~ /^none$/i;

     my $status = $list->remove_aliases();
     my $suffix = &Conf::get_robot_conf($robot, 'return_path_suffix');
     my $aliases;

     unless ($status == 1) {
	 &Log::do_log('err','Failed to remove aliases for list %s', $list->{'name'});

	 ## build a list of required aliases the listmaster should install
     my $libexecdir = Sympa::Constants::LIBEXECDIR;
	 $aliases = <<EOF;
#----------------- $list->{'name'}
$list->{'name'}: "$libexecdir/queue $list->{'name'}"
$list->{'name'}-request: "|$libexecdir/queue $list->{'name'}-request"
$list->{'name'}$suffix: "|$libexecdir/bouncequeue $list->{'name'}"
$list->{'name'}-unsubscribe: "|$libexecdir/queue $list->{'name'}-unsubscribe"
# $list->{'name'}-subscribe: "|$libexecdir/queue $list->{'name'}-subscribe"
EOF
	 
	 return $aliases;
     }

     &Log::do_log('info','Aliases removed successfully');

     return 1;
 }


#####################################################
# check_topics
#####################################################  
# Check $topic in the $robot conf
#
# IN  : - $topic : id of the topic
#       - $robot : the list's robot
# OUT : - 1 if the topic is in the robot conf or undef
#####################################################
sub check_topics {
    my $topic = shift;
    my $robot = shift;
    &Log::do_log('info', "admin::check_topics($topic,$robot)");

    my ($top, $subtop) = split /\//, $topic;

    my %topics;
    unless (%topics = &List::load_topics($robot)) {
	&Log::do_log('err','admin::check_topics : unable to load list of topics');
    }

    if ($subtop) {
	return 1 if (defined $topics{$top} && defined $topics{$top}{'sub'}{$subtop});
    }else {
	return 1 if (defined $topics{$top});
    }

    return undef;
}

# change a user email address for both his memberships and ownerships
# 
# IN  : - current_email : current user email address
#       - new_email     : new user email address
#       - robot         : virtual robot
#
# OUT : - status(scalar)          : status of the subroutine
#       - failed_for(arrayref)    : list of lists for which the change could not be done (because user was
#                                   included or for authorization reasons)                 
sub change_user_email {
    my %in = @_;

    my @failed_for;

    unless ($in{'current_email'} && $in{'new_email'} && $in{'robot'}) {
	&Log::do_log('err','Missing incoming parameter');
	return undef;
    }

    ## Change email as list MEMBER
    foreach my $list ( &List::get_which($in{'current_email'},$in{'robot'}, 'member') ) {
	 
	 my $l = $list->{'name'};
	 
	 my $user_entry = $list->get_list_member($in{'current_email'});
	 
	 if ($user_entry->{'included'} == 1) {
	     ## Check the type of data sources
	     ## If only include_list of local mailing lists, then no problem
	     ## Otherwise, notify list owner
	     ## We could also force a sync_include for local lists
	     my $use_external_data_sources;
	     foreach my $datasource_id (split(/,/, $user_entry->{'id'})) {
		 my $datasource = $list->search_datasource($datasource_id);
		 if (!defined $datasource || $datasource->{'type'} ne 'include_list' || ($datasource->{'def'} =~ /\@(.+)$/ && $1 ne $in{'robot'})) {
		     $use_external_data_sources = 1;
		     last;
		 }
	     }
	     if ($use_external_data_sources) {
		 ## Notify list owner
		 $list->send_notify_to_owner('failed_to_change_included_member',
					     {'current_email' => $in{'current_email'}, 
					      'new_email' => $in{'new_email'},
					      'datasource' => $list->get_datasource_name($user_entry->{'id'})});
		 push @failed_for, $list;
		 &Log::do_log('err', 'could not change member email for list %s because member is included', $l);
		 next;
	     }
	 }

	 ## Check if user is already member of the list with his new address
	 ## then we just need to remove the old address
	 if ($list->is_list_member($in{'new_email'})) {
	     unless ($list->delete_list_member('users' => [$in{'current_email'}]) ) {
		 push @failed_for, $list;
		 &Log::do_log('info', 'could not remove email from list %s', $l);		 
	     }
	     
	 }else {
	     
	     unless ($list->update_list_member($in{'current_email'}, {'email' => $in{'new_email'}, 'update_date' => time}) ) {
		 push @failed_for, $list;
		 &Log::do_log('err', 'could not change email for list %s', $l);
	     }
	 }
     }
    
    ## Change email as list OWNER/MODERATOR
    my %updated_lists;
    foreach my $role ('owner', 'editor') { 
	foreach my $list ( &List::get_which($in{'current_email'},$in{'robot'}, $role) ) {
	    
	    ## Check if admin is include via an external datasource
	    my $admin_user = $list->get_list_admin($role, $in{'current_email'});
	    if ($admin_user->{'included'}) {
		## Notify listmaster
		&List::send_notify_to_listmaster('failed_to_change_included_admin',$in{'robot'},{'list' => $list,
											   'current_email' => $in{'current_email'}, 
											   'new_email' => $in{'new_email'},
											   'datasource' => $list->get_datasource_name($admin_user->{'id'})});
		push @failed_for, $list;
		&Log::do_log('err', 'could not change %s email for list %s because admin is included', $role, $list->{'name'});
		next;
	    }
	    
	    ## Go through owners/editors of the list
	    foreach my $admin (@{$list->{'admin'}{$role}}) {
		next unless (lc($admin->{'email'}) eq lc($in{'current_email'}));
		
		## Update entry with new email address
		$admin->{'email'} = $in{'new_email'};
		$updated_lists{$list->{'name'}}++;
	    }
	    
	    ## Update Db cache for the list
	    $list->sync_include_admin();
	    $list->save_config();
	}
    }
    ## Notify listmasters that list owners/moderators email have changed
    if (keys %updated_lists) {
	&List::send_notify_to_listmaster('listowner_email_changed',$in{'robot'}, 
					 {'previous_email' => $in{'current_email'},
					  'new_email' => $in{'new_email'},
					  'updated_lists' => keys %updated_lists})
    }
    
    ## Update User_table and remove existing entry first (to avoid duplicate entries)
    &List::delete_global_user($in{'new_email'},);
    
    unless ( &List::update_global_user($in{'current_email'},
				       {'email' => $in{'new_email'},					
				       })) {
	&Log::do_log('err','change_email: update failed');
	return undef;
    }
    
    ## Update netidmap_table
    unless ( &List::update_email_netidmap_db($in{'robot'}, $in{'current_email'}, $in{'new_email'}) ){
	&Log::do_log('err','change_email: update failed');
	return undef;
    }
    
    
    return (1,\@failed_for);
}

=pod 

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier Salaun <os AT cru.fr> 

=back 

=cut 

1;
