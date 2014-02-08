%define name sympa
%define version --VERSION--
%define release 7--SUFFIX--
%define home_s --HOMEDIR--
%define data_s --DATADIR--
%define conf_s --CONFDIR--
%define etc_s --ETCDIR--
%define spoo_s --SPOOLDIR--

Summary:  Sympa is a powerful multilingual List Manager - LDAP and SQL features.
Summary(fr): Sympa est un gestionnaire de listes �lectroniques. 
Name:  %{name}
Version:  %{version}
Release:  %{release}
Copyright:  GPL
Group: --APPGROUP--
Source:  http://www.sympa.org/distribution/%{name}-%{version}.tar.--ZIPEXT--
URL: http://www.sympa.org/
Requires: MailTransportAgent
Requires: perl >= 0:5.005
Requires: perl-MailTools >= 1.14
Requires: perl-MIME-Base64   >= 1.0
Requires: perl-IO-stringy    >= 1.0
Requires: perl-Msgcat        >= 1.03
Requires: perl-MIME-tools    >= 5.209
Requires: perl-CGI    >= 2.52
Requires: perl-DBI    >= 1.06
Requires: perl-DB_File    >= 1.73
Requires: perl-ldap >= 0.10
Requires: perl-CipherSaber >= 0.50
# AJOUTER MySQL (base et DBD)
## Also requires a DBD for the DBMS 
## (perl-DBD-Pg or Perl- Msql-Mysql-modules)
Requires: perl-FCGI    >= 0.48
Requires: perl-Digest-MD5
Requires: MHonArc >= 2.4.6
Requires: webserver
Requires: openssl >= 0.9.5a
Prereq: /usr/sbin/useradd
Prereq: /usr/sbin/groupadd
BuildRoot: %{_tmppath}/%{name}-%{version}
#BuildRequires: openssl-devel >= 0.9.5a
Prefix: %{_prefix}

%description
Sympa is scalable and highly customizable mailing list manager. It can cope with big lists
(200,000 subscribers) and comes with a complete (user and admin) Web interface. It is
internationalized, and supports the us, fr, de, es, it, fi, and chinese locales. A scripting
language allows you to extend the behavior of commands. Sympa can be linked to an
LDAP directory or an RDBMS to create dynamic mailing lists. Sympa provides
S/MIME-based authentication and encryption.

Documentation is available under HTML and Latex (source) formats. 


%prep
rm -rf $RPM_BUILD_ROOT

%setup -q

%build

make sources languages CONFDIR=%{conf_s}

%install
rm -rf $RPM_BUILD_ROOT

#make INITDIR=/etc/rc.d/init.d HOST=MYHOST DIR=%{home_s} EXPL_DIR=%{home_s}/expl PIDDIR=--PIDDIR-- BINDIR=%{home_s}/bin SBINDIR=%{home_s}/sbin LIBDIR=%{home_s}/lib MAILERPROGDIR=/etc/smrsh ETCBINDIR=%{home_s}/bin/etc DESTDIR=$RPM_BUILD_ROOT MANDIR=%{_mandir} ICONSDIR=--ICONSDIR-- CGIDIR=%{home_s}/sbin install
make INITDIR=%{_initrddir} HOST=MYHOST DIR=%{home_s} EXPL_DIR=--EXPLDIR-- PIDDIR=--PIDDIR-- BINDIR=--BINDIR-- SBINDIR=--SBINDIR-- LIBDIR=--LIBDIR-- MAILERPROGDIR=--BINDIR-- ETCDIR=--ETCDIR-- ETCBINDIR=%{data_s} DESTDIR=$RPM_BUILD_ROOT MANDIR=%{_mandir} ICONSDIR=--ICONSDIR-- CGIDIR=--CGIDIR-- CONFDIR=--CONFDIR-- NLSDIR=--NLSDIR-- SCRIPTDIR=--SCRIPTDIR-- SAMPLEDIR=--SAMPLEDIR-- SPOOLDIR=%{spoo_s} install

## Setting Runlevels
for I in 0 1 2 6; do
        mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc$I.d
        ln -s %{_initrddir}/%{name} $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/K25%{name}
done
for I in 3 5; do
        mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc$I.d
        ln -s %{_initrddir}/%{name} $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/S95%{name}
done

#echo "See README and INSTALL in %{prefix}/doc/%{name}-%{version}" > $RPM_BUILD_ROOT%{home_s}/README.first
 
## Populate config directory
#for dir in create_list_templates scenari wws_templates templates; do
#  mkdir -p $RPM_BUILD_ROOT--ETCDIR--/$dir
#done
 
