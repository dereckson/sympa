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

Sympa::Bulk - FIXME

=head1 DESCRIPTION

FIXME

=cut

package Sympa::Bulk;

use strict;
use warnings;
use constant MAX => 100_000;

use Carp qw(croak);
use Digest::MD5;
use English qw(-no_match_vars);
use Scalar::Util qw(blessed);
use Sys::Hostname;

use Sympa::DatabaseManager;
use Sympa::Logger;
use Sympa::Monitor;
use Sympa::Spool::SQL;
use Sympa::Tools::Daemon;

## Database and SQL statement handlers
my $sth;

# last message stored in spool, this global var is used to prevent multiple
# stored of the same message in spool table
my $last_stored_message_key;

# create an empty Bulk
#sub new {
#    my $pkg = shift;
#    my $packet = Sympa::Bulk::next();;
#    bless \$packet, $pkg;
#    return $packet
#}
##
# get next packet to process, order is controled by priority_message, then by
# priority_packet, then by creation date.
# Packets marked as being sent with VERP will be treated last.
# Next lock the packetb to prevent multiple proccessing of a single packet

sub next {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '()');

    # lock next packet
    my $lock = Sympa::Tools::Daemon::get_lockname();

    my $order;
    my $limit_oracle = '';
    my $limit_sybase = '';
    ## Only the first record found is locked, thanks to the "LIMIT 1" clause
    $order =
        'ORDER BY priority_message_bulkpacket ASC, priority_packet_bulkpacket ASC, reception_date_bulkpacket ASC, verp_bulkpacket ASC';
    if (   Sympa::Site->db_type eq 'mysql'
        or Sympa::Site->db_type eq 'Pg'
        or Sympa::Site->db_type eq 'SQLite') {
        $order .= ' LIMIT 1';
    } elsif (Sympa::Site->db_type eq 'Oracle') {
        $limit_oracle = 'AND rownum<=1';
    } elsif (Sympa::Site->db_type eq 'Sybase') {
        $limit_sybase = 'TOP 1';
    }

    # Select the most prioritary packet to lock.
    unless (
        $sth = Sympa::DatabaseManager::do_prepared_query(
            sprintf(
                q{SELECT %s messagekey_bulkpacket AS messagekey,
		 packetid_bulkpacket AS packetid
	  FROM bulkpacket_table
	  WHERE lock_bulkpacket IS NULL AND delivery_date_bulkpacket <= ?
		%s %s},
                $limit_sybase, $limit_oracle, $order
            ),
            int(time())
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to get the most prioritary packet from database');
        return undef;
    }

    my $packet;
    unless ($packet = $sth->fetchrow_hashref('NAME_lc')) {
        $sth->finish;
        return undef;
    }
    $sth->finish;

    # Lock the packet previously selected.
    unless (
        $sth = Sympa::DatabaseManager::do_prepared_query(
            q{UPDATE bulkpacket_table
	  SET lock_bulkpacket = ?
	  WHERE messagekey_bulkpacket = ? AND packetid_bulkpacket = ? AND
		lock_bulkpacket IS NULL},
            $lock, $packet->{'messagekey'}, $packet->{'packetid'}
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to lock packet %s for message %s',
            $packet->{'packetid'}, $packet->{'messagekey'});
        return undef;
    }

    if ($sth->rows < 0) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to lock packet %s for message %s, though the query succeeded',
            $packet->{'packetid'},
            $packet->{'messagekey'}
        );
        return undef;
    }
    unless ($sth->rows) {
        $main::logger->do_log(Sympa::Logger::INFO, 'Bulk packet is already locked');
        return undef;
    }

    # select the packet that has been locked previously
    unless (
        $sth = Sympa::DatabaseManager::do_query(
            q{SELECT messagekey_bulkpacket AS messagekey,
		 messageid_bulkpacket AS messageid,
		 packetid_bulkpacket AS packetid,
		 recipients_bulkpacket AS recipients,
		 returnpath_bulkpacket AS returnpath,
		 listname_bulkpacket AS listname, robot_bulkpacket AS robot,
		 priority_message_bulkpacket AS priority_message,
		 priority_packet_bulkpacket AS priority_packet,
		 verp_bulkpacket AS verp, tracking_bulkpacket AS tracking,
		 merge_bulkpacket as merge,
		 reception_date_bulkpacket AS reception_date,
		 delivery_date_bulkpacket AS delivery_date
	  FROM bulkpacket_table
	  WHERE lock_bulkpacket=%s %s},
            Sympa::DatabaseManager::quote($lock), $order
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to retrieve informations for packet %s of message %s',
            $packet->{'packetid'}, $packet->{'messagekey'});
        return undef;
    }

    my $result = $sth->fetchrow_hashref('NAME_lc');

    ## add objects
    my $robot_id = $result->{'robot'};
    my $listname = $result->{'listname'};
    my $robot;

    if ($robot_id and $robot_id ne '*') {
        require Sympa::VirtualHost;
        $robot = Sympa::VirtualHost->new($robot_id);
    }
    if ($robot) {
        if ($listname and length $listname) {
            require Sympa::List;
            $result->{'list_object'} = Sympa::List->new($listname, $robot);
        }
        $result->{'robot_object'} = $robot;
    }

    return $result;
}

