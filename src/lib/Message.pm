# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

Message - Mail message embedding for internal use in Sympa

=head1 DESCRIPTION 

While processing a message in Sympa, we need to link informations to the
message, modify headers and such.  This was quite a problem when a message was
signed, as modifying anything in the message body would alter its MD5
footprint. And probably make the message to be rejected by clients verifying
its identity (which is somehow a good thing as it is the reason why people use
MD5 after all). With such messages, the process was complex. We then decided
to embed any message treated in a "Message" object, thus making the process
easier.

=cut 

package Message;

use strict;
use warnings;
use Encode qw();
use HTML::Entities qw();
use Mail::Address;
use MIME::Charset;
use MIME::Decoder;
use MIME::Entity;
use MIME::EncWords;
use MIME::Parser;
use MIME::Tools;
use Storable qw();
use URI::Escape qw();

use Conf;
use Sympa::Language;
use List;
use Log;
use Scenario;
use tools;
use tt2;

# Language context
my $language = Sympa::Language->instance;

=head2 Methods and functions

=over

=item new ( parameter =E<gt> value, ... )

I<Constructor>.
Creates a new Message object.

Parameters:

=over 

=item $file

the message file

=item $noxsympato

a boolean

=back 

Returns:

=over 

=item a Message object

if created

=item undef

if something went wrong

=back 

=back

=cut 

## Creates a new object
sub new {
    Log::do_log('debug2', '(%s, ...)', @_);
    my $class           = shift;
    my $messageasstring = shift;

    my $self = bless {@_} => $class;

    if (ref $messageasstring) {
        Log::do_log('err', 
            'Deprecated: $messageasstring must be string, not %s',
            $messageasstring);
        return undef;
    }
    unless (defined $messageasstring and length $messageasstring) {
        Log::do_log('err', 'Empty message');
        return undef;
    }

    # Get attributes

    unless ($self->{'noxsympato'}) {
        pos($messageasstring) = 0;
        while ($messageasstring =~ /\G(X-Sympa-\w+): (.*?)\n(?![ \t])/cgs) {
            my ($k, $v) = ($1, $2);
            next unless length $v;

            if ($k eq 'X-Sympa-To') {
                $self->{'rcpt'} = join ',', split(/\s*,\s*/, $v);
            } elsif ($k eq 'X-Sympa-Checksum') {
                $self->{'checksum'} = $v;
            } elsif ($k eq 'X-Sympa-Family') {
                $self->{'family'} = $v;
            } elsif ($k eq 'X-Sympa-From') { # Compatibility. Use Return-Path:
                $self->{'envelope_sender'} = $v;
            } elsif ($k eq 'X-Sympa-Spam-Status') { # New in 6.2a.41
                $self->{'spam_status'} = $v;
            } else {
                Log::do_log('err', 'Unknown meta information: "%s: %s"',
                    $k, $v);
            }
        }

        # Ignore Unix From_
        $messageasstring =~ /\GFrom (.*?)\n(?![ \t])/cgs;

        # Get envelope sender from Return-Path:.
        # If old style X-Sympa-From: has been found, omit Return-Path:.
        #
        # We trust in "Return-Path:" header field only at the top of message
        # to prevent forgery.  To ensure it will be added to messages by MDA:
        # - Sendmail:   Add 'P' in the 'F=' flags of local mailer line (such
        #               as 'Mlocal').
        # - Postfix:
        #   - local(8): Available by default.
        #   - pipe(8):  Add 'R' in the 'flags=' attributes in master.cf.
        # - Exim:       Set 'return_path_add' to true with pipe_transport.
        # - qmail:      Use preline(1).
        if ($messageasstring =~ /\GReturn-Path: (.*?)\n(?![ \t])/cgs
            and not exists $self->{'envelope_sender'}) {
            my $addr = $1;
            if ($addr =~ /<>/) {    # special: null envelope sender
                $self->{'envelope_sender'} = '<>';
            } else {
                my @addrs = Mail::Address->parse($addr);
                if (@addrs and tools::valid_email($addrs[0]->address)) {
                    $self->{'envelope_sender'} = $addrs[0]->address;
                }
            }
        }

        # Strip attributes.
        substr($messageasstring, 0, pos $messageasstring) = '';
    }

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    my $msg = $parser->parse_data(\$messageasstring);
    unless ($msg) {
        Log::do_log('err', 'Unable to parse message');
        return undef;
    }
    my $hdr = $msg->head;
    my ($dummy, $body_string) = split /(?:\A|\n)\r?\n/, $messageasstring, 2;

    $self->{'msg'}  = $msg;
    $self->{_head}  = $hdr;
    $self->{_body}  = $body_string;
    $self->{'size'} = length $messageasstring;

    ($self->{'sender'}, $self->{'gecos'}) = $self->_get_sender_email;
    return undef unless defined $self->{'sender'};

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
        $self->{'decoded_subject'} = tools::decode_header($hdr, 'Subject');
    } else {
        if ($subject) {
            chomp $subject;
            $subject =~ s/(\r\n|\r|\n)(?=[ \t])//g;
            $subject =~ s/\r\n|\r|\n/ /g;
        }
        $self->{'decoded_subject'} = $subject;
    }

    ## valid X-Sympa-Checksum prove the message comes from web interface with
    ## authenticated sender
    if ($self->{'checksum'}) {
        if ($self->{'checksum'} eq tools::sympa_checksum($self->{'rcpt'})) {
            $self->{'md5_check'} = 1;
        } else {
            Log::do_log('err', 'Incorrect X-Sympa-Checksum header');
        }
    }

    ## S/MIME
    if ($Conf::Conf{'openssl'} && $self->{'noxsympato'} ) {
		## Decrypt messages
		if (   ($hdr->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i)
			&& ($hdr->get('Content-Type') !~ /signed-data/)) {
			my ($dec_head, $dec_body_as_string) =
				tools::smime_decrypt($self);

			unless ($dec_head) {
				Log::do_log('debug', "Message could not be decrypted");
				return undef;
				## We should the sender and/or the listmaster
			}

			$self->{'smime_crypted'} = 'smime_crypted';
			$self->{'orig_msg_as_string'} = $self->as_string;
                        $self->{_head} = $dec_head;
			$self->{_body} = $dec_body_as_string;
                        delete $self->{'msg'};    # Clear entity cache.
			Log::do_log('debug', 'Message has been decrypted');
		}

        ## Check S/MIME signatures
        if ($hdr->get('Content-Type') =~
            /multipart\/signed|application\/(x-)?pkcs7-mime/i) {
            ## Messages that should not be altered (no footer)
            $self->{'protected'} = 1;
            my $signed = tools::smime_sign_check($self);
            if ($signed->{'body'}) {
                $self->{'smime_signed'}  = 1;
                $self->{'smime_subject'} = $signed->{'subject'};
                Log::do_log('debug',
                    'Message is signed, signature is checked');
            }
            ## Il faudrait traiter les cas d'erreur (0 différent de undef)
        }
    }
    ## TOPICS
    my $topics;
    if ($topics = $hdr->get('X-Sympa-Topic')) {
        $self->{'topic'} = $topics;
    }

    # Message ID
    $self->{'message_id'} = _get_message_id($self);

    return $self;
}

