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

Sympa::VirtualHost - A virtual host

=head1 DESCRIPTION

This class implements a virtual hosts for Sympa. It should :

=over

=item * provide access to virtual host configuration

=item * determine the current virtual host, given a domain

=item * deliver the list of virtual hosts

=back

=cut

package Sympa::VirtualHost;

use strict;
use warnings;
use base qw(Sympa::ConfigurableObject);

use Carp qw(croak);

use Sympa::Language;
use Sympa::ListDef;
use Sympa::Logger;
use Sympa::Tools::Data;

## Croak if Robot object is used where robot name shall be used.
## It may be removed when refactoring has finished.
use overload
    'bool' => sub {1},
    '""'   => sub { croak "object Robot <$_[0]->{'name'}> is not a string"; };

sub _ensure_site_is_loaded {
    my %options = @_;
    !$Sympa::Site::is_initialized || $options{'force_reload'}
	or Sympa::Site->load(%options);
    $Sympa::Site::is_initialized
    || croak die sprintf q(can't load or reload site config at %s:%s ), (caller)[1,2];
}

=head1 CLASS METHODS

=over 4

=item Sympa::VirtualHost->new( NAME, [ OPTIONS ] )

Creates a new object named as NAME.
Returns a Robot object, or undef on errors.

=cut

sub new {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, ...)', @_);
    my $pkg  = shift;
    my $name = shift;

    my %options = @_;

    ##XXX$name = '*' unless defined $name and length $name;

    _ensure_site_is_loaded %options;

    my $robot;
    ## If robot already in memory
    if (Sympa::Site->robots($name)) {

        # use the current robot in memory and update it
        $robot = Sympa::Site->robots($name);
    } else {

        # create a new object robot
        $robot = bless {} => $pkg;
        my $status = $robot->load($name, %options);
        unless (defined $status) {
            Sympa::Site->robots($name, undef);
            return undef;
        }
    }

##    ## Initialize internal list cache
##    $robot->init_list_cache();

    return $robot;
}

=back

=head1 INSTANCE METHODS

=over

=item $vhost->load( NAME, [ KEY => VAL, ... ] )

Loads the indicated robot into the object.

=over 4

=item NAME

Name of robot.
This is the name of subdirectory under Sympa config & home directory.
The name C<'*'> (it is the default) indicates default robot.

=back

Note: To load site default, use C<Site-E<gt>load()>.
See also L<Site/load>.

=cut

sub load {
    my $self    = shift;
    my $name    = shift;
    my %options = @_;

    $name = Sympa::Site->domain
        unless defined $name
            and length $name
            and $name ne '*';

    _ensure_site_is_loaded %options;

    unless ($self->{'name'} and $self->{'etc'}) {
        my $vhost_etc = Sympa::Site->etc . '/' . $name;

        if (-f $vhost_etc . '/robot.conf') {
            ## virtual robot, even if its domain is same as that of main conf
            $self->{'etc'} = $vhost_etc;
        } elsif ($name eq Sympa::Site->domain) {
            ## robot of main conf
            $self->{'etc'} = Sympa::Site->etc;
        } else {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unknown robot "%s": config directory was not found', $name)
                unless ($options{'just_try'});
            return undef;
        }

        $self->{'name'} = $name;
    }

    unless ($self->{'name'} eq $name) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Bug in logic.  Ask developer');
        return undef;
    }

    unless ($self->{'etc'} eq Sympa::Site->etc) {
        ## the robot uses per-robot config
        my $config_file = $self->{'etc'} . '/robot.conf';

        unless (-r $config_file) {
            $main::logger->do_log(Sympa::Logger::ERR, 'No read access on %s',
                $config_file);
            Sympa::Site->send_notify_to_listmaster(
                'cannot_access_robot_conf',
                [   "No read access on $config_file. you should change privileges on this file to activate this virtual host. "
                ]
            );
            return undef;
        }

        unless (defined $self->SUPER::load(%options)) {
            return undef;
        }

        ##
        ## From now on, accessors such as "$self->domain" can be used.
        ##

        ## FIXME: Check if robot name is same as domain parameter.
        ## Sympa might be wanted to allow arbitrary robot names  used
        ## for config & home directories, though.
        unless ($self->domain eq $name) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Robot name "%s" is not same as domain "%s"',
                $name, $self->domain);
            Sympa::Site->robots($name, undef);
            ##delete Sympa::Site->robots_config->{$self->domain};
            return undef;
        }
    }

    unless ($self->{'home'}) {
        my $vhost_home = Sympa::Site->home . '/' . $name;

        if (-d $vhost_home) {
            $self->{'home'} = $vhost_home;
        } elsif ($self->domain eq Sympa::Site->domain) {
            $self->{'home'} = Sympa::Site->home;
        } else {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unknown robot "%s": home directory was not found', $name);
            return undef;
        }
    }

    Sympa::Site->robots($name, $self);
    return 1;
}

