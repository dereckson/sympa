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

## Note to developers:
## This corresponds to Sympa::ConfigurableObject (and Sympa::Site) package
## in trunk.

=encoding utf-8

=head1 NAME

Sympa - Future base class of Sympa functional objects

=head1 DESCRIPTION

This module aims to be the base class for functional objects of Sympa:
Site, Robot, Family and List.

=cut

package Sympa;

use strict;
use warnings;
#use Cwd qw();
use DateTime;
use Digest::MD5;
use English qw(-no_match_vars);

use Sympa::Alarm;
use Sympa::Auth;
use Sympa::Bulk;
use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::Log;
use Sympa::Message;
use tools;
use Sympa::Tools::Data;

my $log = Sympa::Log->instance;

=head2 Functions

=head3 Handling the Authentication Token

=over

=item compute_auth

    # To compute site-wide token
    Sympa::compute_auth(('*', 'user@dom.ain', 'remind');
    # To cpmpute a token specific to a list
    Sympa::compute_auth($list, 'user@dom.ain', 'subscribe');

Genererate a MD5 checksum using private cookie and parameters.

Parameters:

=over

=item $that

L<Sympa::List>, Robot or Site.

=item $email

Recipient (the person who asked for the command).

=item $cmd

XXX

=back

Returns:

Authenticaton key.

=back

=cut

# Old name: List::compute_auth().
sub compute_auth {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $that  = shift;
    my $email = shift;
    my $cmd   = shift;

    my ($list, $robot);
    if (ref $that eq 'Sympa::List') {
        $list = $that;
    } elsif ($that and $that ne '*') {
        $robot = $that;
    } else {
        $robot = '*';
    }

    $email =~ y/[A-Z]/[a-z]/;
    $cmd   =~ y/[A-Z]/[a-z]/;

    my ($cookie, $key, $listname);

    if ($list) {
        $listname = $list->{'name'};
        $cookie   = $list->{'admin'}{'cookie'}
            || Conf::get_robot_conf($robot, 'cookie');
    } else {
        $listname = '';
        $cookie = Conf::get_robot_conf($robot, 'cookie');
    }

    $key = substr(
        Digest::MD5::md5_hex(join('/', $cookie, $listname, $email, $cmd)),
        -8);

    return $key;
}

=over

=item request_auth

    # To send robot or site auth request
    Sympa::request_auth('*', 'user@dom.ain', 'remind');
    # To send auth request specific to a list
    Sympa::request_auth($list, 'user@dom.ain', 'subscribe'):

Sends an authentication request for a requested
command.

Parameters:

=over

=item $that

L<Sympa::List>, Robot or Site.

=item $email

Recipient (the person who asked for the command)

=item $cmd

'signoff', 'subscribe', 'add', 'del' or 'remind' if $that is List.
'remind' else.

=item @param

[0] is used if $cmd is subscribe|add|del|invite.
[1] is used if $cmd is C<'add'>.

=back

Returns:

C<1> or C<undef>.

=back

=cut

# Old name: List::request_auth().
sub request_auth {
    $log->syslog('debug2', '(%s, %s, %s, %s)', @_);
    my $that  = shift;
    my $email = shift;
    my $cmd   = shift;
    my @param = @_;

    my ($list, $robot);
    if (ref $that eq 'Sympa::List') {
        $list  = $that;
        $robot = $that->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot = $that;
    } else {
        $robot = '*';
    }

    my $keyauth;
    my $data = {'to' => $email};

    if ($list) {
        my $listname = $list->{'name'};
        $data->{'list_context'} = 1;

        if ($cmd =~ /signoff$/) {
            $keyauth = Sympa::compute_auth($list, $email, 'signoff');
            $data->{'command'} = "auth $keyauth $cmd $listname $email";
            $data->{'type'}    = 'signoff';

        } elsif ($cmd =~ /subscribe$/) {
            $keyauth = Sympa::compute_auth($list, $email, 'subscribe');
            $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
            $data->{'type'}    = 'subscribe';

        } elsif ($cmd =~ /add$/) {
            $keyauth = Sympa::compute_auth($list, $param[0], 'add');
            $data->{'command'} =
                "auth $keyauth $cmd $listname $param[0] $param[1]";
            $data->{'type'} = 'add';

        } elsif ($cmd =~ /del$/) {
            my $keyauth = Sympa::compute_auth($list, $param[0], 'del');
            $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
            $data->{'type'}    = 'del';

        } elsif ($cmd eq 'remind') {
            my $keyauth = Sympa::compute_auth($list, '', 'remind');
            $data->{'command'} = "auth $keyauth $cmd $listname";
            $data->{'type'}    = 'remind';

        } elsif ($cmd eq 'invite') {
            my $keyauth = Sympa::compute_auth($list, $param[0], 'invite');
            $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
            $data->{'type'}    = 'invite';
        }

        $data->{'command_escaped'} = tools::escape_url($data->{'command'});
        $data->{'auto_submitted'}  = 'auto-replied';
        unless (Sympa::send_file($list, 'request_auth', $email, $data)) {
            $log->syslog('notice',
                'Unable to send template "request_auth" to %s', $email);
            return undef;
        }

    } else {
        if ($cmd eq 'remind') {
            my $keyauth = Sympa::compute_auth('*', '', $cmd);
            $data->{'command'} = "auth $keyauth $cmd *";
            $data->{'command_escaped'} =
                tools::escape_url($data->{'command'});
            $data->{'type'} = 'remind';

        }
        $data->{'auto_submitted'} = 'auto-replied';
        unless (Sympa::send_file($robot, 'request_auth', $email, $data)) {
            $log->syslog('notice',
                'Unable to send template "request_auth" to %s', $email);
            return undef;
        }
    }

    return 1;
}

=head3 Finding config files and templates

=over 4

=item search_fullpath ( $that, $name, [ opt => val, ...] )

    # To get file name for global site
    $file = Sympa::search_fullpath('*', $name);
    # To get file name for a robot
    $file = Sympa::search_fullpath($robot_id, $name);
    # To get file name for a family
    $file = Sympa::search_fullpath($family, $name);
    # To get file name for a list
    $file = Sympa::search_fullpath($list, $name);

Look for a file in the list > robot > site > default locations.

Possible values for options:
    order     => 'all'
    subdir    => directory ending each path
    lang      => language
    lang_only => if paths without lang subdirectory would be omitted

Returns full path of target file C<I<root>/I<subdir>/I<lang>/I<name>>
or C<I<root>/I<subdir>/I<name>>.
I<root> is the location determined by target object $that.
I<subdir> and I<lang> are optional.
If C<lang_only> option is set, paths without I<lang> subdirectory is omitted.

=back

=cut

# Old names:
# [<=6.2a] tools::get_filename()
# [6.2b] tools::search_fullpath()
# [trunk] Sympa::ConfigurableObject::get_etc_filename()
sub search_fullpath {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $that    = shift;
    my $name    = shift;
    my %options = @_;

    my (@try, $default_name);

    ## template refers to a language
    ## => extend search to default tpls
    ## FIXME: family path precedes to list path.  Is it appropriate?
    if ($name =~ /^(\S+)\.([^\s\/]+)\.tt2$/) {
        $default_name = $1 . '.tt2';
        @try =
            map { ($_ . '/' . $name, $_ . '/' . $default_name) }
            @{Sympa::get_search_path($that, %options)};
    } else {
        @try =
            map { $_ . '/' . $name }
            @{Sympa::get_search_path($that, %options)};
    }

    my @result;
    foreach my $f (@try) {
##        if (-l $f) {
##            my $realpath = Cwd::abs_path($f);    # follow symlink
##            next unless $realpath and -r $realpath;
##        } elsif (!-r $f) {
##            next;
##        }
        next unless -r $f;
        $log->syslog('debug3', 'Name: %s; file %s', $name, $f);

        if ($options{'order'} and $options{'order'} eq 'all') {
            push @result, $f;
        } else {
            return $f;
        }
    }
    if ($options{'order'} and $options{'order'} eq 'all') {
        return @result;
    }

    return undef;
}

=over 4

=item get_search_path ( $that, [ opt => val, ... ] )

    # To make include path for global site
    @path = @{Sympa::get_search_path('*')};
    # To make include path for a robot
    @path = @{Sympa::get_search_path($robot_id)};
    # To make include path for a family
    @path = @{Sympa::get_search_path($family)};
    # To make include path for a list
    @path = @{Sympa::get_search_path($list)};

make an array of include path for tt2 parsing

IN :
      -$that(+) : ref(Sympa::List) | ref(Sympa::Family) | Robot | "*"
      -%options : options

Possible values for options:
    subdir    => directory ending each path
    lang      => language
    lang_only => if paths without lang subdirectory would be omitted

OUT : ref(ARRAY) of tt2 include path

=begin comment

Note:
As of 6.2b, argument $lang is recommended to be IETF language tag,
rather than locale name.

=end comment

=back

=cut

# Old names:
# [<=6.2a] tools::make_tt2_include_path()
# [6.2b] tools::get_search_path()
# [trunk] Sympa::ConfigurableObject::get_etc_include_path()
sub get_search_path {
    $log->syslog('debug3', '(%s, %s, %s)', @_);
    my $that    = shift;
    my %options = @_;

    my $subdir    = $options{'subdir'};
    my $lang      = $options{'lang'};
    my $lang_only = $options{'lang_only'};

    ## Get language subdirectories.
    my $lang_dirs;
    if ($lang) {
        ## For compatibility: add old-style "locale" directory at first.
        ## Add lang itself and fallback directories.
        $lang_dirs = [
            grep {$_} (
                Sympa::Language::lang2oldlocale($lang),
                Sympa::Language::implicated_langs($lang)
            )
        ];
    }

    return [_get_search_path($that, $subdir, $lang_dirs, $lang_only)];
}

sub _get_search_path {
    my $that = shift;
    my ($subdir, $lang_dirs, $lang_only) = @_;    # shift is not used

    my @search_path;

    if (ref $that and ref $that eq 'Sympa::List') {
        my $path_list;
        my $path_family;
        @search_path = _get_search_path($that->{'domain'}, @_);

        if ($subdir) {
            $path_list = $that->{'dir'} . '/' . $subdir;
        } else {
            $path_list = $that->{'dir'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                unshift @search_path, $path_list;
            }
            unshift @search_path, map { $path_list . '/' . $_ } @$lang_dirs;
        } else {
            unshift @search_path, $path_list;
        }

        if (defined $that->get_family) {
            my $family = $that->get_family;
            if ($subdir) {
                $path_family = $family->{'dir'} . '/' . $subdir;
            } else {
                $path_family = $family->{'dir'};
            }
            if ($lang_dirs) {
                unless ($lang_only) {
                    unshift @search_path, $path_family;
                }
                unshift @search_path,
                    map { $path_family . '/' . $_ } @$lang_dirs;
            } else {
                unshift @search_path, $path_family;
            }
        }
    } elsif (ref $that and ref $that eq 'Sympa::Family') {
        my $path_family;
        @search_path = _get_search_path($that->{'robot'}, @_);

        if ($subdir) {
            $path_family = $that->{'dir'} . '/' . $subdir;
        } else {
            $path_family = $that->{'dir'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                unshift @search_path, $path_family;
            }
            unshift @search_path, map { $path_family . '/' . $_ } @$lang_dirs;
        } else {
            unshift @search_path, $path_family;
        }
    } elsif (not ref $that and $that and $that ne '*') {    # Robot
        my $path_robot;
        @search_path = _get_search_path('*', @_);

        if ($subdir) {
            $path_robot = $Conf::Conf{'etc'} . '/' . $that . '/' . $subdir;
        } else {
            $path_robot = $Conf::Conf{'etc'} . '/' . $that;
        }
        if (-d $path_robot) {
            if ($lang_dirs) {
                unless ($lang_only) {
                    unshift @search_path, $path_robot;
                }
                unshift @search_path,
                    map { $path_robot . '/' . $_ } @$lang_dirs;
            } else {
                unshift @search_path, $path_robot;
            }
        }
    } elsif (not ref $that and $that eq '*') {    # Site
        my $path_etcbindir;
        my $path_etcdir;

        if ($subdir) {
            $path_etcbindir = Sympa::Constants::DEFAULTDIR . '/' . $subdir;
            $path_etcdir    = $Conf::Conf{'etc'} . '/' . $subdir;
        } else {
            $path_etcbindir = Sympa::Constants::DEFAULTDIR;
            $path_etcdir    = $Conf::Conf{'etc'};
        }
        if ($lang_dirs) {
            unless ($lang_only) {
                @search_path = (
                    (map { $path_etcdir . '/' . $_ } @$lang_dirs),
                    $path_etcdir,
                    (map { $path_etcbindir . '/' . $_ } @$lang_dirs),
                    $path_etcbindir
                );
            } else {
                @search_path = (
                    (map { $path_etcdir . '/' . $_ } @$lang_dirs),
                    (map { $path_etcbindir . '/' . $_ } @$lang_dirs)
                );
            }
        } else {
            @search_path = ($path_etcdir, $path_etcbindir);
        }
    } else {
        die 'bug in logic.  Ask developer';
    }

    return @search_path;
}

=head3 Sending Notifications

=over 4

=item send_dsn ( $that, $message,
[ { key => val, ... }, [ $status, [ $diag ] ] ] )

    # To send site-wide DSN
    Sympa::send_dsn('*', $message, {'recipient' => $rcpt},
        '5.1.2', 'Unknown robot');
    # To send DSN related to a robot
    Sympa::send_dsn($robot, $message, {'listname' => $name},
        '5.1.1', 'Unknown list');
    # To send DSN specific to a list
    Sympa::send_dsn($list, $message, {}, '2.1.5', 'Success');

Sends a delivery status notification (DSN) to SENDER
by parsing dsn.tt2 template.

=back

=cut

# Default diagnostic messages taken from IANA registry:
# http://www.iana.org/assignments/smtp-enhanced-status-codes/
# They should be modified to fit in Sympa.
my %diag_messages = (
    'default' => 'Other undefined Status',
    # success
    '2.1.5' => 'Destination address valid',
    # no available family, dynamic list creation failed, etc.
    '4.2.1' => 'Mailbox disabled, not accepting messages',
    # no subscribers in dynamic list
    '4.2.4' => 'Mailing list expansion problem',
    # unknown list address
    '5.1.1' => 'Bad destination mailbox address',
    # unknown robot
    '5.1.2' => 'Bad destination system address',
    # too large
    '5.2.3' => 'Message length exceeds administrative limit',
    # misconfigured family list
    '5.3.5' => 'System incorrectly configured',
    # loop detected
    '5.4.6' => 'Routing loop detected',
    # failed to personalize (merge_feature)
    '5.6.5' => 'Conversion Failed',
    # virus found
    '5.7.0' => 'Other or undefined security status',
    # failed to re-encrypt decrypted message
    '5.7.5' => 'Cryptographic failure',
);

# Old names: tools::send_dsn(), Sympa::ConfigurableObject::send_dsn().
sub send_dsn {
    my $that    = shift;
    my $message = shift;
    my $param   = shift || {};
    my $status  = shift;
    my $diag    = shift;

    unless (ref $message eq 'Sympa::Message') {
        $log->syslog('err', 'object %s is not Message', $message);
        return undef;
    }

    my $sender;
    if (defined($sender = $message->{'envelope_sender'})) {
        ## Won't reply to message with null envelope sender.
        return 0 if $sender eq '<>';
    } elsif (!defined($sender = $message->{'sender'})) {
        $log->syslog('err', 'No sender found');
        return undef;
    }

    my $recipient = '';
    if (ref $that eq 'Sympa::List') {
        $recipient = $that->get_list_address;
        $status ||= '5.1.1';
    } elsif (!ref $that and $that and $that ne '*') {
        if ($param->{'listname'}) {
            if ($param->{'function'}) {
                $recipient = sprintf '%s-%s@%s', $param->{'listname'},
                    $param->{'function'}, Conf::get_robot_conf($that, 'host');
            } else {
                $recipient = sprintf '%s@%s', $param->{'listname'},
                    Conf::get_robot_conf($that, 'host');
            }
        }
        $recipient ||= $param->{'recipient'};
        $status ||= '5.1.1';
    } elsif ($that eq '*') {
        $recipient = $param->{'recipient'};
        $status ||= '5.1.2';
    } else {
        die 'bug in logic.  Ask developer';
    }

    # Diagnostic message.
    $diag ||= $diag_messages{$status} || $diag_messages{'default'};
    # Delivery result, "failed" or "delivered".
    my $action = (index($status, '2') == 0) ? 'delivered' : 'failed';

    my $header = $message->header_as_string;

    my $date =
        (eval { DateTime->now(time_zone => 'local') } || DateTime->now)
        ->strftime('%a, %{day} %b %Y %H:%M:%S %z');

    my $dsn_message = Sympa::Message->new_from_template(
        $that, 'dsn', $sender,
        {   %$param,
            'recipient'       => $recipient,
            'to'              => $sender,
            'date'            => $date,
            'header'          => $header,
            'auto_submitted'  => 'auto-replied',
            'action'          => $action,
            'status'          => $status,
            'diagnostic_code' => $diag,
        }
    );
    if ($dsn_message) {
        # Set envelope sender.  DSN _must_ have null envelope sender.
        $dsn_message->{envelope_sender} = '<>';
    }
    unless ($dsn_message and Sympa::Bulk->new->store($dsn_message, $sender)) {
        $log->syslog('err', 'Unable to send DSN to %s', $sender);
        return undef;
    }

    return 1;
}

=over

=item send_file ( $that, $tpl, $who, [ $context, [ options... ] ] )

    # To send site-global (not relative to a list or a robot)
    # message
    Sympa::send_file('*', $template, $who, ...);
    # To send global (not relative to a list, but relative to a
    # robot) message
    Sympa::send_file($robot, $template, $who, ...);
    # To send message relative to a list
    Sympa::send_file($list, $template, $who, ...);

Send a message to user(s).
Find the tt2 file according to $tpl, set up
$data for the next parsing (with $context and
configuration)
Message is signed if the list has a key and a
certificate

Note: List::send_global_file() was deprecated.

=back

=cut

# Old name: List::send_file() and List::send_global_file().
sub send_file {
    $log->syslog('debug2', '(%s, %s, %s, ...)', @_);
    my $that    = shift;
    my $tpl     = shift;
    my $who     = shift;
    my $context = shift || {};
    my %options = @_;

    my $message =
        Sympa::Message->new_from_template($that, $tpl, $who, $context,
        %options);

    unless ($message and defined Sympa::Bulk->new->store($message, $who)) {
        $log->syslog('err', 'Could not send template %s to %s', $tpl, $who);
        return undef;
    }

    return 1;
}

=over 4

=item send_notify_to_listmaster ( $that, $operation, $data )

    # To send notify to super listmaster(s)
    Sympa::send_notify_to_listmaster('*', 'css_updated', ...);
    # To send notify to normal (per-robot) listmaster(s)
    Sympa::send_notify_to_listmaster($robot, 'web_tt2_error', ...);
    # To send notify to normal listmaster(s) of robot the list belongs to.
    Sympa::send_notify_to_listmaster($list, 'request_list_creation', ...);

Sends a notice to (super or normal) listmaster by parsing
listmaster_notification.tt2 template.

Parameters:

=over

=item $self

L<Sympa::List>, Robot or Site.

=item $operation

Notification type.

=item $param

Hashref or arrayref.
Values for template parsing.

=back

Returns:

C<1> or C<undef>.

=back

=cut

# Old name: List::send_notify_to_listmaster()
sub send_notify_to_listmaster {
    $log->syslog('debug2', '(%s, %s, %s)', @_) unless $_[1] eq 'logs_failed';
    my $that      = shift;
    my $operation = shift;
    my $data      = shift;

    my ($list, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $list->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        $robot_id = '*';
    }

    my $listmaster =
        [split /\s*,\s*/, Conf::get_robot_conf($robot_id, 'listmaster')];
    my $to =
          Conf::get_robot_conf($robot_id, 'listmaster_email') . '@'
        . Conf::get_robot_conf($robot_id, 'host');

    if (ref $data ne 'HASH' and ref $data ne 'ARRAY') {
        die
            'Error on incoming parameter "$data", it must be a ref on HASH or a ref on ARRAY';
    }

    if (ref $data ne 'HASH') {
        my $d = {};
        foreach my $i ((0 .. $#{$data})) {
            $d->{"param$i"} = $data->[$i];
        }
        $data = $d;
    }

    $data->{'to'}             = $to;
    $data->{'type'}           = $operation;
    $data->{'auto_submitted'} = 'auto-generated';

    my @tosend;

    if ($operation eq 'no_db' or $operation eq 'db_restored') {
        $data->{'db_name'} = Conf::get_robot_conf($robot_id, 'db_name');
    }

    if (   $operation eq 'request_list_creation'
        or $operation eq 'request_list_renaming') {
        foreach my $email (@$listmaster) {
            my $cdata = Sympa::Tools::Data::dup_var($data);
            $cdata->{'one_time_ticket'} =
                Sympa::Auth::create_one_time_ticket($email, $robot_id,
                'get_pending_lists', $cdata->{'ip'});
            push @tosend,
                {
                email => $email,
                data  => $cdata
                };
        }
    } else {
        push @tosend,
            {
            email => $listmaster,
            data  => $data
            };
    }

    foreach my $ts (@tosend) {
        my $email = $ts->{'email'};
        # Skip DB access because DB is not accessible
        $email = [$email]
            if not ref $email
                and (  $operation eq 'missing_dbd'
                    or $operation eq 'no_db'
                    or $operation eq 'db_restored');

        my $notif_message =
            Sympa::Message->new_from_template($that,
            'listmaster_notification', $email, $ts->{'data'});

        unless (
            $notif_message
            and defined Sympa::Alarm->instance->store(
                $notif_message, $email, operation => $operation
            )
            ) {
            $log->syslog(
                'notice',
                'Unable to send template "listmaster_notification" to %s listmaster %s',
                $robot_id,
                $listmaster
            ) unless $operation eq 'logs_failed';
            return undef;
        }
    }

    return 1;
}

=head3 Internationalization

=over

=item best_language ( LANG, ... )

    # To get site-wide best language.
    $lang = Sympa::best_language('*', 'de', 'en-US;q=0.9');
    # To get robot-wide best language.
    $lang = Sympa::best_language($robot, 'de', 'en-US;q=0.9');
    # To get list-specific best language.
    $lang = Sympa::best_language($list, 'de', 'en-US;q=0.9');

Chooses best language under the context of List, Robot or Site.
Arguments are language codes (see L<Language>) or ones with quality value.
If no arguments are given, the value of C<HTTP_ACCEPT_LANGUAGE> environment
variable will be used.

Returns language tag or, if negotiation failed, lang of object.

=back

=cut

sub best_language {
    my $that = shift;
    my $accept_string = join ',', grep { $_ and $_ =~ /\S/ } @_;
    $accept_string ||= $ENV{HTTP_ACCEPT_LANGUAGE} || '*';

    my @supported_languages;
    my %supported_languages;
    my @langs = ();
    my $lang;

    if (ref $that eq 'Sympa::List') {
        @supported_languages =
            Sympa::get_supported_languages($that->{'domain'});
        $lang = $that->{'admin'}{'lang'};
    } elsif (!ref $that) {
        @supported_languages = Sympa::get_supported_languages($that || '*');
        $lang = Conf::get_robot_conf($that || '*', 'lang');
    } else {
        die 'bug in logic.  Ask developer';
    }
    %supported_languages = map { $_ => 1 } @supported_languages;
    push @langs, $lang
        if $supported_languages{$lang};

    if (ref $that eq 'Sympa::List') {
        my $lang = Conf::get_robot_conf($that->{'domain'}, 'lang');
        push @langs, $lang
            if $supported_languages{$lang} and !grep { $_ eq $lang } @langs;
    }
    if (ref $that eq 'Sympa::List' or !ref $that and $that and $that ne '*') {
        my $lang = $Conf::Conf{'lang'};
        push @langs, $lang
            if $supported_languages{$lang} and !grep { $_ eq $lang } @langs;
    }
    foreach my $lang (@supported_languages) {
        push @langs, $lang
            if !grep { $_ eq $lang } @langs;
    }

    return Sympa::Language::negotiate_lang($accept_string, @langs) || $lang;
}

=over 4

=item get_supported_languages ( $that )

I<Function>.
Gets supported languages, canonicalized.
In array context, returns array of supported languages.
In scalar context, returns arrayref to them.

=back

=cut

#FIXME: Inefficient.  Would be cached.
#FIXME: Would also accept Sympa::List object.
# Old name: [trunk] Sympa::Site::supported_languages().
sub get_supported_languages {
    my $robot = shift;

    my @lang_list = ();
    if (%Conf::Conf) {    # configuration loaded.
        my $supported_lang;

        if ($robot and $robot ne '*') {
            $supported_lang = Conf::get_robot_conf($robot, 'supported_lang');
        } else {
            $supported_lang = $Conf::Conf{'supported_lang'};
        }

        my $language = Sympa::Language->instance;
        $language->push_lang;
        @lang_list =
            grep { $_ and $_ = $language->set_lang($_) }
            split /[\s,]+/, $supported_lang;
        $language->pop_lang;
    }
    @lang_list = ('en') unless @lang_list;
    return @lang_list if wantarray;
    return \@lang_list;
}

1;
__END__

=head1 SEE ALSO

L<Sympa::Site> (not yet available),
L<Sympa::Robot> (not yet available),
L<Sympa::Family>,
L<Sympa::List>.

=cut
