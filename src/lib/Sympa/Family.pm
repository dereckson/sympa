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

Sympa::Family - A mailing-list family

=head1 DESCRIPTION 

A family is a set of mailing-list sharing common properties, to allow creation
and management of multiple lists at once.

=cut 

package Sympa::Family;

use strict;
use base qw(Sympa::ConfigurableObject);

use Carp qw(croak);
use English qw(-no_match_vars);
use File::Copy;
use Scalar::Util qw(blessed);
use Term::ProgressBar;
use XML::LibXML;

use Sympa::Admin;
use Sympa::Constants;
use Sympa::Config_XML;
use Sympa::List; # FIXME: circular dependency
use Sympa::Logger;
use Sympa::VirtualHost;
use Sympa::Site;

my @uncompellable_param = (
    'msg_topic.keywords',
    'owner_include.source_parameters',
    'editor_include.source_parameters'
);

=head1 CLASS METHODS 

=over

=item Sympa::Family->get_available_families($robot)

Returns the list of existing families in the Sympa installation.

Arguments:

=over 

=item * I<$robot>, the robot the family list of which we want to get.

=back 

Return a list of all the robot's families names.

=cut

sub get_families {
    my $robot = shift;

    croak "missing 'robot' parameter" unless $robot;
    croak "invalid 'robot' parameter" unless
        (blessed $robot and $robot->isa('Sympa::VirtualHost'));

    my @families;

    foreach my $dir (reverse @{$robot->get_etc_include_path('families')}) {
        next unless -d $dir;

        unless (opendir FAMILIES, $dir) {
            $main::logger->do_log(Sympa::Logger::ERR, "error : can't open dir %s: %s",
                $dir, $ERRNO);
            next;
        }

        ## If we can create a Sympa::Family object with what we find in the family
        ## directory, then it is worth being added to the list.
        foreach my $subdir (grep !/^\.\.?$/, readdir FAMILIES) {
            next unless -d ("$dir/$subdir");
            if (my $family = Sympa::Family->new($subdir, $robot)) {
                push @families, $family;
            }
        }
    }

    return \@families;
}

sub get_available_families {
    my $robot_id = shift;
    my $families;
    my %hash;
    if ($families = get_families($robot_id)) {
        foreach my $family (@$families) {
            if (ref $family eq 'Sympa::Family') {
                $hash{$family->name} = $family;
            }
        }
        return %hash;
    } else {
        return undef;
    }
}

=item Sympa::Family->new($name, $robot)

Creates a new Sympa::Family object of name $name, belonging to the robot $robot.

Arguments 

=over 

=item * I<$name>, a character string containing the family name,

=item * I<$robot>, a Robot object representing robot which the family is/will be installed in.

=back 

Return the Sympa::Family object 

=cut

sub new {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s)', @_);

    ## NOTICE: Don't use accessors like "$self->dir" but "$self->{'dir'}",
    ## since the object has not been fully initialized yet.

    my $class = shift;
    my $name  = shift;
    my $robot = shift;
    croak "missing 'robot' parameter" unless $robot;
    croak "invalid 'robot' parameter" unless
        (blessed $robot and $robot->isa('Sympa::VirtualHost'));

    my $self = {};

    if ($robot->families($name)) {

        # use the current family in memory and update it
        $self = $robot->families($name);
###########
        # the robot can be different from latest new ...
        if ($robot->domain eq $self->domain) {
            return $self;
        } else {
            $self = {};
        }
    }

    # create a new object family
    bless $self, $class;

    my $family_name_regexp = Sympa::Tools::get_regexp('family_name');

    ## family name
    unless ($name && ($name =~ /^$family_name_regexp$/io)) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Incorrect family name "%s"',
            $name);
        return undef;
    }

    ## Lowercase the family name.
    $name = lc $name;
    $self->{'name'} = $name;

    $self->{'robot'} = $robot->domain;

    ## Adding configuration related to automatic lists.
    my $all_families_config = $robot->automatic_list_families;
    my $family_config       = $all_families_config->{$name};
    foreach my $key (keys %{$family_config}) {
        $self->{$key} = $family_config->{$key};
    }

    ## family directory
    $self->{'dir'} = $self->_get_directory();
    unless (defined $self->{'dir'}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'the family directory %s does not exist',
            $self->{'dir'});
        return undef;
    }

    ## family files
    if (my $file_names = $self->_check_mandatory_files()) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Definition family files are missing : %s', $file_names);
        return undef;
    }

    ## file mtime
    $self->{'mtime'}{'param_constraint_conf'} = undef;

    ## hash of parameters constraint
    $self->{'param_constraint_conf'} = undef;

    ## state of the family for the use of check_param_constraint : 'no_check'
    ## or 'normal'
    ## check_param_constraint  only works in state "normal"
    $self->{'state'} = 'normal';
    $robot->families($name, $self);
    return $self;
}

=back

=head1 INSTANCE METHODS 

=over

=item $family->get_id()

Get unique identifier of family.

=cut

sub get_id {
    my $self = shift;

    ## DO NOT use accessors on Sympa::Family object since $self may not have been
    ## fully initialized.

    return '' unless $self->{'name'} and $self->{'robot'};
    return sprintf '%s@%s',
        $self->{'name'}, Sympa::VirtualHost->new($self->{'robot'})->get_id;
}

=item $family->get_etc_filename()

See L<Site/get_etc_filename>.

=item $family->get_etc_include_path()

See L<Site/get_etc_include_path>.

=item $family->domain()

Gets name attribute.

=cut

=item $family->dir()

Gets dir attribute.

=cut

sub dir {
    shift->{'dir'};
}

sub domain {
    shift->{'robot'};
}

=item $family->name()

Gets name attribute.

=cut

sub name {
    shift->{'name'};
}

=item $family->robot()

Gets robot attribute.

=cut

sub robot {
    Sympa::VirtualHost->new(shift->domain);
}

=item $family->state()

Gets or sets state attribute.

=cut

sub state {
    my $self = shift;
    if (scalar @_) {
        $self->{'state'} = shift;
    }
    $self->{'state'};
}

=item $family->add_list($data, $abort_on_error)

Adds a list to the family. List description can be passed either through a hash of data or through a file handle.

Arguments 

=over 

=item * I<$data>: a file handle on an XML list description file or a hash of data,

=item * I<$abort_on_error>: if true, the function won't create lists in status error_config.

=back 

Return a hash containing the execution state of the method. If everything went well, the "ok" key must be associated to the value "1".

=cut

