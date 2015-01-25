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

package Sympa::Tracking;

use strict;
use warnings;
use DateTime::Format::Mail;
use English qw(-no_match_vars);

use Sympa::Constants;
use Log;
use SDM;
use tools;
use Sympa::Tools::File;

sub new {
    my $class = shift;
    my $list  = shift;

    die 'Bug in logic.  Ask developer'
        unless ref $list eq 'Sympa::List';

    my $self = bless {
        directory => $list->get_bounce_dir,
        context   => $list,
    } => $class;

    $self->_create_spool;

    return $self;
}

sub _create_spool {
    my $self = shift;

    my $umask = umask oct $Conf::Conf{'umask'};
    foreach my $directory (($self->{directory})) {
        unless (-d $directory) {
            Log::do_log('info', 'Creating spool %s', $directory);
            unless (
                mkdir($directory, 0755)
                and Sympa::Tools::File::set_file_rights(
                    file  => $directory,
                    user  => Sympa::Constants::USER(),
                    group => Sympa::Constants::GROUP()
                )
                ) {
                die sprintf 'Cannot create %s: %s', $directory, $ERRNO;
            }
        }
    }
    umask $umask;
}

##############################################
#   get_recipients_status
##############################################
# Function use to get mail addresses and status of
# the recipients who have a different DSN status than "delivered"
# Use the pk identifiant of the mail
#
#     -$pk_mail (+): the identifiant of the stored mail
#
# OUT : @pk_notifs |undef
#
##############################################
sub get_recipients_status {
    Log::do_log('debug2', '(%s, %s, %s)', @_);
    my $msgid    = shift;
    my $listname = shift;
    my $robot    = shift;

    $msgid = tools::clean_msg_id($msgid);

    my $sth;
    my $pk;

    # the message->head method return message-id including <blabla@dom> where
    # mhonarc return blabla@dom that's why we test both of them
    unless (
        $sth = SDM::do_prepared_query(
            q{SELECT recipient_notification AS recipient,
                     reception_option_notification AS reception_option,
                     status_notification AS status,
                     arrival_date_notification AS arrival_date,
                     arrival_date_epoch_notification AS arrival_date_epoch,
                     type_notification AS "type",
                     pk_notification AS envid
              FROM notification_table
              WHERE list_notification = ? AND robot_notification = ? AND
                    (message_id_notification = ? OR
                     message_id_notification = ?)},
            $listname, $robot,
            $msgid,
            '<' . $msgid . '>'
        )
        ) {
        Log::do_log(
            'err',
            'Unable to retrieve tracking informations for message %s, list %s@%s',
            $msgid,
            $listname,
            $robot
        );
        return undef;
    }
    my @pk_notifs;
    while (my $pk_notif = $sth->fetchrow_hashref) {
        push @pk_notifs, $pk_notif;
    }
    $sth->finish;

    return \@pk_notifs;
}

##############################################
#   db_init_notification_table
##############################################
# Function used to initialyse notification table for each subscriber
# IN :
#   listname
#   robot,
#   msgid  : the messageid of the original message
#   rcpt : a tab ref of recipients
#   reception_option : teh reception option of thoses subscribers
# OUT : 1 | undef
#
##############################################
sub db_init_notification_table {

    my %params = @_;
    my $msgid  = $params{'msgid'};
    chomp $msgid;
    my $listname         = $params{'listname'};
    my $robot            = $params{'robot'};
    my $reception_option = $params{'reception_option'};
    my @rcpt             = @{$params{'rcpt'}};

    Log::do_log('debug2', '(msgid = %s, listname = %s, reception_option = %s',
        $msgid, $listname, $reception_option);

    my $time = time;

    foreach my $email (@rcpt) {
        my $email = lc($email);

        unless (
            SDM::do_prepared_query(
                q{INSERT INTO notification_table
                  (message_id_notification, recipient_notification,
                   reception_option_notification,
                   list_notification, robot_notification, date_notification)
                  VALUES (?, ?, ?, ?, ?, ?)},
                $msgid, $email, $reception_option, $listname, $robot, $time
            )
            ) {
            Log::do_log(
                'err',
                'Unable to prepare notification table for user %s, message %s, list %s@%s',
                $email,
                $msgid,
                $listname,
                $robot
            );
            return undef;
        }
    }
    return 1;
}