# Tentative: removed when refactoring finished.
sub new_from_file {
    my $class = shift;
    my $file  = shift;

    open my $fh, '<', $file or return undef;
    my $messageasstring = do { local $/; <$fh> };
    close $fh;

    my $self = $class->new($messageasstring, @_)
        or return undef;

    $self->{'filename'} = $file;
    # Get file date
    unless (exists $self->{'date'}) {
        $self->{'date'} = tools::get_mtime($file);
    }

    return $self;
}

## Get sender of the message according to header fields specified by
## 'sender_headers' parameter.
## FIXME: S/MIME signer may not be same as the sender given by this function.
sub _get_sender_email {
    my $message = shift;

    my $hdr = $message->{_head};

    my $sender = undef;
    my $gecos  = undef;
    foreach my $field (split /[\s,]+/, $Conf::Conf{'sender_headers'}) {
        if (lc $field eq 'return-path') {
            ## Try to get envelope sender
            if (    $message->{'envelope_sender'}
                and $message->{'envelope_sender'} ne '<>') {
                $sender = lc($message->{'envelope_sender'});
            }
        } elsif ($hdr->get($field)) {
            ## Try to get message header.
            ## On "Resent-*:" headers, the first occurrence must be used (see
            ## RFC 5322 3.6.6).
            ## FIXME: Though "From:" can occur multiple times, only the first
            ## one is detected.
            my $addr = $hdr->get($field, 0);               # get the first one
            my @sender_hdr = Mail::Address->parse($addr);
            if (@sender_hdr and $sender_hdr[0]->address) {
                $sender = lc($sender_hdr[0]->address);
                my $phrase = $sender_hdr[0]->phrase;
                if (defined $phrase and length $phrase) {
                    $gecos = MIME::EncWords::decode_mimewords($phrase,
                        Charset => 'UTF-8');
                }
                last;
            }
        }

        last if defined $sender;
    }
    unless (defined $sender) {
        Log::do_log('err', 'No valid sender address');
        return undef;
    }
    unless (tools::valid_email($sender)) {
        Log::do_log('err', 'Invalid sender address "%s"', $sender);
        return undef;
    }

    return ($sender, $gecos);
}

# Note that this must be called after decrypting message
# FIXME: Also check Resent-Message-ID:.
sub _get_message_id {
    my $self = shift;

    return tools::clean_msg_id($self->{_head}->get('Message-Id', 0));
}

=over 4

=item to_string

I<Serializer>.
Returns serialized data of Message object.

=back

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
    if (defined $self->{'spam_status'}) {    # New in 6.2a.41.
        $str .= sprintf "X-Sympa-Spam-Status: %s\n", $self->{'spam_status'};
    }
    # This terminates pseudo-header part for attributes.
    unless (defined $self->{'envelope_sender'}) {
        $str .= "Return-Path: \n";
    }

    $str .= $self->as_string;

    return $str;
}

=over

=item add_header ( $field, $value, [ $index ] )

I<Instance method>.
XXX

=back

=cut

sub add_header {
    my $self = shift;
    $self->{_head}->add(@_);
    delete $self->{'msg'};   # Clear entity cache.
}

=over

=item delete_header ( $field, [ $index ] )

I<Instance method>.
XXX

=back

=cut

sub delete_header {
    my $self = shift;
    $self->{_head}->delete(@_);
    delete $self->{'msg'};   # Clear entity cache.
}

=over

=item replace_header ( $field, $value, [ $index ] )

I<Instance method>.
XXX

=back

=cut

sub replace_header {
    my $self = shift;
    $self->{_head}->replace(@_);
    delete $self->{'msg'};   # Clear entity cache.
}

=over

=item head

I<Instance method>.
Get header of the message as L<MIME::Head> instance.

Note that returned value is real reference to internal data structure.
Even if it was changed, string representaion of message won't be updated.
Alternatively, use L</add_header>(), L</delete_header>() or
L</replace_header() to modify header.

=back

=cut

sub head {
    shift->{_head};
}

=over

=item check_spam_status ( )

I<Instance method>.
Get spam status according to spam_status scenario.
XXX

=back

=cut

# NOTE: As this processes is needed for incoming messages only, it would be
# moved to incoming pipeline class..
sub check_spam_status {
    my $self = shift;

    my $robot_id = $self->{'list'}
        ? $self->{'list'}->{'domain'}
        : $self->{'robot'};

    my $spam_status = Scenario::request_action('spam_status', 'smtp',
        $robot_id || $Conf::Conf{'domain'}, {'message' => $self});
    if (defined $spam_status) {
        if (ref($spam_status) eq 'HASH') {
            $self->{'spam_status'} = $spam_status->{'action'};
        } else {
            $self->{'spam_status'} = $spam_status;
        }
    } else {
        $self->{'spam_status'} = 'unknown';
    }
}

# FIXME: Same as check_spam_status(): This should be moved to pipeline.
sub check_dkim_signature {
    my $self = shift;

    my $robot_id = $self->{'list'}
        ? $self->{'list'}->{'domain'}
        : $self->{'robot'};

    # verify DKIM signature
    if ($robot_id
        and tools::smart_eq(
            Conf::get_robot_conf($robot_id || '*', 'dkim_feature'), 'on'
        )
    ){
        $self->{'dkim_pass'} = tools::dkim_verifier($self->as_string);
    }
}

=over

=item as_entity ( )

I<Instance method>.
Get message content as MIME entity (L<MIME::Entity> instance).