sub add_list {
    my ($self, $data, $abort_on_error) = @_;

    $main::logger->do_log(Sympa::Logger::INFO, 'Sympa::Family::add_list(%s)', $self);

    $self->state('no_check');
    my $return;
    $return->{'ok'}           = undef;
    $return->{'string_info'}  = undef;    ## info and simple errors
    $return->{'string_error'} = undef;    ## fatal errors

    my $hash_list;

    if (ref($data) eq "HASH") {
        $hash_list = {config => $data};
    } else {

        #copy the xml file in another file
        unless (open(FIC, '>', $self->dir . '/_new_list.xml')) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'impossible to create the temp file %s/_new_list.xml : %s',
                $self->dir, $ERRNO);
        }
        while (<$data>) {
            print FIC ($_);
        }
        close FIC;

        # get list data
        open(FIC, '<:raw', $self->dir . '/_new_list.xml');
        my $config = Sympa::Config_XML->new(\*FIC);
        close FIC;
        unless (defined $config->createHash()) {
            push @{$return->{'string_error'}},
                "Error in representation data with these XML data";
            return $return;
        }

        $hash_list = $config->getHash();
    }

    #list creation
    my $result = Sympa::Admin::create_list($hash_list->{'config'},
        $self, $self->{'robot'}, $abort_on_error);
    unless (defined $result) {
        push @{$return->{'string_error'}},
            "Error during list creation, see logs for more information";
        return $return;
    }
    unless (defined $result->{'list'}) {
        push @{$return->{'string_error'}},
            "Errors : no created list, see logs for more information";
        return $return;
    }
    my $list = $result->{'list'};

    ## aliases
    if ($result->{'aliases'} == 1) {
        push @{$return->{'string_info'}},
            sprintf('List %s has been created in family %s',
            $list->name, $self->name);
    } else {
        push @{$return->{'string_info'}},
            sprintf(
            'List %s has been created in family %s, required aliases : %s',
            $list->name, $self->name, $result->{'aliases'});
    }

    # config_changes
    unless (open FILE, '>', $list->dir . '/config_changes') {
        $list->set_status_error_config('error_copy_file', $self->name);
        push @{$return->{'string_info'}},
            sprintf(
            'Impossible to create file %s/config_changes : %s, the list is set in status error_config',
            $list->dir, $ERRNO);
    }
    close FILE;

    my $host = $self->robot->host;

    # info parameters
    $list->latest_instantiation(
        {   'email' => "listmaster\@$host",
            ##FIXME:should be unneccessary
            'date' => $main::language->gettext_strftime(
                "%d %b %Y at %H:%M:%S", localtime time
            ),
            'date_epoch' => time
        }
    );
    $list->save_config("listmaster\@$host");
    $list->family($self);

    ## check param_constraint.conf
    $self->state('normal');
    my $error = $self->check_param_constraint($list);
    $self->state('no_check');

    unless (defined $error) {
        $list->set_status_error_config('no_check_rules_family', $self->name);
        push @{$return->{'string_error'}},
            "Impossible to check parameters constraint, see logs for more information. The list is set in status error_config";
        return $return;
    }

    if (ref($error) eq 'ARRAY') {
        $list->set_status_error_config('no_respect_rules_family',
            $self->name);
        push @{$return->{'string_info'}},
            "The list does not respect the family rules : "
            . join(", ", @{$error});
    }

    ## copy files in the list directory : xml file
    unless (ref($data) eq "HASH") {
        unless ($self->_copy_files($list->dir, "_new_list.xml")) {
            $list->set_status_error_config('error_copy_file', $self->name);
            push @{$return->{'string_info'}},
                "Impossible to copy the XML file in the list directory, the list is set in status error_config.";
        }
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $main::logger->do_log(Sympa::Logger::NOTICE, "Synchronizing list members...");
        $list->sync_include();
    }

    ## END
    $self->state('normal');
    $return->{'ok'} = 1;

    return $return;
}

=item $family->modify_list($handle)

Arguments 

=over 

=item * I<$handle>: a file handle on the list configuration file.

=back 

Return a ref to a hash containing the execution state of the method. If everything went well, the "ok" key must be associated to the value "1".

=cut

sub modify_list {
    my $self = shift;
    my $fh   = shift;
    $main::logger->do_log(Sympa::Logger::INFO, 'Sympa::Family::modify_list(%s)',
        $self->name);

    $self->state('no_check');
    my $return;
    $return->{'ok'}           = undef;
    $return->{'string_info'}  = undef;    ## info and simple errors
    $return->{'string_error'} = undef;    ## fatal errors

    #copy the xml file in another file
    unless (open(FIC, '>', $self->dir . '/_mod_list.xml')) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'impossible to create the temp file %s/_mod_list.xml : %s',
            $self->dir, $ERRNO);
    }
    while (<$fh>) {
        print FIC ($_);
    }
    close FIC;

    # get list data
    open(FIC, '<:raw', $self->dir . '/_mod_list.xml');
    my $config = Sympa::Config_XML->new(\*FIC);
    close FIC;
    unless (defined $config->createHash()) {
        push @{$return->{'string_error'}},
            "Error in representation data with these XML data";
        return $return;
    }

    my $hash_list = $config->getHash();

    #getting list
    my $list;
    unless ($list =
        Sympa::List->new($hash_list->{'config'}{'listname'}, $self->robot)) {
        push @{$return->{'string_error'}},
            "The list $hash_list->{'config'}{'listname'} does not exist.";
        return $return;
    }

    ## check family name
    if (defined $list->family_name) {
        unless ($list->family_name eq $self->name) {
            push @{$return->{'string_error'}},
                sprintf('The list %s already belongs to family %s.',
                $list->name, $list->family_name);
            return $return;
        }
    } else {
        push @{$return->{'string_error'}},
            sprintf('The orphan list %s already exists.', $list->name);
        return $return;
    }

    ## get allowed and forbidden list customizing
    my $custom = $self->_get_customizing($list);
    unless (defined $custom) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'impossible to get list %s customizing', $list);
        push @{$return->{'string_error'}},
            sprintf(
            'Error during updating list %s, the list is set in status error_config.',
            $list->name);
        $list->set_status_error_config('modify_list_family', $self->name);
        return $return;
    }
    my $config_changes = $custom->{'config_changes'};
    my $old_status     = $list->status;

    ## list config family updating
    my $result = Sympa::Admin::update_list($list, $hash_list->{'config'},
        $self, $self->{'robot'});
    unless (defined $result) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'No object list resulting from updating list %s', $list);
        push @{$return->{'string_error'}},
            "Error during updating list $list->name, the list is set in status error_config.";
        $list->set_status_error_config('modify_list_family', $self->name);
        return $return;
    }
    $list = $result;

    ## set list customizing
    foreach my $p (keys %{$custom->{'allowed'}}) {
        $list->$p($custom->{'allowed'}{$p});
        $list->defaults($p, undef);
        $main::logger->do_log(Sympa::Logger::INFO,
            'Customizing : keeping values for parameter %s', $p);
    }

    ## info file
    unless ($config_changes->{'file'}{'info'}) {
        $hash_list->{'config'}{'description'} =~ s/\r\n|\r/\n/g;

        unless (open INFO, '>', $list->dir . '/info') {
            push @{$return->{'string_info'}},
                sprintf('Impossible to create new %s/info file : %s',
                $list->dir, $ERRNO);
        }
        print INFO $hash_list->{'config'}{'description'};
        close INFO;
    }

    foreach my $f (keys %{$config_changes->{'file'}}) {
        $main::logger->do_log(Sympa::Logger::INFO,
            "Customizing : this file has been changed : $f");
    }

    ## rename forbidden files
    #    foreach my $f (@{$custom->{'forbidden'}{'file'}}) {
    #	unless (rename ($list->dir."/"."info",$list->dir."/"."info.orig")) {
    ################
    #	}
    #	if ($f eq 'info') {
    #	    $hash_list->{'config'}{'description'} =~ s/\r\n|\r/\n/g;
    #	    unless (open INFO, '>', "$list_dir/info") {
    ################
    #	    }
    #	    print INFO $hash_list->{'config'}{'description'};
    #	    close INFO;
    #	}
    #    }

    ## notify owner for forbidden customizing
    if (    #(scalar $custom->{'forbidden'}{'file'}) ||
        (scalar @{$custom->{'forbidden'}{'param'}})
        ) {

        #	my $forbidden_files = join(',',@{$custom->{'forbidden'}{'file'}});
        my $forbidden_param = join(',', @{$custom->{'forbidden'}{'param'}});
        $main::logger->do_log(Sympa::Logger::NOTICE,
            "These parameters aren't allowed in the new family definition, they are erased by a new instantiation family : \n $forbidden_param"
        );

        unless (
            $list->send_notify_to_owner(
                'erase_customizing', [$self->name, $forbidden_param]
            )
            ) {
            $main::logger->do_log(
                Sympa::Logger::NOTICE,
                'the owner isn\'t informed from erased customizing of the list %s',
                $list
            );
        }
    }

    ## status
    $result = $self->_set_status_changes($list, $old_status);

    if ($result->{'aliases'} == 1) {
        push @{$return->{'string_info'}},
            sprintf('The %s list has been modified.', $list->name);

    } elsif ($result->{'install_remove'} eq 'install') {
        push @{$return->{'string_info'}},
            sprintf('List %s has been modified, required aliases :\n %s ',
            $list->name, $result->{'aliases'});

    } else {
        push @{$return->{'string_info'}},
            sprintf(
            'List %s has been modified, aliases need to be removed : \n %s',
            $list->name, $result->{'aliases'});

    }

    ## config_changes
    foreach my $p (@{$custom->{'forbidden'}{'param'}}) {

        if (defined $config_changes->{'param'}{$p}) {
            delete $config_changes->{'param'}{$p};
        }

    }

    unless (open FILE, '>', $list->dir . '/config_changes') {
        $list->set_status_error_config('error_copy_file', $self->name);
        push @{$return->{'string_info'}},
            sprintf(
            'Impossible to create file %s/config_changes : %s, the list is set in status error_config.',
            $list->dir, $ERRNO);
    }
    close FILE;

    my @kept_param = keys %{$config_changes->{'param'}};
    $list->update_config_changes('param', \@kept_param);
    my @kept_files = keys %{$config_changes->{'file'}};
    $list->update_config_changes('file', \@kept_files);

    my $host = $self->robot->host;

    $list->latest_instantiation(
        {   'email' => "listmaster\@$host",
            ##FIXME:should be unneccessary
            'date' => $main::language->gettext_strftime(
                "%d %b %Y at %H:%M:%S", localtime time
            ),
            'date_epoch' => time
        }
    );
    $list->save_config("listmaster\@$host");
    $list->family($self);

    ## check param_constraint.conf
    $self->state('normal');
    my $error = $self->check_param_constraint($list);
    $self->state('no_check');

    unless (defined $error) {
        $list->set_status_error_config('no_check_rules_family', $self->name);
        push @{$return->{'string_error'}},
            "Impossible to check parameters constraint, see logs for more information. The list is set in status error_config";
        return $return;
    }

    if (ref($error) eq 'ARRAY') {
        $list->set_status_error_config('no_respect_rules_family',
            $self->name);
        push @{$return->{'string_info'}},
            "The list does not respect the family rules : "
            . join(", ", @{$error});
    }

    ## copy files in the list directory : xml file

    unless ($self->_copy_files($list->dir, "_mod_list.xml")) {
        $list->set_status_error_config('error_copy_file', $self->name);
        push @{$return->{'string_info'}},
            "Impossible to copy the XML file in the list directory, the list is set in status error_config.";
    }

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $main::logger->do_log(Sympa::Logger::NOTICE, "Synchronizing list members...");
        $list->sync_include();
    }

    ## END
    $self->state('normal');
    $return->{'ok'} = 1;

    return $return;
}