# copy the bounce to the appropriate filename
# Old name: store_bounce() in bounced.pl
sub store {
    Log::do_log('debug2', '(%s, %s, %s, %s, ...)', @_);
    my $self     = shift;
    my $filepath = shift;
    my $rcpt     = shift;
    my %options  = @_;

    my $bounce_dir = $self->{directory};

    # Store bounce
    my ($ifh, $ofh);
    unless (open $ifh, '<', $filepath) {
        Log::do_log('err', 'Could not open %s: %m', $filepath);
        return undef;
    }
    my $msg_string = do { local $RS; <$ifh> };
    close $ifh;

    my $filename;
    unless (defined $options{envid} and length $options{envid}) {
        $filename = tools::escape_chars($rcpt);
    } else {
        $filename = sprintf '%s_%08s', tools::escape_chars($rcpt),
            $options{envid};
    }
    unless (open $ofh, '>', $bounce_dir . '/' . $filename) {
        Log::do_log('err', 'Unable to write %s/%s', $bounce_dir, $filename);
        return undef;
    }
    print $ofh $msg_string;
    close $ofh;
    close $ifh;

    if (defined $options{envid} and length $options{envid}) {
        unless (
            _db_insert_notification(
                $options{envid},  $options{type},
                $options{status}, $options{arrival_date}
            )
            ) {
            return undef;
        }
    }

    return 1;
}

##############################################
#   _db_insert_notification
##############################################
# Function used to add a notification entry
# corresponding to a new report. This function
# is called when a report has been received.
# It build a new connection with the database
# using the default database parameter. Then it
# search the notification entry identifiant which
# correspond to the received report. Finally it
# update the recipient entry concerned by the report.
#
# IN :-$id (+): the identifiant entry of the initial mail
#     -$type (+): the notification entry type (DSN|MDN)
#     -$recipient (+): the list subscriber who correspond to this entry
#     -$status (+): the new state of the recipient entry depending of the
#     report data
#     -$arrival_date (+): the mail arrival date.
#
# OUT : 1 | undef
#
##############################################
sub _db_insert_notification {
    my ($notification_id, $type, $status, $arrival_date) = @_;

    Log::do_log('debug2',
        'Notification_id: %s, type: %s, recipient: %s, status: %s',
        $notification_id, $type, $status);

    chomp $arrival_date;
    my $arrival_date_epoch = eval {
        DateTime::Format::Mail->new->loose->parse_datetime($arrival_date)
            ->epoch;
    };

    unless (
        SDM::do_prepared_query(
            q{UPDATE notification_table
              SET status_notification = ?, type_notification = ?,
                  arrival_date_notification = ?,
                  arrival_date_epoch_notification = ?
              WHERE pk_notification = ?},
            $status, $type,
            $arrival_date,
            $arrival_date_epoch,
            $notification_id
        )
        ) {
        Log::do_log('err', 'Unable to update notification %s in database',
            $notification_id);
        return undef;
    }

    return 1;
}

##############################################
#   find_notification_id_by_message
##############################################
# return the tracking_id find by recipeint,message-id,listname and robot
# tracking_id areinitialized by sympa.pl by Sympa::List::distribute_msg
#
# used by bulk.pl in order to set return_path when tracking is required.
#
##############################################

sub find_notification_id_by_message {
    Log::do_log('debug2', '(%s, %s, %s, %s)', @_);
    my $recipient = shift;
    my $msgid     = shift;
    my $listname  = shift;
    my $robot     = shift;

    $msgid = tools::clean_msg_id($msgid);

    my $pk;

    my $sth;

    # the message->head method return message-id including <blabla@dom> where
    # mhonarc return blabla@dom that's why we test both of them
    unless (
        $sth = SDM::do_prepared_query(
            q{SELECT pk_notification
              FROM notification_table
              WHERE recipient_notification = ? AND
                    list_notification = ? AND robot_notification = ? AND
                    (message_id_notification = ? OR
                     message_id_notification = ?)},
            $recipient,
            $listname, $robot,
            $msgid,
            '<' . $msgid . '>'
        )
        ) {
        Log::do_log(
            'err',
            'Unable to retrieve the tracking informations for user %s, message %s, list %s@%s',
            $recipient,
            $msgid,
            $listname,
            $robot
        );
        return undef;
    }

    my @pk_notifications = $sth->fetchrow_array;
    $sth->finish;

    if (scalar @pk_notifications > 1) {
        Log::do_log(
            'err',
            'Found more then one envelope ID maching (recipient=%s, msgis=%s, listname=%s, robot%s)',
            $recipient,
            $msgid,
            $listname,
            $robot
        );
        # we should return undef...
    }
    return $pk_notifications[0];
}

