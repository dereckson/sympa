# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::Auth;

use strict;
use warnings;
use Digest::MD5;
use POSIX qw();

use Conf;
use Sympa::Datasource::LDAP;
use Log;
use Sympa::Report;
use Sympa::Robot;
use SDM;
use Sympa::Session;
use tools;
use Sympa::Tools::Data;
use Sympa::Tools::Time;
use Sympa::User;

## return the password finger print (this proc allow futur replacement of md5
## by sha1 or ....)
sub password_fingerprint {

    Log::do_log('debug', '');

    my $pwd = shift;
    if (Conf::get_robot_conf('*', 'password_case') eq 'insensitive') {
        return Digest::MD5::md5_hex(lc($pwd));
    } else {
        return Digest::MD5::md5_hex($pwd);
    }
}

## authentication : via email or uid
sub check_auth {
    my $robot = shift;
    my $auth  = shift;    ## User email or UID
    my $pwd   = shift;    ## Password
    Log::do_log('debug', '(%s)', $auth);

    my ($canonic, $user);

    if (tools::valid_email($auth)) {
        return authentication($robot, $auth, $pwd);
    } else {
        ## This is an UID
        foreach my $ldap (@{$Conf::Conf{'auth_services'}{$robot}}) {
            # only ldap service are to be applied here
            next unless ($ldap->{'auth_type'} eq 'ldap');

            $canonic =
                ldap_authentication($robot, $ldap, $auth, $pwd, 'uid_filter');
            last if ($canonic);    ## Stop at first match
        }
        if ($canonic) {

            unless ($user = Sympa::User::get_global_user($canonic)) {
                $user = {'email' => $canonic};
            }
            return {
                'user'       => $user,
                'auth'       => 'ldap',
                'alt_emails' => {$canonic => 'ldap'}
            };

        } else {
            Sympa::Report::reject_report_web('user', 'incorrect_passwd', {})
                unless ($ENV{'SYMPA_SOAP'});
            Log::do_log('err', "Incorrect LDAP password");
            return undef;
        }
    }
}

## This subroutine if Sympa may use its native authentication for a given user
## It might not if no user_table paragraph is found in auth.conf or if the
## regexp or
## negative_regexp exclude this user
## IN : robot, user email
## OUT : boolean
sub may_use_sympa_native_auth {
    my ($robot, $user_email) = @_;

    my $ok = 0;
    ## check each auth.conf paragrpah
    foreach my $auth_service (@{$Conf::Conf{'auth_services'}{$robot}}) {
        next unless ($auth_service->{'auth_type'} eq 'user_table');

        next
            if ($auth_service->{'regexp'}
            && ($user_email !~ /$auth_service->{'regexp'}/i));
        next
            if ($auth_service->{'negative_regexp'}
            && ($user_email =~ /$auth_service->{'negative_regexp'}/i));

        $ok = 1;
        last;
    }

    return $ok;
}

