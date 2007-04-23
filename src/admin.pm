# admin.pm - This module includes administrative function for the lists
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

package admin;

use strict;

## Sympa API
use List;
use Conf;
use Language;
use Log;

require "--LIBDIR--/tools.pl";


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
# OUT : - hash with keys :
#          -list :$list
#          -aliases : undef if not applicable; 1 (if ok) or
#           $aliases : concated string of alias if they 
#           are not installed or 1(in status open)
#######################################################
sub create_list_old{
    my ($param,$template,$robot) = @_;
    &do_log('debug', 'admin::create_list_old(%s,%s)',$param->{'listname'},$robot);

     ## obligatory list parameters 
    foreach my $arg ('listname','subject') {
	unless ($param->{$arg}) {
	    &do_log('err','admin::create_list_old : missing list param %s', $arg);
	    return undef;
	}
    }
    # owner.email || owner_include.source
    unless (&check_owner_defined($param->{'owner'},$param->{'owner_include'})) {
	&do_log('err','admin::create_list_old : problem in owner definition in this list creation');
	return undef;
    }


    # template
    unless ($template) {
	&do_log('err','admin::create_list_old : missing param "template"', $template);
	return undef;
    }
    # robot
    unless ($robot) {
	&do_log('err','admin::create_list_old : missing param "robot"', $robot);
	return undef;
    }
   
    ## check listname
    $param->{'listname'} = lc ($param->{'listname'});

    unless ($param->{'listname'} =~ /^$tools::regexp{'listname'}$/i) {
	&do_log('err','admin::create_list_old : incorrect listname %s', $param->{'listname'});
	return undef;
    }

    my $regx = &Conf::get_robot_conf($robot,'list_check_regexp');
    if( $regx ) {
	if ($param->{'listname'} =~ /^(\S+)-($regx)$/) {
	    &do_log('err','admin::create_list_old : incorrect listname %s matches one of service aliases', $param->{'listname'});
	    return undef;
	}
    }    

    ## Check listname on SMTP server
    my $res = &list_check_smtp($param->{'listname'});
    unless (defined $res) {
	&do_log('err', "admin::create_list_old : can't check list %.128s on %.128s",
		$param->{'listname'},
		$Conf{'list_check_smtp'});
	return undef;
    }

    if( $res || new List ($param->{'listname'}, $robot, {'just_try' => 1})) {
	&do_log('err', 'admin::create_list_old : could not create already existing list %s for ', 
		$param->{'listname'});
	foreach my $o (@{$param->{'owner'}}){
	    &do_log('err',$o->{'email'});
	}
	return undef;
    }


    my $template_file = &tools::get_filename('etc',{},'create_list_templates/'.$template.'/config.tt2', $robot);
    unless (defined $template_file) {
	&do_log('err', 'no template %s found',$template);
	return undef;
    }

     ## Create the list directory
     my $list_dir;

     # a virtual robot
     if (-d "$Conf{'home'}/$robot") {
	 unless (-d $Conf{'home'}.'/'.$robot) {
	     unless (mkdir ($Conf{'home'}.'/'.$robot,0777)) {
		 &do_log('err', 'admin::create_list_old : unable to create %s/%s : %s',$Conf{'home'},$robot,$?);
		 return undef;
	     }    
	 }
	 $list_dir = $Conf{'home'}.'/'.$robot.'/'.$param->{'listname'};
     }else {
	 $list_dir = $Conf{'home'}.'/'.$param->{'listname'};
     }

     unless (mkdir ($list_dir,0777)) {
	 &do_log('err', 'admin::create_list_old : unable to create %s : %s',$list_dir,$?);
	 return undef;
     }    
    
    ## Check topics
    if ($param->{'topics'}){
	unless (&check_topics($param->{'topics'},$robot)){
	    &do_log('err', 'admin::create_list_old : topics param %s not defined in topics.conf',$param->{'topics'});
	}
    }
      
    ## Creation of the config file
    my $host = &Conf::get_robot_conf($robot, 'host');
    $param->{'creation'}{'date'} = gettext_strftime "%d %b %Y at %H:%M:%S", localtime(time);
    $param->{'creation'}{'date_epoch'} = time;
    $param->{'creation_email'} = "listmaster\@$host" unless ($param->{'creation_email'});
    $param->{'status'} = 'open'  unless ($param->{'status'});
       
    my $tt2_include_path = &tools::make_tt2_include_path($robot,'create_list_templates/'.$template,'','');

    open CONFIG, ">$list_dir/config";
    &tt2::parse_tt2($param, 'config.tt2', \*CONFIG, $tt2_include_path);
    close CONFIG;
    
    ## Creation of the info file 
    # remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
    $param->{'description'} =~ s/\015//g;
    
    unless (open INFO, ">$list_dir/info") {
	&do_log('err','Impossible to create %s/info : %s',$list_dir,$!);
    }
    if (defined $param->{'description'}) {
	print INFO $param->{'description'};
    }
    close INFO;
    
    ## Create list object
    my $list;
    unless ($list = new List ($param->{'listname'}, $robot)) {
	&do_log('err','admin::create_list_old : unable to create list %s', $param->{'listname'});
	return undef;
    }

    ## Create shared if required
    if (defined $list->{'admin'}{'shared_doc'}) {
	$list->create_shared();
    }

    my $return = {};
    $return->{'list'} = $list;

    if ($param->{'status'} eq 'open') {
	$return->{'aliases'} = &install_aliases($list,$robot);
	return $return;
    }

    $return->{'aliases'} = 1;
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
    &do_log('info', 'admin::create_list(%s,%s,%s)',$param->{'listname'},$family->{'name'},$param->{'subject'});

    ## mandatory list parameters 
    foreach my $arg ('listname') {
	unless ($param->{$arg}) {
	    &do_log('err','admin::create_list : missing list param %s', $arg);
	    return undef;
	}
    }

    unless ($family) {
	&do_log('err','admin::create_list : missing param "family"');
	return undef;
    }

    #robot
    unless ($robot) {
	&do_log('err','admin::create_list : missing param "robot"', $robot);
	return undef;
    }
   
    ## check listname
    $param->{'listname'} = lc ($param->{'listname'});

    unless ($param->{'listname'} =~ /^$tools::regexp{'listname'}$/i) {
	&do_log('err','admin::create_list : incorrect listname %s', $param->{'listname'});
	return undef;
    }

    my $regx = &Conf::get_robot_conf($robot,'list_check_regexp');
    if( $regx ) {
	if ($param->{'listname'} =~ /^(\S+)-($regx)$/) {
	    &do_log('err','admin::create_list : incorrect listname %s matches one of service aliases', $param->{'listname'});
	    return undef;
	}
    }    

    ## Check listname on SMTP server
    my $res = &list_check_smtp($param->{'listname'});
    unless (defined $res) {
	&do_log('err', "admin::create_list : can't check list %.128s on %.128s",
		$param->{'listname'},
		$Conf{'list_check_smtp'});
	return undef;
    }

    if ($res) {
	&do_log('err', 'admin::create_list : could not create already existing list %s for ',$param->{'listname'});
	foreach my $o (@{$param->{'owner'}}){
	    &do_log('err',$o->{'email'});
	}
	return undef;
    }

    ## template file
    my $template_file = &tools::get_filename('etc',{},'config.tt2', $robot,$family);
    unless (defined $template_file) {
	&do_log('err', 'admin::create_list : no config template from family %s@%s',$family->{'name'},$robot);
	return undef;
    }

    my $conf;
    my $tt_result = &tt2::parse_tt2($param, 'config.tt2', \$conf, [$family->{'dir'}]);
    unless (defined $tt_result || !$abort_on_error) {
      &do_log('err', 'admin::create_list : abort on tt2 error. List %s from family %s@%s',
                $param->{'listname'}, $family->{'name'},$robot);
      return undef;
    }

     ## Create the list directory
     my $list_dir;

    if (-d "$Conf{'home'}/$robot") {
	unless (-d $Conf{'home'}.'/'.$robot) {
	    unless (mkdir ($Conf{'home'}.'/'.$robot,0777)) {
		&do_log('err', 'admin::create_list : unable to create %s/%s : %s',$Conf{'home'},$robot,$?);
		return undef;
	    }    
	}
	$list_dir = $Conf{'home'}.'/'.$robot.'/'.$param->{'listname'};
    }else {
	$list_dir = $Conf{'home'}.'/'.$param->{'listname'};
    }

     unless (-r $list_dir || mkdir ($list_dir,0777)) {
	 &do_log('err', 'admin::create_list : unable to create %s : %s',$list_dir,$?);
	 return undef;
     }    
    
    ## Check topics
    if (defined $param->{'topics'}){
	unless (&check_topics($param->{'topics'},$robot)){
	    &do_log('err', 'admin::create_list : topics param %s not defined in topics.conf',$param->{'topics'});
	    return undef;
	}
    }
      
    ## Creation of the config file
    open CONFIG, ">$list_dir/config";
    #&tt2::parse_tt2($param, 'config.tt2', \*CONFIG, [$family->{'dir'}]);
    print CONFIG $conf;
    close CONFIG;
    
    ## Creation of the info file 
    # remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
    $param->{'description'} =~ s/\015//g;
    
    unless (open INFO, ">$list_dir/info") {
	&do_log('err','Impossible to create %s/info : %s',$list_dir,$!);
    }
    if (defined $param->{'description'}) {
	print INFO $param->{'description'};
    }
    close INFO;
    
    ## Create list object
    my $list;
    unless ($list = new List ($param->{'listname'}, $robot)) {
	&do_log('err','admin::create_list : unable to create list %s', $param->{'listname'});
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
	return $return;
    }

    $return->{'aliases'} = 1;
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
    &do_log('info', 'admin::update_list(%s,%s,%s)',$param->{'listname'},$family->{'name'},$param->{'subject'});

    ## mandatory list parameters
    foreach my $arg ('listname') {
	unless ($param->{$arg}) {
	    &do_log('err','admin::update_list : missing list param %s', $arg);
	    return undef;
	}
    }

    ## template file
    my $template_file = &tools::get_filename('etc',{}, 'config.tt2', $robot,$family);
    unless (defined $template_file) {
	&do_log('err', 'admin::update_list : no config template from family %s@%s',$family->{'name'},$robot);
	return undef;
    }

    ## Check topics
    if (defined $param->{'topics'}){
	unless (&check_topics($param->{'topics'},$robot)){
	    &do_log('err', 'admin::update_list : topics param %s not defined in topics.conf',$param->{'topics'});
	    return undef;
	}
    }

    ## Creation of the config file
    open CONFIG, ">$list->{'dir'}/config";
    &tt2::parse_tt2($param, 'config.tt2', \*CONFIG, [$family->{'dir'}]);
    close CONFIG;

    ## Create list object
    my $list;
    unless ($list = new List ($param->{'listname'}, $robot)) {
	&do_log('err','admin::create_list : unable to create list %s', $param->{'listname'});
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

    return $list;
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
    &do_log('debug2',"admin::check_owner_defined()");
    
    if (ref($owner) eq "ARRAY") {
	if (ref($owner_include) eq "ARRAY") {
	    if (($#{$owner} < 0) && ($#{$owner_include} <0)) {
		&do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	} else {
	    if (($#{$owner} < 0) && !($owner_include)) {
		&do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	}
    } else {
	if (ref($owner_include) eq "ARRAY") {
	    if (!($owner) && ($#{$owner_include} <0)) {
		&do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	}else {
	    if (!($owner) && !($owner_include)) {
		&do_log('err','missing list param owner or owner_include');
		return undef;
	    }
	}
    }
    
    if (ref($owner) eq "ARRAY") {
	foreach my $o (@{$owner}) {
	    unless($o){ 
		&do_log('err','empty param "owner"');
		return undef;
	    }
	    unless ($o->{'email'}) {
		&do_log('err','missing sub param "email" for param "owner"');
		return undef;
	    }
	}
    } elsif (ref($owner) eq "HASH"){
	unless ($owner->{'email'}) {
	    &do_log('err','missing sub param "email" for param "owner"');
	    return undef;
	}
    } elsif (defined $owner) {
	&do_log('err','missing sub param "email" for param "owner"');
	return undef;
    }	
    
    if (ref($owner_include) eq "ARRAY") {
	foreach my $o (@{$owner_include}) {
	    unless($o){ 
		&do_log('err','empty param "owner_include"');
		return undef;
	    }
	    unless ($o->{'source'}) {
		&do_log('err','missing sub param "source" for param "owner_include"');
		return undef;
	    }
	} 
    }elsif (ref($owner_include) eq "HASH"){
	unless ($owner_include->{'source'}) {
	    &do_log('err','missing sub param "source" for param "owner_include"');
	    return undef;
	}
    } elsif (defined $owner_include) {
	&do_log('err','missing sub param "source" for param "owner_include"');
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
     &do_log('debug2', 'admin::list_check_smtp(%s,%s)',$list,$robot);

     my $conf = '';
     my $smtp;
     my (@suf, @addresses);

     my $smtp_relay = $Conf{'robots'}{$robot}{'list_check_smtp'} || $Conf{'list_check_smtp'};
     my $suffixes = $Conf{'robots'}{$robot}{'list_check_suffixes'} || $Conf{'list_check_suffixes'};
     return 0 
	 unless ($smtp_relay && $suffixes);
     my $domain = &Conf::get_robot_conf($robot, 'host');
     &do_log('debug2', 'list_check_smtp(%s)',$list);
     @suf = split(/,/,$suffixes);
     return 0 if ! @suf;
     for(@suf) {
	 push @addresses, $list."-$_\@".$domain;
     }
     push @addresses,"$list\@" . $domain;

     unless (require Net::SMTP) {
	 do_log ('err',"admin::list_check_smtp : Unable to use Net library, Net::SMTP required, install it (CPAN) first");
	 return undef;
     }
     if( $smtp = Net::SMTP->new($smtp_relay,
				Hello => $smtp_relay,
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
# OUT : - undef if not applicable
#         1 (if ok) or
#         $resul : concated string of alias not installed 
##########################################################
sub install_aliases {
    my $list = shift;
    my $robot = shift;
    &do_log('debug', "admin::install_aliases($list->{'name'},$robot)");

    return 1
	if ($Conf{'sendmail_aliases'} =~ /^none$/i);

    my $alias_installed = 0;
    my $alias_manager = '--SBINDIR--/alias_manager.pl';
    &do_log('debug2',"admin::install_aliases : $alias_manager add $list->{'name'} $list->{'admin'}{'host'}");
     if (-x $alias_manager) {
	 system ("$alias_manager add $list->{'name'} $list->{'admin'}{'host'}") ;
	 my $status = $? / 256;
	 if ($status == '0') {
	     &do_log('err','admin::install_aliases : Aliases installed successfully') ;
	     $alias_installed = 1;
	 }elsif ($status == '1') {
	     &do_log('err','admin::install_aliases : Configuration file --CONFIG-- has errors');
	 }elsif ($status == '2')  {
	     &do_log('err','admin::install_aliases : Internal error : Incorrect call to alias_manager');
	 }elsif ($status == '3')  {
	     &do_log('err','admin::install_aliases : Could not read sympa config file, report to httpd error_log') ;
	 }elsif ($status == '4')  {
	     &do_log('err','admin::install_aliases : Could not get default domain, report to httpd error_log') ;
	 }elsif ($status == '5')  {
	     &do_log('err','admin::install_aliases : Unable to append to alias file') ;
	 }elsif ($status == '6')  {
	     &do_log('err','admin::install_aliases : Unable to run newaliases') ;
	 }elsif ($status == '7')  {
	     &do_log('err','admin::install_aliases : Unable to read alias file, report to httpd error_log') ;
	 }elsif ($status == '8')  {
	     &do_log('err','admin::install_aliases : Could not create temporay file, report to httpd error_log') ;
	 }elsif ($status == '13') {
	     &do_log('err','admin::install_aliases : Some of list aliases already exist') ;
	 }elsif ($status == '14') {
	     &do_log('err','admin::install_aliases : Can not open lock file, report to httpd error_log') ;
	 }elsif ($status == '15') {
	     &do_log('err','The parser returned empty aliases') ;
	 }else {
	     &do_log('err',"admin::install_aliases : Unknown error $status while running alias manager $alias_manager");
	 } 
     }else {
	 &do_log('err','admin::install_aliases : Failed to install aliases: %s', $!);
     }
    
    unless ($alias_installed) {
	my $aliases ;
	my %data;
	$data{'list'}{'domain'} = $data{'robot'} = $robot;
	$data{'list'}{'name'} = $list->{'name'};
	$data{'default_domain'} = $Conf{'domain'};
	$data{'is_default_domain'} = 1 if ($robot == $Conf{'domain'});
	$data{'return_path_suffix'} = &Conf::get_robot_conf($robot, 'return_path_suffix');

	my $tt2_include_path = &tools::make_tt2_include_path($robot,'','','');

	&tt2::parse_tt2 (\%data,'list_aliases.tt2',\$aliases, $tt2_include_path);
	
	return $aliases;
    }

    return 1;
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
     &do_log('info', "_remove_aliases($list->{'name'},$robot");

    return 1
	if ($Conf{'sendmail_aliases'} =~ /^none$/i);

     my $status = $list->remove_aliases();
     my $suffix = &Conf::get_robot_conf($robot, 'return_path_suffix');
     my $aliases;

     unless ($status == 1) {
	 &do_log('err','Failed to remove aliases for list %s', $list->{'name'});

	 ## build a list of required aliases the listmaster should install
	 $aliases = "#----------------- $list->{'name'}\n";
	 $aliases .= "$list->{'name'}: \"| --MAILERPROGDIR--/queue $list->{'name'}\"\n";
	 $aliases .= "$list->{'name'}-request: \"| --MAILERPROGDIR--/queue $list->{'name'}-request\"\n";
	 $aliases .= "$list->{'name'}$suffix: \"| --MAILERPROGDIR--/bouncequeue $list->{'name'}\"\n";
	 $aliases .= "$list->{'name'}-unsubscribe: \"| --MAILERPROGDIR--/queue $list->{'name'}-unsubscribe\"\n";
	 $aliases .= "# $list->{'name'}-subscribe: \"| --MAILERPROGDIR--/queue $list->{'name'}-subscribe\"\n";
	 
	 return $aliases;
     }

     &do_log('info','Aliases removed successfully');

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
    &do_log('info', "admin::check_topics($topic,$robot)");

    my ($top, $subtop) = split /\//, $topic;

    my %topics;
    unless (%topics = &List::load_topics($robot)) {
	&do_log('err','admin::check_topics : unable to load list of topics');
    }

    if ($subtop) {
	return 1 if (defined $topics{$top} && defined $topics{$top}{'sub'}{$subtop});
    }else {
	return 1 if (defined $topics{$top});
    }

    return undef;
}


########################################""
return 1;
