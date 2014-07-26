# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

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

package tracking;

use strict;
use warnings;
use MIME::Base64 qw();

use Log;
use SDM;

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
    my $msgid    = shift;
    my $listname = shift;
    my $robot    = shift;

    Log::do_log('debug2', '(%s, %s, %s)', $msgid, $listname, $robot);

    my $sth;
    my $pk;

    # the message->head method return message-id including <blabla@dom> where
    # mhonarc return blabla@dom that's why we test both of them
    unless (
        $sth = SDM::do_query(
            "SELECT recipient_notification AS recipient,  reception_option_notification AS reception_option, status_notification AS status, arrival_date_notification AS arrival_date, type_notification as type, message_notification as notification_message FROM notification_table WHERE (list_notification = %s AND robot_notification = %s AND (message_id_notification = %s OR CONCAT('<',message_id_notification,'>') = %s OR message_id_notification = %s ))",
            SDM::quote($listname),
            SDM::quote($robot),
            SDM::quote($msgid),
            SDM::quote($msgid),
            SDM::quote('<' . $msgid . '>')
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
            SDM::do_query(
                "INSERT INTO notification_table (message_id_notification,recipient_notification,reception_option_notification,list_notification,robot_notification,date_notification) VALUES (%s,%s,%s,%s,%s,%s)",
                SDM::quote($msgid),
                SDM::quote($email),
                SDM::quote($reception_option),
                SDM::quote($listname),
                SDM::quote($robot),
                $time
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
    my ($notification_id, $type, $status, $arrival_date,
        $notification_as_string)
        = @_;

    Log::do_log(
        'debug2',
        'Notification_id: %s, type: %s, recipient: %s, msgid: %s, status: %s',
        $notification_id,
        $type,
        $status
    );

    chomp $arrival_date;

    $notification_as_string = MIME::Base64::encode($notification_as_string);

    unless (
        SDM::do_prepared_query(
            q{UPDATE notification_table
              SET status_notification = ?, arrival_date_notification = ?,
                  message_notification = ?
              WHERE pk_notification = ?},
            $status, $arrival_date,
            $notification_as_string,
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
# tracking_id areinitialized by sympa.pl by List::distribute_msg
#
# used by bulk.pl in order to set return_path when tracking is required.
#
##############################################

sub find_notification_id_by_message {
    my $recipient = shift;
    my $msgid     = shift;
    chomp $msgid;
    my $listname = shift;
    my $robot    = shift;

    Log::do_log('debug2', '(%s, %s, %s, %s)',
        $recipient, $msgid, $listname, $robot);
    my $pk;

    my $sth;

    # the message->head method return message-id including <blabla@dom> where
    # mhonarc return blabla@dom that's why we test both of them
    unless (
        $sth = SDM::do_query(
            "SELECT pk_notification FROM notification_table WHERE ( recipient_notification = %s AND list_notification = %s AND robot_notification = %s AND (message_id_notification = %s OR CONCAT('<',message_id_notification,'>') = %s OR message_id_notification = %s ))",
            SDM::quote($recipient),
            SDM::quote($listname),
            SDM::quote($robot),
            SDM::quote($msgid),
            SDM::quote($msgid),
            SDM::quote('<' . $msgid . '>')
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
    if ($#pk_notifications > 0) {
        Log::do_log(
            'err',
            'Found more then one pk_notification maching (recipient=%s, msgis=%s, listname=%s, robot%s)',
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
    my $msgid    = shift;
    my $listname = shift;
    my $robot    = shift;

    Log::do_log('debug2', 'Remove message id = %s, listname = %s, robot = %s',
        $msgid, $listname, $robot);
    my $sth;
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
    my $period   = shift;
    my $listname = shift;
    my $robot    = shift;

    my $sth;

    my $limit = time - ($period * 24 * 60 * 60);

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
