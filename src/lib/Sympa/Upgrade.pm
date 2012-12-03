# $Id$

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

=head1 NAME

Sympa::Upgrade - Upgrade functions

=head1 DESCRIPTION

This module provides functions to upgrade Sympa data structures.

=cut

package Sympa::Upgrade;

use strict;

use POSIX qw();

use Sympa::Configuration;
use Sympa::Constants;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::SDM;
use Sympa::Spool;
use Sympa::Tools::Data;
use Sympa::Tools::File;

## Return the previous Sympa version, ie the one listed in data_structure.version
sub get_previous_version {
    my $version_file = "$Sympa::Configuration::Conf{'etc'}/data_structure.version";
    my $previous_version;
    
    if (-f $version_file) {
	unless (open VFILE, $version_file) {
	    &Sympa::Log::do_log('err', "Unable to open %s : %s", $version_file, $!);
	    return undef;
	}
	while (<VFILE>) {
	    next if /^\s*$/;
	    next if /^\s*\#/;
	    chomp;
	    $previous_version = $_;
	    last;
	}
	close VFILE;
	
	return $previous_version;
    }
    
    return undef;
}

sub update_version {
    my $version_file = "$Sympa::Configuration::Conf{'etc'}/data_structure.version";

    ## Saving current version if required
    unless (open VFILE, ">$version_file") {
	&Sympa::Log::do_log('err', "Unable to write %s ; sympa.pl needs write access on %s directory : %s", $version_file, $Sympa::Configuration::Conf{'etc'}, $!);
	return undef;
    }
    printf VFILE "# This file is automatically created by sympa.pl after installation\n# Unless you know what you are doing, you should not modify it\n";
    printf VFILE "%s\n", Sympa::Constants::VERSION;
    close VFILE;
    
    return 1;
}


