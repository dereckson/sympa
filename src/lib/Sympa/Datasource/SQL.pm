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

package Sympa::Datasource::SQL;

use strict;
use warnings;
use DBI;
use English qw(-no_match_vars);

use Log;

#use base qw(Sympa::Datasource);

# Structure to keep track of active connections/connection status
# Keys: unique ID of connection (includes type, server, port, dbname and user).
# Values: database handler.
our %connection_of;

# Map to driver names from older format of db_type parameter.
my %driver_aliases = (
    mysql => 'Sympa::DatabaseDriver::MySQL',
    Pg    => 'Sympa::DatabaseDriver::PostgreSQL',
);

sub new {
    Log::do_log('debug2', '(%s, %s)', @_);
    my $class  = shift;
    my $params = shift;
    my %params = %$params;

    my $driver = $driver_aliases{$params{'db_type'}} || $params{'db_type'};
    $driver = 'Sympa::DatabaseDriver::' . $driver
        unless $driver =~ /::/;
    unless (eval "require $driver"
        and $driver->isa('Sympa::DatabaseDriver')) {
        Log::do_log('err', 'Unable to use %s module: %s',
            $driver, $EVAL_ERROR);
        return undef;
    }

    my $self = bless {
        map {
                  (exists $params{$_} and defined $params{$_})
                ? ($_ => $params{$_})
                : ()
            } (
            @{$driver->required_parameters},
            @{$driver->optional_parameters},
            'reconnect_options'
            )
    } => $driver;

    return $self;
}

############################################################
#  connect
############################################################
#  Connect to an SQL database.
#
# IN : $options : ref to a hash. Options for the connection process.
#         currently accepts 'keep_trying' : wait and retry until
#         db connection is ok (boolean) ; 'warn' : warn
#         listmaster if connection fails (boolean)
# OUT : 1 | undef
#
##############################################################
sub connect {
    Log::do_log('debug3', '(%s)', @_);
    my $self = shift;

    # First check if we have an active connection with this server
    if ($self->ping) {
        Log::do_log('debug3', 'Connection to database %s already available',
            $self);
        return 1;
    }

    # Do we have required parameters?
    foreach my $param (@{$self->required_parameters}) {
        unless (defined $self->{$param}) {
            Log::do_log('info', 'Missing parameter %s for DBI connection',
                $param);
            return undef;
        }
    }

    # Check if required module such as DBD is installed.
    foreach my $module (@{$self->required_modules}) {
        unless (eval "require $module") {
            Log::do_log(
                'err',
                'A module for %s is not installed. You should download and install %s',
                ref($self),
                $module
            );
            tools::send_notify_to_listmaster('*', 'missing_dbd',
                {'db_type' => ref($self), 'db_module' => $module});
            return undef;
        }
    }

    # Set unique ID to determine connection.
    $self->{_id} = $self->get_id;

    # Establish new connection.

    # Set environment variables
    # Used by Oracle (ORACLE_HOME) etc.
    if ($self->{'db_env'}) {
        foreach my $env (split /;/, $self->{'db_env'}) {
            my ($key, $value) = split /=/, $env, 2;
            $ENV{$key} = $value if ($key);
        }
    }

    $connection_of{$self->{_id}} = eval { $self->_connect };

    unless ($self->ping) {
        unless (    $self->{'reconnect_options'}
            and $self->{'reconnect_options'}{'keep_trying'}) {
            Log::do_log('err', 'Can\'t connect to Database %s', $self);
            $self->{_status} = 'failed';
            return undef;
        }

        # Notify listmaster unless the 'failed' status was set earlier.
        Log::do_log('err', 'Can\'t connect to Database %s, still trying...',
            $self);
        unless ($self->{_status} and $self->{_status} eq 'failed') {
            tools::send_notify_to_listmaster('*', 'no_db', {});
        }

        # Loop until connect works
        my $sleep_delay = 60;
        while (1) {
            sleep $sleep_delay;
            $connection_of{$self->{_id}} = eval { $self->_connect };
            last if $self->ping;
            $sleep_delay += 10;
        }

        delete $self->{_status};

        Log::do_log('notice', 'Connection to Database %s restored', $self);
        tools::send_notify_to_listmaster('*', 'db_restored', {});
    }

    Log::do_log('debug2', 'Connected to Database %s', $self);

    return 1;
}

