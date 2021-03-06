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

Sympa::Tracking - FIXME

=head1 DESCRIPTION

FIXME

=cut

package Sympa::Tracking;

use strict;

use MIME::Base64;

use Sympa::Logger;
use Sympa::DatabaseManager;

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
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $list     = shift;
    my $msgid    = shift;
    my $listname = $list->name;
    my $robot_id = $list->domain;

    my $sth;

    # the message->head method return message-id including <blabla@dom>
    # where mhonarc return blabla@dom that's why we test both of them
    unless (
        $sth = Sympa::DatabaseManager::do_query(
            q{SELECT recipient_notification AS recipient,
	  reception_option_notification AS reception_option,
	  status_notification AS status,
	  arrival_date_notification AS arrival_date,
	  type_notification as type,
	  message_notification as notification_message
	 FROM notification_table
	 WHERE list_notification = %s AND robot_notification = %s AND
	       (message_id_notification = %s OR
		CONCAT('<',message_id_notification,'>') = %s OR
		message_id_notification = %s)},
            Sympa::DatabaseManager::quote($listname), Sympa::DatabaseManager::quote($robot_id),
            Sympa::DatabaseManager::quote($msgid),    Sympa::DatabaseManager::quote($msgid),
            Sympa::DatabaseManager::quote('<' . $msgid . '>')
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to retrieve tracking informations for message %s, list %s',
            $msgid,
            $list
        );
        return undef;
    }

    my @pk_notifs;
    while (my $pk_notif = $sth->fetchrow_hashref) {
        if ($pk_notif->{'notification_message'}) {
            $pk_notif->{'notification_message'} =
                MIME::Base64::decode($pk_notif->{'notification_message'});
        } else {
            $pk_notif->{'notification_message'} = '';
        }
        push @pk_notifs, $pk_notif;
    }
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
    my $list   = shift;
    my %params = @_;

    my $msgid = $params{'msgid'};
    chomp $msgid;
    my $listname         = $list->name;
    my $robot_id         = $list->domain;
    my $reception_option = $params{'reception_option'};
    my @rcpt             = @{$params{'rcpt'}};

    $main::logger->do_log(Sympa::Logger::DEBUG2,
        '(%s, msgid=%s, reception_option=%s)',
        $list, $msgid, $reception_option);

    my $time = time;

    foreach my $email (@rcpt) {
        my $email = lc($email);

        unless (
            Sympa::DatabaseManager::do_prepared_query(
                q{INSERT INTO notification_table
	      (message_id_notification, recipient_notification,
	       reception_option_notification,
	       list_notification, robot_notification, date_notification)
	      VALUES (?, ?, ?, ?, ?, ?)},
                $msgid,    $email,    $reception_option,
                $listname, $robot_id, $time
            )
            ) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Unable to prepare notification table for user %s, message %s, list %s',
                $email,
                $msgid,
                $list
            );
            return undef;
        }
    }
    return 1;
}

##############################################
#   db_insert_notification
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
#     -$msg_id (+): the report message-id
#     -$status (+): the new state of the recipient entry depending of the
#     report data
#     -$arrival_date (+): the mail arrival date.
#     -$notification_as_string : the DSN or the MDM as string
#
# OUT : 1 | undef
#
##############################################
sub db_insert_notification {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s, %s, ...)', @_);
    my ($notification_id, undef, $status, $arrival_date,
        $notification_as_string)
        = @_;
    chomp $arrival_date;

    $notification_as_string = MIME::Base64::encode($notification_as_string);

    unless (
        Sympa::DatabaseManager::do_prepared_query(
            q{UPDATE notification_table
	  SET status_notification = ?, arrival_date_notification = ?,
	      message_notification = ?
	  WHERE pk_notification = ?},
            $status, $arrival_date, $notification_as_string, $notification_id
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to update notification %s in database',
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
    my $recipient = shift;
    my $msgid     = shift;
    chomp $msgid;
    my $listname = shift;
    my $robot_id = shift;

    $main::logger->do_log(Sympa::Logger::DEBUG2,
        'find_notification_id_by_message(%s,%s,%s,%s)',
        $recipient, $msgid, $listname, $robot_id);

    my $sth;

    # the message->head method return message-id including <blabla@dom> where
    # mhonarc return blabla@dom that's why we test both of them
    unless (
        $sth = Sympa::DatabaseManager::do_query(
            "SELECT pk_notification FROM notification_table WHERE ( recipient_notification = %s AND list_notification = %s AND robot_notification = %s AND (message_id_notification = %s OR CONCAT('<',message_id_notification,'>') = %s OR message_id_notification = %s ))",
            Sympa::DatabaseManager::quote($recipient),
            Sympa::DatabaseManager::quote($listname),
            Sympa::DatabaseManager::quote($robot_id),
            Sympa::DatabaseManager::quote($msgid),
            Sympa::DatabaseManager::quote($msgid),
            Sympa::DatabaseManager::quote('<' . $msgid . '>')
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to retrieve the tracking informations for user %s, message %s, list %s@%s',
            $recipient,
            $msgid,
            $listname,
            $robot_id
        );
        return undef;
    }

    my @pk_notifications = $sth->fetchrow_array;
    if ($#pk_notifications > 0) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Found more then one pk_notification maching  (recipient=%s,msgis=%s,listname=%s,robot%s)',
            $recipient,
            $msgid,
            $listname,
            $robot_id
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
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $list  = shift;
    my $msgid = shift;

    my $listname = $list->name;
    my $robot_id = $list->domain;

    my $sth;
    unless (
        $sth = Sympa::DatabaseManager::do_prepared_query(
            q{DELETE FROM notification_table
	  WHERE message_id_notification = ? AND
	  list_notification = ? AND robot_notification = ?},
            $msgid, $listname, $robot_id
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to remove the tracking informations for message %s, list %s',
            $msgid,
            $listname,
            $robot_id
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
# IN : $list : ref(List)
#    : $period
#
# OUT : $sth | undef
#
##############################################
sub remove_message_by_period {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $list   = shift;
    my $period = shift;

    my $listname = $list->name;
    my $robot_id = $list->domain;

    my $sth;

    my $limit = time - ($period * 24 * 60 * 60);

    unless (
        $sth = Sympa::DatabaseManager::do_prepared_query(
            q{DELETE FROM notification_table
	  WHERE "date_notification" < ? AND
	  list_notification = ? AND robot_notification = ?},
            $limit, $listname, $robot_id
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to remove the tracking informations older than %s days for list %s',
            $limit,
            $list
        );
        return undef;
    }

    my $deleted = $sth->rows;
    return $deleted;
}

1;
