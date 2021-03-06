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
# along with this program.  If not, see <http://www.gnu.org/licenses>.

=encoding utf-8

=head1 NAME

Sympa::Spool::File - A file-based spool

=head1 DESCRIPTION

This class implements a spool using the filesystem as storage backend.

=cut

package Sympa::Spool::File;

use strict;
use warnings;
use base qw(Sympa::Spool);

use Carp qw(croak);
use English qw(-no_match_vars);
use File::Copy;
use File::Path qw(make_path);

use Sympa::Tools;
use Sympa::Tools::File;

our $filename_regexp = '^(\S+)\.(\d+)\.\w+$';

=head1 CLASS METHODS

=over 4

=item Sympa::Spool::File->new(%parameters)

Creates a new L<Sympa::Spool::File> object.

Parameters:

=over 4

=item * I<name>: the spool name

=item * I<directory>: the spool directory

=item * I<status>: selection status (ok|bad)

=item * I<selector>: FIXME

=item * I<sortby>: FIXME

=item * I<way>: FIXME

=back

Returns a new L<Sympa::Spool::File> object, or I<undef> for failure.

=cut

sub new {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s, ...)', @_);
    my ($class, %params) = @_;

    my $name      = $params{name};
    my $directory = $params{directory};
    my $status    = $params{status} || 'ok';
    my $selector  = $params{selector};
    my $sortby    = $params{sortby};
    my $way       = $params{way};

    if (!$name) {
        $main::logger->do_log(
            Sympa::Logger::ERR, 'Missing name parameter'
        );
        return undef;
    }

    if (!$directory) {
        $main::logger->do_log(
            Sympa::Logger::ERR, 'Missing directory parameter'
        );
        return undef;
    }

    if ($status ne 'ok' and $status ne 'bad') {
        $status = 'ok';
    }

    if ($status eq 'bad') {
        $directory .= '/bad';
    }

    my $self = bless {
        name      => $name,
        status    => $status,
        directory => $directory,
    }, $class;

    $self->{'selector'} = $selector if $selector;
    $self->{'sortby'}   = $sortby   if $sortby;
    $self->{'way'}      = $way      if $way;

    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Spool to scan "%s"', $directory);

    $self->_create_spool_dir();

    return $self;
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
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my ($self, %params) = @_;

    my $perlselector =
           _perlselector($params{'selector'})
        || _perlselector($self->{'selector'})
        || '1';
    my $perlcomparator = _perlcomparator($params{'sortby'}, $params{'way'})
        || _perlcomparator($self->{'sortby'}, $self->{'way'});
    my $offset = $params{'offset'} || 0;
    my $page_size = $params{'page_size'};

    # the fields to select. possible values are :
    #    -  '*'  is the default .
    #    -  '*_but_message' mean any field except message which may be huge
    #       and unuseful while listing spools
    #    - 'count' mean the selection is just a count.
    # should be used mainly to select only metadata that may be huge and
    # may be unuseful
    my $selection = $params{'selection'} || '*';

    my @messages;
    foreach my $key ($self->get_files_in_spool) {
        next unless $self->is_readable($key);
        my $item = $self->parse_filename($key);

        # We don't decide moving erroneous file to bad spool here, since it
        # may be a temporary file "T.xxx" and so on.
        next unless $item;

        # Get additional details from spool file, likely to be used in
        # queries.
        unless ($self->get_additional_details($item->{'messagekey'}, $item)) {
            $self->move_to_bad($item->{'messagekey'});
            next;
        }
        my $cmp = eval $perlselector;
        if ($EVAL_ERROR) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Failed to evaluate selector: %s', $EVAL_ERROR);
            return undef;
        }
        next unless $cmp;
        push @messages, $item;
    }

    # Sorting
    if ($perlcomparator) {
        my @sorted = eval sprintf 'sort { %s } @messages', $perlcomparator;
        if ($EVAL_ERROR) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Could not sort messages: %s',
                $EVAL_ERROR);
        } else {
            @messages = @sorted;
        }
    }

    # Paging
    my $end;
    if ($page_size) {
        $end = $offset + $page_size;
        $end = scalar @messages if $end > scalar @messages;
    } else {
        $end = scalar @messages;
    }

    # Field selection
    if ($selection eq '*_but_message') {
        return () if $offset >= scalar @messages;
        return (splice @messages, $offset, $end - $offset);
    } elsif ($selection eq 'count') {
        return 0 if $offset >= scalar @messages;
        my @retained_messages = splice @messages, $offset, $end - $offset;
        return scalar(scalar @retained_messages);
    }

    # Extract subset
    my @ret = ();
    my $i   = 0;
    foreach my $item (@messages) {
        last if $end <= $i;
        my $content = $self->get_file_content($item->{'messagekey'});
        unless ($content) {
            $self->move_to_bad($item->{'messagekey'});
            next;
        }
        $item->{messageastring} = $content;
        push @ret, $item
            if $offset <= $i;
        $i++;
    }
    return @ret;
}