=item $vhost->get_address ( [ TYPE ] )

returns the site or robot email address of type TYPE: email command address
(default), "owner" (<sympa-request> address) or "listmaster".

=cut

sub get_address {
    my ($self, $type) = @_;

    unless ($type) {
        return $self->email . '@' . $self->host;
    } elsif ($type eq 'sympa') {    # same as above, for convenience
        return $self->email . '@' . $self->host;
    } elsif ($type eq 'owner' or $type eq 'request') {
        return $self->email . '-request' . '@' . $self->host;
    } elsif ($type eq 'listmaster') {
        return $self->listmaster_email . '@' . $self->host;
    } elsif ($type eq 'return_path') {
        return
              $self->email
            . $self->return_path_suffix . '@'
            . $self->host;
    }

    $main::logger->do_log(Sympa::Logger::ERR,
        'Unknown type of address "%s" for %s.  Ask developer',
        $type, $self);
    return undef;
}

=item $vhost->is_listmaster( WHO )

Is the user listmaster?

=cut

sub is_listmaster {
    my $self = shift;
    my $who = Sympa::Tools::clean_email(shift || '');
    return 0 unless $who;

    foreach my $listmaster (($self->listmasters,)) {
        return 1 if $listmaster eq $who;
    }

    foreach my $listmaster ((Sympa::Site->listmasters,)) {
        return 1 if $listmaster eq $who;
    }

    return 0;
}

=item $vhost->get_id

Get unique name of robot.

=cut

sub get_id {
    ## DO NOT use accessors since $self may not have been fully initialized.
    shift->{'name'} || '';
}

=item $vhost->is_listmaster

See L<Site/is_listmaster>.

=item $vhost->get_etc_include_path

make an array of include path for tt2 parsing.
See L<Site/get_etc_include_path>.

=item $vhost->send_dsn

Sends an delivery status notification (DSN).
See L<Site/send_dsn>.

=item $vhost->send_file ( ... )

Send a global (not relative to a list, but relative to a robot)
message to user(s).
See L<Site/send_file>.

Note: Sympa::List::send_global_file() was deprecated.

=item $vhost->send_notify_to_listmaster ( OPERATION, DATA, CHECKSTACK, PURGE )

Sends a notice to normal listmaster by parsing
listmaster_notification.tt2 template
See L<Site/send_notify_to_listmaster>.

Note: Sympa::List::send_notify_to_listmaster() was deprecated.

=item $vhost->is_available_topic ( TOPIC )

Check $topic in the $self conf

IN  : - $topic : id of the topic

OUT : - 1 if the topic is in the robot conf or undef

=cut

sub is_available_topic {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $self  = shift;
    my $topic = shift;

    my ($top, $subtop) = split /\//, $topic;

    my %topics;
    unless (%topics = %{$self->topics || {}}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'unable to load list of topics');
    }

    if ($subtop) {
        return 1
            if defined $topics{$top}
                and defined $topics{$top}{'sub'}{$subtop};
    } else {
        return 1 if defined $topics{$top};
    }

    return undef;
}

=item $vhost->split_listname ( MAILBOX )

XXX @todo doc

Note:
For C<-request> and C<-owner> suffix, this function returns
C<owner> and C<return_path> type, respectively.


=cut

