# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

=encoding utf-8

=head1 NAME

Sympa::Marc - FIXME

=head1 DESCRIPTION

FIXME

=cut

package Sympa::Marc;

use strict;

use Carp qw(croak);

use Sympa::Logger;

our $AUTOLOAD;
our $VERSION = "4.3";

##------------------------------------------------------------------------##
## Constructor

sub new {
    my $class      = shift;
    my $fields_ref = shift;
    my $self       = {
        directory_labels => {},
        permitted        => $fields_ref,
        sort_function    => 'sub { $a cmp $b }',
        %$fields_ref,
    };
    $self->{permitted}->{sort_function} = 'sub { $a cmp $b }';
    bless $self, $class;
    return $self;
}

##------------------------------------------------------------------------##
## The AUTOLOAD function allows for the dynamic creation of accessor methods

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";
    my $name = $AUTOLOAD;

    # DESTROY messages should never be propagated.
    return if $name =~ /::DESTROY$/;

    # Remove the package name.
    $name =~ s/^.*://;

    unless (exists($self->{permitted}->{$name})) {
        message('arcsearch_marc_autoload_no_access');
        wwslog(Sympa::Logger::INFO,
            'arcsearch_marc: Can not access %s field in object of class %s',
            $name, $type);
        return undef;
    }
    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

1;
