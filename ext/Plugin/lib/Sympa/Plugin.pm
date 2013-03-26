package Sympa::Plugin;
use warnings;
use strict;

use Sympa::Plugin::Util qw/:functions/;

# FIXME: clean interface needed for these:
use tt2;
*wwslog = \&main::wwslog;

=head1 NAME

Sympa::Plugin - add plugin system to Sympa

=head1 SYNOPSIS

  # in the main program
  use Sympa::Plugins;
  Sympa::Plugins->load;

  # each plugin
  package Sympa::VOOT;  # example
  use parent 'Sympa::Plugin';

=head1 DESCRIPTION

In the Sympa system (version 6.2), each component has facts listed
all over the code.  This hinders a pluggable interface.  This module
implements a few tricky hacks to move towards accepting optional modules
which can get upgraded between major Sympa releases.

=head1 METHODS

=head2 Constructors

=head3 new OPTIONS
=cut

sub new(@)
{   my ($class, %args) = @_;
    (bless {}, $class)->init(\%args);
}

sub init($) {shift}


=head2 Plugin loader

The follow code is really tricky: it tries to separate the components
from the existing interface.

=head3 class method: register_plugin HASH

This method takes a HASH.  The supported keys are

over 4

=item C<url_commands> =E<gt> PAIRS

=item C<validate> =E<gt> PAIRS

=item C<templates> =E<gt> HASHES

=back

See the source of L<Sympa::VOOT> for an extended example.

=cut

sub register_plugin($)
{   my ($class, $args) = @_;

    if(my $url = $args->{url_commands})
    {   my @url = @$url;
        while(@url)
        {   my ($command, $settings) = (shift @url, shift @url);
            my $handler = $settings->{handler};

            $main::comm{$command} = sub
              { wwslog(info => "$command(@_)");
                $handler->
                  ( in       => \%main::in
                  , param    => $main::param
                  , session  => $main::session
                  , list     => $main::list
                  , robot_id => $main::robot_id
                  , @_
                  );
              };

            if(my $a = $settings->{path_args})
            {   $main::action_args{$command} = ref $a ? $a : [ $a ];
            }
            if(my $r = $settings->{required})
            {   $main::required_args{$command} = ref $r ? $r : [ $r ];
            }
	    if(my $p = $settings->{privilege})
            {   # default is 'everybody'
                $main::required_privileges{$command} = ref $p ? $p : [$p];
            }
        }
    }
    if(my $val = $args->{validate})
    {   my @val = @$val;
        while(@val)
        {   my $param = shift @val;
            $main::in_regexp{$param} = shift @val;
        }
    }

    if(my $templ = $args->{templates})
    {   $main::plugins->add_templates(%$_)
            for ref $templ ? @$templ : $templ;
    }

    # Add info to listdef.pm table.  This can be made simpler with some
    # better defaults in listdef.pm itself.
    if(my $form = $args->{listdef})
    {   my @form = @$form;
        while(@form)
        {   my ($header, $fields) = (shift @form, shift @form);
            my $format = $fields->{format};
            if(ref $format eq 'ARRAY')
            {   # for convenience: automatically add 'order' when the
                # format is passed as ARRAY
                my %h;
                my @format = @$format;
                while(@format)
                {   my ($field, $def) = (shift @format, shift @format);
                    $def->{order} = keys(%h) + 1;
                    $h{$field}    = $def;
                }
                $format = $fields->{format} = \%h;
            }

            # for convenience, default occurence==1
            $_->{occurrent} ||= 1 for values %$format;

            $listdef::pinfo{$header} = $fields;
            $fields->{order} = @listdef::param_order;  # to late for init
            push @listdef::param_order, $header;
        }
    }
}

=head3 upgrade OPTIONS

Upgrade the information in the system.  Returned is the next version
for that information: you can better not make more than one step at
the time for the upgrade: we would like to update the plugin status
inbetween these steps.

=over 4

=item * I<from_version> =E<gt> VERSION

=back

=cut

sub upgrade(%)
{   my ($self, %args) = @_;
    my $from = $args{from_version};

    my $upgrade_class = ref($self) . "::Upgrade";
    eval "require $upgrade_class"
        or fatal "cannot upgrade via $upgrade_class: $@";

    return $upgrade_class->upgrade(from => $from, to => $self->VERSION)
        if $from;

    # First run
    $upgrade_class->setup;
    $self->VERSION;
}

1;
