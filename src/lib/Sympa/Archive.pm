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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=encoding utf-8

=head1 NAME

Sympa::Archive - Archiving functions

=head1 DESCRIPTION

This module provides archiving-related functions.

=cut

package Sympa::Archive;

use strict;

use Cwd;
use Encode qw(decode_utf8 encode_utf8);
use English qw(-no_match_vars);
use HTML::Entities qw(decode_entities);

use Sympa::Log::Syslog;
use Sympa::Message;
use Sympa::Tools::File;

my $serial_number = 0; # incremented on each archived mail

=head1 FUNCTIONS

=over

=item store_last($list, $msg)

Does the real job : stores the message given as an argument into
the indicated directory.

=cut

sub store_last {
	my($list, $msg) = @_;

	Sympa::Log::Syslog::do_log ('debug2','()');

	return unless $list->is_archived();
	my $dir = $list->{'dir'}.'/archives';

	## Create the archive directory if needed
	mkdir ($dir, "0775") if !(-d $dir);
	chmod 0774, $dir;


	## erase the last  message and replace it by the current one
	open(OUT, "> $dir/last_message");
	if (ref ($msg)) {
		$msg->print(\*OUT);
} else {
	print OUT $msg;
}
close(OUT);

}

=item list($name)

Lists the files included in the archive, preformatted for printing.

Returns an array.

=cut

sub list {
	my ($name) = @_;
	Sympa::Log::Syslog::do_log ('debug',"($name)");

	my($filename, $newfile);
	my(@l, $i);

	unless (-d "$name") {
		Sympa::Log::Syslog::do_log ('warning',"no directory $name");
#      @l = ($msg::no_archives_available);
		return @l;
	}
	unless (opendir(DIR, "$name")) {
		Sympa::Log::Syslog::do_log ('warning',"($name) failed, cannot open directory $name");
#	@l = ($msg::no_archives_available);
		return @l;
	}
	foreach $i (sort readdir(DIR)) {
		next if ($i =~ /^\./o);
		next unless  ($i =~ /^\d\d\d\d\-\d\d$/);
		my(@s) = stat("$name/$i");
		my $a = localtime($s[9]);
		push(@l, sprintf("%-40s %7d   %s\n", $i, $s[7], $a));
	}
	return @l;
}

=item scan_dir_archive($dir, $month)

FIXME.

=cut

sub scan_dir_archive {

	my($dir, $month) = @_;

	Sympa::Log::Syslog::do_log ('info',"($dir, $month)");

	unless (opendir (DIR, "$dir/$month/arctxt")){
		Sympa::Log::Syslog::do_log ('info',"($dir, $month): unable to open dir $dir/$month/arctxt");
		return undef;
	}

	my $all_msg = [];
	my $i = 0;
	foreach my $file (sort readdir(DIR)) {
		next unless ($file =~ /^\d+$/);
		Sympa::Log::Syslog::do_log ('debug',"($dir, $month): start parsing message $dir/$month/arctxt/$file");

		my $message = Sympa::Message->new(
			file       => "$dir/$month/arctxt/$file",
			noxsympato => 'noxsympato'
		);
		unless ($message) {
			Sympa::Log::Syslog::do_log('err', 'Unable to create Message object from file %s', $file);
			return undef;
		}

		Sympa::Log::Syslog::do_log('debug',"MAIL object : %s", $message);

		$i++;
		my $msg = {};
		$msg->{'id'} = $i;

		$msg->{'subject'} = Sympa::Tools::decode_header($message, 'Subject');
		$msg->{'from'} = Sympa::Tools::decode_header($message, 'From');
		$msg->{'date'} = Sympa::Tools::decode_header($message, 'Date');

		$msg->{'full_msg'} = $message->as_string();

		Sympa::Log::Syslog::do_log('debug','adding message %s in archive to send', $msg->{'subject'});

		push @{$all_msg}, $msg;
	}
	closedir DIR;

	return $all_msg;
}

=item search_msgid($dir, $msgid)

Find a message in archive specified by I<$dir> and I<$msgid>.

Parameters:

=over

=item C<$dir> =>

=item C<$msgid> =>

=back

Return value:

undef | #message in arctxt

=cut

