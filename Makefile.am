# Makefile.am - Top-level Makefile.am for Sympa
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

SUBDIRS = src default doc po www

check_SCRIPTS = t/compile_modules.t \
		t/compile_executables.t \
		t/pod_syntax.t \
		t/pod_spelling.t \
		t/pod_coverage.t \
		t/Datasource_LDAP.t \
		t/Instruction.t \
		t/Language.t \
		t/LockedFile.t \
		t/Logger.t \
		t/Mailer.t \
		t/Message.t \
		t/Tools_Data.t \
		t/Tools_Daemon.t \
		t/Tools_File.t \
		t/Tools_Time.t \
		t/Tools_SMIME.t
check_DATA = t/locale/cs/LC_MESSAGES/sympa.mo \
	     t/locale/cs/LC_MESSAGES/web_help.mo \
	     t/locale/zh_TW/LC_MESSAGES/sympa.mo

EXTRA_DIST = important_changes.pl \
	     sympa.spec.in \
	     sympa.spec \
	     $(check_SCRIPTS) $(check_DATA)
CLEANFILES = sympa_wizard.pl.inst

MSGFMT=@MSGFMT@
.po.mo:
	$(MSGFMT) -o $@ $<

check-local:
	[ -z "$(TEST_FILES)" ] && TEST_FILES="$(check_SCRIPTS)"; \
	PERL5LIB=src/lib; export PERL5LIB; \
	$(PROVE) $$TEST_FILES

check-local-jenkins:
	[ ! -d out ] && mkdir out; \
	[ -z "$(TEST_FILES)" ] && TEST_FILES="$(check_SCRIPTS)"; \
	PERL5LIB=src/lib; export PERL5LIB; \
	$(PROVE) --archive out $$TEST_FILES

install-data-hook: installdir installconfig nextstep importantchanges

installdir:
	@echo "Creating plugin directory"
	@for dir in $(modulesdir)/Sympa/Template/Plugin; do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			install -d -m 755 $(DESTDIR)$$dir; \
		fi; \
	done
	@echo "Creating writable directories"
	@for dir in $(expldir) $(spooldir) $(spooldir)/msg $(spooldir)/digest \
		$(spooldir)/moderation $(spooldir)/expire $(spooldir)/auth \
		$(spooldir)/outgoing $(spooldir)/tmp $(spooldir)/task \
		$(bouncedir) $(arcdir) $(piddir) $(staticdir) $(staticdir)/js $(sysconfdir); do \
		if [ ! -d $(DESTDIR)$$dir ] ; then \
			echo "Creating $(DESTDIR)$$dir"; \
			install -d -m 755 $(DESTDIR)$$dir; \
		fi; \
		chown $(USER) $(DESTDIR)$$dir || /bin/true; \
		chgrp $(GROUP) $(DESTDIR)$$dir || /bin/true; \
	done

sympa_wizard.pl.inst: $(top_srcdir)/src/sbin/sympa_wizard.pl.in Makefile
	$(SED) \
		-e 's|--PERL--|$(PERL)|' \
		-e 's|--modulesdir--|$(top_srcdir)/src/lib|' \
		< $(top_srcdir)/src/sbin/sympa_wizard.pl.in > $@

installconfig: installdir sympa_wizard.pl.inst
	@echo "Installing basic configuration ..."
	export PERL5LIB=$(DESTDIR)$(modulesdir); \
	if [ ! -f  $(DESTDIR)$(confdir)/sympa.conf ]; then \
		echo "This looks like your first Sympa installation. The following wizard will assist you to create your first Sympa configuration.";\
		if [ ! -d $(DESTDIR)$(confdir) ]; then \
			$(INSTALL) -d -m 755 $(DESTDIR)$(confdir); \
		fi; \
		$(PERL) sympa_wizard.pl.inst \
			--create sympa.conf \
			--target $(DESTDIR)$(confdir)/sympa.conf \
			|| /bin/true; \
	fi; \
	if [ ! -f $(DESTDIR)$(sysconfdir)/data_structure.version ]; then \
		cd $(DESTDIR)$(sysconfdir); \
		echo "# automatically created file" >> data_structure.version; \
		echo "# you should not modify it" >> data_structure.version; \
		echo $(VERSION) >> data_structure.version; \
		chown $(USER) data_structure.version || /bin/true; \
		chgrp $(GROUP) data_structure.version || /bin/true; \
	fi

nextstep: 
	@echo ""
	@echo "** You can find documentation at:"
	@echo "** http://www.sympa.org/documentation/manual/sympa-$(VERSION).pdf"
	@echo ""
	@echo "#########################################################"
	@echo "# CHECK YOU HAVE ALL THE NEEDED MODULES:"
	@echo "#    * Check the required perl modules are installed:"
	@echo "#        $(sbindir)/sympa_wizard.pl --check"
	@echo "#"
	@echo "# FIRST INSTALLATION:"
	@echo "#    * Check the INSTALL file."
	@echo "#    * Run the wizard to define some required parameters that can't be guessed."
	@echo "#        $(sbindir)/sympa_wizard.pl"
	@echo "#"
	@echo "# UPGRADING"
	@echo "#    * Run this script to upgrade your data structures:"
	@echo "#        $(sbindir)/sympa.pl --upgrade"
	@echo "#######################################################"

importantchanges:
	if [ -f $(DESTDIR)$(modulesdir)/Sympa/Constants.pm ]; then \
		previous=`perl -Mlib=$(DESTDIR)$(modulesdir) -MSympa::Constants -e 'print Sympa::Constants::VERSION'`; \
        elif [ -f $(DESTDIR)$(bindir)/Version.pm ]; then \
                previous=`perl -Mlib=$(DESTDIR)$(bindir) -MVersion -e 'print $$Version::Version'`; \
	fi; \
	$(PERL) $(top_srcdir)/important_changes.pl \
		--current=$(VERSION) \
		--previous=$${previous};

uninstall-hook:
	rm -f $(DESTDIR)$(confdir)/sympa.conf
	rm -f $(DESTDIR)$(confdir)/wwsympa.conf
