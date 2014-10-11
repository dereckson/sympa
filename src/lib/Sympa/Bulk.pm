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

package Sympa::Bulk;

use strict;
use warnings;
use Digest::MD5;
use MIME::Base64 qw();
use Term::ProgressBar;
use Time::HiRes qw();
#use constant MAX => 100_000;

use Conf;
use Log;
use SDM;
use Sympa::Tools::Daemon;

## Database and SQL statement handlers
my $sth;

# fingerprint of last message stored in bulkspool
my $message_fingerprint;

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
    Log::do_log('debug', '');

    # lock next packet
    my $lock = Sympa::Tools::Daemon::get_lockname();

    # Select the most prioritary packet to lock.
    # As rows not assigned tag should be upgraded, they are skipped.
    unless (
        $sth = SDM::do_prepared_query(
            q{SELECT messagekey_bulkmailer AS messagekey,
                     packetid_bulkmailer AS packetid
              FROM bulkmailer_table
              WHERE lock_bulkmailer IS NULL AND
                    delivery_date_bulkmailer <= ? AND
                    tag_bulkmailer IS NOT NULL
              ORDER BY priority_message_bulkmailer ASC,
                       priority_packet_bulkmailer ASC,
                       delivery_date_bulkmailer ASC,
                       reception_date_bulkmailer ASC,
                       tag_bulkmailer ASC},
            time
        )
        ) {
        Log::do_log('err',
            'Unable to get the most prioritary packet from database');
        return undef;
    }

    # Only the first record found is locked.
    my $packet = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish;
    unless ($packet) {
        return undef;
    }

    # Lock the packet previously selected.
    unless (
        $sth = SDM::do_prepared_query(
            q{UPDATE bulkmailer_table
              SET lock_bulkmailer = ?
              WHERE messagekey_bulkmailer = ? AND packetid_bulkmailer = ? AND
                    lock_bulkmailer IS NULL},
            $lock,
            $packet->{'messagekey'},
            $packet->{'packetid'}
        )
        ) {
        Log::do_log('err', 'Unable to lock packet %s for message %s',
            $packet->{'packetid'}, $packet->{'messagekey'});
        return undef;
    }

    if ($sth->rows < 0) {
        Log::do_log(
            'err',
            'Unable to lock packet %s for message %s, though the query succeeded',
            $packet->{'packetid'},
            $packet->{'messagekey'}
        );
        return undef;
    }
    unless ($sth->rows) {
        Log::do_log('info', 'Bulk packet is already locked');
        return undef;
    }

    # select the packet that has been locked previously
    #FIXME: A column name is recEipients_bulkmailer.
    $sth = SDM::do_prepared_query(
        q{SELECT messagekey_bulkmailer AS messagekey,
                 packetid_bulkmailer AS packetid,
                 receipients_bulkmailer AS recipients,
                 listname_bulkmailer AS listname,
                 robot_bulkmailer AS robot,
                 priority_message_bulkmailer AS "priority",
                 priority_packet_bulkmailer AS priority_packet,
                 reception_date_bulkmailer AS reception_date,
                 delivery_date_bulkmailer AS "date",
                 tag_bulkmailer AS "tag"
          FROM bulkmailer_table
          WHERE lock_bulkmailer = ? AND tag_bulkmailer IS NOT NULL
          ORDER BY priority_message_bulkmailer ASC,
                   priority_packet_bulkmailer ASC,
                   delivery_date_bulkmailer ASC,
                   reception_date_bulkmailer ASC,
                   tag_bulkmailer ASC},
        $lock
    );
    unless ($sth) {
        Log::do_log('err',
            'Unable to retrieve informations for packet %s of message %s',
            $packet->{'packetid'}, $packet->{'messagekey'});
        return undef;
    }

    my $result = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish;

    return $result;

}

# remove a packet from database by packet id. return undef if packet does not
# exist