sub search_msgid {

	my($dir, $msgid) = @_;

	Sympa::Log::Syslog::do_log ('info',"($dir, $msgid)");


	if ($msgid =~ /NO-ID-FOUND\.mhonarc\.org/) {
		Sympa::Log::Syslog::do_log('err','remove_arc: no message id found');return undef;
	}
	unless ($dir =~ /\d\d\d\d\-\d\d\/arctxt/) {
		Sympa::Log::Syslog::do_log ('err',"dir $dir look unproper");
		return undef;
	}
	unless (opendir (ARC, "$dir")){
		Sympa::Log::Syslog::do_log ('err',"($dir, $msgid): unable to open dir $dir");
		return undef;
	}
	chomp $msgid;

	foreach my $file (grep (!/\./,readdir ARC)) {
		next unless (open MAIL,"$dir/$file");
		while (<MAIL>) {
			last if /^$/ ; #stop parse after end of headers
			if (/^Message-id:\s?<?([^>\s]+)>?\s?/i ) {
				my $id = $1;
				if ($id eq $msgid) {
					close MAIL; closedir ARC;
					return $file;
				}
			}
		}
		close MAIL;
	}
	closedir ARC;
	return undef;
}

=item exist($name, $file)

FIXME.

=cut

sub exist {
	my($name, $file) = @_;
	my $fn = "$name/$file";

	return $fn if (-r $fn && -f $fn);
	return undef;
}


=item last_path($list)

Return path for latest message distributed in the list.

=cut

sub last_path {
	my ($list) = @_;
	Sympa::Log::Syslog::do_log('debug', '(%s)', $list->{'name'});

	return undef unless ($list->is_archived());
	my $file = $list->{'dir'}.'/archives/last_message';

	return $file if (-f $file);
	return undef;

}

=item load_html_message(%parameters)

Load an archived message, returns the mhonarc metadata

Parameters:

=over

=item C<file_path> =>

=back

Return value:

=cut

