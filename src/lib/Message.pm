# Message.pm - This module includes Message processing functions
#<!-- RCS Identication ; $Revision$ ; $Date$ --> 

#
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

=pod 

=encoding utf-8

=head1 NAME 

I<Message.pm> - mail message embedding for internal use in Sympa

=head1 DESCRIPTION 

While processing a message in Sympa, we need to link informations to rhe message, mdify headers and such. This was quite a problem when a message was signed, as modifying anything in the message body would alter its MD5 footprint. And probably make the message to be rejected by clients verifying its identity (which is somehow a good thing as it is the reason why people use MD5 after all). With such messages, the process was complex. We then decided to embed any message treated in a "Message" object, thus making the process easier.

=cut 

package Message;

use strict;
#use Carp; # currently not used
#use Mail::Header; #not used
use Mail::Address;
#use MIME::Entity; #not used
use MIME::Charset;
use MIME::EncWords;
use MIME::Parser;
use POSIX qw(mkfifo);
# tentative
use Data::Dumper;

#use List;
##The line above was removed to avoid dependency loop.
##"use List" MUST precede to "use Message".

#use Site; # loaded in List - Robot
#use tools; # loaded in Conf
#use tt2; # loaded by List
#use Conf; # loaded in Site
#use Log; # loaded in Conf

my %openssl_errors = (1 => 'an error occurred parsing the command options',
		      2 => 'one of the input files could not be read',
		      3 => 'an error occurred creating the PKCS#7 file or when reading the MIME message',
		      4 => 'an error occurred decrypting or verifying the message',
		      5 => 'the message was verified correctly but an error occurred writing out the signers certificates');
=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by Message.pm

=cut 


=pod 

=head2 sub new

Creates a new Message object.

=head3 Arguments 

=over 

=item * I<$pkg>, a package name 

=item * I<$file>, the message file

=item * I<$noxsympato>, a boolean

=back 

=head3 Return 

=over 

=item * I<a Message object>, if created

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * Log::do_log

=item * List::new

=item * Mail::Address::parse

=item * MIME::EncWords::decode_mimewords

=item * MIME::Entity::as_string

=item * MIME::Head::get

=item * MIME::Parser::output_to_core

=item * MIME::Parser::read

=item * tools::valid_email

=item * tools::smime_decrypt

=item * tools::smime_sign_check

=back 

=cut 

## Creates a new object
sub new {
    
    my $pkg =shift;
    my $datas = shift;

    my $file = $datas->{'file'};
    my $noxsympato = $datas->{'noxsympato'};
    my $messageasstring = $datas->{'messageasstring'};
    my $mimeentity = $datas->{'mimeentity'};
    my $message_in_spool= $datas->{'message_in_spool'};

    my $message;
    my $input = 'file' if $file;
    $input = 'messageasstring' if $messageasstring; 
    $input = 'message_in_spool' if $message_in_spool; 
    $input = 'mimeentity' if $mimeentity; 
    Log::do_log('debug2', 'Message::new(input= %s, noxsympato= %s)',$input,$noxsympato);
    
    if ($mimeentity) {
	return create_message_from_mime_entity($pkg,$message,$mimeentity);
    }
    if ($message_in_spool){
	$message = create_message_from_spool($message_in_spool);
    }
    if ($file) {
	$message = create_message_from_file($file);
    }
    if($messageasstring){
	$message = create_message_from_string($messageasstring);
    }  

    unless ($message){
	Log::do_log('err',"Could not parse message");
	return undef;
    }

    ## Bless Message object
    bless $message, $pkg;
    $message->{'noxsympato'} = $noxsympato;
    $message->{'size'} = length($message->{'msg_as_string'});
    $message->{'msg_id'} = $message->{'msg'}->head->get('Message-Id');
    chomp $message->{'msg_id'};
    $message->{'list'} ||= $datas->{'list'}; # Some messages without X-Sympa-To still need a list context.

    $message->get_envelope_sender;

    return undef unless($message->get_sender_email);

    $message->get_subject;
    $message->get_receipient;
    $message->get_robot;
    $message->get_list;
    $message->get_sympa_local_part;
    $message->check_spam_status;
    $message->check_dkim_signature;
    $message->check_x_sympa_checksum;
    
    ## S/MIME
    if (Site->openssl) {
	return undef unless $message->decrypt;
	$message->check_smime_signature;
    }
    ## TOPICS
    $message->set_topic;
    return $message;
}

sub create_message_from_mime_entity {
    my $pkg = shift;
    my $self = shift;
    my $mimeentity = shift;
    Log::do_log('debug2','Creating message object from MIME entity %s',$mimeentity);
    
    $self->{'msg'} = $mimeentity;
    $self->{'altered'} = '_ALTERED';
    $self->{'msg_as_string'} = $self->{'msg'}->as_string;

    ## Bless Message object
    bless $self, $pkg;
    
    return $self;
}

sub create_message_from_spool {
    my $message_in_spool = shift;
    my $self;
    Log::do_log('debug2','Creating message object from spooled message %s',$message_in_spool->{'messagekey'});
    
    $self = create_message_from_string($message_in_spool->{'messageasstring'});
    $self->{'messagekey'}= $message_in_spool->{'messagekey'};
    $self->{'spoolname'}= $message_in_spool->{'spoolname'};
    $self->{'create_list_if_needed'}= $message_in_spool->{'create_list_if_needed'};
    $self->{'list'} = $message_in_spool->{'list_object'};
    $self->{'robot_id'} = $message_in_spool->{'robot'};

    return $self;
}

sub create_message_from_file {
    my $file = shift;
    my $self;
    my $messageasstring;
    Log::do_log('debug2','Creating message object from file %s',$file);
    
    unless (open FILE, "$file") {
	Log::do_log('err', 'Cannot open message file %s : %s',  $file, $!);
	return undef;
    }
    while (<FILE>){
	$messageasstring = $messageasstring.$_;
    }
    close(FILE);

    $self = create_message_from_string($messageasstring);
    $self->{'filename'} = $file;
    $file =~ s/^.*\/([^\/]+)$/$1/;
    unless ($file =~ /^(\S+)\.(\d+)\.\w+$/) {
	Log::do_log('err','Unable to extract data from filename %s',$file);
    }else{
	$self->{'rcpt'} = $1;
	$self->{'date'} = $2;
    }
    
    return $self;
}

sub create_message_from_string {
    my $messageasstring = shift;
    my $self;
    Log::do_log('debug2','Creating message object from character string');
    
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    
    my $msg;

    if (ref ($messageasstring)){
	$msg = $parser->parse_data($messageasstring);
    }else{
	$msg = $parser->parse_data(\$messageasstring);
    }

    $self->{'msg'} = $msg;
    $self->{'msg_as_string'} = $messageasstring;

    return $self;
}

