# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
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

Sympa::OAuth::Consumer - OAuth consumer object

=head1 DESCRIPTION

This class implements the client side of the OAuth workflow.

It handles authorization request, token retrieving and database storage.

=cut

package Sympa::OAuth::Consumer;

use strict;

use OAuth::Lite::Consumer;

use Sympa::Auth;
use Sympa::Log;
use Sympa::SDM;
use Sympa::Tools;

=head1 CLASS METHODS

=head2 Sympa::OAuth::Consumer->new(%parameters)

Creates a new L<Sympa::OAuth::Consumer> object.

=head3 Parameters

=over

=item * I<user>: a user email

=item * I<provider>: the OAuth provider key

=item * I<consumer_key>: FIXME

=item * I<consumer_secret>: FIXME

=item * I<request_token_path>: the temporary token request URL

=item * I<access_token_path>: the access token request URL

=item * I<authorize_path>: the authorization URL

=back

=head3 Return value

A L<Sympa::OAuth::Consumer> object, or undef if something went wrong.

=cut

sub new {
	my ($class, %params) = @_;
	Sympa::Log::do_log('debug2', '(%s, %s, %s)', $params{'user'}, $params{'provider'}, $params{'consumer_key'});

	my $sth = Sympa::SDM::do_prepared_query('SELECT tmp_token_oauthconsumer AS tmp_token, tmp_secret_oauthconsumer AS tmp_secret, access_token_oauthconsumer AS access_token, access_secret_oauthconsumer AS access_secret FROM oauthconsumer_sessions_table WHERE user_oauthconsumer=? AND provider_oauthconsumer=?', $params{'user'}, $params{'provider'});
	unless ($sth) {
		Sympa::Log::do_log('err','Unable to load token data %s %s', $params{'user'}, $params{'provider'});
		return undef;
	}

	my $self = {
		user               => $params{'user'},
		provider           => $params{'provider'},
		consumer_key       => $params{'consumer_key'},
		consumer_secret    => $params{'consumer_secret'},
		request_token_path => $params{'request_token_path'},
		access_token_path  => $params{'access_token_path'},
		authorize_path     => $params{'authorize_path'},
		redirect_url       => undef,
		handler            => OAuth::Lite::Consumer->new(
			consumer_key       => $params{'consumer_key'},
			consumer_secret    => $params{'consumer_secret'},
			request_token_path => $params{'request_token_path'},
			access_token_path  => $params{'access_token_path'},
			authorize_path     => $params{'authorize_path'}
		)
	};

	$self->{'session'} = {
		defined => undef,
		tmp     => undef,
		access  => undef
	};

	if(my $data = $sth->fetchrow_hashref('NAME_lc')) {
		$self->{'session'}{'tmp'} = OAuth::Lite::Token->new(
			token => $data->{'tmp_token'},
			secret => $data->{'tmp_secret'}
		) if($data->{'tmp_token'});
		$self->{'session'}{'access'} = OAuth::Lite::Token->new(
			token => $data->{'access_token'},
			secret => $data->{'access_secret'}
		) if($data->{'access_token'});
		$self->{'session'}{'defined'} = 1;
	}

	bless $self, $class;

	return $self;
}

=head1 INSTANCE METHODS

=head2 $consumer->set_web_env(%parameters)

=head3 Parameters

=over

=item * I<robot>

=item * I<here_path>

=item * I<base_path>

=back

=cut

sub set_web_env {
	my ($self, %params) = @_;

	$self->{'robot'} = $params{'robot'};
	$self->{'here_path'} = $params{'here_path'};
	$self->{'base_path'} = $params{'base_path'};
}

=head2 $consumer->must_redirect()

=head3 Parameters

None.

=cut

sub must_redirect {
	my ($self) = @_;

	return $self->{'redirect_url'};
}

=head2 $consumer->fetch_ressource(%parameters)

Check if user has an access token already and fetch resource.

=head3 parameters

=over

=item * I<url>: the resource url

=item * I<params>: the request parameters (optional)

=back

=head3 Return value

The resource body, as a string, or undef if something went wrong.

=cut

sub fetch_ressource {
	my ($self, %params) = @_;
	Sympa::Log::do_log('debug2', '(%s)', $params{'url'});

	# Get access token, return 1 if it exists
	my $token = $self->has_access();
	return undef unless(defined $token); # Should never return here unless failed to retreive token

	my $res = $self->{'handler'}->request(
		method => 'GET',
		url    => $params{'url'},
		token  => $token,
		params => $params{'params'},
	);

	unless($res->is_success) {
		if($res->status == 400 || $res->status == 401) {
			my $auth_header = $res->header('WWW-Authenticate');
			if($auth_header && $auth_header =~ /^OAuth/) {
				# access token may be expired,
				# get request-token and authorize again
				if($self->{'here_path'}) { # We are running in web env.
					$self->trigger_flow();
				}
				return undef;
			}else{
				# another auth error.
				return undef;
			}
		}
		# another error.
		return undef;
	}

	return $res->decoded_content || $res->content;
}

=head2 $consumer->has_access()

Check if user has an access token already, triggers OAuth workflow otherwise