=item $spool->get_count(%parameters)

Return the number of spool entries matching the given criteria.

=cut

sub get_count {
    my ($self, %params) = @_;
    my @messages = $self->get_raw_entries(%params);
    return $#messages + 1;
}

=item $spool->get_file_key()

Returns the single file corresponding to the selector.

=cut

sub get_file_key {
    my $self     = shift;
    my $selector = shift;
    my $message;
    unless ($message = $self->get_message($selector)) {
        return undef;
    }
    return $message->{'messagekey'};
}

=item $spool->next()

Return the next spool entry ordered by priority.

next lock the
message_in_spool that is returned
returns 0 if no file found
returns undef if problem scanning spool

=cut

sub next {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s)', @_);
    my $self = shift;

    my $data;

    unless ($self->_refresh_spool_files_list) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to refresh spool %s files list', $self);
        return undef;
    }
    return 0 unless ($#{$self->{'spool_files_list'}} > -1);
    return 0 unless $data = $self->get_next_file_to_process;
    my $content = $self->get_file_content($data->{'messagekey'});
    unless ($content) {
        $self->move_to_bad($data->{'messagekey'});
        return undef;
    }
    $data->{messageastring} = $content;
    return $data;
}

#FIXME: This would be replaced by Sympa::Message::new().
sub parse_filename {
    my $self = shift;
    my $key  = shift;

    unless ($key) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to find out which file to process');
        return undef;
    }

    my $data = {
        'file'       => $self->{directory} . '/' . $key,
        'messagekey' => $key,
    };

    unless ($self->is_relevant($key)) {
        return undef;
    }
    unless ($self->analyze_file_name($key, $data)) {
        return undef;
    }
    return $data;
}

# Placeholder: overriden in inheriting classes to get additionnal details from
# the file content.
sub get_additional_details {
    my $self = shift;
    my $key  = shift;
    my $data = shift;
    return 1;
}

sub get_next_file_to_process {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s)', @_);
    my $self = shift;

    my $perlselector = _perlselector($self->{'selector'}) || '1';
    my $perlcomparator = _perlcomparator($self->{'sortby'}, $self->{'way'});

    my $data = undef;
    my $cmp;
    foreach my $key (@{$self->{'spool_files_list'}}) {
        next unless $self->is_readable($key);
        my $item = $self->parse_filename($key);
        next unless $item;

        $cmp = eval $perlselector;
        if ($EVAL_ERROR) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Failed to evaluate selector: %s', $EVAL_ERROR);
            return undef;
        }
        next unless $cmp;

        unless ($data) {
            $data = $item;
            next;
        }
        my ($a, $b) = ($data, $item);
        $cmp = eval $perlcomparator;
        if ($EVAL_ERROR) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Could not compare messages: %s', $EVAL_ERROR);
            return $data;
        }
        if ($cmp > 0) {
            $data = $item;
        }
    }
    return $data;
}

sub analyze_file_name {
    my $self = shift;
    my $data = shift;
    return $data;
}

sub is_relevant {
    return 1;
}

sub is_readable {
    my $self = shift;
    my $key  = shift;

    if (-f "$self->{directory}/$key" && -r _) {
        return 1;
    } else {
        return 0;
    }
}

