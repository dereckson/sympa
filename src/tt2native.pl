package Sympa::I18N;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon;
use vars qw/%Lexicon/;
use Log;

%Lexicon = (_AUTO => 1);

Locale::Maketext::Lexicon->import({
    '*' => [Gettext => '--PODIR--/*.po'],
#    _decode => 1,
});

sub maketext {
    my $self = shift;
    my $msg = shift;

    &do_log('notice','Maketext: %s', $msg);

    $msg =~ s/%(\d)/[_$1]/g;
    $self->SUPER::maketext($msg, @_);
}

1;

package parser;

use strict;
use Template;
use CGI::Util;
use Log;

my $tt2 = Template->new({
    ABSOLUTE => 1,
    INCLUDE_PATH => '--ETCBINDIR--/web_tt2',

    FILTERS => {
	unescape => \&CGI::Util::unescape,
	l => [\&maketext, 1]
	},
#PRE_CHOMP   => 1,
#POST_CHOMP   => 1,
	}) or die $!;

my %lh;
my $currentlh;

sub maketext {
    my ($context, @arg) = @_;

    return sub {
	$currentlh->maketext($_[0], @arg);
    }
}

## The main parsing sub
## Parameters are   
## data: a HASH ref containing the data   
## template : a filename or a ARRAY ref that contains the template   
## output : a Filedescriptor or a SCALAR ref for the output

sub parse_tpl {
    my ($data, $template, $output, $recurse) = @_;
    my $wantarray;

    ## An array can be used as a template (instead of a filename)
    if (ref($template) eq 'ARRAY') {
	$template = \join('', @$template);
    }

    # quick hack! wrong layer!
    s|^/home/sympa/bin/etc/wws_templates/(.*?)(\...)?(\.tpl)|$1.tt2|
	for values %$data;

    &do_log('notice', 'TPL: %s ; LANG: %s', $template, $data->{lang});
    $currentlh = ($lh{$data->{lang}} ||= Sympa::I18N->get_handle($data->{lang}));

    unless ($tt2->process($template, $data, $output)) {
	&do_log('err', 'Failed to parse %s : %s', $template, $tt2->error());
	return undef;
    } 
}

1;
