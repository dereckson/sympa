#!--PERL--

# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
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

## Authors :
##           Serge Aumont <sa@cru.fr>
##           Olivier Sala�n <os@cru.fr>

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';

use strict vars;
use POSIX;
use Conf;

## Configuration

my $new_wwsympa_conf = '/tmp/wwsympa.conf';
my $new_sympa_conf = '/tmp/sympa.conf';

my $wwsconf = {};

## Change to your wwsympa.conf location
my $wwsympa_conf = '--WWSCONFIG--';
my $sympa_conf = '--CONFIG--';
my $somechange = 0;

## parameters that can be edited with this script
my @params = ({'title' => 'Directories and file location'},
	      {'name' => 'home',
	       'query' => 'The home directory for sympa',
	       'file' => 'sympa.conf','edit' => '1',
               'advice' =>''},

	      {'name' => 'pidfile',
	       'query' => 'File containing Sympa PID while running.',
	       'file' => 'sympa.conf','edit' => '0',
               'advice' =>''},
	      
	      {'name' => 'archived_pidfile',
	       'query' => 'File containing archived PID while running.',
	       'file' => 'wwsympa.conf','edit' => '0',
               'advice' =>''},
	      
	      {'name' => 'bounced_pidfile',
	       'query' => 'File containing bounced PID while running.',
	       'file' => 'wwsympa.conf','edit' => '0',
               'advice' =>''},
	      
	      {'name' => 'arc_path',
	       'query' => 'Where to store HTML archives',
	       'file' => 'wwsympa.conf','edit' => '1',
               'advice' =>'Better if not in a critical partition'},
	      
	      {'name' => 'bounce_path',
	       'query' => 'Where to store bounces',
	       'file' => 'wwsympa.conf','edit' => '0',
               'advice' =>'Better if not in a critical partition'},
	      
	      {'name' => 'msgcat',
	       'query' => 'Directory containig available NLS catalogues',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'queue',
	       'query' => 'Incoming spool',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'queuebounce',
	       'query' => 'Bounce incoming spool',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'title' => 'Syslog'},

	      {'name' => 'syslog',
	       'query' => 'The syslog facility for sympa',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Do not forget to edit syslog.conf'},
	      
	      {'name' => 'log_facility',
	       'query' => 'The syslog facility for wwsympa, archived and bounced',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>'default is to use previously defined sympa log facility'},
	      
	      {'name' => 'log_socket_type',
	       'query' => 'The syslog socket (unix | inet)',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'log_level',
	       'query' => 'Log intensity',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>'0 : normal, 2,3,4 for debug'},
	      
	      {'title' => 'General definition'},
	      
	      {'name' => 'sleep',
	       'query' => 'Main sympa loop sleep',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'sympa_priority',
	       'query' => 'Sympa commands priority',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'default_list_priority',
	       'query' => 'Default priority for list messages',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	       
	      {'name' => 'umask',
	       'query' => 'Umask used for file creation by Sympa',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'cookie',
	       'query' => 'Secret used by Sympa to make MD5 fingerprint in web cookies secure',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>'Should not be changed ! May invalid all user password'},

	      {'name' => 'password_case',
	       'query' => 'Password case (insensitive | sensitive)',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>'Should not be changed ! May invalid all user password'},

	      {'name' => 'cookie_expire',
	       'query' => 'HTTP cookies lifetime',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'cookie_domain',
	       'query' => 'HTTP cookies validity domain',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'listmaster',
	       'query' => 'Listmasters email list colon separated',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'max_size',
	       'query' => 'The default maximum size (in bytes) for messages (can be re-defined for each list)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},


	      {'name' => 'host',
	       'query' => 'Name of the host',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'email',
	       'query' => 'Local part of sympa email adresse',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>'Effective address will be \[EMAIL\]@\[HOST\]'},


	      {'name' => 'lang',
	       'query' => 'Default lang (fr | us | es | de | it | cn | tw | fi | pl | cz | hu | ro | et)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'create_list',
	       'query' => 'Who is able to create lists',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'This parameter is a scenario, check sympa documentation about scenarios if you want to define one'},

	      {'name'  => 'rfc2369_header_fields',
	       'query' => 'Specify which rfc2369 mailing list headers to add',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' => '' },


	      {'name'  => 'remove_headers',
	       'query' => 'Specify header fields to be removed before message distribution',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' => '' },

	      {'title' => 'Errors management'},

	      {'name'  => 'bounce_warn_rate',
	       'query' => 'Bouncing email rate for warn list owner',
	       'file' => 'sympa.conf','edit' => '1',
	       'comment' => 'bounce_warn_rate 20',
	       'advice' => '' },

	      {'name'  => 'bounce_halt_rate',
	       'query' => 'Bouncing email rate for halt the list (not implemented)',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'bounce_halt_rate 50',
	       'advice' => 'Not yet used in current version, Default is 50' },


	      {'name'  => 'expire_bounce',
	       'query' => 'Task name for expiration of old bounces',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'expire_bounce daily',
	       'advice' => '' },
	      
	      {'name'  => 'welcome_return_path',
	       'query' => 'Welcome message return-path',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'welcome_return_path unique',
	       'advice' => 'If set to unique, new subcriber is removed if welcome message bounce' },
	       
	      {'name'  => 'remind_return_path',
	       'query' => 'Remind message return-path',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' => 'If set to unique, subcriber is removed if remind message bounce, use with care' },

	      {'title' => 'MTA related'},

	      {'name' => 'sendmail',
	       'query' => 'Path to the MTA (sendmail, postfix, exim or qmail)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'nrcpt',
	       'query' => 'Maximum number of recipients per call to Sendmail',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'nrcpt 20',
	       'advice' =>''},

	      {'name' => 'avg',
	       'query' => 'Max. number of different domains per call to Sendmail',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'maxsmtp 10',
	       'advice' =>''},


	      {'name' => 'maxsmtp',
	       'query' => 'Max. number of Sendmail processes (launched by Sympa) running simultaneously',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'maxsmtp 60',
	       'advice' =>'Proposed value is quite low, you can rise it up to 100, 200 or even 300 with powerfull systems.'},

	       {'name' => 'alias_manager',
		'query' => 'Full path to program managing alias (alias_manager.pl | postfix_manager.pl) ',
		'file' => 'wwsympa.conf','edit' => '1',
		'comment' => 'alias_manager --SBINDIR--/alias_manager.pl'
		},

	      {'title' => 'Pluggin'},

	      {'name' => 'antivirus_path',
	       'query' => 'Path to the antivirus scanner engine',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'supported antivirus : McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall'},


	      {'name' => 'antivirus_args',
	       'query' => 'Antivirus pluggin command argument',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

              {'name' => 'mhonarc',
	       'query' => 'Path to MhOnarc mail2html pluggin',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'title' => 'S/MIME pluggin'},
	      {'name' => 'openssl',
	       'query' => 'Path to OpenSSL',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Sympa knowns S/MIME if openssl is installed'},

	      {'name' => 'trusted_ca_options',
	       'query' => 'The OpenSSL option string to qualify trusted CAs',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' => 'This parameter is used by sympa when sending some URL by mail'},
	      
	      {'name' => 'key_passwd',
	       'query' => 'Password used to crypt lists private keys',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'title' => 'Database'},
	      
	      {'name' => 'db_type',
	       'query' => 'Database type (mysql | Pg | Oracle | Sybase)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'be carefull to the case'},

	      {'name' => 'db_name',
	       'query' => 'Name of the database',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'db_host',
	       'query' => 'The host hosting your sympa database',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'db_port',
	       'query' => 'The database port',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'db_user',
	       'query' => 'Database user for connexion',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'db_passwd',
	       'query' => 'Database password (associated to the db_user)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'What ever you use a password or not, you must protect the SQL server (is it a not a public internet service ?)'},

	      {'name' => 'db_env',
	       'query' => 'Environment variables setting for database',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>'This is usefull for definign ORACLE_HOME '},

	      {'name'  => 'db_additional_subscriber_fields',
	       'query' => 'Database private extention to subscriber table',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'db_additional_subscriber_fields billing_delay,subscription_expiration',
	       'advice' => 'You need to extend the database format with these fields' },

	      {'title' => 'Web interface'},

	      {'name' => 'use_fast_cgi',
	       'query' => 'Is fast_cgi module for Apache (or Roxen) installed (0 | 1)',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>'This module provide much faster web interface'},

	      {'name' => 'wwsympa_url',
	       'query' => 'Sympa main page URL',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'title',
	       'query' => 'Title of main web page',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'default_home',
	       'query' => 'Main page type (lists | home)',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	       {'name' => 'default_shared_quota',
	       'query' => 'Default disk quota for shared repository',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'dark_color',
	       'query' => 'web interface color : dark',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'selected_color',
	       'query' => 'web interface color : selected_color',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'light_color',
	       'query' => 'web interface color : light',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'shaded_color',
	       'query' => 'web_interface color : shaded',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'bg_color',
	       'query' => 'web_interface color : background',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      );


## Load config 
unless ($wwsconf = &wwslib::load_config($wwsympa_conf)) {
    die('Unable to load config file %s', $wwsympa_conf);
}

#printf "Conf WWS: %s\n", join(',', %{$wwsconf});

## Load sympa config
unless (&Conf::load( $sympa_conf )) {
    die('Unable to load sympa config file %s', $sympa_conf);
}

unless (open (WWSYMPA,"> $new_wwsympa_conf")){
    printf STDERR "unable to open $new_wwsympa_conf, exiting";
    exit;
};

unless (open (SYMPA,"> $new_sympa_conf")){
    printf STDERR "unable to open $new_sympa_conf, exiting";
    exit;
};

foreach my $i (0..$#params) {
    if ($params[$i]->{'title'}) {
	my $title = $params[$i]->{'title'};
	printf "\n\n** $title **\n";
	next;
    }
    my $file = $params[$i]->{'file'} ;
    my $name = $params[$i]->{'name'} ; 
    my $query = $params[$i]->{'query'} ;
    my $advice = $params[$i]->{'advice'} ;
    my $comment = $params[$i]->{'comment'} ;
    my $current_value ;
    if ($file eq 'wwsympa.conf') {	
	$current_value = $wwsconf->{$name} ;
    }elsif ($file eq 'sympa.conf') {
	$current_value = $Conf{$name}; 
    }else {
	printf STDERR "incorrect definition of $name\n";
    }
    my $new_value;
    if ($params[$i]->{'edit'} eq '1') {
	printf "... $advice\n" unless ($advice eq '') ;
	printf "$name: $query \[$current_value\] : ";
	$new_value = <STDIN> ;
	chomp $new_value;
    }
    if ($new_value eq '') {
	$new_value = $current_value;
    }
    my $desc ;
    if ($file eq 'wwsympa.conf') {
	$desc = \*WWSYMPA;
    }elsif ($file eq 'sympa.conf') {
	$desc = \*SYMPA;
    }else{
	printf STDERR "incorrect parameter $name definition \n";
    }
    printf $desc "# $query\n";
    unless ($advice eq '') {
	printf $desc "# ... $advice\n";
    }
    
    if ($current_value ne $new_value) {
	printf $desc "# was $name $current_value\n";
	$somechange = 1;
    }elsif($comment ne '') {
	printf $desc "# $comment\n";
    }
    printf $desc "$name $new_value\n\n";
}

close SYMPA;
close WWSYMPA;

if ($somechange ne '0') {

    my $date = &POSIX::strftime("%d.%b.%Y-%H.%M.%S", localtime(time));

    unless (rename $wwsympa_conf, $wwsympa_conf.'.'.$date) {
	die "Unable to rename $wwsympa_conf\n";
    }

    unless (rename $sympa_conf, $sympa_conf.'.'.$date) {
	die "Unable to rename $sympa_conf\n";
    }

    unless (rename $new_wwsympa_conf, $wwsympa_conf) {
	die "Unable to rename $new_wwsympa_conf\n";
    }
    
    unless (rename $new_sympa_conf, $sympa_conf) {
	die "Unable to rename $new_sympa_conf\n";
    }


    printf "$sympa_conf and $wwsympa_conf have been updated.\nPrevious versions have been saved as $sympa_conf.$date and $wwsympa_conf.$date\n";
}
    