sub split_listname {
    my $self    = shift;
    my $mailbox = shift;
    return () unless defined $mailbox and length $mailbox;

    my $return_path_suffix = $self->return_path_suffix;
    my $regexp             = join('|',
        map { s/(\W)/\\$1/g; $_ }
            grep { $_ and length $_ }
            split(/[\s,]+/, $self->list_check_suffixes));

    if ($mailbox eq 'sympa' and $self->domain eq Sympa::Site->domain) {
        # compat.
        return (undef, 'sympa');
    } elsif ($mailbox eq $self->email
        or $self->domain eq Sympa::Site->domain
        and $mailbox eq Sympa::Site->email) {
        return (undef, 'sympa');
    } elsif ($mailbox eq $self->listmaster_email
        or $self->domain eq Sympa::Site->domain
        and $mailbox eq Sympa::Site->listmaster_email) {
        return (undef, 'listmaster');
    } elsif ($mailbox =~ /^(\S+)$return_path_suffix$/) {    # -owner
        return ($1, 'return_path');
    } elsif (!$regexp) {
        return ($mailbox);
    } elsif ($mailbox =~ /^(\S+)-($regexp)$/) {
        my ($name, $suffix) = ($1, $2);
        my $type;

        if ($suffix eq 'request') {
            $type = 'owner';
        } elsif ($suffix eq 'editor') {
            $type = 'editor';
        } elsif ($suffix eq 'subscribe') {
            $type = 'subscribe';
        } elsif ($suffix eq 'unsubscribe') {
            $type = 'unsubscribe';
        } else {
            $name = $mailbox;
            $type = 'UNKNOWN';
        }
        return ($name, $type);
    } else {
        return ($mailbox);
    }
}

=item $vhost->get_netidtoemail_db

get idp xref to locally validated email address

=cut

sub get_netidtoemail_db {
    my $self    = shift;
    my $netid   = shift;
    my $idpname = shift;

    $main::logger->do_log(Sympa::Logger::DEBUG,
        'Sympa::List::get_netidtoemail_db(%s, %s)',
        $netid, $idpname);

    my $robot_id = $self->domain();

    my ($l, %which, $email);

    my $sth;

    unless (
        $sth = Sympa::DatabaseManager::do_prepared_query(
            q{SELECT email_netidmap
	      FROM netidmap_table
	      WHERE netid_netidmap = ? AND serviceid_netidmap = ? AND
		    robot_netidmap = ?},
            $netid, $idpname, $robot_id
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to get email address from netidmap_table for id %s, service %s, robot %s',
            $netid,
            $idpname,
            $robot_id
        );
        return undef;
    }

    $email = $sth->fetchrow;
    $sth->finish();

    return $email;
}

=item $vhost->set_netidtoemail_db

set idp xref to locally validated email address

=cut

sub set_netidtoemail_db {
    my $self    = shift;
    my $netid   = shift;
    my $idpname = shift;
    my $email   = shift;

    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s, %s)', @_);

    my $robot_id = $self->domain();

    my ($l, %which);

    unless (
        Sympa::DatabaseManager::do_prepared_query(
            q{INSERT INTO netidmap_table
	      (netid_netidmap, serviceid_netidmap, email_netidmap,
	       robot_netidmap)
	      VALUES (?, ?, ?, ?)},
            $netid, $idpname, $email, $robot_id
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to set email address %s in netidmap_table for id %s, service %s, robot %s',
            $email,
            $netid,
            $idpname,
            $robot_id
        );
        return undef;
    }

    return 1;
}

=item $vhost->update_email_netidmap_db

Update netidmap table when user email address changes

=cut

sub update_email_netidmap_db {
    my ($self, $old_email, $new_email) = @_;

    my $robot_id = $self->domain();

    unless (defined $robot_id
        && defined $old_email
        && defined $new_email) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Missing parameter');
        return undef;
    }

    unless (
        Sympa::DatabaseManager::do_prepared_query(
            q{UPDATE netidmap_table
	      SET email_netidmap = ?
	      WHERE email_netidmap = ? AND robot_netidmap = ?},
            $new_email, $old_email, $robot_id
        )
        ) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to set new email address %s in netidmap_table to replace old address %s for robot %s',
            $new_email,
            $old_email,
            $robot_id
        );
        return undef;
    }

    return 1;
}

=item $vhost->families ( [ NAME, [ FAMILY ] ] )

Handles cached information of families on memory.

I<Getter>.
Gets cached family/ies on memory.  If memory cache is missed, returns C<undef>.