sub get_envelope_sender {
    my $self = shift;

    unless (exists $self->{'envelope_sender'}) {
	## We trust in Return-Path: header field at the top of message.
	## To add it to messages by MDA:
	## - Sendmail:   Add 'P' in the 'F=' flags of local mailer line (such
	##               as 'Mlocal').
	## - Postfix:
	##   - local(8): Available by default.
	##   - pipe(8):  Add 'R' in the 'flags=' attributes of master.cf.
	## - Exim:       Set 'return_path_add' to true with pipe_transport.
	## - qmail:      Use preline(1).
	my $headers = $self->{'msg'}->head->header();
	my $i = 0;
	$i++ while $headers->[$i] and $headers->[$i] =~ /^X-Sympa-/;
	if ($headers->[$i] and $headers->[$i] =~ /^Return-Path:\s*(.+)$/) {
	    my $addr = $1;
	    if ($addr =~ /<>/) {
		$self->{'envelope_sender'} = '<>';
	    } else {
		my @addrs = Mail::Address->parse($addr);
		if (@addrs and tools::valid_email($addrs[0]->address)) {
		    $self->{'envelope_sender'} = $addrs[0]->address;
		}
	    }
	}
    }
    return $self->{'envelope_sender'};
}

## Get sender of the message according to header fields specified by
## 'sender_headers' parameter.
## FIXME: S/MIME signer may not be same as sender given by this method.
sub get_sender_email {
    my $self = shift;

    unless ($self->{'sender'}) {
	my $hdr = $self->{'msg'}->head;
	my $sender = undef;
	my $gecos = undef;
	foreach my $field (split /[\s,]+/, Site->sender_headers) {
	    if (lc $field eq 'from_') {
		## Try to get envelope sender
		if ($self->get_envelope_sender and
		    $self->get_envelope_sender ne '<>') {
		    $sender = $self->get_envelope_sender;
		    last;
		}
	    } elsif ($hdr->get($field)) {
		## Try to get message header
		## On "Resent-*:" headers, the first occurrance must be used.
		## Though "From:" can occur multiple times, only the first
		## one is detected.
		my @sender_hdr = Mail::Address->parse($hdr->get($field));
		if (scalar @sender_hdr and $sender_hdr[0]->address) {
		    $sender = lc($sender_hdr[0]->address);
		    my $phrase = $sender_hdr[0]->phrase;
		    if (defined $phrase and length $phrase) {
			$gecos = MIME::EncWords::decode_mimewords(
			    $phrase, Charset => 'UTF-8'
			);
		    }
		    last;
		}
	    }
	}
	unless (defined $sender) {
	    Log::do_log('err', 'No valid sender address');
	    return undef;
	}
	unless (tools::valid_email($sender)) {
	    Log::do_log('err', 'Invalid sender address "%s"', $sender);
	    return undef;
	}
	$self->{'sender'} = $sender;
	$self->{'gecos'} = $gecos;
    }
    return $self->{'sender'};
}

sub get_sender_gecos {
    my $self = shift;
    $self->get_sender_email unless exists $self->{'gecos'};
    return $self->{'gecos'};
}

sub get_subject {
    my $self = shift;

    unless ($self->{'decoded_subject'}) {
	my $hdr = $self->{'msg'}->head;
	## Store decoded subject and its original charset
	my $subject = $hdr->get('Subject');
	if ($subject =~ /\S/) {
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
		MIME::EncWords::decode_mimewords($subject, Charset => 'utf8');
	} else {
	    $self->{'decoded_subject'} = $subject;
	}
	chomp $self->{'decoded_subject'};
    }
    return $self->{'decoded_subject'};
}

sub get_family {
    my $self = shift;
    unless ($self->{'family'}) {
	$self->{'family'} = $self->{'msg'}->head->get('X-Sympa-Family');
	chomp $self->{'family'};
	$self->{'family'} =~ s/^\s+//;
	$self->{'family'} =~ s/\s+$//;
    }
    return $self->{'family'};
}

sub get_receipient {
    my $self = shift;
    my $force = shift;
    my $hdr = $self->{'msg'}->head;
    my $rcpt;
    if (!$self->{'rcpt'} || $self->get_family) {
	unless (defined $self->{'noxsympato'}) { # message.pm can be used not only for message coming from queue
	    unless ($rcpt = $hdr->get('X-Sympa-To')) {
		Log::do_log('err', 'no X-Sympa-To found, ignoring message.');
		return undef;
	    }
	}else {
	    unless ($rcpt = $hdr->get('To')) {
		Log::do_log('err', 'no To: header found, ignoring message.');
		return undef;
	    }
	}
	## Extract recepient address (X-Sympa-To)
	$self->{'rcpt'} = $rcpt;
	chomp $self->{'rcpt'};
    }
    return $self->{'rcpt'};
}

sub set_receipient {
    my $self = shift;
    my $new_rcpt = shift;

    $self->{'rcpt'} = $new_rcpt;
}

sub get_list {
    my $self = shift;
    unless ($self->{'list'}) {
	unless ($self->{'listname'}) {
	    my ($listname, $robot_id) = split /\@/, $self->{'rcpt'};
	    $self->{'listname'} = lc($robot_id || '');
	}
	unless ($self->{'list'} = List->new($self->{'listname'},$self->get_robot,{'just_try' => 1})) {
	    return undef;
	}
    }
    return $self->{'list'};    
}

sub set_sympa_headers {
    my $self = shift;
    my $param = shift;
    my $rcpt = $param->{'rcpt'};
    my $from = $param->{'from'};
    $rcpt ||= $self->get_receipient;
    $from ||= $self->get_sender_email;
    my $all_rcpt;
    if (ref($rcpt) eq 'ARRAY') {
	$all_rcpt = join(',', @{$rcpt});
    }else {
	$all_rcpt = $rcpt;
    }
    if ($self->get_mime_message->head->get('X-Sympa-To')) {
	$self->get_mime_message->head->replace('X-Sympa-To', $all_rcpt);
    }else {
	$self->get_mime_message->head->add('X-Sympa-To', $all_rcpt);
    }
    if ($self->get_mime_message->head->get('X-Sympa-From')) {
	$self->get_mime_message->head->replace('X-Sympa-From', $from);
    }else{
	$self->get_mime_message->head->add('X-Sympa-From', $from);
    }
    if ($self->get_mime_message->head->get('X-Sympa-Checksum')) {
	$self->get_mime_message->head->replace('X-Sympa-Checksum', tools::sympa_checksum($all_rcpt));
    }else{
	$self->get_mime_message->head->add('X-Sympa-Checksum', tools::sympa_checksum($all_rcpt));
    }
    
    $self->set_message_as_string($self->get_mime_message->as_string);
}

sub get_sympa_local_part {
    my $self = shift;
    unless ($self->{'list'}) {
	if ($self->{'robot'}) {
	    my $conf_email = $self->{'robot'}->email;
	    my $conf_host = $self->{'robot'}->host;
	    my $site_email = Site->listmaster_email;
	    my $site_host = Site->host;
	    unless ($self->{'listname'} =~
		/^(sympa|$site_email|$conf_email)(\@$conf_host)?$/i) {
		my ($listname, $type) =
		    $self->{'robot'}->split_listname($self->{'listname'});
		if ($listname) {
		    $self->{'listname'} = $listname;
		}

		my $list = List->new($self->{'listname'}, $self->{'robot'},
		    {'just_try' => 1});
		if ($list) {
		    $self->{'list'} = $list;
		}	
	    }
	}else{
	    Log::do_log('debug2','No robot: will not find list');
	}
    }else{
	Log::do_log('debug2','List "%s" already identified',$self->{'list'});
    }
    return 1;
}