=item $family->close_family()

Closes every list of the family.

Return a string describing the result.

=cut

sub close_family {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s)', @_);
    my $self = shift;

    my $family_lists = Sympa::List::get_lists($self);
    my @impossible_close;
    my @close_ok;

    foreach my $list (@{$family_lists}) {
        my $listname = $list->name;    #XXX FIXME
        unless (defined $list) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'The %s list belongs to %s family but the list does not exist',
                $listname,
                $self
            );
            next;
        }

        unless ($list->set_status_family_closed('close_list', $self->name)) {
            push(@impossible_close, $list->name);
            next;
        }
        push(@close_ok, $list->name);
    }
    my $string =
        "\n\n******************************************************************************\n";
    $string .= sprintf(
        "\n******************** CLOSURE of %s FAMILY ********************\n",
        $self->name);
    $string .=
        "\n******************************************************************************\n\n";

    unless ($#impossible_close < 0) {
        $string .= "\nImpossible list closure for : \n  "
            . join(", ", @impossible_close) . "\n";
    }

    $string .= "\n****************************************\n";

    unless ($#close_ok < 0) {
        $string .=
            "\nThese lists are closed : \n  " . join(", ", @close_ok) . "\n";
    }

    $string .=
        "\n******************************************************************************\n";

    return $string;
}

=item $family->instantiate($handle, $close_unknown)

Creates family lists or updates them if they exist already.

Arguments:

=over 

=item * I<$handle>: a file handle on the family XML file,

=item * I<$close_unknown>: if true, the function will close old lists undefined in the new instantiation.

=back 

Return a true value.

=cut