I<Setter>.
Updates memory cache.
If C<undef> was given as FAMILY, cache entry on the memory will be removed.

=cut

sub families {
    my $self = shift;
    my $name = shift;

    if (scalar @_) {
        my $v = shift;
        unless (defined $v) {
            delete $self->{'families'}{$name};
        } else {
            $self->{'families'} ||= {};
            $self->{'families'}{$name} = $v;
        }
    }
    $self->{'families'}{$name};
}

=item $vhost->init_list_cache

Clear list cache on memory.

=cut

sub init_list_cache {
    my $self = shift;
    delete $self->{'lists'};
    delete $self->{'lists_ok'};
}

=item $vhost->lists ( [ NAME, [ LIST ] ] )

Handles cached information of lists on memory.

I<Getter>.
Gets cached list(s) on memory.

When NAME and LIST are not given, returns an array of all cached lists.
Note: To ensure all lists are cached, check L<lists_ok>.

When NAME is given, returns cached list.
If memory cache is missed, returns C<undef>.

I<Setter>.
Updates memory cache.
If C<undef> was given as LIST, cache entry on the memory will be removed.

=cut

sub lists {
    my $self = shift;
    unless (scalar @_) {
        return map { $self->{'lists'}->{$_} }
            sort keys %{$self->{'lists'} || {}};
    }

    my $name = shift;
    if (scalar @_) {
        my $v = shift;
        unless (defined $v) {
            delete $self->{'lists'}{$name};
        } else {
            $self->{'lists'} ||= {};
            $self->{'lists'}{$name} = $v;
        }
    }
    $self->{'lists'}{$name};
}

=item $vhost->lists_ok

I<Setter>, I<internal use>.
XXX @todo doc

=cut

sub lists_ok {
    my $self = shift;
    $self->{'lists_ok'} = shift if scalar @_;
    $self->{'lists_ok'};
}

=item E<lt>config parameterE<gt>

I<Getters>.
Get robot config parameter.
For example C<$robot-E<gt>listmaster> returns "listmaster" parameter of the
robot.

=item etc

=item home

=item name

I<Getters>.
Get profile of robot.

## AUTOLOAD method will be inherited from Site class

sub DESTROY { }   # "sub DESTROY;" may cause segfault with Perl around 5.10.1.

=item $vhost->list_params

I<Getter>.
Returns hashref to list parameter information.

=cut

sub list_params {
    croak "Can't modify \"list_params\" attribute" if scalar @_ > 1;
    my $self = shift;

    return $self->{'list_params'} if $self->{'list_params'};

    my $pinfo = Sympa::Tools::Data::dup_var(\%Sympa::ListDef::pinfo);
    $pinfo->{'lang'}{'format'} = [$self->supported_languages];

    return $self->{'list_params'} = $pinfo;
}

=item $vhost->topics

Get a hashref including information of list topics available on the robot.

=cut