sub get_robot {
    my $self = shift;
    unless ($self->{'robot'}) {
	unless ($self->{'robot_id'}) {
	    my ($listname, $robot_id) = split /\@/, $self->{'rcpt'};
	    $self->{'robot_id'} = lc($robot_id || '');
	    $self->{'listname'} = lc($listname);
	    $self->{'robot_id'} ||= Site->domain;
	}
	unless ($self->{'robot'} = Robot->new($self->{'robot_id'},('just_try' => 1))) {
	    if (my $from = $self->get_mime_message->head->get('X-Sympa-From')) {
		chomp $from;
		my ($listname, $robot_id) = split /\@/, $from;
		$self->{'robot_id'} = lc($robot_id || '');
		$self->{'robot'} = Robot->new($self->{'robot_id'});
	    }
	}
	unless ($self->{'robot'}) {
	    Log::do_log('err', 'Unable to define a robot context. Aborting.');
	    return undef;
	}
    }
    return $self->{'robot'};
}

sub check_spam_status {
    my $self = shift;
    my $spam_status = Scenario::request_action($self->{'robot'},
	'spam_status', 'smtp', {'message' => $self});
    $self->{'spam_status'} = 'unkown';
    if(defined $spam_status) {
	if (ref($spam_status ) eq 'HASH') {
	    $self->{'spam_status'} =  $spam_status ->{'action'};
	}else{
	    $self->{'spam_status'} = $spam_status ;
	}
    }
    return 1;    
}

sub check_dkim_signature {
    my $self = shift;
    # verify DKIM signature
    if ($self->{'robot'}->dkim_feature eq 'on'){
	$self->{'dkim_pass'} = &tools::dkim_verifier($self->{'msg_as_string'});
    }
    return 1;
}

sub check_x_sympa_checksum {
    my $self = shift;
    my $hdr = $self->{'msg'}->head;
    unless ($self->{'noxsympato'}) {
	## valid X-Sympa-Checksum prove the message comes from web interface with authenticated sender
	if ( $hdr->get('X-Sympa-Checksum')) {
	    my $chksum = $hdr->get('X-Sympa-Checksum'); chomp $chksum;
	    my $rcpt = $hdr->get('X-Sympa-To'); chomp $rcpt;

	    if ($chksum eq &tools::sympa_checksum($rcpt)) {
		$self->{'md5_check'} = 1 ;
	    }else{
		Log::do_log('err',"incorrect X-Sympa-Checksum header");	
	    }
	}
    }
}

sub decrypt {
    my $self = shift;
    ## Decrypt messages
    my $hdr = $self->get_mime_message->head;
    if (($hdr->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i) &&
	($hdr->get('Content-Type') !~ /signed-data/i)){
	unless (defined $self->smime_decrypt()) {
	    Log::do_log('err', "Message %s could not be decrypted", $self->{'msg_id'});
	    return undef;
	    ## We should warn the sender and/or the listmaster
	}
	Log::do_log('notice', "message %s has been decrypted", $self->{'msg_id'});
    }
    return 1;
}

sub check_smime_signature {
    my $self = shift;
    my $hdr = $self->get_mime_message->head;
    Log::do_log('debug','Checking S/MIME signature for message %s, from user %s',$self->get_msg_id,$self->get_sender_email);
    ## Check S/MIME signatures
    if ($hdr->get('Content-Type') =~ /multipart\/signed/ || ($hdr->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i && $hdr->get('Content-Type') =~ /signed-data/i)) {
	$self->{'protected'} = 1; ## Messages that should not be altered (no footer)
	$self->smime_sign_check();
	if($self->{'smime_signed'}) {
	    Log::do_log('notice', "message %s is signed, signature is checked", $self->{'msg_id'});
	}
	## TODO: Handle errors (0 different from undef)
    }
}
=pod 

=head2 sub dump

Dump a Message object to a stream.

=head3 Arguments 

=over 

=item * I<$self>, the Message object to dump

=item * I<$output>, the stream to which dump the object

=back 

=head3 Return 

=over 

=item * I<1>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

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
	}else {
	    printf "%s => %s\n", $key, $self->{$key};
	}
    }
    
    select $old_output;

    return 1;
}

=pod 

=head2 sub add_topic

Add topic and put header X-Sympa-Topic.

=head3 Arguments 

=over 

=item * I<$self>, the Message object to which add a topic

=item * I<$output>, the string containing the topic to add

=back 

=head3 Return 

=over 

=item * I<1>, if everything's alright

=back 

=head3 Calls 

=over 

=item * MIME::Head::add

=back 

=cut 

## Add topic and put header X-Sympa-Topic
sub add_topic {
    my ($self,$topic) = @_;

    $self->{'topic'} = $topic;
    my $hdr = $self->{'msg'}->head;
    $hdr->add('X-Sympa-Topic', $topic);

    return 1;
}

sub set_topic {
    my $self = shift;
    my $topics;
    if ($topics = $self->get_mime_message->head->get('X-Sympa-Topic')){
	$self->{'topic'} = $topics;
    }
}

=pod 

=head2 sub add_topic

Add topic and put header X-Sympa-Topic.

=head3 Arguments 

=over 

=item * I<$self>, the Message object whose topic is retrieved

=back 

=head3 Return 

=over 

=item * I<the topic>, if it exists

=item * I<empty string>, otherwise

=back 

=head3 Calls 

=over 

=item * MIME::Head::add

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

sub clean_html {
    my $self = shift;
    my $robot = shift;
    my $new_msg;
    if($new_msg = _fix_html_part($self->get_encrypted_mime_message, $robot)) {
	$self->{'msg'} = $new_msg;
	return 1;
    }
    return 0;
}

sub _fix_html_part {
    my $part = shift;
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

	my $body = $bodyh->as_string;
	# Re-encode parts with 7-bit charset (ISO-2022-*), since
	# StripScripts cannot handle them correctly.
	my $cset = MIME::Charset->new($part->head->mime_attr('Content-Type.Charset') || '');
	unless ($cset->decoder) {
	    # Charset is unknown.  Detect 7-bit charset.
	    my ($dummy, $charset) =
		MIME::Charset::body_encode($body, '', Detect7Bit => 'YES');
	    $cset = MIME::Charset->new($charset);
	}
	if ($cset->decoder and $cset->as_string =~ /^ISO-2022-/i) {
	    $part->head->mime_attr('Content-Type.Charset', 'UTF-8');
	    $cset->encoder('UTF-8');
	    $body = $cset->encode($body);
	}

	my $filtered_body = tools::sanitize_html(
	    'string' => $body, 'robot'=> $robot);

	my $io = $bodyh->open("w");
	unless (defined $io) {
	    Log::do_log('err', "Failed to save message : $!");
	    return undef;
	}
	$io->print($filtered_body);
	$io->close;
    }
    return $part;
}

# extract body as string from msg_as_string
# do NOT use Mime::Entity in order to preserveB64 encoding form and so preserve S/MIME signature
sub get_body_from_msg_as_string {
    my $msg =shift;

    my @bodysection =split("\n\n",$msg );    # convert it as a tab with headers as first element
    shift @bodysection;                      # remove headers
    return (join ("\n\n",@bodysection));  # convert it back as string
}

