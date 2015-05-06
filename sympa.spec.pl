# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use lib qw(src/lib);
use strict;
use warnings;
use Sympa::Constants;
use Sympa::ModDef;

my %m = %Sympa::ModDef::cpan_modules;
my $requires =
    sprintf('Requires: perl >= %s', $m{perl}->{required_version}) . "\n"
    . join(
    "\n",
    map {
        sprintf '%sRequires: perl(%s)%s',
            ($m{$_}->{mandatory} ? '' : '#'),
            $_, $m{$_}->{required_version}
            ? " >= $m{$_}->{required_version}"
            : ''
        } grep {
        $_ ne 'perl' and $_ ne 'MHonArc::UTF8'
        } sort {
        lc $a cmp lc $b || $a cmp $b
        } keys %m
    )
    . "\n"
    . sprintf(
    'Requires: mhonarc >= %s',
    $m{'MHonArc::UTF8'}->{required_version}
    );
my $version = Sympa::Constants::VERSION();

undef $/;
$_ = <DATA>;
s/\@VERSION\@/$version/;
s/\@REQUIRES\@/$requires/;
print $_;

__END__
# RPM spec file for Sympa.

%define name    sympa
%define version @VERSION@
%define release 1%{?dist}

Name:     %{name}
Version:  %{version}
Release:  %{release}
Summary(fr): Sympa est un gestionnaire de listes électroniques
Summary:  Sympa is a powerful multilingual List Manager
License:  GPL
Group:    System Environment/Daemons
URL:      http://www.sympa.org/
Source:   http://www.sympa.org/distribution/%{name}-%{version}.tar.gz
Requires: smtpdaemon
@REQUIRES@
Requires: webserver
Requires(pre): /usr/sbin/useradd
Requires(pre): /usr/sbin/groupadd
BuildRoot: %{_tmppath}/%{name}-%{version}

%description
Sympa is scalable and highly customizable mailing list manager. It can cope
with big lists (200,000 subscribers) and comes with a complete (user and admin)
Web interface. It is internationalized, and supports the us, fr, de, es, it,
fi, and chinese locales. A scripting language allows you to extend the behavior
of commands. Sympa can be linked to an LDAP directory or an RDBMS to create
dynamic mailing lists. Sympa provides S/MIME-based authentication and
encryption.

%prep
%setup -q

%build
# Give install "-p" preserving mtime to prevent unexpected update of CSS.
# Give DESTDIR to cancel workaround in Makefile getting previous version.
%configure \
    --enable-fhs \
    --prefix=%{_prefix} \
    --docdir=%{_docdir}/%{name} \
    --libexecdir=%{_libexecdir}/sympa \
    --localstatedir=%{_localstatedir} \
    --sysconfdir=%{_sysconfdir}/sympa \
    --with-cgidir=%{_libexecdir}/sympa \
    --with-confdir=%{_sysconfdir}/sympa \
    --with-initdir=%{_initrddir} \
    --with-smrshdir=%{_sysconfdir}/smrsh \
    INSTALL_DATA='install -c -p -m 644'
make DESTDIR=%{buildroot}

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}
cp -rp %{buildroot}%{_docdir}/%{name}/* ./
rm -rf %{buildroot}%{_docdir}/%{name}/*

%check
%if 0%{?do_check}
make check
make authorcheck || true
%endif

%clean
rm -rf %{buildroot}

%pre
# Create "sympa" group if it does not exists
if ! getent group sympa > /dev/null 2>&1; then
  /usr/sbin/groupadd sympa
fi

# Create "sympa" user if it does not exists
if ! getent passwd sympa > /dev/null 2>&1; then
  /usr/sbin/useradd -r -g sympa \
      -d %{_localstatedir}/lib/sympa \
      -c "system user for sympa" \
      -s "/bin/bash"
fi

%files
%defattr(-,root,root)
%doc AUTHORS COPYING dot.perltidyrc NEWS README* samples sympa.pdf
%attr(-,sympa,sympa) %{_localstatedir}/*/sympa
%{_sbindir}/*
%dir %{_libexecdir}/sympa
%attr(-,sympa,sympa) %{_libexecdir}/sympa/bouncequeue
%attr(-,sympa,sympa) %{_libexecdir}/sympa/familyqueue
%attr(-,sympa,sympa) %{_libexecdir}/sympa/queue
%attr(-,root,sympa) %{_libexecdir}/sympa/sympa_newaliases-wrapper
%attr(-,sympa,sympa) %{_libexecdir}/sympa/sympa_soap_server-wrapper.fcgi
%{_libexecdir}/sympa/sympa_soap_server.fcgi
%attr(-,sympa,sympa) %{_libexecdir}/sympa/wwsympa-wrapper.fcgi
%{_libexecdir}/sympa/wwsympa.fcgi
%{_mandir}/man1/*
%{_mandir}/man3/*
%{_mandir}/man5/*
%{_mandir}/man8/*
%{_datadir}/sympa
%{_datadir}/locale/*/*/*
%{_sysconfdir}/smrsh/*
%dir %attr(-,sympa,sympa) %{_sysconfdir}/sympa
%config(noreplace,missingok) %attr(-,sympa,sympa) %{_sysconfdir}/sympa/*
%{_initrddir}/sympa
