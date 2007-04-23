# important_changes.pl - This script prints important changes in Sympa since last install
# It is based on the NEWS ***** entries
# RCS Identication ; $Revision$ ; $Date$ 
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

## Print important changes in Sympa since last install
## It is based on the NEWS ***** entries

my ($first_install, $current_version, $previous_version);

$current_version = $ENV{'SYMPA_VERSION'};

unless ($current_version) {
    print STDERR "Could not get current Sympa version\n";
    exit -1;
}

## Get previous installed version of Sympa
unless (open VERSION, "$ENV{'BINDIR'}/Version.pm") {
    print STDERR "Could not find previous install of Sympa ; assuming first install\n";
    exit 0;
}

unless ($first_install) {
    while (<VERSION>) {
	if (/^\$Version = \'(\S+)\'\;/) {
	    $previous_version = $1;
	    last;
	}
    }
}
close VERSION;

if (($previous_version eq $current_version) ||
    &higher($previous_version,$current_version)){
    exit 0;
}

print "You are upgrading from Sympa $previous_version\nYou should read CAREFULLY the changes listed below ; they might be uncompatible changes :\n<RETURN>";
my $wait = <STDIN>;

## Extracting Important changes from release notes
open NOTES, 'NEWS';
my ($current, $ok);
while (<NOTES>) {
    if (/^$previous_version\s/) {
	last;
    }elsif (/^$current_version\s/) {
	$ok = 1;
    }

    next unless $ok;

    if (/^\*{4}/) {
	print "\n" unless $current;
	$current = 1;
	print;
    }else {
	$current = 0;
    }
    
}
close NOTES;
print "<RETURN>";
my $wait = <STDIN>;

sub higher {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./,$v1;
    my @tab2 = split /\./,$v2;
    
    
    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for $i (0..$max) {
    
        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        }elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        }elsif ($tab2[0] =~ /^(\d*)b$/) {
            $tab2[0] = $1 - 0.25;
        }

        if ($tab1[0] eq $tab2[0]) {
            #printf "\t%s = %s\n",$tab1[0],$tab2[0];
            shift @tab1;
            shift @tab2;
            next;
        }
        return ($tab1[0] > $tab2[0]);
    }

    return 0;
}