sub topics {
    my $self = shift;

    my $conf_file = $self->get_etc_filename('topics.conf');
    unless ($conf_file) {
        $main::logger->do_log(Sympa::Logger::ERR, 'No topics.conf defined');
        return undef;
    }

    my $list_of_topics;

    ## Load if not loaded or changed on disk
    if (   !$self->{'topics'}
        or !$self->{'mtime'}{'topics.conf'}
        or (stat($conf_file))[9] > $self->{'mtime'}{'topics.conf'}) {

        ## delete previous list of topics
        $list_of_topics = {};

        unless (-r $conf_file) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Unable to read %s',
                $conf_file);
            return undef;
        }

        unless (open(FILE, '<', $conf_file)) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unable to open config file %s', $conf_file);
            return undef;
        }

        ## Rough parsing
        my $index = 0;
        my (@rough_data, $topic);
        while (<FILE>) {
            Encode::from_to($_, Sympa::Site->filesystem_encoding, 'utf8');
            if (/^([\-\w\/]+)\s*$/) {
                $index++;
                $topic = {
                    'name'  => $1,
                    'order' => $index
                };
            } elsif (/^([\w\.]+)\s+(.+)\s*$/) {
                next unless defined $topic->{'name'};

                $topic->{$1} = $2;
            } elsif (/^\s*$/) {
                next unless defined $topic->{'name'};

                push @rough_data, $topic;
                $topic = {};
            }
        }
        close FILE;

        ## Last topic
        if (defined $topic->{'name'}) {
            push @rough_data, $topic;
            $topic = {};
        }

        $self->{'mtime'}{'topics.conf'} = (stat($conf_file))[9];

        unless ($#rough_data > -1) {
            $main::logger->do_log(Sympa::Logger::NOTICE,
                'No topic defined in %s', $conf_file);
            return undef;
        }

        ## Analysis
        foreach my $topic (@rough_data) {
            my @tree = split '/', $topic->{'name'};

            if ($#tree == 0) {
                my $title = _get_topic_titles($topic);
                $list_of_topics->{$tree[0]}{'title'} = $title;
                $list_of_topics->{$tree[0]}{'visibility'} =
                    $topic->{'visibility'} || 'default';
                #$list_of_topics->{$tree[0]}{'visibility'} =
                #    _load_scenario_file('topics_visibility', $self,
                #    $topic->{'visibility'} || 'default');
                $list_of_topics->{$tree[0]}{'order'} = $topic->{'order'};
            } else {
                my $subtopic = join('/', @tree[1 .. $#tree]);
                my $title = _get_topic_titles($topic);
                $list_of_topics->{$tree[0]}{'sub'}{$subtopic} =
                    _add_topic($subtopic, $title);
            }
        }

        ## Set undefined Topic (defined via subtopic)
        foreach my $t (keys %{$list_of_topics}) {
            unless (defined $list_of_topics->{$t}{'visibility'}) {
                #$list_of_topics->{$t}{'visibility'} =
                #    _load_scenario_file('topics_visibility', $self,
                #    'default');
            }

            unless (defined $list_of_topics->{$t}{'title'}) {
                $list_of_topics->{$t}{'title'} = {'default' => $t};
            }
        }
    }

    ## Set the title in the current language
    my $lang = $main::language->get_lang;
    foreach my $top (keys %{$list_of_topics}) {
        my $topic = $list_of_topics->{$top};
        foreach my $l (Sympa::Language::implicated_langs($lang)) {
            if (exists $topic->{'title'}{$l}) {
                $topic->{'current_title'} = $topic->{'title'}{$l};
            }
        }
        unless (exists $topic->{'current_title'}) {
            if (exists $topic->{'title'}{'gettext'}) {
                $topic->{'current_title'} =
                    $main::language->gettext($topic->{'title'}{'gettext'});
            } else {
                $topic->{'current_title'} = $topic->{'title'}{'default'}
                    || $top;
            }
        }

        foreach my $subtop (keys %{$topic->{'sub'}}) {
            foreach my $l (Sympa::Language::implicated_langs($lang)) {
                if (exists $topic->{'sub'}{$subtop}{'title'}{$l}) {
                    $topic->{'sub'}{$subtop}{'current_title'} =
                        $topic->{'sub'}{$subtop}{'title'}{$l};
                }
            }
            unless (exists $topic->{'sub'}{$subtop}{'current_title'}) {
                if (exists $topic->{'sub'}{$subtop}{'title'}{'gettext'}) {
                    $topic->{'sub'}{$subtop}{'current_title'} =
                        $main::language->gettext(
                        $topic->{'sub'}{$subtop}{'title'}{'gettext'});
                } else {
                    $topic->{'sub'}{$subtop}{'current_title'} =
                           $topic->{'sub'}{$subtop}{'title'}{'default'}
                        || $subtop;
                }
            }
        }
    }

    return $list_of_topics;
}

sub _get_topic_titles {
    my $topic = shift;

    my $title;
    foreach my $key (%{$topic}) {
        if ($key =~ /^title\.gettext$/i) {
            $title->{'gettext'} = $topic->{$key};
        } elsif ($key =~ /^title\.(\S+)$/i) {
            my $lang = $1;
            # canonicalize lang if possible.
            $lang = Sympa::Language::canonic_lang($lang) || $lang;
            $title->{$lang} = $topic->{$key};
        } elsif ($key =~ /^title$/i) {
            $title->{'default'} = $topic->{$key};
        }
    }

    return $title;
}