sub remove {
    my $messagekey = shift;
    my $packetid   = shift;

    Log::do_log('debug', '(%s, %s)', $messagekey, $packetid);

    unless (
        $sth = SDM::do_query(
            "DELETE FROM bulkmailer_table WHERE packetid_bulkmailer = %s AND messagekey_bulkmailer = %s",
            SDM::quote($packetid),
            SDM::quote($messagekey)
        )
        ) {
        Log::do_log('err', 'Unable to delete packet %s of message %s',
            $packetid, $messagekey);
        return undef;
    }
    return $sth;
}

sub messageasstring {
    my $messagekey = shift;
    Log::do_log('debug', '(%s)', $messagekey);

    unless (
        $sth = SDM::do_query(
            "SELECT message_bulkspool AS message FROM bulkspool_table WHERE messagekey_bulkspool = %s",
            SDM::quote($messagekey)
        )
        ) {
        Log::do_log(
            'err',
            'Unable to retrieve message %s text representation from database',
            $messagekey
        );
        return undef;
    }

    my $messageasstring = $sth->fetchrow_hashref('NAME_lc');

    unless ($messageasstring) {
        Log::do_log('err', 'Could not fetch message %s from spool',
            $messagekey);
        return undef;
    }
    my $msg = MIME::Base64::decode($messageasstring->{'message'});
    unless ($msg) {
        Log::do_log('err',
            "could not decode message $messagekey extrated from spool (base64)"
        );
        return undef;
    }
    return $msg;
}

# fetch message from bulkspool_table by key
#
# Old name: Sympa::Bulk::message_from_spool()
sub fetch_content {
    Log::do_log('debug', '(%s)', @_);
    my $messagekey = shift;
    Log::do_log('debug', '(messagekey: %s)', $messagekey);

    unless (
        $sth = SDM::do_prepared_query(
            q{SELECT message_bulkspool
              FROM bulkspool_table
              WHERE messagekey_bulkspool = ?},
            $messagekey
        )
        ) {
        Log::do_log('err',
            'Unable to retrieve message %s full data from database',
            $messagekey);
        return undef;
    }

    my ($msg_string_encoded) = $sth->fetchrow_array;
    $sth->finish;

    return MIME::Base64::decode($msg_string_encoded);
}

# DEPRECATED: Use Sympa::Message::personalize().
# sub merge_msg;

# DEPRECATED: Use Sympa::Message::personalize_text().
# sub merge_data ($rcpt, $listname, $robot_id, $data, $body, \$message_output)