## Copy to examples directory
#mkdir -p $RPM_BUILD_ROOT%{data_s}/examples/config
#(cd $RPM_BUILD_ROOT%{data_s}/examples/config;
#  cp -p $RPM_BUILD_ROOT%{conf_s}/sympa.conf .
#  cp -p $RPM_BUILD_ROOT%{conf_s}/wwsympa.conf .
#)

## Create a directory for Sympa PIDs
#mkdir -p $RPM_BUILD_ROOT/var/run/sympa

# Move DB scripts to examples/db
#mkdir -p $RPM_BUILD_ROOT%{data_s}/examples/db
#mv $RPM_BUILD_ROOT%{data_s}/examples/script/create_db.* \
#   $RPM_BUILD_ROOT%{data_s}/examples/db/

## Create Sympa home dir and spools
#mkdir -p $RPM_BUILD_ROOT%{home_s}/expl
#for dir in msg bounce wwsarchive wwsbounce; do
#  mkdir -p $RPM_BUILD_ROOT%{spoo_s}/$dir
#done

%pre

# Create "sympa" group if it is not already there
if ! grep -q "^sympa:" /etc/group; then
  echo "Adding system group: sympa."
  /usr/sbin/groupadd sympa
fi
 
# Add "apache" in group "sympa" so that it could access
# /etc/sympa/wwsympa.conf and therefore a working wwsympa ;-)
if ! grep -q "^sympa:.*\<apache\>" /etc/group; then
  echo "Adding apache in group sympa."
  comma="";
  [ -n "$(grep '^sympa:' /etc/group | sed -e 's/^sympa:.*:.*://')" ] && comma=",";
  perl -pi -e "s/^(sympa:.*)/\1${comma}apache/" /etc/group
fi
 
# Create "sympa" user if it is not already there
home_s_pw=`sed -n -e "/^sympa:[^:]*:[^:]*:[^:]*:[^:]*:\([^:]*\):.*/s//\1/p" /etc/passwd`
if [ -z "$home_s_pw" ]; then
  echo "Adding system user: sympa."
  /usr/sbin/useradd -u 89 -m -g sympa -d %{home_s} sympa -c "Sympa mailing-list manager" -s "/bin/false"
elif [ "$home_s_pw" != "%{home_s}" ]; then
  echo "Problem: user \"sympa\" already exists with a home different from %{home_s}"
  exit 0
fi

%post
#perl -pi -e "s|MYHOST|${HOSTNAME}|g" /etc/sympa.conf /etc/wwsympa.conf

# Ensure permissions and ownerships are right
#chown -R root.root %{_libdir}/sympa
#chown -R sympa.sympa %{spoo_s}
#chmod -R ug=rwX,o=X %{spoo_s}
#chown -R sympa.sympa /var/run/sympa
 
#chown -R sympa.sympa %{conf_s}/*
#chmod 0640 %{conf_s}/sympa.conf
 
if [ -e "/var/log/sympa" ] && [ ! -f "/var/log/sympa" ]; then
  echo "Problem: /var/log/sympa already exists but it is not a file!"
fi
touch /var/log/sympa || /bin/true
chown sympa.sympa /var/log/sympa
chmod 0640 /var/log/sympa
 
#chown sympa.sympa %{_libdir}/sympa/bin/queue
#chown sympa.sympa %{_libdir}/sympa/bin/bouncequeue
 
# Setup log facility for Sympa
if [ -f /etc/syslog.conf ] ;then
  if [ `grep -c sympa /etc/syslog.conf` -eq 0 ] ;then
    typeset -i cntlog
    cntlog=0
    while [ `grep -c local${cntlog} /etc/syslog.conf` -gt 0 ];do cntlog=${cntlog}+1;done
    if [ ${cntlog} -le 9 ];then
      echo "# added by %{name}-%{version} rpm $(date)" >> /etc/syslog.conf
      echo "local${cntlog}.*       -/var/log/%{name}" >> /etc/syslog.conf
    fi
    perl -pi -e "s|^\*\.info;|\*\.info;local${cntlog}.none;|" /etc/syslog.conf
  fi
fi
 
# Fix syslog variable for the correct subsystem to use in config files
cntlog=`sed -n -e "/^local.*sympa/s|^local\([0-9][0-9]*\)\.\*[ \t]*/var/log/sympa|\1|p" < /etc/syslog.conf`
for conffile in %{conf_s}/sympa.conf; do
  perl -pi -e "s|syslog(\s+)LOCAL[0-9]+|syslog\1LOCAL${cntlog}|" $conffile
done