# input : msg object for a list, return a new message object decrypted
sub smime_decrypt {
    my $self = shift;
    my $from = $self->{'msg'}->head->get('from');
    chomp $from;
    my $list = $self->{'list'};

    use Data::Dumper;
    Log::do_log('debug2', 'Decrypting message from %s, %s', $from, $list);

    ## an empty "list" parameter means mail to sympa@, listmaster@...
    my $dir;
    if ($list) {
	$dir = $list->dir;
    } else {
	$dir = Site->home . '/sympa';
    }
    my ($certs,$keys) = tools::smime_find_keys($dir, 'decrypt');
    unless (defined $certs && @$certs) {
	Log::do_log('err', "Unable to decrypt message : missing certificate file");
	return undef;
    }

    my $temporary_file = Site->tmpdir."/".$list->get_list_id().".".$$ ;
    my $temporary_pwd = Site->tmpdir.'/pass.'.$$;

    ## dump the incoming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	Log::do_log('info', 'Can\'t store message in file %s',$temporary_file);
	return undef;
    }
    $self->{'msg'}->print(\*MSGDUMP);
    close(MSGDUMP);
    
    my $pass_option;
    $self->{'decrypted_msg_as_string'} = '';
    if (Site->key_passwd ne '') {
	# if password is defined in sympa.conf pass the password to OpenSSL
	$pass_option = "-passin file:$temporary_pwd";	
    }

    ## try all keys/certs until one decrypts.
    while (my $certfile = shift @$certs) {
	my $keyfile = shift @$keys;
	Log::do_log('debug', "Trying decrypt with $certfile, $keyfile");
	if (Site->key_passwd ne '') {
	    unless (mkfifo($temporary_pwd,0600)) {
		Log::do_log('err', 'Unable to make fifo for %s', $temporary_pwd);
		return undef;
	    }
	}
	my $cmd = sprintf '%s smime -decrypt -in %s -recip %s -inkey %s %s',
	    Site->openssl, $temporary_file, $certfile, $keyfile,
	    $pass_option;
	Log::do_log('debug3', $cmd);
	open (NEWMSG, "$cmd |");

	if (defined Site->key_passwd and Site->key_passwd ne '') {
	    unless (open (FIFO,"> $temporary_pwd")) {
		Log::do_log('err', 'Unable to open fifo for %s', $temporary_pwd);
		return undef;
	    }
	    print FIFO Site->key_passwd;
	    close FIFO;
	    unlink ($temporary_pwd);
	}
	
	while (<NEWMSG>) {
	    $self->{'decrypted_msg_as_string'} .= $_;
	}
	close NEWMSG ;
	my $status = $?/256;
	
	unless ($status == 0) {
	    Log::do_log('err', 'Unable to decrypt S/MIME message : %s', $openssl_errors{$status});
	    next;
	}
	
	unlink ($temporary_file) unless ($main::options{'debug'}) ;
	
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($self->{'decrypted_msg'} = $parser->parse_data($self->{'decrypted_msg_as_string'})) {
	    Log::do_log('err', 'Unable to parse message');
	    last;
	}
    }
	
    unless (defined $self->{'decrypted_msg'}) {
      Log::do_log('err', 'Message could not be decrypted');
      return undef;
    }

    ## Now remove headers from $self->{'decrypted_msg_as_string'}
    my @msg_tab = split(/\n/, $self->{'decrypted_msg_as_string'});
    my $line;
    do {$line = shift(@msg_tab)} while ($line !~ /^\s*$/);
    $self->{'decrypted_msg_as_string'} = join("\n", @msg_tab);
    
    ## foreach header defined in the incoming message but undefined in the
    ## decrypted message, add this header in the decrypted form.
    my $predefined_headers ;
    foreach my $header ($self->{'decrypted_msg'}->head->tags) {
	if ($self->{'decrypted_msg'}->head->get($header)) {
	    $predefined_headers->{lc $header} = 1;
	}
    }
    foreach my $header (split /\n(?![ \t])/, $self->{'msg'}->head->as_string) {
	next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
	my ($tag, $val) = ($1, $2);
	unless ($predefined_headers->{lc $tag}) {
	    $self->{'decrypted_msg'}->head->add($tag, $val);
	}
    }
    ## Some headers from the initial message should not be restored
    ## Content-Disposition and Content-Transfer-Encoding if the result is multipart
    $self->{'decrypted_msg'}->head->delete('Content-Disposition') if ($self->{'decrypted_msg'}->head->get('Content-Disposition'));
    if ($self->{'decrypted_msg'}->head->get('Content-Type') =~ /multipart/) {
	$self->{'decrypted_msg'}->head->delete('Content-Transfer-Encoding') if ($self->{'decrypted_msg'}->head->get('Content-Transfer-Encoding'));
    }

    ## Now add headers to message as string
    $self->{'decrypted_msg_as_string'}  = $self->{'decrypted_msg'}->head->as_string."\n".$self->{'decrypted_msg_as_string'};
    
    $self->{'smime_crypted'} = 'smime_crypted';

    return 1;
}

# input : msg object, return a new message object encrypted
sub smime_encrypt {
    my $self = shift;
    my $email = shift ;
    my $list = shift ;

    my $usercert;
    my $dummy;

    Log::do_log('debug2', 'tools::smime_encrypt( %s, %s)', $email, $list);
    if ($list eq 'list') {
	my $self = new List($email);
	($usercert, $dummy) = tools::smime_find_keys($self->{dir}, 'encrypt');
    }else{
	my $base = Site->ssl_cert_dir . '/' . tools::escape_chars($email);
	if(-f "$base\@enc") {
	    $usercert = "$base\@enc";
	} else {
	    $usercert = "$base";
	}
    }
    if (-r $usercert) {
	my $temporary_file = Site->tmpdir."/".$email.".".$$ ;

	## encrypt the incoming message parse it.
	my $cmd = sprintf '%s smime -encrypt -out %s -des3 %s',
	    Site->openssl, $temporary_file, $usercert;
        &Log::do_log ('debug3', '%s', $cmd);
	if (!open(MSGDUMP, "| $cmd")) {
	    &Log::do_log('info', 'Can\'t encrypt message for recipient %s',
		$email);
	}
	## don't; cf RFC2633 3.1. netscape 4.7 at least can't parse encrypted stuff
	## that contains a whole header again... since MIME::Tools has got no function
	## for this, we need to manually extract only the MIME headers...
	##	$self->head->print(\*MSGDUMP);
	##	printf MSGDUMP "\n%s", $self->body;
	my $mime_hdr = $self->get_mime_message->head->dup();
	foreach my $t ($mime_hdr->tags()) {
	  $mime_hdr->delete($t) unless ($t =~ /^(mime|content)-/i);
	}
	$mime_hdr->print(\*MSGDUMP);

	printf MSGDUMP "\n";
	foreach (@{$self->get_mime_message->body}) { printf MSGDUMP '%s',$_;}
	##$self->get_mime_message->bodyhandle->print(\*MSGDUMP);
	close(MSGDUMP);
	my $status = $?/256 ;
	unless ($status == 0) {
	    &Log::do_log('err', 'Unable to S/MIME encrypt message (error %s) : %s', $status, $openssl_errors{$status});
	    return undef ;
	}

        ## Get as MIME object
	open (NEWMSG, $temporary_file);
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($self->{'crypted_message'} = $parser->read(\*NEWMSG)) {
	    &Log::do_log('notice', 'Unable to parse message');
	    return undef;
	}
	close NEWMSG ;

        ## Get body
	open (NEWMSG, $temporary_file);
        my $in_header = 1 ;
	while (<NEWMSG>) {
	   if ( !$in_header)  { 
	     $self->{'encrypted_body'} .= $_;       
	   }else {
	     $in_header = 0 if (/^$/); 
	   }
	}						    
	close NEWMSG;

	unlink ($temporary_file) unless ($main::options{'debug'}) ;

	## foreach header defined in  the incomming message but undefined in the
        ## crypted message, add this header in the crypted form.
	my $predefined_headers ;
	foreach my $header ($self->{'crypted_message'}->head->tags) {
	    $predefined_headers->{lc $header} = 1 
	        if ($self->{'crypted_message'}->head->get($header)) ;
	}
	foreach my $header (split /\n(?![ \t])/, $self->get_mime_message->head->as_string) {
	    next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
	    my ($tag, $val) = ($1, $2);
	    $self->{'crypted_message'}->head->add($tag, $val) 
	        unless $predefined_headers->{lc $tag};
	}
	$self->{'msg'} = $self->{'crypted_message'};
	$self->set_message_as_string($self->{'crypted_message'}->as_string);
	$self->{'smime_crypted'} = 1;
    }else{
	&Log::do_log ('err','unable to encrypt message to %s (missing certificate %s)',$email,$usercert);
	return undef;
    }
        
    return 1;
}