sub store {
    Log::do_log('debug2', '(%s, ...)', @_);
    my $message = shift;
    my $rcpt    = shift;
    my %data    = @_;

    my $tag = $data{'tag'};
    $tag = 's' unless defined $tag;

    my ($list, $robot_id);
    if (ref $message->{context} eq 'Sympa::List') {
        $list     = $message->{context};
        $robot_id = $list->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot_id = $message->{context};
    } else {
        $robot_id = '*';
    }

    my $priority_message = $message->{priority};
    $priority_message =
          $list
        ? $list->{admin}{priority}
        : Conf::get_robot_conf($robot_id, 'sympa_priority')
        unless defined $priority_message and length $priority_message;
    my $priority_packet =
        Conf::get_robot_conf($robot_id, 'sympa_packet_priority');
    my $delivery_date = $message->{date};
    $delivery_date = time() unless defined $delivery_date;

    ##-----------------------------##

    my $msg        = MIME::Base64::encode($message->to_string);
    my $messagekey = Digest::MD5::md5_hex($msg);

    # first store the message in bulk_spool_table
    # because as soon as packet are created bulk.pl may distribute them
    # Compare the current message finger print to the fingerprint
    # of the last call to store() ($message_fingerprint is a global var)
    # If fingerprint is the same, then the message should not be stored
    # again in bulkspool_table

    my $message_already_on_spool;

    if (    defined $message_fingerprint
        and defined $messagekey
        and $messagekey eq $message_fingerprint) {
        $message_already_on_spool = 1;

    } else {
        ## search if this message is already in spool database : mailfile may
        ## perform multiple submission of exactly the same message
        unless (
            $sth = SDM::do_query(
                "SELECT count(*) FROM bulkspool_table WHERE ( messagekey_bulkspool = %s )",
                SDM::quote($messagekey)
            )
            ) {
            Log::do_log('err',
                'Unable to check whether message %s is in spool already',
                $messagekey);
            return undef;
        }

        $message_already_on_spool = $sth->fetchrow;
        $sth->finish();

        # if message is not found in bulkspool_table store it
        if ($message_already_on_spool == 0) {
            unless (
                SDM::do_prepared_query(
                    q{INSERT INTO bulkspool_table
                      (messagekey_bulkspool, message_bulkspool, lock_bulkspool)
                      VALUES (?, ?, 1)},
                    $messagekey, $msg
                )
                ) {
                Log::do_log('err',
                    'Unable to add message <%s> in bulkspool_table',
                    $messagekey,);
                return undef;
            }

            #log in stat_table to make statistics...
            my $robot_domain =
                ($robot_id and $robot_id ne '*')
                ? $robot_id
                : $Conf::Conf{'domain'};

            # Ignore messages sent by robot or -request
            # FIMXE: Is it effective?
            unless (not $list
                and $message->{sender} eq
                Conf::get_robot_conf($robot_id, 'sympa')
                or $list
                and $message->{sender} eq $list->get_list_address('owner')) {
                Log::db_stat_log(
                    {   'robot'     => $robot_id,
                        'list'      => ($list ? $list->{'name'} : undef),
                        'operation' => 'send_mail',
                        'parameter' => $message->{size},
                        'mail'      => $message->{sender},
                        'client'    => '',
                        'daemon'    => 'sympa.pl'
                    }
                );
            }
            $message_fingerprint = $messagekey;
        }
    }

    my $current_date = Time::HiRes::time();

    # second : create each recipient packet in bulkmailer_table
    my @rcpts;
    unless (ref $rcpt) {
        @rcpts = ([$rcpt]);
    } else {
        @rcpts = get_recipient_tabs_by_domain($list, @{$rcpt || []});
    }

    # Initialize counter used to check wether we are copying the last packet.
    my $packet_rank = 0;
    foreach my $packet (@rcpts) {
        my $rcptasstring;
        if (ref $packet eq 'ARRAY') {
            $rcptasstring = join ',', @{$packet};
        } else {
            $rcptasstring = $packet;
        }
        my $packetid = Digest::MD5::md5_hex($rcptasstring);
        my $packet_already_exist;
        if ($message_already_on_spool) {
            ## search if this packet is already in spool database : mailfile
            ## may perform multiple submission of exactly the same message
            unless (
                $sth = SDM::do_query(
                    "SELECT count(*) FROM bulkmailer_table WHERE ( messagekey_bulkmailer = %s AND  packetid_bulkmailer = %s)",
                    SDM::quote($messagekey),
                    SDM::quote($packetid)
                )
                ) {
                Log::do_log(
                    'err',
                    'Unable to check presence of packet %s of message %s in database',
                    $packetid,
                    $messagekey
                );
                return undef;
            }
            $packet_already_exist = $sth->fetchrow;
            $sth->finish();
        }

        if ($packet_already_exist) {
            Log::do_log('err',
                'Duplicate message not stored in bulmailer_table');

        } else {
            unless (
                SDM::do_prepared_query(
                    q{INSERT INTO bulkmailer_table
                      (messagekey_bulkmailer,
                       packetid_bulkmailer, receipients_bulkmailer,
                       robot_bulkmailer, listname_bulkmailer,
                       priority_message_bulkmailer,
                       priority_packet_bulkmailer,
                       reception_date_bulkmailer, delivery_date_bulkmailer,
                       tag_bulkmailer)
                      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)},
                    $messagekey,
                    $packetid, $rcptasstring,
                    $robot_id, $list->{'name'},
                    $priority_message,
                    $priority_packet,
                    SDM::AS_DOUBLE($current_date), $delivery_date,
                    $tag
                )
                ) {
                Log::do_log(
                    'err',
                    'Unable to add packet %s of message %s to database spool',
                    $packetid,
                    $message
                );
                return undef;
            }
        }
        $packet_rank++;

        $tag = '0';
    }
    # last : unlock message in bulkspool_table so it is now possible to remove
    # this message if no packet has a ref on it
    unless (
        SDM::do_query(
            "UPDATE bulkspool_table SET lock_bulkspool='0' WHERE messagekey_bulkspool = %s",
            SDM::quote($messagekey)
        )
        ) {
        Log::do_log('err', 'Unable to unlock packet %s in bulkmailer_table',
            $messagekey);
        return undef;
    }
    return $messagekey;
}