Note that returned value is real reference to internal data structure.
Even if it was changed, string representaion of message won't be updated.
Below is better way to modify message.

    my $entity = $message->as_entity->dup;
    # Mofify entity...
    $message->set_entity($entity);

=back

=cut

sub as_entity {
    my $self = shift;

    unless (defined $self->{'msg'}) {
        die 'Bug in logic.  Ask developer'
            unless $self->{_head} and defined $self->{_body};
        my $string = $self->{_head}->as_string . "\n" . $self->{_body};

        my $parser = MIME::Parser->new();
        $parser->output_to_core(1);
        $self->{'msg'} = $parser->parse_data(\$string);
    }
    return $self->{'msg'};
}

=over

=item set_entity ( $entity )

I<Instance method>.
Update message with MIME entity (L<MIME::Entity> instance).
String representation will be automatically updated.

=back

=cut

sub set_entity {
    my $self   = shift;
    my $entity = shift;
    return undef unless $entity;

    local $Storable::canonical = 1;
    my $orig = Storable::freeze($self->as_entity);
    my $new  = Storable::freeze($entity);

    if ($orig ne $new) {
        $self->{_head} = $entity->head;
        $self->{_body} = $entity->body_as_string;
        $self->{'msg'} = $entity;   # Also update entity cache.
    }

    return $entity;
}

=over

=item as_string ( )

I<Instance method>.
Get a string representation of message in MIME-compliant format.

=back

=cut

sub as_string {
    my $self = shift;

    die 'Bug in logic.  Ask developer'
        unless $self->{_head} and defined $self->{_body};

    my $return_path = '';
    if (defined $self->{'envelope_sender'}) {
        my $val = $self->{'envelope_sender'};
        $val = "<$val>" unless $val eq '<>';
        $return_path = sprintf "Return-Path: %s\n", $val;
    }
    return $return_path . $self->{_head}->as_string . "\n" . $self->{_body};
}

=over

=item body_as_string ( )

I<Instance method>.
XXX

=back

=cut

sub body_as_string {
    my $self = shift;
    return $self->{_body};
}

=over

=item header_as_string ( )

I<Instance method>.
XXX

=back

=cut

sub header_as_string {
    my $self = shift;
    return $self->{_head}->as_string;
}

=over 4

=item get_header ( $field, [ $sep ] )

I<Instance method>.
Gets value(s) of header field $field, stripping trailing newline.

B<In scalar context> without $sep, returns first occurrence or C<undef>.
If $sep is defined, returns all occurrences joined by it, or C<undef>.
Otherwise B<in array context>, returns an array of all occurrences or C<()>.

Note:
Folding newlines will not be removed.

=back

=cut