##############################################
#   remove_message_by_id
##############################################
# Function use to remove notifications
#
# IN : $msgid : id of related message
#    : $listname
#    : $robot
#
# OUT : $sth | undef
#
##############################################
sub remove_message_by_id {
    Log::do_log('debug2', '(%s, %s, %s)', @_);
    my $self  = shift;
    my $msgid = shift;

    my $listname = $self->{context}->{'name'};
    my $robot    = $self->{context}->{'domain'};

    my $sth;

    # Remove messages in bounce directory.
    unless (
        $sth = SDM::do_prepared_query(
            q{SELECT recipient_notification AS recipient,
                     pk_notification AS envid
              FROM notification_table
              WHERE message_id_notification = ? AND
                    list_notification = ? AND robot_notification = ?},
            $msgid,
            $listname, $robot
        )
        ) {
        Log::do_log(
            'err',
            'Unable to search tracking information for message %s, list %s@%s',
            $msgid,
            $listname,
            $robot
        );
        return undef;
    }
    while (my $info = $sth->fetchrow_hashref('NAME_lc')) {
        my $bounce_dir    = $self->{directory};
        my $escaped_email = tools::escape_chars($info->{'recipient'});
        my $envid         = $info->{'envid'};
        unlink sprintf('%s/%s_%08s', $bounce_dir, $escaped_email, $envid);
    }
    $sth->finish;

    # Remove row in notification table.
    unless (
        $sth = SDM::do_prepared_query(
            q{DELETE FROM notification_table
              WHERE message_id_notification = ? AND
                    list_notification = ? AND robot_notification = ?},
            $msgid,
            $listname, $robot
        )
        ) {
        Log::do_log(
            'err',
            'Unable to remove the tracking informations for message %s, list %s@%s',
            $msgid,
            $listname,
            $robot
        );
        return undef;
    }

    return 1;
}

##############################################
#   remove_message_by_period
##############################################
# Function use to remove notifications older than number of days
#
# IN : $period
#    : $listname
#    : $robot
#
# OUT : $sth | undef
#
##############################################
sub remove_message_by_period {
    Log::do_log('debug2', '(%s, %s, %s)', @_);
    my $self   = shift;
    my $period = shift;

    my $listname = $self->{context}->{'name'};
    my $robot    = $self->{context}->{'domain'};

    my $sth;

    my $limit = time - ($period * 24 * 60 * 60);

    # Remove messages in bounce directory.
    unless (
        $sth = SDM::do_prepared_query(
            q{SELECT recipient_notification AS recipient,
                     pk_notification AS envid
              FROM notification_table
              WHERE date_notification < ? AND
                    list_notification = ? AND robot_notification = ?},
            $limit,
            $listname, $robot
        )
        ) {
        Log::do_log(
            'err',
            'Unable to search tracking information for older than %s days for list %s@%s',
            $limit,
            $listname,
            $robot
        );
        return undef;
    }
    while (my $info = $sth->fetchrow_hashref('NAME_lc')) {
        my $bounce_dir    = $self->{directory};
        my $escaped_email = tools::escape_chars($info->{'recipient'});
        my $envid         = $info->{'envid'};
        unlink sprintf('%s/%s_%08s', $bounce_dir, $escaped_email, $envid);
    }
    $sth->finish;

    # Remove rows in notification table.
    unless (
        $sth = SDM::do_prepared_query(
            q{DELETE FROM notification_table
              WHERE date_notification < ? AND
              list_notification = ? AND robot_notification = ?},
            $limit,
            $listname, $robot
        )
        ) {
        Log::do_log(
            'err',
            'Unable to remove the tracking informations older than %s days for list %s@%s',
            $limit,
            $listname,
            $robot
        );
        return undef;
    }

    my $deleted = $sth->rows;
    return $deleted;
}

1;
