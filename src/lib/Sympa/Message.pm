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

Sympa::Message - An e-mail message

=head1 DESCRIPTION 

This class implements an e-mail message. It is mostly a wrapper over a
L<Mime::Entity> object, with additional methods and attributes.

=cut 

package Sympa::Message;

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars);

use File::Temp;
use HTML::Entities qw(encode_entities);
use Mail::Address;
use MIME::Charset;
use MIME::EncWords;
use MIME::Entity;
use MIME::Parser;
use MIME::Tools;
use POSIX qw();
use Storable qw(dclone);
use URI::Escape;

use Sympa::Logger;
use Sympa::Site;
use Sympa::Template;
use Sympa::Tools;
use Sympa::Tools::DKIM;
use Sympa::Tools::Message;
use Sympa::Tools::SMIME;
use Sympa::Tools::WWW;

my %openssl_errors = (
    1 => 'an error occurred parsing the command options',
    2 => 'one of the input files could not be read',
    3 =>
        'an error occurred creating the PKCS#7 file or when reading the MIME message',
    4 => 'an error occurred decrypting or verifying the message',
    5 =>
        'the message was verified correctly but an error occurred writing out the signers certificates',
);

=head1 CLASS METHODS

=over 4

=item Sympa::Message->new(%parameters)

Creates a new L<Sympa::Message> object.

Parameters:

=over 4

=item * I<file>: the message, as a file

=item * I<messageasstring>: the message, as a string

=item * I<noxsympato>: FIXME

=item * I<messagekey>: FIXME

=item * I<spoolname>: FIXME

=item * I<robot>: FIXME

=item * I<robot_object>: FIXME

=item * I<list>: FIXME

=item * I<list_object>: FIXME

=item * I<authkey>: FIXME

=item * I<priority>: FIXME

=item * I<type>: FIXME

=back 

Returns a new L<Sympa::Message> object, or I<undef> for failure.

=cut 

sub new {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my ($class, %params) = @_;

    my $self = bless {
        'noxsympato' => $params{'noxsympato'},
        'messagekey' => $params{'messagekey'},
        'spoolname'  => $params{'spoolname'},
        'robot_id'   => $params{'robot'},
        'file'       => $params{'file'},
        'listname'   => $params{'list'},       #++
        'authkey'    => $params{'authkey'},    #FIXME: needed only by KeySpool.
        'priority'   => $params{'priority'},   #++
    } => $class;

    # set date from filename, if relevant
    if ($params{'file'}) {
        my $file = $params{'file'};
        $file =~ s/^.*\/([^\/]+)$/$1/;
        if ($file =~ /^(\S+)\.(\d+)\.\w+$/) {
            $self->{'date'} = $2;
        }
    }

    unless ($self->{'list'} or $self->{'robot'}) {
        if ($params{'list_object'}) {
            $self->{'list'} = $params{'list_object'};
        } elsif ($params{'robot_object'}) {
            $self->{'robot'} = $params{'robot_object'};
        }
        $self->{'listtype'} = $params{'type'} if $params{'type'};    #++
    }

    ## Load content

    my $messageasstring;
    if ($params{'file'}) {
        eval {
            $messageasstring = Sympa::Tools::File::slurp_file($params{'file'});
        };
        if ($EVAL_ERROR) {
            $main::logger->do_log(Sympa::Logger::ERR, $EVAL_ERROR);
            return undef;
        }
    } elsif ($params{'messageasstring'}) {
        $messageasstring = $params{'messageasstring'};
    }

    return undef unless
        $messageasstring && $self->_load($messageasstring);

    return $self;
}

=back

=head1 INSTANCE METHODS

=over

=item $message->as_file()

Returns the message itself, as a file name.

=cut

sub as_file {
    my ($self) = @_;

    return $self->{'file'};
}

=item $message->as_string()

Returns the message itself, as a string.

=cut

sub as_string {
    my $self = shift;
    return $self->{'string'};
}

=item $message->as_entity()

Returns the message itself, as a L<MIME::Entity> object.

=cut

sub as_entity {
    my $self = shift;
    return $self->{'entity'};
}

=item $message->get_family()

Gets the family context of this message.

=cut

sub get_family {
    my $self = shift;

    return $self->{'family'};
}

=item $message->get_list()

Gets the list context of this message, as a L<Sympa::List> object.

=cut

sub get_list {
    my $self = shift;

    return $self->{'list'};
}

=item $message->get_robot()

Gets the robot context of this message, as a L<Sympa::VirtualHost> object.

=cut

sub get_robot {
    my $self = shift;

    return 
        $self->{'robot'} ? $self->{'robot'}         :
        $self->{'list'}  ? $self->{'list'}->robot() :
                           undef;
}

=item $message->get_size()

Gets the size of this message.

=cut

sub get_size {
    my ($self) = @_;

    return length $self->{'string'};
}

sub _load {
    my $self            = shift;
    my $messageasstring = shift;

    # Get metadata

    unless ($self->{'noxsympato'}) {
        pos($messageasstring) = 0;
        while ($messageasstring =~ /\G(X-Sympa-\w+): (.*?)\n(?![ \t])/cgs) {
            my ($k, $v) = ($1, $2);
            next unless length $v;

            if ($k eq 'X-Sympa-To') {    # obsoleted; for migration
                $self->{'rcpt'} = join ',', split(/\s*,\s*/, $v);
            } elsif ($k eq 'X-Sympa-Checksum') {    # obsoleted; for migration
                $self->{'checksum'} = $v;
            } elsif ($k eq 'X-Sympa-Family') {
                $self->{'family'} = $v;
            } elsif ($k eq 'X-Sympa-From') {
                $self->{'envelope_sender'} = $v;
            } elsif ($k eq 'X-Sympa-Authenticated') {
                $self->{'authenticated'} = $v;
            } elsif ($k eq 'X-Sympa-Sender') {
                $self->{'sender_email'} = $v;
            } elsif ($k eq 'X-Sympa-Gecos') {
                $self->{'sender_gecos'} = $v;
            } elsif ($k eq 'X-Sympa-Spam-Status') {
                $self->{'spam_status'} = $v;
            } else {
                $main::logger->do_log('warn',
                    'Unknown meta information: "%s: %s"',
                    $k, $v);
            }
        }

        # Strip meta information
        substr($messageasstring, 0, pos $messageasstring) = '';
    }

    $self->{'string'} = $messageasstring;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    $self->{'entity'} = $parser->parse_data(\$messageasstring);

    return $self;
}

=item $message->to_string()

Returns serialized data for this message.

=cut

sub to_string {
    my $self = shift;

    my $str = '';
    if (ref $self->{'rcpt'} eq 'ARRAY' and @{$self->{'rcpt'}}) {
        $str .= sprintf "X-Sympa-To: %s\n", join(',', @{$self->{'rcpt'}});
    } elsif (defined $self->{'rcpt'} and length $self->{'rcpt'}) {
        $str .= sprintf "X-Sympa-To: %s\n",
            join(',', split(/\s*,\s*/, $self->{'rcpt'}));
    }
    if (defined $self->{'checksum'}) {
        $str .= sprintf "X-Sympa-Checksum: %s\n", $self->{'checksum'};
    }
    if (defined $self->{'family'}) {
        $str .= sprintf "X-Sympa-Family: %s\n", $self->{'family'};
    }
    if (defined $self->{'envelope_sender'}) {
        $str .= sprintf "X-Sympa-From: %s\n", $self->{'envelope_sender'};
    }
    if (defined $self->{'authenticated'}) {
        $str .= sprintf "X-Sympa-Authenticated: %s\n",
            $self->{'authenticated'};
    }
    if (defined $self->{'sender_email'}) {
        $str .= sprintf "X-Sympa-Sender: %s\n", $self->{'sender_email'};
    }
    if (defined $self->{'sender_gecos'} and length $self->{'sender_gecos'}) {
        $str .= sprintf "X-Sympa-Gecos: %s\n", $self->{'sender_gecos'};
    }
    if ($self->{'spam_status'}) {
        $str .= sprintf "X-Sympa-Spam-Status: %s\n", $self->{'spam_status'};
    }

    $str .= $self->{'string'};

    return $str;
}

=item $message->get_header( FIELD, [ SEP ] )

Gets value(s) of header field FIELD, stripping trailing newline.

B<In scalar context> without SEP, returns first occurrence or I<undef>.
If SEP is defined, returns all occurrences joined by it, or I<undef>.
Otherwise B<in array context>, returns an array of all occurrences or I<()>.

Note:
Folding newlines will not be removed.

=cut