=head3 Parameters

None.

=head3 Return value

An hashref, if there is a known access token, undef otherwise.

=cut

sub has_access {
	my ($self) = @_;
	Sympa::Log::do_log('debug2', '(%s, %s)', $self->{'user'}, $self->{'consumer_type'}.':'.$self->{'provider'});

	unless(defined $self->{'session'}{'access'}) {
		if($self->{'here_path'}) { # We are running in web env.
			$self->trigger_flow();
		}
		return undef;
	}

	return $self->{'session'}{'access'};
}

=head2 $consumer->trigger_flow()

Triggers OAuth authorization workflow, call only in web env.

=head3 Parameters

None.

=head3 Return value

A true value, if everything's alright.

=cut

sub trigger_flow {
	my ($self) = @_;
	Sympa::Log::do_log('debug2', '(%s, %s)', $self->{'user'}, $self->{'consumer_type'}.':'.$self->{'provider'});

	my $ticket = Sympa::Auth::create_one_time_ticket(
		$self->{'user'},
		$self->{'robot'},
		$self->{'here_path'},
		'mail'
	);
	my $callback = $self->{'base_path'}.'/oauth_ready/'.$self->{'provider'}.'/'.$ticket;

	my $tmp = $self->{'handler'}->get_request_token(
		callback_url => $callback
	);

	unless(defined $tmp) {
		Sympa::Log::do_log('err', 'Unable to get tmp token for %s %s %s', $self->{'user'}, $self->{'provider'}, $self->{'handler'}->errstr);
		return undef;
	}

	if(defined $self->{'session'}{'defined'}) {
		unless(Sympa::SDM::do_query('UPDATE oauthconsumer_sessions_table SET tmp_token_oauthconsumer=%s, tmp_secret_oauthconsumer=%s WHERE user_oauthconsumer=%s AND provider_oauthconsumer=%s', Sympa::SDM::quote($tmp->{'token'}), Sympa::SDM::quote($tmp->{'secret'}), Sympa::SDM::quote($self->{'user'}), Sympa::SDM::quote($self->{'provider'}))) {
			Sympa::Log::do_log('err', 'Unable to update token record %s %s in database', $self->{'user'}, $self->{'provider'});
			return undef;
		}
	}else{
		unless(Sympa::SDM::do_query('INSERT INTO oauthconsumer_sessions_table(user_oauthconsumer, provider_oauthconsumer, tmp_token_oauthconsumer, tmp_secret_oauthconsumer) VALUES (%s, %s, %s, %s)', Sympa::SDM::quote($self->{'user'}), Sympa::SDM::quote($self->{'provider'}), Sympa::SDM::quote($tmp->{'token'}), Sympa::SDM::quote($tmp->{'secret'}))) {
			Sympa::Log::do_log('err', 'Unable to add new token record %s %s in database', $self->{'user'}, $self->{'provider'});
			return undef;
		}
	}

	$self->{'session'}{'tmp'} = $tmp;

	my $url = $self->{'handler'}->url_to_authorize(
		token => $tmp
	);

	Sympa::Log::do_log('info', 'Ask for redirect to %s with callback %s for %s', $url, $callback, $self->{'here_path'});
	$self->{'redirect_url'} = $url;

	return 1;
}

=head2 head2 $consumer->get_access_token(%parameters)

Try to obtain access token from verifier.

=head3 Parameters

=over

=item * I<verifier>

=item * I<token>

=back

=head3 Return value

A true value if the token was retreived successfully, undef otherwise.

=cut

sub get_access_token {
	my ($self, %params) = @_;
	Sympa::Log::do_log('debug2', '(%s, %s)', $self->{'user'}, $self->{'consumer_type'}.':'.$self->{'provider'});

	return $self->{'session'}{'access'} if(defined $self->{'session'}{'access'});

	return undef unless(defined $self->{'session'}{'tmp'} && $self->{'session'}{'tmp'}->token eq $params{'token'} && defined $params{'verifier'} && $params{'verifier'} ne '');

	my $access = $self->{'handler'}->get_access_token(
		token => $self->{'session'}{'tmp'},
		verifier => $params{'verifier'}
	);

	$self->{'session'}{'access'} = $access;
	$self->{'session'}{'tmp'} = undef;

	unless(Sympa::SDM::do_query('UPDATE oauthconsumer_sessions_table SET tmp_token_oauthconsumer=NULL, tmp_secret_oauthconsumer=NULL, access_token_oauthconsumer=%s, access_secret_oauthconsumer=%s WHERE user_oauthconsumer=%s AND provider_oauthconsumer=%s', Sympa::SDM::quote($access->{'token'}), Sympa::SDM::quote($access->{'secret'}), Sympa::SDM::quote($self->{'user'}), Sympa::SDM::quote($self->{'provider'}))) {
		Sympa::Log::do_log('err', 'Unable to update token record %s %s in database', $self->{'user'}, $self->{'provider'});
		return undef;
	}

	return $self->{'session'}{'access'};
}

=head1 AUTHORS

=over

=item * Etienne Meleard <etienne.meleard AT renater.fr>

=back

=cut

1;