# Old name: (part of) Sympa::Mail::mail_message().
sub get_recipient_tabs_by_domain {
    my $list = shift;
    my @rcpt = @_;

    return unless @rcpt;

    my $robot_id = $list->{'domain'};

    my ($i, $j, $nrcpt);
    my $size = 0;

    my %rcpt_by_dom;

    my @sendto;
    my @sendtobypacket;

    #my $db_type = $Conf::Conf{'db_type'};

    while (defined($i = shift @rcpt)) {
        my @k = reverse split /[\.@]/, $i;
        my @l = reverse split /[\.@]/, (defined $j ? $j : '@');

        my $dom;
        if ($i =~ /\@(.*)$/) {
            $dom = $1;
            chomp $dom;
        }
        $rcpt_by_dom{$dom} += 1;
        Log::do_log(
            'debug2',
            'Domain: %s; rcpt by dom: %s; limit for this domain: %s',
            $dom,
            $rcpt_by_dom{$dom},
            $Conf::Conf{'nrcpt_by_domain'}{$dom}
        );

        if (
            # number of recipients by each domain
            (   defined $Conf::Conf{'nrcpt_by_domain'}{$dom}
                and $rcpt_by_dom{$dom} >= $Conf::Conf{'nrcpt_by_domain'}{$dom}
            )
            or
            # number of different domains
            (       $j
                and scalar(@sendto) > Conf::get_robot_conf($robot_id, 'avg')
                and lc "$k[0] $k[1]" ne lc "$l[0] $l[1]"
            )
            or
            # number of recipients in general
            (@sendto and $nrcpt >= Conf::get_robot_conf($robot_id, 'nrcpt'))
            #or
            ## length of recipients field stored into bulkmailer table
            ## (these limits might be relaxed by future release of Sympa)
            #($db_type eq 'mysql' and $size + length($i) + 5 > 65535)
            #or
            #($db_type !~ /^(mysql|SQLite)$/ and $size + length($i) + 5 > 500)
            ) {
            undef %rcpt_by_dom;
            # do not replace this line by "push @sendtobypacket, \@sendto" !!!
            my @tab = @sendto;
            push @sendtobypacket, \@tab;
            $nrcpt = $size = 0;
            @sendto = ();
        }

        $nrcpt++;
        $size += length($i) + 5;
        push(@sendto, $i);
        $j = $i;
    }

    if (@sendto) {
        my @tab = @sendto;
        # do not replace this line by push @sendtobypacket, \@sendto !!!
        push @sendtobypacket, \@tab;
    }

    return @sendtobypacket;
}