sub instantiate {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s)', @_);
    my $self          = shift;
    my $xml_file      = shift;
    my $close_unknown = shift;

    ## all the description variables are emptied.
    $self->_initialize_instantiation();

    ## set impossible checking (used by list->load)
    $self->state('no_check');

    ## get the currently existing lists in the family
    my $previous_family_lists =
        {(map { $_->name => $_ } @{Sympa::List::get_lists($self)})};

    ## Splits the family description XML file into a set of list description
    ## xml files
    ## and collects lists to be created in $self->{'list_to_generate'}.
    unless ($self->_split_xml_file($xml_file)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Errors during the parsing of family xml file');
        return undef;
    }

    my $created  = 0;
    my $total    = $#{@{$self->{'list_to_generate'}}} + 1;
    my $progress = Term::ProgressBar->new(
        {   name  => 'Creating lists',
            count => $total,
            ETA   => 'linear'
        }
    );
    $progress->max_update_rate(1);
    my $next_update = 0;
    my $aliasmanager_output_file =
        Sympa::Site->tmpdir . '/aliasmanager.stdout.' . $PID;
    my $output_file = Sympa::Site->tmpdir . '/instantiate_family.stdout.' . $PID;
    my $output      = '';

    ## EACH FAMILY LIST
    foreach my $listname (@{$self->{'list_to_generate'}}) {

        my $list = Sympa::List->new($listname, $self->{'robot'});

        ## get data from list XML file. Stored into $config (class
        ## Config_XML).
        my $xml_fh;
        open $xml_fh, '<:raw', $self->dir . "/" . $listname . ".xml";
        my $config = Sympa::Config_XML->new($xml_fh);
        close $xml_fh;
        unless (defined $config->createHash()) {
            push(
                @{$self->{'errors'}{'create_hash'}},
                $self->dir . "/$listname.xml"
            );
            if ($list) {
                $list->set_status_error_config('instantiation_family',
                    $self->name);
            }
            next;
        }

        ## stores the list config into the hash referenced by $hash_list.
        my $hash_list = $config->getHash();

        ## LIST ALREADY EXISTING
        if ($list) {

            delete $previous_family_lists->{$list->name};

            ## check family name
            if (defined $list->family_name) {
                unless ($list->family_name eq $self->name) {
                    push(
                        @{$self->{'errors'}{'listname_already_used'}},
                        $list->name
                    );
                    $main::logger->do_log(Sympa::Logger::ERR,
                        'The list %s already belongs to family %s',
                        $list, $list->family_name);
                    next;
                }
            } else {
                push(
                    @{$self->{'errors'}{'listname_already_used'}},
                    $list->name
                );
                $main::logger->do_log(Sympa::Logger::ERR,
                    'The orphan list %s already exists', $list);
                next;
            }

            ## Update list config
            my $result = $self->_update_existing_list($list, $hash_list);
            unless (defined $result) {
                push(@{$self->{'errors'}{'update_list'}}, $list->name);
                $list->set_status_error_config('instantiation_family',
                    $self->name);
                next;
            }
            $list = $result;

            ## FIRST LIST CREATION
        } else {

            ## Create the list
            my $result = Sympa::Admin::create_list($hash_list->{'config'},
                $self, $self->{'robot'});
            unless (defined $result) {
                push(
                    @{$self->{'errors'}{'create_list'}},
                    $hash_list->{'config'}{'listname'}
                );
                next;
            }
            unless (defined $result->{'list'}) {
                push(
                    @{$self->{'errors'}{'create_list'}},
                    $hash_list->{'config'}{'listname'}
                );
                next;
            }
            $list = $result->{'list'};

            ## aliases
            if ($result->{'aliases'} == 1) {
                push(@{$self->{'created_lists'}{'with_aliases'}},
                    $list->name);

            } else {
                $self->{'created_lists'}{'without_aliases'}{$list->name} =
                    $result->{'aliases'};
            }

            # config_changes
            unless (open FILE, '>', $list->dir . '/config_changes') {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Sympa::Family::instantiate : impossible to create file %s/config_changes : %s',
                    $list->dir,
                    $ERRNO
                );
                push(@{$self->{'generated_lists'}{'file_error'}},
                    $list->name);
                $list->set_status_error_config('error_copy_file',
                    $self->name);
            }
            close FILE;
        }

        ## ENDING : existing and new lists
        unless ($self->_end_update_list($list, 1)) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Instantiation stopped on list %s', $list);
            return undef;
        }
        $created++;
        $progress->message(
            sprintf(
                "List \"%s\" (%i/%i) created/updated",
                $list->name, $created, $total
            )
        );
        $next_update = $progress->update($created)
            if ($created > $next_update);

        if (-f $aliasmanager_output_file) {
            open OUT, $aliasmanager_output_file;
            while (<OUT>) {
                $output .= $_;
            }
            close OUT;
            unlink $aliasmanager_output_file; # remove file to catch next call
        }
    }

    $progress->update($total);

    if ($output && !$main::options{'quiet'}) {
        print STDOUT
            "There is unread output from the instantiation process (aliasmanager messages ...), do you want to see it ? (y or n)";
        my $answer = <STDIN>;
        chomp($answer);
        $answer ||= 'n';
        print $output if ($answer eq 'y');

        if (open OUT, '>' . $output_file) {
            print OUT $output;
            close OUT;
            print STDOUT "\nOutput saved in $output_file\n";
        } else {
            print STDERR "\nUnable to save output in $output_file\n";
        }
    }

    ## PREVIOUS LIST LEFT
    foreach my $l (keys %{$previous_family_lists}) {
        my $list;
        unless ($list = Sympa::List->new($l, $self->{'robot'})) {
            push(@{$self->{'errors'}{'previous_list'}}, $l);
            next;
        }

        my $answer;
        unless ($close_unknown) {

            #	while (($answer ne 'y') && ($answer ne 'n')) {
            print STDOUT
                "The list $l isn't defined in the new instantiation family, do you want to close it ? (y or n)";
            $answer = <STDIN>;
            chomp($answer);
#######################
            $answer ||= 'y';

            #}
        }
        if ($close_unknown || $answer eq 'y') {

            unless (
                $list->set_status_family_closed('close_list', $self->name)) {
                push(@{$self->{'family_closed'}{'impossible'}}, $list->name);
            }
            push(@{$self->{'family_closed'}{'ok'}}, $list->name);

        } else {
            ## get data from list xml file
            my $xml_fh;
            open $xml_fh, '<:raw', $list->dir . '/instance.xml';
            my $config = Sympa::Config_XML->new($xml_fh);
            close $xml_fh;
            unless (defined $config->createHash()) {
                push(
                    @{$self->{'errors'}{'create_hash'}},
                    $list->dir . '/instance.xml'
                );
                $list->set_status_error_config('instantiation_family',
                    $self->name);
                next;
            }
            my $hash_list = $config->getHash();

            my $result = $self->_update_existing_list($list, $hash_list);
            unless (defined $result) {
                push(@{$self->{'errors'}{'update_list'}}, $list->name);
                $list->set_status_error_config('instantiation_family',
                    $self->name);
                next;
            }
            $list = $result;

            unless ($self->_end_update_list($list, 0)) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Instantiation stopped on list %s', $list);
                return undef;
            }
        }
    }
    $self->state('normal');
    return 1;
}

=item $family->get_instantiation_results()

Returns a string with information summarizing the instantiation results.

Return a character string containing a message to display

=cut

