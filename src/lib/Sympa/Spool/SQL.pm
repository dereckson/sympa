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

Sympa::Spool::SQL - A SQL-based spool

=head1 DESCRIPTION

This class implements a spool using a relational database as storage backend.

=cut

package Sympa::Spool::SQL;

use strict;
use base qw(Sympa::Spool);

use English qw(-no_match_vars);

use Mail::Address;
use MIME::Base64;
use Sys::Hostname qw(hostname);

use Sympa::DatabaseManager;
use Sympa::Logger;
use Sympa::Message;

=head1 CLASS METHODS

=over 4

=item Sympa::Spool::SQL->new(%parameters)

Creates a new L<Sympa::Spool::SQL> object.

Parameters:

=over 4

=item * I<name>: the spool name

=item * I<status>: selection status (ok|bad)

=item * I<selector>: FIXME

=item * I<sortby>: FIXME

=item * I<way>: FIXME

=back

Returns a new L<Sympa::Spool::SQL> object, or I<undef> for failure.

=cut

sub new {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s)', @_);
    my ($class, %params) = @_;

    my $name     = $params{name};
    my $status   = $params{status} || 'ok';
    my $selector = $params{selector};
    my $sortby   = $params{sortby};
    my $way      = $params{way};

    if (!$name) {
        $main::logger->do_log(
            Sympa::Logger::ERR, 'Missing name parameter'
        );
        return undef;
    }

    if ($status ne 'ok' and $status ne 'bad') {
        $status = 'ok';
    }

    my $self = bless {
        name   => $name,
        status => $status,
    }, $class;

    $self->{'selector'} = $selector if $selector;
    $self->{'sortby'}   = $sortby   if $sortby;
    $self->{'way'}      = $way      if $way;

    return $self;
}

=item Sympa::Spool::SQL->global_count($status)

=cut

sub global_count {
    my $class = shift;
    my $message_status = shift;

    my $sth = Sympa::DatabaseManager::do_query(
        "SELECT COUNT(*) FROM spool_table where message_status_spool = '"
            . $message_status
            . "'");

    my @result = $sth->fetchrow_array();
    $sth->finish();

    return $result[0];
}

=back

=head1 INSTANCE METHODS

=over

=item $spool->get_raw_entries(%parameters)

Return the raw content of the spool, as a list of serialized entries.

Parameters:

=over 4

=item * I<selector>: FIXME

=item * I<selection>: FIXME

=item * I<sortby>: FIXME

=item * I<way>: FIXME

=item * I<offset>: FIXME

=item * I<page_size>: FIXME

=back

=cut

sub get_raw_entries {
    my ($self, %params) = @_;

    # hash field->value used as filter WHERE sql query
    my $selector = $params{'selector'} || $self->{'selector'};

    # the list of field to select. possible values are :
    #    -  a comma separated list of field to select.
    #    -  '*'  is the default .
    #    -  '*_but_message' mean any field except message which may be huge
    #       and unusefull while listing spools
    # should be used mainly to select all but 'message' that may be huge and
    # may be unusefull
    my $selection = $params{'selection'};

    # for pagination, start fetch at element number = $offset;
    my $offset = $params{'offset'};

    # for pagination, limit answers to $page_size
    my $page_size = $params{'page_size'};

    my $orderby = $params{'sortby'} || $self->{'sortby'};    # sort
    my $way     = $params{'way'}    || $self->{'way'};       # asc or desc

    my $sql_where = _sqlselector($selector);
    if ($self->{status} eq 'bad') {
        $sql_where = $sql_where . " AND message_status_spool = 'bad' ";
    } else {
        $sql_where = $sql_where . " AND message_status_spool <> 'bad' ";
    }
    $sql_where =~ s/^\s*AND//;

    my $statement =
        'SELECT ' . _selectfields($selection)
        . sprintf " FROM spool_table WHERE %s AND spoolname_spool = %s ",
        $sql_where, Sympa::DatabaseManager::quote($self->{name});

    if ($orderby) {
        $statement = $statement . ' ORDER BY ' . $orderby . '_spool ';
        $statement = $statement . ' DESC' if ($way eq 'desc');
    }
    if ($page_size) {
        $statement .= Sympa::DatabaseManager::get_limit_clause(
            {'offset' => $offset, 'rows_count' => $page_size});
    }

    my $sth = Sympa::DatabaseManager::do_query($statement);
    return unless $sth;

    my @messages;
    while (my $message = $sth->fetchrow_hashref('NAME_lc')) {
        $message->{'messageasstring'} =
            MIME::Base64::decode($message->{'message'})
            if ($message->{'message'});
        $message->{'listname'} = $message->{'list'
            }; # duplicated because "list" is a tt2 method that convert a string to an array of chars so you can't test  [% IF  message.list %] because it is always defined!!!
        $message->{'status'}    = $self->{status};
        $message->{'spoolname'} = $self->{name};
        push @messages, $message;

        last if $page_size and $page_size <= scalar @messages;
    }
    $sth->finish();
    return @messages;
}