# input object msg and listname, output signed message object
sub smime_sign {
    my $self = shift;
    my $list = $self->{'list'};

    Log::do_log('debug2', 'tools::smime_sign (%s,%s)',$self,$list);

    my($cert, $key) = tools::smime_find_keys($list->dir, 'sign');
    my $temporary_file = Site->tmpdir .'/'. $list->get_id . "." . $$;
    my $temporary_pwd = Site->tmpdir . '/pass.' . $$;

    my ($signed_msg,$pass_option );
    $pass_option = "-passin file:$temporary_pwd" if (Site->key_passwd ne '') ;

    ## Keep a set of header fields ONLY
    ## OpenSSL only needs content type & encoding to generate a multipart/signed msg
    my $dup_msg = $self->get_mime_message->dup;
    foreach my $field ($dup_msg->head->tags) {
         next if ($field =~ /^(content-type|content-transfer-encoding)$/i);
         $dup_msg->head->delete($field);
    }

    ## dump the incomming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	Log::do_log('info', 'Can\'t store message in file %s', $temporary_file);
	return undef;
    }
    $dup_msg->print(\*MSGDUMP);
    close(MSGDUMP);

    if (Site->key_passwd ne '') {
	unless ( mkfifo($temporary_pwd,0600)) {
	    Log::do_log('notice', 'Unable to make fifo for %s',$temporary_pwd);
	}
    }
    my $cmd = sprintf
	'%s smime -sign -rand %s/rand -signer %s %s -inkey %s -in %s',
	Site->openssl, Site->tmpdir, $cert, $pass_option, $key,
	$temporary_file;
    Log::do_log('debug2', '%s', $cmd);
    unless (open NEWMSG, "$cmd |") {
    	Log::do_log('notice', 'Cannot sign message (open pipe)');
	return undef;
    }

    if (Site->key_passwd ne '') {
	unless (open (FIFO,"> $temporary_pwd")) {
	    Log::do_log('notice', 'Unable to open fifo for %s', $temporary_pwd);
	}

	print FIFO Site->key_passwd;
	close FIFO;
	unlink ($temporary_pwd);
    }

    my $new_message_as_string = '';
    while (<NEWMSG>) {
	$new_message_as_string .= $_;
    }

    my $parser = new MIME::Parser;

    $parser->output_to_core(1);
    unless ($signed_msg = $parser->parse_data($new_message_as_string)) {
	Log::do_log('notice', 'Unable to parse message');
	return undef;
    }
    unlink ($temporary_file) unless ($main::options{'debug'}) ;
    
    ## foreach header defined in  the incoming message but undefined in the
    ## crypted message, add this header in the crypted form.
    my $predefined_headers ;
    foreach my $header ($signed_msg->head->tags) {
	$predefined_headers->{lc $header} = 1
	    if ($signed_msg->head->get($header));
    }
    foreach my $header (split /\n(?![ \t])/, $self->get_mime_message->head->as_string) {
	next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
	my ($tag, $val) = ($1, $2);
	$signed_msg->head->add($tag, $val)
	    unless $predefined_headers->{lc $tag};
    }
    ## Keeping original message string in addition to updated headers.
    my @new_message = split('\n\n',$new_message_as_string,2);
    $new_message_as_string = $signed_msg->head->as_string.'\n\n'.$new_message[1];
	
    $self->{'msg'} = $signed_msg;
    $self->{'msg_as_string'} = $new_message_as_string;
    $self->check_smime_signature;
    return 1;
}

