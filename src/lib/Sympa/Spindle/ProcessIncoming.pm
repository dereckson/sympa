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

package Sympa::Spindle::ProcessIncoming;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Copy qw();
use POSIX qw();

use Sympa;
use Sympa::Alarm;
use Sympa::Commands;
use Conf;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Process;
use Sympa::Regexps;
use Sympa::Report;
use Sympa::Scenario;
use Sympa::Tools::Data;
use Sympa::Topic;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;
my $mailer   = Sympa::Mailer->instance;
my $process  = Sympa::Process->instance;

use constant _distaff => 'Sympa::Spool::Incoming';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 0) {
        $self->{_loop_info}     = {};
        $self->{_msgid}         = {};
        $self->{_msgid_cleanup} = time;
    } elsif ($state == 1) {
    Sympa::List::init_list_cache();
    # Process grouped notifications
    Sympa::Alarm->instance->flush;

    # Cleanup in-memory msgid table, only in a while.
    if (time > $self->{_msgid_cleanup} +
        $Conf::Conf{'msgid_table_cleanup_frequency'}) {
        $self->_clean_msgid_table();
        $self->{_msgid_cleanup} = time;
    }
    } elsif ($state == 2) {
    # Free zombie sendmail process.
    Sympa::Process->instance->reap_child;
    }

    1;
}

sub _on_success {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

            if ($self->{keepcopy}) {
                unless (
                    File::Copy::copy(
                        $self->{distaff}->{directory} . '/' . $handle->basename,
                        $self->{keepcopy} . '/' . $handle->basename
                    )
                    ) {
                    $log->syslog(
                        'notice',
                        'Could not rename %s/%s to %s/%s: %m',
                        $self->{distaff}->{directory},
                        $handle->basename,
                        $self->{keepcopy},
                        $handle->basename
                    );
                }
            }

    $self->SUPER::_on_success($message, $handle);
}