sub get_entries {
    my ($self, %params) = @_;

    return map { Sympa::Message->new(%$_) } $self->get_raw_entries(%params);
}

=item $spool->get_count(%parameters)

Return the number of spool entries matching the given criteria.

Parameters:

=over 4

=item * I<selector>: FIXME

=back

=cut

sub get_count {
    my ($self, %params) = @_;

    my $selector = $params{'selector'} || $self->{'selector'};
    my $sql_where = _sqlselector($selector);
    if ($self->{status} eq 'bad') {
        $sql_where = $sql_where . " AND message_status_spool = 'bad' ";
    } else {
        $sql_where = $sql_where . " AND message_status_spool <> 'bad' ";
    }
    $sql_where =~ s/^\s*AND//;

    my $statement = 'SELECT COUNT(*) '
        . sprintf " FROM spool_table WHERE %s AND spoolname_spool = %s ",
        $sql_where, Sympa::DatabaseManager::quote($self->{name});

    my $sth = Sympa::DatabaseManager::do_query($statement);
    return unless $sth;

    my @result = $sth->fetchrow_array();
    $sth->finish;
    return $result[0];
}

=item $spool->next()

Return the next spool entry ordered by priority.

=cut

sub next {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s)', @_);
    my $self = shift;

    my $sql_where = _sqlselector($self->{'selector'});

    if ($self->{status} eq 'bad') {
        $sql_where = $sql_where . " AND message_status_spool = 'bad' ";
    } else {
        $sql_where = $sql_where . " AND message_status_spool <> 'bad' ";
    }
    $sql_where =~ s/^\s*AND//;

    my $lock  = $PID . '@' . hostname();
    my $epoch = time;                  # should we use milli or nano seconds ?

    my $messagekey;
    while (1) {
        my $sth = Sympa::DatabaseManager::do_query(
            q{SELECT messagekey_spool FROM spool_table
          WHERE messagelock_spool IS NULL AND spoolname_spool = %s AND
                (priority_spool <> 'z' OR priority_spool IS NULL) AND %s
          ORDER by priority_spool, date_spool
          %s},
            Sympa::DatabaseManager::quote($self->{name}), $sql_where,
            Sympa::DatabaseManager::get_limit_clause({'rows_count' => 1})
        );
        unless ($sth) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Could not search spool %s',
                $self->{name});
            return undef;
        }
        $messagekey = $sth->fetchrow_array();
        $sth->finish();

        unless (defined $messagekey) {    # spool is empty
            return undef;
        }

        $sth = Sympa::DatabaseManager::do_prepared_query(
            q{UPDATE spool_table
          SET messagelock_spool = ?, lockdate_spool = ?
          WHERE messagekey_spool = ? AND messagelock_spool IS NULL},
            $lock, $epoch, $messagekey
        );
        unless ($sth) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Could not update spool %s',
                $self->{name});
            return undef;
        }
        unless ($sth->rows) {    # locked by another process?  retry.
            next;
        }
        last;
    }

    my $sth = Sympa::DatabaseManager::do_prepared_query(
        sprintf(
            q{SELECT %s
          FROM spool_table
          WHERE messagekey_spool = ? AND messagelock_spool = ?},
            _selectfields()
        ),
        $messagekey,
        $lock
    );
    unless ($sth) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not search message previously locked');
        return undef;
    }
    my $message = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish();

    unless ($message and $message->{'message'}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'INTERNAL Could not find message previouly locked');
        return undef;
    }
    $message->{'messageasstring'} =
        MIME::Base64::decode($message->{'message'});
    unless ($message->{'messageasstring'}) {
        $main::logger->do_log(Sympa::Logger::ERR, "Could not decode %s",
            $message->{'message'});
        return undef;
    }

    $message->{'spoolname'} = $self->{name};

    ## add objects
    my $robot_id = $message->{'robot'};
    my $listname = $message->{'list'};
    my $robot;

    if ($robot_id and $robot_id ne '*') {
        require Sympa::VirtualHost;
        $robot = Sympa::VirtualHost->new($robot_id);
    }
    if ($robot) {
        if ($listname and length $listname) {
            require Sympa::List;
            $message->{'list_object'} = Sympa::List->new($listname, $robot);
        }
        $message->{'robot_object'} = $robot;
    }

    return $message;
}