sub get_instantiation_results {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s)', @_);
    my ($self, $result) = @_;

    $result->{'errors'} = ();
    $result->{'warn'}   = ();
    $result->{'info'}   = ();
    my $string;

    unless ($#{$self->{'errors'}{'create_hash'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list generation because errors in XML file for : \n  "
                . join(", ", @{$self->{'errors'}{'create_hash'}}) . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'create_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list creation for : \n  "
                . join(", ", @{$self->{'errors'}{'create_list'}}) . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'listname_already_used'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list creation because list name is already used (orphan list or in another family) for : \n  "
                . join(", ", @{$self->{'errors'}{'listname_already_used'}})
                . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'update_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list updating for : \n  "
                . join(", ", @{$self->{'errors'}{'update_list'}}) . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'previous_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nExisted lists from the latest instantiation impossible to get and not anymore defined in the new instantiation : \n  "
                . join(", ", @{$self->{'errors'}{'previous_list'}}) . "\n"
        );
    }

    # $string .= "\n****************************************\n";

    unless ($#{$self->{'created_lists'}{'with_aliases'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists have been created and aliases are ok :\n  "
                . join(", ", @{$self->{'created_lists'}{'with_aliases'}})
                . "\n"
        );
    }

    my $without_aliases = $self->{'created_lists'}{'without_aliases'};
    if (ref $without_aliases) {
        if (scalar %{$without_aliases}) {
            $string =
                "\nThese lists have been created but aliases need to be installed : \n";
            foreach my $l (keys %{$without_aliases}) {
                $string .= " $without_aliases->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    unless ($#{$self->{'updated_lists'}{'aliases_ok'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists have been updated and aliases are ok :\n  "
                . join(", ", @{$self->{'updated_lists'}{'aliases_ok'}}) . "\n"
        );
    }

    my $aliases_to_install = $self->{'updated_lists'}{'aliases_to_install'};
    if (ref $aliases_to_install) {
        if (scalar %{$aliases_to_install}) {
            $string =
                "\nThese lists have been updated but aliases need to be installed : \n";
            foreach my $l (keys %{$aliases_to_install}) {
                $string .= " $aliases_to_install->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    my $aliases_to_remove = $self->{'updated_lists'}{'aliases_to_remove'};
    if (ref $aliases_to_remove) {
        if (scalar %{$aliases_to_remove}) {
            $string =
                "\nThese lists have been updated but aliases need to be removed : \n";
            foreach my $l (keys %{$aliases_to_remove}) {
                $string .= " $aliases_to_remove->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    # $string .= "\n****************************************\n";

    unless ($#{$self->{'generated_lists'}{'file_error'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nThese lists have been generated but they are in status error_config because of errors while creating list config files :\n  "
                . join(", ", @{$self->{'generated_lists'}{'file_error'}})
                . "\n"
        );
    }

    my $constraint_error = $self->{'generated_lists'}{'constraint_error'};
    if (ref $constraint_error) {
        if (scalar %{$constraint_error}) {
            $string =
                "\nThese lists have been generated but there are in status error_config because of errors on parameter constraint :\n";
            foreach my $l (keys %{$constraint_error}) {
                $string .= " $l : " . $constraint_error->{$l} . "\n";
            }
            push(@{$result->{'errors'}}, $string);
        }
    }

    # $string .= "\n****************************************\n";

    unless ($#{$self->{'family_closed'}{'ok'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists don't belong anymore to the family, they are in status family_closed :\n  "
                . join(", ", @{$self->{'family_closed'}{'ok'}}) . "\n"
        );
    }

    unless ($#{$self->{'family_closed'}{'impossible'}} < 0) {
        push(
            @{$result->{'warn'}},
            "\nThese lists don't belong anymore to the family, but they can't be set in status family_closed :\n  "
                . join(", ", @{$self->{'family_closed'}{'impossible'}}) . "\n"
        );
    }

    unshift @{$result->{'errors'}},
        sprintf(
        "\n********** ERRORS IN INSTANTIATION of %s FAMILY ********************\n",
        $self->name)
        if $#{$result->{'errors'}} > 0;
    unshift @{$result->{'warn'}},
        sprintf(
        "\n********** WARNINGS IN INSTANTIATION of %s FAMILY ********************\n",
        $self->name)
        if $#{$result->{'warn'}} > 0;
    unshift @{$result->{'info'}},
        sprintf(
        "\n\n******************************************************************************\n"
            . "\n******************** INSTANTIATION of %s FAMILY ********************\n"
            . "\n******************************************************************************\n\n",
        $self->name
        );

    return $#{$result->{'errors'}};

}

=item $family->check_param_constraint($list)

Checks the parameter constraints taken from param_constraint.conf file for the
List object $list.

Arguments 

=over 

=item * I<$list>: a list

=back 

Return:

=over 

=item * I<1> if everything goes well,

=item * I<undef> if something goes wrong,

=item * I<\@error>, a ref on an array containing parameters conflicting with constraints.

=back 

=cut

sub check_param_constraint {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $self = shift;
    my $list = shift;

    if ($self->state eq 'no_check') {
        return 1;

        # because called by load(called by new that is called by instantiate)
        # it is not yet the time to check param constraint,
        # it will be called later by instantiate
    }

    my @error;

    ## checking
    my $constraint = $self->get_constraints();
    unless (defined $constraint) {
        $main::logger->do_log(Sympa::Logger::ERR, 'unable to get family constraints');
        return undef;
    }
    foreach my $param (keys %{$constraint}) {
        my $constraint_value = $constraint->{$param};
        my $param_value;
        my $value_error;

        unless (defined $constraint_value) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'No value constraint on parameter %s in param_constraint.conf',
                $param
            );
            next;
        }

        $param_value = $list->get_param_value($param);

        # exception for uncompellable parameter
        foreach my $forbidden (@uncompellable_param) {
            if ($param eq $forbidden) {
                next;
            }
        }

        $value_error = $self->check_values($param_value, $constraint_value);

        if (ref($value_error)) {
            foreach my $v (@{$value_error}) {
                push(@error, $param);
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Error constraint on parameter %s, value : %s',
                    $param, $v);
            }
        }
    }

    if (scalar @error) {
        return \@error;
    } else {
        return 1;
    }
}

=item $family->get_constraints()

Returns a hash containing the values found in the param_constraint.conf file.

Return ah hash containing the values found in the param_constraint.conf file

=cut

sub get_constraints {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s)', @_);
    my $self = shift;

    ## load param_constraint.conf
    my $time_file = (stat($self->dir . '/param_constraint.conf'))[9];
    unless ((defined $self->{'param_constraint_conf'})
        && ($self->{'mtime'}{'param_constraint_conf'} >= $time_file)) {
        $self->{'param_constraint_conf'} =
            $self->_load_param_constraint_conf();
        unless (defined $self->{'param_constraint_conf'}) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Cannot load file param_constraint.conf ');
            return undef;
        }
        $self->{'mtime'}{'param_constraint_conf'} = $time_file;
    }

    return $self->{'param_constraint_conf'};
}

=item $family>check_values($param, $constraint)

Returns 0 if all the value(s) found in $param_value appear also in $constraint_value. Otherwise the function returns an array containing the unmatching values.

Arguments:

=over 

=item * I<$param>: a scalar or a ref to a list (which is also a scalar after all)

=item * I<$constraint>: a scalar or a ref to a list

=back 

Return a ref to an array containing the values in $param_value which don't match those in $constraint_value.

=cut

sub check_values {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, ...)', @_);
    my ($self, $param_value, $constraint_value) = @_;

    my @param_values;
    my @error;

    # just in case
    if ($constraint_value eq '0') {
        return [];
    }

    if (ref($param_value) eq 'ARRAY') {
        @param_values = @{$param_value};    # for multiple parameters
    } else {
        push @param_values, $param_value;    # for single parameters
    }

    foreach my $p_val (@param_values) {

        ## multiple values
        if (ref($p_val) eq 'ARRAY') {

            foreach my $p (@{$p_val}) {
                ## controlled parameter
                if (ref($constraint_value) eq 'HASH') {
                    unless ($constraint_value->{$p}) {
                        push(@error, $p);
                    }
                    ## fixed parameter
                } else {
                    unless ($constraint_value eq $p) {
                        push(@error, $p);
                    }
                }
            }
            ## single value
        } else {
            ## controlled parameter
            if (ref($constraint_value) eq 'HASH') {
                unless ($constraint_value->{$p_val}) {
                    push(@error, $p_val);
                }
                ## fixed parameter
            } else {
                unless ($constraint_value eq $p_val) {
                    push(@error, $p_val);
                }
            }
        }
    }

    return \@error;
}

=item $family->get_param_constraint($param)

Gets the constraints defined for a parameter in the 'param_constraint.conf'
file.

Arguments:

=over 

=item * I<$param>: parameter name

=back 

Return:

=over 

=item * I<0> if there are no constraints on the parameter,

=item * a scalar containing the allowed value if the parameter has a fixed
value,

=item * an hashref containing the allowed values if the parameter is controlled,

=item * I<undef> if something went wrong.

=back 

=cut

sub get_param_constraint {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s)', @_);
    my $self  = shift;
    my $param = shift;

    unless (defined $self->get_constraints()) {
        return undef;
    }

    if (defined $self->{'param_constraint_conf'}{$param}) {
        ## fixed or controlled parameter
        return $self->{'param_constraint_conf'}{$param};

    } else {    ## free parameter
        return '0';
    }
}

=item $family->get_uncompellable_param()

Gets the uncompellable parameters.

Return an hashref whose keys are the uncompellable parameters names.

=cut

sub get_uncompellable_param {
    my %list_of_param;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'Sympa::Family::get_uncompellable_param()');

    foreach my $param (@uncompellable_param) {
        if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
            $list_of_param{$1} = $2;

        } else {
            $list_of_param{$param} = '';
        }
    }

    return \%list_of_param;
}

# $family->_get_directory()
# Gets the family directory, look for it in the robot, then in the site and
# finally in the distrib.
# Return the family directory name
sub _get_directory {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s)', @_);
    my $self  = shift;
    my $robot = $self->{'robot'};
    my $name  = $self->name;

    my @try = (
        Sympa::Site->etc . "/$robot/families",
        Sympa::Site->etc . "/families",
        Sympa::Constants::DEFAULTDIR . "/families"
    );

    foreach my $d (@try) {
        if (-d "$d/$name") {
            return "$d/$name";
        }
    }
    return undef;
}