sub get_header {
    my $self  = shift;
    my $field = shift;
    my $sep   = shift;

    my $hdr = $self->as_entity()->head;

    if (defined $sep or wantarray) {
        my @values = grep {s/\A$field\s*:\s*//i}
            split /\n(?![ \t])/, $hdr->as_string();
        if (defined $sep) {
            return undef unless @values;
            return join $sep, @values;
        }
        return @values;
    } else {
        my $value = $hdr->get($field, 0);
        chomp $value if defined $value;
        return $value;
    }
}

=item $message->get_envelope_sender()

Gets the enveloper sender of this message.

=cut

sub get_envelope_sender {
    my ($self) = @_;

    $self->_set_envelope_sender() unless $self->{'envelope_sender'};

    return $self->{'envelope_sender'};
}

sub _set_envelope_sender {
    my ($self) = @_;

    ## We trust in Return-Path: header field at the top of message.
    ## To add it to messages by MDA:
    ## - Sendmail:   Add 'P' in the 'F=' flags of local mailer line (such
    ##               as 'Mlocal').
    ## - Postfix:
    ##   - local(8): Available by default.
    ##   - pipe(8):  Add 'R' in the 'flags=' attributes of master.cf.
    ## - Exim:       Set 'return_path_add' to true with pipe_transport.
    ## - qmail:      Use preline(1).
    my $headers = $self->as_entity()->head->header();
    my $i       = 0;
    $i++ while $headers->[$i] and $headers->[$i] =~ /^X-Sympa-/;
    if ($headers->[$i] and $headers->[$i] =~ /^Return-Path:\s*(.+)$/) {
        my $addr = $1;
        if ($addr =~ /<>/) {
            $self->{'envelope_sender'} = '<>';
        } else {
            my @addrs = Mail::Address->parse($addr);
            if (@addrs and Sympa::Tools::valid_email($addrs[0]->address)) {
                $self->{'envelope_sender'} = $addrs[0]->address;
            }
        }
    }
}

=item $message->get_sender_email(%params)

Gets the email part of the sender address (ie, "user@domain" for "User
<user@domain>"), according to the given headers.

Parameters:

=over

=item * I<headers>: the list of allowed headers, as a comma-separated string
(default: Resent-From,From,From_,Resent-Sender,Sender)

=back

=cut

sub get_sender_email {
    my ($self, %params) = @_;

    $self->_set_sender_email(%params) unless $self->{'sender_email'};

    return $self->{'sender_email'};
}

=item $message->get_sender_gecos(%params)

Gets the label part of the sender address (ie, "User" for "User
<user@domain>"), according to the given headers.

Parameters:

=over

=item * I<headers>: the list of allowed headers, as a comma-separated string
(default: Resent-From,From,From_,Resent-Sender,Sender)

=back

=cut

sub get_sender_gecos {
    my ($self, %params) = @_;

    $self->_set_sender_email(%params) unless $self->{'sender_gecos'};

    return $self->{'sender_gecos'};
}

sub _set_sender_email {
    my ($self, %params) = @_;

    my $headers = $params{headers} ||
                  'Resent-From,From,From_,Resent-Sender,Sender';

    my $hdr    = $self->as_entity()->head;
    my $sender = undef;
    my $gecos  = undef;
    foreach my $field (split /[\s,]+/, $headers) {
        if (lc $field eq 'from_') {
            ## Try to get envelope sender
            my $envelope_sender = $self->get_envelope_sender();
            if ($envelope_sender and $envelope_sender ne '<>') {
                $sender = $envelope_sender;
                last;
            }
        } elsif ($hdr->get($field)) {
            ## Try to get message header
            ## On "Resent-*:" headers, the first occurrence must be used.
            ## Though "From:" can occur multiple times, only the first
            ## one is detected.
            my @sender_hdr = Mail::Address->parse($hdr->get($field));
            if (scalar @sender_hdr and $sender_hdr[0]->address) {
                $sender = lc($sender_hdr[0]->address);
                my $phrase = $sender_hdr[0]->phrase;
                if (defined $phrase and length $phrase) {
                    $gecos = MIME::EncWords::decode_mimewords($phrase,
                        Charset => 'UTF-8');
                }
                last;
            }
        }
    }

    $self->{'sender_email'} = $sender;
    $self->{'sender_gecos'} = $gecos;
}

sub has_valid_sender {
    my ($self) = @_;

    my $sender = $self->get_sender_email();

    return $sender && Sympa::Tools::valid_email($sender);
}

sub get_decoded_subject {
    my ($self) = @_;

    $self->_set_decoded_subject() unless $self->{'decoded_subject'};

    return $self->{'decoded_subject'};
}

sub get_subject_charset {
    my ($self) = @_;

    $self->_set_decoded_subject() unless $self->{'subject_charset'};

    return $self->{'subject_charset'};
}

sub _set_decoded_subject {
    my ($self) = @_;

    my $hdr = $self->as_entity()->head;
    ## Store decoded subject and its original charset
    my $subject = $hdr->get('Subject');
    if (defined $subject and $subject =~ /\S/) {
        my @decoded_subject = MIME::EncWords::decode_mimewords($subject);
        $self->{'subject_charset'} = 'US-ASCII';
        foreach my $token (@decoded_subject) {
            unless ($token->[1]) {

                # don't decode header including raw 8-bit bytes.
                if ($token->[0] =~ /[^\x00-\x7F]/) {
                    $self->{'subject_charset'} = undef;
                    last;
                }
                next;
            }
            my $cset = MIME::Charset->new($token->[1]);

            # don't decode header encoded with unknown charset.
            unless ($cset->decoder) {
                $self->{'subject_charset'} = undef;
                last;
            }
            unless ($cset->output_charset eq 'US-ASCII') {
                $self->{'subject_charset'} = $token->[1];
            }
        }
    } else {
        $self->{'subject_charset'} = undef;
    }
    if ($self->{'subject_charset'}) {
        $self->{'decoded_subject'} =
            $self->decode_header('Subject');
    } else {
        if ($subject) {
            chomp $subject;
            $subject =~ s/(\r\n|\r|\n)([ \t])/$2/g;
        }
        $self->{'decoded_subject'} = $subject;
    }
}

=item $message->is_spam()

Returns a true value if this message is considered spam.

=cut

sub is_spam {
    my ($self) = @_;

    $self->_set_spam_status() unless $self->{'spam_status'};

    return $self->{'spam_status'} && $self->{'spam_status'} eq 'spam';
}

sub _set_spam_status {
    my ($self) = @_;

    return unless $self->{robot};

    require Sympa::Scenario;
    my $scenario = Sympa::Scenario->new(
        that     => $self->{robot},
        function => 'spam_status',
        name     => $self->{robot}->spam_status(),
    );
    unless ($scenario) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Failed to load scenario for "spam_status"'
        );
        $self->{'spam_status'} = 'unknown';
        return;
    }

    my $action = $scenario->evaluate(
        that        => $self->{robot},
        operation   => 'spam_status',
        auth_method => 'smtp',
        context     => {
            'message' => $self
        }
    );

    $self->{'spam_status'} =
        !defined $action      ? 'unknown'           :
        ref $action eq 'HASH' ? $action->{'action'} :
                                $action             ;
}

sub get_dkim_status {
    my ($self) = @_;

    $self->_set_dkim_status() unless $self->{'dkim_status'};

    return $self->{'dkim_status'};
}

sub _set_dkim_status {
    my ($self) = @_;

    return unless $self->{robot};
    return unless $self->{robot}->dkim_feature eq 'on';

    $self->{'dkim_status'} = Sympa::Tools::DKIM::verifier($self->{'string'});
}

=item $message->is_authenticated()

Returns a true value if this message is authenticated.

=cut

sub is_authenticated {
    return shift->{'authenticated'};
}

=item $message->decrypt()

Decrypts this message.

Parameters:

=over

=item * I<openssl>: path to openssl binary (default: 'openssl')

=item * I<tmpdir>: path to temporary file directory (default: '/tmp')

=item * I<ssl_cert_dir>: path to Sympa certificate/keys directory.

=item * I<key_password>: key password

=back

Returns a true value on success, C<undef> otherwise.

=cut

sub decrypt {
    my ($self, %params) = @_;

    my $tmpdir       = $params{tmpdir} || '/tmp';
    my $openssl      = $params{openssl} || 'openssl';
    my $ssl_cert_dir = $params{ssl_cert_dir};
    my $key_password = $params{key_password};

    return undef unless $self->is_encrypted();

    my $from = $self->get_header('From');

    $main::logger->do_log(Sympa::Logger::DEBUG2,
        'Decrypting message from %s', $from
    );

    my ($certs, $keys) = Sympa::Tools::SMIME::find_keys($ssl_cert_dir, 'decrypt');
    unless (defined $certs && @$certs) {
        $main::logger->do_log(Sympa::Logger::ERR,
            "Unable to decrypt message : missing certificate file");
        return undef;
    }

    local $ENV{OPENSSL_PASSWORD} = $key_password if $key_password;

    ## try all keys/certs until one decrypts.
    my $decrypted_entity;
    while (my $certfile = shift @$certs) {
        my $keyfile = shift @$keys;
        $main::logger->do_log(Sympa::Logger::DEBUG, 'Trying decrypt with %s, %s',
            $certfile, $keyfile);

        my $decrypted_message_file = File::Temp->new(
            DIR    => $tmpdir,
            UNLINK => $main::options{'debug'} ? 0 : 1
        );

        my $command =
            "$openssl smime -decrypt -out $decrypted_message_file" . 
            " -recip $certfile -inkey $keyfile" .
            ($key_password ? " -passin env:OPENSSL_PASSWORD" : "" );
        $main::logger->do_log(Sympa::Logger::DEBUG3, '%s', $command);

        my $command_handle;
        if (!open($command_handle, '|-', $command)) {
            $main::logger->do_log(
                Sympa::Logger::ERR,
                'Unable to execute command %s: %s',
                $command, $ERRNO
            );
            return undef;
        }

        $self->{'entity'}->print($command_handle);
        close $command_handle;

        my $status = $CHILD_ERROR >> 8;
        if ($status) {
            $main::logger->do_log(
                Sympa::Logger::ERR, 'Unable to decrypt S/MIME message: (%d) %s',
                $status, ($openssl_errors{$status} || 'unknown reason')
            );
            next;
        }

        my $parser = MIME::Parser->new();
        $parser->output_to_core(1);
        $decrypted_entity = $parser->parse($decrypted_message_file);
        unless ($decrypted_entity) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Unable to parse message');
            last;
        }
    }

    unless ($decrypted_entity) {
        $main::logger->do_log(Sympa::Logger::ERR, 'Message could not be decrypted');
        return undef;
    }

    ## foreach header defined in the incoming message but undefined in the
    ## decrypted message, add this header in the decrypted form.
    my $predefined_headers;
    foreach my $header ($decrypted_entity->head->tags) {
        if ($decrypted_entity->head->get($header)) {
            $predefined_headers->{lc $header} = 1;
        }
    }
    foreach my $header (split /\n(?![ \t])/,
        $self->as_entity()->head->as_string()) {
        next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
        my ($tag, $val) = ($1, $2);
        unless ($predefined_headers->{lc $tag}) {
            $decrypted_entity->head->add($tag, $val);
        }
    }
    ## Some headers from the initial message should not be restored
    ## Content-Disposition and Content-Transfer-Encoding if the result is
    ## multipart
    $decrypted_entity->head->delete('Content-Disposition')
        if ($decrypted_entity->head->get('Content-Disposition'));
    if ($decrypted_entity->head->get('Content-Type') =~ /multipart/) {
        $decrypted_entity->head->delete('Content-Transfer-Encoding')
            if (
            $decrypted_entity->head->get('Content-Transfer-Encoding'));
    }

    # keep original entity (is this really needed ?)
    $self->{'old_entity'} = $self->{'entity'};

    # replace current entity
    $self->{'entity'} = $decrypted_entity;
    $self->{'string'} = $decrypted_entity->as_string();

    # switch encrypted flag off
    undef $self->{'encrypted'};

    $main::logger->do_log(Sympa::Logger::NOTICE,
        "message %s has been decrypted", $self
    );

    return 1;
}