## Upgrade data structure from one version to another
sub upgrade {
    my ($previous_version, $new_version) = @_;

    &Sympa::Log::do_log('notice', '%s::upgrade(%s, %s)', __PACKAGE__, $previous_version, $new_version);
    
    if (&Sympa::Tools::Data::lower_version($new_version, $previous_version)) {
	&Sympa::Log::do_log('notice', 'Installing  older version of Sympa ; no upgrade operation is required');
	return 1;
    }

    ## Always update config.bin files while upgrading
    &Sympa::Configuration::delete_binaries();

    ## Always update config.bin files while upgrading
    ## This is especially useful for character encoding reasons
    &Sympa::Log::do_log('notice','Rebuilding config.bin files for ALL lists...it may take a while...');
    my $all_lists = &Sympa::List::get_lists('*',{'reload_config' => 1});

    ## Empty the admin_table entries and recreate them
    &Sympa::Log::do_log('notice','Rebuilding the admin_table...');
    &Sympa::List::delete_all_list_admin();
    foreach my $list (@$all_lists) {
	$list->sync_include_admin();
    }

    ## Migration to tt2
    if (&Sympa::Tools::Data::lower_version($previous_version, '4.2b')) {

	&Sympa::Log::do_log('notice','Migrating templates to TT2 format...');	
	
	my $tpl_script = Sympa::Constants::SCRIPTDIR . '/tpl2tt2.pl';
	unless (open EXEC, "$tpl_script|") {
	    &Sympa::Log::do_log('err', "Unable to run $tpl_script");
	    return undef;
	}
	close EXEC;
	
	&Sympa::Log::do_log('notice','Rebuilding web archives...');
	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    next unless (defined $list->{'admin'}{'web_archive'});
	    my $file = $Sympa::Configuration::Conf{'queueoutgoing'}.'/.rebuild.'.$list->get_list_id();
	    
	    unless (open REBUILD, ">$file") {
		&Sympa::Log::do_log('err','Cannot create %s', $file);
		next;
	    }
	    print REBUILD ' ';
	    close REBUILD;
	}	
    }
    
    ## Initializing the new admin_table
    if (&Sympa::Tools::Data::lower_version($previous_version, '4.2b.4')) {
	&Sympa::Log::do_log('notice','Initializing the new admin_table...');
	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    $list->sync_include_admin();
	}
    }

    ## Move old-style web templates out of the include_path
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.0.1')) {
	&Sympa::Log::do_log('notice','Old web templates HTML structure is not compliant with latest ones.');
	&Sympa::Log::do_log('notice','Moving old-style web templates out of the include_path...');

	my @directories;

	if (-d "$Sympa::Configuration::Conf{'etc'}/web_tt2") {
	    push @directories, "$Sympa::Configuration::Conf{'etc'}/web_tt2";
	}

	## Go through Virtual Robots
	foreach my $vr (keys %{$Sympa::Configuration::Conf{'robots'}}) {

	    if (-d "$Sympa::Configuration::Conf{'etc'}/$vr/web_tt2") {
		push @directories, "$Sympa::Configuration::Conf{'etc'}/$vr/web_tt2";
	    }
	}

	## Search in V. Robot Lists
	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    if (-d "$list->{'dir'}/web_tt2") {
		push @directories, "$list->{'dir'}/web_tt2";
	    }	    
	}

	my @templates;

	foreach my $d (@directories) {
	    unless (opendir DIR, $d) {
		printf STDERR "Error: Cannot read %s directory : %s", $d, $!;
		next;
	    }
	    
	    foreach my $tt2 (sort grep(/\.tt2$/,readdir DIR)) {
		push @templates, "$d/$tt2";
	    }
	    
	    closedir DIR;
	}

	foreach my $tpl (@templates) {
	    unless (rename $tpl, "$tpl.oldtemplate") {
		printf STDERR "Error : failed to rename $tpl to $tpl.oldtemplate : $!\n";
		next;
	    }

	    &Sympa::Log::do_log('notice','File %s renamed %s', $tpl, "$tpl.oldtemplate");
	}
    }


    ## Clean buggy list config files
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.1b')) {
	&Sympa::Log::do_log('notice','Cleaning buggy list config files...');
	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    $list->save_config('listmaster@'.$list->{'domain'});
	}
    }

    ## Fix a bug in Sympa 5.1
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.1.2')) {
	&Sympa::Log::do_log('notice','Rename archives/log. files...');
	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    my $l = $list->{'name'}; 
	    if (-f $list->{'dir'}.'/archives/log.') {
		rename $list->{'dir'}.'/archives/log.', $list->{'dir'}.'/archives/log.00';
	    }
	}
    }

    if (&Sympa::Tools::Data::lower_version($previous_version, '5.2a.1')) {

	## Fill the robot_subscriber and robot_admin fields in DB
	&Sympa::Log::do_log('notice','Updating the new robot_subscriber and robot_admin  Db fields...');

	foreach my $r (keys %{$Sympa::Configuration::Conf{'robots'}}) {
	    my $all_lists = &Sympa::List::get_lists($r, {'skip_sync_admin' => 1});
	    foreach my $list ( @$all_lists ) {
		
		foreach my $table ('subscriber','admin') {
		    unless (&Sympa::SDM::do_query("UPDATE %s_table SET robot_%s=%s WHERE (list_%s=%s)",
		    $table,
		    $table,
		    &Sympa::SDM::quote($r),
		    $table,
		    &Sympa::SDM::quote($list->{'name'}))) {
			&Sympa::Log::do_log('err','Unable to fille the robot_admin and robot_subscriber fields in database for robot %s.',$r);
			&Sympa::List::send_notify_to_listmaster('upgrade_failed', $Sympa::Configuration::Conf{'domain'},{'error' => $Sympa::SDM::db_source->{'db_handler'}->errstr});
			return undef;
		    }
		}
		
		## Force Sync_admin
		$list = new Sympa::List ($list->{'name'}, $list->{'domain'}, {'force_sync_admin' => 1});
	    }
	}

	## Rename web archive directories using 'domain' instead of 'host'
	&Sympa::Log::do_log('notice','Renaming web archive directories with the list domain...');
	
	my $root_dir = &Sympa::Configuration::get_robot_conf($Sympa::Configuration::Conf{'domain'},'arc_path');
	unless (opendir ARCDIR, $root_dir) {
	    &Sympa::Log::do_log('err',"Unable to open $root_dir : $!");
	    return undef;
	}
	
	foreach my $dir (sort readdir(ARCDIR)) {
	    next if (($dir =~ /^\./o) || (! -d $root_dir.'/'.$dir)); ## Skip files and entries starting with '.'
		     
	    my ($listname, $listdomain) = split /\@/, $dir;

	    next unless ($listname & $listdomain);

	    my $list = new Sympa::List $listname;
	    unless (defined $list) {
		&Sympa::Log::do_log('notice',"Skipping unknown list $listname");
		next;
	    }
	    
	    if ($listdomain ne $list->{'domain'}) {
		my $old_path = $root_dir.'/'.$listname.'@'.$listdomain;		
		my $new_path = $root_dir.'/'.$listname.'@'.$list->{'domain'};

		if (-d $new_path) {
		    &Sympa::Log::do_log('err',"Could not rename %s to %s ; directory already exists", $old_path, $new_path);
		    next;
		}else {
		    unless (rename $old_path, $new_path) {
			&Sympa::Log::do_log('err',"Failed to rename %s to %s : %s", $old_path, $new_path, $!);
			next;
		    }
		    &Sympa::Log::do_log('notice', "Renamed %s to %s", $old_path, $new_path);
		}
	    }		     
	}
	close ARCDIR;
	
    }

    ## DB fields of enum type have been changed to int
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.2a.1')) {
	
	if (&Sympa::SDM::use_db & $Sympa::Configuration::Conf{'db_type'} eq 'mysql') {
	    my %check = ('subscribed_subscriber' => 'subscriber_table',
			 'included_subscriber' => 'subscriber_table',
			 'subscribed_admin' => 'admin_table',
			 'included_admin' => 'admin_table');
	    
    my $dbh = &Sympa::SDM::db_get_handler();

	    foreach my $field (keys %check) {

		my $statement;
				
		## Query the Database
		$statement = sprintf "SELECT max(%s) FROM %s", $field, $check{$field};
		
		my $sth;
		
		unless ($sth = $dbh->prepare($statement)) {
		    &Sympa::Log::do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
		    return undef;
		}
		
		unless ($sth->execute) {
		    &Sympa::Log::do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		    return undef;
		}
		
		my $max = $sth->fetchrow();
		$sth->finish();		

		## '0' has been mapped to 1 and '1' to 2
		## Restore correct field value
		if ($max > 1) {
		    ## 1 to 0
		    &Sympa::Log::do_log('notice', 'Fixing DB field %s ; turning 1 to 0...', $field);
		    
		    my $statement = sprintf "UPDATE %s SET %s=%d WHERE (%s=%d)", $check{$field}, $field, 0, $field, 1;
		    my $rows;
		    unless ($rows = $dbh->do($statement)) {
			&Sympa::Log::do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			return undef;
		    }
		    
		    &Sympa::Log::do_log('notice', 'Updated %d rows', $rows);

		    ## 2 to 1
		    &Sympa::Log::do_log('notice', 'Fixing DB field %s ; turning 2 to 1...', $field);
		    
		    $statement = sprintf "UPDATE %s SET %s=%d WHERE (%s=%d)", $check{$field}, $field, 1, $field, 2;

		    unless ($rows = $dbh->do($statement)) {
			&Sympa::Log::do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			return undef;
		    }
		    
		    &Sympa::Log::do_log('notice', 'Updated %d rows', $rows);		    

		}

		## Set 'subscribed' data field to '1' is none of 'subscribed' and 'included' is set		
		$statement = "UPDATE subscriber_table SET subscribed_subscriber=1 WHERE ((included_subscriber IS NULL OR included_subscriber!=1) AND (subscribed_subscriber IS NULL OR subscribed_subscriber!=1))";
		
		&Sympa::Log::do_log('notice','Updating subscribed field of the subscriber table...');
		my $rows = $dbh->do($statement);
		unless (defined $rows) {
		    &Sympa::Log::fatal_err("Unable to execute SQL statement %s : %s", $statement, $dbh->errstr);	    
		}
		&Sympa::Log::do_log('notice','%d rows have been updated', $rows);
				
	    }
	}
    }

    ## Rename bounce sub-directories
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.2a.1')) {

	&Sympa::Log::do_log('notice','Renaming bounce sub-directories adding list domain...');
	
	my $root_dir = &Sympa::Configuration::get_robot_conf($Sympa::Configuration::Conf{'domain'},'bounce_path');
	unless (opendir BOUNCEDIR, $root_dir) {
	    &Sympa::Log::do_log('err',"Unable to open $root_dir : $!");
	    return undef;
	}
	
	foreach my $dir (sort readdir(BOUNCEDIR)) {
	    next if (($dir =~ /^\./o) || (! -d $root_dir.'/'.$dir)); ## Skip files and entries starting with '.'
		     
	    next if ($dir =~ /\@/); ## Directory already include the list domain

	    my $listname = $dir;
	    my $list = new Sympa::List $listname;
	    unless (defined $list) {
		&Sympa::Log::do_log('notice',"Skipping unknown list $listname");
		next;
	    }
	    
	    my $old_path = $root_dir.'/'.$listname;		
	    my $new_path = $root_dir.'/'.$listname.'@'.$list->{'domain'};
	    
	    if (-d $new_path) {
		&Sympa::Log::do_log('err',"Could not rename %s to %s ; directory already exists", $old_path, $new_path);
		next;
	    }else {
		unless (rename $old_path, $new_path) {
		    &Sympa::Log::do_log('err',"Failed to rename %s to %s : %s", $old_path, $new_path, $!);
		    next;
		}
		&Sympa::Log::do_log('notice', "Renamed %s to %s", $old_path, $new_path);
	    }
	}
	close BOUNCEDIR;
    }

    ## Update lists config using 'include_list'
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.2a.1')) {
	
	&Sympa::Log::do_log('notice','Update lists config using include_list parameter...');

	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    if (defined $list->{'admin'}{'include_list'}) {
	    
		foreach my $index (0..$#{$list->{'admin'}{'include_list'}}) {
		    my $incl = $list->{'admin'}{'include_list'}[$index];
		    my $incl_list = new Sympa::List ($incl);
		    
		    if (defined $incl_list &
			$incl_list->{'domain'} ne $list->{'domain'}) {
			&Sympa::Log::do_log('notice','Update config file of list %s, including list %s', $list->get_list_id(), $incl_list->get_list_id());
			
			$list->{'admin'}{'include_list'}[$index] = $incl_list->get_list_id();

			$list->save_config('listmaster@'.$list->{'domain'});
		    }
		}
	    }
	}	
    }

    ## New mhonarc ressource file with utf-8 recoding
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.3a.6')) {
	
	&Sympa::Log::do_log('notice','Looking for customized mhonarc-ressources.tt2 files...');
	foreach my $vr (keys %{$Sympa::Configuration::Conf{'robots'}}) {
	    my $etc_dir = $Sympa::Configuration::Conf{'etc'};

	    if ($vr ne $Sympa::Configuration::Conf{'domain'}) {
		$etc_dir .= '/'.$vr;
	    }

	    if (-f $etc_dir.'/mhonarc-ressources.tt2') {
		my $new_filename = $etc_dir.'/mhonarc-ressources.tt2'.'.'.time;
		rename $etc_dir.'/mhonarc-ressources.tt2', $new_filename;
		&Sympa::Log::do_log('notice', "Custom %s file has been backed up as %s", $etc_dir.'/mhonarc-ressources.tt2', $new_filename);
		&Sympa::List::send_notify_to_listmaster('file_removed',$Sympa::Configuration::Conf{'domain'},
						 [$etc_dir.'/mhonarc-ressources.tt2', $new_filename]);
	    }
	}


	&Sympa::Log::do_log('notice','Rebuilding web archives...');
	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    next unless (defined $list->{'admin'}{'web_archive'});
	    my $file = $Sympa::Configuration::Conf{'queueoutgoing'}.'/.rebuild.'.$list->get_list_id();
	    
	    unless (open REBUILD, ">$file") {
		&Sympa::Log::do_log('err','Cannot create %s', $file);
		next;
	    }
	    print REBUILD ' ';
	    close REBUILD;
	}	

    }

    ## Changed shared documents name encoding
    ## They are Q-encoded therefore easier to store on any filesystem with any encoding
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.3a.8')) {
	&Sympa::Log::do_log('notice','Q-Encoding web documents filenames...');

	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    if (-d $list->{'dir'}.'/shared') {
		&Sympa::Log::do_log('notice','  Processing list %s...', $list->get_list_address());

		## Determine default lang for this list
		## It should tell us what character encoding was used for filenames
		&Sympa::Language::SetLang($list->{'admin'}{'lang'});
		my $list_encoding = &Sympa::Language::GetCharset();

		my $count = &Sympa::Tools::qencode_hierarchy($list->{'dir'}.'/shared', $list_encoding);

		if ($count) {
		    &Sympa::Log::do_log('notice', 'List %s : %d filenames has been changed', $list->{'name'}, $count);
		}
	    }
	}

    }    

    ## We now support UTF-8 only for custom templates, config files, headers and footers, info files
    ## + web_tt2, scenari, create_list_templatee, families
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.3b.3')) {
	&Sympa::Log::do_log('notice','Encoding all custom files to UTF-8...');

	my (@directories, @files);

	## Site level
	foreach my $type ('mail_tt2','web_tt2','scenari','create_list_templates','families') {
	    if (-d $Sympa::Configuration::Conf{'etc'}.'/'.$type) {
		push @directories, [$Sympa::Configuration::Conf{'etc'}.'/'.$type, $Sympa::Configuration::Conf{'lang'}];
	    }
	}

	foreach my $f (
        Sympa::Constants::CONFIG,
        Sympa::Constants::WWSCONFIG,
        $Sympa::Configuration::Conf{'etc'}.'/'.'topics.conf',
        $Sympa::Configuration::Conf{'etc'}.'/'.'auth.conf'
    ) {
	    if (-f $f) {
		push @files, [$f, $Sympa::Configuration::Conf{'lang'}];
	    }
	}

	## Go through Virtual Robots
	foreach my $vr (keys %{$Sympa::Configuration::Conf{'robots'}}) {
	    foreach my $type ('mail_tt2','web_tt2','scenari','create_list_templates','families') {
		if (-d $Sympa::Configuration::Conf{'etc'}.'/'.$vr.'/'.$type) {
		    push @directories, [$Sympa::Configuration::Conf{'etc'}.'/'.$vr.'/'.$type, &Sympa::Configuration::get_robot_conf($vr, 'lang')];
		}
	    }

	    foreach my $f ('robot.conf','topics.conf','auth.conf') {
		if (-f $Sympa::Configuration::Conf{'etc'}.'/'.$vr.'/'.$f) {
		    push @files, [$Sympa::Configuration::Conf{'etc'}.'/'.$vr.'/'.$f, $Sympa::Configuration::Conf{'lang'}];
		}
	    }
	}

	## Search in Lists
	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    foreach my $f ('config','info','homepage','message.header','message.footer') {
		if (-f $list->{'dir'}.'/'.$f){
		    push @files, [$list->{'dir'}.'/'.$f, $list->{'admin'}{'lang'}];
		}
	    }

	    foreach my $type ('mail_tt2','web_tt2','scenari') {
		my $directory = $list->{'dir'}.'/'.$type;
		if (-d $directory) {
		    push @directories, [$directory, $list->{'admin'}{'lang'}];
		}	    
	    }
	}

	## Search language directories
	foreach my $pair (@directories) {
	    my ($d, $lang) = @$pair;
	    unless (opendir DIR, $d) {
		next;
	    }

	    if ($d =~ /(mail_tt2|web_tt2)$/) {
		foreach my $subdir (grep(/^[a-z]{2}(_[A-Z]{2})?$/, readdir DIR)) {
		    if (-d "$d/$subdir") {
			push @directories, ["$d/$subdir", $subdir];
		    }
		}
		closedir DIR;

	    }elsif ($d =~ /(create_list_templates|families)$/) {
		foreach my $subdir (grep(/^\w+$/, readdir DIR)) {
		    if (-d "$d/$subdir") {
			push @directories, ["$d/$subdir", $Sympa::Configuration::Conf{'lang'}];
		    }
		}
		closedir DIR;
	    }
	}

	foreach my $pair (@directories) {
	    my ($d, $lang) = @$pair;
	    unless (opendir DIR, $d) {
		next;
	    }
	    foreach my $file (readdir DIR) {
		next unless (($d =~ /mail_tt2|web_tt2|create_list_templates|families/ & $file =~ /\.tt2$/) ||
			     ($d =~ /scenari$/ & $file =~ /\w+\.\w+$/));
		push @files, [$d.'/'.$file, $lang];
	    }
	    closedir DIR;
	}

	## Do the encoding modifications
	## Previous versions of files are backed up with the date extension
	my $total = &to_utf8(\@files);
	&Sympa::Log::do_log('notice','%d files have been modified', $total);
    }

    ## giving up subscribers flat files ; moving subscribers to the DB
    ## Also giving up old 'database' mode
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.4a.1')) {
	
	&Sympa::Log::do_log('notice','Looking for lists with user_data_source parameter set to file or database...');

	my $all_lists = &Sympa::List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    if ($list->{'admin'}{'user_data_source'} eq 'file') {

		&Sympa::Log::do_log('notice','List %s ; changing user_data_source from file to include2...', $list->{'name'});
		
		my @users = &Sympa::List::_load_list_members_file("$list->{'dir'}/subscribers");
		
		$list->{'admin'}{'user_data_source'} = 'include2';
		$list->{'total'} = 0;
		
		## Add users to the DB
		$list->add_list_member(@users);
		my $total = $list->{'add_outcome'}{'added_members'};
		if (defined $list->{'add_outcome'}{'errors'}) {
		    &Sympa::Log::do_log('err', 'Failed to add users: %s',$list->{'add_outcome'}{'errors'}{'error_message'});
		}
		
		&Sympa::Log::do_log('notice','%d subscribers have been loaded into the database', $total);
		
		unless ($list->save_config('automatic')) {
		    &Sympa::Log::do_log('err', 'Failed to save config file for list %s', $list->{'name'});
		}
	    }elsif ($list->{'admin'}{'user_data_source'} eq 'database') {

		&Sympa::Log::do_log('notice','List %s ; changing user_data_source from database to include2...', $list->{'name'});

		unless ($list->update_list_member('*', {'subscribed' => 1})) {
		    &Sympa::Log::do_log('err', 'Failed to update subscribed DB field');
		}

		$list->{'admin'}{'user_data_source'} = 'include2';

		unless ($list->save_config('automatic')) {
		    &Sympa::Log::do_log('err', 'Failed to save config file for list %s', $list->{'name'});
		}
	    }
	}
    }
    
    if (&Sympa::Tools::Data::lower_version($previous_version, '5.5a.1')) {

      ## Remove OTHER/ subdirectories in bounces
      &Sympa::Log::do_log('notice', "Removing obsolete OTHER/ bounce directories");
      if (opendir BOUNCEDIR, &Sympa::Configuration::get_robot_conf($Sympa::Configuration::Conf{'domain'}, 'bounce_path')) {
	
	foreach my $subdir (sort grep (!/^\.+$/,readdir(BOUNCEDIR))) {
	  my $other_dir = &Sympa::Configuration::get_robot_conf($Sympa::Configuration::Conf{'domain'}, 'bounce_path').'/'.$subdir.'/OTHER';
	  if (-d $other_dir) {
	    &Sympa::Tools::File::remove_dir($other_dir);
	    &Sympa::Log::do_log('notice', "Directory $other_dir removed");
	  }
	}
	
	close BOUNCEDIR;
 
      }else {
	&Sympa::Log::do_log('err', "Failed to open directory $Sympa::Configuration::Conf{'queuebounce'} : $!");	
      }

   }

   if (&Sympa::Tools::Data::lower_version($previous_version, '6.1b.5')) {
		## Encoding of shared documents was not consistent with recent versions of MIME::Encode
		## MIME::EncWords::encode_mimewords() used to encode characters -!*+/ 
		## Now these characters are preserved, according to RFC 2047 section 5 
		## We change encoding of shared documents according to new algorithm
		&Sympa::Log::do_log('notice','Fixing Q-encoding of web document filenames...');
		my $all_lists = &Sympa::List::get_lists('*');
		foreach my $list ( @$all_lists ) {
			if (-d $list->{'dir'}.'/shared') {
				&Sympa::Log::do_log('notice','  Processing list %s...', $list->get_list_address());

				my @all_files;
				&Sympa::Tools::File::list_dir($list->{'dir'}, \@all_files, 'utf-8');
				
				my $count;
				foreach my $f_struct (reverse @all_files) {
					my $new_filename = $f_struct->{'filename'};
					
					## Decode and re-encode filename
					$new_filename = &Sympa::Tools::qencode_filename(&Sympa::Tools::qdecode_filename($new_filename));
					
					if ($new_filename ne $f_struct->{'filename'}) {
						## Rename file
						my $orig_f = $f_struct->{'directory'}.'/'.$f_struct->{'filename'};
						my $new_f = $f_struct->{'directory'}.'/'.$new_filename;
						&Sympa::Log::do_log('notice', "Renaming %s to %s", $orig_f, $new_f);
						unless (rename $orig_f, $new_f) {
							&Sympa::Log::do_log('err', "Failed to rename %s to %s : %s", $orig_f, $new_f, $!);
							next;
						}
						$count++;
					}
				}
				if ($count) {
				&Sympa::Log::do_log('notice', 'List %s : %d filenames has been changed', $list->{'name'}, $count);
				}
			}
		}
		
   }		
    if (&Sympa::Tools::Data::lower_version($previous_version, '6.3a')) {
	# move spools from file to database.
	my %spools_def = ('queue' =>  'msg',
			  'bouncequeue' => 'bounce',
			  'queuedistribute' => 'msg',
			  'queuedigest' => 'digest',
			  'queuemod' => 'mod',
			  'queuesubscribe' =>  'subscribe',
			  'queuetopic' => 'topic',
			  'queueautomatic' => 'automatic',
			  'queueauth' => 'auth',
			  'queueoutgoing' => 'archive',
			  'queuetask' => 'task');
   if (&Sympa::Tools::Data::lower_version($previous_version, '6.1.11')) {
       ## Exclusion table was not robot-enabled.
       &Sympa::Log::do_log('notice','fixing robot column of exclusion table.');
       my $sth;
	unless ($sth = &Sympa::SDM::do_query("SELECT * FROM exclusion_table")) {
	    &Sympa::Log::do_log('err','Unable to gather informations from the exclusions table.');
	}
	my @robots = &Sympa::List::get_robots();
	while (my $data = $sth->fetchrow_hashref){
	    next if (defined $data->{'robot_exclusion'} && $data->{'robot_exclusion'} ne '');
	    ## Guessing right robot for each exclusion.
	    my $valid_robot = '';
	    my @valid_robot_candidates;
	    foreach my $robot (@robots) {
		if (my $list = new Sympa::List($data->{'list_exclusion'},$robot)) {
		    if ($list->is_list_member($data->{'user_exclusion'})) {
			push @valid_robot_candidates,$robot;
		    }
		}
	    }
	    if ($#valid_robot_candidates == 0) {
		$valid_robot = $valid_robot_candidates[0];
		my $sth;
		unless ($sth = &Sympa::SDM::do_query("UPDATE exclusion_table SET robot_exclusion = %s WHERE list_exclusion=%s AND user_exclusion=%s", &Sympa::SDM::quote($valid_robot),&Sympa::SDM::quote($data->{'list_exclusion'}),&Sympa::SDM::quote($data->{'user_exclusion'}))) {
		    &Sympa::Log::do_log('err','Unable to update entry (%s,%s) in exclusions table (trying to add robot %s)',$data->{'list_exclusion'},$data->{'user_exclusion'},$valid_robot);
		}
	    }else {
		&Sympa::Log::do_log('err',"Exclusion robot could not be guessed for user '%s' in list '%s'. Either this user is no longer subscribed to the list or the list appears in more than one robot (or the query to the database failed). Here is the list of robots in which this list name appears: '%s'",$data->{'user_exclusion'},$data->{'list_exclusion'},@valid_robot_candidates);
	    }
	}
	## Caching all lists config subset to database
	&Sympa::Log::do_log('notice','Caching all lists config subset to database');
	&Sympa::List::_flush_list_db();
	my $all_lists = &Sympa::List::get_lists('*', { 'use_files' => 1 });
	foreach my $list (@$all_lists) {
	    $list->_update_list_db;
	}
   }

	foreach my $spoolparameter (keys %spools_def ){
	    next if ($spoolparameter eq 'queuetask'); # task is to be done later
	    
	    my $spooldir = $Sympa::Configuration::Conf{$spoolparameter};
	    
	    unless (-d $spooldir){
		&Sympa::Log::do_log('info',"Could not perform migration of spool %s because it is not a directory", $spoolparameter);
		next;
	    }
	    &Sympa::Log::do_log('notice',"Performing upgrade for spool  %s ",$spooldir);

	    my $spool = new Sympa::Spool($spools_def{$spoolparameter});
	    if (!opendir(DIR, $spooldir)) {
		&Sympa::Log::fatal_err("Can't open dir %s: %m", $spooldir); ## No return.
	    }
	    my @qfile = sort tools::by_date grep (!/^\./,readdir(DIR));
	    closedir(DIR);
	    my $filename;
	    my $listname;
	    my $robot;

	    my $ignored = '';
	    my $performed = '';
	    
	    ## Scans files in queue
	    foreach my $filename (sort @qfile) {
		my $type;
		my $list;
		my ($listname, $robot);	
		my %meta ;

		&Sympa::Log::do_log('notice'," spool : $spooldir, fichier $filename");
		if (-d $spooldir.'/'.$filename){
		    &Sympa::Log::do_log('notice',"%s/%s est un répertoire",$spooldir,$filename);
		    next;
		}				

		if (($spoolparameter eq 'queuedigest')){
		    unless ($filename =~ /^([^@]*)\@([^@]*)$/){$ignored .= ','.$filename; next;}
		    $listname = $1;
		    $robot = $2;
		    $meta{'date'} = (stat($spooldir.'/'.$filename))[9];
		}elsif (($spoolparameter eq 'queueauth')||($spoolparameter eq 'queuemod')){
		    unless ($filename =~ /^([^@]*)\@([^@]*)\_(.*)$/){$ignored .= ','.$filename;next;}
		    $listname = $1;
		    $robot = $2;
		    $meta{'authkey'} = $3;
		    $meta{'date'} = (stat($spooldir.'/'.$filename))[9];
		}elsif ($spoolparameter eq 'queuetopic'){
		    unless ($filename =~ /^([^@]*)\@([^@]*)\_(.*)$/){$ignored .= ','.$filename;next;}
		    $listname = $1;
		    $robot = $2;
		    $meta{'authkey'} = $3;
		    $meta{'date'} = (stat($spooldir.'/'.$filename))[9];
		}elsif ($spoolparameter eq 'queuesubscribe'){
		    my $match = 0;		    
		    foreach my $robot (keys %{$Sympa::Configuration::Conf{'robots'}}) {
			&Sympa::Log::do_log('notice',"robot : $robot");
			if ($filename =~ /^([^@]*)\@$robot\.(.*)$/){
			    $listname = $1;
			    $robot = $2;
			    $meta{'authkey'} = $3;
			    $meta{'date'} = (stat($spooldir.'/'.$filename))[9];
			    $match = 1;
			}
		    }
		    unless ($match){$ignored .= ','.$filename;next;}
		}elsif (($spoolparameter eq 'queue')||($spoolparameter eq 'bouncequeue')||($spoolparameter eq 'queueoutgoing')){

		    ## Don't process temporary files created by queue bouncequeue queueautomatic (T.xxx)
		    next if ($filename =~ /^T\./);

		    unless ($filename =~ /^(\S+)\.(\d+)\.\w+$/){$ignored .= ','.$filename;next;}
		    ($listname, $robot) = split(/\@/,$1);
		    $meta{'date'} = $2;
		    
		    if ($spoolparameter eq 'queue') {
			my $list_check_regexp = &Sympa::Configuration::get_robot_conf($robot,'list_check_regexp');
			if ($listname =~ /^(\S+)-($list_check_regexp)$/) {
			    ($listname, $type) = ($1, $2);
			    $meta{'type'} = $type if $type;

			    my $email = &Sympa::Configuration::get_robot_conf($robot, 'email');	
			    
			    my $priority;
			    
			    if ($listname eq $Sympa::Configuration::Conf{'listmaster_email'}) {
				$priority = 0;
			    }elsif ($type eq 'request') {
				$priority = &Sympa::Configuration::get_robot_conf($robot, 'request_priority');
			    }elsif ($type eq 'owner') {
				$priority = &Sympa::Configuration::get_robot_conf($robot, 'owner_priority');
			    }elsif ($listname =~ /^(sympa|$email)(\@$Sympa::Configuration::Conf{'host'})?$/i) {	
				$priority = &Sympa::Configuration::get_robot_conf($robot,'sympa_priority');
				$listname ='';
			    }
			    $meta{'priority'} = $priority;
			    
			}
		    }
		}
		
		$listname = lc($listname);
		if ($robot) {
		    $robot=lc($robot);
		}else{
		    $robot = lc(&Sympa::Configuration::get_robot_conf($robot, 'host'));
		}

		$meta{'robot'} = $robot if $robot;
		$meta{'list'} = $listname if $listname;
		$meta{'priority'} = 1 unless $meta{'priority'};
		
		unless (open FILE, $spooldir.'/'.$filename) {
		    &Sympa::Log::do_log('err', 'Cannot open message file %s : %s',  $filename, $!);
		    return undef;
		}
		my $messageasstring;
		while (<FILE>){
		    $messageasstring = $messageasstring.$_;
		}
		close(FILE);
		
		my $messagekey = $spool->store($messageasstring,\%meta);
		unless($messagekey) {
		    &Sympa::Log::do_log('err',"Could not load message %s/%s in db spool",$spooldir, $filename);
		    next;
		}

		mkdir $spooldir.'/copy_by_upgrade_process/'  unless (-d $spooldir.'/copy_by_upgrade_process/');		
		
		my $source = $spooldir.'/'.$filename;
		my $goal = $spooldir.'/copy_by_upgrade_process/'.$filename;

		&Sympa::Log::do_log('notice','source %s, goal %s',$source,$goal);
		# unless (&File::Copy::copy($spooldir.'/'.$filename, $spooldir.'/copy_by_upgrade_process/'.$filename)) {
		unless (&File::Copy::copy($source, $goal)) {
		    &Sympa::Log::do_log('err', 'Could not rename %s to %s: %s', $source,$goal, $!);
		    exit;
		}
		
		unless (unlink ($spooldir.'/'.$filename)) {
		    &Sympa::Log::do_log('err',"Could not unlink message %s/%s . Exiting",$spooldir, $filename);
		}
		$performed .= ','.$filename;
	    } 	    
	    &Sympa::Log::do_log('info',"Upgrade process for spool %s : ignored files %s",$spooldir,$ignored);
	    &Sympa::Log::do_log('info',"Upgrade process for spool %s : performed files %s",$spooldir,$performed);
	}	
    }
    return 1;
}