sub get_file_content {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    my $content;
    eval {
        $content = Sympa::Tools::File::slurp_file(
            $self->{directory} . '/' . $key
        );
    };
    if ($EVAL_ERROR) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to open file %s: %s',
            $self->{directory} . '/' . $key, $EVAL_ERROR
        );
        return undef;
    }

    return $content;
}

sub lock_message {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    $self->{'lock'} = Sympa::Lock->new($key);
    $self->{'lock'}->set_timeout(-1);
    unless ($self->{'lock'}->lock('write')) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Unable to put a lock on file %s',
            $key);
        delete $self->{'lock'};
        return undef;
    }
    return 1;
}

=item $spool->unlock_message($key)

Unlock a message from the spool.

=cut

sub unlock_message {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    unless (ref($self->{'lock'}) and $self->{'lock'}->isa('Sympa::Lock')) {
        delete $self->{'lock'};
        return undef;
    }
    unless ($self->{'lock'}->unlock()) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to remove lock from file %s', $key);
        delete $self->{'lock'};
        return undef;
    }
    return 1;
}

sub get_files_in_spool {
    my $self = shift;
    return undef unless ($self->_refresh_spool_files_list);
    return @{$self->{'spool_files_list'}};
}

sub get_dirs_in_spool {
    my $self = shift;
    return undef unless ($self->_refresh_spool_dirs_list);
    return @{$self->{'spool_dirs_list'}};
}

sub _refresh_spool_files_list {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG2, '%s', $self->get_id);
    unless (opendir SPOOLDIR, $self->{directory}) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to access %s spool. Please check proper rights are set;',
            $self->{directory}
        );
        return undef;
    }
    my @qfile =
        sort Sympa::Tools::by_date grep { !/^\./ && -f "$self->{directory}/$_" }
        readdir(SPOOLDIR);
    closedir(SPOOLDIR);
    $self->{'spool_files_list'} = \@qfile;
    return 1;
}

sub _refresh_spool_dirs_list {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG2, '%s', $self->get_id);
    unless (opendir SPOOLDIR, $self->{directory}) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to access %s spool. Please check proper rights are set;',
            $self->{directory}
        );
        return undef;
    }
    my @qdir =
        sort Sympa::Tools::by_date grep { !/^(\.\.|\.)$/ && -d "$self->{directory}/$_" }
        readdir(SPOOLDIR);
    closedir(SPOOLDIR);
    $self->{'spool_dirs_list'} = \@qdir;
    return 1;
}

sub _create_spool_dir {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG, '%s', $self->get_id);
    unless (-d $self->{directory}) {
        make_path($self->{directory});
    }
}

=item $spool->move_to_bad($key)

=cut

sub move_to_bad {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    unless (-d $self->{directory} . '/bad') {
        make_path($self->{directory} . '/bad');
    }
    unless (
        File::Copy::copy(
            $self->{directory} . '/' . $key,
            $self->{directory} . '/bad/' . $key
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Could not move file %s to spool bad %s: %s',
            $self->{directory} . '/' . $key,
            $self->{directory} . '/bad', $ERRNO
        );
        return undef;
    }
    unless (unlink($self->{directory} . '/' . $key)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            "Could not unlink message %s/%s . Exiting",
            $self->{directory}, $key);
    }
    $self->unlock_message($key);
    return 1;
}

=item $spool->get_first_raw_entry(%parameters)

Return the first spool entry matching given selector.

=cut

sub get_first_raw_entry {
    my ($self, %params) = @_;

    my @entries = $self->get_raw_entries(%params);
    return $entries[0];
}

#################"
# lock one message from related spool using a specified selector
#
#sub unlock_message {
#
#    my $self = shift;
#    my $messagekey = shift;
#
#    $main::logger->do_log(Sympa::Logger::DEBUG, 'Spool::unlock_message(%s,%s)',$self->{name}, $messagekey);
#    return ( $self->update({'messagekey' => $messagekey},
#			   {'messagelock' => 'NULL'}));
#}

sub update {
    croak 'Not implemented yet';
}

=item $spool->store($string, $param)

Store a new entry in the spool.

=cut