=item $message->decrypt_if_needed()

Decrypts this message, but only if in S/MIME format.

See $message->decrypt() for parameters and return value.

=cut

sub decrypt_if_needed {
    my ($self, %params) = @_;

    return $self->is_encrypted() ? $self->decrypt(%params) : 1;
}

=item $message->check_signature(%params)

Check the signature of this message.

Parameters:

=over

=item * I<cafile>: path to a CA certificate file.

=item * I<capath>: path to a CA certificate directory.

=item * I<openssl>: path to openssl binary (default: 'openssl')

=item * I<tmpdir>: path to temporary file directory (default: '/tmp')

=item * I<ssl_cert_dir>: path to Sympa certificate/keys directory.

=back

Return a data structure corresponding to the signer certificate on
success, C<undef> otherwise.

=cut

sub check_signature {
    my ($self, %params) = @_;

    my $tmpdir       = $params{tmpdir} || '/tmp';
    my $openssl      = $params{openssl} || 'openssl';
    my $cafile       = $params{cafile};
    my $capath       = $params{capath};
    my $ssl_cert_dir = $params{ssl_cert_dir};

    $main::logger->do_log(Sympa::Logger::DEBUG2, '(sender=%s, filename=%s)',
        $self->{'sender_email'}, $self->{'file'});

    return undef unless $self->is_signed();

    my $certificate_file = File::Temp->new(
        DIR    => $tmpdir,
        UNLINK => $main::options{'debug'} ? 0 : 1
    );

    my $command = "$openssl smime -verify -signer $certificate_file " .
        ($cafile ? "-CAfile $cafile" : '')          .
        ($capath ? "-CApath $capath" : '')          .
        ">/dev/null";
    $main::logger->do_log(Sympa::Logger::DEBUG2, '%s', $command);

    my $command_handle;
    unless (open $command_handle, '|-', $command) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to execute command %s: %s',
            $command, $ERRNO
        );
        return undef;
    }

    $self->{'entity'}->print($command_handle);
    close $command_handle;

    my $status = $CHILD_ERROR >> 8;
    if ($status) {
        $main::logger->do_log(
            Sympa::Logger::ERR, 'Unable to check S/MIME signature: (%d) %s',
            $status, ($openssl_errors{$status} || 'unknown reason')
        );
        return undef;
    }
    ## second step is the message signer match the sender
    ## a better analyse should be performed to extract the signer email.
    my $certificate = Sympa::Tools::SMIME::parse_cert(
        file    => $certificate_file,
        tmpdir  => $tmpdir,
        openssl => $openssl,
    );

    unless (Sympa::Tools::any { $_ eq lc($self->{'sender_email'}) } @{$certificate->{'email'}}) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            "S/MIME signed message, sender(%s) does NOT match signer(%s)",
            $self->{'sender_email'},
            join(',', @{$certificate->{'email'}})
        );
        return undef;
    }

    $main::logger->do_log(
        Sympa::Logger::DEBUG,
        "S/MIME signed message, signature checked and sender match signer(%s)",
        join(',', @{$certificate->{'email'}})
    );
    ## store the signer certificat
    unless (-d $ssl_cert_dir) {
        if (mkdir($ssl_cert_dir, 0775)) {
            $main::logger->do_log(Sympa::Logger::INFO, 'creating spool %s',
                $ssl_cert_dir);
        } else {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unable to create user certificat directory %s',
                $ssl_cert_dir);
        }
    }

    ## It gets a bit complicated now. openssl smime -signer only puts
    ## the _signing_ certificate into the given file; to get all included
    ## certs, we need to extract them from the signature proper, and then
    ## we need to check if they are for our user (CA and intermediate certs
    ## are also included), and look at the purpose:
    ## "S/MIME signing : Yes/No"
    ## "S/MIME encryption : Yes/No"
    my $certbundle = $tmpdir . "/certbundle.$PID";
    my $tmpcert    = $tmpdir . "/cert.$PID";
    my $nparts     = $self->{'entity'}->parts;
    my $extracted  = 0;
    $main::logger->do_log(Sympa::Logger::DEBUG3, 'smime_sign_check: parsing %d parts',
        $nparts);
    if ($nparts == 0) {    # could be opaque signing...
        $extracted += Sympa::Tools::SMIME::extract_certs(
            entity  => $self->{'entity'},
            file    => $certbundle,
            openssl => $openssl
        );
    } else {
        for (my $i = 0; $i < $nparts; $i++) {
            my $part = $self->{'entity'}->parts($i);
            $extracted += Sympa::Tools::SMIME::extract_certs(
                entity  => $part,
                file    => $certbundle,
                openssl => $openssl
            );
            last if $extracted;
        }
    }

    unless ($extracted) {
        $main::logger->do_log(Sympa::Logger::ERR,
            "No application/x-pkcs7-* parts found");
        return undef;
    }

    unless (open(BUNDLE, $certbundle)) {
        $main::logger->do_log(Sympa::Logger::ERR, "Can't open cert bundle %s: %s",
            $certbundle, $ERRNO);
        return undef;
    }

    ## read it in, split on "-----END CERTIFICATE-----"
    my $cert = '';
    my (%certs);
    while (<BUNDLE>) {
        $cert .= $_;
        if (/^-----END CERTIFICATE-----$/) {
            my $workcert = $cert;
            $cert = '';
            unless (open(CERT, ">$tmpcert")) {
                $main::logger->do_log(Sympa::Logger::ERR, "Can't create %s: %s",
                    $tmpcert, $ERRNO);
                return undef;
            }
            print CERT $workcert;
            close(CERT);
            my ($parsed) = Sympa::Tools::SMIME::parse_cert(
                file => $tmpcert,
                tmpdir  => $tmpdir,
                openssl => $openssl,
            );
            unless ($parsed) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'No result from parse_cert');
                return undef;
            }
            unless ($parsed->{'email'}) {
                $main::logger->do_log(Sympa::Logger::DEBUG,
                    'No email in cert for %s, skipping',
                    $parsed->{subject});
                next;
            }

            $main::logger->do_log(
                Sympa::Logger::DEBUG2,
                "Found cert for <%s>",
                join(',', @{$parsed->{'email'}})
            );
            if (Sympa::Tools::any { $_ eq lc($self->{'sender_email'}) } @{$parsed->{'email'}}) {
                if (   $parsed->{'purpose'}{'sign'}
                    && $parsed->{'purpose'}{'enc'}) {
                    $certs{'both'} = $workcert;
                    $main::logger->do_log(Sympa::Logger::DEBUG,
                        'Found a signing + encryption cert');
                } elsif ($parsed->{'purpose'}{'sign'}) {
                    $certs{'sign'} = $workcert;
                    $main::logger->do_log(Sympa::Logger::DEBUG,
                        'Found a signing cert');
                } elsif ($parsed->{'purpose'}{'enc'}) {
                    $certs{'enc'} = $workcert;
                    $main::logger->do_log(Sympa::Logger::DEBUG,
                        'Found an encryption cert');
                }
            }
            last if (($certs{'both'}) || ($certs{'sign'} && $certs{'enc'}));
        }
    }
    close(BUNDLE);
    if (!($certs{both} || ($certs{sign} || $certs{enc}))) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            "Could not extract certificate for %s",
            join(',', keys %{$certificate->{'email'}})
        );
        return undef;
    }
    ## OK, now we have the certs, either a combined sign+encryption one
    ## or a pair of single-purpose. save them, as email@addr if combined,
    ## or as email@addr@sign / email@addr@enc for split certs.
    foreach my $c (keys %certs) {
        my $fn = $ssl_cert_dir . '/'
            . Sympa::Tools::escape_chars(lc($self->{'sender_email'}));
        if ($c ne 'both') {
            unlink($fn);    # just in case there's an old cert left...
            $fn .= "\@$c";
        } else {
            unlink("$fn\@enc");
            unlink("$fn\@sign");
        }
        $main::logger->do_log(Sympa::Logger::DEBUG, 'Saving %s cert in %s', $c, $fn);
        unless (open(CERT, ">$fn")) {
            $main::logger->do_log(Sympa::Logger::ERR,
                'Unable to create certificate file %s: %s',
                $fn, $ERRNO);
            return undef;
        }
        print CERT $certs{$c};
        close(CERT);
    }

    unless ($main::options{'debug'}) {
        unlink($tmpcert);
        unlink($certbundle);
    }

    # future version should check if the subject was part of the SMIME
    # signature.
    $self->{'smime_signed'}  = 1;
    $self->{'smime_subject'} = $certificate;

    return 1;
}

