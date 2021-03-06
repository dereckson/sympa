# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997-1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997-2011 Comite Reseau des Universites
# Copyright (c) 2011-2014 GIP RENATER
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

=encoding utf-8

=head1 NAME

Sympa::Conf - Sympa configuration

=head1 DESCRIPTION

FIXME

=cut

package Sympa::Conf;

use strict;

use English qw(-no_match_vars);
use Storable;

use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::DatabaseManager;
use Sympa::Language;
use Sympa::LockedFile;
use Sympa::Logger;
use Sympa::Tools;
use Sympa::Tools::Data;
use Sympa::Tools::File;

## Database and SQL statement handlers
my $sth;

# parameters hash, keyed by parameter name
our %params =
    map { $_->{name} => $_ }
    grep { $_->{name} } @Sympa::ConfDef::params;

# valid virtual host parameters, keyed by parameter name
my %valid_robot_key_words;
my %db_storable_parameters;
my %optional_key_words;
foreach my $hash (@Sympa::ConfDef::params) {
    $valid_robot_key_words{$hash->{'name'}} = 1 if ($hash->{'vhost'});
    $db_storable_parameters{$hash->{'name'}} = 1
        if (defined($hash->{'db'}) and $hash->{'db'} ne 'none');
    $optional_key_words{$hash->{'name'}} = 1 if ($hash->{'optional'});
}

our $params_by_categories = _get_parameters_names_by_category();

my %old_params = (
    trusted_ca_options     => 'capath,cafile',
    'msgcat'               => '',
    queueexpire            => '',
    clean_delay_queueother => '',
    pidfile_distribute     => '',
    pidfile_creation       => '',
    'web_recode_to'        => 'filesystem_encoding',    # ??? - 5.2
    'localedir'            => '',
    'html_editor_file'     => 'html_editor_url',        # 6.2a.0 - 6.2a.32
    'ldap_export_connection_timeout' => '',             # 3.3b3 - 4.1?
    'ldap_export_dnmanager'          => '',             # ,,
    'ldap_export_host'               => '',             # ,,
    'ldap_export_name'               => '',             # ,,
    'ldap_export_password'           => '',             # ,,
    'ldap_export_suffix'             => '',             # ,,
    'tri'                            => 'sort',         # ??? - 1.3.4-1
    'sort'                           => '',             # 1.4.0 - ???
    'pidfile_spooler'                => '',             # ??? - 6.2a.33
    'pidfile'                        => '',             # ,,
    'pidfile_bulk'                   => '',             # ,,
    'archived_pidfile'               => '',             # ,,
    'bounced_pidfile'                => '',             # ,,
    'task_manager_pidfile'           => '',             # ,,
    'lock_method'                    => '',             # 5.3b.3 - 6.2a.33
);

## These parameters now have a hard-coded value
## Customized value can be accessed though as %Ignored_Conf
my %Ignored_Conf;
my %hardcoded_params = (filesystem_encoding => 'utf8');

my %trusted_applications = (
    'trusted_application' => {
        'occurrence' => '0-n',
        'format'     => {
            'name' => {
                'format'     => '\S*',
                'occurrence' => '1',
                'case'       => 'insensitive',
            },
            'ip' => {
                'format'     => '\d+\.\d+\.\d+\.\d+',
                'occurrence' => '0-1'
            },
            'md5password' => {
                'format'     => '.*',
                'occurrence' => '0-1'
            },
            'proxy_for_variables' => {
                'format'     => '.*',
                'occurrence' => '0-n',
                'split_char' => ','
            }
        }
    }
);
my $binary_file_extension = ".bin";

our $wwsconf;
our %Conf = ();

=head2 FUNCTIONS

=cut

## load each virtual robots configuration files
sub load_robots {
    my $param = shift;
    my @robots;

    my $robots_list_ref = get_robots_list();
    unless (defined $robots_list_ref) {
        $main::logger->do_log(Sympa::Logger::ERR, 'robots config loading failed.');
        return undef;
    } else {
        @robots = @{$robots_list_ref};
    }
    unless (scalar @robots) {
        return 1;
    }
    my $exiting = 0;
    foreach my $robot (@robots) {
        my $config_file = "$Conf{'etc'}/$robot/robot.conf";
        unless (
            defined load_robot_conf(
                {   %$param,
                    'config_file' => $config_file,
                    'robot'       => $robot
                }
            )
            ) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'The config for robot %s contain errors: it could not be correctly loaded.',
                $robot
            );
            $exiting = 1;
        }
    }
    return undef if ($exiting);
    return 1;
}

## returns a robot conf parameter
sub get_robot_conf {
    my ($robot, $param) = @_;

    if (defined $robot && $robot ne '*') {
        if (   defined $Conf{'robots'}{$robot}
            && defined $Conf{'robots'}{$robot}{$param}) {
            return $Conf{'robots'}{$robot}{$param};
        }
    }
    ## default
    return $Conf{$param};
}

=over 4

=item get_sympa_conf

Gets path name of main config file.
Path name is taken from:

=over 4

=item 1

C<--config> command line option

=item 2

C<SYMPA_CONFIG> environment variable 

=item 3

built-in default

=back

=back

=cut

sub get_sympa_conf {
    return $main::options{'config'}
        if %main::options and defined $main::options{'config'};
    return $ENV{'SYMPA_CONFIG'} || Sympa::Constants::CONFIG;
}

=over 4

=item get_wwsympa_conf

Gets path name of wwsympa.conf file.
Path name is taken from:

=over 4

=item 1

C<SYMPA_WWSCONFIG> environment variable

=item 2

built-in default

=back

=back

=cut

sub get_wwsympa_conf {
    return $ENV{'SYMPA_WWSCONFIG'} || Sympa::Constants::WWSCONFIG;
}

# deletes all the *.conf.bin files.
sub delete_binaries {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '()');
    my @files = (get_sympa_conf(), get_wwsympa_conf());
    foreach my $robot (@{get_robots_list()}) {
        push @files, "$Conf{'etc'}/$robot/robot.conf";
    }
    foreach my $c_file (@files) {
        my $binary_file = $c_file . ".bin";
        if (-f $binary_file) {
            unless (unlink $binary_file) {
                $main::logger->do_log(
                    Sympa::Logger::NOTICE,
                    'Could not remove file %s: %s. You should remove it manually to ensure the configuration used is valid.',
                    $binary_file,
                    $ERRNO
                );
            }
        }
    }
}

# Return a reference to an array containing the names of the robots on the
# server.
sub get_robots_list {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '()');
    my @robots_list;
    unless (opendir DIR, $Conf{'etc'}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to open directory %s for virtual robots config',
            $Conf{'etc'});
        return undef;
    }
    foreach my $robot (readdir DIR) {
        my $robot_config_file = "$Conf{'etc'}/$robot/robot.conf";
        next unless (-d "$Conf{'etc'}/$robot");
        next unless (-f $robot_config_file);
        push @robots_list, $robot;
    }
    closedir(DIR);
    return \@robots_list;
}

## Returns a hash containing the values of all the parameters of the group
## (as defined in confdef.pm) whose name is given as argument, in the context
## of the robot given as argument.
sub get_parameters_group {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s)', @_);
    my ($robot, $group) = @_;
    my $param_hash;
    foreach my $param_name (keys %{$params_by_categories->{$group}}) {
        $param_hash->{$param_name} = get_robot_conf($robot, $param_name);
    }
    return $param_hash;
}

## fetch the value from parameter $label of robot $robot from conf_table
sub get_db_conf {

    my $robot = shift;
    my $label = shift;

    # if the value is related to a robot that is not explicitly defined, apply
    # it to the default robot.
    $robot = '*' unless (-f $Conf{'etc'} . '/' . $robot . '/robot.conf');
    unless ($robot) { $robot = '*' }

    unless (
        $sth = Sympa::DatabaseManager::do_query(
            "SELECT value_conf AS value FROM conf_table WHERE (robot_conf =%s AND label_conf =%s)",
            Sympa::DatabaseManager::quote($robot),
            Sympa::DatabaseManager::quote($label)
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable retrieve value of parameter %s for robot %s from the database',
            $label,
            $robot
        );
        return undef;
    }

    my $value = $sth->fetchrow;

    $sth->finish();
    return $value;
}

## store the value from parameter $label of robot $robot from conf_table
sub set_robot_conf {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s)', @_);
    my $robot = shift;
    my $label = shift;
    my $value = shift;

    # set the current config before to update database.
    if (-f "$Conf{'etc'}/$robot/robot.conf") {
        $Conf{'robots'}{$robot}{$label} = $value;
    } else {
        $Conf{$label} = $value;
        $robot = '*';
    }

    unless (
        $sth = Sympa::DatabaseManager::do_query(
            "SELECT count(*) FROM conf_table WHERE (robot_conf=%s AND label_conf =%s)",
            Sympa::DatabaseManager::quote($robot),
            Sympa::DatabaseManager::quote($label)
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to check presence of parameter %s for robot %s in database',
            $label,
            $robot
        );
        return undef;
    }

    my $count = $sth->fetchrow;
    $sth->finish();

    if ($count == 0) {
        unless (
            $sth = Sympa::DatabaseManager::do_query(
                "INSERT INTO conf_table (robot_conf, label_conf, value_conf) VALUES (%s,%s,%s)",
                Sympa::DatabaseManager::quote($robot),
                Sympa::DatabaseManager::quote($label),
                Sympa::DatabaseManager::quote($value)
            )
            ) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Unable add value %s for parameter %s in the robot %s DB conf',
                $value,
                $label,
                $robot
            );
            return undef;
        }
    } else {
        unless (
            $sth = Sympa::DatabaseManager::do_query(
                "UPDATE conf_table SET robot_conf=%s, label_conf=%s, value_conf=%s WHERE ( robot_conf  =%s AND label_conf =%s)",
                Sympa::DatabaseManager::quote($robot),
                Sympa::DatabaseManager::quote($label),
                Sympa::DatabaseManager::quote($value),
                Sympa::DatabaseManager::quote($robot),
                Sympa::DatabaseManager::quote($label)
            )
            ) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Unable set parameter %s value to %s in the robot %s DB conf',
                $label,
                $value,
                $robot
            );
            return undef;
        }
    }
}