# Handles a file received and files in the queue directory.
# This will read the file, separate the header and the body
# of the message and call the adequate function wether we
# have received a command or a message to be redistributed
# to a list.
# Old name: process_message() in sympa_msg.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    unless (defined $message->{'message_id'}
        and length $message->{'message_id'}) {
        $log->syslog('err', 'Message %s has no message ID', $message);
        $log->db_log(
            #'robot'        => $robot,
            #'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => $message->get_id,
            'target_email' => "",
            'msg_id'       => "",
            'status'       => 'error',
            'error_type'   => 'no_message_id',
            'user_email'   => $message->{'sender'}
        );
        return undef;
    }

    my $msg_id = $message->{message_id};

    $language->set_lang($self->{lang}, $Conf::Conf{'lang'}, 'en');

    # Compatibility: Message with checksum by Sympa <=6.2a.40
    # They should be migrated.
    if ($message and $message->{checksum}) {
        $log->syslog('err',
            '%s: Message with old format.  Run upgrade_send_spool.pl',
            $message);
        return 0;    # Skip
    }

    $log->syslog(
        'notice',
        'Processing %s; envelope_sender=%s; message_id=%s; sender=%s',
        $message,
        $message->{envelope_sender},
        $message->{message_id},
        $message->{sender}
    );

    my $robot;
    my $listname;

    if (ref $message->{context} eq 'Sympa::List') {
        $robot = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        # Older "sympa" alias may not have "@domain" in argument of queue
        # program.
        $robot = $Conf::Conf{'domain'};
    }
    $listname = $message->{'listname'};

    ## Ignoring messages with no sender
    my $sender = $message->{'sender'};
    unless ($message->{'md5_check'} or $sender) {
        $log->syslog('err', 'No sender found in message %s', $message);
        $log->db_log(
            'robot'        => $robot,
            'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => "",
            'target_email' => "",
            'msg_id'       => $msg_id,
            'status'       => 'error',
            'error_type'   => 'no_sender',
            'user_email'   => $sender
        );
        return undef;
    }

    ## Unknown robot
    unless ($message->{'md5_check'} or Conf::valid_robot($robot)) {
        $log->syslog('err', 'Robot %s does not exist', $robot);
        Sympa::Report::reject_report_msg('user', 'list_unknown', $sender,
            {'listname' => $listname, 'message' => $message},
            '*', $message->as_string, '');
        $log->db_log(
            'robot'        => $robot,
            'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => "",
            'target_email' => "",
            'msg_id'       => $msg_id,
            'status'       => 'error',
            'error_type'   => 'unknown_robot',
            'user_email'   => $sender
        );
        return undef;
    }

    $language->set_lang(Conf::get_robot_conf($robot, 'lang'));

    # Load spam status.
    $message->check_spam_status;
    # Check DKIM signatures.
    $message->check_dkim_signature;
    # Check S/MIME signature.
    $message->check_smime_signature;
    # Decrypt message.  On success, check nested S/MIME signature.
    if ($message->smime_decrypt and not $message->{'smime_signed'}) {
        $message->check_smime_signature;
    }

    # *** Now message content may be altered. ***

    # Enable SMTP logging if required.
    $mailer->{log_smtp} = $self->{log_smtp}
        || Sympa::Tools::Data::smart_eq(
        Conf::get_robot_conf($robot, 'log_smtp'), 'on');
    # Setting log_level using conf unless it is set by calling option.
    $log->{level} = (defined $self->{log_level})
        ? $self->{log_level}
        : Conf::get_robot_conf($robot, 'log_level');

    ## Strip of the initial X-Sympa-To and X-Sympa-Checksum internal headers
    delete $message->{'rcpt'};
    delete $message->{'checksum'};

    my $list =
        (ref $message->{context} eq 'Sympa::List')
        ? $message->{context}
        : undef;

    my $list_address;
    if ($message->{'listtype'} and $message->{'listtype'} eq 'listmaster') {
        $list_address =
              Conf::get_robot_conf($robot, 'listmaster_email') . '@'
            . Conf::get_robot_conf($robot, 'host');
    } elsif ($message->{'listtype'} and $message->{'listtype'} eq 'sympa') {
        $list_address =
              Conf::get_robot_conf($robot, 'email') . '@'
            . Conf::get_robot_conf($robot, 'host');
    } else {
        unless (ref $list eq 'Sympa::List') {
            $log->syslog('err', 'List %s does not exist', $listname);
            Sympa::Report::reject_report_msg(
                'user',
                'list_unknown',
                $sender,
                {   'listname' => $listname,
                    'message'  => $message
                },
                $robot,
                $message->as_string,
                ''
            );
            $log->db_log(
                'robot'        => $robot,
                'list'         => $listname,
                'action'       => 'process_message',
                'parameters'   => "",
                'target_email' => "",
                'msg_id'       => $msg_id,
                'status'       => 'error',
                'error_type'   => 'unknown_list',
                'user_email'   => $sender
            );
            return undef;
        }
        $list_address = $list->get_list_address();
    }

    ## Loop prevention
    if (ref $list eq 'Sympa::List'
        and Sympa::Tools::Data::smart_eq(
            $list->{'admin'}{'reject_mail_from_automates_feature'}, 'on'
        )
        ) {
        my $conf_loop_prevention_regex;
        $conf_loop_prevention_regex =
            $list->{'admin'}{'loop_prevention_regex'};
        $conf_loop_prevention_regex ||=
            Conf::get_robot_conf($robot, 'loop_prevention_regex');
        if ($sender =~ /^($conf_loop_prevention_regex)(\@|$)/mi) {
            $log->syslog(
                'err',
                'Ignoring message which would cause a loop, sent by %s; matches loop_prevention_regex',
                $sender
            );
            return undef;
        }

        ## Ignore messages that would cause a loop
        ## Content-Identifier: Auto-replied is generated by some non standard
        ## X400 mailer
        if (grep {/Auto-replied/i} $message->get_header('Content-Identifier')
            or grep {/Auto Reply to/i}
            $message->get_header('X400-Content-Identifier')
            or grep { !/^no$/i } $message->get_header('Auto-Submitted')) {
            $log->syslog('err',
                "Ignoring message which would cause a loop; message appears to be an auto-reply"
            );
            return undef;
        }
    }

    ## Loop prevention
    my $loop;
    foreach $loop ($message->get_header('X-Loop')) {
        chomp $loop;
        $log->syslog('debug2', 'X-Loop: %s', $loop);
        #foreach my $l (split(/[\s,]+/, lc($loop))) {
        if ($loop eq lc($list_address)) {
            $log->syslog('err',
                'Ignoring message which would cause a loop (X-Loop: %s)',
                $loop);
            return undef;
        }
        #}
    }

    # Anti-virus
    my $rc = $message->check_virus_infection;
    if ($rc) {
        my $antivirus_notify =
            Conf::get_robot_conf($robot, 'antivirus_notify') || 'none';
        if ($antivirus_notify eq 'sender') {
            Sympa::send_file(
                $robot,
                'your_infected_msg',
                $sender,
                {   'virus_name'     => $rc,
                    'recipient'      => $list_address,
                    'sender'         => $message->{sender},
                    'lang'           => Conf::get_robot_conf($robot, 'lang'),
                    'auto_submitted' => 'auto-replied'
                }
            );
        } elsif ($antivirus_notify eq 'delivery_status') {
            Sympa::send_dsn(
                $message->{context},
                $message,
                {   'virus_name' => $rc,
                    'recipient'  => $list_address,
                    'sender'     => $message->{sender}
                },
                '5.7.0'
            );
        }
        $log->syslog('notice',
            "Message for %s from %s ignored, virus %s found",
            $list_address, $sender, $rc);
        $log->db_log(
            'robot'        => $robot,
            'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => "",
            'target_email' => "",
            'msg_id'       => $msg_id,
            'status'       => 'error',
            'error_type'   => 'virus',
            'user_email'   => $sender
        );
        return undef;
    } elsif (!defined($rc)) {
        Sympa::send_notify_to_listmaster(
            $robot,
            'antivirus_failed',
            [   sprintf
                    "Could not scan message %s; The message has been saved as BAD.",
                $message->get_id
            ]
        );

        return undef;
    }

    # Route messages to appropriate handlers.
    if (    $message->{listtype}
        and $message->{listtype} eq 'owner'
        and $message->{'decoded_subject'}
        and $message->{'decoded_subject'} =~
        /\A\s*(subscribe|unsubscribe)(\s*$listname)?\s*\z/i) {
        # Simulate Smartlist behaviour with command in subject.
        $message->{listtype} = lc $1;
    }
    my $status = do {
        no strict 'refs';
        (   {   editor      => 'DoForward',
                listmaster  => 'DoForward',
                owner       => 'DoForward',    # -request
                return_path => 'DoForward',    # -owner
                subscribe   => 'DoCommand',
                sympa       => 'DoCommand',
                unsubscribe => 'DoCommand',
            }->{$message->{listtype} || ''}
                || 'DoMessage'
        )->($self, $message);
    };
    return $status;
}