=item $message->check_signature_if_needed(%params)

Check the signature of this message, but only if digitally signed.

See $message->check_signature() for parameters and return value.

=cut

sub check_signature_if_needed {
    my ($self, %params) = @_;

    return $self->is_signed() ? $self->check_signature(%params) : 1;
}

=item $message->dump($output)

Dumps this message to a stream.

Parameters:

=over 4

=item * I<$output>: the stream to which dump the object

=back 

Returns a true value for success.

=cut 

sub dump {
    my ($self, $output) = @_;

    #    my $output ||= \*STDERR;

    my $old_output = select;
    select $output;

    foreach my $key (keys %{$self}) {
        if (ref($self->{$key}) eq 'MIME::Entity') {
            printf "%s =>\n", $key;
            $self->{$key}->print;
        } else {
            printf "%s => %s\n", $key, $self->{$key};
        }
    }

    select $old_output;

    return 1;
}

=item $message->add_topic($topic)

Add topic and put header X-Sympa-Topic.

Parameters:

=over 4

=item * I<$topic>: the topic, as a string

=back 

=cut 

sub add_topic {
    my ($self, $topic) = @_;

    $self->{entity}->head()->add('X-Sympa-Topic', $topic);
}

=item $message->get_topic()

Gets the topic of this message.

=cut 

sub get_topic {
    my ($self) = @_;

    return $self->{entity}->head()->get('X-Sympa-Topic');
}

sub clean_html {
    my $self  = shift;
    my $robot = shift;
    my $new_msg;
    if ($new_msg = _fix_html_part($self->as_entity(), $robot)) {
        $self->{'entity'} = $new_msg;
        $self->{'string'} = $new_msg->as_string();
        return 1;
    }
    return 0;
}

sub _fix_html_part {
    my $part  = shift;
    my $robot = shift;
    return $part unless $part;

    my $eff_type = $part->head->mime_attr("Content-Type");
    if ($part->parts) {
        my @newparts = ();
        foreach ($part->parts) {
            push @newparts, _fix_html_part($_, $robot);
        }
        $part->parts(\@newparts);
    } elsif ($eff_type =~ /^text\/html/i) {
        my $bodyh = $part->bodyhandle;

        # Encoded body or null body won't be modified.
        return $part if !$bodyh or $bodyh->is_encoded;

        my $body = $bodyh->as_string();

        # Re-encode parts to UTF-8, since StripScripts cannot handle texts
        # with some charsets (ISO-2022-*, UTF-16*, ...) correctly.
        my $cset =
            MIME::Charset->new($part->head->mime_attr('Content-Type.Charset')
                || '');
        unless ($cset->decoder) {

            # Charset is unknown.  Detect 7-bit charset.
            my (undef, $charset) =
                MIME::Charset::body_encode($body, '', Detect7Bit => 'YES');
            $cset = MIME::Charset->new($charset)
                if $charset;
        }
        if (    $cset->decoder
            and $cset->as_string() ne 'UTF-8'
            and $cset->as_string() ne 'US-ASCII') {
            $cset->encoder('UTF-8');
            $body = $cset->encode($body);
            $part->head->mime_attr('Content-Type.Charset', 'UTF-8');
        }

        my $filtered_body =
            Sympa::Tools::sanitize_html('string' => $body, 'robot' => $robot);

        my $io = $bodyh->open("w");
        unless (defined $io) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Failed to save message : %s',
                $ERRNO);
            return undef;
        }
        $io->print($filtered_body);
        $io->close;
        $part->sync_headers(Length => 'COMPUTE');
    }
    return $part;
}

# extract body as string from msg_as_string
# do NOT use Mime::Entity in order to preserveB64 encoding form and so
# preserve S/MIME signature
sub get_body_from_msg_as_string {
    my $msg = shift;

    # convert it as a tab with headers as first element
    my @bodysection = split "\n\n", $msg;
    shift @bodysection;    # remove headers
    return (join("\n\n", @bodysection));    # convert it back as string
}

=item $message->encrypt(%parameter)

Encrypts this message for the given recipient, using S/MIME format.

Parameters:

=over

=item * I<email>: FIXME

=item * I<openssl>: path to openssl binary (default: 'openssl')

=item * I<tmpdir>: path to temporary file directory (default: '/tmp')

=item * I<ssl_cert_dir>: path to Sympa certificate/keys directory.

=back

=cut

sub encrypt {
    my ($self, %params) = @_;
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s, %s)', @_);

    my $tmpdir       = $params{tmpdir} || '/tmp';
    my $openssl      = $params{openssl} || 'openssl';
    my $ssl_cert_dir = $params{ssl_cert_dir};
    my $email        = $params{email};

    my $usercert;

    my $base = $ssl_cert_dir . '/' . Sympa::Tools::escape_chars($email);
    if (-f "$base\@enc") {
        $usercert = "$base\@enc";
    } else {
        $usercert = "$base";
    }

    unless (-r $usercert) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'unable to encrypt message to %s (missing certificate %s)',
            $email, $usercert);
        return undef;
    }
    
    # clone original MIME entity, and discard all headers excepted
    # mime and content ones
    my $entity = $self->{'entity'}->dup();
    foreach my $header ($entity->head->tags) {
        $entity->head->delete($header)
            unless $header =~ /^(mime|content)-/i;
    }

    my $encrypted_message_file = File::Temp->new(
        DIR    => $tmpdir,
        UNLINK => $main::options{'debug'} ? 0 : 1
    );

    my $command =
        "$openssl smime -encrypt -out $encrypted_message_file -des3 $usercert";
    $main::logger->do_log(Sympa::Logger::DEBUG3, '%s', $command);

    my $command_handle;
    if (!open($command_handle, '|-', $command)) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to execute command %s: %s',
            $command, $ERRNO
        );
        return undef;
    }
    $entity->print($command_handle);
    close $command_handle;

    my $status = $CHILD_ERROR >> 8;
    if ($status) {
        $main::logger->do_log(
            Sympa::Logger::ERR, 'Unable to S/MIME encrypt message: (%d) %s',
            $status, ($openssl_errors{$status} || 'unknown reason')
        );
        return undef;
    }

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    my $encrypted_entity =  $parser->read($encrypted_message_file);
    unless ($encrypted_entity) {
        $main::logger->do_log(Sympa::Logger::NOTICE, 'Unable to parse message');
        return undef;
    }

    ## foreach header defined in  the incomming message but undefined in
    ## the
    ## crypted message, add this header in the crypted form.
    my $predefined_headers;
    foreach my $header ($encrypted_entity->head->tags) {
        $predefined_headers->{lc $header} = 1
            if ($encrypted_entity->head->get($header));
    }
    foreach my $header (split /\n(?![ \t])/,
        $self->{'entity'}->head->as_string()) {
        next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
        my ($tag, $val) = ($1, $2);
        $encrypted_entity->head->add($tag, $val)
            unless $predefined_headers->{lc $tag};
    }
    
    # keep original entity (is this really needed ?)
    $self->{'old_entity'} = $self->{'entity'};

    # replace current entity
    $self->{'entity'} = $encrypted_entity;
    $self->{'string'} = $encrypted_entity->as_string();

    # switch encrypted flag on
    $self->{'encrypted'} = 1;

    $main::logger->do_log(Sympa::Logger::NOTICE,
        "message %s has been encrypted", $self
    );

    return 1;
}