# Store configs to database
sub conf_2_db {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s)', @_);

    my @conf_parameters = @Sympa::ConfDef::params;

    # store in database robots parameters.
    # load only parameters that are in a robot.conf file (do not apply
    # defaults).
    load_robots();

    unless (opendir DIR, $Conf{'etc'}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to open directory %s for virtual robots config',
            $Conf{'etc'});
        return undef;
    }

    foreach my $robot (readdir(DIR)) {
        next unless (-d "$Conf{'etc'}/$robot");
        next unless (-f "$Conf{'etc'}/$robot/robot.conf");

        my $config;
        my $result;
        if ($result = _load_config_file_to_hash(
                {         'config_file' => $Conf{'etc'} . '/' 
                        . $robot
                        . '/robot.conf'
                }
            )
            ) {
            $config = $result->{'config'};
        }
        _remove_unvalid_robot_entry($config);

        for my $i (0 .. $#conf_parameters) {
            if ($conf_parameters[$i]->{'name'}) {

                # skip separators in conf_parameters structure
                if (($conf_parameters[$i]->{'vhost'} eq '1')
                    && #skip parameters that can't be define by robot so not to be loaded in db at that stage
                    ($config->{$conf_parameters[$i]->{'name'}})
                    ) {
                    Sympa::Conf::set_robot_conf(
                        $robot,
                        $conf_parameters[$i]->{'name'},
                        $config->{$conf_parameters[$i]->{'name'}}
                    );
                }
            }
        }
    }
    closedir(DIR);

    # store sympa.conf into database.

    ## Load configuration file. Ignoring database config and get result
    my $global_conf;
    unless ($global_conf =
        Sympa::Site->load('no_db' => 1, 'return_result' => 1)) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Configuration file %s has errors.',
            get_sympa_conf());
        return undef;
    }

    for my $i (0 .. $#conf_parameters) {
        if (($conf_parameters[$i]->{'edit'} eq '1')
            && $global_conf->{$conf_parameters[$i]->{'name'}}) {
            Sympa::Conf::set_robot_conf(
                "*",
                $conf_parameters[$i]->{'name'},
                $global_conf->{$conf_parameters[$i]->{'name'}}[0]
            );
        }
    }
}

## Check required files and create them if required
sub checkfiles_as_root {

    my $config_err = 0;

    ## Check aliases file
    unless (-f $Conf{'sendmail_aliases'}
        || ($Conf{'sendmail_aliases'} =~ /^none$/i)) {
        unless (open ALIASES, ">$Conf{'sendmail_aliases'}") {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Failed to create aliases file %s',
                $Conf{'sendmail_aliases'}
            );
            return undef;
        }

        print ALIASES
            "## This aliases file is dedicated to Sympa Mailing List Manager\n";
        print ALIASES
            "## You should edit your sendmail.mc or sendmail.cf file to declare it\n";
        close ALIASES;
        $main::logger->do_log(
            Sympa::Logger::NOTICE,
            "Created missing file %s",
            $Conf{'sendmail_aliases'}
        );
        unless (
            Sympa::Tools::File::set_file_rights(
                file  => $Conf{'sendmail_aliases'},
                user  => Sympa::Constants::USER,
                group => Sympa::Constants::GROUP,
                mode  => 0644,
            )
            ) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Unable to set rights on %s',
                $Conf{'sendmail_aliases'}
            );
            return undef;
        }
    }

    foreach my $robot (keys %{$Conf{'robots'}}) {

        # create static content directory
        my $dir = get_robot_conf($robot, 'static_content_path');
        if ($dir ne '' && !-d $dir) {
            unless (mkdir($dir, 0775)) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Unable to create directory %s: %s',
                    $dir, $ERRNO);
                $config_err++;
            }

            unless (
                Sympa::Tools::File::set_file_rights(
                    file  => $dir,
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
                )
                ) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Unable to set rights on %s', $dir);
                return undef;
            }
        }
    }

    return 1;
}

## Check a few files
sub checkfiles {
    my $config_err = 0;

    foreach my $p ('sendmail', 'openssl', 'antivirus_path') {
        next unless $Conf{$p};

        unless (-x $Conf{$p}) {
            $main::logger->do_log(Sympa::Logger::ERR,
                "File %s does not exist or is not executable",
                $Conf{$p});
            $config_err++;
        }
    }

    foreach my $qdir (
        'spool',          'queue',
        'queueautomatic', 'queuedigest',
        'queuemod',       'queuetopic',
        'queueauth',      'queueoutgoing',
        'queuebounce',    'queuesubscribe',
        'queuetask',      'queuedistribute',
        'tmpdir'
        ) {
        unless (-d $Conf{$qdir}) {
            $main::logger->do_log(Sympa::Logger::INFO, "creating spool $Conf{$qdir}");
            unless (mkdir($Conf{$qdir}, 0775)) {
                $main::logger->do_log(Sympa::Logger::ERR, 'Unable to create spool %s',
                    $Conf{$qdir});
                $config_err++;
            }
            unless (
                Sympa::Tools::File::set_file_rights(
                    file  => $Conf{$qdir},
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
                )
                ) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Unable to set rights on %s',
                    $Conf{$qdir});
                $config_err++;
            }
        }
    }

    ## Also create associated bad/ spools
    foreach my $qdir ('queue', 'queuedistribute', 'queueautomatic') {
        my $subdir = $Conf{$qdir} . '/bad';
        unless (-d $subdir) {
            $main::logger->do_log(Sympa::Logger::INFO, 'creating spool %s', $subdir);
            unless (mkdir($subdir, 0775)) {
                $main::logger->do_log(Sympa::Logger::ERR, 'Unable to create spool %s',
                    $subdir);
                $config_err++;
            }
            unless (
                Sympa::Tools::File::set_file_rights(
                    file  => $subdir,
                    user  => Sympa::Constants::USER,
                    group => Sympa::Constants::GROUP,
                )
                ) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Unable to set rights on %s', $subdir);
                $config_err++;
            }
        }
    }

    ## Check cafile and capath access
    if (defined $Conf{'cafile'} && $Conf{'cafile'}) {
        unless (-f $Conf{'cafile'} && -r $Conf{'cafile'}) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Cannot access cafile %s',
                $Conf{'cafile'});
            Sympa::Site->send_notify_to_listmaster('cannot_access_cafile',
                $Conf{'cafile'});
            $config_err++;
        }
    }

    if (defined $Conf{'capath'} && $Conf{'capath'}) {
        unless (-d $Conf{'capath'} && -x $Conf{'capath'}) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Cannot access capath %s',
                $Conf{'capath'});
            Sympa::Site->send_notify_to_listmaster('cannot_access_capath',
                $Conf{'capath'});
            $config_err++;
        }
    }

    ## queuebounce and bounce_path pointing to the same directory
    if ($Conf{'queuebounce'} eq $wwsconf->{'bounce_path'}) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Error in config: queuebounce and bounce_path parameters pointing to the same directory (%s)',
            $Conf{'queuebounce'}
        );
        Sympa::Site->send_notify_to_listmaster(
            'queuebounce_and_bounce_path_are_the_same',
            $Conf{'queuebounce'});
        $config_err++;
    }

    #  create pictures dir if usefull for each robot
    foreach my $robot_id (keys %{$Conf{'robots'}}) {
        my $robot = Sympa::VirtualHost->new($robot_id);
        my $dir   = $robot->static_content_path;
        if ($dir ne '' && -d $dir) {
            unless (-f $dir . '/index.html') {
                unless (open(FF, ">$dir" . '/index.html')) {
                    $main::logger->do_log(
                        Sympa::Logger::ERR,
                        'Unable to create %s/index.html as an empty file to protect directory: %s',
                        $dir,
                        $ERRNO
                    );
                }
                close FF;
            }

            # create picture dir
            if ($robot->pictures_feature eq 'on') {
                my $pictures_dir = $robot->static_content_path . '/pictures';
                unless (-d $pictures_dir) {
                    unless (mkdir($pictures_dir, 0775)) {
                        $main::logger->do_log(Sympa::Logger::ERR,
                            'Unable to create directory %s',
                            $pictures_dir);
                        $config_err++;
                    }
                    chmod 0775, $pictures_dir;

                    my $index_path = $pictures_dir . '/index.html';
                    unless (-f $index_path) {
                        unless (open(FF, ">$index_path")) {
                            $main::logger->do_log(
                                Sympa::Logger::ERR,
                                'Unable to create %s as an empty file to protect directory',
                                $index_path
                            );
                        }
                        close FF;
                    }
                }
            }
        }
    }

    # create or update static CSS files
    my $css_updated = undef;
    foreach my $robot_id (keys %{$Conf{'robots'}}) {
        my $robot = Sympa::VirtualHost->new($robot_id);
        my $dir   = $robot->css_path;

        ## Get colors for parsing
        my $param = {};
        foreach my $p (%params) {
            $param->{$p} = get_robot_conf($robot_id, $p)
                if $p =~ /_color$/
                    or $p =~ /color_/;
        }

        ## Set TT2 path
        my $tt2_include_path = $robot->get_etc_include_path('web_tt2');

        ## Create directory if required
        unless (-d $dir) {
            unless (Sympa::Tools::File::mkdir_all($dir, 0755)) {
                my $msg = "Failed to create directory $dir: $ERRNO";
                $main::logger->do_log(Sympa::Logger::ERR, '%s', $msg);
                $robot->send_notify_to_listmaster('cannot_mkdir', $msg);
                return undef;
            }
        }

        foreach my $css ('style.css', 'print.css', 'fullPage.css',
            'print-preview.css') {

            $param->{'css'} = $css;
            my $css_tt2_path = $robot->get_etc_filename('web_tt2/css.tt2');

            ## Update the CSS if it is missing or if a new css.tt2 was
            ## installed
            if (!-f $dir . '/' . $css
                || (stat($css_tt2_path))[9] > (stat($dir . '/' . $css))[9]) {
                $main::logger->do_log(
                    Sympa::Logger::NOTICE,
                    'TT2 file %s has changed; updating static CSS file %s/%s ; previous file renamed',
                    $css_tt2_path,
                    $dir,
                    $css
                );

                ## Keep copy of previous file
                rename $dir . '/' . $css, $dir . '/' . $css . '.' . time;

                unless (open CSS, '>', "$dir/$css") {
                    my $msg = "Could not open (write) file $dir/$css: $ERRNO";
                    $robot->send_notify_to_listmaster('cannot_open_file',
                        $msg);
                    $main::logger->do_log(Sympa::Logger::ERR, '%s', $msg);
                    return undef;
                }

                unless (
                    Sympa::Template::parse_tt2(
                        $param, 'css.tt2', \*CSS, $tt2_include_path
                    )
                    ) {
                    my $error = Sympa::Template::get_error();
                    $param->{'tt2_error'} = $error;
                    $robot->send_notify_to_listmaster('web_tt2_error',
                        $error);
                    $main::logger->do_log(Sympa::Logger::ERR,
                        'Error while installing %s/%s',
                        $dir, $css);
                }

                $css_updated++;

                close(CSS);

                ## Make the CSS world-readable
                chmod 0644, $dir . '/' . $css;
            }
        }
    }
    if ($css_updated) {
        ## Notify main listmaster
        Sympa::Site->send_notify_to_listmaster('css_updated',
            "Static CSS files have been updated ; check log file for details"
        );
    }

    return undef if ($config_err);
    return 1;
}