sub probe_db {
    &Sympa::SDM::probe_db();
}

sub data_structure_uptodate {
    &Sympa::SDM::data_structure_uptodate();
}

## used to encode files to UTF-8
## also add X-Attach header field if template requires it
## IN : - arrayref with list of filepath/lang pairs
sub to_utf8 {
    my $files = shift;

    my $with_attachments = qr{ archive.tt2 | digest.tt2 | get_archive.tt2 | listmaster_notification.tt2 | 
				   message_report.tt2 | moderate.tt2 |  modindex.tt2 | send_auth.tt2 }x;
    my $total;
    
    foreach my $pair (@{$files}) {
	my ($file, $lang) = @$pair;
	unless (open(TEMPLATE, $file)) {
	    &Sympa::Log::do_log('err', "Cannot open template %s", $file);
	    next;
	}
	
	my $text = '';
	my $modified = 0;

	## If filesystem_encoding is set, files are supposed to be encoded according to it
	my $charset;
	if ((defined $Sympa::Configuration::Conf::Ignored_Conf{'filesystem_encoding'})&($Sympa::Configuration::Conf::Ignored_Conf{'filesystem_encoding'} ne 'utf-8')) {
	    $charset = $Sympa::Configuration::Conf::Ignored_Conf{'filesystem_encoding'};
	}else {	    
	    &Sympa::Language::PushLang($lang);
	    $charset = &Sympa::Language::GetCharset;
	    &Sympa::Language::PopLang;
	}
	
	# Add X-Sympa-Attach: headers if required.
	if (($file =~ /mail_tt2/) & ($file =~ /\/($with_attachments)$/)) {
	    while (<TEMPLATE>) {
		$text .= $_;
		if (m/^Content-Type:\s*message\/rfc822/i) {
		    while (<TEMPLATE>) {
			if (m{^X-Sympa-Attach:}i) {
			    $text .= $_;
			    last;
			}
			if (m/^[\r\n]+$/) {
			    $text .= "X-Sympa-Attach: yes\n";
			    $modified = 1;
			    $text .= $_;
			    last;
			}
			$text .= $_;
		    }
		}
	    }
	} else {
	    $text = join('', <TEMPLATE>);
	}
	close TEMPLATE;
	
	# Check if template is encoded by UTF-8.
	if ($text =~ /[^\x20-\x7E]/) {
	    my $t = $text;
	    eval {
		&Encode::decode('UTF-8', $t, Encode::FB_CROAK);
	      };
	    if ($@) {
		eval {
		    $t = $text;
		    &Encode::from_to($t, $charset, "UTF-8", Encode::FB_CROAK);
		};
		if ($@) {
		    &Sympa::Log::do_log('err',"Template %s cannot be converted from %s to UTF-8", $charset, $file);
		} else {
		    $text = $t;
		    $modified = 1;
		}
	    }
	}
	
	next unless $modified;
	
	my $date = POSIX::strftime("%Y.%m.%d-%H.%M.%S", localtime(time));
	unless (rename $file, $file.'@'.$date) {
	    &Sympa::Log::do_log('err', "Cannot rename old template %s", $file);
	    next;
	}
	unless (open(TEMPLATE, ">$file")) {
	    &Sympa::Log::do_log('err', "Cannot open new template %s", $file);
	    next;
	}
	print TEMPLATE $text;
	close TEMPLATE;
	unless (&Sympa::Tools::File::set_file_rights(file => $file,
					user =>  Sympa::Constants::USER,
					group => Sympa::Constants::GROUP,
					mode =>  0644,
					))
	{
	    &Sympa::Log::do_log('err','Unable to set rights on %s',$Sympa::Configuration::Conf{'db_name'});
	    next;
	}
	&Sympa::Log::do_log('notice','Modified file %s ; original file kept as %s', $file, $file.'@'.$date);
	
	$total++;
    }

    return $total;
}