=item $message->sign()

Sign this message digitally, using S/MIME format.

Parameters:

=over

=item * I<openssl>: path to openssl binary (default: 'openssl')

=item * I<tmpdir>: path to temporary file directory (default: '/tmp')

=item * I<ssl_cert_dir>: path to Sympa certificate/keys directory.

=item * I<key_password>: key password

=back

=cut

sub sign {
    my ($self, %params) = @_;

    my $tmpdir       = $params{tmpdir} || '/tmp';
    my $openssl      = $params{openssl} || 'openssl';
    my $ssl_cert_dir = $params{ssl_cert_dir};
    my $key_password = $params{key_password};

    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s)', $self);

    my ($cert, $key) = Sympa::Tools::SMIME::find_keys($ssl_cert_dir, 'sign');

    # clone original MIME entity, and discard all headers excepted
    # content-type and content-transfer-encoding
    my $entity = $self->{'entity'}->dup();
    foreach my $header ($entity->head->tags) {
        $entity->head->delete($header)
            unless $header =~ /^(content-type|content-transfer-encoding)$/i
    }

    my $signed_message_file = File::Temp->new(
        DIR    => $tmpdir,
        UNLINK => $main::options{'debug'} ? 0 : 1
    );

    local $ENV{OPENSSL_PASSWORD} = $key_password if $key_password;

    my $command = "$openssl smime -sign"                             .
        " -signer $cert -inkey $key " .  "-out $signed_message_file" .
        ($key_password ? " -passin env:OPENSSL_PASSWORD" : "" );
    $main::logger->do_log(Sympa::Logger::DEBUG2, '%s', $command);

    my $command_handle;
    unless (open $command_handle, '|-', $command) {
        $main::logger->do_log(
            Sympa::Logger::ERR,
            'Unable to execute command %s: %s',
            $command, $ERRNO
        );
        return undef;
    }
    $entity->print($command_handle);
    close $command_handle;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    my $signed_entity = $parser->read($signed_message_file);
    unless ($signed_entity) {
        $main::logger->do_log(Sympa::Logger::NOTICE, 'Unable to parse message');
        return undef;
    }

    ## foreach header defined in  the incoming message but undefined in the
    ## crypted message, add this header in the crypted form.
    my $predefined_headers;
    foreach my $header ($signed_entity->head->tags) {
        $predefined_headers->{lc $header} = 1
            if ($signed_entity->head->get($header));
    }
    foreach my $header (split /\n(?![ \t])/,
        $self->{'entity'}->head->as_string()) {
        next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
        my ($tag, $val) = ($1, $2);
        $signed_entity->head->add($tag, $val)
            unless $predefined_headers->{lc $tag};
    }

    $self->{'entity'} = $signed_entity;
    $self->{'string'} = $signed_entity->as_string();

    return 1;
}


sub set_message_as_string {
    my $self = shift;

    $self->{'string'} = shift;
}

sub _reset_message_from_entity {
    my $self   = shift;
    my $entity = shift;

    unless (ref($entity) =~ /^MIME/) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Can not reset a message by starting from object %s',
            ref $entity);
        return undef;
    }
    $self->{'entity'} = $entity;
    $self->{'string'} = $entity->as_string();
    if ($self->is_encrypted) {
        $self->{'decrypted_msg'}           = $entity;
        $self->{'decrypted_msg_as_string'} = $entity->as_string();
    }
    return 1;
}

sub get_msg_id {
    my $self = shift;
    unless ($self->{'id'}) {
        $self->{'id'} = $self->{'entity'}->head->get('Message-Id');
        chomp $self->{'id'} if $self->{'id'};
    }
    return $self->{'id'};
}

=item $message->is_signed()

Returns a true value if this message is digitally signed.

=cut

sub is_signed {
    my ($self) = @_;

    my $content_type = $self->{'entity'}->head()->get('Content-Type');
    return
        $content_type =~ /multipart\/signed/ ||
            (
                $content_type =~ /application\/(x-)?pkcs7-mime/i &&
                $content_type =~ /signed-data/i
            );
}

=item $message->is_encrypted()

Returns a true value if this message is encrypted.

=cut

sub is_encrypted {
    my ($self) = @_;

    my $content_type = $self->{'entity'}->head()->get('Content-Type');
    return
        $content_type =~ /application\/(x-)?pkcs7-mime/i && 
        $content_type !~ /signed-data/i;
}

sub has_html_part {
    my $self = shift;
    $self->check_message_structure
        unless ($self->{'structure_already_checked'});
    return $self->{'has_html_part'};
}

sub has_text_part {
    my $self = shift;
    $self->check_message_structure
        unless ($self->{'structure_already_checked'});
    return $self->{'has_text_part'};
}

sub has_attachments {
    my $self = shift;
    $self->check_message_structure
        unless ($self->{'structure_already_checked'});
    return $self->{'has_attachments'};
}

## Make a multipart/alternative, a singlepart
sub check_message_structure {
    $main::logger->do_log(Sympa::Logger::DEBUG2, '(%s, %s)', @_);
    my $self = shift;
    my $msg  = shift;
    $msg ||= $self->{'entity'}->dup;
    $self->{'structure_already_checked'} = 1;
    if ($msg->effective_type() =~ /^multipart\/alternative/) {
        foreach my $part ($msg->parts) {
            if (($part->effective_type() =~ /^text\/html$/)
                || (   ($part->effective_type() =~ /^multipart\/related$/)
                    && $part->parts
                    && ($part->parts(0)->effective_type() =~ /^text\/html$/))
                ) {
                $main::logger->do_log(Sympa::Logger::DEBUG3, 'Found html part');
                $self->{'has_html_part'} = 1;
            } elsif ($part->effective_type() =~ /^text\/plain$/) {
                $main::logger->do_log(Sympa::Logger::DEBUG3, 'Found text part');
                $self->{'has_text_part'} = 1;
            } else {
                $main::logger->do_log(Sympa::Logger::DEBUG3, 'Found attachment: %s',
                    $part->effective_type());
                $self->{'has_attachments'} = 1;
            }
        }
    } elsif ($msg->effective_type() =~ /multipart\/signed/) {
        my @parts = $msg->parts();
        ## Only keep the first part
        $msg->parts([$parts[0]]);
        $msg->make_singlepart();
        $self->check_message_structure($msg);

    } elsif ($msg->effective_type() =~ /^multipart/) {
        $main::logger->do_log(Sympa::Logger::DEBUG3, 'Found multipart: %s',
            $msg->effective_type());
        foreach my $part ($msg->parts) {
            next unless (defined $part);    ## Skip empty parts
            if ($part->effective_type() =~ /^multipart\/alternative/) {
                $self->check_message_structure($part);
            } else {
                $main::logger->do_log(Sympa::Logger::DEBUG3, 'Found attachment: %s',
                    $part->effective_type());
                $self->{'has_attachments'} = 1;
            }
        }
    }
}