## return 1 if the parameter is a known robot
## Valid options :
##    'just_try' : prevent error logs if robot is not valid
sub valid_robot {
    my $robot   = shift;
    my $options = shift;

    ## Main host
    return 1 if ($robot eq $Conf{'domain'});

    ## Missing etc directory
    unless (-d $Conf{'etc'} . '/' . $robot) {
        $main::logger->do_log(
            Sympa::Logger::ERR,  'Robot %s undefined ; no %s directory',
            $robot, $Conf{'etc'} . '/' . $robot
        ) unless ($options->{'just_try'});
        return undef;
    }

    ## Missing expl directory
    unless (-d $Conf{'home'} . '/' . $robot) {
        $main::logger->do_log(
            Sympa::Logger::ERR,  'Robot %s undefined ; no %s directory',
            $robot, $Conf{'home'} . '/' . $robot
        ) unless ($options->{'just_try'});
        return undef;
    }

    ## Robot not loaded
    unless (defined $Conf{'robots'}{$robot}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Robot %s was not loaded by this Sympa process', $robot)
            unless ($options->{'just_try'});
        return undef;
    }

    return 1;
}

## Returns the SSO record correponding to the provided sso_id
## return undef if none was found
sub get_sso_by_id {
    my %param = @_;

    unless (defined $param{'service_id'} && defined $param{'robot'}) {
        return undef;
    }

    foreach my $sso (@{$Conf{'auth_services'}{$param{'robot'}}}) {
        $main::logger->do_log(Sympa::Logger::DEBUG3, 'SSO: %s', $sso->{'service_id'});
        next unless ($sso->{'service_id'} eq $param{'service_id'});

        return $sso;
    }

    return undef;
}

##########################################
## Low level subs. Not supposed to be called from other modules.
##########################################

sub _load_auth {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $robot         = shift;
    my $is_main_robot = shift;

    # find appropriate auth.conf file
    my $config_file =
        _get_config_file_name({'robot' => $robot, 'file' => "auth.conf"});
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'config_file: %s', $config_file);

    $robot ||= $Conf{'domain'};
    my $line_num   = 0;
    my $config_err = 0;
    my @paragraphs;
    my %result;
    my $current_paragraph;

    my %valid_keywords = (
        'ldap' => {
            'regexp'          => '.*',
            'negative_regexp' => '.*',
            'host'            => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
            'timeout'         => '\d+',
            'suffix'          => '.+',
            'bind_dn'         => '.+',
            'bind_password'   => '.+',
            'get_dn_by_uid_filter'        => '.+',
            'get_dn_by_email_filter'      => '.+',
            'email_attribute'             => '\w+',
            'alternative_email_attribute' => '(\w+)(,\w+)*',
            'scope'                       => 'base|one|sub',
            'authentication_info_url'     => 'http(s)?:/.*',
            'use_ssl'                     => '1',
            'ssl_version'                 => 'sslv2/3|sslv2|sslv3|tlsv1',
            'ssl_ciphers'                 => '[\w:]+'
        },

        'user_table' => {
            'regexp'          => '.*',
            'negative_regexp' => '.*'
        },

        'cas' => {
            'base_url'                   => 'http(s)?:/.*',
            'non_blocking_redirection'   => 'on|off',
            'login_path'                 => '.*',
            'logout_path'                => '.*',
            'service_validate_path'      => '.*',
            'proxy_path'                 => '.*',
            'proxy_validate_path'        => '.*',
            'auth_service_name'          => '[\w\-\.]+',
            'auth_service_friendly_name' => '.*',
            'authentication_info_url'    => 'http(s)?:/.*',
            'ldap_host'    => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
            'ldap_bind_dn' => '.+',
            'ldap_bind_password'           => '.+',
            'ldap_timeout'                 => '\d+',
            'ldap_suffix'                  => '.+',
            'ldap_scope'                   => 'base|one|sub',
            'ldap_get_email_by_uid_filter' => '.+',
            'ldap_email_attribute'         => '\w+',
            'ldap_use_ssl'                 => '1',
            'ldap_ssl_version'             => 'sslv2/3|sslv2|sslv3|tlsv1',
            'ldap_ssl_ciphers'             => '[\w:]+'
        },
        'generic_sso' => {
            'service_name'                => '.+',
            'service_id'                  => '\S+',
            'http_header_prefix'          => '\w+',
            'http_header_list'            => '[\w\.\-\,]+',
            'email_http_header'           => '\w+',
            'http_header_value_separator' => '.+',
            'logout_url'                  => '.+',
            'ldap_host'    => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
            'ldap_bind_dn' => '.+',
            'ldap_bind_password'           => '.+',
            'ldap_timeout'                 => '\d+',
            'ldap_suffix'                  => '.+',
            'ldap_scope'                   => 'base|one|sub',
            'ldap_get_email_by_uid_filter' => '.+',
            'ldap_email_attribute'         => '\w+',
            'ldap_use_ssl'                 => '1',
            'ldap_ssl_version'             => 'sslv2/3|sslv2|sslv3|tlsv1',
            'ldap_ssl_ciphers'             => '[\w:]+',
            'force_email_verify'           => '1',
            'internal_email_by_netid'      => '1',
            'netid_http_header'            => '[\w\-\.]+',
        },
        'authentication_info_url' => 'http(s)?:/.*'
    );

    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config_file)) {
        $main::logger->do_log(Sympa::Logger::NOTICE, 'Unable to open %s: %s',
            $config_file, $ERRNO);
        return undef;
    }

    $Conf{'cas_number'}{$robot}         = 0;
    $Conf{'generic_sso_number'}{$robot} = 0;
    $Conf{'ldap_number'}{$robot}        = 0;
    $Conf{'use_passwd'}{$robot}         = 0;

    ## Parsing  auth.conf
    while (<IN>) {

        $line_num++;
        next if (/^\s*[\#\;]/o);

        if (/^\s*authentication_info_url\s+(.*\S)\s*$/o) {
            $Conf{'authentication_info_url'}{$robot} = $1;
            next;
        } elsif (/^\s*(ldap|cas|user_table|generic_sso)\s*$/io) {
            $current_paragraph->{'auth_type'} = lc($1);
        } elsif (/^\s*(\S+)\s+(.*\S)\s*$/o) {
            my ($keyword, $value) = ($1, $2);
            unless (
                defined $valid_keywords{$current_paragraph->{'auth_type'}}
                {$keyword}) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'unknown keyword "%s" in %s line %d',
                    $keyword, $config_file, $line_num);
                next;
            }
            unless ($value =~
                /^$valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}$/
                ) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'unknown format "%s" for keyword "%s" in %s line %d',
                    $value, $keyword, $config_file, $line_num);
                next;
            }

            ## Allow white spaces between hosts
            if ($keyword =~ /host$/) {
                $value =~ s/\s//g;
            }

            $current_paragraph->{$keyword} = $value;
        }

        ## process current paragraph
        if (/^\s+$/o || eof(IN)) {
            if (defined($current_paragraph)) {

                if ($current_paragraph->{'auth_type'} eq 'cas') {
                    unless (defined $current_paragraph->{'base_url'}) {
                        $main::logger->do_log(Sympa::Logger::ERR,
                            'Incorrect CAS paragraph in auth.conf');
                        next;
                    }

                    eval "require AuthCAS";
                    if ($EVAL_ERROR) {
                        $main::logger->do_log(Sympa::Logger::ERR,
                            'Failed to load AuthCAS perl module');
                        return undef;
                    }

                    my $cas_param =
                        {casUrl => $current_paragraph->{'base_url'}};

                    ## Optional parameters
                    ## We should also cope with X509 CAs
                    $cas_param->{'loginPath'} =
                        $current_paragraph->{'login_path'}
                        if (defined $current_paragraph->{'login_path'});
                    $cas_param->{'logoutPath'} =
                        $current_paragraph->{'logout_path'}
                        if (defined $current_paragraph->{'logout_path'});
                    $cas_param->{'serviceValidatePath'} =
                        $current_paragraph->{'service_validate_path'}
                        if (
                        defined $current_paragraph->{'service_validate_path'}
                        );
                    $cas_param->{'proxyPath'} =
                        $current_paragraph->{'proxy_path'}
                        if (defined $current_paragraph->{'proxy_path'});
                    $cas_param->{'proxyValidatePath'} =
                        $current_paragraph->{'proxy_validate_path'}
                        if (
                        defined $current_paragraph->{'proxy_validate_path'});

                    $current_paragraph->{'cas_server'} =
                        AuthCAS->new(%{$cas_param});
                    unless (defined $current_paragraph->{'cas_server'}) {
                        $main::logger->do_log(
                            Sympa::Logger::ERR,
                            'Failed to create CAS object for %s: %s',
                            $current_paragraph->{'base_url'},
                            AuthCAS::get_errors()
                        );
                        next;
                    }

                    $Conf{'cas_number'}{$robot}++;
                    $Conf{'cas_id'}{$robot}
                        {$current_paragraph->{'auth_service_name'}}{'id'} =
                        $#paragraphs + 1;

                    ## Default value for auth_service_friendly_name IS
                    ## auth_service_name
                    $Conf{'cas_id'}{$robot}
                        {$current_paragraph->{'auth_service_name'}}
                        {'auth_service_friendly_name'} =
                           $current_paragraph->{'auth_service_friendly_name'}
                        || $current_paragraph->{'auth_service_name'};

                    ## Force the default scope because '' is interpreted as
                    ## 'base'
                    $current_paragraph->{'ldap_scope'} ||= 'sub';
                } elsif ($current_paragraph->{'auth_type'} eq 'generic_sso') {
                    $Conf{'generic_sso_number'}{$robot}++;
                    $Conf{'generic_sso_id'}{$robot}
                        {$current_paragraph->{'service_id'}} =
                        $#paragraphs + 1;
                    ## Force the default scope because '' is interpreted as
                    ## 'base'
                    $current_paragraph->{'ldap_scope'} ||= 'sub';
                    ## default value for http_header_value_separator is ';'
                    $current_paragraph->{'http_header_value_separator'} ||=
                        ';';

                    ## CGI.pm changes environment variable names ('-' => '_')
                    ## declared environment variable names needs to be
                    ## transformed accordingly
                    foreach my $parameter ('http_header_list',
                        'email_http_header', 'netid_http_header') {
                        $current_paragraph->{$parameter} =~ s/\-/\_/g
                            if (defined $current_paragraph->{$parameter});
                    }
                } elsif ($current_paragraph->{'auth_type'} eq 'ldap') {
                    $Conf{'ldap'}{$robot}++;
                    $Conf{'use_passwd'}{$robot} = 1;
                    ## Force the default scope because '' is interpreted as
                    ## 'base'
                    $current_paragraph->{'scope'} ||= 'sub';
                } elsif ($current_paragraph->{'auth_type'} eq 'user_table') {
                    $Conf{'use_passwd'}{$robot} = 1;
                }

                # setting default
                $current_paragraph->{'regexp'} = '.*'
                    unless (defined($current_paragraph->{'regexp'}));
                $current_paragraph->{'non_blocking_redirection'} = 'on'
                    unless (
                    defined($current_paragraph->{'non_blocking_redirection'})
                    );
                push(@paragraphs, $current_paragraph);

                undef $current_paragraph;
            }
            next;
        }
    }
    close(IN);

    return \@paragraphs;

}