sub smime_sign_check {
    my $message = shift;

    Log::do_log('debug2', 'tools::smime_sign_check (message, %s, %s)', $message->{'sender'}, $message->{'filename'});

    my $is_signed = {};
    $is_signed->{'body'} = undef;   
    $is_signed->{'subject'} = undef;

    my $verify ;

    ## first step is the msg signing OK ; /tmp/sympa-smime.$$ is created
    ## to store the signer certificat for step two. I known, that's dirty.

    my $temporary_file = Site->tmpdir."/".'smime-sender.'.$$ ;
    my $trusted_ca_options = '';
    $trusted_ca_options = "-CAfile " . Site->cafile . " " if Site->cafile;
    $trusted_ca_options .= "-CApath " . Site->capath . " " if Site->capath;
    my $cmd = sprintf '%s smime -verify %s -signer %s',
	Site->openssl, $trusted_ca_options, $temporary_file;
    &Log::do_log('debug2', '%s', $cmd);

    unless (open MSGDUMP, "| $cmd > /dev/null") {
	&Log::do_log('err', 'Unable to run command %s to check signature from %s: %s', $cmd, $message->{'sender'},$!);
	return undef ;
    }
    
    $message->get_mime_message->head->print(\*MSGDUMP);
    print MSGDUMP "\n";
    print MSGDUMP $message->get_message_as_string;
    close MSGDUMP;

    my $status = $?/256 ;
    unless ($status == 0) {
	&Log::do_log('err', 'Unable to check S/MIME signature: %s', $openssl_errors{$status});
	return undef ;
    }
    ## second step is the message signer match the sender
    ## a better analyse should be performed to extract the signer email. 
    my $signer = tools::smime_parse_cert({file => $temporary_file});

    unless ($signer->{'email'}{lc($message->{'sender'})}) {
	unlink($temporary_file) unless ($main::options{'debug'}) ;
	&Log::do_log('err', "S/MIME signed message, sender(%s) does NOT match signer(%s)",$message->{'sender'}, join(',', keys %{$signer->{'email'}}));
	return undef;
    }

    &Log::do_log('debug', "S/MIME signed message, signature checked and sender match signer(%s)", join(',', keys %{$signer->{'email'}}));
    ## store the signer certificat
    unless (-d Site->ssl_cert_dir) {
	if ( mkdir (Site->ssl_cert_dir, 0775)) {
	    &Log::do_log('info', 'creating spool %s', Site->ssl_cert_dir);
	}else{
	    &Log::do_log('err',
		'Unable to create user certificat directory %s',
		Site->ssl_cert_dir);
	}
    }

    ## It gets a bit complicated now. openssl smime -signer only puts
    ## the _signing_ certificate into the given file; to get all included
    ## certs, we need to extract them from the signature proper, and then
    ## we need to check if they are for our user (CA and intermediate certs
    ## are also included), and look at the purpose:
    ## "S/MIME signing : Yes/No"
    ## "S/MIME encryption : Yes/No"
    my $certbundle = Site->tmpdir . "/certbundle.$$";
    my $tmpcert = Site->tmpdir . "/cert.$$";
    my $nparts = $message->get_mime_message->parts;
    my $extracted = 0;
    &Log::do_log('debug2', "smime_sign_check: parsing $nparts parts");
    if($nparts == 0) { # could be opaque signing...
	$extracted +=tools::smime_extract_certs($message->get_mime_message, $certbundle);
    } else {
	for (my $i = 0; $i < $nparts; $i++) {
	    my $part = $message->get_mime_message->parts($i);
	    $extracted += tools::smime_extract_certs($part, $certbundle);
	    last if $extracted;
	}
    }
    
    unless($extracted) {
	&Log::do_log('err', "No application/x-pkcs7-* parts found");
	return undef;
    }

    unless(open(BUNDLE, $certbundle)) {
	&Log::do_log('err', "Can't open cert bundle $certbundle: $!");
	return undef;
    }
    
    ## read it in, split on "-----END CERTIFICATE-----"
    my $cert = '';
    my(%certs);
    while(<BUNDLE>) {
	$cert .= $_;
	if(/^-----END CERTIFICATE-----$/) {
	    my $workcert = $cert;
	    $cert = '';
	    unless(open(CERT, ">$tmpcert")) {
		&Log::do_log('err', "Can't create $tmpcert: $!");
		return undef;
	    }
	    print CERT $workcert;
	    close(CERT);
	    my($parsed) = tools::smime_parse_cert({file => $tmpcert});
	    unless($parsed) {
		&Log::do_log('err', 'No result from smime_parse_cert');
		return undef;
	    }
	    unless($parsed->{'email'}) {
		&Log::do_log('debug', "No email in cert for $parsed->{subject}, skipping");
		next;
	    }
	    
	    &Log::do_log('debug2', "Found cert for <%s>", join(',', keys %{$parsed->{'email'}}));
	    if ($parsed->{'email'}{lc($message->{'sender'})}) {
		if ($parsed->{'purpose'}{'sign'} && $parsed->{'purpose'}{'enc'}) {
		    $certs{'both'} = $workcert;
		    &Log::do_log('debug', 'Found a signing + encryption cert');
		}elsif ($parsed->{'purpose'}{'sign'}) {
		    $certs{'sign'} = $workcert;
		    &Log::do_log('debug', 'Found a signing cert');
		} elsif($parsed->{'purpose'}{'enc'}) {
		    $certs{'enc'} = $workcert;
		    &Log::do_log('debug', 'Found an encryption cert');
		}
	    }
	    last if(($certs{'both'}) || ($certs{'sign'} && $certs{'enc'}));
	}
    }
    close(BUNDLE);
    if(!($certs{both} || ($certs{sign} || $certs{enc}))) {
	&Log::do_log('err', "Could not extract certificate for %s", join(',', keys %{$signer->{'email'}}));
	return undef;
    }
    ## OK, now we have the certs, either a combined sign+encryption one
    ## or a pair of single-purpose. save them, as email@addr if combined,
    ## or as email@addr@sign / email@addr@enc for split certs.
    foreach my $c (keys %certs) {
	my $fn = Site->ssl_cert_dir . '/' . tools::escape_chars(lc($message->{'sender'}));
	if ($c ne 'both') {
	    unlink($fn); # just in case there's an old cert left...
	    $fn .= "\@$c";
	}else {
	    unlink("$fn\@enc");
	    unlink("$fn\@sign");
	}
	&Log::do_log('debug', "Saving $c cert in $fn");
	unless (open(CERT, ">$fn")) {
	    &Log::do_log('err', "Unable to create certificate file $fn: $!");
	    return undef;
	}
	print CERT $certs{$c};
	close(CERT);
    }

    unless ($main::options{'debug'}) {
	unlink($temporary_file);
	unlink($tmpcert);
	unlink($certbundle);
    }

    $is_signed->{'body'} = 'smime';
    
    # future version should check if the subject was part of the SMIME signature.
    $is_signed->{'subject'} = $signer;

    if ($is_signed->{'body'}) {
	$message->{'smime_signed'} = 1;
	$message->{'smime_subject'} = $is_signed->{'subject'};
    }
    
    return 1;
}

sub get_mime_message {
    my $self = shift;
    if ($self->{'smime_crypted'}) {
	return $self->{'decrypted_msg'};
    }
    return $self->{'msg'};
}

sub get_encrypted_mime_message {
    my $self = shift;
    return $self->{'msg'};
}

sub get_message_as_string {
    my $self = shift;
    if ($self->{'smime_crypted'}) {
	return $self->{'decrypted_msg_as_string'};
    }
    return $self->{'msg_as_string'};
}

sub set_message_as_string {
    my $self = shift;
    
    $self->{'msg_as_string'} = shift;
}

sub set_decrypted_message_as_string {
    my $self = shift;
    my $param = shift;
    
    $self->{'decrypted_msg_as_string'} = $param->{'new_message_as_string'};
}

sub reset_message_from_entity {
    my $self = shift;
    my $entity = shift;
    
    unless (ref ($entity) =~ /^MIME/) {
	Log::do_log('trace','Can not reset a message by starting from object %s', ref $entity);
	return undef;
    }
    $self->{'msg'} = $entity;
    $self->{'msg_as_string'} = $entity->as_string;
    if ($self->is_crypted) {
	$self->{'decrypted_msg'} = $entity;
	$self->{'decrypted_msg_as_string'} = $entity->as_string;
    }
    return 1;
}

sub get_encrypted_message_as_string {
    my $self = shift;
    return $self->{'msg_as_string'};
}

sub get_msg_id {
    my $self = shift;
    unless ($self->{'id'}) {
	$self->{'id'} = $self->get_mime_message->head->get('Message-Id');
	chomp $self->{'id'};
    }
    return $self->{'id'}
}

sub is_signed {
    my $self = shift;
    return $self->{'protected'};
}

sub is_crypted {
    my $self = shift;
    unless(defined $self->{'smime_crypted'}) {
	$self->decrypt;
    }
    return $self->{'smime_crypted'};
}

sub has_html_part {
    my $self = shift;
    $self->check_message_structure unless ($self->{'structure_already_checked'});
    return $self->{'has_html_part'};
}