## Add footer/header to a message
sub _add_parts {
    my $self = shift;
    unless ($self->{'list'}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'The message %s has no list context; No header/footer to add',
            $self);
        return undef;
    }
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(%s, list=%s, type=%s)',
        $self, $self->{'list'}, $self->{'list'}->footer_type);

    my $msg      = $self->{'entity'};
    my $type     = $self->{'list'}->footer_type;
    my $listdir  = $self->{'list'}->dir;
    my $eff_type = $msg->effective_type || 'text/plain';

    ## Signed or encrypted messages won't be modified.
    if ($eff_type =~ /^multipart\/(signed|encrypted)$/i) {
        return $msg;
    }

    my $header;
    foreach my $file (
        "$listdir/message.header",
        "$listdir/message.header.mime",
        Sympa::Site->etc . '/mail_tt2/message.header',
        Sympa::Site->etc . '/mail_tt2/message.header.mime'
        ) {
        if (-f $file) {
            unless (-r $file) {
                $main::logger->do_log(Sympa::Logger::NOTICE, 'Cannot read %s', $file);
                next;
            }
            $header = $file;
            last;
        }
    }

    my $footer;
    foreach my $file (
        "$listdir/message.footer",
        "$listdir/message.footer.mime",
        Sympa::Site->etc . '/mail_tt2/message.footer',
        Sympa::Site->etc . '/mail_tt2/message.footer.mime'
        ) {
        if (-f $file) {
            unless (-r $file) {
                $main::logger->do_log(Sympa::Logger::NOTICE, 'Cannot read %s', $file);
                next;
            }
            $footer = $file;
            last;
        }
    }

    ## No footer/header
    unless (($footer and -s $footer) or ($header and -s $header)) {
        return undef;
    }

    if ($type eq 'append') {
        ## append footer/header
        my ($footer_msg, $header_msg);
        if ($header and -s $header) {
            open HEADER, $header;
            $header_msg = join '', <HEADER>;
            close HEADER;
            $header_msg = '' unless $header_msg =~ /\S/;
        }
        if ($footer and -s $footer) {
            open FOOTER, $footer;
            $footer_msg = join '', <FOOTER>;
            close FOOTER;
            $footer_msg = '' unless $footer_msg =~ /\S/;
        }
        if (length $header_msg or length $footer_msg) {
            if (_append_parts($msg, $header_msg, $footer_msg)) {
                $msg->sync_headers(Length => 'COMPUTE')
                    if $msg->head->get('Content-Length');
            }
        }
    } else {
        ## MIME footer/header
        my $parser = MIME::Parser->new();
        $parser->output_to_core(1);

        if (   $eff_type =~ /^multipart\/alternative/i
            || $eff_type =~ /^multipart\/related/i) {
            $main::logger->do_log(Sympa::Logger::DEBUG3,
                'Making message %s into multipart/mixed', $self);
            $msg->make_multipart("mixed", Force => 1);
        }

        if ($header and -s $header) {
            if ($header =~ /\.mime$/) {
                my $header_part;
                eval { $header_part = $parser->parse_in($header); };
                if ($EVAL_ERROR) {
                    $main::logger->do_log(Sympa::Logger::ERR,
                        'Failed to parse MIME data %s: %s',
                        $header, $parser->last_error);
                } else {
                    $msg->make_multipart unless $msg->is_multipart;
                    $msg->add_part($header_part, 0);  ## Add AS FIRST PART (0)
                }
                ## text/plain header
            } else {
                $msg->make_multipart unless $msg->is_multipart;
                my $header_part = build MIME::Entity
                    Path       => $header,
                    Type       => "text/plain",
                    Filename   => undef,
                    'X-Mailer' => undef,
                    Encoding   => "8bit",
                    Charset    => "UTF-8";
                $msg->add_part($header_part, 0);
            }
        }
        if ($footer and -s $footer) {
            if ($footer =~ /\.mime$/) {
                my $footer_part;
                eval { $footer_part = $parser->parse_in($footer); };
                if ($EVAL_ERROR) {
                    $main::logger->do_log(Sympa::Logger::ERR,
                        'Failed to parse MIME data %s: %s',
                        $footer, $parser->last_error);
                } else {
                    $msg->make_multipart unless $msg->is_multipart;
                    $msg->add_part($footer_part);
                }
                ## text/plain footer
            } else {
                $msg->make_multipart unless $msg->is_multipart;
                $msg->attach(
                    Path       => $footer,
                    Type       => "text/plain",
                    Filename   => undef,
                    'X-Mailer' => undef,
                    Encoding   => "8bit",
                    Charset    => "UTF-8"
                );
            }
        }
    }

    return $msg;
}

## Append header/footer to text/plain body.
## Note: As some charsets (e.g. UTF-16) are not compatible to US-ASCII,
##   we must concatenate decoded header/body/footer and at last encode it.
## Note: With BASE64 transfer-encoding, newline must be normalized to CRLF,
##   however, original body would be intact.
sub _append_parts {
    my $part       = shift;
    my $header_msg = shift || '';
    my $footer_msg = shift || '';

    my $enc = $part->head->mime_encoding;

    # Parts with nonstandard encodings aren't modified.
    if ($enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i) {
        return undef;
    }
    my $eff_type = $part->effective_type || 'text/plain';
    my $body;
    my $io;

    ## Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}i) {
        return undef;
    }

    ## Skip attached parts.
    my $disposition = $part->head->mime_attr('Content-Disposition');
    return undef
        if $disposition and uc $disposition ne 'INLINE';

    ## Preparing header and footer for inclusion.
    if ($eff_type eq 'text/plain' or $eff_type eq 'text/html') {
        if (length $header_msg or length $footer_msg) {

            ## Only decodable bodies are allowed.
            my $bodyh = $part->bodyhandle;
            if ($bodyh) {
                return undef if $bodyh->is_encoded;
                $body = $bodyh->as_string();
            } else {
                $body = '';
            }

            $body = _append_footer_header_to_part(
                {   'part'     => $part,
                    'header'   => $header_msg,
                    'footer'   => $footer_msg,
                    'eff_type' => $eff_type,
                    'body'     => $body
                }
            );
            return undef unless defined $body;

            $io = $bodyh->open('w');
            unless (defined $io) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Failed to save message: %s', $ERRNO);
                return undef;
            }
            $io->print($body);
            $io->close;
            $part->sync_headers(Length => 'COMPUTE')
                if $part->head->get('Content-Length');

            return 1;
        }
    } elsif ($eff_type eq 'multipart/mixed') {
        ## Append to the first part, since other parts will be "attachments".
        if ($part->parts
            and _append_parts($part->parts(0), $header_msg, $footer_msg)) {
            return 1;
        }
    } elsif ($eff_type eq 'multipart/alternative') {
        ## We try all the alternatives
        my $r = undef;
        foreach my $p ($part->parts) {
            $r = 1
                if _append_parts($p, $header_msg, $footer_msg);
        }
        return $r if $r;
    } elsif ($eff_type eq 'multipart/related') {
        ## Append to the first part, since other parts will be "attachments".
        if ($part->parts
            and _append_parts($part->parts(0), $header_msg, $footer_msg)) {
            return 1;
        }
    }

    ## We couldn't find any parts to modify.
    return undef;
}

# Styles to cancel local CSS.
my $div_style =
    'background: transparent; border: none; clear: both; display: block; float: none; position: static';

sub _append_footer_header_to_part {
    my $data = shift;

    my $part       = $data->{'part'};
    my $header_msg = $data->{'header'};
    my $footer_msg = $data->{'footer'};
    my $eff_type   = $data->{'eff_type'};
    my $body       = $data->{'body'};

    my $cset;

    ## Detect charset.  If charset is unknown, detect 7-bit charset.
    my $charset = $part->head->mime_attr('Content-Type.Charset');
    $cset = MIME::Charset->new($charset || 'NONE');
    unless ($cset->decoder) {

        # n.b. detect_7bit_charset() in MIME::Charset prior to 1.009.2 doesn't
        # work correctly.
        my (undef, $charset) =
            MIME::Charset::body_encode($body, '', Detect7Bit => 'YES');
        $cset = MIME::Charset->new($charset)
            if $charset;
    }
    unless ($cset->decoder) {

        #$main::logger->do_log(Sympa::Logger::ERR, 'Unknown charset "%s"', $charset);
        return undef;
    }

    ## Decode body to Unicode, since encode_entities() and newline
    ## normalization will break texts with several character sets (UTF-16/32,
    ## ISO-2022-JP, ...).
    eval {
        $body = $cset->decode($body, 1);
        $header_msg = Encode::decode_utf8($header_msg, 1);
        $footer_msg = Encode::decode_utf8($footer_msg, 1);
    };
    return undef if $EVAL_ERROR;

    my $new_body;
    if ($eff_type eq 'text/plain') {
        $main::logger->do_log(Sympa::Logger::DEBUG3, "Treating text/plain part");

        ## Add newlines. For BASE64 encoding they also must be normalized.
        if (length $header_msg) {
            $header_msg .= "\n" unless $header_msg =~ /\n\z/;
        }
        if (length $footer_msg and length $body) {
            $body .= "\n" unless $body =~ /\n\z/;
        }
        if (uc($part->head->mime_attr('Content-Transfer-Encoding') || '') eq
            'BASE64') {
            $header_msg =~ s/\r\n|\r|\n/\r\n/g;
            $body       =~ s/(\r\n|\r|\n)\z/\r\n/;    # only at end
            $footer_msg =~ s/\r\n|\r|\n/\r\n/g;
        }

        $new_body = $header_msg . $body . $footer_msg;
    } elsif ($eff_type eq 'text/html') {
        $main::logger->do_log(Sympa::Logger::DEBUG3, "Treating text/html part");

        # Escape special characters.
        $header_msg = encode_entities($header_msg, '<>&"');
        $header_msg =~ s/(\r\n|\r|\n)$//;        # strip the last newline.
        $header_msg =~ s,(\r\n|\r|\n),<br/>,g;
        $footer_msg = encode_entities($footer_msg, '<>&"');
        $footer_msg =~ s/(\r\n|\r|\n)$//;        # strip the last newline.
        $footer_msg =~ s,(\r\n|\r|\n),<br/>,g;

        my @bodydata = split '</body>', $body;
        if (length $header_msg) {
            $new_body = sprintf '<div style="%s">%s</div>',
                $div_style, $header_msg;
        } else {
            $new_body = '';
        }
        my $i = -1;
        foreach my $html_body_bit (@bodydata) {
            $new_body .= $html_body_bit;
            $i++;
            if ($i == $#bodydata and length $footer_msg) {
                $new_body .= sprintf '<div style="%s">%s</div></body>',
                    $div_style, $footer_msg;
            } else {
                $new_body .= '</body>';
            }
        }
    }

    ## Only encodable footer/header are allowed.
    eval { $new_body = $cset->encode($new_body, 1); };
    return undef if $EVAL_ERROR;

    return $new_body;
}