sub authentication {
    my ($robot, $email, $pwd) = @_;
    my ($user, $canonic);
    Log::do_log('debug', '(%s)', $email);

    unless ($user = Sympa::User::get_global_user($email)) {
        $user = {'email' => $email};
    }
    unless ($user->{'password'}) {
        $user->{'password'} = '';
    }

    if ($user->{'wrong_login_count'} >
        Conf::get_robot_conf($robot, 'max_wrong_password')) {
        # too many wrong login attemp
        Sympa::User::update_global_user($email,
            {wrong_login_count => $user->{'wrong_login_count'} + 1});
        Sympa::Report::reject_report_web('user', 'too_many_wrong_login', {})
            unless ($ENV{'SYMPA_SOAP'});
        Log::do_log('err',
            'Login is blocked: too many wrong password submission for %s',
            $email);
        return undef;
    }
    foreach my $auth_service (@{$Conf::Conf{'auth_services'}{$robot}}) {
        next if ($auth_service->{'auth_type'} eq 'authentication_info_url');
        next if ($email !~ /$auth_service->{'regexp'}/i);
        next
            if $auth_service->{'negative_regexp'}
                and $email =~ /$auth_service->{'negative_regexp'}/i;

        ## Only 'user_table' and 'ldap' backends will need that Sympa collects
        ## the user passwords
        ## Other backends are Single Sign-On solutions
        if ($auth_service->{'auth_type'} eq 'user_table') {
            my $fingerprint = password_fingerprint($pwd);

            if ($fingerprint eq $user->{'password'}) {
                Sympa::User::update_global_user($email,
                    {wrong_login_count => 0});
                return {
                    'user'       => $user,
                    'auth'       => 'classic',
                    'alt_emails' => {$email => 'classic'}
                };
            }
        } elsif ($auth_service->{'auth_type'} eq 'ldap') {
            if ($canonic = ldap_authentication(
                    $robot, $auth_service, $email, $pwd, 'email_filter'
                )
                ) {
                unless ($user = Sympa::User::get_global_user($canonic)) {
                    $user = {'email' => $canonic};
                }
                Sympa::User::update_global_user($canonic,
                    {wrong_login_count => 0});
                return {
                    'user'       => $user,
                    'auth'       => 'ldap',
                    'alt_emails' => {$email => 'ldap'}
                };
            }
        }
    }

    # increment wrong login count.
    Sympa::User::update_global_user($email,
        {wrong_login_count => $user->{'wrong_login_count'} + 1});

    Sympa::Report::reject_report_web('user', 'incorrect_passwd', {})
        unless ($ENV{'SYMPA_SOAP'});
    Log::do_log('err', 'Incorrect password for user %s', $email);

    my $param;    #FIXME FIXME: not used.
    $param->{'init_email'}         = $email;
    $param->{'escaped_init_email'} = tools::escape_chars($email);
    return undef;
}