sub has_text_part {
    my $self = shift;
    $self->check_message_structure unless ($self->{'structure_already_checked'});
    return $self->{'has_text_part'};
}

sub has_attachments {
    my $self = shift;
    $self->check_message_structure unless ($self->{'structure_already_checked'});
    return $self->{'has_attachments'};
}

## Make a multipart/alternative, a singlepart
sub check_message_structure {
    my $self = shift;
    my $msg = shift;
    $msg ||= $self->get_mime_message->dup;
    Log::do_log('debug2', 'Message: %s, part: %s',$self,$msg);
    $self->{'structure_already_checked'} = 1;
    if ($msg->effective_type() =~ /^multipart\/alternative/) {
	foreach my $part ($msg->parts) {
	    if (($part->effective_type() =~ /^text\/html$/) ||
	    (
	    ($part->effective_type() =~ /^multipart\/related$/) &&
	    $part->parts &&
	    ($part->parts(0)->effective_type() =~ /^text\/html$/))) {
		Log::do_log('debug3', 'Found html part');
		$self->{'has_html_part'} = 1;
	    }elsif($part->effective_type() =~ /^text\/plain$/) {
		Log::do_log('debug3', 'Found text part');
		$self->{'has_text_part'} = 1;
	    }else{
		Log::do_log('debug3', 'Found attachment: %s',$part->effective_type());
		$self->{'has_attachments'} = 1;
	    }
	}
    }elsif ($msg->effective_type() =~ /multipart\/signed/) {
	my @parts = $msg->parts();
	## Only keep the first part
	$msg->parts([$parts[0]]);
	$msg->make_singlepart();       
	$self->check_message_structure($msg);

    }elsif ($msg->effective_type() =~ /^multipart/) {
	Log::do_log('debug3', 'Found multipart: %s',$msg->effective_type());
	foreach my $part ($msg->parts) {
            next unless (defined $part); ## Skip empty parts
	    if ($part->effective_type() =~ /^multipart\/alternative/) {
		$self->check_message_structure($part);
	    }else{
		Log::do_log('debug3', 'Found attachment: %s',$part->effective_type());
		$self->{'has_attachments'} = 1;
	    }
	}
    }    
}