=item $message->personalize($list, [ $recipient ])

Personalize a message with custom attributes of a user.

Parameters:

=over 4

=item * I<$list>: a L<Sympa::List> object.

=item * I<$recipient>: the recipient email

=back

Returns the modified message itself, or I<undef> for failure.
Note that message can be modified in case of error.

=cut

sub personalize {
    my $self = shift;
    my $list = shift;
    my $rcpt = shift || undef;

    my $entity = _personalize_entity($self->as_entity(), $list, $rcpt);
    unless (defined $entity) {
        return undef;
    }
    if ($entity) {
        $self->{'string'} = $entity->as_string();
    }
    return $self;
}

sub _personalize_entity {
    my $entity = shift;
    my $list   = shift;
    my $rcpt   = shift;

    my $enc = $entity->head->mime_encoding;

    # Parts with nonstandard encodings aren't modified.
    if ($enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i) {
        return $entity;
    }
    my $eff_type = $entity->effective_type || 'text/plain';

    # Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}) {
        return $entity;
    }

    if ($entity->parts) {
        foreach my $part ($entity->parts) {
            unless (defined _personalize_entity($part, $list, $rcpt)) {
                $main::logger->do_log(Sympa::Logger::ERR,
                    'Failed to personalize message part');
                return undef;
            }
        }
    } elsif ($eff_type =~ m{^(?:multipart|message)(?:/|\Z)}i) {

        # multipart or message types without subparts.
        return $entity;
    } elsif (MIME::Tools::textual_type($eff_type)) {
        my ($charset, $in_cset, $bodyh, $body, $utf8_body);

        # Encoded body or null body won't be modified.
        $bodyh = $entity->bodyhandle;
        if (!$bodyh or $bodyh->is_encoded) {
            return $entity;
        }
        $body = $bodyh->as_string();
        unless (defined $body and length $body) {
            return $entity;
        }

        ## Detect charset.  If charset is unknown, detect 7-bit charset.
        $charset = $entity->head->mime_attr('Content-Type.Charset');
        $in_cset = MIME::Charset->new($charset || 'NONE');
        unless ($in_cset->decoder) {
            $in_cset =
                MIME::Charset->new(MIME::Charset::detect_7bit_charset($body)
                    || 'NONE');
        }
        unless ($in_cset->decoder) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Unknown charset "%s"',
                $charset);
            return undef;
        }
        $in_cset->encoder($in_cset);    # no charset conversion

        ## Only decodable bodies are allowed.
        eval { $utf8_body = Encode::encode_utf8($in_cset->decode($body, 1)); };
        if ($EVAL_ERROR) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Cannot decode by charset "%s"',
                $charset);
            return undef;
        }

        ## PARSAGE ##
        $utf8_body = personalize_text($utf8_body, $list, $rcpt);
        unless (defined $utf8_body) {
            $main::logger->do_log(Sympa::Logger::ERR, 'error personalizing message');
            return undef;
        }

        ## Data not encodable by original charset will fallback to UTF-8.
        my ($newcharset, $newenc);
        ($body, $newcharset, $newenc) =
            $in_cset->body_encode(Encode::decode_utf8($utf8_body),
            Replacement => 'FALLBACK');
        unless ($newcharset) {    # bug in MIME::Charset?
            $main::logger->do_log(Sympa::Logger::ERR,
                'Can\'t determine output charset');
            return undef;
        } elsif ($newcharset ne $in_cset->as_string()) {
            $entity->head->mime_attr('Content-Transfer-Encoding' => $newenc);
            $entity->head->mime_attr('Content-Type.Charset' => $newcharset);

            ## normalize newline to CRLF if transfer-encoding is BASE64.
            $body =~ s/\r\n|\r|\n/\r\n/g
                if $newenc
                    and $newenc eq 'BASE64';
        } else {
            ## normalize newline to CRLF if transfer-encoding is BASE64.
            $body =~ s/\r\n|\r|\n/\r\n/g
                if $enc
                    and uc $enc eq 'BASE64';
        }

        ## Save new body.
        my $io = $bodyh->open('w');
        unless ($io
            and $io->print($body)
            and $io->close) {
            $main::logger->do_log(Sympa::Logger::ERR, 'Can\'t write in Entity: %s',
                $ERRNO);
            return undef;
        }
        $entity->sync_headers(Length => 'COMPUTE')
            if $entity->head->get('Content-Length');

        return $entity;
    }

    return $entity;
}

=item $message->test_personalize($list)

Test if personalization can be performed successfully over all subscribers
of I<$list>.

Returns a true value, or I<undef> for failure.

=cut

sub test_personalize {
    my $self = shift;
    my $list = shift;

    return 1
        unless $list->merge_feature
            and $list->merge_feature eq 'on';

    $list->get_list_members_per_mode($self);
    foreach my $mode (keys %{$self->{'rcpts_by_mode'}}) {
        my $message = dclone $self;
        $message->prepare_message_according_to_mode($mode);

        foreach my $rcpt (
            @{$message->{'rcpts_by_mode'}{$mode}{'verp'}   || []},
            @{$message->{'rcpts_by_mode'}{$mode}{'noverp'} || []}
            ) {
            unless ($message->personalize($list, $rcpt)) {
                return undef;
            }
        }
    }
    return 1;
}


sub prepare_message_according_to_mode {
    my $self = shift;
    my $mode = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3, '(msg_id=%s, mode=%s)',
        $self->get_msg_id, $mode);
    ##Prepare message for normal reception mode
    if ($mode eq 'mail') {
        $self->_prepare_reception_mail;
    } elsif (($mode eq 'nomail')
        || ($mode eq 'summary')
        || ($mode eq 'digest')
        || ($mode eq 'digestplain')) {
        ##Prepare message for notice reception mode
    } elsif ($mode eq 'notice') {
        $self->_prepare_reception_notice;
        ##Prepare message for txt reception mode
    } elsif ($mode eq 'txt') {
        $self->_prepare_reception_txt;
        ##Prepare message for html reception mode
    } elsif ($mode eq 'html') {
        $self->_prepare_reception_html;
        ##Prepare message for urlize reception mode
    } elsif ($mode eq 'url') {
        $self->_prepare_reception_urlize;
    } else {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unknown variable/reception mode %s', $mode);
        return undef;
    }

    unless (defined $self) {
        $main::logger->do_log(Sympa::Logger::ERR, "Failed to create Message object");
        return undef;
    }
    return 1;

}

sub _prepare_reception_mail {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'preparing message for mail reception mode');
    ## Add footer and header
    return 0 if ($self->is_signed);
    my $new_msg = $self->_add_parts;
    if (defined $new_msg) {
        $self->{'entity'}  = $new_msg;
        $self->{'altered'} = '_ALTERED_';
        $self->{'string'}  = $new_msg->as_string();
    } else {
        $main::logger->do_log(Sympa::Logger::ERR, 'Part addition failed');
        return undef;
    }
    return 1;
}

sub _prepare_reception_notice {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'preparing message for notice reception mode');
    my $notice_msg = $self->{'entity'}->dup;
    $notice_msg->bodyhandle(undef);
    $notice_msg->parts([]);
    if ((   $notice_msg->head->get('Content-Type') =~
            /application\/(x-)?pkcs7-mime/i
        )
        && ($notice_msg->head->get('Content-Type') !~ /signed-data/i)
        ) {
        $notice_msg->head->delete('Content-Disposition');
        $notice_msg->head->delete('Content-Description');
        $notice_msg->head->replace('Content-Type',
            'text/plain; charset="US-ASCII"');
        $notice_msg->head->replace('Content-Transfer-Encoding', '7BIT');
    }
    $self->_reset_message_from_entity($notice_msg);
    undef $self->{'encrypted'};
    return 1;
}

sub _prepare_reception_txt {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'preparing message for txt reception mode');
    return 0 if ($self->is_signed);
    if (Sympa::Tools::Message::as_singlepart($self->{'entity'}, 'text/plain')) {
        $main::logger->do_log(Sympa::Logger::NOTICE,
            'Multipart message changed to text singlepart');
    }
    ## Add a footer
    $self->_reset_message_from_entity($self->_add_parts);
    return 1;
}