sub get_header {
    my $self  = shift;
    my $field = shift;
    my $sep   = shift;
    die sprintf 'Second argument is not index but separator: "%s"', $sep
        if defined $sep and Scalar::Util::looks_like_number($sep);

    my $hdr = $self->{_head};

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

=over

=item dump ( $output )

I<Instance method>.
Dump a Message object to a stream.

Parameters:

=over 

=item $output

the stream to which dump the object

=back 

Returns:

=over 

=item 1

if everything's alright

=back 

=back

=cut 

## Dump the Message object
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

=over

=item add_topic ( $output )

I<Instance method>.
Add topic and put header X-Sympa-Topic.

Parameters:

=over 

=item $output

the string containing the topic to add

=back 

Returns:

=over 

=item 1

if everything's alright

=back 

=back

=cut 

## Add topic and put header X-Sympa-Topic
sub add_topic {
    my ($self, $topic) = @_;

    $self->{'topic'} = $topic;
    $self->add_header('X-Sympa-Topic', $topic);
}

=over

=item get_topic ( )

I<Instance method>.
Get topic of message.

Parameters:

None.

Returns:

=over 

=item the topic

if it exists

=item empty string

otherwise

=back 

=back

=cut 

## Get topic
sub get_topic {
    my ($self) = @_;

    if (defined $self->{'topic'}) {
        return $self->{'topic'};

    } else {
        return '';
    }
}

=over

=item clean_html ( $robot )

I<Instance method>.
XXX

=back

=cut

sub clean_html {
    my $self  = shift;
    my $robot = shift;

    my $entity = $self->as_entity->dup;
    if ($entity = _fix_html_part($entity, $robot)) {
        $self->set_entity($entity);
        return 1;
    }
    return 0;
}

sub _fix_html_part {
    my $entity = shift;
    my $robot  = shift;
    return $entity unless $entity;

    my $eff_type = $entity->head->mime_attr("Content-Type");
    if ($entity->parts) {
        my @newparts = ();
        foreach my $part ($entity->parts) {
            push @newparts, _fix_html_part($part, $robot);
        }
        $entity->parts(\@newparts);
    } elsif ($eff_type =~ /^text\/html/i) {
        my $bodyh = $entity->bodyhandle;
        # Encoded body or null body won't be modified.
        return $entity if !$bodyh or $bodyh->is_encoded;

        my $body = $bodyh->as_string;
        # Re-encode parts to UTF-8, since StripScripts cannot handle texts
        # with some charsets (ISO-2022-*, UTF-16*, ...) correctly.
        my $cset = MIME::Charset->new(
            $entity->head->mime_attr('Content-Type.Charset') || '');
        unless ($cset->decoder) {
            # Charset is unknown.  Detect 7-bit charset.
            my ($dummy, $charset) =
                MIME::Charset::body_encode($body, '', Detect7Bit => 'YES');
            $cset = MIME::Charset->new($charset)
                if $charset;
        }
        if (    $cset->decoder
            and $cset->as_string ne 'UTF-8'
            and $cset->as_string ne 'US-ASCII') {
            $cset->encoder('UTF-8');
            $body = $cset->encode($body);
            $entity->head->mime_attr('Content-Type.Charset', 'UTF-8');
        }

        my $filtered_body =
            tools::sanitize_html('string' => $body, 'robot' => $robot);

        my $io = $bodyh->open("w");
        unless (defined $io) {
            Log::do_log('err', 'Failed to save message: %m');
            return undef;
        }
        $io->print($filtered_body);
        $io->close;
        $entity->sync_headers(Length => 'COMPUTE')
            if $entity->head->get('Content-Length');
    }
    return $entity;
}

=over

=item personalize ( $list, [ $rcpt ], [ $data ] )

I<Instance method>.
Personalize a message with custom attributes of a user.

Parameters:

=over

=item $list

L<List> object.

=item $rcpt

Recipient.

=item $data

Hashref.  Additional data to be interpolated into personalized message.

=back

Returns:

Modified message itself, or C<undef> if error occurred.

=back

=cut

# Old name: Bulk::merge_msg()
sub personalize {
    my $self = shift;
    my $list = shift;
    my $rcpt = shift || undef;
    my $data = shift || {};

    my $entity = $self->as_entity->dup;

    # Initialize parameters at first only once.
    $data->{'headers'} ||= {};
    my $headers = $entity->head;
    foreach my $key (
        qw/subject x-originating-ip message-id date x-original-to from to thread-topic content-type/
        ) {
        next unless $headers->count($key);
        my $value = $headers->get($key, 0);
        chomp $value;
        $value =~ s/(?:\r\n|\r|\n)(?=[ \t])//g;    # unfold
        $data->{'headers'}{$key} = $value;
    }
    $data->{'subject'} = tools::decode_header($headers, 'Subject');

    unless (defined _merge_msg($entity, $list, $rcpt, $data)) {
        return undef;
    }

    $self->set_entity($entity);
    return $self;
}

sub _merge_msg {
    my $entity = shift;
    my $list   = shift;
    my $rcpt   = shift;
    my $data   = shift;

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
            unless (_merge_msg($part, $list, $rcpt, $data)) {
                Log::do_log('err', 'Failed to merge message part');
                return undef;
            }
        }
    } elsif ($eff_type =~ m{^(?:multipart|message)(?:/|\Z)}i) {
        # multipart or message types without subparts.
        return $entity;
    } elsif (MIME::Tools::textual_type($eff_type)) {
        my ($charset, $in_cset, $bodyh, $body, $utf8_body);

        $data->{'part'} = {
            description =>
                tools::decode_header($entity, 'Content-Description'),
            disposition =>
                lc($entity->head->mime_attr('Content-Disposition') || ''),
            encoding => $enc,
            type     => $eff_type,
        };

        $bodyh = $entity->bodyhandle;
        # Encoded body or null body won't be modified.
        if (!$bodyh or $bodyh->is_encoded) {
            return $entity;
        }

        $body = $bodyh->as_string;
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
            Log::do_log('err', 'Unknown charset "%s"', $charset);
            return undef;
        }
        $in_cset->encoder($in_cset);    # no charset conversion

        ## Only decodable bodies are allowed.
        eval { $utf8_body = Encode::encode_utf8($in_cset->decode($body, 1)); };
        if ($@) {
            Log::do_log('err', 'Cannot decode by charset "%s"', $charset);
            return undef;
        }

        ## PARSAGE ##

        my $message_output;
        unless (
            defined(
                $message_output =
                    personalize_text($utf8_body, $list, $rcpt, $data)
            )
            ) {
            Log::do_log('err', 'Error merging message');
            return undef;
        }
        $utf8_body = $message_output;

        ## Data not encodable by original charset will fallback to UTF-8.
        my ($newcharset, $newenc);
        ($body, $newcharset, $newenc) =
            $in_cset->body_encode(Encode::decode_utf8($utf8_body),
            Replacement => 'FALLBACK');
        unless ($newcharset) {    # bug in MIME::Charset?
            Log::do_log('err', 'Can\'t determine output charset');
            return undef;
        } elsif ($newcharset ne $in_cset->as_string) {
            $entity->head->mime_attr('Content-Transfer-Encoding' => $newenc);
            $entity->head->mime_attr('Content-Type.Charset' => $newcharset);

            ## normalize newline to CRLF if transfer-encoding is BASE64.
            $body =~ s/\r\n|\r|\n/\r\n/g
                if $newenc and $newenc eq 'BASE64';
        } else {
            ## normalize newline to CRLF if transfer-encoding is BASE64.
            $body =~ s/\r\n|\r|\n/\r\n/g
                if $enc and uc $enc eq 'BASE64';
        }

        ## Save new body.
        my $io = $bodyh->open('w');
        unless ($io
            and $io->print($body)
            and $io->close) {
            Log::do_log('err', 'Can\'t write in Entity: %s', $!);
            return undef;
        }
        $entity->sync_headers(Length => 'COMPUTE')
            if $entity->head->get('Content-Length');

        return $entity;
    }

    return $entity;
}

=over 4

=item test_personalize ( $list )

I<Instance method>.
Test if personalization can be performed successfully over all subscribers
of list.

Parameters:

Returns:

C<1> if succeed, or C<undef>.

=back

=cut

sub test_personalize {
    my $self = shift;
    my $list = shift;

    return 1
        unless tools::smart_eq($list->{'admin'}{'merge_feature'}, 'on');

    # Get available recipients to test.
    my $available_recipients = $list->get_recipients_per_mode($self) || {};
    # Always test all available reception modes using sender.
    foreach my $mode ('mail',
        grep { $_ and $_ ne 'nomail' and $_ ne 'not_me' }
        @{$list->{'admin'}{'available_user_options'}->{'reception'} || []}) {
        push @{$available_recipients->{$mode}{'verp'}}, $self->{'sender'};
    }

    foreach my $mode (sort keys %$available_recipients) {
        my $message = Storable::dclone $self;
        $message->prepare_message_according_to_mode($mode, $list);

        foreach my $rcpt (
            @{$available_recipients->{$mode}{'verp'}   || []},
            @{$available_recipients->{$mode}{'noverp'} || []}
            ) {
            unless ($message->personalize($list, $rcpt, {})) {
                return undef;
            }
        }
    }
    return 1;
}

=over

=item personalize_text ( $body, $list, [ $rcpt ], [ $data ] )

I<Function>.
Retrieves the customized data of the
users then parse the text. It returns the
personalized text.

Parameters:

=over

=item $body

Message body with the TT2.

=item $list

L<List> object.

=item $rcpt

The recipient email.

=item $data

Hashref.  Additional data to be interpolated into personalized message.

=back

Returns:

Customized text, or C<undef> if error occurred.

=back

=cut