# $family->_check_mandatory_files()
# Checks the existence of the mandatory files (param_constraint.conf and
# config.tt2) in the family directory.
# Return the missing file(s)' name(s), separated by white spaces.
sub _check_mandatory_files {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s)', @_);
    my $self   = shift;
    my $dir    = $self->dir;
    my $string = "";

    foreach my $f ('config.tt2') {
        unless (-f "$dir/$f") {
            $string .= $f . " ";
        }
    }

    if ($string eq "") {
        return 0;
    } else {
        return $string;
    }
}

# $family->_initialize_instantiation()
# Initializes all the values used for instantiation and results description to
# empty values.
# Return 1
sub _initialize_instantiation() {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s)', @_);
    my $self = shift;

    ### info vars for instantiate  ###
    ### returned by                ###
    ### get_instantiation_results  ###

    ## array of list to generate
    $self->{'list_to_generate'} = ();

    ## lists in error during creation or updating : LIST FATAL ERROR
    # array of xml file name  : error during xml data extraction
    $self->{'errors'}{'create_hash'} = ();
    ## array of list name : error during list creation
    $self->{'errors'}{'create_list'} = ();
    ## array of list name : error during list updating
    $self->{'errors'}{'update_list'} = ();
    ## array of list name : listname already used (in another family)
    $self->{'errors'}{'listname_already_used'} = ();
    ## array of list name : previous list impossible to get
    $self->{'errors'}{'previous_list'} = ();

    ## created or updated lists
    ## array of list name : aliases are OK (installed or not, according to
    ## status)
    $self->{'created_lists'}{'with_aliases'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $self->{'created_lists'}{'without_aliases'} = {};
    ## array of list name : aliases are OK (installed or not, according to
    ## status)
    $self->{'updated_lists'}{'aliases_ok'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $self->{'updated_lists'}{'aliases_to_install'} = {};
    ## hash of (list name -> aliases) : aliases needed to be removed
    $self->{'updated_lists'}{'aliases_to_remove'} = {};

    ## generated (created or updated) lists in error : no fatal error for the
    ## list
    ## array of list name : error during copying files
    $self->{'generated_lists'}{'file_error'} = ();
    ## hash of (list name -> array of param) : family constraint error
    $self->{'generated_lists'}{'constraint_error'} = {};

    ## lists isn't anymore in the family
    ## array of list name : lists in status family_closed
    $self->{'family_closed'}{'ok'} = ();
    ## array of list name : lists that must be in status family_closed but
    ## they aren't
    $self->{'family_closed'}{'impossible'} = ();

    return 1;
}

# $family->_split_xml_file($fh)
# Splits the XML family file into XML list files. New list names are put in the
# array referenced by $self->{'list_to_generate'} and new files are put in the
# family directory.
# Arguments:
# * $handle: a file handle to the XML description file
# Return a true value if everything goes well, false otherwise
sub _split_xml_file {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $self     = shift;
    my $xml_file = shift;
    my $root;

    ## parse file
    my $parser = XML::LibXML->new();
    $parser->line_numbers(1);
    my $doc;

    unless ($doc = $parser->parse_file($xml_file)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            "Sympa::Family::_split_xml_file() : failed to parse XML file");
        return undef;
    }

    ## the family document
    $root = $doc->documentElement();
    unless ($root->nodeName eq 'family') {
        $main::logger->do_log(Sympa::Logger::ERR,
            "Sympa::Family::_split_xml_file() : the root element must be called \"family\" "
        );
        return undef;
    }

    ## lists : family's elements
    foreach my $list_elt ($root->childNodes()) {

        if ($list_elt->nodeType == 1) {    # ELEMENT_NODE
            unless ($list_elt->nodeName eq 'list') {
                $main::logger->do_log(
                    Sympa::Logger::ERR,
                    'Sympa::Family::_split_xml_file() : elements contained in the root element must be called "list", line %s',
                    $list_elt->line_number()
                );
                return undef;
            }
        } else {
            next;
        }

        ## listname
        my @children = $list_elt->getChildrenByTagName('listname');

        if ($#children < 0) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Sympa::Family::_split_xml_file() : "listname" element is required in "list" element, line : %s',
                $list_elt->line_number()
            );
            return undef;
        }
        if ($#children > 0) {
            my @error;
            foreach my $i (@children) {
                push(@error, $i->line_number());
            }
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Sympa::Family::_split_xml_file() : Only one "listname" element is allowed for "list" element, lines : %s',
                join(", ", @error)
            );
            return undef;
        }
        my $listname_elt = shift @children;
        my $listname     = $listname_elt->textContent();
        $listname =~ s/^\s*//;
        $listname =~ s/\s*$//;
        $listname = lc $listname;
        my $filename = $listname . ".xml";

        ## creating list XML document
        my $list_doc =
            XML::LibXML::Document->createDocument($doc->version(),
            $doc->encoding());
        $list_doc->setDocumentElement($list_elt);

        ## creating the list xml file
        unless ($list_doc->toFile($self->dir . "/$filename", 0)) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Sympa::Family::_split_xml_file() : cannot create list file %s',
                $self->dir . '/' . $filename,
                $list_elt->line_number()
            );
            return undef;
        }

        push(@{$self->{'list_to_generate'}}, $listname);
    }
    return 1;
}

# $family->_update_existing_list($list, $hash)
# Updates an already existing list in the new family context
# Arguments:
# * $list: the list to update
# * $hash: an hashref containing data to create the list config file.
# Return the updated List object, if everything goes well, undef otherwise
sub _update_existing_list {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s, %s)', @_);
    my ($self, $list, $hash_list) = @_;

    ## get allowed and forbidden list customizing
    my $custom = $self->_get_customizing($list);
    unless (defined $custom) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'impossible to get list %s customizing', $list);
        return undef;
    }
    my $config_changes = $custom->{'config_changes'};
    my $old_status     = $list->status;

    ## list config family updating
    my $result = Sympa::Admin::update_list($list, $hash_list->{'config'},
        $self, $self->{'robot'});
    unless (defined $result) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'No object list resulting from updating list %s', $list);
        return undef;
    }
    $list = $result;

    ## set list customizing
    foreach my $p (keys %{$custom->{'allowed'}}) {
        $list->$p($custom->{'allowed'}{$p});
        $list->defaults($p, undef);
        $main::logger->do_log(Sympa::Logger::INFO,
            'Customizing : keeping values for parameter %s', $p);
    }

    ## info file
    unless ($config_changes->{'file'}{'info'}) {
        $hash_list->{'config'}{'description'} =~ s/\r\n|\r/\n/g;

        unless (open INFO, '>', $list->dir . '/info') {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Impossible to open %s/info : %s',
                $list->dir, $ERRNO);
        }
        print INFO $hash_list->{'config'}{'description'};
        close INFO;
    }

    foreach my $f (keys %{$config_changes->{'file'}}) {
        $main::logger->do_log(Sympa::Logger::INFO,
            'Customizing : this file has been changed : %s', $f);
    }

    ## rename forbidden files
    #    foreach my $f (@{$custom->{'forbidden'}{'file'}}) {
    #	unless (rename ($list->dir . "/"."info", $list->dir ."/"."info.orig")) {
    ################
    #	}
    #	if ($f 'info') {
    #	    $hash_list->{'config'}{'description'} =~ s/\r\n|\r/\n/g;
    #	    unless (open INFO, '>', "$list_dir/info") {
    ################
    #	    }
    #	    print INFO $hash_list->{'config'}{'description'};
    #	    close INFO;
    #	}
    #    }

    ## notify owner for forbidden customizing
    if (    #(scalar $custom->{'forbidden'}{'file'}) ||
        (scalar @{$custom->{'forbidden'}{'param'}})
        ) {

        #	my $forbidden_files = join(',',@{$custom->{'forbidden'}{'file'}});
        my $forbidden_param = join(',', @{$custom->{'forbidden'}{'param'}});
        $main::logger->do_log(Sympa::Logger::NOTICE,
            "These parameters aren't allowed in the new family definition, they are erased by a new instantiation family : \n $forbidden_param"
        );

        unless (
            $list->send_notify_to_owner(
                'erase_customizing', [$self->name, $forbidden_param]
            )
            ) {
            $main::logger->do_log(
                Sympa::Logger::NOTICE,
                'the owner isn\'t informed from erased customizing of the list %s',
                $list->name
            );
        }
    }

    ## status
    $result = $self->_set_status_changes($list, $old_status);

    if ($result->{'aliases'} == 1) {
        push(@{$self->{'updated_lists'}{'aliases_ok'}}, $list->name);

    } elsif ($result->{'install_remove'} eq 'install') {
        $self->{'updated_lists'}{'aliases_to_install'}{$list->name} =
            $result->{'aliases'};

    } else {
        $self->{'updated_lists'}{'aliases_to_remove'}{$list->name} =
            $result->{'aliases'};

    }

    ## config_changes
    foreach my $p (@{$custom->{'forbidden'}{'param'}}) {

        if (defined $config_changes->{'param'}{$p}) {
            delete $config_changes->{'param'}{$p};
        }

    }

    unless (open FILE, '>', $list->dir . '/config_changes') {
        $main::logger->do_log(Sympa::Logger::ERR,
            'impossible to open file %s/config_changes : %s',
            $list->dir, $ERRNO);
        push(@{$self->{'generated_lists'}{'file_error'}}, $list->name);
        $list->set_status_error_config('error_copy_file', $self->name);
    }
    close FILE;

    my @kept_param = keys %{$config_changes->{'param'}};
    $list->update_config_changes('param', \@kept_param);
    my @kept_files = keys %{$config_changes->{'file'}};
    $list->update_config_changes('file', \@kept_files);

    return $list;
}

