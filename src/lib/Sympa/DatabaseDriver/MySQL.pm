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

package Sympa::DatabaseDriver::MySQL;

use strict;
use base qw(Sympa::DatabaseDriver);

use Sympa::Logger;

# Builds the string to be used by the DBI to connect to the database.
#
# IN: Nothing
#
# OUT: Nothing
sub build_connect_string {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'Building connection string to database %s',
        $self->{'db_name'});
    $self->{'connect_string'} =
        "DBI:$self->{'db_type'}:$self->{'db_name'}:$self->{'db_host'}";
}

# Returns an SQL clause to be inserted in a query.
# This clause will compute a substring of max length
# $param->{'substring_length'} starting from the first character equal
# to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Building substring clause');
    return
          "REVERSE(SUBSTRING("
        . $param->{'source_field'}
        . " FROM position('"
        . $param->{'separator'} . "' IN "
        . $param->{'source_field'}
        . ") FOR "
        . $param->{'substring_length'} . "))";
}

# Returns an SQL clause to be inserted in a query.
# This clause will limit the number of records returned by the query to
# $param->{'rows_count'}. If $param->{'offset'} is provided, an offset of
# $param->{'offset'} rows is done from the first record before selecting
# the rows to return.
sub get_limit_clause {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Building limit 1 clause');
    if ($param->{'offset'}) {
        return "LIMIT " . $param->{'offset'} . "," . $param->{'rows_count'};
    } else {
        return "LIMIT " . $param->{'rows_count'};
    }
}

# Returns a character string corresponding to the expression to use in a query
# involving a date.
# IN: A ref to hash containing the following keys:
#	* 'mode'
# 	   authorized values:
#		- 'write': the sub returns the expression to use in 'INSERT'
#		or 'UPDATE' queries
#		- 'read': the sub returns the expression to use in 'SELECT' queries
#	* 'target': the name of the field or the value to be used in the query
#
# OUT: the formatted date or undef if the date format mode is unknonw.
sub get_formatted_date {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Building SQL date formatting');
    if (lc($param->{'mode'}) eq 'read') {
        return sprintf 'UNIX_TIMESTAMP(%s)', $param->{'target'};
    } elsif (lc($param->{'mode'}) eq 'write') {
        return sprintf 'FROM_UNIXTIME(%d)', $param->{'target'};
    } else {
        $main::logger->do_log(Sympa::Logger::ERR, "Unknown date format mode %s",
            $param->{'mode'});
        return undef;
    }
}