# Old name: Bulk::merge_data()
sub personalize_text {
    my $body = shift;
    my $list = shift;
    my $rcpt = shift;
    my $data = shift || {};

    die 'Unexpected type of $list' unless ref $list eq 'List';

    my $listname = $list->{'name'};
    my $robot_id = $list->{'domain'};

    $data->{'listname'}    = $listname;
    $data->{'robot'}       = $robot_id;
    $data->{'wwsympa_url'} = Conf::get_robot_conf($robot_id, 'wwsympa_url');

    my $message_output;
    my $options;

    $options->{'is_not_template'} = 1;

    # get_list_member_no_object() return the user's details with the custom
    # attributes
    my $user = List::get_list_member_no_object(
        {   'email'  => $rcpt,
            'name'   => $listname,
            'domain' => $robot_id,
        }
    );

    if ($user) {
        $user->{'escaped_email'} = URI::Escape::uri_escape($rcpt);
        $user->{'friendly_date'} =
            $language->gettext_strftime("%d %b %Y  %H:%M",
            localtime($user->{'date'}));

        # this method has been removed because some users may forward
        # authentication link
        # $user->{'fingerprint'} = tools::get_fingerprint($rcpt);
    }

    $data->{'user'} = $user if $user;

    # Parse the TT2 in the message : replace the tags and the parameters by
    # the corresponding values
    return undef
        unless tt2::parse_tt2($data, \$body, \$message_output, '', $options);

    return $message_output;
}

=over

=item prepare_message_according_to_mode ( $mode, $list )

I<Instance method>.
XXX

=back

=cut

sub prepare_message_according_to_mode {
    my $self = shift;
    my $mode = shift;
    my $list = shift;

    my $robot_id = $list->{'domain'};

    if ($mode eq 'mail') {
        ##Prepare message for normal reception mode
        ## Add a footer
        unless ($self->{'protected'}) {
            my $entity = $self->as_entity->dup;

            _decorate_parts($entity, $list);
            $self->set_entity($entity);
        }
    } elsif ($mode eq 'nomail'
        or $mode eq 'summary'
        or $mode eq 'digest'
        or $mode eq 'digestplain') {
        ;
    } elsif ($mode eq 'notice') {
        ##Prepare message for notice reception mode
        my $entity = $self->as_entity->dup;

        $entity->bodyhandle(undef);
        $entity->parts([]);
        $self->set_entity($entity);
    } elsif ($mode eq 'txt') {
        ##Prepare message for txt reception mode
        my $entity = $self->as_entity->dup;

        if (tools::as_singlepart($entity, 'text/plain')) {
            Log::do_log('notice', 'Multipart message changed to singlepart');
        }
        ## Add a footer
        _decorate_parts($entity, $list);
        $self->set_entity($entity);
    } elsif ($mode eq 'html') {
        ##Prepare message for html reception mode
        my $entity = $self->as_entity->dup;

        if (tools::as_singlepart($entity, 'text/html')) {
            Log::do_log('notice', 'Multipart message changed to singlepart');
        }
        ## Add a footer
        _decorate_parts($entity, $list);
        $self->set_entity($entity);
    } elsif ($mode eq 'urlize') {
        ##Prepare message for urlize reception mode
        my $entity = $self->as_entity->dup;

        _urlize_parts($entity, $list, $self->{'message_id'});
        ## Add a footer
        _decorate_parts($entity, $list);
        $self->set_entity($entity);
    } else {
        die sprintf 'Unknown variable/reception mode %s', $mode;
    }

    return $self;
}