# $family->_get_customizing($list)
# Gets list customizations from the config_changes file and keeps on changes allowed by param_constraint.conf
# Argument:
# * $list: a list
# Returns an hashref with the following keys:
# * config_changes: the list config_changes
# * allowed: a hash of allowed parameters: ($param,$values)
# * forbidden: FIXME
sub _get_customizing {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s)', @_);
    my ($self, $list) = @_;

    my $result;
    my $config_changes = $list->get_config_changes;

    unless (defined $config_changes) {
        $main::logger->do_log(Sympa::Logger::ERR, 'impossible to get config_changes');
        return undef;
    }

    ## FILES
    #    foreach my $f (keys %{$config_changes->{'file'}}) {

    #	my $privilege; # =may_edit($f)

    #	unless ($privilege eq 'write') {
    #	    push @{$result->{'forbidden'}{'file'}},$f;
    #	}
    #    }

    ## PARAMETERS

    # get customizing values
    my $changed_values;
    foreach my $p (keys %{$config_changes->{'param'}}) {
        $changed_values->{$p} = $list->$p;
    }

    # check these values
    my $constraint = $self->get_constraints();
    unless (defined $constraint) {
        $main::logger->do_log(Sympa::Logger::ERR, 'unable to get family constraints');
        return undef;
    }

    my $fake_list =
        bless {'robot' => $list->robot, 'config' => $changed_values} =>
        'Sympa::List';
    $fake_list->config;    # update parameter cache

    foreach my $param (keys %{$constraint}) {
        my $constraint_value = $constraint->{$param};
        my $param_value;
        my $value_error;

        unless (defined $constraint_value) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'No value constraint on parameter %s in param_constraint.conf',
                $param
            );
            next;
        }

        $param_value = $fake_list->get_param_value($param, 1);

        $value_error = $self->check_values($param_value, $constraint_value);

        foreach my $v (@{$value_error}) {
            push @{$result->{'forbidden'}{'param'}}, $param;
            $main::logger->do_log(Sympa::Logger::ERR,
                'Error constraint on parameter %s, value : %s',
                $param, $v);
        }

    }

    # keep allowed values
    foreach my $param (@{$result->{'forbidden'}{'param'}}) {
        if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
            $param = $1;
        }

        if (defined $changed_values->{$param}) {
            delete $changed_values->{$param};
        }
    }
    $result->{'allowed'} = $changed_values;

    $result->{'config_changes'} = $config_changes;
    return $result;
}

# $family->_set_status_changes($list, $old_status)
# Sets changes (loads the users, installs or removes the aliases); deals with
# the new and old_status (for already existing lists).
# Arguments:
# * $list: a list
# * $old_status: the list status before instanciation
# Return an hashref containing:
# * install_remove: "install" or "remove"
# * aliases: true if aliases needed to be installed or removed
sub _set_status_changes {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s, %s)', @_);
    my ($self, $list, $old_status) = @_;

    my $result;

    $result->{'aliases'} = 1;

    unless (defined $list->status) {
        $list->status('open');
    }

    ## aliases
    if ($list->status eq 'open') {
        unless ($old_status eq 'open') {
            $result->{'install_remove'} = 'install';
            $result->{'aliases'}        = Sympa::Admin::install_aliases($list);
        }
    }

    if ($list->status eq 'pending'
        and ($old_status eq 'open' or $old_status eq 'error_config')) {
        $result->{'install_remove'} = 'remove';
        $result->{'aliases'} =
            Sympa::Admin::remove_aliases($list, $self->{'robot'});
    }

##    ## subscribers
##    if (($old_status ne 'pending') && ($old_status ne 'open')) {
##
##	if ($list->user_data_source eq 'file') {
##	    $list->{'users'} = Sympa::List::_load_list_members_file($list->dir . '/subscribers.closed.dump');
##	}elsif ($list->user_data_source eq 'database') {
##	    unless (-f $list->dir . '/subscribers.closed.dump') {
##		$main::logger->do_log(Sympa::Logger::NOTICE, 'No subscribers to restore');
##	    }
##	    my @users = Sympa::List::_load_list_members_file($list->dir . '/subscribers.closed.dump');
##
##	    ## Insert users in database
##	    foreach my $user (@users) {
##		$list->add_list_member($user);
##	    }
##	}
##    }

    return $result;
}

# $family->_end_update_list($list, $copy)
# Finishes to generate a list in a family context (for a new or an already
# existing list). This means: checking that the list config respects the family
# constraints and copying its XML description file into the 'instance.xml' file
# contained in the list directory.  If errors occur, the list is set in status
# error_config.
# Arguments:
# * $list: a list
# * $copy: copy XML file if true, don't copy it otherwise
# Return a true value if everything goes well, false otherwise
sub _end_update_list {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s, %s)', @_);
    my ($self, $list, $xml_file) = @_;

    my $host = $self->robot->host;
    $list->latest_instantiation(
        {   'email' => "listmaster\@$host",
            ##FIXME:should be unneccessary
            'date' => $main::language->gettext_strftime(
                "%d %b %Y at %H:%M:%S", localtime time
            ),
            'date_epoch' => time
        }
    );
    $list->save_config("listmaster\@$host");
    $list->family($self);

    ## check param_constraint.conf
    $self->state('normal');
    my $error = $self->check_param_constraint($list);
    $self->state('no_check');

    unless (defined $error) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Impossible to check parameters constraint, it happens on list %s. It is set in status error_config',
            $list
        );
        $list->set_status_error_config('no_check_rules_family', $self->name);
        return undef;
    }
    if (ref($error) eq 'ARRAY') {
        $self->{'generated_lists'}{'constraint_error'}{$list->name} =
            join(", ", @{$error});
        $list->set_status_error_config('no_respect_rules_family',
            $self->name);
    }

    ## copy files in the list directory
    if ($xml_file) {    # copying the xml file
        unless ($self->_copy_files($list->dir, $list->name . '.xml')) {
            push(@{$self->{'generated_lists'}{'file_error'}}, $list->name);
            $list->set_status_error_config('error_copy_file', $self->name);
        }
    }

    return 1;
}