sub _prepare_reception_html {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'preparing message for html reception mode');
    return 0 if ($self->is_signed);
    if (Sympa::Tools::Message::as_singlepart($self->{'entity'}, 'text/html')) {
        $main::logger->do_log(Sympa::Logger::NOTICE,
            'Multipart message changed to html singlepart');
    }
    ## Add a footer
    $self->_reset_message_from_entity($self->_add_parts);
    return 1;
}

sub _prepare_reception_urlize {
    my $self = shift;
    $main::logger->do_log(Sympa::Logger::DEBUG3,
        'preparing message for urlize reception mode');
    return 0 if ($self->is_signed);
    unless ($self->{'list'}) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'The message has no list context; Nowhere to place urlized attachments.'
        );
        return undef;
    }

    my $expl = $self->{'list'}->dir . '/urlized';

    unless ((-d $expl) || (mkdir $expl, 0775)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to create urlize directory %s', $expl);
        return undef;
    }

    my $dir1 =
        Sympa::Tools::clean_msg_id(
        $self->{'entity'}->head->get('Message-ID'));

    ## Clean up Message-ID
    $dir1 = Sympa::Tools::escape_chars($dir1);
    $dir1 = '/' . $dir1;

    unless (mkdir("$expl/$dir1", 0775)) {
        $main::logger->do_log(Sympa::Logger::ERR,
            'Unable to create urlize directory %s/%s',
            $expl, $dir1);
        printf "Unable to create urlized directory %s/%s\n", $expl, $dir1;
        return 0;
    }
    my @parts      = ();
    my $i          = 0;
    foreach my $part ($self->{'entity'}->parts()) {
        my $entity =
            _urlize_part($part, $self->{'list'}, $dir1, $i,
            $self->{'list'}->robot->wwsympa_url);
        if (defined $entity) {
            push @parts, $entity;
        } else {
            push @parts, $part;
        }
        $i++;
    }

    ## Replace message parts
    $self->{'entity'}->parts(\@parts);

    ## Add a footer
    $self->_reset_message_from_entity($self->_add_parts);
    return 1;
}

sub _urlize_part {
    my $message     = shift;
    my $list        = shift;
    my $expl        = $list->dir . '/urlized';
    my $dir         = shift;
    my $i           = shift;
    my $listname    = $list->name;
    my $wwsympa_url = shift;

    my $head     = $message->head;
    my $encoding = $head->mime_encoding;
    my $eff_type = $message->effective_type || 'text/plain';
    return undef
        if $eff_type =~ /multipart\/alternative/gi
            or $eff_type =~ /text\//gi;
    ##  name of the linked file
    my $fileExt = Sympa::Tools::WWW::get_mime_type($head->mime_type);
    if ($fileExt) {
        $fileExt = '.' . $fileExt;
    }
    my $filename;

    if ($head->recommended_filename) {
        $filename = $head->recommended_filename;
    } else {
        if ($head->mime_type =~ /multipart\//i) {
            my $content_type = $head->get('Content-Type');
            $content_type =~ s/multipart\/[^;]+/multipart\/mixed/g;
            $message->head->replace('Content-Type', $content_type);
            my @parts = $message->parts();
            foreach my $i (0 .. $#parts) {
                my $entity =
                    _urlize_part($message->parts($i), $list, $dir, $i,
                    $list->robot->wwsympa_url);
                if (defined $entity) {
                    $parts[$i] = $entity;
                }
            }
            ## Replace message parts
            $message->parts(\@parts);
        }
        $filename = "msg.$i" . $fileExt;
    }

    ##create the linked file
    ## Store body in file
    if (open OFILE, ">$expl/$dir/$filename") {
        my $ct = $message->effective_type || 'text/plain';
        printf OFILE "Content-type: %s", $ct;
        printf OFILE "; Charset=%s", $head->mime_attr('Content-Type.Charset')
            if $head->mime_attr('Content-Type.Charset') =~ /\S/;
        print OFILE "\n\n";
    } else {
        $main::logger->do_log(Sympa::Logger::NOTICE, 'Unable to open %s/%s/%s',
            $expl, $dir, $filename);
        return undef;
    }

    if ($encoding =~
        /^(binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64)$/
        ) {
        open TMP, ">$expl/$dir/$filename.$encoding";
        $message->print_body(\*TMP);
        close TMP;

        open BODY, "$expl/$dir/$filename.$encoding";
        my $decoder = MIME::Decoder->($encoding);
        $decoder->decode(\*BODY, \*OFILE);
        unlink "$expl/$dir/$filename.$encoding";
    } else {
        $message->print_body(\*OFILE);
    }
    close(OFILE);
    my $file = "$expl/$dir/$filename";
    my $size = (-s $file);

    ## Only URLize files with a moderate size
    if ($size < Sympa::Site->urlize_min_size) {
        unlink "$expl/$dir/$filename";
        return undef;
    }

    ## Delete files created twice or more (with Content-Type.name and Content-
    ## Disposition.filename)
    $message->purge;

    (my $file_name = $filename) =~ s/\./\_/g;

    # do NOT escape '/' chars
    my $file_url = "$wwsympa_url/attach/$listname"
        . Sympa::Tools::escape_chars("$dir/$filename", '/');

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    my $new_part;

    my $lang    = $main::language->get_lang();
    my $charset = Site->get_charset();

    my $tt2_include_path = $list->get_etc_include_path('mail_tt2', $lang);

    Sympa::Template::parse_tt2(
        {   'file_name' => $file_name,
            'file_url'  => $file_url,
            'file_size' => $size,
            'charset'   => $charset
        },
        'urlized_part.tt2',
        \$new_part,
        $tt2_include_path
    );

    my $entity = $parser->parse_data(\$new_part);

    return $entity;
}

=item $message->get_id()

Get unique ID for object.

=cut

sub get_id {
    my $self = shift;
    return sprintf 'key=%s;id=%s',
        ($self->{'messagekey'} || ''),
        Sympa::Tools::clean_msg_id($self->get_msg_id || '');
}

=back

=head1 FUNCTIONS

=over 4

=item personalize_text($body, $list, [ $recipient ])

Retrieves the customized data of the
users then parse the text. It returns the
personalized text.

Parameters:

=over 4

=item * I<$body>: the message body with the TT2

=item * I<$list>: a L<Sympa::List> object

=item * I<$recipient>: the recipient email

=back

Returns the customized text, or I<undef> for failure.

=cut

sub personalize_text {
    my $body = shift;
    my $list = shift;
    my $rcpt = shift || undef;

    my $options;
    $options->{'is_not_template'} = 1;

    my $user = $list->user('member', $rcpt);
    if ($user) {
        $user->{'escaped_email'} = URI::Escape::uri_escape($rcpt);
        $user->{'friendly_date'} =
            $main::language->gettext_strftime("%d %b %Y  %H:%M", localtime($user->{'date'}));
    }

    # this method as been removed because some users may forward
    # authentication link
    # $user->{'fingerprint'} = Sympa::Tools::get_fingerprint($rcpt);

    my $data = {
        'listname'    => $list->name,
        'robot'       => $list->domain,
        'wwsympa_url' => $list->robot->wwsympa_url,
    };
    $data->{'user'} = $user if $user;

    # Parse the TT2 in the message : replace the tags and the parameters by
    # the corresponding values
    my $output;
    unless (Sympa::Template::parse_tt2($data, \$body, \$output, '', $options)) {
        return undef;
    }

    return $output;
}

=item $message->decode_header($tag, $separator)

Return header value, decoded to UTF-8. trailing newline will be
removed. If sep is given, return all occurrences joined by it.

Parameters:

=over

=item * I<$tag>: FIXME

=item * I<$separator>: FIXME

=back

Returns decoded header(s), with hostile characters (newline, nul) removed.

=cut

sub decode_header {
    my ($self, $tag, $sep) = @_;

    my $head = $self->as_entity()->head;

    if (defined $sep) {
        my @values = $head->get($tag);
        return undef unless scalar @values;
        foreach my $val (@values) {
            $val = MIME::EncWords::decode_mimewords($val, Charset => 'UTF-8');
            chomp $val;
            $val =~ s/(\r\n|\r|\n)([ \t])/$2/g;    #unfold
            $val =~ s/\0|\r\n|\r|\n//g;            # remove newline & nul
        }
        return join $sep, @values;
    } else {
        my $val = $head->get($tag, 0);
        return undef unless defined $val;
        $val = MIME::EncWords::decode_mimewords($val, Charset => 'UTF-8');
        chomp $val;
        $val =~ s/(\r\n|\r|\n)([ \t])/$2/g;        #unfold
        $val =~ s/\0|\r\n|\r|\n//g;                # remove newline & nul

        return $val;
    }
}

=back

=cut

1;