sub ldap_authentication {
    my ($robot, $ldap, $auth, $pwd, $whichfilter) = @_;
    my ($mesg, $host, $ldaph);
    Log::do_log('debug2', '(%s, %s, %s)', $auth, '****', $whichfilter);
    Log::do_log('debug3', 'Password used: %s', $pwd);

    unless (tools::search_fullpath($robot, 'auth.conf')) {
        return undef;
    }

    ## No LDAP entry is defined in auth.conf
    if ($#{$Conf::Conf{'auth_services'}{$robot}} < 0) {
        Log::do_log('notice', 'Skipping empty auth.conf');
        return undef;
    }

    # only ldap service are to be applied here
    return undef unless ($ldap->{'auth_type'} eq 'ldap');

    # skip ldap auth service if the an email address was provided
    # and this email address does not match the corresponding regexp
    return undef if ($auth =~ /@/ && $auth !~ /$ldap->{'regexp'}/i);

    my @alternative_conf = split(/,/, $ldap->{'alternative_email_attribute'});
    my $attrs            = $ldap->{'email_attribute'};
    my $filter           = $ldap->{'get_dn_by_uid_filter'}
        if ($whichfilter eq 'uid_filter');
    $filter = $ldap->{'get_dn_by_email_filter'}
        if ($whichfilter eq 'email_filter');
    $filter =~ s/\[sender\]/$auth/ig;

    ## bind in order to have the user's DN
    my $ds = Sympa::Datasource::LDAP->new($ldap);

    unless ($ds and $ldaph = $ds->connect()) {
        Log::do_log('err', 'Unable to connect to the LDAP server "%s"',
            $ldap->{'host'});
        return undef;
    }

    $mesg = $ldaph->search(
        base    => $ldap->{'suffix'},
        filter  => "$filter",
        scope   => $ldap->{'scope'},
        timeout => $ldap->{'timeout'}
    );

    if ($mesg->count() == 0) {
        Log::do_log('notice',
            'No entry in the LDAP Directory Tree of %s for %s',
            $ldap->{'host'}, $auth);
        $ds->disconnect();
        return undef;
    }

    my $refhash = $mesg->as_struct();
    my (@DN) = keys(%$refhash);
    $ds->disconnect();

    ##  bind with the DN and the pwd

    # Then set the bind_dn and password according to the current user
    $ds = Sympa::Datasource::LDAP->new(
        {   %$ldap,
            bind_dn       => $DN[0],
            bind_password => $pwd,
        }
    );

    unless ($ds and $ldaph = $ds->connect()) {
        Log::do_log('err', 'Unable to connect to the LDAP server "%s"',
            $ldap->{'host'});
        return undef;
    }

    $mesg = $ldaph->search(
        base    => $ldap->{'suffix'},
        filter  => "$filter",
        scope   => $ldap->{'scope'},
        timeout => $ldap->{'timeout'}
    );

    if ($mesg->count() == 0 || $mesg->code() != 0) {
        Log::do_log('notice', "No entry in the LDAP Directory Tree of %s",
            $ldap->{'host'});
        $ds->disconnect();
        return undef;
    }

    ## To get the value of the canonic email and the alternative email
    my (@canonic_email, @alternative);

    my $param = Sympa::Tools::Data::dup_var($ldap);
    ## Keep previous alt emails not from LDAP source
    my $previous = {};
    foreach my $alt (keys %{$param->{'alt_emails'}}) {
        $previous->{$alt} = $param->{'alt_emails'}{$alt}
            if ($param->{'alt_emails'}{$alt} ne 'ldap');
    }
    $param->{'alt_emails'} = {};

    my $entry = $mesg->entry(0);
    @canonic_email = $entry->get_value($attrs, 'alloptions' => 1);
    foreach my $email (@canonic_email) {
        my $e = lc($email);
        $param->{'alt_emails'}{$e} = 'ldap' if ($e);
    }

    foreach my $attribute_value (@alternative_conf) {
        @alternative = $entry->get_value($attribute_value, 'alloptions' => 1);
        foreach my $alter (@alternative) {
            my $a = lc($alter);
            $param->{'alt_emails'}{$a} = 'ldap' if ($a);
        }
    }

    ## Restore previous emails
    foreach my $alt (keys %{$previous}) {
        $param->{'alt_emails'}{$alt} = $previous->{$alt};
    }

    $ds->disconnect() or Log::do_log('notice', 'Unable to unbind');
    Log::do_log('debug3', 'Canonic: %s', $canonic_email[0]);
    ## If the identifier provided was a valid email, return the provided
    ## email.
    ## Otherwise, return the canonical email guessed after the login.
    if (tools::valid_email($auth)
        && !Conf::get_robot_conf($robot, 'ldap_force_canonical_email')) {
        return ($auth);
    } else {
        return lc($canonic_email[0]);
    }
}

