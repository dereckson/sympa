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

Sympa::Transport - FIXME

=head1 DESCRIPTION

FIXME

=cut

package Sympa::Transport;

use strict;

use SOAP::Transport::HTTP;

use Sympa::Logger;
use Sympa::VirtualHost;
use Sympa::Session;
use Sympa::Site;

our @ISA = qw(SOAP::Transport::HTTP::FCGI);

sub request {
    my $self = shift;

    if (my $request = $_[0]) {
        ## Select appropriate robot
        if (Sympa::Site->robot_by_soap_url->{$ENV{'SERVER_NAME'}
                    . $ENV{'SCRIPT_NAME'}}) {
            $ENV{'SYMPA_ROBOT'} =
                Sympa::Site->robot_by_soap_url->{$ENV{'SERVER_NAME'}
                    . $ENV{'SCRIPT_NAME'}};
            $main::logger->do_log(Sympa::Logger::DEBUG2, 'Robot : %s',
                $ENV{'SYMPA_ROBOT'});
        } else {
            $main::logger->do_log(Sympa::Logger::DEBUG2, 'URL : %s',
                $ENV{'SERVER_NAME'} . $ENV{'SCRIPT_NAME'});
            $ENV{'SYMPA_ROBOT'} = Sympa::Site->domain;
        }

        ## Empty list cache of the robot
        my $robot = Sympa::VirtualHost->new($ENV{'SYMPA_ROBOT'});
        $robot->init_list_cache();

        my $session;
        ## Existing session or new one
        if (Sympa::Session::get_session_cookie($ENV{'HTTP_COOKIE'})) {
            $session = Sympa::Session->new(
                robot   => $robot,
                cookie  => Sympa::Session::get_session_cookie($ENV{'HTTP_COOKIE'}),
                refresh => Sympa::Site->cookie_refresh()
            );
        } else {
            $session = Sympa::Session->new(
                robot => $robot,
                refresh => Sympa::Site->cookie_refresh()
            );
            $session->store() if defined $session;
            ## Note that id_session changes each time it is saved in the DB
            $session->renew() if defined $session;
        }

        delete $ENV{'USER_EMAIL'};
        if (defined $session) {
            $ENV{'SESSION_ID'} = $session->{'id_session'};
            if ($session->{'email'} ne 'nobody') {
                $ENV{'USER_EMAIL'} = $session->{'email'};
            }
        }
    }

    $self->SUPER::request(@_);
}

sub response {
    my $self = shift;

    if (my $response = $_[0]) {
        if (defined $ENV{'SESSION_ID'}) {
            my $expire = $main::param->{'user'}{'cookie_delay'}
                || Sympa::Site->cookie_expire;
            my $cookie =
                Sympa::Session::soap_cookie2($ENV{'SESSION_ID'},
                $ENV{'SERVER_NAME'}, $expire);
            $response->headers->push_header('Set-Cookie2' => $cookie);
        }
    }

    $self->SUPER::request(@_);
}

## Redefine FCGI's handle subroutine
sub handle ($$) {
    my $self     = shift->new;
    my $birthday = shift;

    my ($r1, $r2);
    my $fcgirq = $self->{_fcgirq};

    ## If fastcgi changed on disk, die
    ## Apache will restart the process
    while (($r1 = $fcgirq->Accept()) >= 0) {

        $r2 = $self->SOAP::Transport::HTTP::CGI::handle;

        if ((stat($ENV{'SCRIPT_FILENAME'}))[9] > $birthday) {
            exit(0);
        }

        # print
        # "Set-Cookie: sympa_altemails=olivier.salaun%40cru.fr; path=/; expires=Tue , 19-Oct-2004 14 :08:19 GMT\n";
    }
    return undef;
}

1;