# Merged into connect(().
#sub establish_connection();

sub _connect {
    my $self = shift;

    my $connection = DBI->connect(
        $self->build_connect_string, $self->{'db_user'},
        $self->{'db_passwd'}, {PrintError => 0}
    );
    # Force field names to be lowercased.
    # This has has been added after some problems of field names
    # upercased with Oracle.
    $connection->{FetchHashKeyName} = 'NAME_lc' if $connection;

    return $connection;
}

sub __dbh {
    my $self = shift;
    return $connection_of{$self->{_id} || ''};
}

sub do_query {
    my $self   = shift;
    my $query  = shift;
    my @params = @_;

    my $sth;

    $query =~ s/^\s+//;
    $query =~ s/\s+$//;
    my $statement = sprintf $query, @params;

    my $s = $statement;
    $s =~ s/\n\s*/ /g;
    Log::do_log('debug3', 'Will perform query "%s"', $s);

    unless ($sth = $self->__dbh->prepare($statement)) {
        # Check connection to database in case it would be the cause of the
        # problem.
        unless ($self->connect()) {
            Log::do_log('err', 'Unable to get a handle to %s database',
                $self->{'db_name'});
            return undef;
        } else {
            unless ($sth = $self->__dbh->prepare($statement)) {
                my $trace_statement = sprintf $query,
                    @{$self->prepare_query_log_values(@params)};
                Log::do_log('err', 'Unable to prepare SQL statement %s: %s',
                    $trace_statement, $self->__dbh->errstr);
                return undef;
            }
        }
    }
    unless ($sth->execute) {
        # Check connection to database in case it would be the cause of the
        # problem.
        unless ($self->connect()) {
            Log::do_log('err', 'Unable to get a handle to %s database',
                $self->{'db_name'});
            return undef;
        } else {
            unless ($sth = $self->__dbh->prepare($statement)) {
                # Check connection to database in case it would be the cause
                # of the problem.
                unless ($self->connect()) {
                    Log::do_log('err',
                        'Unable to get a handle to %s database',
                        $self->{'db_name'});
                    return undef;
                } else {
                    unless ($sth = $self->__dbh->prepare($statement)) {
                        my $trace_statement = sprintf $query,
                            @{$self->prepare_query_log_values(@params)};
                        Log::do_log('err',
                            'Unable to prepare SQL statement %s: %s',
                            $trace_statement, $self->__dbh->errstr);
                        return undef;
                    }
                }
            }
            unless ($sth->execute) {
                my $trace_statement = sprintf $query,
                    @{$self->prepare_query_log_values(@params)};
                Log::do_log('err', 'Unable to execute SQL statement "%s": %s',
                    $trace_statement, $self->__dbh->errstr);
                return undef;
            }
        }
    }

    return $sth;
}