# Add footer/header to a message.
# Old name: List::add_parts() or Message::add_parts(), n.b. not add_part().
sub _decorate_parts {
    Log::do_log('debug3', '(%s, %s)');
    my $entity = shift;
    my $list   = shift;

    my $type     = $list->{'admin'}{'footer_type'};
    my $listdir  = $list->{'dir'};
    my $eff_type = $entity->effective_type || 'text/plain';

    ## Signed or encrypted messages won't be modified.
    if ($eff_type =~ /^multipart\/(signed|encrypted)$/i) {
        return $entity;
    }

    my ($header, $headermime);
    foreach my $file (
        "$listdir/message.header",
        "$listdir/message.header.mime",
        $Conf::Conf{'etc'} . '/mail_tt2/message.header',
        $Conf::Conf{'etc'} . '/mail_tt2/message.header.mime'
        ) {
        if (-f $file) {
            unless (-r $file) {
                Log::do_log('notice', 'Cannot read %s', $file);
                next;
            }
            $header = $file;
            last;
        }
    }

    my ($footer, $footermime);
    foreach my $file (
        "$listdir/message.footer",
        "$listdir/message.footer.mime",
        $Conf::Conf{'etc'} . '/mail_tt2/message.footer',
        $Conf::Conf{'etc'} . '/mail_tt2/message.footer.mime'
        ) {
        if (-f $file) {
            unless (-r $file) {
                Log::do_log('notice', 'Cannot read %s', $file);
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
            if (_append_parts($entity, $header_msg, $footer_msg)) {
                $entity->sync_headers(Length => 'COMPUTE')
                    if $entity->head->get('Content-Length');
            }
        }
    } else {
        ## MIME footer/header
        my $parser = MIME::Parser->new;
        $parser->output_to_core(1);

        if (   $eff_type =~ /^multipart\/alternative/i
            || $eff_type =~ /^multipart\/related/i) {
            Log::do_log('debug3', 'Making message %s into multipart/mixed',
                $entity);
            $entity->make_multipart("mixed", Force => 1);
        }

        if ($header and -s $header) {
            if ($header =~ /\.mime$/) {
                my $header_part;
                eval { $header_part = $parser->parse_in($header); };
                if ($@) {
                    Log::do_log('err', 'Failed to parse MIME data %s: %s',
                        $header, $parser->last_error);
                } else {
                    $entity->make_multipart unless $entity->is_multipart;
                    ## Add AS FIRST PART (0)
                    $entity->add_part($header_part, 0);
                }
            } else {
                ## text/plain header
                $entity->make_multipart unless $entity->is_multipart;
                my $header_part = MIME::Entity->build(
                    Path       => $header,
                    Type       => "text/plain",
                    Filename   => undef,
                    'X-Mailer' => undef,
                    Encoding   => "8bit",
                    Charset    => "UTF-8"
                );
                $entity->add_part($header_part, 0);
            }
        }
        if ($footer and -s $footer) {
            if ($footer =~ /\.mime$/) {
                my $footer_part;
                eval { $footer_part = $parser->parse_in($footer); };
                if ($@) {
                    Log::do_log('err', 'Failed to parse MIME data %s: %s',
                        $footer, $parser->last_error);
                } else {
                    $entity->make_multipart unless $entity->is_multipart;
                    $entity->add_part($footer_part);
                }
            } else {
                ## text/plain footer
                $entity->make_multipart unless $entity->is_multipart;
                $entity->attach(
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

    return $entity;
}

## Append header/footer to text/plain body.
## Note: As some charsets (e.g. UTF-16) are not compatible to US-ASCII,
##   we must concatenate decoded header/body/footer and at last encode it.
## Note: With BASE64 transfer-encoding, newline must be normalized to CRLF,
##   however, original body would be intact.
sub _append_parts {
    my $entity     = shift;
    my $header_msg = shift || '';
    my $footer_msg = shift || '';

    my $enc = $entity->head->mime_encoding;
    # Parts with nonstandard encodings aren't modified.
    if ($enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i) {
        return undef;
    }
    my $eff_type = $entity->effective_type || 'text/plain';
    my $body;
    my $io;

    ## Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}i) {
        return undef;
    }

    ## Skip attached parts.
    my $disposition = $entity->head->mime_attr('Content-Disposition');
    return undef
        if $disposition and uc $disposition ne 'INLINE';

    ## Preparing header and footer for inclusion.
    if ($eff_type eq 'text/plain' or $eff_type eq 'text/html') {
        if (length $header_msg or length $footer_msg) {
            # Only decodable bodies are allowed.
            my $bodyh = $entity->bodyhandle;
            if ($bodyh) {
                return undef if $bodyh->is_encoded;
                $body = $bodyh->as_string();
            } else {
                $body = '';
            }

            # Alter body.
            $body = _append_footer_header_to_part(
                {   'part'     => $entity,
                    'header'   => $header_msg,
                    'footer'   => $footer_msg,
                    'eff_type' => $eff_type,
                    'body'     => $body
                }
            );
            return undef unless defined $body;

            # Save new body.
            $io = $bodyh->open('w');
            unless (defined $io) {
                Log::do_log('err', 'Failed to save message: %s', "$!");
                return undef;
            }
            $io->print($body);
            $io->close;
            $entity->sync_headers(Length => 'COMPUTE')
                if $entity->head->get('Content-Length');

            return 1;
        }
    } elsif ($eff_type eq 'multipart/mixed') {
        ## Append to the first part, since other parts will be "attachments".
        if ($entity->parts
            and _append_parts($entity->parts(0), $header_msg, $footer_msg)) {
            return 1;
        }
    } elsif ($eff_type eq 'multipart/alternative') {
        ## We try all the alternatives
        my $r = undef;
        foreach my $p ($entity->parts) {
            $r = 1
                if _append_parts($p, $header_msg, $footer_msg);
        }
        return $r if $r;
    } elsif ($eff_type eq 'multipart/related') {
        ## Append to the first part, since other parts will be "attachments".
        if ($entity->parts
            and _append_parts($entity->parts(0), $header_msg, $footer_msg)) {
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

    my $entity     = $data->{'part'};
    my $header_msg = $data->{'header'};
    my $footer_msg = $data->{'footer'};
    my $eff_type   = $data->{'eff_type'};
    my $body       = $data->{'body'};

    my $in_cset;

    ## Detect charset.  If charset is unknown, detect 7-bit charset.
    my $charset = $entity->head->mime_attr('Content-Type.Charset');
    $in_cset = MIME::Charset->new($charset || 'NONE');
    unless ($in_cset->decoder) {
        # MIME::Charset 1.009.2 or later required.
        $in_cset =
            MIME::Charset->new(MIME::Charset::detect_7bit_charset($body)
                || 'NONE');
    }
    unless ($in_cset->decoder) {
        return undef;
    }
    $in_cset->encoder($in_cset);    # no charset conversion

    ## Decode body to Unicode, since HTML::Entities::encode_entities() and
    ## newline normalization will break texts with several character sets
    ## (UTF-16/32, ISO-2022-JP, ...).
    ## Only decodable bodies are allowed.
    eval {
        $body = $in_cset->decode($body, 1);
        $header_msg = Encode::decode_utf8($header_msg, 1);
        $footer_msg = Encode::decode_utf8($footer_msg, 1);
    };
    return undef if $@;

    my $new_body;
    if ($eff_type eq 'text/plain') {
        Log::do_log('debug3', "Treating text/plain part");

        ## Add newlines.  For BASE64 encoding they also must be normalized.
        if (length $header_msg) {
            $header_msg .= "\n" unless $header_msg =~ /\n\z/;
        }
        if (length $footer_msg and length $body) {
            $body .= "\n" unless $body =~ /\n\z/;
        }
        if (length $footer_msg) {
            $footer_msg .= "\n" unless $footer_msg =~ /\n\z/;
        }
        if (uc($entity->head->mime_attr('Content-Transfer-Encoding') || '') eq
            'BASE64') {
            $header_msg =~ s/\r\n|\r|\n/\r\n/g;
            $body       =~ s/(\r\n|\r|\n)\z/\r\n/;    # only at end
            $footer_msg =~ s/\r\n|\r|\n/\r\n/g;
        }

        $new_body = $header_msg . $body . $footer_msg;

        ## Data not encodable by original charset will fallback to UTF-8.
        my ($newcharset, $newenc);
        ($body, $newcharset, $newenc) =
            $in_cset->body_encode($new_body, Replacement => 'FALLBACK');
        unless ($newcharset) {                        # bug in MIME::Charset?
            Log::do_log('err', 'Can\'t determine output charset');
            return undef;
        } elsif ($newcharset ne $in_cset->as_string) {
            $entity->head->mime_attr('Content-Transfer-Encoding' => $newenc);
            $entity->head->mime_attr('Content-Type.Charset' => $newcharset);
        }
    } elsif ($eff_type eq 'text/html') {
        Log::do_log('debug3', "Treating text/html part");

        # Escape special characters.
        $header_msg = HTML::Entities::encode_entities($header_msg, '<>&"');
        $header_msg =~ s/(\r\n|\r|\n)$//;        # strip the last newline.
        $header_msg =~ s,(\r\n|\r|\n),<br/>,g;
        $footer_msg = HTML::Entities::encode_entities($footer_msg, '<>&"');
        $footer_msg =~ s/(\r\n|\r|\n)$//;        # strip the last newline.
        $footer_msg =~ s,(\r\n|\r|\n),<br/>,g;

        $new_body = $body;
        if (length $header_msg) {
            my $div = sprintf '<div style="%s">%s</div>',
                $div_style, $header_msg;
            $new_body =~ s,(<body\b[^>]*>),$1$div,i
                or $new_body = $div . $new_body;
        }
        if (length $footer_msg) {
            my $div = sprintf '<div style="%s">%s</div>',
                $div_style, $footer_msg;
            $new_body =~ s,(</\s*body\b[^>]*>),$div$1,i
                or $new_body = $new_body . $div;
        }
        # Append newline if it is not there: A few MUAs need it.
        $new_body .= "\n" unless $new_body =~ /\n\z/;

        # Unencodable characters are encoded to entity, because charset
        # metadata in HTML won't be altered.
        # Problem: FB_HTMLCREF of several codecs are broken.
        eval { $body = $in_cset->encode($new_body, Encode::FB_HTMLCREF); };
        return undef if $@;
    }

    return $body;
}

sub _urlize_parts {
    my $entity     = shift;
    my $list       = shift;
    my $message_id = shift;

    ## Only multipart/mixed messages are modified.
    my $eff_type = $entity->effective_type || 'text/plain';
    unless ($eff_type eq 'multipart/mixed') {
        return undef;
    }

    my $expl = $list->{'dir'} . '/urlized';
    unless (-d $expl or mkdir $expl, 0775) {
        Log::do_log('err', 'Unable to create urlized directory %s', $expl);
        return undef;
    }

    ## Clean up Message-ID
    my $dir1 = tools::escape_chars($message_id);
    $dir1 = '/' . $dir1;
    unless (mkdir "$expl/$dir1", 0775) {
        Log::do_log('err', 'Unable to create urlized directory %s/%s',
            $expl, $dir1);
        return 0;
    }

    my $wwsympa_url = Conf::get_robot_conf($list->{'domain'}, 'wwsympa_url');
    my $mime_types  = tools::load_mime_types();
    my @parts       = ();
    my $i           = 0;
    foreach my $part ($entity->parts) {
        my $p = _urlize_one_part($part->dup, $list, $dir1, $i, $mime_types,
            $wwsympa_url);
        if (defined $p) {
            push @parts, $p;
            $i++;
        } else {
            push @parts, $part;
        }
    }
    if ($i) {
        ## Replace message parts
        $entity->parts(\@parts);
    }

    return $entity;
}

sub _urlize_one_part {
    my $entity      = shift;
    my $list        = shift;
    my $dir         = shift;
    my $i           = shift;
    my $mime_types  = shift;
    my $wwsympa_url = shift;

    my $expl     = $list->{'dir'} . '/urlized';
    my $robot    = $list->{'domain'};
    my $listname = $list->{'name'};
    my $head     = $entity->head;
    my $encoding = $head->mime_encoding;

    ##  name of the linked file
    my $fileExt = $mime_types->{$head->mime_type};
    if ($fileExt) {
        $fileExt = '.' . $fileExt;
    }
    my $filename;

    if ($head->recommended_filename) {
        $filename = $head->recommended_filename;
        # MIME-tools >= 5.501 returns Unicode value ("utf8 flag" on).
        $filename = Encode::encode_utf8($filename)
            if Encode::is_utf8($filename);
    } else {
        $filename = "msg.$i" . $fileExt;
    }

    ##create the linked file
    ## Store body in file
    if (open OFILE, ">$expl/$dir/$filename") {
        my $ct = $entity->effective_type || 'text/plain';
        printf OFILE "Content-type: %s", $ct;
        printf OFILE "; Charset=%s", $head->mime_attr('Content-Type.Charset')
            if tools::smart_eq($head->mime_attr('Content-Type.Charset'),
            qr/\S/);
        print OFILE "\n\n";
    } else {
        Log::do_log('notice', 'Unable to open %s/%s/%s',
            $expl, $dir, $filename);
        return undef;
    }

    if ($encoding =~
        /^(binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64)$/
        ) {
        open TMP, ">$expl/$dir/$filename.$encoding";
        $entity->print_body(\*TMP);
        close TMP;

        open BODY, "$expl/$dir/$filename.$encoding";
        my $decoder = MIME::Decoder->new($encoding);
        $decoder->decode(\*BODY, \*OFILE);
        unlink "$expl/$dir/$filename.$encoding";
    } else {
        $entity->print_body(\*OFILE);
    }
    close(OFILE);
    my $file = "$expl/$dir/$filename";
    my $size = (-s $file);

    ## Only URLize files with a moderate size
    if ($size < $Conf::Conf{'urlize_min_size'}) {
        unlink "$expl/$dir/$filename";
        return undef;
    }

    ## Delete files created twice or more (with Content-Type.name and Content-
    ## Disposition.filename)
    $entity->purge;

    (my $file_name = $filename) =~ s/\./\_/g;
    # do NOT escape '/' chars
    my $file_url = "$wwsympa_url/attach/$listname"
        . tools::escape_chars("$dir/$filename", '/');

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    my $new_part;

    my $charset = tools::lang2charset($language->get_lang);

    my $tt2_include_path = tools::get_search_path(
        $list,
        subdir => 'mail_tt2',
        lang   => $language->get_lang
    );

    tt2::parse_tt2(
        {   'file_name' => $file_name,
            'file_url'  => $file_url,
            'file_size' => $size,
            'charset'   => $charset,     # compat. <= 6.1.
        },
        'urlized_part.tt2',
        \$new_part,
        $tt2_include_path
    );
    $entity = $parser->parse_data(\$new_part);
    _fix_utf8_parts($entity, $parser, [], $charset);

    return $entity;
}

=over

=item reformat_utf8_message ( )

I<Instance method>.
Reformat bodies of text parts contained in the message using
recommended encoding schema and/or charsets defined by MIME::Charset.

MIME-compliant headers are appended / modified.  And custom X-Mailer:
header is appended :).

Parameters:

=over

=item $attachments

ref(ARRAY) - messages to be attached as subparts.

=back

Returns:

string

=back

=cut

# Some paths of message processing in Sympa can't recognize Unicode strings.
# At least MIME::Parser::parse_data() and Template::proccess(): these
# methods occationalily break strings containing Unicode characters.
#
# My mail_utf8 patch expects the behavior as following ---
#
# Sub-messages to be attached (into digests, moderation notices etc.) will
# passed to mail::reformat_message() separately then attached to reformatted
# parent message again.  As a result, sub-messages won't be broken.  Since
# they won't cause mixture of Unicode string (parent message generated by
# tt2::parse_tt2()) and byte string (sub-messages).
#
# Note: For compatibility with old style, data passed to
# mail::reformat_message() already includes sub-message(s).  Then:
# - When a part has an `X-Sympa-Attach:' header field for internal use, new
#   style, mail::reformat_message() attaches raw sub-message to reformatted
#   parent message again;
# - When a part doesn't have any `X-Sympa-Attach:' header fields, sub-
#   messages generated by [% INSERT %] directive(s) in the template will be
#   used.
#
# More Note: Latter behavior above will give expected result only if
# contents of sub-messages are US-ASCII or ISO-8859-1. In other cases
# customized templates (if any) should be modified so that they have
# appropriate `X-Sympa-Attach:' header fileds.
#
# Sub-messages are gathered from template context paramenters.

sub reformat_utf8_message {
    my $self        = shift;
    my $attachments = shift || [];
    my $defcharset  = shift;

    my $entity = $self->as_entity->dup;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);

    $entity->head->delete('X-Mailer');
    _fix_utf8_parts($entity, $parser, $attachments, $defcharset);
    $entity->head->add('X-Mailer', sprintf 'Sympa %s',
        Sympa::Constants::VERSION);

    $self->set_entity($entity);
    return $self;
}

sub _fix_utf8_parts {
    my $entity      = shift;
    my $parser      = shift;
    my $attachments = shift || [];
    my $defcharset  = shift;
    return $entity unless $entity;

    my $enc = $entity->head->mime_encoding;
    # Parts with nonstandard encodings aren't modified.
    return $entity
        if $enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i;
    my $eff_type = $entity->effective_type;
    # Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}) {
        return $entity;
    }

    if ($entity->head->get('X-Sympa-Attach')) {    # Need re-attaching data.
        my $data = shift @{$attachments};
        if (ref $data eq 'MIME::Entity') {
            $entity->parts([$data]);
        } elsif (ref $data eq 'SCALAR' or ref $data eq 'ARRAY') {
            eval { $data = $parser->parse_data($data); };
            if ($@) {
                Log::do_log('notice', 'Failed to parse MIME data');
                $data = $parser->parse_data('');
            }
            $entity->parts([$data]);
        } else {
            if (ref $data eq 'Message') {
                $data = $data->as_string;
            } elsif (ref $data) {
                die sprintf 'Unsupported type for attachment: %s', ref $data;
            } else {   # already stringified.
                eval { $parser->parse_data($data); };   # check only.
                if ($@) {
                    Log::do_log('notice', 'Failed to parse MIME data');
                    $data = '';
                }
            }
            $parser->extract_nested_messages(0);   # Keep attachments intact.
            $data =
                $parser->parse_data($entity->head->as_string . "\n" . $data);
            $parser->extract_nested_messages(1);
            %$entity = %$data;
        }
        $entity->head->delete('X-Sympa-Attach');
    } elsif ($entity->parts) {
        my @newparts = ();
        foreach my $part ($entity->parts) {
            push @newparts,
                _fix_utf8_parts($part, $parser, $attachments, $defcharset);
        }
        $entity->parts(\@newparts);
    } elsif ($eff_type =~ m{^(?:multipart|message)(?:/|\Z)}i) {
        # multipart or message types without subparts.
        return $entity;
    } elsif (MIME::Tools::textual_type($eff_type)) {
        my $bodyh = $entity->bodyhandle;
        # Encoded body or null body won't be modified.
        return $entity if !$bodyh or $bodyh->is_encoded;

        my $head = $entity->head;
        my $body = $bodyh->as_string;
        my $wrap = $body;
        if ($head->get('X-Sympa-NoWrap')) {    # Need not wrapping
            $head->delete('X-Sympa-NoWrap');
        } elsif ($eff_type eq 'text/plain'
            and lc($head->mime_attr('Content-type.Format') || '') ne 'flowed')
        {
            $wrap = tools::wrap_text($body);
        }

        my $charset = $head->mime_attr("Content-Type.Charset") || $defcharset;
        my ($newbody, $newcharset, $newenc) =
            MIME::Charset::body_encode(Encode::decode_utf8($wrap),
            $charset, Replacement => 'FALLBACK');
        # Append newline if it is not there.  A few MUAs need it.
        $newbody .= "\n" unless $newbody =~ /\n\z/;

        if (    $newenc eq $enc
            and $newcharset eq $charset
            and $newbody eq $body) {
            # Normalize field, especially because charset may be absent.
            $head->mime_attr('Content-Type',              uc $eff_type);
            $head->mime_attr('Content-Type.Charset',      $newcharset);
            $head->mime_attr('Content-Transfer-Encoding', $newenc);

            $head->add("MIME-Version", "1.0")
                unless $head->get("MIME-Version");
            return $entity;
        }

        ## normalize newline to CRLF if transfer-encoding is BASE64.
        $newbody =~ s/\r\n|\r|\n/\r\n/g
            if $newenc and $newenc eq 'BASE64';

        # Fix headers and body.
        $head->mime_attr("Content-Type", "TEXT/PLAIN")
            unless $head->mime_attr("Content-Type");
        $head->mime_attr("Content-Type.Charset",      $newcharset);
        $head->mime_attr("Content-Transfer-Encoding", $newenc);
        $head->add("MIME-Version", "1.0") unless $head->get("MIME-Version");
        my $io = $bodyh->open("w");

        unless (defined $io) {
            Log::do_log('err', 'Failed to save message: %m');
            return undef;
        }

        $io->print($newbody);
        $io->close;
        $entity->sync_headers(Length => 'COMPUTE');
    } else {
        # Binary or text with long lines will be suggested to be BASE64.
        $entity->head->mime_attr("Content-Transfer-Encoding",
            $entity->suggest_encoding);
        $entity->sync_headers(Length => 'COMPUTE');
    }
    return $entity;
}

=over

=item get_id ( )

I<Instance method>.
Get unique identifier of instance.

=back

=cut

sub get_id {
    my $self = shift;

    # Tentative.  Alternatives for more general ID in the future.
    return $self->{'messagekey'} if $self->{'messagekey'};
    if ($self->{'filename'}) {
        my @parts = split /\//, $self->{'filename'};
        return pop @parts;
    }
    return $self->{'message_id'};
}

1;

=head1 HISTORY

L<Message> module appeared on Sympa 3.3.6.
It was initially written by:

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier SalaE<252>n <os AT cru.fr> 

=back 

=cut 