## remove file that are not referenced by any packet
sub purge_bulkspool {
    Log::do_log('debug', '');

    unless (
        $sth = SDM::do_query(
            "SELECT messagekey_bulkspool AS messagekey FROM bulkspool_table LEFT JOIN bulkmailer_table ON messagekey_bulkspool = messagekey_bulkmailer WHERE messagekey_bulkmailer IS NULL AND lock_bulkspool = 0"
        )
        ) {
        Log::do_log('err',
            'Unable to check messages unreferenced by packets in database');
        return undef;
    }

    my $count = 0;
    while (my $key = $sth->fetchrow_hashref('NAME_lc')) {
        if (remove_bulkspool_message('bulkspool', $key->{'messagekey'})) {
            $count++;
        } else {
            Log::do_log('err',
                'Unable to remove message (key = %s) from bulkspool_table',
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
        SDM::do_query(
            "DELETE FROM %s WHERE %s = %s", $table,
            $key,                           SDM::quote($messagekey)
        )
        ) {
        Log::do_log('err', 'Unable to delete %s %s from %s',
            $table, $key, $messagekey);
        return undef;
    }

    return 1;
}

# test the maximal message size the database will accept
sub store_test {
    my $value_test       = shift;
    my $divider          = 100;
    my $steps            = 50;
    my $maxtest          = $value_test / $divider;
    my $size_increment   = $divider * $maxtest / $steps;
    my $barmax           = $size_increment * $steps * ($steps + 1) / 2;
    my $even_part        = $barmax / $steps;
    my $robot            = 'notarobot';
    my $listname         = 'notalist';
    my $priority_message = 9;

    print "maxtest: $maxtest\n";
    print "barmax: $barmax\n";
    my $progress = Term::ProgressBar->new(
        {   name  => 'Total size transfered',
            count => $barmax,
            ETA   => 'linear',
        }
    );
    $priority_message = 9;

    my $messagekey = Digest::MD5::md5_hex(Time::HiRes::time());
    my $msg        = '';
    $progress->max_update_rate(1);
    my $next_update = 0;
    my $total       = 0;

    my $result = 0;

    for (my $z = 1; $z <= $steps; $z++) {
        $msg = MIME::Base64::decode($msg);
        for (my $i = 1; $i <= 1024 * $size_increment; $i++) {
            $msg .= 'a';
        }
        $msg = MIME::Base64::encode($msg);
        my $time = Time::HiRes::time();
        $progress->message(
            sprintf
                "Test storing and removing of a %5d kB message (step %s out of %s)",
            $z * $size_increment,
            $z, $steps
        );
        #
        unless (
            SDM::do_prepared_query(
                q{INSERT INTO bulkspool_table
                  (messagekey_bulkspool, message_bulkspool, lock_bulkspool)
                  VALUES (?, ?, 1)},
                $messagekey, $msg
            )
            ) {
            return (($z - 1) * $size_increment);
        }
        unless (remove_bulkspool_message('bulkspool', $messagekey)) {
            Log::do_log(
                'err',
                'Unable to remove test message (key = %s) from bulkspool_table',
                $messagekey
            );
        }
        $total += $z * $size_increment;
        $progress->message(sprintf ".........[OK. Done in %.2f sec]",
            Time::HiRes::time() - $time);
        $next_update = $progress->update($total + $even_part)
            if $total > $next_update && $total < $barmax;
        $result = $z * $size_increment;
    }
    $progress->update($barmax)
        if $barmax >= $next_update;
    return $result;
}

## Return the number of remaining packets in the bulkmailer table.
sub get_remaining_packets_count {
    Log::do_log('debug3', '');

    my $m_count = 0;

    unless (
        $sth = SDM::do_prepared_query(
            "SELECT COUNT(*) FROM bulkmailer_table WHERE lock_bulkmailer IS NULL"
        )
        ) {
        Log::do_log('err',
            'Unable to count remaining packets in bulkmailer_table');
        return undef;
    }

    my @result = $sth->fetchrow_array();

    return $result[0];
}

## Returns 1 if the number of remaining packets in the bulkmailer table
## exceeds
## the value of the 'bulk_fork_threshold' config parameter.
sub there_is_too_much_remaining_packets {
    Log::do_log('debug3', '');
    my $remaining_packets = get_remaining_packets_count();
    if ($remaining_packets > Conf::get_robot_conf('*', 'bulk_fork_threshold'))
    {
        return $remaining_packets;
    } else {
        return 0;
    }
}

1;