# remove a packet from database by packet id. return undef if packet does not
# exist

sub remove {
    my $messagekey = shift;
    my $packetid   = shift;

    $main::logger->do_log(Sympa::Logger::DEBUG, "Sympa::Bulk::remove(%s,%s)",
        $messagekey, $packetid);

    unless (
        $sth = Sympa::DatabaseManager::do_query(
            q{DELETE FROM bulkpacket_table
	  WHERE packetid_bulkpacket = %s AND messagekey_bulkpacket = %s},
            Sympa::DatabaseManager::quote($packetid),
            Sympa::DatabaseManager::quote($messagekey)
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to delete packet %s of message %s',
            $packetid, $messagekey);
        return undef;
    }
    return $sth;
}

sub store {
    my %data = @_;

    my $message  = $data{'message'};
    my $msg_id   = $message->get_header('Message-Id');
    my $rcpts    = $data{'rcpts'};
    my $from     = $data{'from'};
    my $robot    = $data{'robot'};
    my $listname = $data{'listname'};
    my $priority_message = $data{'priority_message'};
    my $priority_packet  = $data{'priority_packet'};
    my $delivery_date    = $data{'delivery_date'};
    my $verp             = $data{'verp'};
    my $tracking         = $data{'tracking'};

    croak "missing 'robot' parameter" unless $robot;
    croak "invalid 'robot' parameter" unless
        $robot eq '*' or
        (blessed $robot and $robot->isa('Sympa::VirtualHost'));

    $tracking = '' unless (($tracking eq 'dsn') || ($tracking eq 'mdn'));
    $verp = 0 unless ($verp);
    my $merge = $data{'merge'};
    $merge = 0 unless ($merge);
    my $dkim        = $data{'dkim'};
    my $tag_as_last = $data{'tag_as_last'};

    #$main::logger->do_log(Sympa::Logger::TRACE,
    #    'Sympa::Bulk::store(<msg>,rcpts: %s,from = %s,robot = %s,listname=
    #    %s,priority_message = %s, delivery_date= %s,verp = %s, tracking = %s,
    #    merge = %s, dkim: d= %s i=%s, last: %s)',
    #    $rcpts, $from, $robot, $listname, $priority_message, $delivery_date,
    #    $verp,$tracking, $merge, $dkim->{'d'}, $dkim->{'i'}, $tag_as_last);

    $priority_message = $robot->sympa_priority unless $priority_message;
    $priority_packet = $robot->sympa_packet_priority unless $priority_packet;

    my $messageasstring = $message->to_string;
    my $message_sender  =
        $message->get_sender_email(headers => Sympa::Site->sender_headers());

    # first store the message in spool_table
    # because as soon as packet are created bulk.pl may distribute the
    # $last_stored_message_key is a global var used in order to detect if a
    # message as been already stored
    my $message_already_on_spool;
    my $bulkspool = Sympa::Spool::SQL->new(name => 'bulk');

    if (    defined $last_stored_message_key
        and defined $message->{'messagekey'}
        and $message->{'messagekey'} eq $last_stored_message_key) {
        $message_already_on_spool = 1;
    } else {
        my $lock = $PID . '@' . hostname();
        if ($message->{'messagekey'}) {

            # move message to spool bulk and keep it locked
            $bulkspool->update(
                {'messagekey' => $message->{'messagekey'}},
                {   'messagelock' => $lock,
                    'spoolname'   => 'bulk',
                    'message'     => $messageasstring
                }
            );
        } else {
            $message->{'messagekey'} = $bulkspool->store(
                $messageasstring,
                {   'dkim_d'           => $dkim->{d},
                    'dkim_i'           => $dkim->{i},
                    'dkim_selector'    => $dkim->{selector},
                    'dkim_privatekey'  => $dkim->{private_key},
                    'dkim_header_list' => $dkim->{header_list}
                },
                $lock
            );
            unless ($message->{'messagekey'}) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Could not store message in spool distribute. Message lost?'
                );
                return undef;
            }
        }
        $last_stored_message_key = $message->{'messagekey'};

        #log in stat_table to make statistics...
        my $robot_domain = $robot->domain;
        unless (index($message_sender, "$robot_domain\@") >= 0) {

            #ignore messages sent by robot
            unless (index($message_sender, "$listname-request") >= 0) {

                #ignore messages of requests
                Sympa::Monitor::db_stat_log(
                    'robot'     => $robot->name,
                    'list'      => $listname,
                    'operation' => 'send_mail',
                    'parameter' => $message->get_size(),
                    'mail'      => $message_sender,
                    'daemon'    => 'sympa.pl'
                );
            }
        }
    }

    my $current_date = int(time);

    # second : create each recipient packet in bulkpacket_table
    my $type = ref $rcpts;

    unless (ref $rcpts) {
        my @tab = ($rcpts);
        my @tabtab;
        push @tabtab, \@tab;
        $rcpts = \@tabtab;
    }

    my $priority_for_packet;
    my $already_tagged = 0;

    # Initialize counter used to check whether we are copying the last packet.
    my $packet_rank = 0;
    foreach my $packet (@{$rcpts}) {
        $priority_for_packet = $priority_packet;
        if ($tag_as_last && !$already_tagged) {
            $priority_for_packet = $priority_packet + 5;
            $already_tagged      = 1;
        }
        $type = ref $packet;
        my $rcptasstring;
        if (ref $packet eq 'ARRAY') {
            $rcptasstring = join ',', @{$packet};
        } else {
            $rcptasstring = $packet;
        }
        my $packetid = Digest::MD5::md5_hex($rcptasstring);
        my $packet_already_exist;
        if (ref $listname eq 'Sympa::List') {
            $listname = $listname->name;
        }
        if ($message_already_on_spool) {
            ## search if this packet is already in spool database : mailfile
            ## may perform multiple submission of exactly the same message
            unless (
                $sth = Sympa::DatabaseManager::do_prepared_query(
                    q{SELECT count(*)
		  FROM bulkpacket_table
		  WHERE messagekey_bulkpacket = ? AND packetid_bulkpacket = ?},
                    $message->{'messagekey'}, $packetid
                )
                ) {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Unable to check presence of packet %s of message %s in database',
                    $packetid,
                    $message->{'messagekey'}
                );
                return undef;
            }
            $packet_already_exist = $sth->fetchrow;
            $sth->finish();
        }

        if ($packet_already_exist) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Duplicate message not stored in bulmailer_table');

        } else {
            unless (
                Sympa::DatabaseManager::do_prepared_query(
                    q{INSERT INTO bulkpacket_table
		  (messagekey_bulkpacket, messageid_bulkpacket,
		   packetid_bulkpacket,
		   recipients_bulkpacket, returnpath_bulkpacket,
		   robot_bulkpacket,
		   listname_bulkpacket,
		   verp_bulkpacket, tracking_bulkpacket, merge_bulkpacket,
		   priority_message_bulkpacket, priority_packet_bulkpacket,
		   reception_date_bulkpacket, delivery_date_bulkpacket)
		  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)},
                    $message->{'messagekey'}, $msg_id,
                    $packetid,
                    $rcptasstring, $from,
                    $robot->name,    ## '*' for Site
                    $listname,
                    $verp,             $tracking, $merge,
                    $priority_message, $priority_for_packet,
                    $current_date,     $delivery_date
                )
                ) {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Unable to add packet %s of message %s to database spool',
                    $packetid,
                    $msg_id
                );
                return undef;
            }
        }
        $packet_rank++;
    }
    $bulkspool->unlock_message($message->{'messagekey'});
    return 1;
}