sub load_html_message {
	my (%params) = @_;

	Sympa::Log::Syslog::do_log ('debug2',$params{'file_path'});
	my %metadata;

	unless (open ARC, $params{'file_path'}) {
		Sympa::Log::Syslog::do_log('err', "Failed to load message '%s' : $ERRNO", $params{'file_path'});
		return undef;
	}

	while (<ARC>) {
		last if /^\s*$/; ## Metadata end with an emtpy line

		if (/^<!--(\S+): (.*) -->$/) {
			my ($key, $value) = ($1, $2);
			$value = encode_utf8(decode_entities(decode_utf8($value)));
			if ($key eq 'X-From-R13') {
				$metadata{'X-From'} = $value;
				$metadata{'X-From'} =~ tr/N-Z[@A-Mn-za-m/@A-Z[a-z/; ## Mhonarc protection of email addresses
				$metadata{'X-From'} =~ s/^.*<(.*)>/$1/g; ## Remove the gecos
			}
			$metadata{$key} = $value;
		}
	}

	close ARC;

	return \%metadata;
}

=item clean_archive_directory(%parameters)

FIXME

=cut

sub clean_archive_directory{
	my (%params) = @_;

	Sympa::Log::Syslog::do_log('debug',"Cleaning archives for directory '%s'.",$params{'arc_root'}.'/'.$params{'dir_to_rebuild'});

	my $answer;
	$answer->{'dir_to_rebuild'} = $params{'arc_root'}.'/'.$params{'dir_to_rebuild'};
	$answer->{'cleaned_dir'} = $params{'tmpdir'}.'/'.$params{'dir_to_rebuild'};
	unless(my $number_of_copies = Sympa::Tools::File::copy_dir($answer->{'dir_to_rebuild'},$answer->{'cleaned_dir'})){
		Sympa::Log::Syslog::do_log('err',"Unable to create a temporary directory where to store files for HTML escaping (%s). Cancelling.",$number_of_copies);
		return undef;
	}
	if(opendir ARCDIR,$answer->{'cleaned_dir'}){
		my $files_left_uncleaned = 0;
		foreach my $file (readdir(ARCDIR)){
			next if($file =~ /^\./);
			$file = $answer->{'cleaned_dir'}.'/'.$file;
			$files_left_uncleaned++ unless(clean_archived_message(
					'input'  => $file ,
					'output' => $file
				));
		}
		closedir DIR;
		if ($files_left_uncleaned) {
			Sympa::Log::Syslog::do_log('err',"HTML cleaning failed for %s files in the directory %s.",$files_left_uncleaned,$answer->{'dir_to_rebuild'});
		}
		$answer->{'dir_to_rebuild'} = $answer->{'cleaned_dir'};
	} else {
		Sympa::Log::Syslog::do_log('err','Unable to open directory %s: %s',$answer->{'dir_to_rebuild'},$ERRNO);
		Sympa::Tools::File::del_dir($answer->{'cleaned_dir'});
		return undef;
	}
	return $answer;
}

=item clean_archived_message(%parameters)

FIXME

=cut

sub clean_archived_message {
	my (%params) = @_;

	Sympa::Log::Syslog::do_log('debug',"Cleaning HTML parts of a message input %s , output  %s ",$params{'input'},$params{'output'});

	my $input = $params{'input'};
	my $output = $params{'output'};


	my $message = Sympa::Message->new(file => $input);
	if ($message) {
		if($message->clean_html()){
			if(open TMP, ">$output") {
				print TMP $message->as_string();
				close TMP;
			} else {
				Sympa::Log::Syslog::do_log('err','Unable to create a tmp file to write clean HTML to file %s',$output);
				return undef;
			}
		} else {
			Sympa::Log::Syslog::do_log('err','HTML cleaning in file %s failed.',$output);
			return undef;
		}
	} else {
		Sympa::Log::Syslog::do_log('err','Unable to create a Message object with file %s',$input);
		return undef;
	}
}


#############################
# convert a message to HTML. 
#    result is stored in $destination_dir
#    attachement_url is used to link attachement
#    
# NOTE: This might be moved to Site package as a mutative method.
# NOTE: convert_single_msg_2_html() was deprecated.
sub convert_single_message {
    my $that = shift; # List or Robot object
    my $message = shift; # Message object or hashref
    my %opts = @_;

    my $robot;
    my $listname;
    my $hostname;
    if (ref $that and ref $that eq 'List') {
	$robot = $that->robot;
	$listname = $that->name;
    } elsif (ref $that and ref $that eq 'Robot') {
	$robot = $that;
	$listname = '';
    } else {
	croak 'bug in logic.  Ask developer';
    }
    $hostname = $that->host;

    my $msg_as_string;
    my $messagekey;
    if (ref $message eq 'Message') {
	$msg_as_string = $message->get_message_as_string;
	$messagekey = $message->{'messagekey'};
    } elsif (ref $message eq 'HASH') {
	$msg_as_string = $message->{'messageasstring'};
	$messagekey = $message->{'messagekey'};
    } else {
        croak 'bug in logic.  Ask developer';
    }

    my $destination_dir = $opts{'destination_dir'};
    my $attachement_url = $opts{'attachement_url'};

    my $mhonarc_ressources = $that->get_etc_filename(
	'mhonarc-ressources.tt2'
    );
    unless ($mhonarc_ressources) {
	Sympa::Log::Syslog::do_log('notice', 'Cannot find any MhOnArc ressource file');
	return undef;
    }

    unless (-d $destination_dir) {
	unless (Sympa::Tools::mkdir_all($destination_dir, 0755)) {
	    Sympa::Log::Syslog::do_log('err', 'Unable to create %s', $destination_dir);
	    return undef;
	}
    }

    my $msg_file = $destination_dir . '/msg00000.txt';
    unless (open OUT, '>', $msg_file) {
	Sympa::Log::Syslog::do_log('notice', 'Could Not open %s', $msg_file);
	return undef;
    }
    print OUT $msg_as_string;
    close OUT;

    # mhonarc require du change workdir so this proc must retore it    
    my $pwd = getcwd;

    ## generate HTML
    unless (chdir $destination_dir) {
	Sympa::Log::Syslog::do_log('err', 'Could not change working directory to %s',
	    $destination_dir);
	return undef;
    }

    my $tag = get_tag($that);
    my $exitcode = system(
	$robot->mhonarc, '-single',
	'-rcfile' => $mhonarc_ressources,
	'-definevars' => "listname='$listname' hostname=$hostname tag=$tag",
	'-outdir' => $destination_dir,
	'-attachmentdir' => $destination_dir,
	'-attachmenturl' => $attachement_url,
	'-umask' => Site->umask,
	'-stdout' => "$destination_dir/msg00000.html",
	'--', $msg_file
    ) >> 8;

    # restore current wd 
    chdir $pwd;		

    if ($exitcode) {
	Sympa::Log::Syslog::do_log('err', 'Command %s failed with exit code %d',
	    $robot->mhonarc, $exitcode
	);
    }

    return 1;
}

=head2 sub get_tag(OBJECT $that)

Returns a tag derived from the listname.

=head3 Arguments 

=over 

=item * I<$that>, a List or Robot object.

=back 

=head3 Return 

=over 

=item * I<a character string>, corresponding to the 10 last characters of a 32 bytes string containing the MD5 digest of the concatenation of the following strings (in this order):

=over 4

=item - the cookie config parameter

=item - a slash: "/"

=item - name attribute of the I<$that> argument

=back 

=back

=head3 Calls 

=over 

=item * Digest::MD5::md5_hex

=back 

=cut 

sub get_tag {
    my $that = shift;

    return substr(
	Digest::MD5::md5_hex(join '/', Site->cookie, $that->name), -10
    );
}

1;
