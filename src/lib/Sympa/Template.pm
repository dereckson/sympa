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

package Sympa::Template;

use strict;
use warnings;

use CGI::Util;
use Encode qw();
use English; # FIXME: drop $MATCH usage
use MIME::EncWords;
use Template;

use Sympa::Constants;
use Sympa::Language;
use Sympa::List; # FIXME: circular dependency
use Sympa::Log::Syslog;
use Sympa::Tools::Text;

my $current_lang;
my $last_error;
my @other_include_path;
my $allow_absolute;

sub qencode {
    my $string = shift;

    # We are not able to determine the name of header field, so assume
    # longest (maybe) one.
    return MIME::EncWords::encode_mimewords(
        Encode::decode('utf8', $string),
        Encoding => 'A',
        Charset  => Sympa::Language::GetCharset(),
        Field    => "message-id"
    );
}

sub escape_url {

    my $string = shift;

    $string =~ s/[\s+]/sprintf('%%%02x', ord($MATCH))/eg;

    # Some MUAs aren't able to decode ``%40'' (escaped ``@'') in e-mail
    # address of mailto: URL, or take ``@'' in query component for a
    # delimiter to separate URL from the rest.
    my ($body, $query) = split(/\?/, $string, 2);
    if (defined $query) {
        $query =~ s/\@/sprintf('%%%02x', ord($MATCH))/eg;
        $string = $body . '?' . $query;
    }

    return $string;
}

sub escape_xml {
    my $string = shift;

    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\'/&apos;/g;
    $string =~ s/\"/&quot;/g;

    return $string;
}

sub escape_quote {
    my $string = shift;

    $string =~ s/\'/\\\'/g;
    $string =~ s/\"/\\\"/g;

    return $string;
}

sub encode_utf8 {
    my $string = shift;

    ## Skip if already internally tagged utf8
    if (Encode::is_utf8($string)) {
        return Encode::encode_utf8($string);
    }

    return $string;

}

sub decode_utf8 {
    my $string = shift;

    ## Skip if already internally tagged utf8
    unless (Encode::is_utf8($string)) {
        ## Wrapped with eval to prevent Sympa process from dying
        ## FB_CROAK is used instead of FB_WARN to pass $string intact to
        ## succeeding processes it operation fails
        eval { $string = Encode::decode('utf8', $string, Encode::FB_CROAK); };
        $EVAL_ERROR = '';
    }

    return $string;

}

sub maketext {
    my ($context, @arg) = @_;

    my $stash         = $context->stash();
    my $component     = $stash->get('component');
    my $template_name = $component->{'name'};
    my ($provider) =
        grep { $_->{HEAD}[2] eq $component } @{$context->{LOAD_TEMPLATES}};
    my $path = $provider->{HEAD}[1] if $provider;

    ## Strangely the path is sometimes empty...
    ## TODO : investigate
    #    Sympa::Log::Syslog::do_log('notice', "PATH: $path ; $template_name");

    ## Sample code to dump the STASH
    # my $s = $stash->_dump();

    return sub {
        Sympa::Language::maketext($template_name, $_[0], @arg);
        }
}

# IN:
#    $fmt: strftime() style format string.
#    $arg: a string representing date/time:
#          "YYYY/MM", "YYYY/MM/DD", "YYYY/MM/DD/HH/MM", "YYYY/MM/DD/HH/MM/SS"
# OUT:
#    Subref to generate formatted (i18n'ized) date/time.
sub locdatetime {
    my ($fmt, $arg) = @_;
    if ($arg !~
        /^(\d{4})\D(\d\d?)(?:\D(\d\d?)(?:\D(\d\d?)\D(\d\d?)(?:\D(\d\d?))?)?)?/
        ) {
        return sub { Sympa::Language::gettext("(unknown date)"); };
    } else {
        my @arg =
            ($6 + 0, $5 + 0, $4 + 0, $3 + 0 || 1, $2 - 1, $1 - 1900, 0, 0, 0);
        return sub { Sympa::Language::gettext_strftime($_[0], @arg); };
    }
}