# fetch user email using his cas net_id and the paragrapah number in auth.conf
# NOTE: This might be moved to Robot package.
sub get_email_by_net_id {

    my $robot      = shift;
    my $auth_id    = shift;
    my $attributes = shift;

    Log::do_log('debug', '(%s, %s)', $auth_id, $attributes->{'uid'});

    if (defined $Conf::Conf{'auth_services'}{$robot}[$auth_id]
        {'internal_email_by_netid'}) {
        my $sso_config   = @{$Conf::Conf{'auth_services'}{$robot}}[$auth_id];
        my $netid_cookie = $sso_config->{'netid_http_header'};

        $netid_cookie =~ s/(\w+)/$attributes->{$1}/ig;

        my $email =
            Sympa::Robot::get_netidtoemail_db($robot, $netid_cookie,
            $Conf::Conf{'auth_services'}{$robot}[$auth_id]{'service_id'});

        return $email;
    }

    my $ldap = $Conf::Conf{'auth_services'}{$robot}->[$auth_id];

    my $ds = Sympa::Datasource::LDAP->new($ldap);
    my $ldaph;

    unless ($ds and $ldaph = $ds->connect()) {
        Log::do_log('err', 'Unable to connect to the LDAP server "%s"',
            $ldap->{'host'});
        return undef;
    }

    my $filter = $ldap->{'get_email_by_uid_filter'};
    $filter =~ s/\[([\w-]+)\]/$attributes->{$1}/ig;

    # my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});

    my $emails = $ldaph->search(
        base    => $ldap->{'suffix'},
        filter  => $filter,
        scope   => $ldap->{'scope'},
        timeout => $ldap->{'timeout'},
        attrs   => [$ldap->{'email_attribute'}],
    );
    my $count = $emails->count();

    if ($emails->count() == 0) {
        Log::do_log('notice', "No entry in the LDAP Directory Tree of %s",
            $ldap->{'host'});
        $ds->disconnect();
        return undef;
    }

    $ds->disconnect();

    ## return only the first attribute
    my @results = $emails->entries;
    foreach my $result (@results) {
        return (lc($result->get_value($ldap->{'email_attribute'})));
    }

}

# check trusted_application_name et trusted_application_password : return 1 or
# undef;
sub remote_app_check_password {
    my ($trusted_application_name, $password, $robot, $service) = @_;
    Log::do_log('debug', '(%s, %s, %s)', $trusted_application_name, $robot,
        $service);

    my $md5 = Digest::MD5::md5_hex($password);

    my $vars;
    # seach entry for trusted_application in Conf
    my @trusted_apps;

    # select trusted_apps from robot context or sympa context
    @trusted_apps = @{Conf::get_robot_conf($robot, 'trusted_applications')};

    foreach my $application (@trusted_apps) {

        if (lc($application->{'name'}) eq lc($trusted_application_name)) {
            if ($md5 eq $application->{'md5password'}) {
                # Log::do_log('debug', 'Authentication succeed for %s',$application->{'name'});
                my %proxy_for_vars;
                my %set_vars;
                foreach my $varname (@{$application->{'proxy_for_variables'}})
                {
                    $proxy_for_vars{$varname} = 1;
                }
                foreach my $varname (@{$application->{'set_variables'}}) {
                    $set_vars{$1} = $2 if $varname =~ /(\S+)=(.*)/;
                }
                if ($application->{'allow_commands'}) {
                    foreach my $cmdname (@{$application->{'allow_commands'}})
                    {
                        return (\%proxy_for_vars, \%set_vars)
                            if $cmdname eq $service;
                    }
                    Log::do_log(
                        'info',   'Illegal command %s received from %s',
                        $service, $trusted_application_name
                    );
                    return;
                }
                return (\%proxy_for_vars, \%set_vars);
            } else {
                Log::do_log('info', 'Bad password from %s',
                    $trusted_application_name);
                return;
            }
        }
    }
    # no matching application found
    Log::do_log('info', 'Unknown application name %s',
        $trusted_application_name);
    return;
}

# create new entry in one_time_ticket table using a rand as id so later
# access is authenticated
sub create_one_time_ticket {
    my $email       = shift;
    my $robot       = shift;
    my $data_string = shift;
    my $remote_addr = shift;
    ## Value may be 'mail' if the IP address is not known

    my $ticket = Sympa::Session::get_random();
    #Log::do_log('info', '(%s, %s, %s, %s) Value = %s',
    #    $email, $robot, $data_string, $remote_addr, $ticket);

    my $date = time;
    my $sth;

    unless (
        SDM::do_prepared_query(
            q{INSERT INTO one_time_ticket_table
          (ticket_one_time_ticket, robot_one_time_ticket,
           email_one_time_ticket, date_one_time_ticket, data_one_time_ticket,
           remote_addr_one_time_ticket, status_one_time_ticket)
          VALUES (?, ?, ?, ?, ?, ?, ?)},
            $ticket, $robot,
            $email,       time, $data_string,
            $remote_addr, 'open'
        )
        ) {
        Log::do_log(
            'err',
            'Unable to insert new one time ticket for user %s, robot %s in the database',
            $email,
            $robot
        );
        return undef;
    }
    return $ticket;
}