## Add footer/header to a message
sub add_parts {
    my $self = shift;
    unless ($self->{'list'}) {
	Log::do_log('err','The message has no list context; No header/footer to add');
	return undef;
    }
    my $msg = $self->get_mime_message;
    my ($listname, $type) =
	($self->{'list'}->name, $self->{'list'}->footer_type);
    my $listdir = $self->{'list'}->dir;
    &Log::do_log('debug3', '%s, %s, %s',
	$msg, $listname, $type);
    
    my ($header, $headermime);
    foreach my $file (
	"$listdir/message.header",
	"$listdir/message.header.mime",
	Site->etc . '/mail_tt2/message.header',
	Site->etc . '/mail_tt2/message.header.mime'
	) {
	if (-f $file) {
	    unless (-r $file) {
		&Log::do_log('notice', 'Cannot read %s', $file);
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
	Site->etc . '/mail_tt2/message.footer',
	Site->etc . '/mail_tt2/message.footer.mime'
	) {
	if (-f $file) {
	    unless (-r $file) {
		&Log::do_log('notice', 'Cannot read %s', $file);
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
	    if (&_append_parts($msg, $header_msg, $footer_msg)) {
		$msg->sync_headers(Length => 'COMPUTE')
		    if $msg->head->get('Content-Length');
	    }
	}
    } else {
	## MIME footer/header
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);

	my $content_type = $msg->effective_type || 'text/plain';

	if ($content_type =~ /^multipart\/alternative/i ||
	    $content_type =~ /^multipart\/related/i) {

	    &Log::do_log('notice', 'Making message into multipart/mixed');
	    $msg->make_multipart("mixed", Force => 1);
	}

	if ($header and -s $header) {
	    if ($header =~ /\.mime$/) {
		my $header_part;
		eval { $header_part = $parser->parse_in($header); };
		if ($@) {
		    &Log::do_log('err', 'Failed to parse MIME data %s: %s',
				 $header, $parser->last_error);
		} else {
		    $msg->make_multipart unless $msg->is_multipart;
		    $msg->add_part($header_part, 0); ## Add AS FIRST PART (0)
		}
	    ## text/plain header
	    } else {

		$msg->make_multipart unless $msg->is_multipart;
		my $header_part = build MIME::Entity
		    Path       => $header,
		Type        => "text/plain",
		Filename    => undef,
		'X-Mailer'  => undef,
		Encoding    => "8bit",
		Charset     => "UTF-8";
		$msg->add_part($header_part, 0);
	    }
	}
	if ($footer and -s $footer) {
	    if ($footer =~ /\.mime$/) {
		my $footer_part;
		eval { $footer_part = $parser->parse_in($footer); };
		if ($@) {
		    &Log::do_log('err', 'Failed to parse MIME data %s: %s',
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
			     Type        => "text/plain",
			     Filename    => undef,
			     'X-Mailer'  => undef,
			     Encoding    => "8bit",
			     Charset     => "UTF-8"
			     );
	    }
	}
    }

    return $msg;
}

sub _append_parts {
    my $part = shift;
    my $header_msg = shift || '';
    my $footer_msg = shift || '';

    my $eff_type = $part->effective_type || 'text/plain';

    if ($eff_type eq 'text/plain') {
	my $cset = MIME::Charset->new('UTF-8');
	$cset->encoder($part->head->mime_attr('Content-Type.Charset') ||
		'NONE');

	my $body;
	if (defined $part->bodyhandle) {
	    $body = $part->bodyhandle->as_string;
	} else {
	    $body = '';
	}

	## Only encodable footer/header are allowed.
	if ($cset->encoder) {
	    eval { $header_msg = $cset->encode($header_msg, 1); };
	    $header_msg = '' if $@;
	    eval { $footer_msg = $cset->encode($footer_msg, 1); };
	    $footer_msg = '' if $@;
	} else {
	    $header_msg = '' if $header_msg =~ /[^\x01-\x7F]/;
	    $footer_msg = '' if $footer_msg =~ /[^\x01-\x7F]/;
	}

	if (length $header_msg or length $footer_msg) {
	    $header_msg .= "\n"
		if length $header_msg and
		    $header_msg !~ /\n$/;
	    $body .= "\n"
		if length $footer_msg and
		    length $body and
		    $body !~ /\n$/;

	    my $io = $part->bodyhandle->open('w');
	    unless (defined $io) {
		&Log::do_log('err',
		    "Failed to save message : $!");
		return undef;
	    }
	    $io->print($header_msg);
	    $io->print($body);
	    $io->print($footer_msg);
	    $io->close;
	    $part->sync_headers(Length => 'COMPUTE')
		if $part->head->get('Content-Length');
	}
	return 1;
    } elsif ($eff_type eq 'multipart/mixed') {
	## Append to first part if text/plain
	if ($part->parts and
	    &_append_parts($part->parts(0), $header_msg, $footer_msg)) {
	    return 1;
	}
    } elsif ($eff_type eq 'multipart/alternative') {
	## Append to first text/plain part
	foreach my $p ($part->parts) {
	    if (&_append_parts($p, $header_msg, $footer_msg)) {
		return 1;
	    }
	}
    }

    return undef;
}

sub prepare_message_according_to_mode {
    my $self = shift;
    my $mode = shift;
    Log::do_log('debug3','msg %s, mode: %s',$self->get_msg_id,$mode);
    ##Prepare message for normal reception mode
    if ($mode eq 'mail') {
	$self->prepare_reception_mail;
    } elsif (($mode eq 'nomail') ||
	($mode eq 'summary') ||
	($mode eq 'digest') ||
	($mode eq 'digestplain')) {
    ##Prepare message for notice reception mode
    }elsif ($mode eq 'notice') {
	$self->prepare_reception_notice;
    ##Prepare message for txt reception mode
    } elsif ($mode eq 'txt') {
	$self->prepare_reception_txt;
    ##Prepare message for html reception mode
    } elsif ($mode eq 'html') {
	$self->prepare_reception_html;
    ##Prepare message for urlize reception mode
    } elsif ($mode eq 'url') {
	$self->prepare_reception_urlize;
    } else {
	&Log::do_log('err',
	    "Unknown variable/reception mode $mode");
	return undef;
    }

    unless (defined $self) {
	    &Log::do_log('err', "Failed to create Message object");
	return undef;
    }
    return 1;

}
sub prepare_reception_mail {
    my $self = shift;
    Log::do_log('debug3','preparing message for mail reception mode');
    ## Add footer and header
    return 0 if ($self->is_signed);
    my $new_msg = $self->add_parts;
    if (defined $new_msg) {
	$self->{'msg'} = $new_msg;
	$self->{'altered'} = '_ALTERED_';
    }else{
	Log::do_log('err','Part addition failed');
	return undef;
    }
    return 1;
}

sub prepare_reception_notice {
    my $self = shift;
    Log::do_log('debug3','preparing message for notice reception mode');
    my $notice_msg = $self->get_mime_message->dup;
    $notice_msg->bodyhandle(undef);
    $notice_msg->parts([]);
    if(($notice_msg->head->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i) &&
    ($notice_msg->head->get('Content-Type') !~ /signed-data/i)) {
	$notice_msg->head->delete('Content-Disposition');
	$notice_msg->head->delete('Content-Description');
	$notice_msg->head->replace('Content-Type','text/plain; charset="US-ASCII"');
	$notice_msg->head->replace('Content-Transfer-Encoding','7BIT');
    }
    $self->reset_message_from_entity($notice_msg);
    undef $self->{'smime_crypted'};
    return 1;
}

sub prepare_reception_txt {
    my $self = shift;
    Log::do_log('debug3','preparing message for txt reception mode');
    return 0 if ($self->is_signed);
    if (tools::as_singlepart($self->get_mime_message, 'text/plain')) {
	Log::do_log('notice',
	    'Multipart message changed to text singlepart');
    }
    ## Add a footer
    $self->reset_message_from_entity($self->add_parts);
    return 1;
}

sub prepare_reception_html {
    my $self = shift;
    Log::do_log('debug3','preparing message for html reception mode');
    return 0 if ($self->is_signed);
    if (tools::as_singlepart($self->get_mime_message, 'text/html')) {
	Log::do_log('notice',
	    'Multipart message changed to html singlepart');
    }
    ## Add a footer
    $self->reset_message_from_entity($self->add_parts);
    return 1;
}

sub prepare_reception_urlize {
    my $self = shift;
    Log::do_log('debug3','preparing message for urlize reception mode');
    return 0 if ($self->is_signed);
    unless ($self->{'list'}) {
	Log::do_log('err','The message has no list context; Nowhere to place urlized attachments.');
	return undef;
    }

    my $expl = $self->{'list'}->dir . '/urlized';

    unless ((-d $expl) || (mkdir $expl, 0775)) {
	&Log::do_log('err',
	    "Unable to create urlize directory $expl");
	return undef;
    }

    my $dir1 =
	&tools::clean_msg_id($self->get_mime_message->head->get('Message-ID'));

    ## Clean up Message-ID
    $dir1 = &tools::escape_chars($dir1);
    $dir1 = '/' . $dir1;

    unless (mkdir("$expl/$dir1", 0775)) {
	Log::do_log('err',
	    'Unable to create urlize directory %s/%s', $expl, $dir1);
	printf "Unable to create urlized directory %s/%s\n",
	    $expl, $dir1;
	return 0;
    }
    my $mime_types = &tools::load_mime_types();
    my @parts = ();
    my $i = 0;
    foreach my $part ($self->get_mime_message->parts()) {
	my $entity =
	    &_urlize_part($part, $self->{'list'}, $dir1, $i, $mime_types,
	    $self->{'list'}->robot->wwsympa_url);
	if (defined $entity) {
	    push @parts, $entity;
	} else {
	    push @parts, $part;
	}
	$i++;
    }

    ## Replace message parts
    $self->get_mime_message->parts(\@parts);

    ## Add a footer
    $self->reset_message_from_entity($self->add_parts);
    return 1;
}

sub _urlize_part {
    my $message = shift;
    my $list = shift;
    my $expl        = $list->dir . '/urlized';
    my $robot       = $list->domain;
    my $dir = shift;
    my $i = shift;
    my $mime_types = shift;
    my $listname    = $list->name;
    my $wwsympa_url = shift;

    my $head     = $message->head;
    my $encoding = $head->mime_encoding;
    my $content_type = $head->get('Content-Type');
    chomp $content_type;
    return undef if ($content_type =~ /multipart\/alternative/gi || $content_type =~ /text\//gi);
    ##  name of the linked file
    my $fileExt = $mime_types->{$head->mime_type};
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
		    _urlize_part(
			$message->parts($i), $list, $dir, $i, $mime_types,
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
	&Log::do_log('notice', "Unable to open $expl/$dir/$filename");
	return undef;
    }

    if ($encoding =~
	/^(binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64)$/
	) {
	open TMP, ">$expl/$dir/$filename.$encoding";
	$message->print_body(\*TMP);
	close TMP;

	open BODY, "$expl/$dir/$filename.$encoding";
	my $decoder = new MIME::Decoder $encoding;
	$decoder->decode(\*BODY, \*OFILE);
	unlink "$expl/$dir/$filename.$encoding";
    } else {
	$message->print_body(\*OFILE);
    }
    close(OFILE);
    my $file = "$expl/$dir/$filename";
    my $size = (-s $file);

    ## Only URLize files with a moderate size
    if ($size < Site->urlize_min_size) {
	unlink "$expl/$dir/$filename";
	return undef;
    }

    ## Delete files created twice or more (with Content-Type.name and Content-Disposition.filename)
    $message->purge;

    (my $file_name = $filename) =~ s/\./\_/g;
    my $file_url = "$wwsympa_url/attach/$listname" .
	&tools::escape_chars("$dir/$filename", '/'); # do NOT escape '/' chars

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    my $new_part;

    my $lang = &Language::GetLang();
    my $charset = &Language::GetCharset();

    my $tt2_include_path = $list->get_etc_include_path('mail_tt2', $lang);

    &tt2::parse_tt2(
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

## Packages must return true.
1;
=pod 

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier SalaE<0xfc>n <os AT cru.fr> 

=back 

=cut 