=item $spool->move_to_bad($key)

=cut

sub move_to_bad {
    my $self = shift;
    my $key  = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG,
        'Moving spooled entity with key %s to bad', $key);
    unless (
        $self->update(
            {'messagekey'     => $key},
            {'message_status' => 'bad', 'messagelock' => 'NULL'}
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to  to set status bad to spooled entity with key %s',
            $key);
        return undef;
    }
}

=item $spool->get_first_raw_entry(%parameters)

Return the first spool entry matching given selector.

=cut

sub get_first_raw_entry {
    my ($self, %params) = @_;

    my $selector = $params{selector};

    $main::logger->do_log(
        Sympa::Logger::DEBUG2, '(%s, messagekey=%s, list=%s, robot=%s)',
        $self, $selector->{'messagekey'},
        $selector->{'list'}, $selector->{'robot'}
    );

    my $sqlselector = _sqlselector($selector || $self->{'selector'});
    my $all = _selectfields();

    my $sth = Sympa::DatabaseManager::do_query(
        q{SELECT %s
      FROM spool_table
      WHERE spoolname_spool = %s%s
      %s},
        $all, Sympa::DatabaseManager::quote($self->{name}),
        ($sqlselector ? " AND $sqlselector" : ''),
        Sympa::DatabaseManager::get_limit_clause({'rows_count' => 1})
    );
    unless ($sth) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not get message from spool %s', $self);
        return undef;
    }

    my $message = $sth->fetchrow_hashref('NAME_lc');

    $sth->finish;

    unless ($message and %$message) {
        $main::logger->do_log(Sympa::Logger::ERR, 'No message: %s', $sqlselector);
        return undef;
    } else {
        $main::logger->do_log(Sympa::Logger::DEBUG3, 'Success: %s', $sqlselector);
    }

    $message->{'lock'} = $message->{'messagelock'};
    $message->{'messageasstring'} =
        MIME::Base64::decode($message->{'message'});
    $message->{'spoolname'} = $self->{name};

    if ($message->{'list'} && $message->{'robot'}) {
        my $robot = Sympa::VirtualHost->new($message->{'robot'});
        if ($robot) {
            my $list = Sympa::List->new($message->{'list'}, $robot);
            if ($list) {
                $message->{'list_object'} = $list;
            }
        }
    }
    return $message;
}

sub get_first_entry {
    my ($self, %params) = @_;

    my $raw_entry = $self->get_first_raw_entry(%params);
    return Sympa::Message->new(%$raw_entry);
}

=item $spool->unlock_message($key)

Unlock a message from the spool.

=cut

sub unlock_message {

    my $self       = shift;
    my $messagekey = shift;

    $main::logger->do_log(Sympa::Logger::DEBUG, 'Spool::unlock_message(%s,%s)',
        $self->{name}, $messagekey);
    return (
        $self->update(
            {'messagekey'  => $messagekey},
            {'messagelock' => 'NULL'}
        )
    );
}

#################"
#
#  update spool entries that match selector with values
sub update {
    my $self     = shift;
    my $selector = shift;
    my $values   = shift;

    $main::logger->do_log(Sympa::Logger::DEBUG2,
        "Spool::update($self->{name}, list = $selector->{'list'}, robot = $selector->{'robot'}, messagekey = $selector->{'messagekey'}"
    );

    my $where = _sqlselector($selector);

    my $set = '';

    # hidde B64 encoding inside spool database.
    if ($values->{'message'}) {
        $values->{'size'}    = length($values->{'message'});
        $values->{'message'} = MIME::Base64::encode($values->{'message'});
    }

    # update can be used in order to move a message from a spool to another
    # one
    $values->{'spoolname'} = $self->{name}
        unless ($values->{'spoolname'});

    foreach my $meta (keys %$values) {
        next if ($meta =~ /^(messagekey)$/);
        if ($set) {
            $set = $set . ',';
        }
        if (($meta eq 'messagelock') && ($values->{$meta} eq 'NULL')) {

            # SQL set  xx = NULL and set xx = 'NULL' is not the same !
            $set = $set . $meta . '_spool = NULL';
        } else {
            $set = $set . $meta . '_spool = ' . Sympa::DatabaseManager::quote($values->{$meta});
        }
        if ($meta eq 'messagelock') {
            if ($values->{'messagelock'} eq 'NULL') {

                # when unlock always reset the lockdate
                $set = $set . ', lockdate_spool = NULL ';
            } else {

                # when setting a lock always set the lockdate
                $set = $set . ', lockdate_spool = ' . time;
            }
        }
    }

    unless ($set) {
        $main::logger->do_log(Sympa::Logger::ERR, "No value to update");
        return undef;
    }
    unless ($where) {
        $main::logger->do_log(Sympa::Logger::ERR, "No selector for an update");
        return undef;
    }

    ## Updating Db
    my $statement = sprintf "UPDATE spool_table SET %s WHERE (%s)", $set,
        $where;

    unless (Sympa::DatabaseManager::do_query($statement)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to execute SQL statement "%s"', $statement);
        return undef;
    }
    return 1;
}