# $family->_copy_files($dir, $file)
# Copies the instance.xml file into the list directory. This file contains the
# current list description.
# Arguments:
# $dir: the list directory
# $file: the XML file name (optional)
# Return a true value if everything goes well, false otherwise
sub _copy_files {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, %s, %s)', @_);
    my $self     = shift;
    my $list_dir = shift;
    my $file     = shift;
    my $dir      = $self->dir;

    # instance.xml
    if (defined $file) {
        unless (File::Copy::copy("$dir/$file", "$list_dir/instance.xml")) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'impossible to copy %s/%s into %s/instance.xml : %s',
                $dir, $file, $list_dir, $ERRNO);
            return undef;
        }
    }

    return 1;
}

# $family->_load_param_constraint_conf()
# Loads the param_constraint.conf configuration file.
# Returns an hashref containing the data, undef if something went wrong.
sub _load_param_constraint_conf {
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s)', @_);
    my $self = shift;

    my $file = $self->dir . '/param_constraint.conf';

    my $constraint = {};

    unless (-e $file) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'No file %s. Assuming no constraints to apply.', $file);
        return $constraint;
    }

    unless (open(FILE, $file)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'File %s exists, but unable to open it: %s',
            $file, $ERRNO);
        return undef;
    }

    my $error = 0;

    ## Just in case...
    local $RS = "\n";

    while (<FILE>) {
        next if /^\s*(\#.*|\s*)$/;

        if (/^\s*([\w\-\.]+)\s+(.+)\s*$/) {
            my $param  = $1;
            my $value  = $2;
            my @values = split /,/, $value;

            unless (($param =~ /^([\w-]+)\.([\w-]+)$/)
                || ($param =~ /^([\w-]+)$/)) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'unknown parameter "%s" in %s',
                    $_, $file);
                $error = 1;
                next;
            }

            if (scalar(@values) == 1) {
                $constraint->{$param} = shift @values;
            } else {
                foreach my $v (@values) {
                    $constraint->{$param}{$v} = 1;
                }
            }
        } else {
            $main::logger->do_log(Sympa::Logger::ERR, 'bad line : %s in %s',
                $_, $file);
            $error = 1;
            next;
        }
    }
    if ($error) {
        $self->robot->send_notify_to_listmaster('param_constraint_conf_error',
            [$file]);
    }
    close FILE;

    # Parameters not allowed in param_constraint.conf file :
    foreach my $forbidden (@uncompellable_param) {
        if (defined $constraint->{$forbidden}) {
            delete $constraint->{$forbidden};
        }
    }

    return $constraint;
}

sub create_automatic_list {
    my $self       = shift;
    my %param      = @_;
    my $sender     = $param{'sender'};
    my $listname   = $param{'listname'};

    unless ($self->is_allowed_to_create_automatic_lists(%param)) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unconsistent scenario evaluation result for automatic list creation of list %s@%s by user %s.',
            $listname,
            $self->domain,
            $sender
        );
        return undef;
    }
    my $result = $self->add_list({listname => $listname}, 1);

    unless (defined $result->{'ok'}) {
        my $details =
               $result->{'string_error'}
            || $result->{'string_info'}
            || [];
        $main::logger->do_log(Sympa::Logger::ERR,
            "Failed to add a dynamic list to the family %s : %s",
            $self, join(';', @{$details}));
        return undef;
    }
    my $list = Sympa::List->new($listname, $self->robot);
    unless (defined $list) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'dynamic list %s could not be created', $listname);
        return undef;
    }
    return $list;
}

# Returns 1 if the user is allowed to create lists based on the family.
sub is_allowed_to_create_automatic_lists {
    my $self  = shift;
    my %param = @_;

    my $auth_level = $param{'auth_level'};
    my $sender     = $param{'sender'};
    my $message    = $param{'message'};
    my $listname   = $param{'listname'};

    # check authorization
    my $scenario = Sympa::Scenario->new(
        that     => $self->robot,
        function => 'automatic_list_creation',
        name     => $self->robot()->automatic_list_creation()
    );
    unless ($scenario) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Failed to load scenario for "automatic_list_creation"',
        );
        return undef;
    }

    my $result = $scenario->evaluate(
        that        => $self->robot,
        operation   => 'automatic_list_creation',
        auth_method => $auth_level,
        context => {
            'sender'             => $sender,
            'message'            => $message,
            'family'             => $self,
            'automatic_listname' => $listname
        }
    );
    my $r_action;
    unless (defined $result) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to evaluate scenario "automatic_list_creation" for family %s',
            $self
        );
        return undef;
    }

    if (ref($result) eq 'HASH') {
        $r_action = $result->{'action'};
    } else {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Inconsistent scenario evaluation result for automatic list creation in family %s',
            $self
        );
        return undef;
    }

    unless ($r_action =~ /do_it/) {
        $main::logger->do_log(Sympa::Logger::DEBUG2,
            'Automatic list creation refused to user %s for family %s',
            $sender, $self);
        return undef;
    }

    return 1;
}

## Handle exclusion table for family
sub insert_delete_exclusion {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s)', @_);
    my $self   = shift;
    my $email  = shift;
    my $action = shift;

    my $name  = $self->name;
    my $robot = $self->robot;

    if ($action eq 'insert') {
        ##FXIME: Check if user belong to any list of family
        my $date = time;

        ## Insert: family, user and date
        ## Add dummy list_exclusion column to satisfy constraint.
        unless (
            Sympa::DatabaseManager::do_query(
                'INSERT INTO exclusion_table (list_exclusion, family_exclusion, robot_exclusion, user_exclusion, date_exclusion) VALUES (%s, %s, %s, %s, %s)',
                Sympa::DatabaseManager::quote('family:' . $name),
                Sympa::DatabaseManager::quote($name),
                Sympa::DatabaseManager::quote($robot->domain),
                Sympa::DatabaseManager::quote($email),
                Sympa::DatabaseManager::quote($date)
            )
            ) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unable to exclude user %s from family %s',
                $email, $self);
            return undef;
        }
        return 1;
    } elsif ($action eq 'delete') {
        ##FIXME: Not implemented yet.
        return undef;
    } else {
        $main::logger->do_log(Sympa::Logger::ERR, 'Unknown action %s', $action);
        return undef;
    }

    return 1;
}

sub _get_etc_include_path {
    my ($self, $dir, $lang_dirs) = @_;

    my @include_path;

    my $path_family;
    @include_path = $self->robot->_get_etc_include_path(@_);

    if ($dir) {
        $path_family = $self->dir . '/' . $dir;
    } else {
        $path_family = $self->dir;
    }
    if ($lang_dirs) {
        unshift @include_path,
            (map { $path_family . '/' . $_ } @$lang_dirs),
            $path_family;
    } else {
        unshift @include_path, $path_family;
    }

    return @include_path;
}

=back

=cut

1;