## remove file that are not referenced by any packet
sub purge_bulkspool {
    $main::logger->do_log(Sympa::Logger::DEBUG, 'purge_bulkspool');

    unless (
        $sth = Sympa::DatabaseManager::do_prepared_query(
            q{SELECT messagekey_spool AS messagekey
	  FROM spool_table LEFT JOIN bulkpacket_table
	  ON messagekey_spool = messagekey_bulkpacket
	  WHERE messagekey_bulkpacket IS NULL AND messagelock_spool IS NULL AND
		spoolname_spool = ?},
            'bulk'
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to check messages unreferenced by packets in database');
        return undef;
    }

    my $count = 0;
    while (my $key = $sth->fetchrow_hashref('NAME_lc')) {
        if (remove_bulkspool_message('spool', $key->{'messagekey'})) {
            $count++;
        } else {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unable to remove message (key = %s) from spool_table',
                $key->{'messagekey'});
        }
    }
    $sth->finish;
    return $count;
}

sub remove_bulkspool_message {
    my $spool      = shift;
    my $messagekey = shift;

    my $table = $spool . '_table';
    my $key   = 'messagekey_' . $spool;

    unless (
        Sympa::DatabaseManager::do_query(
            "DELETE FROM %s WHERE %s = %s",
            $table, $key, Sympa::DatabaseManager::quote($messagekey)
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Unable to delete %s %s from %s',
            $table, $key, $messagekey);
        return undef;
    }

    return 1;
}
## Return the number of remaining packets in the bulkpacket table.
sub get_remaining_packets_count {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '()');

    unless (
        $sth = Sympa::DatabaseManager::do_prepared_query(
            q{SELECT COUNT(*)
	  FROM bulkpacket_table
	  WHERE lock_bulkpacket IS NULL}
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to count remaining packets in bulkpacket_table');
        return undef;
    }

    my @result = $sth->fetchrow_array();

    return $result[0];
}

1;