############################################################
#  DoForward
############################################################
#  Handles a message sent to [list]-editor : the list editor,
#  [list]-request : the list owner or the listmaster.
#  Message is forwarded according to $function
#
# IN : -$msg (+): ref(message object).
#
# OUT : 1
#     | undef
#
############################################################
# Old name: DoForward() in sympa_msg.pl.
sub DoForward {
    my $self    = shift;
    my $message = shift;

    my ($name, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $name  = $message->{context}->{'name'};
        $robot = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $name  = 'sympa';
        $robot = $message->{context};
    } else {
        $name  = 'sympa';
        $robot = $Conf::Conf{'domain'};
    }
    my $function = $message->{listtype};

    my $msg        = $message->as_entity;        #FIXME: not required.
    my $messageid  = $message->{'message_id'};
    my $msg_string = $message->as_string;        #FIMXE: not required.
    my $sender     = $message->{'sender'};
    chomp $sender;

    if ($message->{'spam_status'} eq 'spam') {
        $log->syslog(
            'notice',
            'Message for %s-%s ignored, because tagued as spam (message ID: %s)',
            $name,
            $function,
            $messageid
        );
        return undef;
    }

    # Search for the list.
    my ($list, $recipient, $priority);

    if ($function eq 'listmaster') {
        $recipient =
            $Conf::Conf{'listmaster_email'} . '@'
            . Conf::get_robot_conf($robot, 'host');
        $priority = 0;
    } else {
        $list = $message->{context};
        unless (ref $list eq 'Sympa::List') {
            $log->syslog(
                'notice',
                'Message for %s function %s ignored, unknown list %s (message ID: %s)',
                $name,
                $function,
                $name,
                $messageid
            );
            my $sympa_email = Conf::get_robot_conf($robot, 'sympa');
            unless (
                Sympa::send_file(
                    $robot,
                    'list_unknown',
                    $sender,
                    {   'list' => $name,
                        'date' => POSIX::strftime(
                            "%d %b %Y  %H:%M",
                            localtime(time)
                        ),
                        'boundary'       => $sympa_email . time,
                        'header'         => $message->header_as_string,
                        'auto_submitted' => 'auto-replied'
                    }
                )
                ) {
                $log->syslog('notice',
                    'Unable to send template "list_unknown" to %s', $sender);
            }
            return undef;
        }

        $recipient = $list->get_list_address($function);
        $priority  = $list->{'admin'}{'priority'};
    }

    my @rcpt;

    $log->syslog('info',
        'Processing %s; message_id=%s; priority=%s; recipient=%s',
        $message, $messageid, $priority, $recipient);

    delete $message->{'rcpt'};
    delete $message->{'family'};

    if ($function eq 'listmaster') {
        @rcpt = Sympa::get_listmasters_email($robot);
        $log->syslog('notice', 'Warning: No listmaster defined in sympa.conf')
            unless @rcpt;
    } elsif ($function eq 'owner') {    # -request
        @rcpt = $list->get_admins_email('receptive_owner');
        @rcpt = $list->get_admins_email('owner') unless @rcpt;
        $log->syslog('notice', 'Warning: No owner defined at all in list %s',
            $name)
            unless @rcpt;
    } elsif ($function eq 'editor') {
        @rcpt = $list->get_admins_email('receptive_editor');
        @rcpt = $list->get_admins_email('actual_editor') unless @rcpt;
        $log->syslog('notice',
            'Warning: No owner and editor defined at all in list %s', $name)
            unless @rcpt;
    }

    # Did we find a recipient?
    unless (@rcpt) {
        $log->syslog('err',
            'Message for %s function %s ignored, %s undefined in list %s',
            $name, $function, $function, $name);
        my $string =
            sprintf
            'Impossible to forward a message to %s function %s : undefined in this list',
            $name, $function;
        Sympa::Report::reject_report_msg(
            'intern', $string, $sender,
            {   'msg_id'   => $messageid,
                'entry'    => 'forward',
                'function' => $function,
                'message'  => $msg
            },
            $robot,
            $msg_string,
            $list
        );
        $log->db_log(
            'robot'        => $robot,
            'list'         => $list->{'name'},
            'action'       => 'DoForward',
            'parameters'   => "$name,$function",
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }

    # Add or remove several headers to forward message safely.
    # - Add X-Loop: field to mitigate mail looping.
    # - The Sender: field should be added (overwritten) at least for Sender ID
    #   (a.k.a. SPF 2.0) compatibility.  Note that Resent-Sender: field will
    #   be removed.
    # - Apply DMARC protection if needed.
    #FIXME: Existing DKIM signature depends on these headers will be broken.
    #FIXME: Currently messages via -request and -editor addresses will be
    #       protected against DMARC if neccessary.  The listmaster address
    #       would be protected, too.
    $message->add_header('X-Loop', $recipient);
    $message->replace_header('Sender',
        Conf::get_robot_conf($robot, 'request'));
    $message->delete_header('Resent-Sender');
    if ($function eq 'owner' or $function eq 'editor') {
        $message->dmarc_protect if $list;
    }

    # Overwrite envelope sender.  It is REQUIRED for delivery.
    $message->{envelope_sender} = Conf::get_robot_conf($robot, 'request');

    unless (defined $mailer->store($message, \@rcpt)) {
        $log->syslog('err', 'Impossible to forward mail for %s function %s',
            $name, $function);
        my $string =
            sprintf 'Impossible to forward a message for %s function %s',
            $name, $function;
        Sympa::Report::reject_report_msg(
            'intern', $string, $sender,
            {   'msg_id'   => $messageid,
                'entry'    => 'forward',
                'function' => $function,
                'message'  => $msg
            },
            $robot,
            $msg_string,
            $list
        );
        $log->db_log(
            'robot'        => $robot,
            'list'         => $list->{'name'},
            'action'       => 'DoForward',
            'parameters'   => "$name,$function",
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }
    $log->db_log(
        'robot'        => $robot,
        'list'         => $list->{'name'},
        'action'       => 'DoForward',
        'parameters'   => "$name,$function",
        'target_email' => '',
        'msg_id'       => $messageid,
        'status'       => 'success',
        'error_type'   => '',
        'user_email'   => $sender
    );

    return 1;
}

####################################################
#  DoMessage
####################################################
#  Handles a message sent to a list. (Those that can
#  make loop and those containing a command are
#  rejected)
#
# IN : -$which (+): 'listname@hostname' - concerned list
#      -$message (+): ref(Message) - sent message
#      -$robot (+): robot
#
# OUT : 1 if ok (in order to remove the file from the queue)
#     | undef
#
####################################################
# Old name: DoMessage() in sympa_msg.pl.
sub DoMessage {
    my $self    = shift;
    my $message = shift;

    my ($list, $robot_id, $listname);
    if (ref($message->{context}) eq 'Sympa::List') {
        $list     = $message->{context};
        $robot_id = $list->{'domain'};
        $listname = $list->{'name'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot_id = $message->{context};
        $listname = $message->{'localpart'};
    } else {
        $robot_id = '*';
        $listname = $message->{'localpart'};
    }

    my $messageid  = $message->{'message_id'};
    my $msg        = $message->as_entity;        #FIMXE: not required.
    my $msg_string = $msg->as_string;            #FIXME: not required.

    my $sender = $message->{'sender'};

    ## List unknown
    unless ($list) {
        $log->syslog('notice', 'Unknown list %s', $listname);
        my $sympa_email = Conf::get_robot_conf($robot_id, 'sympa');

        unless (
            Sympa::send_file(
                $robot_id,
                'list_unknown',
                $sender,
                {   'list' => $listname,
                    'date' =>
                        POSIX::strftime("%d %b %Y  %H:%M", localtime(time)),
                    'boundary'       => $sympa_email . time,
                    'header'         => $message->header_as_string,
                    'auto_submitted' => 'auto-replied'
                }
            )
            ) {
            $log->syslog('notice',
                'Unable to send template "list_unknown" to %s', $sender);
        }
        return undef;
    }

    my $start_time = time;

    $language->set_lang(
        $list->{'admin'}{'lang'},
        Conf::get_robot_conf($robot_id, 'lang'),
        $Conf::Conf{'lang'}, 'en'
    );

    ## Now check if the sender is an authorized address.

    $log->syslog('info',
        "Processing message %s for %s with priority %s, <%s>",
        $message, $list, $list->{'admin'}{'priority'}, $messageid);

    if ($self->{_msgid}{$list->get_list_id()}{$messageid}) {
        $log->syslog(
            'err',
            'Found known Message-ID <%s>, ignoring message %s which would cause a loop',
            $messageid,
            $message
        );
        $log->db_log(
            'robot'        => $robot_id,
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'known_message',
            'user_email'   => $sender
        );
        return undef;
    }

    # Reject messages with commands
    if ($Conf::Conf{'misaddressed_commands'} =~ /reject/i) {
        # Check the message for commands and catch them.
        my $cmd = _check_command($message);
        if (defined $cmd) {
            $log->syslog('err',
                'Found command "%s" in message, ignoring message', $cmd);
            Sympa::Report::reject_report_msg('user', 'routing_error', $sender,
                {'message' => $message},
                $robot_id, $msg_string, $list);
            $log->db_log(
                'robot'        => $robot_id,
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'routing_error',
                'user_email'   => $sender
            );
            return undef;
        }
    }

    my $admin = $list->{'admin'};
    unless ($admin) {
        $log->syslog('err', 'List config is undefined');
        Sympa::Report::reject_report_msg('intern', '', $sender,
            {'message' => $message},
            $robot_id, $msg_string, $list);
        $log->db_log(
            'robot'        => $robot_id,
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }

    my $customheader = $admin->{'custom_header'};

    # Check if the message is too large
    my $max_size = $list->{'admin'}{'max_size'};

    if ($max_size && $message->{'size'} > $max_size) {
        $log->syslog('info',
            'Message for %s from %s rejected because too large (%d > %d)',
            $listname, $sender, $message->{'size'}, $max_size);
        Sympa::Report::reject_report_msg(
            'user',
            'message_too_large',
            $sender,
            {   'msg_size' => int($message->{'size'} / 1024),
                'max_size' => int($max_size / 1024)
            },
            $robot_id,
            '', $list
        );
        $log->db_log(
            'robot'        => $robot_id,
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'message_too_large',
            'user_email'   => $sender
        );
        return undef;
    }

    my $rc;

    my $context = {
        'sender'  => $sender,
        'message' => $message
    };

    # List msg topic.
    if ($list->is_there_msg_topic()) {
        my $topic;
        if ($topic = Sympa::Topic->load($message)) {
            # Is message already tagged?
            ;
        } elsif ($topic = Sympa::Topic->load($message, in_reply_to => 1)) {
            # Is message in-reply-to already tagged?
            $topic =
                Sympa::Topic->new(topic => $topic->{topic}, method => 'auto');
            $topic->store($message);
        } elsif (my $topic_list = $message->compute_topic) {
            # Not already tagged.
            $topic =
                Sympa::Topic->new(topic => $topic_list, method => 'auto');
            $topic->store($message);
        }

        if ($topic) {
            $context->{'topic'} = $context->{'topic_' . $topic->{method}} =
                $topic->{topic};
        }
        $context->{'topic_needed'} =
            (!$context->{'topic'} && $list->is_msg_topic_tagging_required());
    }

    ## Call scenarii : auth_method MD5 do not have any sense in send
    ## scenarii because auth is perfom by distribute or reject command.

    my $action;
    my $result;

    # the order of the following 3 lines is important ! SMIME > DKIM > SMTP
    my $auth_method =
          $message->{'smime_signed'} ? 'smime'
        : $message->{'md5_check'}    ? 'md5'
        : $message->{'dkim_pass'}    ? 'dkim'
        :                              'smtp';

    $result = Sympa::Scenario::request_action($list, 'send', $auth_method,
        $context);
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        $log->syslog(
            'err',
            'Message (%s) ignored because unable to evaluate scenario "send" for list %s',
            $messageid,
            $listname
        );
        Sympa::Report::reject_report_msg(
            'intern',
            'Message ignored because scenario "send" cannot be evaluated',
            $sender,
            {'msg_id' => $messageid, 'message' => $message},
            $robot_id,
            $msg_string,
            $list
        );
        $log->db_log(
            'robot'        => $robot_id,
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }

    ## message topic context
    if (($action =~ /^do_it/) && ($context->{'topic_needed'})) {
        $action = 'editorkey'
            if (
            $list->{'admin'}{'msg_topic_tagging'} eq 'required_moderator');
        $action = 'request_auth'
            if ($list->{'admin'}{'msg_topic_tagging'} eq 'required_sender');
    }

    if ($action =~ /^do_it/) {
        $message->{shelved}{dkim_sign} = 1
            if Sympa::Tools::Data::is_in_array(
            $list->{'admin'}{'dkim_signature_apply_on'}, 'any')
            or (
            Sympa::Tools::Data::is_in_array(
                $list->{'admin'}{'dkim_signature_apply_on'},
                'smime_authenticated_messages')
            and $message->{'smime_signed'}
            )
            or (
            Sympa::Tools::Data::is_in_array(
                $list->{'admin'}{'dkim_signature_apply_on'},
                'dkim_authenticated_messages')
            and $message->{'dkim_pass'}
            );

        ## Check TT2 syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $numsmtp = Sympa::List::distribute_msg($message);

        # Keep track of known message IDs...if any.
        $self->{_msgid}{$list->get_list_id()}{$messageid} = time
            if $messageid;

        unless (defined $numsmtp) {
            $log->syslog('err', 'Unable to send message to list %s',
                $listname);
            Sympa::Report::reject_report_msg('intern', '', $sender,
                {'msg_id' => $messageid, 'message' => $message},
                $robot_id, $msg_string, $list);
            $log->db_log(
                'robot'        => $robot_id,
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }
        $log->syslog(
            'info',
            'Message %s for %s from %s accepted (%d seconds, %d sessions, %d subscribers), message ID=%s, size=%d',
            $message,
            $listname,
            $sender,
            time - $start_time,
            $numsmtp,
            $list->get_total(),
            $messageid,
            $message->{'size'}
        );

        return 1;
    } elsif ($action =~ /^request_auth/) {
        ## Check syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $key = Sympa::List::send_confirm_to_sender($message);

        unless (defined $key) {
            $log->syslog('err',
                'Failed to send confirmation of %s for %s to sender %s',
                $message, $list, $sender);
            Sympa::Report::reject_report_msg(
                'intern', 'The request authentication sending failed',
                $sender, {'msg_id' => $messageid, 'message' => $message},
                $robot_id, $msg_string,
                $list
            );
            $log->db_log(
                'robot'        => $robot_id,
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }
        $log->syslog('notice',
            'Message for %s from %s kept for authentication with key %s',
            $listname, $sender, $key);
        $log->db_log(
            'robot'        => $robot_id,
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'success',
            'error_type'   => 'kept_for_auth',
            'user_email'   => $sender
        );
        return 1;
    } elsif ($action =~ /^editorkey(\s?,\s?(quiet))?/) {
        my $quiet = $2;

        ## Check syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $key = Sympa::List::send_confirm_to_editor($message, 'md5');

        unless (defined $key) {
            $log->syslog(
                'err',
                'Failed to moderation request of %s from %s for list %s to editor(s)',
                $message,
                $sender,
                $list
            );
            Sympa::Report::reject_report_msg(
                'intern',
                'The request moderation sending to moderator failed.',
                $sender,
                {'msg_id' => $messageid, 'message' => $message},
                $robot_id,
                $msg_string,
                $list
            );
            $log->db_log(
                'robot'        => $robot_id,
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }

        $log->syslog('info',
            'Key %s of message %s for list %s from %s sent to editors',
            $key, $message, $listname, $sender);

        # do not report to the sender if the message was tagged as a spam
        unless ($quiet or $message->{'spam_status'} eq 'spam') {
            unless (
                Sympa::Report::notice_report_msg(
                    'moderating_message', $sender,
                    {'message' => $message}, $robot_id,
                    $list
                )
                ) {
                $log->syslog(
                    'notice',
                    'Unable to send template "message_report", entry "moderating_message" to %s',
                    $sender
                );
            }
        }
        return 1;
    } elsif ($action =~ /^editor(\s?,\s?(quiet))?/) {
        my $quiet = $2;

        ## Check syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $key = Sympa::List::send_confirm_to_editor($message, 'smtp');

        unless (defined $key) {
            $log->syslog(
                'err',
                'Failed to send moderation request of %s by %s for list %s to editor(s)',
                $message,
                $sender,
                $list
            );
            Sympa::Report::reject_report_msg(
                'intern',
                'The request moderation sending to moderator failed.',
                $sender,
                {'msg_id' => $messageid, 'message' => $message},
                $robot_id,
                $msg_string,
                $list
            );
            $log->db_log(
                'robot'        => $robot_id,
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }

        $log->syslog('info', 'Message %s for %s from %s sent to editors',
            $message, $listname, $sender);

        # do not report to the sender if the message was tagged as a spam
        unless ($quiet or $message->{'spam_status'} eq 'spam') {
            unless (
                Sympa::Report::notice_report_msg(
                    'moderating_message', $sender,
                    {'message' => $message}, $robot_id,
                    $list
                )
                ) {
                $log->syslog('notice',
                    "sympa::DoMessage(): Unable to send template 'message_report', type 'success', entry 'moderating_message' to $sender"
                );
            }
        }
        return 1;
    } elsif ($action =~ /^reject(,(quiet))?/) {
        my $quiet = $2;

        $log->syslog(
            'notice',
            'Message for %s from %s rejected(%s) because sender not allowed',
            $listname,
            $sender,
            $result->{'tt2'}
        );

        # do not report to the sender if the message was tagued as a spam
        unless ($quiet or $message->{'spam_status'} eq 'spam') {
            if (defined $result->{'tt2'}) {
                unless (
                    Sympa::send_file(
                        $list, $result->{'tt2'},
                        $sender, {'auto_submitted' => 'auto-replied'}
                    )
                    ) {
                    $log->syslog('notice',
                        "sympa::DoMessage(): Unable to send template '$result->{'tt2'}' to $sender"
                    );
                }
            } else {
                unless (
                    Sympa::Report::reject_report_msg(
                        'auth', $result->{'reason'},
                        $sender, {'message' => $message},
                        $robot_id, $msg_string,
                        $list
                    )
                    ) {
                    $log->syslog(
                        'notice',
                        'Unable to send template "message_report", type "auth" to %s',
                        $sender
                    );
                }
            }
        }
        $log->db_log(
            'robot'        => $robot_id,
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'rejected_authorization',
            'user_email'   => $sender
        );
        return undef;
    } else {
        $log->syslog('err',
            'Unknown action %s returned by the scenario "send"', $action);
        Sympa::Report::reject_report_msg(
            'intern', 'Unknown action returned by the scenario "send"',
            $sender, {'msg_id' => $messageid, 'message' => $message},
            $robot_id, $msg_string,
            $list
        );
        $log->db_log(
            'robot'        => $robot_id,
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }
}

# Checks command in the body of the message.
# If there are any commands in it, returns string.
#
# IN : -$message (+): ref(Sympa::Message) - message to check
#
# OUT : -string: Command found
#       -undef:  Else.
#
# Old name: tools::checkcommand(), _check_command() in sympa_msg.pl.
sub _check_command {
    my $message = shift;

    my $commands_re = $Conf::Conf{'misaddressed_commands_regexp'};
    return undef unless defined $commands_re and length $commands_re;

    # Check for commands in the subject.
    my $subject_field = $message->{'decoded_subject'};
    $subject_field = '' unless defined $subject_field;
    $subject_field =~ s/\n//mg;    # multiline subjects
    my $re_regexp = Sympa::Regexps::re();
    $subject_field =~ s/^\s*(?:$re_regexp)?\s*(.*)\s*$/$1/i;

    if ($subject_field =~ /^($commands_re)$/im) {
        return $1;
    }

    my @body = map { s/\r\n|\n//; $_ } split /(?<=\n)/,
        ($message->get_plain_body || '');

    # More than 5 lines in the text.
    return undef if scalar @body > 5;

    foreach my $line (@body) {
        if ($line =~ /^($commands_re)\b/im) {
            return $1;
        }

        # Control is only applied to first non-blank line.
        last unless $line =~ /\A\s*\z/;
    }
    return undef;
}

############################################################
#  DoCommand
############################################################
#  Handles a command sent to the list manager.
#
# IN : -$message : ref(Message)
#
# OUT : $success
#     | undef
#
##############################################################
# Old name: DoCommand() in sympa_msg.pl.
sub DoCommand {
    my $self    = shift;
    my $message = shift;

    my ($list, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $list  = $message->{context};
        $robot = $list->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        $robot = '*';
    }

    my $messageid = $message->{'message_id'};

    $log->syslog(
        'debug',
        "Processing command with priority %s, %s",
        $Conf::Conf{'sympa_priority'}, $messageid
    );

    my $sender = $message->{'sender'};

    if ($message->{'spam_status'} eq 'spam') {
        $log->syslog(
            'notice',
            'Message for %s ignored, because tagged as spam (message ID: %s)',
            $message->{context},
            $messageid
        );
        return undef;
    }

    ## Detect loops
    if ($self->{_msgid}{'sympa@' . $robot}{$messageid}) {
        $log->syslog('err',
            'Found known Message-ID, ignoring command which would cause a loop'
        );
        $log->db_log(
            'robot' => $robot,
            #'list'         => 'sympa',
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'known_message',
            'user_email'   => $sender
        );
        # Clean old files from spool.
        return undef;
    }
    # Keep track of known message IDs...if any.
    $self->{_msgid}{'sympa@' . $robot}{$messageid} = time;

    # Initialize command report.
    Sympa::Report::init_report_cmd();

    my $status = _do_command($message);

    # Mail back the result.
    if (Sympa::Report::is_there_any_report_cmd()) {
        ## Loop prevention

        ## Count reports sent to $sender
        $self->{_loop_info}{$sender}{'count'}++;

        ## Sampling delay
        if ((time - ($self->{_loop_info}{$sender}{'date_init'} || 0)) <
            $Conf::Conf{'loop_command_sampling_delay'}) {

            # Notify listmaster of first rejection.
            if ($self->{_loop_info}{$sender}{'count'} ==
                $Conf::Conf{'loop_command_max'}) {
                ## Notify listmaster
                Sympa::send_notify_to_listmaster($robot, 'loop_command',
                    {'msg' => $message});
            }

            # Too many reports sent => message skipped !!
            if ($self->{_loop_info}{$sender}{'count'} >=
                $Conf::Conf{'loop_command_max'}) {
                $log->syslog(
                    'err',
                    'Ignoring message which would cause a loop, %d messages sent to %s; loop_command_max exceeded',
                    $self->{_loop_info}{$sender}{'count'},
                    $sender
                );

                return undef;
            }
        } else {
            # Sampling delay is over, reinit.
            $self->{_loop_info}{$sender}{'date_init'} = time;

            # We apply Decrease factor if a loop occurred.
            $self->{_loop_info}{$sender}{'count'} *=
                $Conf::Conf{'loop_command_decrease_factor'};
        }

        ## Send the reply message
        Sympa::Report::send_report_cmd($sender, $robot);
        $log->db_log(
            'robot' => $robot,
            #'list'         => 'sympa',
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => "",
            'msg_id'       => $message->{message_id},
            'status'       => 'success',
            'error_type'   => '',
            'user_email'   => $sender
        );

    }

    return $status;
}

# Old name: (part of) DoCommand() in sympa_msg.pl.
sub _do_command {
    my $message = shift;

    my ($list, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $list  = $message->{context};
        $robot = $list->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        $robot = '*';
    }

    my $success;
    my $cmd_found = 0;
    my $messageid = $message->{message_id};
    my $sender    = $message->{sender};

    # If type is subscribe or unsubscribe, parse as a single command.
    if (   $message->{listtype} eq 'subscribe'
        or $message->{listtype} eq 'unsubscribe') {
        $log->syslog('debug', 'Processing message for %s type %s',
            $message->{context}, $message->{listtype});
        # FIXME: at this point $message->{'dkim_pass'} does not verify that
        # Subject: is part of the signature. It SHOULD !
        my $auth_level = $message->{'dkim_pass'} ? 'dkim' : undef;

        Sympa::Commands::parse($sender, $robot,
            sprintf('%s %s', $message->{listtype}, $list->{'name'}),
            $auth_level, $message);
        $log->db_log(
            'robot'        => $robot,
            'list'         => $list->{'name'},
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'success',
            'error_type'   => '',
            'user_email'   => $sender
        );
        return 1;
    }

    ## Process the Subject of the message
    ## Search and process a command in the Subject field
    my $subject_field = $message->{'decoded_subject'};
    $subject_field = '' unless defined $subject_field;
    $subject_field =~ s/\n//mg;    ## multiline subjects
    my $re_regexp = Sympa::Regexps::re();
    $subject_field =~ s/^\s*(?:$re_regexp)?\s*(.*)\s*$/$1/i;

    #FIXME
    my $auth_level =
          $message->{'smime_signed'} ? 'smime'
        : $message->{'dkim_pass'}    ? 'dkim'
        :                              undef;

    if (defined $subject_field and $subject_field =~ /\S/) {
        $success ||= Sympa::Commands::parse($sender, $robot, $subject_field,
            $auth_level, $message);
        unless ($success and $success eq 'unknown_cmd') {
            $cmd_found = 1;
        }
    }

    my $i;
    my $size;

    ## Process the body of the message
    ## unless subject contained commands or message has no body
    unless ($cmd_found) {
        my $body = $message->get_plain_body;
        unless (defined $body) {
            $log->syslog('err', 'Could not change multipart to singlepart');
            Sympa::Report::global_report_cmd('user', 'error_content_type',
                {});
            $log->db_log(
                'robot' => $robot,
                #'list'         => 'sympa',
                'action'       => 'DoCommand',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'error_content_type',
                'user_email'   => $sender
            );
            return $success ? 1 : undef;
        }

        foreach $i (split /\r\n|\r|\n/, $body) {
            last if $i =~ /^-- $/;    ## ignore signature
            $i =~ s/^\s*>?\s*(.*)\s*$/$1/g;
            next unless length $i;    ## skip empty lines
            next if $i =~ /^\s*\#/;

            #FIXME
            $auth_level =
                  $message->{'smime_signed'} ? 'smime'
                : $message->{'dkim_pass'}    ? 'dkim'
                :                              $auth_level;
            my $status =
                Sympa::Commands::parse($sender, $robot, $i, $auth_level,
                $message);

            $cmd_found = 1;    # if problem no_cmd_understood is sent here
            if ($status eq 'unknown_cmd') {
                $log->syslog('notice', 'Unknown command found: %s', $i);
                Sympa::Report::reject_report_cmd('user', 'not_understood', {},
                    $i);
                $log->db_log(
                    'robot' => $robot,
                    #'list'         => 'sympa',
                    'action'       => 'DoCommand',
                    'parameters'   => $message->get_id,
                    'target_email' => '',
                    'msg_id'       => $messageid,
                    'status'       => 'error',
                    'error_type'   => 'not_understood',
                    'user_email'   => $sender
                );
                last;
            }
            if ($i =~ /^(quit|end|stop|-)\s*$/io) {
                last;
            }

            $success ||= $status;
        }
    }

    ## No command found
    unless ($cmd_found) {
        $log->syslog('info', "No command found in message");
        Sympa::Report::global_report_cmd('user', 'no_cmd_found', {});
        $log->db_log(
            'robot' => $robot,
            #'list'         => 'sympa',
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'no_cmd_found',
            'user_email'   => $sender
        );
        return undef;
    }

    return $success ? 1 : undef;
}

# Cleanup the msgid_table every 'msgid_table_cleanup_frequency' seconds.
# Removes all entries older than 'msgid_table_cleanup_ttl' seconds.
# Old name: clean_msgid_table() in sympa_msg.pl.
sub _clean_msgid_table {
    my $self = shift;

    foreach my $rcpt (keys %{$self->{_msgid}}) {
        foreach my $msgid (keys %{$self->{_msgid}{$rcpt}}) {
            if (time > $self->{_msgid}{$rcpt}{$msgid} +
                $Conf::Conf{'msgid_table_cleanup_ttl'}) {
                delete $self->{_msgid}{$rcpt}{$msgid};
            }
        }
    }

    return 1;
}

1;
__END__