# rotate log for sympa
# a inclure dans les fichiers...
if [ -d /etc/logrotate.d ] ;then
  if [ ! -f /etc/logrotate.d/sympa ] ;then
    echo "/var/log/sympa {" > /etc/logrotate.d/sympa
    echo "    missingok" >> /etc/logrotate.d/sympa
    echo "    notifempty" >> /etc/logrotate.d/sympa
    echo "    copytruncate" >> /etc/logrotate.d/sympa
    echo "    rotate 10" >> /etc/logrotate.d/sympa
    echo "}" >> /etc/logrotate.d/sympa
  fi
fi

# eventually, add queue and bouncequeue to sendmail security shell
if [ -d /etc/smrsh ]; then
  if [ ! -e /etc/smrsh/queue ]; then
    ln -s --BINDIR--/queue /etc/smrsh/queue
  fi
 
  if [ ! -e /etc/smrsh/bouncequeue ]; then
    ln -s --BINDIR--/bouncequeue /etc/smrsh/bouncequeue
  fi
fi
 
# Try to add some sample entries in /etc/aliases for sympa
for a_file in /etc/aliases /etc/postfix/aliases; do
  if [ -f ${a_file} ]; then
    if [ `grep -c sympa ${a_file}` -eq 0 ]; then
      cp -f ${a_file} ${a_file}.rpmorig
      echo >> ${a_file}
      echo "# added by %{name}-%{version} rpm " $(date) >> ${a_file}
      if [ `grep -c listmaster ${a_file}` -eq 0 ]; then
        echo "# listmaster:     root" >> ${a_file}
      fi
      echo "# sympa:          \"|/etc/smrsh/queue 0 sympa\"" >> ${a_file}
      echo "# sympa-request:  listmaster@${HOSTNAME}" >> ${a_file}
      echo "# sympa-owner:    listmaster@${HOSTNAME}" >> ${a_file}
      echo "" >> ${a_file}
      # (gb) The user have to manually comment out the new aliases
      # and then invoke: /usr/bin/newaliases
      echo "Your new aliases have been set up in ${a_file}. Please check them out before running /usr/bin/newaliases"
    else
      # Possibly fix up bad paths in aliases file
      perl -pi -e "s|/var/lib/sympa/bin/queue|%{_libdir}/sympa/bin/queue|" ${a_file}
      /usr/bin/newaliases
    fi
  fi
done


%postun
if [ ! -d %{home_s} ]; then
  /usr/sbin/userdel sympa
  /usr/sbin/groupdel sympa  
fi
if [ $1 = 0 -a -d /etc/smrsh ]; then
  if [ -L /etc/smrsh/queue ]; then
    rm -f /etc/smrsh/queue
  fi
  if [ -L /etc/smrsh/bouncequeue ]; then
    rm -f /etc/smrsh/bouncequeue
  fi

fi


%files

%defattr(-,sympa,sympa)

# Home directory
%dir %{home_s}
%dir --EXPLDIR--
 