=item $spool->store($string, $metadata, $locked)

Store an entry in the spool.

=cut

sub store {
    my $self             = shift;
    my $message_asstring = shift;
    my $metadata         = shift;   # a set of attributes related to the spool
    my $locked = shift;    # if define message must stay locked after store
    my $sender = $metadata->{'sender'};
    $sender |= '';

    $main::logger->do_log(
        Sympa::Logger::DEBUG2,
        '(%s, <message_asstring>, list=%s, robot=%s, date=%s, %s)',
        $self,
        $metadata->{'list'},
        $metadata->{'robot'},
        $metadata->{'date'},
        $locked
    );

    my $b64msg = MIME::Base64::encode($message_asstring);
    my $message;
    if (   $self->{name} ne 'task'
        && $message_asstring    ne 'rebuild'
        && $self->{name} ne 'digest'
        && $self->{name} ne 'subscribe') {
        $message = Sympa::Message->new(
            'messageasstring' => $message_asstring,
            'noxsympato'      => 1
        );
    }

    if ($message && $message->has_valid_sender()) {
        $metadata->{'spam_status'} = 'spam' if $message->is_spam();
        $metadata->{'subject'}     = $message->get_header('Subject');
        $metadata->{'subject'}     = substr $metadata->{'subject'}, 0, 109
            if defined $metadata->{'subject'};
        $metadata->{'messageid'} = $message->get_header('Message-Id');
        $metadata->{'messageid'} = substr $metadata->{'messageid'}, 0, 295
            if defined $metadata->{'messageid'};
        $metadata->{'headerdate'} = substr $message->get_header('Date'), 0,
            78;

        #FIXME: get_sender_email() ?
        my @sender_hdr = Mail::Address->parse($message->get_header('From'));
        if (@sender_hdr) {
            $metadata->{'sender'} = lc($sender_hdr[0]->address)
                unless $sender;
            $metadata->{'sender'} = substr $metadata->{'sender'}, 0, 109;
        }
    } else {
        $metadata->{'subject'}   = '';
        $metadata->{'messageid'} = '';
        $metadata->{'sender'}    = $sender;
    }
    $metadata->{'date'} = int(time) unless ($metadata->{'date'});
    $metadata->{'size'} = length($message_asstring)
        unless ($metadata->{'size'});
    $metadata->{'message_status'} = 'ok';

    my ($insertpart1, $insertpart2, @insertparts) = ('', '');
    foreach my $meta (
        qw(list authkey robot message_status priority date type subject sender
        messageid size headerdate spam_status dkim_privatekey dkim_d dkim_i
        dkim_selector task_label task_date task_model
        task_flavour task_object)
        ) {
        $insertpart1 .= ', ' . $meta . '_spool';
        $insertpart2 .= ', ?';
        push @insertparts, $metadata->{$meta};
    }
    my $lock = $PID . '@' . hostname();

    my $sth = Sympa::DatabaseManager::do_prepared_query(
        sprintf(
            q{INSERT INTO spool_table
	      (spoolname_spool, messagelock_spool, message_spool%s)
	      VALUES (?, ?, ?%s)},
            $insertpart1, $insertpart2
        ),
        $self->{name},
        $lock,
        $b64msg,
        @insertparts
    );

    # this query returns the autoinc primary key as result of this insert
    $sth = Sympa::DatabaseManager::do_prepared_query(
        q{SELECT messagekey_spool as messagekey
	  FROM spool_table
	  WHERE messagelock_spool = ? AND date_spool = ?},
        $lock, $metadata->{'date'}
    );
    ##FIXME: should check error

    my $inserted_message = $sth->fetchrow_hashref('NAME_lc');
    my $messagekey       = $inserted_message->{'messagekey'};

    $sth->finish;

    unless ($locked) {
        $self->unlock_message($messagekey);
    }
    return $messagekey;
}

=item $spool->remove($params)