## load charset.conf file (charset mapping for service messages)
sub load_charset {
    my $charset = {};

    my $config_file =
        _get_config_file_name({'robot' => '', 'file' => "charset.conf"});
    if (-f $config_file) {
        unless (open CONFIG, $config_file) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unable to read configuration file %s: %s',
                $config_file, $ERRNO);
            return {};
        }
        while (<CONFIG>) {
            chomp $_;
            s/\s*#.*//;
            s/^\s+//;
            next unless /\S/;
            my ($lang, $cset) = split(/\s+/, $_);
            unless ($cset) {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Charset name is missing in configuration file %s line %d',
                    $config_file,
                    $.
                );
                next;
            }
	    # canonicalize lang if possible.
	    $lang = Sympa::Language::canonic_lang($lang) || $lang;
	    $charset->{$lang} = $cset;
        }
        close CONFIG;
    }

    return $charset;
}

## load nrcpt file (limite receipient par domain
sub load_nrcpt_by_domain {
    my $config_file = _get_config_file_name(
        {'robot' => '', 'file' => "nrcpt_by_domain.conf"});
    return undef unless (-r $config_file);
    my $line_num   = 0;
    my $config_err = 0;
    my $nrcpt_by_domain;
    my $valid_dom = 0;

    return undef unless (-f $config_file);
    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config_file)) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Unable to open %s: %s',
            $config_file, $ERRNO);
        return undef;
    }
    while (<IN>) {
        $line_num++;
        next if (/^\s*$/o || /^[\#\;]/o);
        if (/^(\S+)\s+(\d+)$/io) {
            my ($domain, $value) = ($1, $2);
            chomp $domain;
            chomp $value;
            $nrcpt_by_domain->{$domain} = $value;
            $valid_dom += 1;
        } else {
            $main::logger->do_log(Sympa::Logger::NOTICE,
                'Error at line %d: %s',
                $line_num, $config_file, $_);
            $config_err++;
        }
    }
    close(IN);
    return ($nrcpt_by_domain);
}

## load .sql named filter conf file
sub load_sql_filter {

    my $file                    = shift;
    my %sql_named_filter_params = (
        'sql_named_filter_query' => {
            'occurrence' => '1',
            'format'     => {
                'db_type'   => {'format' => 'mysql|SQLite|Pg|Oracle|Sybase',},
                'db_name'   => {'format' => '.*', 'occurrence' => '1',},
                'db_host'   => {'format' => '.*', 'occurrence' => '1',},
                'statement' => {'format' => '.*', 'occurrence' => '1',},
                'db_user'   => {'format' => '.*', 'occurrence' => '0-1',},
                'db_passwd' => {'format' => '.*', 'occurrence' => '0-1',},
                'db_options' => {'format' => '.*', 'occurrence' => '0-1',},
                'db_env'     => {'format' => '.*',  'occurrence' => '0-1',},
                'db_port'    => {'format' => '\d+', 'occurrence' => '0-1',},
                'db_timeout' => {'format' => '\d+', 'occurrence' => '0-1',},
            }
        }
    );

    return undef unless (-r $file);

    return (
        load_generic_conf_file($file, \%sql_named_filter_params, 'abort'));
}

## load automatic_list_description.conf configuration file
sub load_automatic_lists_description {
    my $robot  = shift;
    my $family = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG2, 'Starting: robot %s family %s',
        $robot, $family);

    my %automatic_lists_params = (
        'class' => {
            'occurrence' => '1-n',
            'format'     => {
                'name'        => {'format' => '.*',  'occurrence' => '1',},
                'stamp'       => {'format' => '.*',  'occurrence' => '1',},
                'description' => {'format' => '.*',  'occurrence' => '1',},
                'order'       => {'format' => '\d+', 'occurrence' => '1',},
                'instances' => {'occurrence' => '1', 'format' => '.*',},

                #'format' => {
                #'instance' => {
                #'occurrence' => '1-n',
                #'format' => {
                #'value' => {'format' => '.*', 'occurrence' => '1', },
                #'tag' => {'format' => '.*', 'occurrence' => '1', },
                #'order' => {'format' => '\d+', 'occurrence' => '1',  },
                #},
                #},
                #},
            },
        },
    );

    # find appropriate automatic_lists_description.tt2 file
    my $config;
    if (defined $robot) {
        $config =
              $Conf{'etc'} . '/' 
            . $robot
            . '/families/'
            . $family
            . '/automatic_lists_description.conf';
    } else {
        $config =
              $Conf{'etc'}
            . '/families/'
            . $family
            . '/automatic_lists_description.conf';
    }
    return undef unless (-r $config);
    my $description =
        load_generic_conf_file($config, \%automatic_lists_params);

    ## Now doing some structuration work because
    ## Sympa::Conf::load_automatic_lists_description() can't handle
    ## data structured beyond one level of hash. This needs to be changed.
    my @structured_data;
    foreach my $class (@{$description->{'class'}}) {
        my @structured_instances;
        my @instances = split '%%%', $class->{'instances'};
        my $default_found = 0;
        foreach my $instance (@instances) {
            my $structured_instance;
            my @instance_params = split '---', $instance;
            foreach my $instance_param (@instance_params) {
                $instance_param =~ /^\s*(\S+)\s+(.*)\s*$/;
                my $key   = $1;
                my $value = $2;
                $key   =~ s/^\s*//;
                $key   =~ s/\s*$//;
                $value =~ s/^\s*//;
                $value =~ s/\s*$//;
                $structured_instance->{$key} = $value;
            }
            $structured_instances[$structured_instance->{'order'}] =
                $structured_instance;
            if (defined $structured_instance->{'default'}) {
                $default_found = 1;
            }
        }
        unless ($default_found) { $structured_instances[0]->{'default'} = 1; }
        $class->{'instances'} = \@structured_instances;
        $structured_data[$class->{'order'}] = $class;
    }
    $description->{'class'} = \@structured_data;
    return $description;
}

## load trusted_application.conf configuration file
sub load_trusted_application {
    # find appropriate trusted-application.conf file
    my $config_file =
        _get_config_file_name({'file' => "trusted_applications.conf"});
    return undef unless -r $config_file;
    return load_generic_conf_file($config_file, \%trusted_applications);
}

## load trusted_application.conf configuration file
sub load_crawlers_detection {
    my $robot = shift;

    my %crawlers_detection_conf = (
        'user_agent_string' => {
            'occurrence' => '0-n',
            'format'     => '.+'
        }
    );

    my $config_file = _get_config_file_name(
        {'robot' => $robot, 'file' => "crawlers_detection.conf"});
    return undef unless (-r $config_file);
    my $hashtab =
        load_generic_conf_file($config_file, \%crawlers_detection_conf);
    my $hashhash;

    foreach my $kword (keys %{$hashtab}) {

        # ignore comments and default
        next
            unless ($crawlers_detection_conf{$kword});
        foreach my $value (@{$hashtab->{$kword}}) {
            $hashhash->{$kword}{$value} = 'true';
        }
    }

    return $hashhash;
}

