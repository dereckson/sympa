# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 NAME

Sympa::Datasource::SQL::Default - Generic SQL data source object

=head1 DESCRIPTION

This class implements a generic SQL data source.

=cut

package Sympa::Datasource::SQL::Default;

use strict;
use base qw(Sympa::Datasource::SQL);

use Sympa::Log;

=head1 INSTANCE METHODS

=head2 $source->get_all_primary_keys()

Returns the primary keys for all the tables in the database.

=head3 Parameters

None.

=head3 Return value

An hashref with the following keys, or I<undef> if something went wrong:

=over

=item * The keys of the first level are the database's tables name.

=item * The keys of the second level are the name of the primary keys for the
table whose name is  given by the first level key.

=back

=cut

sub get_all_primary_keys {
    my $self = shift;
    &Sympa::Log::do_log('debug','Retrieving all primary keys in database %s',$self->{'db_name'});
    my %found_keys = undef;
    foreach my $table (@{$self->get_tables()}) {
	unless($found_keys{$table} = $self->get_primary_key({'table'=>$table})) {
	    &Sympa::Log::do_log('err','Primary key retrieval for table %s failed. Aborting.',$table);
	    return undef;
	}
    }
    return \%found_keys;
}

=head2 $source->get_all_indexes()

Returns the indexes for all the tables in the database.

=head3 Parameters

None.

=head3 Return value

An hashref with the following keys, or I<undef> if something went wrong:

=over

=item * The keys of the first level are the database's tables name.

=item * The keys of the second level are the name of the indexes for the table whose name is given by the first level key.

=back

=cut

sub get_all_indexes {
    my $self = shift;
    &Sympa::Log::do_log('debug','Retrieving all indexes in database %s',$self->{'db_name'});
    my %found_indexes;
    foreach my $table (@{$self->get_tables()}) {
	unless($found_indexes{$table} = $self->get_indexes({'table'=>$table})) {
	    &Sympa::Log::do_log('err','Index retrieval for table %s failed. Aborting.',$table);
	    return undef;
	}
    }
    return \%found_indexes;
}

=head2 $source->check_key($parameters)

Checks the compliance of a key of a table compared to what it is supposed to
reference.

=head3 Parameters

* 'table' : the name of the table for which we want to check the primary key
* 'key_name' : the kind of key tested:
	- if the value is 'primary', the key tested will be the table primary key
		- for any other value, the index whose name is this value will be tested.
	* 'expected_keys' : A ref to an array containing the list of fields that we
	   expect to be part of the key.

=head3 Return value

A ref likely to contain the following values:
#	* 'empty': if this key is defined, then no key was found for the table
#	* 'existing_key_correct': if this key's value is 1, then a key
#	   exists and is fair to the structure defined in the 'expected_keys' parameter hash.
#	   Otherwise, the key is not correct.
#	* 'missing_key': if this key is defined, then a part of the key was missing.
#	   The value associated to this key is a hash whose keys are the names of the fields
#	   missing in the key.
#	* 'unexpected_key': if this key is defined, then we found fields in the actual
#	   key that don't belong to the list provided in the 'expected_keys' parameter hash.
#	   The value associated to this key is a hash whose keys are the names of the fields
#	   unexpectedely found.

=cut

sub check_key {
    my $self = shift;
    my $param = shift;
    &Sympa::Log::do_log('debug','Checking %s key structure for table %s',$param->{'key_name'},$param->{'table'});
    my $keysFound;
    my $result;
    if (lc($param->{'key_name'}) eq 'primary') {
	return undef unless ($keysFound = $self->get_primary_key({'table'=>$param->{'table'}}));
    }else {
	return undef unless ($keysFound = $self->get_indexes({'table'=>$param->{'table'}}));
	$keysFound = $keysFound->{$param->{'key_name'}};
    }
    
    my @keys_list = keys %{$keysFound};
    if ($#keys_list < 0) {
	$result->{'empty'}=1;
    }else{
	$result->{'existing_key_correct'} = 1;
	my %expected_keys;
	foreach my $expected_field (@{$param->{'expected_keys'}}){
	    $expected_keys{$expected_field} = 1;
	}
	foreach my $field (@{$param->{'expected_keys'}}) {
	    unless ($keysFound->{$field}) {
		&Sympa::Log::do_log('info','Table %s: Missing expected key part %s in %s key.',$param->{'table'},$field,$param->{'key_name'});
		$result->{'missing_key'}{$field} = 1;
		$result->{'existing_key_correct'} = 0;
	    }
	}		
	foreach my $field (keys %{$keysFound}) {
	    unless ($expected_keys{$field}) {
		&Sympa::Log::do_log('info','Table %s: Found unexpected key part %s in %s key.',$param->{'table'},$field,$param->{'key_name'});
		$result->{'unexpected_key'}{$field} = 1;
		$result->{'existing_key_correct'} = 0;
	    }
	}
    }
    return $result;
}

return 1;