# read one_time_ticket from table and remove it
sub get_one_time_ticket {
    Log::do_log('debug2', '(%s, %s, %s)', @_);
    my $robot         = shift;
    my $ticket_number = shift;
    my $addr          = shift;

    my $sth;

    unless (
        $sth = SDM::do_prepared_query(
            q{SELECT ticket_one_time_ticket AS ticket,
                 robot_one_time_ticket AS robot,
                 email_one_time_ticket AS email,
                 date_one_time_ticket AS "date",
                 data_one_time_ticket AS data,
                 remote_addr_one_time_ticket AS remote_addr,
                 status_one_time_ticket as status
          FROM one_time_ticket_table
          WHERE ticket_one_time_ticket = ? AND robot_one_time_ticket = ?},
            $ticket_number, $robot
        )
        ) {
        Log::do_log('err',
            'Unable to retrieve one time ticket %s from database',
            $ticket_number);
        return {'result' => 'error'};
    }

    my $ticket = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish;

    unless ($ticket) {
        Log::do_log('info', 'Unable to find one time ticket %s', $ticket);
        return {'result' => 'not_found'};
    }

    my $result;
    my $printable_date =
        POSIX::strftime("%d %b %Y at %H:%M:%S", localtime($ticket->{'date'}));
    my $lockout = Conf::get_robot_conf($robot, 'one_time_ticket_lockout')
        || 'open';
    my $lifetime =
        Sympa::Tools::Time::duration_conv(
        Conf::get_robot_conf($robot, 'one_time_ticket_lifetime') || 0);

    if ($lockout eq 'one_time' and $ticket->{'status'} ne 'open') {
        $result = 'closed';
        Log::do_log('info', 'Ticket %s from %s has been used before (%s)',
            $ticket_number, $ticket->{'email'}, $printable_date);
    } elsif ($lockout eq 'remote_addr'
        and $ticket->{'status'} ne $addr
        and $ticket->{'status'} ne 'open') {
        $result = 'closed';
        Log::do_log('info',
            'ticket %s from %s refused because accessed by the other (%s)',
            $ticket_number, $ticket->{'email'}, $printable_date);
    } elsif ($lifetime and $ticket->{'date'} + $lifetime < time) {
        Log::do_log('info', 'Ticket %s from %s refused because expired (%s)',
            $ticket_number, $ticket->{'email'}, $printable_date);
        $result = 'expired';
    } else {
        $result = 'success';
    }

    if ($result eq 'success') {
        unless (
            $sth = SDM::do_prepared_query(
                q{UPDATE one_time_ticket_table
                  SET status_one_time_ticket = ?
                  WHERE ticket_one_time_ticket = ? AND
                        robot_one_time_ticket = ?},
                $addr, $ticket_number, $robot
            )
            ) {
            Log::do_log('err',
                'Unable to set one time ticket %s status to %s',
                $ticket_number, $addr);
        } elsif (!$sth->rows) {
            # ticket may be removed by task.
            Log::do_log('info', 'Unable to find one time ticket %s',
                $ticket_number);
            return {'result' => 'not_found'};
        }
    }

    Log::do_log('info', 'Ticket: %s; Result: %s', $ticket_number, $result);
    return {
        'result'      => $result,
        'date'        => $ticket->{'date'},
        'email'       => $ticket->{'email'},
        'remote_addr' => $ticket->{'remote_addr'},
        'robot'       => $robot,
        'data'        => $ticket->{'data'},
        'status'      => $ticket->{'status'}
    };
}

1;