# Checks whether a field is an autoincrement field or not.
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to test
# * 'table' : the name of the table to add
#
# OUT: Returns true if the field is an autoincrement field, false otherwise
sub is_autoinc {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'Checking whether field %s.%s is autoincremental',
        $param->{'field'}, $param->{'table'});
    my $sth;
    unless (
        $sth = $self->do_query(
            "SHOW FIELDS FROM `%s` WHERE Extra ='auto_increment' and Field = '%s'",
            $param->{'table'},
            $param->{'field'}
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to gather autoincrement field named %s for table %s',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    my $ref = $sth->fetchrow_hashref('NAME_lc');
    return ($ref->{'field'} eq $param->{'field'});
}

# Defines the field as an autoincrement field
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to set
# * 'table' : the name of the table to add
#
# OUT: 1 if the autoincrement could be set, undef otherwise.
sub set_autoinc {
    my $self  = shift;
    my $param = shift;
    my $field_type =
        defined($param->{'field_type'})
        ? $param->{'field_type'}
        : 'BIGINT( 20 )';
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'Setting field %s.%s as autoincremental',
        $param->{'field'}, $param->{'table'});
    unless (
        $self->do_query(
            "ALTER TABLE `%s` CHANGE `%s` `%s` %s NOT NULL AUTO_INCREMENT",
            $param->{'table'}, $param->{'field'},
            $param->{'field'}, $field_type
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to set field %s in table %s as autoincrement',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    return 1;
}

# Returns the list of the tables in the database.
# Returns undef if something goes wrong.
#
# OUT: a ref to an array containing the list of the tables names in the
# database, undef if something went wrong
sub get_tables {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'Retrieving all tables in database %s',
        $self->{'db_name'});
    my @raw_tables;
    my @result;
    unless (@raw_tables = $self->{'dbh'}->tables()) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to retrieve the list of tables from database %s',
            $self->{'db_name'});
        return undef;
    }

    foreach my $t (@raw_tables) {

        # Clean table names that would look like `databaseName`.`tableName`
        # (mysql)
        $t =~ s/^\`[^\`]+\`\.//;

        # Clean table names that could be surrounded by `` (recent DBD::mysql
        # release)
        $t =~ s/^\`(.+)\`$/$1/;
        push @result, $t;
    }
    return \@result;
}

# Adds a table to the database
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table to add
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
sub add_table {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Adding table %s to database %s',
        $param->{'table'}, $self->{'db_name'});
    unless (
        $self->do_query(
            "CREATE TABLE %s (temporary INT) DEFAULT CHARACTER SET utf8",
            $param->{'table'}
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not create table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    return sprintf "Table %s created in database %s", $param->{'table'},
        $self->{'db_name'};
}

# Returns a ref to an hash containing the description of the fields in a table
# from the database.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table whose fields are requested.
#
# OUT: A hash in which:
#	* the keys are the field names
#	* the values are the field type
#	Returns undef if something went wrong.
#
sub get_fields {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'Getting fields list from table %s in database %s',
        $param->{'table'}, $self->{'db_name'});
    my $sth;
    my %result;
    unless ($sth = $self->do_query("SHOW FIELDS FROM %s", $param->{'table'}))
    {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not get the list of fields from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
        $result{$ref->{'field'}} = $ref->{'type'};
    }
    return \%result;
}

# Changes the type of a field in a table from the database.
# IN: A ref to hash containing the following keys:
# * 'field' : the name of the field to update
# * 'table' : the name of the table whose fields will be updated.
# * 'type' : the type of the field to add
# * 'notnull' : specifies that the field must not be null
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub update_field {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'Updating field %s in table %s (%s, %s)',
        $param->{'field'}, $param->{'table'}, $param->{'type'},
        $param->{'notnull'});
    my $options;
    if ($param->{'notnull'}) {
        $options .= ' NOT NULL ';
    }
    my $report = sprintf(
        "ALTER TABLE %s CHANGE %s %s %s %s",
        $param->{'table'}, $param->{'field'}, $param->{'field'},
        $param->{'type'},  $options
    );
    $main::logger->do_log(Sympa::Logger::NOTICE, "ALTER TABLE %s CHANGE %s %s %s %s",
        $param->{'table'}, $param->{'field'}, $param->{'field'},
        $param->{'type'}, $options);
    unless (
        $self->do_query(
            "ALTER TABLE %s CHANGE %s %s %s %s",
            $param->{'table'}, $param->{'field'}, $param->{'field'},
            $param->{'type'},  $options
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not change field \'%s\' in table\'%s\'.',
            $param->{'field'}, $param->{'table'});
        return undef;
    }
    $report .= sprintf("\nField %s in table %s, structure updated",
        $param->{'field'}, $param->{'table'});
    $main::logger->do_log(Sympa::Logger::INFO,
        'Field %s in table %s, structure updated',
        $param->{'field'}, $param->{'table'});
    return $report;
}

# Adds a field in a table from the database.
# IN: A ref to hash containing the following keys:
#	* 'field' : the name of the field to add
#	* 'table' : the name of the table where the field will be added.
#	* 'type' : the type of the field to add
#	* 'notnull' : specifies that the field must not be null
#	* 'autoinc' : specifies that the field must be autoincremental
#	* 'primary' : specifies that the field is a key
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub add_field {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(
        Sympa::Logger::DEBUG3,            'Adding field %s in table %s (%s, %s, %s, %s)',
        $param->{'field'},   $param->{'table'},
        $param->{'type'},    $param->{'notnull'},
        $param->{'autoinc'}, $param->{'primary'}
    );
    my $options;

    # To prevent "Cannot add a NOT NULL column with default value NULL" errors
    if ($param->{'notnull'}) {
        $options .= 'NOT NULL ';
    }
    if ($param->{'autoinc'}) {
        $options .= ' AUTO_INCREMENT ';
    }
    if ($param->{'primary'}) {
        $options .= ' PRIMARY KEY ';
    }
    unless (
        $self->do_query(
            "ALTER TABLE %s ADD %s %s %s", $param->{'table'},
            $param->{'field'},             $param->{'type'},
            $options
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not add field %s to table %s in database %s',
            $param->{'field'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf('Field %s added to table %s (options : %s)',
        $param->{'field'}, $param->{'table'}, $options);
    $main::logger->do_log(Sympa::Logger::INFO,
        'Field %s added to table %s  (options : %s)',
        $param->{'field'}, $param->{'table'}, $options);

    return $report;
}

# Deletes a field from a table in the database.
# IN: A ref to hash containing the following keys:
#	* 'field' : the name of the field to delete
#	* 'table' : the name of the table where the field will be deleted.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub delete_field {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Deleting field %s from table %s',
        $param->{'field'}, $param->{'table'});

    unless (
        $self->do_query(
            "ALTER TABLE %s DROP COLUMN `%s`", $param->{'table'},
            $param->{'field'}
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not delete field %s from table %s in database %s',
            $param->{'field'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $report = sprintf('Field %s removed from table %s',
        $param->{'field'}, $param->{'table'});
    $main::logger->do_log(Sympa::Logger::INFO, 'Field %s removed from table %s',
        $param->{'field'}, $param->{'table'});

    return $report;
}

# Returns the list fields being part of a table's primary key.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys are requested.
#
# OUT: A ref to a hash in which each key is the name of a primary key or undef
# if something went wrong.
#
sub get_primary_key {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Getting primary key for table %s',
        $param->{'table'});

    my %found_keys;
    my $sth;
    unless ($sth = $self->do_query("SHOW COLUMNS FROM %s", $param->{'table'}))
    {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not get field list from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }

    my $test_request_result = $sth->fetchall_hashref('field');
    foreach my $scannedResult (keys %$test_request_result) {
        if ($test_request_result->{$scannedResult}{'key'} eq "PRI") {
            $found_keys{$scannedResult} = 1;
        }
    }
    return \%found_keys;
}

# Drops the primary key of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys must be
#	dropped.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub unset_primary_key {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Removing primary key from table %s',
        $param->{'table'});

    my $sth;
    unless ($sth =
        $self->do_query("ALTER TABLE %s DROP PRIMARY KEY", $param->{'table'}))
    {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not drop primary key from table %s in database %s',
            $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    my $report = "Table $param->{'table'}, PRIMARY KEY dropped";
    $main::logger->do_log(Sympa::Logger::INFO, 'Table %s, PRIMARY KEY dropped',
        $param->{'table'});

    return $report;
}

# Sets the primary key of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the primary keys must be
#	defined.
#	* 'fields' : a ref to an array containing the names of the fields used
#	in the key.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub set_primary_key {
    my $self  = shift;
    my $param = shift;

    my $sth;
    my $fields = join ',', @{$param->{'fields'}};
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'Setting primary key for table %s (%s)',
        $param->{'table'}, $fields);
    unless (
        $sth = $self->do_query(
            "ALTER TABLE %s ADD PRIMARY KEY (%s)", $param->{'table'},
            $fields
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Could not set fields %s as primary key for table %s in database %s',
            $fields,
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }
    my $report = "Table $param->{'table'}, PRIMARY KEY set on $fields";
    $main::logger->do_log(Sympa::Logger::INFO, 'Table %s, PRIMARY KEY set on %s',
        $param->{'table'}, $fields);
    return $report;
}

# Returns a ref to a hash in which each key is the name of an index.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the indexes are requested.
#
# OUT: A ref to a hash in which each key is the name of an index. These key
# point to
#	a second level hash in which each key is the name of the field indexed.
#      Returns undef if something went wrong.
#
sub get_indexes {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Looking for indexes in %s',
        $param->{'table'});

    my %found_indexes;
    my $sth;
    unless ($sth = $self->do_query("SHOW INDEX FROM %s", $param->{'table'})) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Could not get the list of indexes from table %s in database %s',
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }
    my $index_part;
    while ($index_part = $sth->fetchrow_hashref('NAME_lc')) {
        if ($index_part->{'key_name'} ne "PRIMARY") {
            my $index_name = $index_part->{'key_name'};
            my $field_name = $index_part->{'column_name'};
            $found_indexes{$index_name}{$field_name} = 1;
        }
    }
    return \%found_indexes;
}

# Drops an index of a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the index must be dropped.
#	* 'index' : the name of the index to be dropped.
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub unset_index {
    my $self  = shift;
    my $param = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Removing index %s from table %s',
        $param->{'index'}, $param->{'table'});

    my $sth;
    unless (
        $sth = $self->do_query(
            "ALTER TABLE %s DROP INDEX %s", $param->{'table'},
            $param->{'index'}
        )
        ) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Could not drop index %s from table %s in database %s',
            $param->{'index'}, $param->{'table'}, $self->{'db_name'});
        return undef;
    }
    my $report = "Table $param->{'table'}, index $param->{'index'} dropped";
    $main::logger->do_log(Sympa::Logger::INFO, 'Table %s, index %s dropped',
        $param->{'table'}, $param->{'index'});

    return $report;
}

# Sets an index in a table.
# IN: A ref to hash containing the following keys:
#	* 'table' : the name of the table for which the index must be defined.
#	* 'fields' : a ref to an array containing the names of the fields used
#	in the index.
#	* 'index_name' : the name of the index to be defined..
#
# OUT: A character string report of the operation done or undef if something
# went wrong.
#
sub set_index {
    my $self  = shift;
    my $param = shift;

    my $sth;
    my $fields = join ',', @{$param->{'fields'}};
    $main::logger->do_log(
        Sympa::Logger::DEBUG3,
        'Setting index %s for table %s using fields %s',
        $param->{'index_name'},
        $param->{'table'}, $fields
    );
    unless (
        $sth = $self->do_query(
            "ALTER TABLE %s ADD INDEX %s (%s)", $param->{'table'},
            $param->{'index_name'},             $fields
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Could not add index %s using field %s for table %s in database %s',
            $fields,
            $param->{'table'},
            $self->{'db_name'}
        );
        return undef;
    }
    my $report = "Table $param->{'table'}, index %s set using $fields";
    $main::logger->do_log(Sympa::Logger::INFO,
        'Table %s, index %s set using fields %s',
        $param->{'table'}, $param->{'index_name'}, $fields);
    return $report;
}

## For DOUBLE type.
sub AS_DOUBLE {
    return ({'mysql_type' => DBD::mysql::FIELD_TYPE_DOUBLE()} => $_[1])
        if scalar @_ > 1;
    return ();
}

1;