sub do_prepared_query {
    my $self   = shift;
    my $query  = shift;
    my @params = ();
    my %types  = ();

    my $sth;

    ## get binding types and parameters
    my $i = 0;
    while (scalar @_) {
        my $p = shift;
        if (ref $p eq 'HASH') {
            # a hashref { sql_type => SQL_type } etc.
            $types{$i} = $p;
            push @params, shift;
        } elsif (ref $p) {
            Log::do_log('err', 'Unexpected %s object.  Ask developer',
                ref $p);
            return undef;
        } else {
            push @params, $p;
        }
        $i++;
    }

    $query =~ s/^\s+//;
    $query =~ s/\s+$//;
    $query =~ s/\n\s*/ /g;
    Log::do_log('debug3', 'Will perform query "%s"', $query);

    if ($self->{'cached_prepared_statements'}{$query}) {
        $sth = $self->{'cached_prepared_statements'}{$query};
    } else {
        Log::do_log('debug3',
            'Did not find prepared statement for %s. Doing it', $query);
        unless ($sth = $self->__dbh->prepare($query)) {
            unless ($self->connect()) {
                Log::do_log('err', 'Unable to get a handle to %s database',
                    $self->{'db_name'});
                return undef;
            } else {
                unless ($sth = $self->__dbh->prepare($query)) {
                    Log::do_log('err', 'Unable to prepare SQL statement: %s',
                        $self->__dbh->errstr);
                    return undef;
                }
            }
        }

        ## bind parameters with special types
        ## this may be done only once when handle is prepared.
        foreach my $i (sort keys %types) {
            $sth->bind_param($i + 1, $params[$i], $types{$i});
        }

        $self->{'cached_prepared_statements'}{$query} = $sth;
    }
    unless ($sth->execute(@params)) {
        # Check database connection in case it would be the cause of the
        # problem.
        unless ($self->connect()) {
            Log::do_log('err', 'Unable to get a handle to %s database',
                $self->{'db_name'});
            return undef;
        } else {
            unless ($sth = $self->__dbh->prepare($query)) {
                unless ($self->connect()) {
                    Log::do_log('err',
                        'Unable to get a handle to %s database',
                        $self->{'db_name'});
                    return undef;
                } else {
                    unless ($sth = $self->__dbh->prepare($query)) {
                        Log::do_log('err',
                            'Unable to prepare SQL statement: %s',
                            $self->__dbh->errstr);
                        return undef;
                    }
                }
            }

            ## bind parameters with special types
            ## this may be done only once when handle is prepared.
            foreach my $i (sort keys %types) {
                $sth->bind_param($i + 1, $params[$i], $types{$i});
            }

            $self->{'cached_prepared_statements'}{$query} = $sth;
            unless ($sth->execute(@params)) {
                Log::do_log('err', 'Unable to execute SQL statement "%s": %s',
                    $query, $self->__dbh->errstr);
                return undef;
            }
        }
    }

    return $sth;
}

sub prepare_query_log_values {
    my $self = shift;
    my @result;
    foreach my $value (@_) {
        my $cropped = substr($value, 0, 100);
        if ($cropped ne $value) {
            $cropped .= "...[shortened]";
        }
        push @result, $cropped;
    }
    return \@result;
}

# DEPRECATED: Use tools::eval_in_time() and fetchall_arrayref().
#sub fetch();

sub disconnect {
    my $self = shift;

    my $id = $self->get_id;
    $connection_of{$id}->disconnect if $connection_of{$id};
    delete $connection_of{$id};

    return 1;
}

# NOT YET USED.
#sub create_db;

sub ping {
    my $self = shift;

    my $dbh = $self->__dbh;

    # Disconnected explicitly.
    return undef unless $dbh;
    # Some drivers don't have ping().
    return 1 unless $dbh->can('ping');
    return $dbh->ping;
}

sub quote {
    my $self = shift;
    my ($string, $datatype) = @_;

    return $self->__dbh->quote($string, $datatype);
}

# No longer used.
#sub set_fetch_timeout($timeout);

## Returns a character string corresponding to the expression to use in
## a read query (e.g. SELECT) for the field given as argument.
## This sub takes a single argument: the name of the field to be used in
## the query.
##
sub get_canonical_write_date {
    my $self  = shift;
    my $field = shift;
    return $self->get_formatted_date({'mode' => 'write', 'target' => $field});
}

## Returns a character string corresponding to the expression to use in
## a write query (e.g. UPDATE or INSERT) for the value given as argument.
## This sub takes a single argument: the value of the date to be used in
## the query.
##
sub get_canonical_read_date {
    my $self  = shift;
    my $value = shift;
    return $self->get_formatted_date({'mode' => 'read', 'target' => $value});
}

# We require that user also matches (except SQLite).
sub get_id {
    my $self = shift;

    return join ';', map {"$_=$self->{$_}"}
        grep {
               !ref($self->{$_})
            and defined $self->{$_}
            and !/\A_/
            and !/passw(or)?d/
        }
        sort keys %$self;
}

1;