# Documentation
%doc %attr(-,root,root) INSTALL README
# A VOIR %doc %attr(-,root,root) INSTALL LICENSE README RELEASE_NOTES
# A VOIR %doc %attr(-,root,root) doc/sympa doc/sympa.ps
%attr(-,root,root) %{_mandir}/man8/*
 
# Spools
%dir %{spoo_s}
%dir %{spoo_s}/msg
%dir %{spoo_s}/bounce
%dir %{spoo_s}/wwsarchive
%dir %{spoo_s}/wwsbounce
 
# PID directory
%dir --PIDDIR--
 
# Config file, permissions are reset in %post as (0640,sympa,sympa)
%dir %{conf_s}
%config(noreplace) %{conf_s}/sympa.conf
%config(noreplace) %{conf_s}/wwsympa.conf
 
# Config directories populated by the user
%dir %{etc_s}/create_list_templates
%dir %{etc_s}/scenari
%dir %{etc_s}/templates
%dir %{etc_s}/wws_templates
 
# Binaries
%dir --BINDIR--
--BINDIR--/*
# on suppose que BINDIR = SBINDIR = LIBDIR =
 
# Locales
%dir --NLSDIR--
--NLSDIR--/*.cat
# ATTENTION A VOIR %{_libdir}/sympa/nls/*.msg
 
# Data
%dir %{data_s}
%{data_s}/ca-bundle.crt
%{data_s}/create_list.conf
%dir %{data_s}/create_list_templates
%{data_s}/create_list_templates/*
%{data_s}/edit_list.conf
%{data_s}/mhonarc-ressources
%dir %{data_s}/scenari
%{data_s}/scenari/*
%dir %{data_s}/templates
%{data_s}/templates/*
%dir %{data_s}/wws_templates
%{data_s}/wws_templates/*
 
# Icons and binaries for Apache
--CGIDIR--/wwsympa.fcgi
%dir --ICONSDIR--
--ICONSDIR--/*
 
# Init scripts
%config(noreplace) %attr(0755,root,root) %{_initrddir}/sympa

# Examples
%dir %{data_s}/examples
#a remettre !  %dir %{data_s}/examples/config
#a remettre !  %{data_s}/examples/config/sympa.conf
#a remettre !  %{data_s}/examples/config/wwsympa.conf
#a remettre !  %dir %{data_s}/examples/db
#a remettre !  %{data_s}/examples/db/*
#a remettre !  %dir %{data_s}/examples/expl
#a remettre !  %{data_s}/examples/expl/*
#a remettre !  %dir %{data_s}/examples/sample
#a remettre !  %{data_s}/examples/sample/*
#a remettre !  %dir %{data_s}/examples/script
#a remettre !  %{data_s}/examples/script/*
#a enlever ! 
%{data_s}/examples/*


%clean
rm -rf $RPM_BUILD_ROOT

%changelog

* Thu Dec 12 2002 Guy PARESSANT <net@ac-nantes.fr> 3.4.2-8
- Rebuild for sympa 3.4.2
- store the files on directory choosed by Mandrake
- the options used before building the rpm for Mandrake 9 :
./configure --prefix=/var/lib/sympa \
--with-confdir=/etc/sympa \
--with-etcdir=/etc/sympa \
--with-cgidir=/var/www/cgi-bin \
--with-iconsdir=/var/www/icons/sympa \
--with-bindir=/usr/lib/sympa/bin \
--with-sbindir=/usr/lib/sympa/bin \
--with-libexecdir=/usr/lib/sympa/bin \
--with-libdir=/usr/lib/sympa/bin \
--with-datadir=/usr/share/sympa \
--with-expldir=/var/lib/sympa/expl \
--with-mandir=/usr/share/man \
--with-piddir=/var/run/sympa \
--with-openssl=/usr/bin/openssl \
--with-nlsdir=/usr/lib/sympa/nls \
--with-scriptdir=/usr/lib/sympa/bin \
--with-sampledir=/usr/share/sympa/examples \
--with-spooldir=/var/spool/sympa

* Mon May 13 2002 Zenon Panoussis <oracle@xs4all.nl>
- Added check and aliases file and link for Courier
- Changed "Requires: apache" to "Requires: webserver" for compatibility 
  with apache2

* Wed Nov 15 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.3b.3
- HOMEPAGE is /var/sympa/
- install binaries with SetUID in /etc/smrsh
- new lib/ sbin/ directories

* Wed Sep 26 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.3a.vhost
- add bouncequeue-related
- add perl-Cipher-saber

* Thu Jun  5 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.2
- perl-CGI.pm becomes perl-CGI

* Thu Feb  8 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.1b.3
- Requires MHOnArc 2.4.6

* Tue Nov 21 2000 Olivier Salaun <olivier.salaun@cru.fr> 3.0b
- Requires perl-DB_File and perl-perl-ldap
- Set sympa user shell to /bin/false 
- Directories (etc expl spool) now created by sympa

* Wed Sep 06 2000 Olivier Salaun <olivier.salaun@cru.fr> 3.0a
- No more nls/ in docs
- generalize %{home_s}
- use DESTDIR
- changed the description ; french version abandoned
- sample conf files now installed by Makefile
- no more patches (Openssl, Mhonarc)
- set correct right in %files
- use $RPM_SOURCE_DIR
- install SYSV init script
- openssl-devel NOT required

* Wed Aug 30 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-5mdk
- requires apache because of wwsympa.
- buildrequires apache to fix building for machines without apache (sic).

* Fri Aug 18 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-4mdk
- rebuild to enable openssl.
- add requires and buildrequires for {openssl,openssl-devel}
- copy the wwsympa configuration file on postun if none is present in /etc.

* Thu Aug 17 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-3mdk
- rebuild to fix some more annoying bugs.

* Mon Aug 14 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-2mdk
- rebuild for sympa disaster

* Tue Aug 01 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-1mdk
- big shiny new version and got this ugly fucking piece of shit to package
- rebuild for BM

* Tue Apr 18 2000 Jerome Dumonteil <jd@mandrakesoft.com>
- change group
* Fri Mar 31 2000 Jerome Dumonteil <jd@mandrakesoft.com>
- change group
- modif postun
* Wed Dec 29 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- version 2.4
* Fri Dec 17 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- added link /etc/smrsh/queue
- added link for /home/sympa/expl/helpfile
* Thu Dec 09 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- remove backup files from sources
- strip binary
* Mon Dec  6 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- added prereq info.
- little cleanup.
* Fri Dec  3 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- first version of rpm.