sub _get_topic_current_title {
    my $topic = shift;
    my $lang  = $main::language->get_lang;
    foreach my $lang (Sympa::Language::implicated_langs($lang)) {
        if ($topic->{'title'}{$lang}) {
            return $topic->{'title'}{$lang};
        }
    }
    if ($topic->{'title'}{'gettext'}) {
        return $main::language->gettext($topic->{'title'}{'gettext'});
    } elsif ($topic->{'title'}{'default'}) {
        return $main::language->gettext($topic->{'title'}{'default'});
    } else {
        return undef;
    }
}

## Inner sub used by load_topics()
sub _add_topic {
    my ($name, $title) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
        return {'title' => $title};
    } else {
        $topic->{'sub'}{$name} =
            _add_topic(join('/', @tree[1 .. $#tree]), $title);
        return $topic;
    }
}

=item $vhost->request

=item $vhost->sympa

Gets derived config parameters.

B<Obsoleted>.
See L<Site/request> and L<Site/sympa>.

=cut

=item $vhost->listmasters

In scalar context, returns arrayref of listmasters of robot.
In array context, returns array of them.

=cut

=item $vhost->supported_languages

In array context, returns array of supported languages by robot.
In scalar context, returns arrayref to them.

=back

=head1 FUNCTIONS

=over 4

=item get_robots ( OPT => VALUE, ... )

I<Function>.
Get all robots hosted by Sympa.
Returns arrayref of Robot objects.

=cut

sub get_robots {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(...)');
    my %options = @_;

    my $robot;
    my @robots = ();
    my %orphan;
    my $got_default = 0;
    my $dir;

    _ensure_site_is_loaded %options;

    ## Check memory cache first.
    if (Sympa::Site->robots_ok) {
        @robots = Sympa::Site->robots;
        return \@robots;
    }

    ## get all cached robots
    %orphan = map { $_->domain => 1 } Sympa::Site->robots;

    unless (opendir $dir, Sympa::Site->etc) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to open directory %s for virtual robots config',
            Sympa::Site->etc);
        return undef;
    }
    foreach my $name (readdir $dir) {
        next if $name =~ /^\./;
        my $vhost_etc = Sympa::Site->etc . '/' . $name;
        next unless -d $vhost_etc;
        next unless -f $vhost_etc . '/robot.conf';

        if ($robot = Sympa::VirtualHost->new($name, %options)) {
            $got_default = 1 if $robot->domain eq Sympa::Site->domain;
            push @robots, $robot;
            delete $orphan{$robot->domain};
        }
    }
    closedir $dir;

    unless ($got_default) {
        if ($robot = Sympa::VirtualHost->new(Sympa::Site->domain, %options)) {
            push @robots, $robot;
            delete $orphan{$robot->domain};
        }
    }

    ## purge orphan robots
    foreach my $domain (keys %orphan) {
        $main::logger->do_log(Sympa::Logger::DEBUG3,
            'removing orphan robot %s', $domain);
        Sympa::Site->robots($domain, undef);
    }

    Sympa::Site->robots_ok(1);

    return \@robots;
}

sub get_dkim_parameters {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s)', @_);
    my $self = shift;

    my $data;
    my $keyfile;

    $data->{'d'}        = $self->dkim_signer_domain;
    $data->{'i'}        = $self->dkim_signer_identity;
    $data->{'selector'} = $self->dkim_selector;
    $keyfile            = $self->dkim_private_key_path;

    unless (open(KEY, $keyfile)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            "Could not read DKIM private key %s", $keyfile);
        return undef;
    }
    while (<KEY>) {
        $data->{'private_key'} .= $_;
    }
    close(KEY);

    return $data;
}

sub _get_etc_include_path {
    my ($self, $dir, $lang_dirs) = @_;

    my @include_path;

    my $path_robot;
    @include_path = Sympa::Site->_get_etc_include_path(@_);

    if ($self->etc ne Sympa::Site->etc) {
        if ($dir) {
            $path_robot = $self->etc . '/' . $dir;
        } else {
            $path_robot = $self->etc;
        }
        if ($lang_dirs) {
            unshift @include_path,
                (map { $path_robot . '/' . $_ } @$lang_dirs),
                $path_robot;
        } else {
            unshift @include_path, $path_robot;
        }
    }

    return @include_path;
}

=back

=cut

1;