# IN:
#    $context: Context.
#    $init: Indentation (or its length) of each paragraphm if any.
#    $subs: Indentation (or its length) of other lines if any.
#    $cols: Line width, defaults to 78.
# OUT:
#    Subref to generate folded text.
sub wrap {
    my ($context, $init, $subs, $cols) = @_;
    $init = '' unless defined $init;
    $init = ' ' x $init if $init =~ /^\d+$/;
    $subs = '' unless defined $subs;
    $subs = ' ' x $subs if $subs =~ /^\d+$/;

    return sub {
        my $text = shift;
        my $nl   = $text =~ /\n$/;
        my $ret  = Sympa::Tools::Text::wrap_text($text, $init, $subs, $cols);
        $ret =~ s/\n$// unless $nl;
        $ret;
    };
}

# IN:
#    $context: Context.
#    $type: type of list parameter value: 'reception', 'visibility', 'status'
#        or others (default).
#    $withval: if parameter value is added to the description. False by
#        default.
# OUT:
#    Subref to generate i18n'ed description of list parameter value.
sub optdesc {
    my ($context, $type, $withval) = @_;
    return sub {
        my $x = shift;
        return undef unless defined $x;
        return undef unless $x =~ /\S/;
        $x =~ s/^\s+//;
        $x =~ s/\s+$//;
        return Sympa::List->get_option_title($x, $type, $withval);
    };
}

## To add a directory to the TT2 include_path
sub add_include_path {
    my $path = shift;

    push @other_include_path, $path;
}

## Get current INCLUDE_PATH
sub get_include_path {
    return @other_include_path;
}

## Clear current INCLUDE_PATH
sub clear_include_path {
    @other_include_path = ();
}

## Allow inclusion/insertion of file with absolute path
sub allow_absolute_path {
    $allow_absolute = 1;
}

## Return the last error message
sub get_error {

    return $last_error;
}

## The main parsing sub
## Parameters are
## data: a HASH ref containing the data
## template : a filename or a ARRAY ref that contains the template
## output : a Filedescriptor or a SCALAR ref for the output

sub parse_tt2 {
    my ($data, $template, $output, $include_path, $options) = @_;
    $include_path ||= [Sympa::Constants::DEFAULTDIR];
    $options ||= {};

    ## Add directories that may have been added
    push @{$include_path}, @other_include_path;
    clear_include_path();    ## Reset it

    my $wantarray;

    ## An array can be used as a template (instead of a filename)
    if (ref($template) eq 'ARRAY') {
        $template = \join('', @$template);
    }

    Sympa::Language::SetLang($data->{lang}) if ($data->{'lang'});

    my $config = {

        # ABSOLUTE => 1,
        INCLUDE_PATH => $include_path,

        #	PRE_CHOMP  => 1,
        UNICODE => 0,    # Prevent BOM auto-detection

        FILTERS => {
            unescape => \CGI::Util::unescape,
            l        => [\Sympa::Template::maketext, 1],
            loc      => [\Sympa::Template::maketext, 1],
            helploc  => [\Sympa::Template::maketext, 1],
            locdt    => [\Sympa::Template::locdatetime, 1],
            wrap         => [\Sympa::Template::wrap,    1],
            optdesc      => [\Sympa::Template::optdesc, 1],
            qencode      => [\&qencode,      0],
            escape_xml   => [\&escape_xml,   0],
            escape_url   => [\&escape_url,   0],
            escape_quote => [\&escape_quote, 0],
            decode_utf8  => [\&decode_utf8,  0],
            encode_utf8  => [\&encode_utf8,  0]
        }
    };

    unless ($options->{'is_not_template'}) {
        $config->{'INCLUDE_PATH'} = $include_path;
    }
    if ($allow_absolute) {
        $config->{'ABSOLUTE'} = 1;
        $allow_absolute = 0;
    }
    if ($options->{'has_header'}) {    # body is separated by an empty line.
        if (ref $template) {
            $template = \("\n" . $$template);
        } else {
            $template = \"\n[% PROCESS $template %]";
        }
    }

    my $tt2 = Template->new($config)
        or die "Template error: " . Template->error();

    unless ($tt2->process($template, $data, $output)) {
        $last_error = $tt2->error();
        Sympa::Log::Syslog::do_log('err', 'Failed to parse %s : %s',
            $template, "$last_error");
        Sympa::Log::Syslog::do_log(
            'err',
            'Looking for TT2 files in %s',
            join(',', @{$include_path})
        );
        return undef;
    }

    return 1;
}

1;