sub store {
    my ($self, $string, $param) = @_;
    my $target_file = $param->{'filename'} || $self->_get_file_name($param);

    if (!$target_file) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unsufficient parameters provided to create file name'
        );
        return undef;
    }

    my $fh;
    unless (open $fh, ">", "$self->{directory}/$target_file") {
        $main::logger->do_log(Sympa::Logger::ERR, 'Unable to write file to spool %s',
            $self->{directory});
        return undef;
    }
    print $fh $string;
    close $fh;
    return 1;
}

=item $spool->remove($key)

Remove an entry from the spool.

=cut

sub remove {
    my $self = shift;
    my $key  = shift;

    unless (unlink $self->{directory} . '/' . $key) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to remove file %s: %s',
            $self->{directory} . '/' . $key, $ERRNO
        );
        return undef;
    }
    return 1;
}

=item $spool->clean($delay)

Clean the spool by removing old entries.

=cut

sub clean {
    my $self  = shift;
    my $delay = shift;
    $main::logger->do_log(
        Sympa::Logger::DEBUG, 'Cleaning spool %s (%s), delay: %s',
        $self->{name}, $self->{status},
        $delay
    );

    return undef unless $delay;

    my $freshness_date = time - ($delay * 60 * 60 * 24);
    my $deleted = 0;

    my @to_kill = $self->get_files_in_spool;
    foreach my $f (@to_kill) {
        if ((stat "$self->{directory}/$f")[9] < $freshness_date) {
            if (unlink("$self->{directory}/$f")) {
                $deleted++;
                $main::logger->do_log(Sympa::Logger::NOTICE, 'Deleting old file %s',
                    "$self->{directory}/$f");
            } else {
                $main::logger->do_log(Sympa::Logger::NOTICE,
                    'unable to delete old file %s: %s',
                    "$self->{directory}/$f", $ERRNO);
            }
        } else {
            last;
        }
    }
    @to_kill = $self->get_dirs_in_spool;
    foreach my $d (@to_kill) {
        if ((stat "$self->{directory}/$d")[9] < $freshness_date) {
            if (Sympa::Tools::File::remove_dir("$self->{directory}/$d")) {
                $deleted++;
                $main::logger->do_log(Sympa::Logger::NOTICE, 'Deleting old file %s',
                    "$self->{directory}/$d");
            } else {
                $main::logger->do_log(Sympa::Logger::NOTICE,
                    'unable to delete old file %s: %s',
                    "$self->{directory}/$d", $ERRNO);
            }
        } else {
            last;
        }
    }

    $main::logger->do_log(Sympa::Logger::DEBUG,
        "%s entries older than %s days removed from spool %s",
        $deleted, $delay, $self->{name});
    return 1;
}

sub _perlselector {
    my $selector = shift || {};

    my ($comparator, $value, $perl_key);

    my @perl_clause = ();
    foreach my $criterium (keys %{$selector}) {
        if (ref($selector->{$criterium}) eq 'ARRAY') {
            ($value, $comparator) = @{$selector->{$criterium}};
            $comparator = 'eq' unless $comparator and $comparator eq 'ne';
        } else {
            ($value, $comparator) = ($selector->{$criterium}, 'eq');
        }

        $perl_key = sprintf '$item->{"%s"}', $criterium;

        push @perl_clause,
            sprintf '%s %s "%s"', $perl_key, $comparator, quotemeta $value;
    }

    return join ' and ', @perl_clause;
}

sub _perlcomparator {
    my $orderby = shift;
    my $way     = shift;

    return undef unless $orderby;

    if ($orderby eq 'date' or $orderby eq 'size') {
        if ($way and $way eq 'desc') {
            return sprintf '$b->{"%s"} <=> $a->{"%s"}', $orderby, $orderby;
        } else {
            return sprintf '$a->{"%s"} <=> $b->{"%s"}', $orderby, $orderby;
        }
    } else {
        if ($way and $way eq 'desc') {
            return sprintf '$b->{"%s"} cmp $a->{"%s"}', $orderby, $orderby;
        } else {
            return sprintf '$a->{"%s"} cmp $b->{"%s"}', $orderby, $orderby;
        }
    }
}

=back

=cut

1;