############################################################
#  load_generic_conf_file
############################################################
#  load a generic config organized by paragraph syntax
#
# IN : -$config_file (+): full path of config file
#      -$structure_ref (+): ref(HASH) describing expected syntax
#      -$on_error: optional. sub returns undef if set to 'abort'
#          and an error is found in conf file
# OUT : ref(HASH) of parsed parameters
#     | undef
#
##############################################################
sub load_generic_conf_file {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s)', @_);
    my $config_file   = shift;
    my $structure_ref = shift;
    my $on_error      = shift;
    my %structure     = %$structure_ref;

    my %admin;
    my (@paragraphs);

    ## Just in case...
    local $RS = "\n";

    ## Set defaults to 1
    foreach my $pname (keys %structure) {
        $admin{'defaults'}{$pname} = 1
            unless ($structure{$pname}{'internal'});
    }

    ## Split in paragraphs
    my $i = 0;
    unless (open(CONFIG, $config_file)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'unable to read configuration file %s', $config_file);
        return undef;
    }
    while (<CONFIG>) {
        if (/^\s*$/) {
            $i++ if $paragraphs[$i];
        } else {
            push @{$paragraphs[$i]}, $_;
        }
    }

    ## Parse each paragraph
    for my $index (0 .. $#paragraphs) {
        my @paragraph = @{$paragraphs[$index]};

        my $pname;

        ## Clean paragraph, keep comments
        for my $i (0 .. $#paragraph) {
            my $changed = undef;
            for my $j (0 .. $#paragraph) {
                if ($paragraph[$j] =~ /^\s*\#/) {
                    chomp($paragraph[$j]);
                    push @{$admin{'comment'}}, $paragraph[$j];
                    splice @paragraph, $j, 1;
                    $changed = 1;
                } elsif ($paragraph[$j] =~ /^\s*$/) {
                    splice @paragraph, $j, 1;
                    $changed = 1;
                }
                last if $changed;
            }
            last unless $changed;
        }

        ## Empty paragraph
        next unless ($#paragraph > -1);

        ## Look for first valid line
        unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
            $main::logger->do_log(Sympa::Logger::NOTICE,
                'Bad paragraph "%s" in %s, ignored',
                $paragraph[0], $config_file);
            return undef if $on_error eq 'abort';
            next;
        }

        $pname = $1;
        unless (defined $structure{$pname}) {
            $main::logger->do_log(Sympa::Logger::NOTICE,
                'Unknown parameter "%s" in %s, ignored',
                $pname, $config_file);
            return undef if $on_error eq 'abort';
            next;
        }
        ## Uniqueness
        if (defined $admin{$pname}) {
            unless (($structure{$pname}{'occurrence'} eq '0-n')
                or ($structure{$pname}{'occurrence'} eq '1-n')) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Multiple parameter "%s" in %s',
                    $pname, $config_file);
                return undef if $on_error eq 'abort';
            }
        }

        ## Line or Paragraph
        if (ref $structure{$pname}{'format'} eq 'HASH') {
            ## This should be a paragraph
            unless ($#paragraph > 0) {
                $main::logger->do_log(
                    Sympa::Logger::NOTICE,
                    'Expecting a paragraph for "%s" parameter in %s, ignore it',
                    $pname,
                    $config_file
                );
                return undef if $on_error eq 'abort';
                next;
            }

            ## Skipping first line
            shift @paragraph;

            my %hash;
            for my $i (0 .. $#paragraph) {
                next if ($paragraph[$i] =~ /^\s*\#/);
                unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
                    $main::logger->do_log(Sympa::Logger::ERR, 'Bad line "%s" in %s',
                        $paragraph[$i], $config_file);
                    return undef if $on_error eq 'abort';
                }
                my $key = $1;
                unless (defined $structure{$pname}{'format'}{$key}) {
                    $main::logger->do_log(Sympa::Logger::ERR,
                        'Unknown key "%s" in paragraph "%s" in %s',
                        $key, $pname, $config_file);
                    return undef if $on_error eq 'abort';
                    next;
                }

                unless ($paragraph[$i] =~
                    /^\s*$key\s+($structure{$pname}{'format'}{$key}{'format'})\s*$/i
                    ) {
                    $main::logger->do_log(Sympa::Logger::ERR,
                        'Bad entry "%s" in paragraph "%s" in %s',
                        $paragraph[$i], $key, $pname, $config_file);
                    return undef if $on_error eq 'abort';
                    next;
                }

                $hash{$key} =
                    _load_a_param($key, $1,
                    $structure{$pname}{'format'}{$key});
            }

            ## Apply defaults & Check required keys
            my $missing_required_field;
            foreach my $k (keys %{$structure{$pname}{'format'}}) {
                ## Default value
                unless (defined $hash{$k}) {
                    if (defined $structure{$pname}{'format'}{$k}{'default'}) {
                        $hash{$k} =
                            _load_a_param($k, 'default',
                            $structure{$pname}{'format'}{$k});
                    }
                }
                ## Required fields
                if ($structure{$pname}{'format'}{$k}{'occurrence'} eq '1') {
                    unless (defined $hash{$k}) {
                        $main::logger->do_log(Sympa::Logger::ERR,
                            'Missing key %s in param %s in %s',
                            $k, $pname, $config_file);
                        return undef if $on_error eq 'abort';
                        $missing_required_field++;
                    }
                }
            }

            next if $missing_required_field;

            delete $admin{'defaults'}{$pname};

            ## Should we store it in an array
            if (($structure{$pname}{'occurrence'} =~ /n$/)) {
                push @{$admin{$pname}}, \%hash;
            } else {
                $admin{$pname} = \%hash;
            }
        } else {
            ## This should be a single line
            my $xxxmachin = $structure{$pname}{'format'};
            unless ($#paragraph == 0) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Expecting a single line for %s parameter in %s %s',
                    $pname, $config_file, $xxxmachin);
                return undef if $on_error eq 'abort';
            }

            unless ($paragraph[0] =~
                /^\s*$pname\s+($structure{$pname}{'format'})\s*$/i) {
                $main::logger->do_log(Sympa::Logger::ERR, 'Bad entry "%s" in %s',
                    $paragraph[0], $config_file);
                return undef if $on_error eq 'abort';
                next;
            }

            my $value = _load_a_param($pname, $1, $structure{$pname});

            delete $admin{'defaults'}{$pname};

            if (($structure{$pname}{'occurrence'} =~ /n$/)
                && !(ref($value) =~ /^ARRAY/)) {
                push @{$admin{$pname}}, $value;
            } else {
                $admin{$pname} = $value;
            }
        }
    }
    close CONFIG;
    return \%admin;
}

### load_a_param
#
sub _load_a_param {
    my (undef, $value, $p) = @_;

    ## Empty value
    if ($value =~ /^\s*$/) {
        return undef;
    }

    ## Default
    if ($value eq 'default') {
        $value = $p->{'default'};
    }
    ## lower case if usefull
    $value = lc($value)
        if (defined $p->{'case'} && $p->{'case'} eq 'insensitive');

    ## Do we need to split param if it is not already an array
    if (   ($p->{'occurrence'} =~ /n$/)
        && $p->{'split_char'}
        && !(ref($value) eq 'ARRAY')) {
        my @array = split /$p->{'split_char'}/, $value;
        foreach my $v (@array) {
            $v =~ s/^\s*(.+)\s*$/$1/g;
        }

        return \@array;
    } else {
        return $value;
    }
}