# md5_encode_password : Version later than 5.4 uses md5 fingerprint instead of symetric crypto to store password.
#  This require to rewrite paassword in database. This upgrade IS NOT REVERSIBLE
sub md5_encode_password {

    my $total = 0;

    &Sympa::Log::do_log('notice', '%s::md5_encode_password() recoding password using md5 fingerprint', __PACKAGE__);
    
    unless (&Sympa::List::check_db_connect()) {
	return undef;
    }

    my $dbh = &Sympa::SDM::db_get_handler();

    my $sth;
    unless ($sth = $dbh->prepare("SELECT email_user,password_user from user_table")) {
	&Sympa::Log::do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	&Sympa::Log::do_log('err','Unable to execute SQL statement : %s', $dbh->errstr);
	return undef;
    }

    $total = 0;
    my $total_md5 = 0 ;

    while (my $user = $sth->fetchrow_hashref('NAME_lc')) {

	my $clear_password ;
	if ($user->{'password_user'} =~ /^[0-9a-f]{32}/){
	    &Sympa::Log::do_log('info','password from %s already encoded as md5 fingerprint',$user->{'email_user'});
	    $total_md5++ ;
	    next;
	}	
	
	## Ignore empty passwords
	next if ($user->{'password_user'} =~ /^$/);

	if ($user->{'password_user'} =~ /^crypt.(.*)$/) {
	    $clear_password = &Sympa::Tools::decrypt_password($user->{'password_user'}, $Sympa::Configuration::Conf{'cookie'});
	}else{ ## Old style cleartext passwords
	    $clear_password = $user->{'password_user'};
	}

	$total++;

	## Updating Db
	my $escaped_email =  $user->{'email_user'};
	$escaped_email =~ s/\'/''/g;
	my $statement = sprintf "UPDATE user_table SET password_user='%s' WHERE (email_user='%s')", &Auth::password_fingerprint($clear_password), $escaped_email ;
	
	unless ($dbh->do($statement)) {
	    &Sympa::Log::do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
    }
    $sth->finish();
    
    &Sympa::Log::do_log('info',"Updating password storage in table user_table using md5 for %d users",$total) ;
    if ($total_md5) {
	&Sympa::Log::do_log('info',"Found in table user %d password stored using md5, did you run Sympa before upgrading ?", $total_md5 );
    }    
    return $total;
}

 
## Packages must return true.
1;