Remove an entry from the spool.

=cut

sub remove {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $self   = shift;
    my $params = shift;

    my $just_try    = $params->{'just_try'};
    my $sqlselector = _sqlselector($params);

    my $sth = Sympa::DatabaseManager::do_query(
        q{DELETE FROM spool_table
      WHERE spoolname_spool = %s%s},
        Sympa::DatabaseManager::quote($self->{name}),
        ($sqlselector ? " AND $sqlselector" : '')
    );

    unless ($sth) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not remove message from spool %s', $self);
        return undef;
    }
    ## search if this message is already in spool database : mailfile may
    ## perform multiple submission of exactly the same message
    unless ($sth->rows) {
        $main::logger->do_log(Sympa::Logger::ERR, 'message is not in spool: %s',
            $sqlselector)
            unless $just_try;
        return undef;
    }

    return 1;
}

=item $spool->clean($delay)

Clean the spool by removing old entries.

=cut

sub clean {
    my $self   = shift;
    my $delay = shift;
    $main::logger->do_log(
        Sympa::Logger::DEBUG, 'Cleaning spool %s (%s), delay: %s',
        $self->{name}, $self->{status},
        $delay
    );

    return undef unless $delay;

    my $freshness_date = time - ($delay * 60 * 60 * 24);

    my $sqlquery =
        sprintf
        "DELETE FROM spool_table WHERE spoolname_spool = %s AND date_spool < %s ",
        Sympa::DatabaseManager::quote($self->{spoolname}), $freshness_date;
    if ($self->{status} eq 'bad') {
        $sqlquery = $sqlquery . " AND message_status_spool = 'bad' ";
    } else {
        $sqlquery = $sqlquery . " AND message_status_spool <> 'bad'";
    }

    my $sth = Sympa::DatabaseManager::do_query('%s', $sqlquery);
    $sth->finish;
    $main::logger->do_log(Sympa::Logger::DEBUG,
        "%s entries older than %s days removed from spool %s",
        $sth->rows, $delay, $self->{name});
    return 1;
}

#######################
# Internal to ease SQL
# return a SQL SELECT substring in ordder to select choosen fields from spool
# table
# selction is comma separated list of field, '*' or '*_but_message'. in this
# case skip message_spool field
sub _selectfields {
    my $selection = shift;    # default all valid fields from spool table

    $selection = '*' unless $selection;
    my $select = '';

    if (($selection eq '*_but_message') || ($selection eq '*')) {

        my %db_struct = Sympa::DatabaseDescription::db_struct();

        foreach my $field (keys %{$db_struct{'mysql'}{'spool_table'}}) {
            next
                if (($selection eq '*_but_message')
                && ($field eq 'message_spool'));
            my $var = $field;
            $var =~ s/\_spool//;
            $select = $select . $field . ' AS ' . $var . ',';
        }
    } else {
        my @fields = split(/,/, $selection);
        foreach my $field (@fields) {
            $select = $select . $field . '_spool AS ' . $field . ',';
        }
    }

    $select =~ s/\,$//;
    return $select;
}

#######################
# Internal to ease SQL
# return a SQL WHERE substring in order to select chosen fields from the spool
# table
# selector is a hash where key is a column name and value is column value
# expected.****
#   **** value can be prefixed with <,>,>=,<=, in that case the default
#   comparator operator (=) is changed, I known this is dirty but I'm lazy :-(
sub _sqlselector {
    my $selector = shift || {};
    my $sqlselector = '';

    $selector = {%$selector};
    if (ref $selector->{'list'}) {
        $selector->{'robot'} = $selector->{'list'}->domain;
        $selector->{'list'}  = $selector->{'list'}->name;
    }
    if (ref $selector->{'robot'}) {
        $selector->{'robot'} = $selector->{'robot'}->domain;
    }

    foreach my $field (keys %$selector) {
        next if $field eq 'just_try';

        my $compare_operator = '=';
        my $select_value     = $selector->{$field};
        if ($select_value =~ /^([\<\>]\=?)\.(.*)$/) {
            $compare_operator = $1;
            $select_value     = $2;
        }

        if ($sqlselector) {
            $sqlselector .=
                  ' AND ' 
                . $field
                . '_spool '
                . $compare_operator . ' '
                . Sympa::DatabaseManager::quote($selector->{$field});
        } else {
            $sqlselector =
                  ' ' 
                . $field
                . '_spool '
                . $compare_operator . ' '
                . Sympa::DatabaseManager::quote($selector->{$field});
        }
    }
    return $sqlselector;
}

=back

=cut

1;