## Simply load a config file and returns a hash.
## the returned hash contains two keys:
## 1- the key 'config' points to a hash containing the data found in the
## config file.
## 2- the key 'numbered_config' points to a hash containing the data found in
## the config file. Each entry contains both the value of a parameter and the
## line where it was found in the config file.
## 3- the key 'errors' contains the number of config entries that could not be
## loaded, due to an error.
## Returns undef if something went wrong while attempting to read the file.
sub _load_config_file_to_hash {
    my $param = shift;
    my $result = { errors => 0, config => {}, numbered_config => {} };
    $result->{'errors'} = 0;
    my $line_num    = 0;
    my $config_file = $param->{'config_file'}
	or die "no config file set";

    ## Open the configuration file or return and read the lines.
    unless (open IN, '<', $config_file) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Unable to open %s: %s',
            $config_file, $ERRNO);
        return undef;
    }
    while (<IN>) {
        $line_num++;

        # skip empty or commented lines
        next if (/^\s*$/ || /^[\#;]/);

        # match "keyword value" pattern
        if (/^(\S+)\s+(.+)$/) {
            my ($keyword, $value) = ($1, $2);
            $value =~ s/\s*$//;
            ##  'key_password' is a synonym for 'key_passwd'
            ## (for compatibilyty with older versions)
            $keyword = 'key_passwd' if ($keyword eq 'key_password');
            ## Special case: `command`
            if ($value =~ /^\`(.*)\`$/) {
                $value = qx/$1/;
                chomp($value);
            }
            if (   exists $params{$keyword}
                && defined $params{$keyword}{'multiple'}
                && $params{$keyword}{'multiple'} == 1) {
                if (defined $result->{'config'}{$keyword}) {
                    push @{$result->{'config'}{$keyword}}, $value;
                    push @{$result->{'numbered_config'}{$keyword}},
                        [$value, $line_num];
                } else {
                    $result->{'config'}{$keyword} = [$value];
                    $result->{'numbered_config'}{$keyword} =
                        [[$value, $line_num]];
                }
            } else {
                $result->{'config'}{$keyword} = $value;
                $result->{'numbered_config'}{$keyword} = [$value, $line_num];
            }
        } else {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Error at %s line %d: %s',
                $config_file, $line_num, $_);
            $result->{'errors'}++;
        }
    }
    close IN;
    return $result;
}

## Checks a hash containing a sympa config and removes any entry that
## is not supposed to be defined at the robot level.
sub _remove_unvalid_robot_entry {
    my $param       = shift;
    my $config_hash = $param->{'config_hash'};
    foreach my $keyword (keys %$config_hash) {
        unless ($valid_robot_key_words{$keyword}) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'removing unknown robot keyword %s', $keyword)
                unless $param->{'quiet'};
            delete $config_hash->{$keyword};
        }
    }
    return 1;
}

sub _detect_unknown_parameters_in_config {
    my $param                              = shift;
    my $number_of_unknown_parameters_found = 0;
    foreach my $parameter (sort keys %{$param->{'config_hash'}}) {
        next if (exists $params{$parameter});
        if (defined $old_params{$parameter}) {
            if ($old_params{$parameter}) {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Line %d of sympa.conf, parameter %s is no more available, read documentation for new parameter(s) %s',
                    $param->{'config_file_line_numbering_reference'}
                        {$parameter}[1],
                    $parameter,
                    $old_params{$parameter}
                );
            } else {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Line %d of sympa.conf, parameter %s is now obsolete',
                    $param->{'config_file_line_numbering_reference'}
                        {$parameter}[1],
                    $parameter
                );
                next;
            }
        } else {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Line %d, unknown field: %s in sympa.conf',
                $param->{'config_file_line_numbering_reference'}{$parameter}
                    [1],
                $parameter
            );
        }
        $number_of_unknown_parameters_found++;
    }
    return $number_of_unknown_parameters_found;
}

sub _infer_server_specific_parameter_values {
    my $param = shift;

    $param->{'config_hash'}{'robot_name'} = '';

##    $param->{'config_hash'}{'pictures_url'} ||= $param->{'config_hash'}{'static_content_url'}.'/pictures/';
##    $param->{'config_hash'}{'pictures_path'} ||= $param->{'config_hash'}{'static_content_path'}.'/pictures/';

    unless ((defined $param->{'config_hash'}{'cafile'})
        || (defined $param->{'config_hash'}{'capath'})) {
        $param->{'config_hash'}{'cafile'} =
            Sympa::Constants::DEFAULTDIR . '/ca-bundle.crt';
    }

    unless ($param->{'config_hash'}{'dkim_feature'} eq 'on') {

        # dkim_signature_apply_ on nothing if DKIM_feature is off
        $param->{'config_hash'}{'dkim_signature_apply_on'} =
            [''];    # empty array
    }

    my $p = 1;
    foreach (split(/,/, $param->{'config_hash'}{'sort'})) {
        $param->{'config_hash'}{'poids'}{$_} = $p++;
    }
    $param->{'config_hash'}{'poids'}{'*'} = $p
        if !$param->{'config_hash'}{'poids'}{'*'};

    ## Parameters made of comma-separated list
    foreach my $parameter (
        'rfc2369_header_fields', 'anonymous_header_fields',
        'remove_headers',        'remove_outgoing_headers'
        ) {
        if ($param->{'config_hash'}{$parameter} eq 'none') {
            delete $param->{'config_hash'}{$parameter};
        } else {
            $param->{'config_hash'}{$parameter} =
                [split(/,/, $param->{'config_hash'}{$parameter})];
        }
    }

    foreach my $action (split(/,/, $param->{'config_hash'}{'use_blacklist'}))
    {
        $param->{'config_hash'}{'blacklist'}{$action} = 1;
    }

    foreach my $log_module (split(/,/, $param->{'config_hash'}{'log_module'}))
    {
        $param->{'config_hash'}{'loging_for_module'}{$log_module} = 1;
    }

    foreach my $log_condition (
        split(/,/, $param->{'config_hash'}{'log_condition'})) {
        chomp $log_condition;
        if ($log_condition =~ /^\s*(ip|email)\s*\=\s*(.*)\s*$/i) {
            $param->{'config_hash'}{'loging_condition'}{$1} = $2;
        } else {
            $main::logger->do_log(Sympa::Logger::NOTICE,
                'unrecognized log_condition token %s ; ignored',
                $log_condition);
        }
    }

    if ($param->{'config_hash'}{'ldap_export_name'}) {
        $param->{'config_hash'}{'ldap_export'} = {
            $param->{'config_hash'}{'ldap_export_name'} => {
                'host'     => $param->{'config_hash'}{'ldap_export_host'},
                'suffix'   => $param->{'config_hash'}{'ldap_export_suffix'},
                'password' => $param->{'config_hash'}{'ldap_export_password'},
                'DnManager' =>
                    $param->{'config_hash'}{'ldap_export_dnmanager'},
                'connection_timeout' =>
                    $param->{'config_hash'}{'ldap_export_connection_timeout'}
            }
        };
    }

    ## Default SOAP URL corresponds to default robot
    if ($param->{'config_hash'}{'soap_url'}) {
        my $url = $param->{'config_hash'}{'soap_url'};
        $url =~ s/^http(s)?:\/\/(.+)$/$2/;
        $param->{'config_hash'}{'robot_by_soap_url'}{$url} =
            $param->{'config_hash'}{'domain'};
    }

    return 1;
}

sub _load_server_specific_secondary_config_files {
    my $param = shift;

    ## wwsympa.conf exists
    if (-f get_wwsympa_conf()) {
        $main::logger->do_log(
            Sympa::Logger::NOTICE,
            '%s was found but it is no longer loaded.  Please run sympa.pl --upgrade to migrate it.',
            get_wwsympa_conf()
        );
    }

    # canonicalize language, or if failed, apply site-wide default.
    $param->{'config_hash'}{'lang'} =
	Sympa::Language::canonic_lang($param->{'config_hash'}{'lang'})
	|| 'en-US';

    ## Load charset.conf file if necessary.
    if ($param->{'config_hash'}{'legacy_character_support_feature'} eq 'on') {
        $param->{'config_hash'}{'locale2charset'} = load_charset();
    } else {
        $param->{'config_hash'}{'locale2charset'} = {};
    }

    ## Load nrcpt_by_domain.conf
    $param->{'config_hash'}{'nrcpt_by_domain'} = load_nrcpt_by_domain();
    $param->{'config_hash'}{'crawlers_detection'} =
        load_crawlers_detection($param->{'config_hash'}{'robot_name'});
}

sub _infer_robot_parameter_values {
    my $param = shift;

    # 'host' and 'domain' are mandatory and synonym.$Conf{'host'} is
    # still widely used even if the doc requires domain.
    $param->{'config_hash'}{'host'} = $param->{'config_hash'}{'domain'}
        if (defined $param->{'config_hash'}{'domain'});
    $param->{'config_hash'}{'domain'} = $param->{'config_hash'}{'host'}
        if (defined $param->{'config_hash'}{'host'});

    $param->{'config_hash'}{'wwsympa_url'} ||=
        "http://$param->{'config_hash'}{'host'}/sympa";

    $param->{'config_hash'}{'static_content_url'} ||=
        $Conf{'static_content_url'};
    $param->{'config_hash'}{'static_content_path'} ||=
        $Conf{'static_content_path'};

    ## CSS
    my $final_separator = '';
    $final_separator = '/' if ($param->{'config_hash'}{'robot_name'});
    $param->{'config_hash'}{'css_url'} ||=
          $param->{'config_hash'}{'static_content_url'} . '/css'
        . $final_separator
        . $param->{'config_hash'}{'robot_name'};
    $param->{'config_hash'}{'css_path'} ||=
          $param->{'config_hash'}{'static_content_path'} . '/css'
        . $final_separator
        . $param->{'config_hash'}{'robot_name'};

    unless ($param->{'config_hash'}{'email'}) {
        $param->{'config_hash'}{'email'} = $Conf{'email'};
    }
##OBSOLETED by Sympa 6.2: Use $robot->get_address().
##    $param->{'config_hash'}{'sympa'} = $param->{'config_hash'}{'email'}.'@'.$param->{'config_hash'}{'host'};
##    $param->{'config_hash'}{'request'} = $param->{'config_hash'}{'email'}.'-request@'.$param->{'config_hash'}{'host'};
    # split action list for blacklist usage
    foreach my $action (split(/,/, $Conf{'use_blacklist'})) {
        $param->{'config_hash'}{'blacklist'}{$action} = 1;
    }

    ## Create a hash to deduce robot from SOAP url
    if ($param->{'config_hash'}{'soap_url'}) {
        my $url = $param->{'config_hash'}{'soap_url'};
        $url =~ s/^http(s)?:\/\/(.+)$/$2/;
        $Conf{'robot_by_soap_url'}{$url} =
            $param->{'config_hash'}{'robot_name'};
    }

    # Hack because multi valued parameters are not available for Sympa 6.1.
    if (defined $param->{'config_hash'}{'automatic_list_families'}) {
        my @families = split ';',
            $param->{'config_hash'}{'automatic_list_families'};
        my %families_description;
        foreach my $family_description (@families) {
            my %family;
            my @family_parameters = split ':', $family_description;
            foreach my $family_parameter (@family_parameters) {
                my @parameter = split '=', $family_parameter;
                $family{$parameter[0]} = $parameter[1];
            }
            $family{'escaped_prefix_separator'} = $family{'prefix_separator'};
            $family{'escaped_prefix_separator'} =~ s/([+*?.])/\\$1/g;
            $family{'escaped_classes_separator'} =
                $family{'classes_separator'};
            $family{'escaped_classes_separator'} =~ s/([+*?.])/\\$1/g;
            $families_description{$family{'name'}} = \%family;
        }
        $param->{'config_hash'}{'automatic_list_families'} =
            \%families_description;
    }

    ## db_list_cache is obsoleted by Sympa 6.2.  Use cache_list_config
    if (    $param->{'config_hash'}{'db_list_cache'}
        and $param->{'config_hash'}{'db_list_cache'} eq 'on') {
        $main::logger->do_log(Sympa::Logger::NOTICE,
            'db_list_cache is "on" but it is obsoleted.  Setting cache_list_config as "database".'
        );
        $param->{'config_hash'}{'cache_list_config'} = 'database';
        delete $param->{'config_hash'}{'db_list_cache'};
    }

    # canonicalize language
    $param->{'config_hash'}{'lang'} =
	Sympa::Language::canonic_lang($param->{'config_hash'}{'lang'})
	or delete $param->{'config_hash'}{'lang'};

    _parse_custom_robot_parameters({'config_hash' => $param->{'config_hash'}});
}

sub _load_robot_secondary_config_files {
    my $param = shift;
    my $trusted_applications =
        load_trusted_application($param->{'config_hash'}{'robot_name'});
    $param->{'config_hash'}{'trusted_applications'} = undef;
    if (defined $trusted_applications) {
        $param->{'config_hash'}{'trusted_applications'} =
            $trusted_applications->{'trusted_application'};
    }
    my $robot_name_for_auth_storing = $param->{'config_hash'}{'robot_name'}
        || $Conf{'domain'};
    my $is_main_robot = 0;
    $is_main_robot = 1 unless ($param->{'config_hash'}{'robot_name'});
    $Conf{'auth_services'}{$robot_name_for_auth_storing} =
        _load_auth($param->{'config_hash'}{'robot_name'}, $is_main_robot);
    if (defined $param->{'config_hash'}{'automatic_list_families'}) {
        foreach my $family (
            keys %{$param->{'config_hash'}{'automatic_list_families'}}) {
            $param->{'config_hash'}{'automatic_list_families'}{$family}
                {'description'} = load_automatic_lists_description(
                $param->{'config_hash'}{'robot_name'},
                $param->{'config_hash'}{'automatic_list_families'}{$family}
                    {'name'}
                );
        }
    }
    return 1;
}
## For parameters whose value is hard_coded, as per %hardcoded_params, set the
## parameter value to the hardcoded value, whatever is defined in the config.
## Returns a ref to a hash containing the ignored values.
sub _set_hardcoded_parameter_values {
    my $param = shift;
    my %ignored_values;
    ## Some parameter values are hardcoded. In that case, ignore what was set
    ## in the config file and simply use the hardcoded value.
    foreach my $p (keys %hardcoded_params) {
        $ignored_values{$p} = $param->{'config_hash'}{$p}
            if (defined $param->{'config_hash'}{$p});
        $param->{'config_hash'}{$p} = $hardcoded_params{$p};
    }
    return \%ignored_values;
}

sub _detect_missing_mandatory_parameters {
    my $param            = shift;
    my $number_of_errors = 0;
    $param->{'file_to_check'} =~ /^(\/.*\/)?([^\/]+)$/;
    my $config_file_name = $2;
    foreach my $parameter (keys %params) {
        next
            if (defined $params{$parameter}->{'file'}
            && $params{$parameter}->{'file'} ne $config_file_name);
        unless (defined $param->{'config_hash'}{$parameter}
            or defined $params{$parameter}->{'default'}
            or defined $params{$parameter}->{'optional'}) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Required field not found in sympa.conf: %s', $parameter);
            $number_of_errors++;
            next;
        }
        $param->{'config_hash'}{$parameter} ||=
            $params{$parameter}->{'default'};
    }
    return $number_of_errors;
}

## Some functionalities activated by some parameter values require that
## some optional CPAN modules are installed. This function checks whether
## these modules are installed and if they are missing, changes the config
## to fall back to a functioning that doesn't require a module and issues
## a warning.
## Returns the number of missing modules.
sub _check_cpan_modules_required_by_config {
    my $param                     = shift;
    my $number_of_missing_modules = 0;

    ## Some parameters require CPAN modules
    if ($param->{'config_hash'}{'dkim_feature'} eq 'on') {
        eval "require Mail::DKIM";
        if ($EVAL_ERROR) {
            $main::logger->do_log(Sympa::Logger::NOTICE,
                'Failed to load Mail::DKIM perl module ; setting "dkim_feature" to "off"'
            );
            $param->{'config_hash'}{'dkim_feature'} = 'off';
            $number_of_missing_modules++;
        }
    }
    return $number_of_missing_modules;
}

sub _dump_non_robot_parameters {
    my $param = shift;
    foreach my $key (keys %{$param->{'config_hash'}}) {
        unless ($valid_robot_key_words{$key}) {
            delete $param->{'config_hash'}{$key};
            $main::logger->do_log(Sympa::Logger::ERR,
                'Robot %s config: unknown robot parameter: %s',
                $param->{'robot'}, $key);
        }
    }
}

sub load_robot_conf {
    my $param = shift || {};

    my $robot = $param->{'robot'};
    unless (defined $robot and length $robot) {
        $robot = '*';
    }
    my $config_file = $param->{'config_file'};
    unless ($config_file) {
        if ($robot eq '*') {
            $config_file = get_sympa_conf();
        } else {
            $config_file = $Conf{'etc'} . '/' . $robot . '/robot.conf';
        }
    }
    my $force_reload  = $param->{'force_reload'};
    my $return_result = $param->{'return_result'};

    my $config_err = 0;
    my %line_numbered_config;

    my $conf = undef;
    if ($robot eq '*') {
        $conf = \%Conf;
    } else {
        $conf = {};
    }

    unless (-r $config_file) {
        $main::logger->do_log(Sympa::Logger::ERR, 'No read access on %s',
            $config_file) if $main::logger;
        return undef;
    }

    my $cached;
    my $result;
    if (    %Conf
        and !$force_reload
        and !$return_result
        and $cached = _load_binary_cache({'config_file' => $config_file})) {
        %$conf = %$cached;
        if ($conf->{'soap_url'}) {
            my $url = $conf->{'soap_url'};
            $url =~ s/^http(s)?:\/\/(.+)$/$2/;
            $Conf{'robot_by_soap_url'}{$url} = $conf->{'robot_name'};
        }
        $main::logger->do_log(
            Sympa::Logger::DEBUG3,
            'got %s from serialized data',
            ($robot ne '*') ? "config for robot $robot" : 'main conf'
        );
    } elsif ($result =
        _load_config_file_to_hash({'config_file' => $config_file})) {
        %$conf = %{$result->{'config'}};
        $main::logger->do_log(
            Sympa::Logger::DEBUG3,
            'got %s from file',
            ($robot ne '*') ? "config for robot $robot" : 'main conf'
        );

        %line_numbered_config = %{$result->{'numbered_config'}};
        $config_err           = $result->{'errors'};

        # Returning the config file content if this is what has been asked.
        return \%line_numbered_config if $return_result;

        # Users may define parameters with a typo or other errors.
        # Check that the parameters we found in the config file are all well
        # defined Sympa parameters.
        $config_err += _detect_unknown_parameters_in_config(
            {   'config_hash' => $conf,
                'config_file_line_numbering_reference' =>
                    \%line_numbered_config,
            }
        );

        if ($robot eq '*') {

            # Some parameter values are hardcoded. In that case, ignore what
            # was set in the config file and simply use the hardcoded value.
            %Ignored_Conf =
                %{_set_hardcoded_parameter_values({'config_hash' => $conf})};
        } else {

            # Remove entries which are not supposed to be defined at the
            # robot level.
            _dump_non_robot_parameters(
                {   'config_hash' => $conf,
                    'robot'       => $robot
                }
            );
            ## Default for 'host' is the domain
            ##FIXME
            $conf->{'host'}       ||= $robot;
            $conf->{'robot_name'} ||= $robot;
        }

        _set_listmasters_entry({'config_hash' => $conf, 'robot' => $robot});

        if ($robot eq '*') {
            ## Some parameters must have a value specifically defined in the
            ## config. If not, it is an error.
            $config_err += _detect_missing_mandatory_parameters(
                {'config_hash' => $conf, 'file_to_check' => $config_file});

            # Some parameters need special treatments to get their final
            # values.
            _infer_server_specific_parameter_values({'config_hash' => $conf});
        }

        _infer_robot_parameter_values({'config_hash' => $conf});

        if ($config_err) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Errors while parsing main config file %s', $config_file);
            return undef;
        }

        _store_source_file_name(
            {'config_hash' => $conf, 'config_file' => $config_file});
        _save_config_hash_to_binary(
            {'config_hash' => $conf, 'source_file' => $config_file});
    } else {
        $main::logger->do_log(Sympa::Logger::ERR, 'Unable to load %s. Aborting',
            $config_file);
        return undef;
    }

    if ($robot eq '*') {
        my $count;
        if ($count =
            _check_cpan_modules_required_by_config({'config_hash' => $conf}))
        {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Warning: %d required modules are missing.', $count);
        }
    }

    _replace_file_value_by_db_value(
        {'config_hash' => $conf, 'robot' => $robot})
        unless $param->{'no_db'};
    if ($robot eq '*') {
        _load_server_specific_secondary_config_files(
            {'config_hash' => $conf});
    }
    _load_robot_secondary_config_files({'config_hash' => $conf});

    unless ($robot eq '*') {
        _check_double_url_usage({'config_hash' => $conf});
    }

    ## Load config
    unless ($robot eq '*') {
        $Conf{'robots'} ||= {};
        $Conf{'robots'}{$robot} = $conf;
    }
    return 1;
}

sub _set_listmasters_entry {
    my $param                    = shift;
    my $number_of_valid_email    = 0;
    my $number_of_email_provided = 0;

    # listmaster is a list of email separated by commas
    if (defined $param->{'config_hash'}{'listmaster'}
        && $param->{'config_hash'}{'listmaster'} !~ /^\s*$/) {
        $param->{'config_hash'}{'listmaster'} =~ s/\s//g;
        my @emails_provided =
            split(/,/, $param->{'config_hash'}{'listmaster'});
        $number_of_email_provided = scalar @emails_provided;
        foreach my $lismaster_address (@emails_provided) {
            if (Sympa::Tools::valid_email($lismaster_address)) {
                push @{$param->{'config_hash'}{'listmasters'}},
                    $lismaster_address;
                $number_of_valid_email++;
            } else {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Robot %s config: Listmaster address "%s" is not a valid email',
                    $param->{'config_hash'}{'host'},
                    $lismaster_address
                );
            }
        }
    } elsif ($param->{'robot'} eq '*') {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Robot %s config: No listmaster defined. This is the main config. It MUST define at least one listmaster. Stopping here.',
            $param->{'config_hash'}{'domain'}
        );
        return undef;
    } else {
        $param->{'config_hash'}{'listmasters'} = $Conf{'listmasters'};
        $param->{'config_hash'}{'listmaster'}  = $Conf{'listmaster'};
        $number_of_valid_email =
            scalar @{$param->{'config_hash'}{'listmasters'}};
    }
    if ($number_of_email_provided > $number_of_valid_email) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Robot %s config: All the listmasters addresses found were not valid. Out of %s addresses provided, %s only are valid email addresses.',
            $param->{'config_hash'}{'host'},
            $number_of_email_provided,
            $number_of_valid_email
        );
        return undef;
    }
    return $number_of_valid_email;
}

sub _check_double_url_usage {
    my $param = shift;
    my ($host, $path);
    if ($param->{'config_hash'}{'http_host'} =~ /^([^\/]+)(\/.*)$/) {
        ($host, $path) = ($1, $2);
    } else {
        ($host, $path) = ($param->{'config_hash'}{'http_host'}, '/');
    }

    ## Warn listmaster if another virtual host is defined with the same host
    ## +path
    if (defined $Conf{'robot_by_http_host'}{$host}{$path}
        and $Conf{'robot_by_http_host'}{$host}{$path} ne
        $param->{'config_hash'}{'robot_name'}) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Error: two virtual hosts (%s and %s) are mapped via a single URL "%s%s"',
            $Conf{'robot_by_http_host'}{$host}{$path},
            $param->{'config_hash'}{'robot_name'},
            $host,
            $path
        );
    }

    $Conf{'robot_by_http_host'}{$host}{$path} =
        $param->{'config_hash'}{'robot_name'};
}

sub _parse_custom_robot_parameters {
    my $param           = shift;
    my $csp_tmp_storage = undef;
    if (defined $param->{'config_hash'}{'custom_robot_parameter'}
        && ref() ne 'HASH') {
        foreach my $custom_p (
            @{$param->{'config_hash'}{'custom_robot_parameter'}}) {
            if ($custom_p =~ /(\S+)\s*\;\s*(.+)/) {
                $csp_tmp_storage->{$1} = $2;
            }
        }
        $param->{'config_hash'}{'custom_robot_parameter'} = $csp_tmp_storage;
    }
}

sub _replace_file_value_by_db_value {
    my $param = shift;
    my $robot = $param->{'robot'};
    foreach my $label (keys %db_storable_parameters) {
        next unless ($robot ne '*' && $valid_robot_key_words{$label} == 1);
        my $value = get_db_conf($robot, $label);
        if (defined $value) {
            $param->{'config_hash'}{$label} = $value;
        }
    }
}

# Stores the config hash binary representation to a file.
# Returns 1 or undef if something went wrong.
sub _save_binary_cache {
    my $param = shift;
    my $lock_fh = Sympa::LockedFile->new($param->{'target_file'}, 2, '>');
    unless ($lock_fh) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Could not create new lock');
        return undef;
    }

    eval { Storable::store_fd($param->{'conf_to_save'}, $lock_fh); };
    if ($@) {
        printf STDERR
            'Conf::_save_binary_cache(): Failed to save the binary config %s. error: %s\n',
            $param->{'target_file'}, $@;
        unless ($lock_fh->close()) {
            return undef;
        }
        return undef;
    }
    eval {
        chown(
            (getpwnam(Sympa::Constants::USER))[2],
            (getgrnam(Sympa::Constants::GROUP))[2],
            $param->{'target_file'}
        );
    };
    if ($EVAL_ERROR) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Failed to change owner of the binary file %s. error: %s',
            $param->{'target_file'}, $EVAL_ERROR
        );
        unless ($lock_fh->close()) {
            return undef;
        }
        return undef;
    }
    unless ($lock_fh->close()) {
        return undef;
    }
    return 1;
}

# Loads the config hash binary representation from a file an returns it
# Returns the hash or undef if something went wrong.
sub _load_binary_cache {
    my $param  = shift;
    my $result = undef;

    my $lock_fh = Sympa::LockedFile->new($param->{'config_file'}, 2, '<');
    unless ($lock_fh) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Could not create new lock');
        return undef;
    }

    eval { $result = Storable::fd_retrieve($lock_fh); };
    if ($@) {
        printf STDERR
            "Conf::_load_binary_cache(): Failed to load the binary config %s. error: %s\n",
            $param->{'config_file'}, $@;
        unless ($lock_fh->close()) {
            return undef;
        }
        return undef;
    }
    ## Release the lock
    unless ($lock_fh->close()) {
        return undef;
    }
    return $result;
}

sub _save_config_hash_to_binary {
    my $param = shift;
    unless (
        _save_binary_cache(
            {   'conf_to_save' => $param->{'config_hash'},
                'target_file'  => $param->{'config_hash'}{'source_file'}
                    . $binary_file_extension
            }
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Could not save main config %s',
            $param->{'config_hash'}{'source_file'}
        );
    }
}

sub _source_has_not_changed {
    my $param    = shift;
    my $is_older = Sympa::Tools::File::a_is_older_than_b(
        {   'a_file' => $param->{'config_file'},
            'b_file' => $param->{'config_file'} . $binary_file_extension,
        }
    );
    return 1 if (defined $is_older && $is_older == 1);
    return 0;
}

sub _store_source_file_name {
    my $param = shift;
    $param->{'config_hash'}{'source_file'} = $param->{'config_file'};
}

sub _get_config_file_name {
    my $param = shift;
    my $config_file;
    if ($param->{'robot'}) {
        $config_file =
            $Conf{'etc'} . '/' . $param->{'robot'} . '/' . $param->{'file'};
    } else {
        $config_file = $Conf{'etc'} . '/' . $param->{'file'};
    }
    $config_file = Sympa::Constants::DEFAULTDIR . '/' . $param->{'file'}
        unless (-f $config_file);
    return $config_file;
}

sub _create_robot_like_config_for_main_robot {
    return
        if (
        defined $Sympa::Conf::Conf{'robots'}{$Sympa::Conf::Conf{'domain'}});
    my $main_conf_no_robots = Sympa::Tools::Data::dup_var(\%Conf);
    delete $main_conf_no_robots->{'robots'};
    _remove_unvalid_robot_entry(
        {'config_hash' => $main_conf_no_robots, 'quiet' => 1});
    $Conf{'robots'}{$Conf{'domain'}} = $main_conf_no_robots;
}

sub _get_parameters_names_by_category {
    my $param_by_categories;
    my $current_category;
    foreach my $entry (@Sympa::ConfDef::params) {
        unless ($entry->{'name'}) {
            $current_category = $entry->{'gettext_id'};
        } else {
            $param_by_categories->{$current_category}{$entry->{'name'}} = 1;
        }
    }
    return $param_by_categories;
}

## Load WWSympa configuration file.
sub _load_wwsconf {
    my $param       = shift;
    my $config_hash = $param->{'config_hash'};
    my $config_file = get_wwsympa_conf();

    return 0 unless -f $config_file;    # this file is optional.

    ## Old params
    my %old_param = (
        'alias_manager' => 'No more used, using '
            . $config_hash->{'alias_manager'},
        'wws_path'  => 'No more used',
        'icons_url' => 'No more used. Using static_content/icons instead.',
        'robots' =>
            'Not used anymore. Robots are fully described in their respective robot.conf file.',
        'htmlarea_url' => 'No longer supported',
    );

    my %default_conf = ();

    ## Valid params
    foreach my $key (keys %params) {
        if (defined $params{$key}{'file'}
            and $params{$key}{'file'} eq 'wwsympa.conf') {
            $default_conf{$key} = $params{$key}{'default'};
        }
    }

    my $conf = \%default_conf;

    my $fh;
    unless (open $fh, '<', $config_file) {
        $main::logger->do_log(Sympa::Logger::ERR, 'unable to open %s', $config_file);
        return undef;
    }

    while (<$fh>) {
        next if /^\s*\#/;

        if (/^\s*(\S+)\s+(.+)$/i) {
            my ($k, $v) = ($1, $2);
            $v =~ s/\s*$//;
            if (defined($conf->{$k})) {    #FIXME: Might "exists" be used?
                $conf->{$k} = $v;
            } elsif (defined $old_param{$k}) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Parameter %s in %s no more supported : %s',
                    $k, $config_file, $old_param{$k});
            } else {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Unknown parameter %s in %s',
                    $k, $config_file);
            }
        }
        next;
    }

    close $fh;

    ## Check binaries and directories
    if ($conf->{'arc_path'} && (!-d $conf->{'arc_path'})) {
        $main::logger->do_log(Sympa::Logger::ERR, "No web archives directory: %s\n",
            $conf->{'arc_path'});
    }

    if ($conf->{'bounce_path'} && (!-d $conf->{'bounce_path'})) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            "Missing directory '%s' (defined by 'bounce_path' parameter)",
            $conf->{'bounce_path'}
        );
    }

    if ($conf->{'mhonarc'} && (!-x $conf->{'mhonarc'})) {
        $main::logger->do_log(Sympa::Logger::ERR,
            "MHonArc is not installed or %s is not executable.",
            $conf->{'mhonarc'});
    }

    ## set default
    $conf->{'log_facility'} ||= $config_hash->{'syslog'};

    foreach my $k (keys %$conf) {
        $config_hash->{$k} = $conf->{$k};
    }
    $wwsconf = $conf;
}

1;
