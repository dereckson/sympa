%
% Copyright (C) 1999, 2000, 2001 Comit� R�seau des Universit�s & Serge Aumont, Olivier Sala�n
%
% Historique
%   1999/04/12 : pda@prism.uvsq.fr : conversion to latex2e
%

[STOPPARSE]
\documentclass [twoside,a4paper] {report}

    \usepackage {epsfig}
    \usepackage {xspace}
    \usepackage {makeidx}
    \usepackage {html}

    \usepackage {palatino}
    \renewcommand {\ttdefault} {cmtt}

    \setlength {\parskip} {5mm}
    \setlength {\parindent} {0mm}

    \pagestyle {headings}
    \makeindex

    \sloppy

    \usepackage [dvips] {changebar}
    % \begin {changebar} ... \end {changebar}
    % ou \cbstart ... \cbend   et \cbdelete

    %
    % Change bars are not well rendered by latex2html
    %

    \begin {htmlonly}
        \renewcommand {\cbstart} {}
        \renewcommand {\cbend} {}
        \renewcommand {\cbdelete} {}
    \end {htmlonly}

    % black text on a white background, links unread in red
    % \bodytext {TEXT="#000000" BGCOLOR="#ffffff" LINK="#ff0000"}
    % black text on a white background
    \bodytext {TEXT="#000000" BGCOLOR="#ffffff"}

    \newcommand {\fig} [2]
    {
        \begin {figure} [htbp]
            \hrule
            \vspace {3mm}
            \begin {center}
                \epsfig {figure=#1.ps}
%                \epsffile {figure=#1.ps}
            \end {center}
            \vspace {2mm}
            \caption {#2}
            \vspace {3mm}
            \hrule
            \label {fig:#1}
        \end {figure}
    }

    \newcommand {\version} {2.7}

    \newcommand {\samplelist} {mylist}

    \newcommand {\samplerobot} {some.domain.org}

    % #1 = text to index and to display
    \newcommand {\textindex} [1] {\index{#1}#1}

    % #1 = sort key, #2 displayed in text and index
    \newcommand {\textindexbis} [2] {\index{#1@#2}#2}

    \newcommand {\Sympa} {\textit {Sympa}\xspace}

    \newcommand {\WWSympa} {\textindexbis {WWSympa}{\textit {WWSympa}}\xspace}

    % #1 = sort key, #2 : displayed in text and index, #3 displayed in index
    \newcommand {\ttindex} [3]  {\index{#1@\texttt {#2} #3}\texttt {#2}}

    \newcommand {\example} [1] {Example: \texttt {#1}}

    \newcommand {\unixcmd} [1] {\ttindex {#1} {#1} {UNIX command}}

    \newcommand {\mailcmd} [1] {\ttindex {#1} {#1} {mail command}}

    \newcommand {\cfkeyword} [1] {\ttindex {#1} {#1} {configuration keyword}}

    \newcommand {\default} [1]  {(Default value: \texttt {#1})}

    \newcommand {\scenarized} [1] {\texttt {#1} parameter is defined by scenario (see~\ref {scenarii}, page~\pageref {scenarii})}

    \newcommand {\lparam} [1] {\ttindex {#1} {#1} {list parameter}}

    \newcommand {\file} [1] {\ttindex {#1} {#1} {file}}

    \newcommand {\dir} [1]  {\ttindex {#1} {#1} {directory}}

    \newcommand {\tildefile} [1] {\ttindex {#1} {\~{}#1} {file}}

    \newcommand {\tildedir} [1] {\ttindex {#1} {\~{}#1} {directory}}

    \newcommand {\rfcheader} [1] {\ttindex {#1:} {#1:} {header}}

    % Notice: use {\at} when using \mailaddr
    \newcommand {\at} {\char64}
    \newcommand {\mailaddr} [1] {\texttt {#1}}   
% mail address
%        {\ttindex {#1} {#1} {mail address}}


\begin {document}

    \title {\Huge\bf Sympa \\ \huge\bf Mailing Lists Management Software}
    \author {
        Serge Aumont,
        Olivier Sala\"un,
        Christophe Wolfhugel,
         }
[STARTPARSE]
    \date {[date]}
[STOPPARSE]
\begin {htmlonly}
For printing purpose, use the 
\htmladdnormallink {postscript format version} {sympa.ps} of this documentation.
\end {htmlonly}

\maketitle


{
    \setlength {\parskip} {0cm}



    \cleardoublepage

    \tableofcontents
    % \listoffigures
    % \listoftables
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Presentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Presentation}

\Sympa is an electronic mailing list manager.  It is used to automate
list management functions such as subscription, moderation,
archive and shared document management. 
It also includes management functions which
would normally require a substantial amount of work (time-consuming
and costly for the list owner). These
functions include automatic management of subscription renewals,
list maintenance, and many others.

\Sympa manages many different kinds of lists. It includes
a web interface for all list functions including management. It allows
a precise definition of each list feature, such as sender authorization,
the moderating process, etc. \Sympa defines, for each feature of each list,
exactly who is authorized to perform the relevant operations, along with the
authentication method to be used. Currently, authentication can be based
on either an SMTP From header, a password, or an S/MIME signature.\\
\Sympa is also able to extract electronic
addresses from an LDAP directory or SQL server, and include them
dynamically in a list.

\Sympa manages the dispatching of messages, and makes it possible to
reduce the load on the computer system where it is installed. In
configurations with sufficient memory, \Sympa is especially well
adapted to handling large lists: for a list of 20,000 subscribers, it requires
less than 6 minutes to send a message to 95 percent of the subscribers,
assuming that the network is available (tested on a 300~MHz, 256~MB
i386 server with Linux).

This guide covers the installation, configuration and management of
the current release (\version) of
\htmladdnormallink {sympa} {http://listes.cru.fr/sympa/}.

\section {License}

\Sympa is free software; you may distribute it under the terms
of the
\htmladdnormallinkfoot {GNU General Public License Version 2}
        {http://www.gnu.org/copyleft/gpl.html}

You may make and give away verbatim copies of the source form of
this package without restriction, provided that you duplicate all
of the original copyright notices and associated disclaimers.

\section {Features}

\Sympa provides all the basic features that any mailing list management robot
should include. While most \Sympa features have their equivalents in other
mailing list applications, \Sympa is unique in including features
in a single software package, including:

\begin {itemize}
    \item High speed distribution processing and load control. \Sympa
        can be tuned to allow the system administrator to control
        the amount of computer resources used.  Its optimized algorithm
        allows:

        \begin {itemize}
            \item the use of your preferred SMTP engine, e.g.
                \unixcmd {sendmail}, \unixcmd {qmail} or \unixcmd
                {postfix}

            \item tuning of the maximum number of SMTP child processes

            \item grouping of messages according to recipients' domains,
	    	and tuning of the grouping factor

            \item detailed logging

        \end {itemize}

    \item \textbf {Multilingual} messages. The current version of
        \Sympa allows the administrator to choose the language
        catalog at run time. At the present time the \Sympa robot is available in
        Chinese (Big5 and GB), Czech, English, Finnish, French, German, Hungarian, Italian, Polish, 
	Portuguese, Spanish. The web interface is available in English, Spanish
	and French.

    \item \textbf {MIME support}. \Sympa naturally respects
        \textindex {MIME} in the distribution process, and in addition
        allows list owners to configure their lists with
        welcome, goodbye and other predefined messages using complex
        \textindex {MIME} structures. For example, a welcome message can be
        \textbf in {multipart/alternative} format, using \textbf {text/html},
        \textbf {audio/x-wav}~:-), or whatever (Note that \Sympa
        commands in multipart messages are successfully processed, provided that
	one part is \textbf {text/plain }).

    \item The \textbf {sending process is controlled} on a per-list basis.
        The list definition allows a number of different actions for
        each incoming message. A \lparam {private} list is a list where
        only subscribers can send messages. A list configured using
        \lparam {privateoreditorkey} mode accepts incoming messages
        from subscribers, but will forward any other (i.e. non-subscriber) message
	to the editor with a one-time secret numeric key that will be used by the
        editor to \textit {reject} or \textit {distribute} it.
        For details about the different sending modes, refer to the
        \lparam {send} parameter (\ref {par-send}, page~\pageref
        {par-send}). The sending process configuration (as well as most other list
	operations) is defined using  a \textbf {scenario}. Any listmaster
        can define new scenarios (scenarii) in order to complement the 20
	predefined configurations included in the distribution. \\
        Example : forward multipart messages to the list editor, while
	distributing others without requiring any further authorization.
        
    \item Privileged operations can be performed by list editors or
        list owners (or any other user category), as defined in the list
        \file {config} file or by
        the robot \textindex {administrator}, the listmaster, defined
        in the \file {/etc/sympa.conf}  global configuration file (listmaster
        can also be defined for a particular virtual robot).
        Privileged operations include the usual \mailcmd {ADD}, \mailcmd
        {DELETE} or \mailcmd {REVIEW} commands, which can be
        authenticated via a one-time password or an S/MIME signature.
	 Any list owner using the \mailcmd {EXPIRE}
        command can require the renewal of subscriptions. This is made
        possible by the presence of a subscription date stored in the
        \Sympa database.

    \item full virtual robot definition : one real \Sympa installation
        can provide multiple virtual robots with both email and web interface
        customization.

    \item E-mail addresses can be retrieved dynamically from a database
    	accepting SQL queries, or from an LDAP directory. In the interest
	of reasonable response times, \Sympa retains the data source in an
	internal cache controlled by a TTL (Time To Live) parameter.

    \item Inclusion of the subscribers of one list among the subscribers of
    	another. This is real inclusion, not the dirty, multi-level cascading
	one might otherwise obtain by simply "subscribing list B to list A".
	 
    \item The internal subscriber data structure can be stored in a
        database or, for compatibility with versions 1.x, in text
        files. The introduction of databases came out of the
        \WWSympa project.  The database ensures a secure access to
        shared data. The PERL database API \textit {dbi/dbd} enables
        interoperability with various RDBMS (MySQL, PostgreSQL,
        Oracle, Sybase).

    \label {wwsympa} 
    \item {\WWSympa} is a global Web interface to all \Sympa functions
    	(including administration). It provides :

        \begin {itemize}

	    \item classification of lists, along with a search index

            \item access control to all functions, including the list of lists
                  (which makes WWSympa particularly well suited to be the main
		  groupware tool within an intranet)
 
       	    \item management of shared documents (download, upload, specific
		  access control for each document)

            \item an HTML document presenting each user with the list of
		  her current subscriptions, including access to archives, and
		  subscription options

            \item management tools for list managers (bounce processing, changing of
                  list parameters, moderating incoming messages)

            \item tools for the robot administrator (list creation, global robot
                  configuration) \index{administrator}

        \end {itemize}



\end {itemize}

\section {Project directions}

\Sympa is a very activ project : check the release note 
\htmladdnormallinkfoot {release note} {http://listes.cru.fr/sympa/release.shtml}.
So it is no longer possible to
maintain multiple document about Sympa project direction.
Please refer to \htmladdnormallinkfoot {in-the-futur document} {http://www.sympa.org/sympa/direct/in-the-future.html}
for information about project direction.

\section {History}

\Sympa development started from scratch in 1995. The goal was to
ensure continuity with the \textindex {TULP} list manager, produced
partly by the initial author of \Sympa: Christophe Wolfhugel.

New features were required, which the TULP code was just not up to
handling. The initial version of \Sympa brought authentication,
the flexible management of commands, high performances in internal
data access, and object oriented code for easy code maintenance.

It took nearly two years to produce the first market releases.

\section {Authors and credits}

Christophe Wolfhugel is the author of the first beta version of
\Sympa. He developed it while working for the
\htmladdnormallinkfoot {Institut Pasteur} {http://www.pasteur.fr}.

Later developments have mainly been driven by the
\htmladdnormallinkfoot {Comit\'e R\'eseaux des Universit\'es} {http://www.cru.fr}
(Olivier Sala\"un and Serge Aumont), who look after a large mailing
list service.

Our thanks to all contributors, including:

\begin {itemize}

   \item Pierre David, who in addition to his help and suggestions
       in developing the code, participated more than actively in
       producing this manual.

  \item Ollivier Robert, Usenet Canal Historique and the good manners
      guru in the PERL program.

  \item Rapha\"el Hertzog (debian) and St\'ephane Poirey (redhat) for
      Linux packages.

  \item Olivier Lacroix, for all his perseverance in bug fixing.

  \item Fabien Marquois, who introduced many new features such as
      the digest.

  \item Alex Nappa and Josep Roman for their Spanish translations

  \item Carsten Clasohm and Jens-Uwe Gaspar for their German translations

  \item Marco Ferrante for his Italian translations

  \item Hubert Ulliac for search in archive base on marcsearch.pm

  \item Tung Siu Fai for his Chinese translations

  \item and also: Manuel Valente, Dominique ROUSSEAU,
    Laurent Ghys, Francois Petillon, Guy Brand, Jean Brange, Fabrice
    Gaillard, Herv� Maza

   \item Anonymous critics who never missed a chance to
       remind us that \textit {smartlist} already did all that
       better.

   \item All contributors and beta-testers cited in the \file
       {RELEASE\_NOTES} file, who, by serving as guinea pigs and
       being the first to use it, made it possible to quickly and
       efficiently debug the \Sympa software.

    \item Bernard Barbier, without whom \Sympa would not
        have a name.

\end {itemize}

We ask all those we have forgotten to thank to accept our apologies
and to let us know, so that we can correct this error in future
releases of this documentation.

\section {Mailing lists and support}
    \label {sympa@cru.fr}

If you wish to contact the authors of \Sympa, please use the address
\mailaddr {sympa-authors{\at}cru.fr}.

There are also a few \htmladdnormallinkfoot {mailing-lists about \Sympa} {http://listes.cru.fr/wws/lists/informatique/sympa} :

	\begin {itemize}
	   \item  \mailaddr {sympa-users{\at}cru.fr} general info list
	   
	   \item   \mailaddr {sympa-fr{\at}cru.fr}, for French-speaking users
			   
	   \item   \mailaddr {sympa-announce{\at}cru.fr}, \Sympa announcements
			  
	   \item   \mailaddr {sympa-dev{\at}cru.fr}, \Sympa developers
			
	   \item   \mailaddr {sympa-translation{\at}cru.fr}, \Sympa translators
  
	\end {itemize}

To join, send the following message to \mailaddr {sympa{\at}cru.fr}:

\begin {quote}
    \texttt {subscribe} \textit {Listname} \textit {Firstname} \textit {Name}
\end {quote}

(replace \textit {Listname}, \textit {Firstname} and \textit {Name} by the list name, your first name and your family name).

You may also consult the \Sympa \htmladdnormallink {home page} {http://listes.cru.fr/sympa},
you will find the latest version, \htmladdnormallink {FAQ} {http://listes.cru.fr/sympa/fom-serve/cache/1.html} and so on.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Overview: what does \Sympa consist of ?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {what does \Sympa consist of ?}

%\begin {htmlonly}
%<A NAME="overview">
%\end {htmlonly}

\section {Organization}
\label {organization}

Here is a snapshot of what \Sympa looks like once it has settled down
on your system. This also illustrates the \Sympa philosophy, I guess.
Almost all configuration files can be defined for a particular list, for
a virtual robot or for the whole site.  

\begin {itemize}

	\item \tildedir {sympa/}\\
	The root directory of \Sympa. You will find almost everything
	related to \Sympa under this directory, except logs and main
	configuration files.
	
	\item \tildedir {sympa/bin/}\\
	This directory contains the binaries, including CGI. It
	also contains the default scenarios, templates and configuration
	files as in the distribution.  \tildedir {sympa/bin/} may be completly
        overwritten by the \unixcmd {make install} So you must not customize
        templates and scenarii under  \tildedir {sympa/bin/}.

	\item \tildedir {sympa/bin/etc/}\\
	Here \Sympa stores the default versions of what it will otherwise find
	in \tildedir {sympa/etc/} (scenarios, templates and configuration
	files, recognized S/Mime certificates).

	\item \tildedir {sympa/etc/}\\
	This is your site's configuration directory. Consult
	\tildedir {sympa/bin/etc/} when drawing up your own.

	\item \tildedir {sympa/etc/create\_list\_templates/}\\
	List templates (suggested at list creation time).

	\item \tildedir {sympa/etc/scenari/}\\
	This directory will contain your scenarii (or scenarios, if you prefer).
	If you don't know what the hell a scenario is, refer to \ref {scenarii}, 
	page~\pageref {scenarii}. Thoses scenarii are default scenarii but you may
        \tildedir {sympa/etc/\samplerobot/scenari/} for default scenarii of \samplerobot
        virtual robot and \tildedir {sympa/expl/\samplelist/scenari} for scenarii
        specific to a particular list 
	
	\item \tildedir {sympa/etc/wws\_templates/}\\
	The web interface (\WWSympa) is composed of template HTML
	files parsed by the CGI program. Templates can also 
        be defined for a particular list in \tildedir {sympa/expl/\samplelist/wws\_templates/}
        or in \tildedir {sympa/etc/\samplerobot/wws\_templates/}

	\item \tildedir {sympa/etc/templates/}\\
	Some of the mail robot's replies are defined by templates
	(\file{welcome.tpl} for SUBSCRIBE). You can overload
	these template files in the individual list directories or
        for each virtual robot, but these are the defaults.


	\item \tildedir {sympa/etc/\samplerobot}\\
        The directory to define the virtual robot \samplerobot dedicated to
        managment of all lists of this domain (list describtion of \samplerobot are stored
        in \tildedir {sympa/expl/\samplerobot}).
        Thoses directories for virtual robots has the same structure as  \tildedir {sympa/etc} which is
        configuration dir of the default robot. 

	\item \tildedir {sympa/expl/}\\
	\Sympa's working directory.

	\item \tildedir {sympa/expl/\samplelist}\\
	The list directory (refer to \ref {list-directory}, 
	page~\pageref {list-directory}). Lists stored in this directory are
        belong the default robot as defined in sympa.conf file, but a list
        can be stored in \tildedir {sympa/expl/\samplerobot/\samplelist} directory and it
        is managed by \samplerobot virtual robot.

	\item \tildedir {sympa/expl/X509-user-certs}\\
	The directory where Sympa store all user's certificat

	\item \tildedir {sympa/nls/}\\
	Internationalization directory. It contains XPG4-compatible
	message catalogues. \Sympa has currently been translated
	into 8 different languages.

	\item \tildedir {sympa/spool/}\\
	\Sympa uses 7 different spools (see \ref{spools}, page~\pageref{spools}).

	\item \tildedir {sympa/src/}\\
	\Sympa sources.

\end {itemize}

\section {Binaries}
\label {binaries}

\begin {itemize}

	\item \file {sympa.pl}\\
	The main daemon ; it processes commands and delivers
	messages. Continuously scans the \dir {msg/} spool.

	\item \file {wwsympa.fcgi}\\
	The CGI program offering a complete web interface
	to mailing lists. It can work in both classical CGI and
	FastCGI modes, although we recommend FastCGI mode, being
	up to 10 times faster.

	\item \file {bounced.pl}\\
	This daemon processes bounces (non-delivered messages),
	looking for the bad addresses. List owners will later
	access bounce information via \WWSympa. Continuously scans
	the \dir {bounce/} spool.

	\item \file {archived.pl}\\
	This daemon feeds the web archives, converting messages
	to HTML format and linking them. It uses the amazing 
	\file {MhOnArc}. Continuously scans the \dir {outgoing/} 
	spool.

	\item \file {queue}\\
	This small program gets the incoming messages from the aliases
	and stores them in \dir {msg/} spool.

	\item \file {bouncequeue}\\
	Same as \file {queue} for bounces. Stores bounces in 
	\dir {bounce/} spool.

\end {itemize}

\section {Configuration files}

\begin {itemize}

	\item \file {sympa.conf}\\
	The main configuration file.
	See \ref{exp-admin}, page~\pageref{exp-admin}.
	

	\item \file {wwsympa.conf}\\
	\WWSympa configuration file.
	See \ref{wwsympa}, page~\pageref{wwsympa}.
	
	\item \file {edit\_list.conf}\\
	Defines which parameters/files are editable by
	owners. See \ref{list-edition}, page~\pageref{list-edition}.

	\item \file {topics.conf}\\
	Contains the declarations your site's topics (classification in
	\WWSympa), along with their titles. A sample is provided in the
	\dir {sample/} directory of the sympa distribution.
	See \ref{topics}, page~\pageref{topics}.

\end {itemize}

\section {Spools}
\label {spools}

See \ref{spool-related}, page~\pageref{spool-related} for spool definition
in \file {sympa.conf}.

\begin {itemize}

	\item \tildedir {sympa/spool/auth/}\\
	For storing messages until they have been confirmed.

	\item \tildedir {sympa/spool/bounce/}\\
	For storing incoming bouncing messages.

	\item \tildedir {sympa/spool/digest/}\\
	For storing lists' digests before they are sent.

	\item \tildedir {sympa/spool/expire/}\\
	Used by the expire process.

	\item \tildedir {sympa/spool/mod/}\\
	For storing unmoderated messages.

	\item \tildedir {sympa/spool/msg/}\\
	For storing incoming messages (including commands).

	\item \tildedir {sympa/spool/outgoing/}\\
	\file {sympa.pl} dumps messages in this spool to await archiving
	by \file {archived.pl}.

\end {itemize}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Installing Sympa
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {Installing \Sympa}

%\begin {htmlonly}
%<A NAME="installsympa">
%\end {htmlonly}

\Sympa is a program written in PERL. It also calls a short
program written in C for tasks which it would be unreasonable to
perform via an interpreted language.

\section {Obtaining \Sympa, related links}

The \Sympa distribution is available from
\htmladdnormallink {\texttt {http://listes.cru.fr/sympa/}}
    {http://listes.cru.fr/sympa/}.
All important resources are referenced there:

\begin {itemize}
    \item sources
    \item \file {RELEASE\_NOTES}
    \item .rpm and .deb packages for Linux
    \item user mailing list
        (see~\ref {sympa@cru.fr}, page~\pageref {sympa@cru.fr})
    \item contributions
    \item ...
\end {itemize}


\section {Prerequisites}

\Sympa installation and configuration are relatively easy
tasks for experienced UNIX users who have already installed PERL packages.

Note that most of the installation time will
involve putting in place the prerequisites, if they are not
already on the system. No more than a handful of ancillary tools are needed,
and on recent UNIX systems their installation is normally very
straightforward. We strongly advise you to perform installation steps and
checks in the order listed below; these steps will be explained in
detail in later sections.

\begin {itemize}
    \item identification of host system characteristics

    \item installation of DB Berkeley module (already installed on
      most UNIX systems)

    \item installation of
        \htmladdnormallinkfoot {CPAN (Comprehensive PERL Archive Network)}
                {http://www.perl.com/CPAN}
        modules

    \item creation of a UNIX user

\end {itemize}

\subsection {System requirements}

You should have a UNIX system that is more or less recent in order
to be able to use \Sympa. In particular, it is necessary
that your system have an ANSI C compiler (in other words, your compiler
should support prototypes), as well as XPG4-standard \textindex {NLS}
(Native Language Support, for languages other than English) extensions.

\Sympa has been installed and tested on the following
systems, therefore you should not have any special problems:

\begin {itemize}
    \item Linux (various distributions)
    \item FreeBSD 2.2.x and 3.x
    \item Digital UNIX 4.x
    \item Solaris 2.5 and 2.6
    \item AIX 4.x
    \item HP-UX 10.20
\end {itemize}

Anyone willing to port it to NT ? ;-)

If your UNIX system has a \unixcmd {gencat} command as well as
\unixcmd {catgets(3)} and \unixcmd {catopen(3)} functions, it is
likely that it has \textindex {NLS} extensions and that these extensions comply
with the XPG4 specifications.

Finally, most UNIX systems are now supplied with an ANSI C compiler;
if this is not the case, you can install the \unixcmd {gcc} compiler,
which you will find on the nearest GNU site, for example
\htmladdnormallinkfoot {in France} {ftp://ftp.oleane.net/pub/mirrors/gnu/}.

To complete the installation, you should make sure that you have a
sufficiently recent release of the \unixcmd {sendmail} MTA, i.e. release
\htmladdnormallinkfoot {8.9.x} {ftp://ftp.oleane.net/pub/mirrors/sendmail-ucb/}
or a more recent release. You may also use \unixcmd {postfix} or
\unixcmd {qmail}.

\subsection {Install Berkeley DB (NEWDB)}

UNIX systems often include a particularly unsophisticated mechanism to
manage indexed files.  This consists of extensions known as \texttt {dbm}
and \texttt {ndbm}, which are unable to meet the needs of many more recent
programs, including \Sympa, which uses the \textindex {DB package}
initially developed at the University of California in Berkeley,
and which is now maintained by the company \htmladdnormallinkfoot
{Sleepycat software} {http://www.sleepycat.com}.  Many UNIX  systems
like Linux, FreeBSD or Digital UNIX 4.x have the DB package in the
standard version. If not you should install this tool if you have not 
already done so.

You can retrieve DB on the
\htmladdnormallinkfoot {Sleepycat site} {http://www.sleepycat.com/},
where you will also find clear installation instructions.

\subsection {Install PERL and CPAN modules}

To be able to use \Sympa you must have release 5.004\_03 or later of the
PERL language, as well as several CPAN modules.

At \texttt {make} time, the \unixcmd {check\_perl\_modules.pl} script is run to
check for installed versions of required PERL and CPAN modules. If a CPAN module is
missing or out of date, this script will install it for you. 

You can also download and install CPAN modules yourself. You will find 
a current release of the PERL interpreter in the nearest CPAN archive. 
If you do not know where to find a nearby site, use the
\htmladdnormallinkfoot {CPAN multiplexor} {http://www.perl.com/CPAN/src/latest.tar.gz};
it will find one for you.

\subsection {Required CPAN modules}

The following CPAN modules required by \Sympa are not included in the standard
PERL distribution. We try to keep this list up to date ; if you have any doubts
run the \unixcmd {check\_perl\_modules.pl} script.

\begin {itemize}
   \item DB\_File (v. 1.50 or later)
   \item Msgcat
   \item MD5
   \item MailTools (version 1.13 o later)
   \item MIME-tools (may require IO/Stringy)
   \item MIME-Base64
\end {itemize}

Since release 2, \Sympa requires an RDBMS to work properly. It stores 
users' subscriptions and preferences in a database. \Sympa is also
able to extract user data from within an external database. 
These features require that you install database-related PERL libraries.
This includes the generic Database interface (DBI) and a Database Driver
for your RDBMS (DBD) :

\begin {itemize}
   \item \textbf {DBI} (DataBase Interface)

   \item \textbf {DBD} (DataBase Driver) related to your RDBMS (e.g.
       Msql-Mysql-modules for MySQL)

\end {itemize}

If you plan to interface \Sympa with an LDAP directory to build
dynamical mailing lists, you need to install PERL LDAP libraries :

\begin {itemize}
    \item \textbf {Net::LDAP} (perlldap).

\end {itemize}

\subsection {Create a UNIX user}

The final step prior to installing \Sympa: create a UNIX user (and
if possible a group) specific to the program. Most of the installation
will be carried out with this account. We suggest that you use the
name \texttt {sympa} for both user and group. Note that UID.GID must be
the same as your httpd. If you are running a dedicated httpd server,
this can be sympa.sympa, otherwise it is possible either to define a virtual httpd
server setting UID.GID, or to run \Sympa as nobody.nobody. 
This second solution is not advisable because the information managed by \Sympa
will be owned by nobody.

Numerous files will be located in the \Sympa user's login directory.
Throughout the remainder of this documentation we shall refer to this
login directory as \tildedir {sympa/}.

\section {Compilation and installation }

Before using \Sympa, you must customize the sources in order to
specify a small number of parameters specific to your installation.

First, extract the sources from the archive file, for example
from the \tildedir {sympa/} directory: the archive will create a
directory named \dir {sympa-\version/} where all the useful files
and directories will be located. In particular, you will have a
\dir {doc/} directory containing this documentation in various
formats; a \dir {sample/} directory containing a few examples of
configuration files; an \dir {nls/} directory where multi-lingual
messages are stored; and, of course, the \dir {src/} directory for the
mail robot and \dir {wwsympa} for the web interface.

Example:

\begin {quote}
\tt
\# su - \\
\$ gzip -dc sympa-\version.tar.gz | tar xf -
\end {quote}

\label {makefile}

Before running \unixcmd {make} in the main
directory, you should edit and configure \file {Makefile},
the first part of which requires customization.
We advise against changing anything located after the STOP
line.

The \file {Makefile} file contains explanations for the fields,
which you may have to change. They main ones are :
\begin {itemize}
\item USER and GROUP, the id of daemons.
\item CONFIG and WWSCONFIG, the location of robot and cgi configurations
\item DIR, the \Sympa home dir
\item MAILERPROGDIR, the location of queue and bouncequeue programs. If sendmail
is configured to use smrsh (check the mailer prog definition in your sendmail.cf),
queue and bouncequeue need to be installed in /etc/smrsh.  This is probably
the case if you are using redhat 6.X.
\item SENDMAIL\_ALIASES, the sendmail aliases file. This is used by the alias\_manager
script.
\item NEWALIASES, the path to newaliases command.
\item NEWALIASES\_ARG, arguments passed to newaliases command.
\item INITDIR, the directory to contain a SYSV init script (typically /etc.rc.d/init.d/)
\item DESTDIR, can be set in the main Makefile to install sympa in DESTDIR/DIR
(instead of DIR). This is useful for building RPM and DEB packages.
\item PERL, SH and CC and GENCAT, respectively perl, sh, cc and gencat locations. 
\item DARK\_COLOR, LIGHT\_COLOR, TEXT\_COLOR, BG\_COLOR, ERROR\_COLOR to define wwsympa
RGB colors
\end {itemize}

Once this file has been configured, you need to run the \texttt {make;make~install} commands.
This generates the binary for the \file {queue} program along with the nls, and inserts
the \Sympa and \WWSympa programs in their final slot, while having propagated
a few parameters into the PERL files, such the access path
to the PERL program. The make command includes the checking of CPAN modules.
 
If everything goes smoothly, the \tildedir {sympa/bin/} directory
will contain various PERL programs as well as the \file {queue}
binary.  You will remark that this binary has the \index{set-uid-on-exec
bit} \textit {set-uid-on-exec} bit (owner is the \texttt {sympa}
user): this is deliberate, and indispensable if \Sympa is to run correctly.

\subsection {Choosing directory locations}

All directories are defined in the \file {/etc/sympa.conf} file, which
is read by \Sympa at runtime. If no \file {sympa.conf} file
was found during installation, a sample one will be created.
For the default organization of directories, please refer to \ref {organization}, 
page~\pageref {organization}.

It would, of course, be possible to disperse files and directories to a number of different
locations. However, we recommend storing all the directories and files in  the \texttt {sympa}
user's login directory.

These directories must be created manually now. You can use restrictive
authorizations if you like, since only programs running with the
\texttt {sympa} account will need to access them.


\section {Robot aliases}
    \index{aliases}
    \index{mail aliases}

An electronic list manager such as \Sympa is built around two processing steps:

\begin {itemize}
    \item a message sent to a list or to \Sympa itself
        (for subscribe, unsubscribe, help messages, etc.) is received
        by the SMTP server (\unixcmd {sendmail} or \unixcmd {qmail}).
        The SMTP server, on reception of this message, runs the
        \file {queue} program (supplied in this package) to store
        the message in a queue, i.e. in a special directory.

    \item the \file {sympa.pl} daemon, set in motion at
        system startup, scans the queue. As soon as it
        detects a new message, it processes it and performs the
        requested action (distribution or processing of an
        administrative request).

\end {itemize}

To separate the processing of administrative requests (subscription,
unsubscription, help requests, etc.) from the processing of messages destined for mailing
lists, a special mail alias is reserved for administrative requests, so
that \Sympa can be permanently accessible to users. The following
lines must therefore be added to the \unixcmd {sendmail} alias file
(often \file {/etc/aliases}):

\begin {quote}
\begin{verbatim}
sympa:             "| /home/sympa/bin/queue sympa"
listmaster: 	   "| /home/sympa/bin/queue listmaster"
bounce+*:          "| /home/sympa/bin/bouncequeue sympa"
sympa-request:     postmaster
sympa-owner:       postmaster
\end{verbatim}
\end {quote}

\mailaddr {sympa-request} should be the address of the robot
\textindex {administrator}, i.e. a person who looks after
\Sympa (here \mailaddr {postmaster{\at}cru.fr}).

\mailaddr {sympa-owner} is the return address for \Sympa error
messages.

The alias bounce+* is dedicated to collect bounces. It is useful
only if at least one list uses \texttt { welcome\_return\_path unique } or
\texttt { remind\_return\_path unique}.
Don't forget to run \unixcmd {newaliases} after any change to
the \file {/etc/aliases} file!

Note: aliases based on \mailaddr {listserv} (in addition to those
based on \mailaddr {sympa}) can be added for the benefit of users
accustomed to the \mailaddr {listserv} and \mailaddr {majordomo} names.
For example:

\begin {quote}
\begin{verbatim}
listserv:          sympa
listserv-request:  sympa-request
majordomo:         sympa
listserv-owner:    sympa-owner
\end{verbatim}
\end {quote}

Note: it will also be necessary to add entries in this alias file
when lists are created (see list creation section, \ref {list-aliases},
page~\pageref {list-aliases}).


\section {Logs}

\Sympa keeps a trace of each of its procedures in its log file.
However, this requires configuration of the \unixcmd {syslogd}
daemon.  By default \Sympa wil use the \texttt {local1} facility
(\lparam {syslog} parameter in \file {sympa.conf}).
WWSympa's logging behaviour is defined by the \lparam {log\_facility}
parameter in \file {wwsympa.conf} (by default the same facility as \Sympa).\\
To this end, a line must be added in the \unixcmd {syslogd} configuration file (\file
{/etc/syslog.conf}). For example:

\begin {quote}
\begin{verbatim}
local1.*       /var/log/sympa 
\end{verbatim}
\end {quote}

Then reload \unixcmd {syslogd}.

Depending on your platform, your syslog daemon may use either
a UDP or a UNIX socket. \Sympa's default is to use a UNIX socket;
you may change this behavior by editing \file {sympa.conf}'s
\lparam {log\_socket\_type} parameter (\ref{par-log-socket-type},
page~\pageref{par-log-socket-type}).

\section {sympa.pl}
\label{sympa.pl}

Once the files are configured, all that remains is to start \Sympa.
At startup, \file {sympa.pl} will change its UID to sympa (as defined in \file {Makefile}).
To do this, add the following sequence or its equivalent in your
\file {/etc/rc.local}:

\begin {quote}
\begin{verbatim}

~sympa/bin/sympa.pl
~sympa/bin/archived.pl
~sympa/bin/bounced.pl

\end{verbatim}
\end {quote}

\file {sympa.pl} recognizes the following command line arguments:

\begin {itemize}

\item --debug | -d 
  
  Sets \Sympa in debug mode and keeps it attached to the terminal. 
  Debugging information is output to STDERR, along with standard log
  information. Each function call is traced. Useful while reporting
  a bug.
  
\item --config | -f \textit {config\_file}
  
  Forces \Sympa to use an alternative configuration file. Default behavior is
  to use the configuration file as defined in the Makefile (\$CONFIG).
  
\item --mail | -m 
  
  \Sympa will log calls to sendmail, including recipients. Useful for
  keeping track of each mail sent (log files may grow faster though).
  
\item --lang | -l \textit {catalog}
  
  Set this option to use a language catalog for \Sympa. 
  The corresponding catalog file must be located in \tildedir {sympa/nls}
  directory. 
  
  For example, with the \file {fr.cat} catalog:

\item --keepcopy | -k \textit {recipient\_directory}

  This option tells Sympa to keep a copy of every incoming message,
  instead of deleting them. \textit {recipient\_directory} is the directory
  to store messages.

  
  \begin {quote}
\begin{verbatim}
/home/sympa/bin/sympa.pl
\end{verbatim}
  \end {quote}

\item --dump \textit {listname | ALL}
  
  Dumps subscribers of a list or all lists. Subscribers are dumped
  in \file {subscribers.db.dump}.
 
\item --import \textit {listname}
  
Import subscribers in the \textit {listname} list. Data are read from STDIN.
  
\item --lowercase 
  
Lowercases e-mail addresses in database.

\item --help | -h
  
  Print usage of sympa.pl.
   

\item --version | -v
  
  Print current version of \Sympa.
 
  
\end {itemize}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sympa.conf params
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\cleardoublepage
\chapter {sympa.conf parameters}
    \label {exp-admin}
    \index{sympa.conf}
    \index{configuration file}

The \file {/etc/sympa.conf} configuration file contains numerous
parameters which are read on start-up of \Sympa. If you change this file, do not forget
that you will need to restart \Sympa afterwards. 

The \file {/etc/sympa.conf} file contains directives in the following
format:

\begin {quote}
    \textit {keyword    value}
\end{quote}

Comments start with the \texttt {\#} character at the beginning of
a line.  Empty lines are also considered as comments and are ignored.
There should only be one directive per line, but their order in
the file is of no importance.

\section {Site customization}

\subsection {\cfkeyword {domain}}

        This keyword is \textbf {mandatory}. It is the domain name
used in the \rfcheader {From} header in replies to administrative
requests. So the smtp engine (qmail, sendmail, postfix or whatever) must
recognize this domain as a local adress. This parameter name replace
the previous parameter name {\cfkeyword {host}} which can always
be used as a synonim. 


        \example {domain cru.fr}

\subsection {\cfkeyword {email}} 
	
	\default {sympa}

        Username (the part of the address preceding the \texttt {@} sign) used
        in the \rfcheader {From} header in replies to administrative requests.

        \example {email           listserv}

\subsection {\cfkeyword {listmaster}} 

        The list of e-mail addresses  of listmasters (users authorized to perform
        global  server commands). Listmaster can be defined for each virtual robot.

        \example {listmaster postmaster@cru.fr,root@cru.fr}

\subsection {\cfkeyword {WWSympa\_url}}  

	 \default {http://<host>/wws}

	This is the root URL of \WWSympa.

        \example {WWSympa\_url https://my.server/wws}

\subsection {\cfkeyword {dark\_color} \cfkeyword {light\_color} \cfkeyword {text\_color} \cfkeyword {bg\_color} \cfkeyword {error\_color} \cfkeyword {selected\_color} \cfkeyword {shaded\_color}}

	They are the color definition for web interface. Default are set in the main Makefile. Thoses parameters can be overwritten in each virtual robot definition.

\subsection {\cfkeyword {cookie}} 

	This string is used to generate MD5 authentication keys.
	It allows generated authentication keys to differ from one
	site to another. It is also used for reversible encryption of
        user passwords stored in the database. The presence of this string
	is one reason why access to \file {sympa.conf} needs to be restricted
	to the Sympa user. 
       
        Note that changing this parameter will break all
        http cookies stored in users' browsers, as well as all user passwords
	and lists X509 private keys.

        \example {cookie gh869jku5}

\subsection {\cfkeyword {create\_list}}  

	\label{create-list}

	 \default {listmaster}

	Defines who can create lists (or request list creations).
	Sympa will use the corresponding scenario.

        \example {create\_list intranet}

\section {Directories}

\subsection {\cfkeyword {home}}

	 \default {\tildedir {sympa/expl}}

        The directory whose subdirectories correspond to the different lists.

        \example {home          /home/sympa/expl}

\subsection {\cfkeyword {etc}}

	 \default {\tildedir {sympa/etc}}

        This is the local directory for configuration files (such as
	\file {edit\_list.conf}. It contains 3 subdirectories:
	\dir {scenari} for local scenarii; \dir {templates}
	for the site's local templates and default list templates; and \dir {wws\_templates}
        for the site's local html templates.

        \example {home          /home/sympa/etc}

\section {System related}

\subsection {\cfkeyword {syslog}} 

	\default {LOCAL1}

        Name of the sub-system (facility) for logging messages.

        \example {syslog          LOCAL2}

\subsection {\cfkeyword {log\_socket\_type}} 
    \label {par-log-socket-type}

	\default {inet}

        \Sympa communicates with \unixcmd {syslogd}
        using either UDP or UNIX sockets.  Set \cfkeyword
        {log\_socket\_type} to \texttt {inet} to use UDP, or \texttt
        {unix} for UNIX sockets.

\subsection {\cfkeyword {pidfile}} 

	\default {\tildefile {sympa/sympa.pid}}

        The file where the \file {sympa.pl} daemon stores its
        process number. Warning: the \texttt {sympa} user must be
        able to write to this file, and to create it if it doesn't
        exist.

        \example {pidfile         /var/run/sympa.pid}

\subsection {\cfkeyword {umask}} 

	\default {027}

        Default mask for file creation (see \unixcmd {umask}(2)).

        \example {umask 007}

\section {Sending related}

\subsection {\cfkeyword {maxsmtp}} 

	\default {20}

        Maximum number of SMTP delivery child processes spawned
        by  \Sympa. This is the main load control parameter.

        \example {maxsmtp           500}


\subsection {\cfkeyword {max\_size}} 

	\default {5 Mb}

	Maximum size allowed for messages distributed by \Sympa.
	This may be customized per virtual robot or per list by setting the \lparam {max\_size} 
	robot or list parameter.

        \example {max\_size           2097152}

\subsection {\cfkeyword {nrcpt}} 

	\default {25}

        Maximum number of recipients per \unixcmd {sendmail} call.
        This grouping factor makes it possible for the (\unixcmd
        {sendmail}) MTA to optimize the number of SMTP sessions for
        message distribution.

\subsection {\cfkeyword {avg}} 

	\default {10}

        Maximum number of different internet domains within addresses per
        \unixcmd {sendmail} call.

\subsection {\cfkeyword {sendmail}} 

	\default {/usr/sbin/sendmail}

        Absolute call path to SMTP message transfer agent (\unixcmd
        {sendmail} for example).

        \example {sendmail        /usr/sbin/sendmail}


\subsection {\cfkeyword {rfc2369\_header\_fields}} 

	\default {help,subscribe,unsubscribe,post,owner,archive}

	RFC2369 compliant header fields (List-xxx) to be added to 
	distributed messages. These header-fields should be implemented
	by MUA's, adding menus.

\subsection {\cfkeyword {remove\_headers}} 

        \default {Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To}

        This is the list of headers that \Sympa should remove from
        outgoing messages. Use it, for example, to ensure some privacy
        for your users by discarding anonymous options.
        It is (for the moment) site-wide. It is applied before the
        \Sympa, {rfc2369\_header\_fields}, and {custom\_header} fields are
        added.

\example {remove\_headers      Resent-Date,Resent-From,Resent-To,Resent-Message-Id,Sender,Delivered-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To}

\subsection {\cfkeyword {anonymous\_headers\_fields}} 

        \default {Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender}

	This parameter defines the list of SMTP header fields that should be
	removed when a mailing list is setup in anonymous mode (see 
	\ref {par-anonymous-sender},  page~\pageref {par-anonymous-sender}).

\section {Spool related}
\label {spool-related}

\subsection {\cfkeyword {spool}}

        \default {\tildedir {sympa/spool}}

	The parent directory which contains all the other spools.  
        

\subsection {\cfkeyword {queue}} 

        The absolute path of the directory which contains the queue, used both by the
        \file {queue} program and the \file {sympa.pl} daemon. This
        parameter is mandatory.

        \example {queue          /home/sympa/queue}


\subsection {\cfkeyword {queuemod}}  
        \label {cf:queuemod}
        \index{moderation}

	\default {\tildedir {sympa/spool/moderation}}

        This parameter is optional and retained solely for backward compatibility.


\subsection {\cfkeyword {queuedigest}}  
        \index{digest}
        \index{spool}

	\default {\tildedir  {digest}}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueexpire}}  

	\default {\tildedir {sympa/spool/expire}}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueauth}} 

	\default {\tildedir {sympa/spool/auth}}

        This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queueoutgoing}} 

	\default {\tildedir {sympa/spool/outgoing}}

	This parameter is optional and retained solely for backward compatibility.

\subsection {\cfkeyword {queuebounce}} 
    \index{bounce}

	\default {\tildedir {sympa/spool/bounce}}

        Spool to store bounces (non-delivery reports) received by the \file {bouncequeue}
	program via the \samplelist-owner or bounce+* addresses . This parameter is mandatory
        and must be an absolute path.


\subsection {\cfkeyword {tmpdir}}

        \default {\tildedir {sympa/spool/tmpdir}}

	Temporary directory used by OpenSSL and antiviruses.

\subsection {\cfkeyword {sleep}}  
        \label {kw-sleep}

	\default {5}

        Waiting period (in seconds) between each scan of the main queue.
        Never set this value to~0!

\subsection {\cfkeyword {clean\_delay\_queue}} 

	\default {1}

        Retention period (in days) for ``bad'' messages in
        \textindex {spool} (as specified by \cfkeyword {queue}).
        \Sympa keeps messages rejected for various reasons (badly
        formatted, looping, etc.) in
        this directory, with a name prefixed by \texttt {BAD}.
        This configuration variable controls the number of days
        these messages are kept.

        \example {clean\_delay\_queue 3}

\subsection {\cfkeyword {clean\_delay\_queuemod}} 

	\default {10}

        Expiration delay (in days) in the \textindex {moderation}
        \textindex {spool} (as specified by \cfkeyword {queuemod}).
        Beyond this deadline, messages that have not been processed
        are deleted.  For moderated lists, the contents of this spool
	can be consulted using a key along with the \mailcmd
        {MODINDEX} command.

\subsection {\cfkeyword {clean\_delay\_queueauth}}  

	\default {3}

        Expiration delay (in days) in the \textindex {authentication}
        queue.  Beyond this deadline, messages not enabled are
        deleted.

\section {Internationalization related}    

\subsection {\cfkeyword {msgcat}}   

	\default{\tildedir {sympa/nls}}

        The location of multilingual (nls) catalog files. Must correspond to
	\tildefile {src/nls/Makefile}.

\subsection {\cfkeyword {lang}}   

	\default {us}

        This is the default language for \Sympa. The message
	catalog (.cat) located in the corresponding \cfkeyword {msgcat} directory
	will be used.

\section {Bounce related}

\subsection {\cfkeyword {bounce\_warn\_rate}}
        \label {kw-bounce-warn-rate}
         
        \default {30}

	Site default value for \lparam {bounce}.
	The list owner receives a warning whenever a message is distributed and
	the number of bounces exceeds this value.

\subsection {\cfkeyword {bounce\_halt\_rate}}
        \label {kw-bounce-halt-rate}
         
        \default {50}

	\texttt {FOR FUTURE USE}

	Site default value for \lparam {bounce}.
	Messages will cease to be distributed if the number of bounces exceeds this value.

\subsection {\cfkeyword {welcome\_return\_path}}
        \label {kw-welcome-return-path}
         
        \default {owner}

	If set to string \texttt {unique}, sympa will use a unique e-mail address in the
        return path, prefixed by \texttt {bounce+}, in order to remove the corresponding
	subscriber. Requires the \texttt {bounced} daemon, and plussed aliases (as in 
        sendmail 8.7 and later).

\subsection {\cfkeyword {remind\_return\_path}}
        \label {kw-remind-return-path}
         
        \default {owner}

        Like \cfkeyword {welcome\_return\_path}, but relates to the remind message.
	
\section {Priority related}

\subsection {\cfkeyword {sympa\_priority}}  
        \label {kw-sympa-priority}

	\default {1}

        Priority applied to \Sympa commands while running the spool.

        Available since release 2.3.1.

\subsection {\cfkeyword {request\_priority}}  
        \label {kw-request-priority}

	\default {0}

        Priority for processing of messages for \samplelist-request,
	i.e. for owners of the list.

        Available since release 2.3.3

\subsection {\cfkeyword {owner\_priority}}  
        \label {kw-owner-priority}

	\default {9}

        Priority for processing messages for \samplelist-owner in
	the spool. This address will receive non-delivery reports
	(bounces) and should have a low priority.

        Available since release 2.3.3


\subsection {\cfkeyword {default\_list\_priority}}  
        \label {kw-default-list-priority}

	\default {5}

        Default priority for messages if not defined in the list
        configuration file.

        Available since release 2.3.1.

\section {Database related}

The following parameters are needed when using an RDBMS, but otherwise are not
required:

\subsection {\cfkeyword {db\_type}}

        Database management system used (e.g. MySQL, Pg, Oracle)
	
	This corresponds to the PERL DataBase Driver (DBD) name and
	is therefore case-sensitive.

\subsection {\cfkeyword {db\_name}} 

	\default {sympa}

        Name of the database containing user information. See
        detailed notes on database structure, \ref{rdbms-struct},
        page~\pageref{rdbms-struct}.

\subsection {\cfkeyword {db\_host}}

        Database host name.

\subsection {\cfkeyword {db\_user}}

        User with read access to the database.

\subsection {\cfkeyword {db\_passwd}}

        Password for \cfkeyword {db\_user}.

\subsection {\cfkeyword {db\_options}}

	If these options are defined, they will be appended to the
	database connect string.

Example for MySQL:
\begin {quote}
\begin{verbatim}
db_options	mysql_read_default_file=/home/joe/my.cnf
\end{verbatim}
\end {quote}
   
\subsection {\cfkeyword {db\_additional\_subscriber\_fields}}
\label{db-additional-subscriber-fields}

	If your \textbf {subscriber\_table} database table has more fields
	than required by \Sympa (because other softwares work this set of
	data), you can make \Sympa load these fields. Therefore, you can
	use them from within mail/web templates (as [subscriber-$>$field]).

	This parameter is a comma-separated list.

Example :
\begin {quote}
\begin{verbatim}
db_additional_subscriber_fields 	billing_delay,subscription_expiration
\end{verbatim}
\end {quote}
 
\subsection {\cfkeyword {db\_additional\_user\_fields}}

\label{db-additional-user-fields}

	If your \textbf {user\_table} database table has more fields
	than required by \Sympa (because other softwares work this set of
	data), you can make \Sympa load these fields. Therefore, you can
	use them from within mail/web templates (as [user-$>$field]).

	This parameter is a comma-separated list.

Example :
\begin {quote}
\begin{verbatim}
db_additional_user_fields 	address,gender
\end{verbatim}
\end {quote}


\section {Loop prevention}

   The following define your loop prevention policy for commands.
(see~\ref {loop-detection}, page~\pageref {loop-detection})

\subsection {\cfkeyword {loop\_command\_max}}

	\default {200}

	The maximum number of command reports sent to an e-mail
	address. When it is reached, messages are stored with the BAD
	prefix, and reports are no longer sent.

\subsection {\cfkeyword {loop\_command\_sampling\_delay}} 

	\default {3600}

	This parameter defines the delay in seconds before decrementing
	the counter of reports sent to an e-mail address.

\subsection {\cfkeyword {loop\_command\_decrease\_factor}} 

	\default {0.5}

	The decrementation factor (\texttt {from 0 to 1}), used to
	determine the new report counter after expiration of the delay.

\section {S/MIME configuration}

\Sympa can optionally verify and use S/MIME signatures for security purposes.
In this case, three optional parameters must be assigned by the listmaster
(see \ref {smimeconf},  page~\pageref {smimeconf}).

\subsection {\cfkeyword {openSSL}}

The path for the openSSL binary file.
         
\subsection {\cfkeyword {trusted\_ca\_options}} 
The option used by OpenSSL
        for trusted CA certificates. Required if cfkeyword {openSSL} is defined.
	
\subsection {\cfkeyword {key\_passwd}} 

The password for list private key encryption. If not
	defined, \Sympa assumes that list private keys are not encrypted.


\section {Antivirus plug-in}
\label {Antivirus plug-in}

\Sympa can optionally check incoming messages before delivering them, using an external antivirus solution.
You must then set two parameters.

\subsection {\cfkeyword {antivirus\_path}}

The path to your favorite antivirus binary file (including the binary file).

Example :
\begin {quote}
\begin{verbatim}
antivirus_path		/usr/local/bin/uvscan
\end{verbatim}
\end {quote}
   
\subsection {\cfkeyword {antivirus\_args}} 

The arguments used by the antivirus software to look for viruses.
You must set them so as to get the virus name.
You should use, if available, the 'unzip' option and check all extensions.

Example with uvscan :
\begin {quote}
\begin{verbatim}
antivirus_args		--summary --secure
\end{verbatim}
\end {quote}

Example with fsav :
\begin {quote}
\begin{verbatim}
antivirus_args		--dumb	--archive
\end{verbatim}
\end {quote}
	       	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WWSympa
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {WWSympa}


WWSympa is \Sympa's web interface.

\section {Organization}
\label {WWSympa}

\WWSympa is fully integrated with \Sympa. It uses \file {sympa.conf}
and \Sympa's libraries. The default \Sympa installation will also
install WWSympa.

Every single piece of HTML in \WWSympa is generated by the CGI code
using template files (See \ref {tpl-format}, page~\pageref {tpl-format}).
This facilitates internationalization of pages, as well as per-site
customization. 

The code consists of one single PERL CGI script, \file {WWSympa.fcgi}.
To enhance performance you can configure \WWSympa to use
FastCGI ; the CGI will be persistent in memory.\\
All data will be accessed through the CGI, including web archives.
This is required to allow the authentication scheme to be applied
systematically.

Authentication is based on passwords stored in the database table
user\_table ; if the the appropriate \file {Crypt::CipherSaber} is
installed, password are encrypted in the database using reversible
encryption based on RC4. Otherwise they are stored in clear text.
In both cases reminding of passwords is possible.
 To keep track of authentication information \WWSympa
uses HTTP cookies stored on the client side. The HTTP cookie only 
indicates that a specified e-mail address has been authenticated ;
permissions are evaluated when an action is requested.

The same web interface is used by the listmaster, list owners, subscribers and
others. Depending on permissions, the same URL may generate a different view.

\WWSympa's main loop algorithm is roughly the following : 
\begin {enumerate}
	\item Check authentication information returned by 
	the HTTP cookie

	\item Evaluate user's permissions for the
        requested action 

	\item Process the requested action 

	\item Set up variables resulting from the action 

	\item Parse the HTML template files
\end {enumerate}

\section {Installation}

%\begin {htmlonly}
%<A NAME='installwwsympa'>
%\end {htmlonly}


\begin{enumerate}

\item Edit \Sympa's main Makefile to customize destination dir, conf location,...

\item Install \Sympa

\item cutomize your \file {/etc/wwsympa.conf}

\item set \file {sympa.conf} parameter \cfkeyword {wwsympa\_url}
	to the base URL of your \WWSympa

\end{enumerate} 

\section {wwsympa.conf parameters}

	\subsection {alias\_manager}
	\label {alias-manager}	

	If this parameter is undefined, then you will have to manage your
	aliases manually.
	Provide the path to a script that will install aliases for a new list
	and delete aliases for closed lists. You can use the \tildefile {sympa/bin/alias\_manager.pl}
	script distributed with \Sympa. The script will receive the following arguments :
	\begin{enumerate}
		\item add | del
		\item <list name>
		\item <list domain>
	\end{enumerate}
	Example : \tildefile {sympa/bin/alias\_manager.pl} add \samplelist cru.fr

	\tildefile {sympa/bin/alias\_manager.pl} works on the alias file as defined
	by the SENDMAIL\_ALIASES variable in the main Makefile (see \ref {makefile},  
	page~\pageref {makefile}). It runs a \unixcmd{newaliases} command (via
	\file {aliaswrapper}), after any changes to aliases file.

	\subsection {arc\_path}

	\default {/home/httpd/html/arc} \\
	Where to store html archives. This parameter is used
        by the \file {archived.pl} daemon. It is a good idea to install the archive
        outside the web hierarchy to prevent possible back doors in the access control
        powered by WWSympa. However, if Apache is configured with a chroot, you may
	have to install the archive in the Apache directory tree.

	\subsection {archive\_default\_index thrd | mail}

	\default {thrd} \\
	The default index organization when entering web archives : either threaded or	
	chronological order.

	\subsection {archived\_pidfile}
	\default {archived.pid} \\
	The file containing the PID of \file {archived.pl}.

	\subsection {bounce\_path}
	\default {/var/bounce} \\
	Root directory for storing bounces (non-delivery reports). This parameter
	is used principally by the \file {bounced.pl} daemon.

	\subsection {bounced\_pidfile}
	\default {bounced.pid} \\
	The file containing the PID of \file {bounced.pl}.

	\subsection {cookie\_expire}
	\default {0}
	Lifetime (in minutes) of HTTP cookies. This is the default value
	when not set explicitly by users.
	
	\subsection {cookie\_domain}
	\default {localhost} \\
	Domain for the HTTP cookies. If beginning with a dot ('.'),
	the cookie is available within the specified internet domain.
	Otherwise, for the specified host. Example : 
		\begin {quote}
		\begin{verbatim}
		   cookie_domain cru.fr
		   cookie is available for host 'cru.fr'

		   cookie_domain .cru.fr
		   cookie is available for any host within 'cru.fr' domain
		\end{verbatim}
		\end {quote}
	The only reason for replacing the default value would be where
	\WWSympa's authentication process is shared with an application
	running on another host.
	
	\subsection {default\_home}
	\default {home} \\
        Organization of the WWSympa home page. If you have only a few lists,
	the default value `home' (presenting a list of lists organized by topic)
	should be replaced by `lists' (a simple alphabetical list of lists).

	\subsection {icons\_url}
	\default {/icons} \\
	URL of WWSympa's icons directory.

      	\subsection {log\_facility}

	WWSympa will log using this facility. Defaults to \Sympa's syslog
        facility.
	Configure your syslog according to this parameter.

	\subsection {mhonarc}
	\default {/usr/bin/mhonarc} \\
	Path to the (superb) MhOnArc program. Required for html archives
	http://www.oac.uci.edu/indiv/ehood/mhonarc.html

	\subsection {title}
	\default {Mailing List Service} \\
	The name of your mailing list service. It will appear in
	the Title section of WWSympa.

	\subsection {use\_fast\_cgi   0 | 1}
	\label{use-fastcgi}
	\default {1} \\
	Choice of whether or not to use FastCGI. On listes.cru.fr, using FastCGI 
        increases WWSympa performance by as much as a factor of 10. Refer to 
       	\htmladdnormallink {http://www.fastcgi.com/} {http://www.fastcgi.com/}
	and the Apache config section of this document for details about 
	FastCGI.


\section {MhOnArc}
 
MhOnArc is a neat little converter from mime messages to html. Refer to
\htmladdnormallink {http://www.oac.uci.edu/indiv/ehood/mhonarc.html}
{http://www.oac.uci.edu/indiv/ehood/mhonarc.html}.

The long mhonarc resource file is used by \WWSympa in a particular way,
as mhonarc is used to produce not a complete html document, but only part
(to be included in a complete document starting with <HTML> and terminating
with </HTML> ;-) )
The best way to start is to use the MhOnArc resource file as
provided in the \WWSympa distribution. 

The mhonarc resource file is named \file {mhonarc-ressources}. 
You may locate this file either in \begin{enumerate}
 	\item \tildedir {sympa/expl/\samplelist/mhonarc-ressources}
	in order to create a specific archive look for a particular list

	\item or \tildedir {sympa/bin/mhonarc-ressources}

\end{enumerate}

\section {Archiving daemon}

\file {archived.pl} converts messages from \Sympa's spools 
and calls \file {mhonarc} to create html versions (whose location is defined by the 
"arc\_path" WWSympa parameter). You should probably install these archives 
outside the \Sympa home\_dir (\Sympa's initial choice for storing mail archives : 
\tildedir {sympa/expl/\samplelist}). Note that the html archive 
contains a text version of each message and is totally separate from \Sympa's
main archive.

\begin{enumerate}

\item create a directory according to the WWSympa "arc\_path" parameter
    (must be owned by sympa, does not have to be in Apache space unless
    your server uses chroot)

\item for each list, if you need a web archive, create a new web archive paragraph
    in the list configuration. Example :
\begin {quote}
\begin{verbatim}
     web_archive
     access public|private|owner|listmaster|closed
\end{verbatim}
\end {quote}

     If web\_archive is defined for a list, every message distributed by this list is copied
     to \tildedir {sympa/spool/outgoing/}. (No need to create nonexistent subscribers to receive
     copies of messages)

\item start \file {archived.pl}.
\Sympa and Apache
 
\item check \WWSympa logs, or alternatively, start \file {archived.pl} in debug mode (-d). 

\item If you change mhonarc resources and wish to rebuild the entire archive 
using the new look defined for mhonarc, simply create an empty file named
".rebuild.\samplelist@myhost" in \tildedir {sympa/spool/outgoing}, and make sure that
the owner of this file is \Sympa. 

\begin {quote}
\begin{verbatim}
     example : su sympa -c "touch ~sympa/spool/outgoing/.rebuild.sympa-fr@cru.fr"
\end{verbatim}
\end {quote}
You can also rebuild web archives from within the admin page of the list.

\end{enumerate}
 
\section {HTTPD setup}

\subsection {wwsympa.fcgi access permissions}
 
      
     Because Sympa and WWSympa share a lot of files, \file {wwsympa.fcgi},
     must run with the same 
     uid/gid as \file {archived.pl}, \file {bounced.pl} and \file {sympa.pl}.
     There are different ways to organize this :
\begin{itemize}
\item With some operating systems no special setup is required because
      wwsympa.fcgi is installed with suid and sgid bits, but this will not work
      if suid scripts are refused by your system.

\item Run a dedicated Apache server with sympa.sympa as uid.gid (The Apache default
      is nobody.nobody)

\item Use a virtual Apache server with sympa.sympa as uid.gid ; Apache
      needs to be compiled with suexec.

\item Otherwise, you can overcome restrictions on the execution of suid scripts
      by using a short C program, owned by sympa and with the suid bit set, to start
      \file {wwsympa.fcgi}. Here is an example (with no guarantee attached) :
\begin {quote}
\begin{verbatim}

#include <unistd.h>

#define WWSYMPA "/home/sympa/bin/wwsympa.fcgi"

int main(int argn, char **argv, char **envp) {
  execve(WWSYMPA,argv,envp);
}

\end{verbatim}
\end{quote}
\end{itemize}

\subsection {Installing wwsympa.fcgi in your Apache server}
     If you chose to run \file {wwsympa.fcgi} as a simple CGI, you simply need to
     script alias it. 

\begin {quote}
\begin{verbatim}
     Example :
       	ScriptAlias /wws /home/sympa/bin/wwsympa.fcgi
\end{verbatim}
\end{quote}

     Running  FastCGI will provide much faster responses from your server and 
     reduce load (to understand why, read 
     \htmladdnormallink 
     {http://www.fastcgi.com/fcgi-devkit-2.1/doc/fcgi-perf.htm}
     {http://www.fastcgi.com/fcgi-devkit-2.1/doc/fcgi-perf.htm})
     
\begin {quote}
\begin{verbatim}
     Example :
	FastCgiServer /home/sympa/bin/wwsympa.fcgi -processes 2
	<Location /wws>
   	  SetHandler fastcgi-script
	</Location>

	ScriptAlias /wws /home/sympa/bin/wwsympa.fcgi

 \end{verbatim}
\end{quote}
 
\subsection {Using FastCGI}

\htmladdnormallink {FastCGI} {http://www.fastcgi.com/} is an extention to CGI that provides persistency for CGI programs. It is extemely usefull
with \WWSympa because it all the intialisations are only performed once, at server startup ; then
file {wwsympa.fcgi} instances are awaiting clients requests. 

\WWSympa can also work without FastCGI, depending on \textbf {use\_fast\_cgi} parameter 
(see \ref {use-fastcgi}, page~\pageref {use-fastcgi}).

To run \WWSympa with FastCGI, you need to install :
\begin{itemize}

\item mod\_fastcgi : the Apache module that provides FastCGI features

\item FCGI : the Perl module used by \WWSympa

\end{itemize}

\section {Database configuration}

\WWSympa needs an RDBMS (Relational Database Management System) in order to
run. All database access is performed via the \Sympa API. \Sympa
currently interfaces with \htmladdnormallink {MySQL}
{http://www.mysql.net/}, \htmladdnormallink {PostgreSQL}
{http://www.postgresql.pyrenet.fr/}, \htmladdnormallink {Oracle}
{http://www.oracle.com/database/} and \htmladdnormallink {Sybase}
{http://www.sybase.com/index_sybase.html}.

A database is needed to store user passwords and preferences.
The database structure is documented in the \Sympa documentation ;
scripts for creating it are also provided with the \Sympa distribution
(in \dir {script}). 

User information (password and preferences) are stored in the �User� table.
User passwords stored in the database are encrypted using reversible
RC4 encryption controlled with the \cfkeyword {cookie} parameter,
since \WWSympa might need to remind users of their passwords. 
The security of \WWSympa rests on the security of your database. 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa with an RDBMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Using \Sympa with a relational database}
\label {sec-rdbms}

It is possible for \Sympa to store its user information using a
relational database. Currently you can use one of the following
RDBMS : MySQL, PostgreSQL, Oracle, Sybase. Interfacing with other RDBMS
requires only a few changes in the code, since the API used, 
\htmladdnormallinkfoot {DBI} {http://www.symbolstone.org/technology/perl/DBI/} 
(DataBase Interface), has DBD (DataBase Drivers) for many RDBMS.

\section {Prerequisites}

You need to have a DataBase System installed (not necessarily 
on the same host as \Sympa), and the client libraries for that
Database installed on the \Sympa host ; provided, of course, that
a PERL DBD (DataBase Driver) is available for your chosen RDBMS!
Check the \htmladdnormallinkfoot
{DBI Module Availability} {http://www.symbolstone.org/technology/perl/DBI/}.

\section {Installing PERL modules}

\Sympa will use DBI to communicate with the database system and
therefore requires the DBD for your database system. DBI and 
DBD::YourDB (Msql-Mysql-modules for MySQL) are distributed as 
CPAN modules. Refer to ~\ref 
{Install other required CPAN modules}, page~\pageref 
{Install other required CPAN modules} for installation
details of these modules.

\section {Creating a sympa DataBase}

\subsection {Database structure}

The sympa database structure is slightly different from the
structure of a \file {subscribers} file. A \file {subscribers}
file is a text file based on paragraphs (similar to 
the \file {config} file) ; each paragraph completely describes 
a subscriber. If somebody is subscribed to two lists, he/she 
will appear in both subscribers files.

The DataBase distinguishes information relative to a person (e-mail,
real name, password) and his/her subscription options (list
concerned, date of subscription, reception option, visibility 
option). This results in a separation of the data into two tables :
the user\_table and the subscriber\_table, linked by a user/subscriber e-mail.

\subsection {Database creation}

The \file {create\_db} script below will create the sympa database for 
you. You can find it in the \dir {script/} directory of the 
distribution (currently scripts are available for MySQL, PostgreSQL, Oracle and Sybase).

\begin{itemize}

  \item MySQL database creation script\\
	\begin {quote}
	\begin{verbatim}
	[STARTPARSE]
	[INCLUDE '../src/etc/script/create_db.mysql']
	[STOPPARSE]
	\end{verbatim}
	\end {quote}

  \item PostgreSQL database creation script\\
	\begin {quote}
	\begin{verbatim}
	[STARTPARSE]
	[INCLUDE '../src/etc/script/create_db.Pg']
	[STOPPARSE]
	\end{verbatim}
	\end {quote}

  \item Sybase database creation script\\
	\begin {quote}
	\begin{verbatim}
	[STARTPARSE]
	[INCLUDE '../src/etc/script/create_db.Sybase']
	[STOPPARSE]
	\end{verbatim}
	\end {quote}

  \item Oracle database creation script\\
	\begin {quote}
	\begin{verbatim}
	[STARTPARSE]
	[INCLUDE '../src/etc/script/create_db.Oracle']
	[STOPPARSE]
	\end{verbatim}
	\end {quote}

\end{itemize}

You can execute the script using a simple SQL shell such as
mysql or psql.

Example:

\begin {quote}
\begin{verbatim}
# mysql  < create_db.mysql
\end{verbatim}  
\end {quote}

\section {Importing subscribers data}

\subsection {Importing data from a text file}

You can import subscribers data into the database from a text file having
one entry per line : the first field is an e-mail address, the second (optional) 
field is the free form name.  Fields are spaces-separated.

Example:
\begin {quote}
\begin{verbatim}
## Data to be imported
## email        gecos
john.steward@some.company.com           John - accountant
mary.blacksmith@another.company.com     Mary - secretary
\end{verbatim}  
\end {quote}

To import data into the database :

\begin {quote}
\begin{verbatim}
cat /tmp/my_import_file | sympa.pl --import=my_list
\end{verbatim}  
\end {quote}

(see \ref {sympa.pl}, page~\pageref {sympa.pl}).


\subsection {Importing data from subscribers files}

If a mailing list was previously setup to store subscribers into 
\file {subscribers} file (the default mode in versions older then 2.2b) 
you can load subscribers data into the sympa database. The simple way
is to edit the list configuration using \WWSympa (this requires listmaster 
privileges) and change the data source from \textbf {file} to \textbf {database}
; subscribers data will be loaded into the database at the same time.
 
If the subscribers file is too big, a timeout may occur with the FastCGI
(You can set longer timeout with \texttt {-idle-timeout} option of
\texttt {FastCgiServer} Apache configuration directive). Then you should
use \file {load\_subscribers.pl} script.


\section {Extending database table format}

You can easily add other fields to \textbf {subscriber\_table} and
\textbf {user\_table}, they will not disturb \Sympa because it makes
clear what field itexpects in SELECT queries.

Moreover you can access these database fields from within \Sympa
(in templates), as far as you list these additional fields in
\file {sympa.conf} (See \ref {db-additional-subscriber-fields}, page~\pageref {db-additional-subscriber-fields}
and \ref {db-additional-user-fields}, page~\pageref {db-additional-user-fields}).


\section {\Sympa configuration}

To store subscriber information in your newly created
database, you first need to tell \Sympa what kind of
database to work with, then you must configure
your list to access the database.

You define the database source in \file {sympa.conf} :
\cfkeyword {db\_type}, \cfkeyword {db\_name}, 
\cfkeyword {db\_host}, \cfkeyword {db\_user}, 
\cfkeyword {db\_passwd}.

If you are interfacing \Sympa with an Oracle database, 
\cfkeyword {db\_name} is the SID.

All your lists are now configured to use the database,
unless you set list parameter \lparam {user\_data\_source} 
to \textbf {file} or \textbf {include}. 

\Sympa will now extract and store user
information for this list using the database instead of the
\file {subscribers} file. Note however that subscriber information is 
dumped to \file {subscribers.db.dump} at every shutdown, 
to allow a manual rescue restart (by renaming subscribers.db.dump to
subscribers and changing the user\_data\_source parameter), if ever the
database were to become inaccessible.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa with LDAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Using \Sympa with LDAP}
\label {ldap}

LDAP is a client-server protocol for accessing a directory service. Sympa
provide various features based on access to one or more LDAP directories :

\begin{itemize}

	\item{authentication using LDAP directory insteed of sympa internal storage of password}\\

	\item{named filters used in scenario condition}\\ 
	
 	\item{dynamic evaluation of list subscribers set (see ~\ref {par-user-data-source})}\\         
	
\end{itemize}


\section {Authentication via uid or alternate email}

\Sympa stores the data relative to the subscribers in a DataBase. Among these data: password, email exploited during the Web authentication . The  module of LDAP authentication allows to use \Sympa in intranet without duplicating the user's passwords. 

Then, users can indiferently authenticate with their ldap\_uid, their alternate\_email or their canonic email stored in theldap directory (the most explicit user's email :for example  John.Carpenter@Host.com).

\Sympa gets the canonic email in the ldap directory with the ldap\_uid or the alternate\_email.  
\Sympa will first intend an anonymous bind to the directory to get the user's DN, and then \Sympa will bind with the DN and the user's ldap\_password in order to realise an efficient authentication. This last bind will work only if the good ldap\_password is provided. Indeed the value returned by the bind(DN,ldap\_password) is tested.


Example: a person is described by
\begin {quote}
\begin{verbatim}
                 Dn:cn=Fabrice Rafart,
                 ou=Siege ,
                 o=MaSociete ,
                 c=FR Objectclass:
                 person Cn: Fabrice Rafart
                 Title: Network Responsible
                 O: Siege
                 Or: Data processing
                 Telephonenumber: 01-00-00-00-00
                 Facsimiletelephonenumber:01-00-00-00-00
                 L:Paris
                 Country: France

		 uid: frafart
 		 mail: Fabrice.Rafart@MaSociete.fr
                 alternate_email: frafart@MaSociete.fr
                 alternate:rafart@MaSociete.fr
\end{verbatim}
\end {quote}

So Fabrice Rafart can be authenticated with: frafart, Fabrice.Rafart@MaSociete.fr, frafart@MaSociete.fr,Rafart@MaSociete.fr.
After this operation, the address in the field FROM will be the Canonic email, in this case  Fabrice.Rafart@MaSociete.fr. 
That means that \Sympa will get this email and use it during all the session until you clearly ask to \Sympa to change your email address via 2 pages : which and pref.
  


\subsection {auth.conf}

The \file {/etc/auth.conf} configuration file contains numerous
parameters which are read on start-up of \Sympa. If you change this file, do not forget
that you will need to restart \Sympa afterwards. 

The \file {/etc/auth.conf} is organised in paragraphs. Each paragraph coincides with the configuration of 
an ldap directory.

The \file {/etc/auth.conf} file contains directives in the following format:

\begin {quote}

 \textit {paragraphs}\\
    \textit {keyword    value}

 \textit {paragraphs}\\
    \textit {keyword    value} 

\end{quote}

Comments start with the \texttt {\#} character at the beginning of a line.
  
Empty lines are also considered as comments and are ignored at the beginning. After the first paragraph they are consideredas paragrahs separators.

There should only be one directive per line, but their order in the file is of no importance.

Thanks to this type of configuration \Sympa is able to consult various directories. So, users who come from different directories will be authenticated thanks to their ldap\_password. Indeed, \Sympa will try to bind on the first directory with the given ldap\_password, if it does not work,  \Sympa will try to bind on the second with the same ldap\_password etc.. This mecanism is useful in the case of homonyms.


Example :

\begin {quote}
\begin{verbatim}

#Configuration file auth.conf for the LDAP authentification
#Description of parameters for each directory



ldap
	host				ldap.univ-rennes1.fr:389
	timeout				30
	suffix				dc=univ-rennes1,dc=fr
	get_dn_by_uid_filter		(uid=[sender])
	get_dn_by_email			(|(mail=[sender])(mailalternateaddress=[sender]))
	email_attribute			mail
	alternative_email_attribute	mailalternateaddress,ur1mail
	scope				sub

ldap
	host				ldap.univ-nancy2.fr:392,ldap1.univ-nancy2.fr:392,ldap2.univ-nancy2.fr:392
	timeout				20		
	suffix				dc=univ-nancy2,dc=fr
	get_dn_by_uid_filter		(uid=[sender])
	get_dn_by_email			(|(mail=[sender])(n2atraliasmail=[sender]))
	alternative_email_attribute	n2atrmaildrop
	email_attribute			mail
	scope				sub
	
\end{verbatim}
\end {quote}

\begin{itemize}
\item{host}\\

        This keyword is \textbf {mandatory}. It is the domain name
	used in order to bind to the directory and then to extract informations.
	You must mention the port number after yhe server name.
	The replication is also taken in charge, then the different servers are comma separated.

        Example :
	\begin {quote}
	\begin{verbatim}

	host ldap.univ-rennes1.fr:389
	host ldap0.university.com:389,ldap1.university.com:389,ldap2.university.com:389

	\end{verbatim}
	\end {quote}
	

\item{timeout}\\ 
	
	It corresponds to the timelimit in the Search fonction. A timelimit that restricts the maximum 
	time (in seconds) allowed for a search. A value of 0, and the default, means that no timelimit
        will be requested.
 
\item{suffix}\\ 

	The root of the DIT (Directory Information Tree).The DN that is the base object entry relative 
	to which the search is to be performed. 

        \example {dc=university,dc=fr}

\item{get\_dn\_by\_uid\_filter}\\
	
	You define the search filter corresponding to the ldap\_uid. (RFC 2254 compliant).
	If you want to apply the filter on the user, mention him with the variable ' [sender] '. It would work with every
	type of authentication (uid, alternate\_email..). 
	  
	Example :
	\begin {quote}
	\begin{verbatim}

	(Login = [sender])
	(|(ID = [sender])(UID = [sender]))

	\end{verbatim}
	\end {quote}
	
\item{get\_dn\_by\_email\_filter}\\

	You define the search filter corresponding to the emails (canonic and alternative).(RFC 2254 compliant). 
	If you want to apply the filter on the user, mention him with the variable ' [sender] '. It would work with every
	type of authentication (uid, alternate\_email..). 

 		Example: a person is described by

\begin {quote}
\begin{verbatim}



                 Dn:cn=Fabrice Rafart,
                 ou=Siege ,
                 o=MaSociete ,
                 c=FR Objectclass:
                 person Cn: Fabrice Rafart
                 Title: Network Responsible
                 O: Siege
                 Or: Data processing
                 Telephonenumber: 01-00-00-00-00
                 Facsimiletelephonenumber:01-00-00-00-00
                 L:Paris
                 Country: France

		 uid: frafart
 		 mail: Fabrice.Rafart@MaSociete.fr
                 alternate_email: frafart@MaSociete.fr
                 alternate:rafart@MaSociete.fr
  

\end{verbatim}
\end {quote}

	The filters can be :

\begin {quote}
\begin{verbatim}
	
	(mail = [sender])
	(| (mail = [sender])(alternate_email = [sender]) )
	(| (mail = [sender])(alternate_email = [sender])(alternate  = [sender]) )


\end{verbatim}
\end {quote}

\item{email\_attribute}\\
	
	The name of the attribute for the canonic email in your directory : for instance mail, canonic\_email, canonic\_add	   res ...
	In the previous example the canonic email is 'mail'.

		 
\item{alternate\_email\_attribute}\\

	The name of the attribute for the alternate email in your directory : for instance alternate\_email, mailalternatea	   ddress, ...
	You make a list of these attributes separated by commas.

	With this list \Sympa creates a cookie which contains various informations : the user is authenticated via Ldap or 	   not, his alternate email. To store the alternate email is interesting when you want to canonify your preferences an	      d subscriptions. 
	That is to say  you want to use a unique adress in User\_table and Subscriber\_table which is the canonic email.

\item{scope}\\

	\default {sub}
	By default the search is performed on the whole tree below the specified base object. This may be changed by 
	specifying a scope :

\begin{itemize}

	\item{base}\\
	Search only the base object.

	\item{one}\\ 
	Search the entries immediately below the base object. 

 	\item{sub}\\         
	Search the whole tree below the base object. This is the default. 

\end{itemize}
\end{itemize}


\section {Named Filters}

At the moment Named Filters are only used in scenarii. They enable to select a category of people who will be authorized or not to realise some actions.
	
As a consequence, you can grant privileges in a list to people belonging to an LDAP directory thanks to a scenario.
	
\subsection {Definition}

	People are selected thanks to an Ldap filter defined in a configuration file. This file must have the extension '.ldap'.It is stored in \tildedir {sympa/etc/search\_filters/}.
	
	You must mention many informations in order to create a Named Filter:

\begin{itemize}

	\item{host}\\
	Name of the LDAP directory host.

	\item{port}\\
	port ldap\_directory\_port (Default 389)	

	\item{suffix}\\
	Defines the naming space covered by the search (optional, depending on the LDAP server).

	\item{filter}\\
	Defines the LDAP search filter (RFC 2254 compliant). 
	But you must absolutely take into account the first part of the filter which is:
	('mail\_attribute' = [sender]) as shown in the example. you will have to replce 'mail\_attribute' by the name 
	of the attribute for the email.
	So \Sympa verifies if the user belongs to the category of people defined in the filter. 
	
	\item{scope}\\
	By default the search is performed on the whole tree below the specified base object. This may be chaned by specify	   ing a scope :

	\begin{itemize}
		\item{base} : Search only the base object.
		\item{one}\\ 
		Search the entries immediately below the base object. 
 		\item{sub}\\         
		Search the whole tree below the base object. This is the default. 
	\end{itemize}
 

\end{itemize}


example.ldap : we want to select the professors of mathematics in the university of Rennes1 in France
\begin {quote}
\begin{verbatim}
	
	host		ldap.univ-rennes1.fr
	port		389
	suffix		dc=univ-rennes1.fr,dc=fr
	filter		(&(canonic_mail = [sender])(EmployeeType = prof)(subject = math))
	scope		sub

\end{verbatim}
\end {quote}


\subsection {Search Condition}
	
The search condition is used in scenarii which are defined and  decribed in (see~\ref {scenarii}) 

The syntax of this rule is:
\begin {quote}
\begin{verbatim}
	search(example.ldap,[sender])      smtp,smime,md5    -> do_it
\end{verbatim}
\end {quote}

The variables used by 'search' are :
\begin{itemize}
	\item{the name of the LDAP Configuration file}\\
	\item{the [sender]}\\
	That is to say the sender email. 
\end{itemize}
 
The method of authentication does not change.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMIME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


\cleardoublepage
\chapter {\Sympa with S/MIME and HTTPS}
    \label {smime}

S/MIME is a cryptographic method for Mime messages based on X509 certificates.
Before installing \Sympa S/Mime features (which we call S/Sympa), you should be
under no illusion about what the S stands for : ``S/MIME'' means ``Secure MIME''.
That S certainly does not stand for ``Simple''.

The aim of this chapter is simply to describe what security level is provided
by \Sympa while
using S/MIME messages, and how to configure \Sympa for it. It is not intended
to teach anyone what S/Mime is and why it is so complex ! RFCs numbers 2311,
2312, 2632, 2633 and 2634, along with a lot of literature about S/MIME, PKCS\#7
and PKI is available on the Internet. \Sympa 2.7 is the first version of
\Sympa to include S/MIME features as beta-testing features.

\section {Signed message distribution}

No action required.
You probably imagine that any mailing list manager (or any mail forwarder)
is compatible with S/MIME signatures, as long as it respects the MIME structure of
incoming messages. You are right. Even Majordomo can distribute a signed message!
As \Sympa provides MIME compatibility, you don't need to do
anything in order to allow subscribers to verify signed messages distributed
through a list. This is not an issue at all, since any processes that
distribute messages  are compatible with end user
signing processes. Sympa simply skips the message footer attachment
(ref \ref {messagefooter}, page~\pageref {messagefooter}) to prevent any
body corruption which would break the signature.

\section {Use of S/MIME signature by Sympa itself}

Sympa is able to verify S/MIME signatures in order to apply S/MIME
authentication methods for message handling. 
Currently, this feature is limited to the
distribution process, and to any commands \Sympa might find in the message
body.  The reasons for this restriction are related to current S/MIME
usage.
S/MIME signature structure is based on the encryption of a digest of the
message. Most S/MIME agents do not include any part of the
message headers in the message digest, so anyone can modify the message
header without signature corruption! This is easy to do : for example, anyone
can edit a signed message with their preferred message agent, modify whatever
header they want (for example \texttt {Subject:} , \texttt {Date:} and
\texttt {To:}, and redistribute the message to a list or to the robot
without breaking the signature.

So Sympa cannot apply the S/MIME
authentication method to a command parsed in the \texttt {Subject:} field of a
message or via the \texttt {-subscribe} or \texttt {-unsubscribe} e-mail
address. 

\section {Use of S/MIME encryption} 

S/Sympa is not an implementation of the ``S/MIME Symmetric Key Distribution''
internet draft. This sophisticated scheme is required for large lists
with encryption. So, there is still some scope for future developments :) 


We assume that S/Sympa distributes message as received, i.e. unencrypted when the
list receives an unencrypted message, but otherwise encrypted.

In order to be able to send encrypted messages to a list, the sender needs
to use the X509 certificate of the list. Sympa will send an encrypted message
to each subscriber using the subscriber's certificate. To provide this feature,
\Sympa needs to manage one certificate for each list and one for each
subscriber. This is available in Sympa version 2.8 and above.

\section {S/Sympa configuration} 

\subsection {Installation}
\label {smimeinstall}

The only requirement is OpenSSL (http://www.openssl.org) version 0.9.5a and above.
OpenSSL is used by \Sympa as an external plugin
(like sendmail or postfix), so it must be installed with the appropriate access
(x for sympa.sympa). 

\subsection {configuration in sympa.conf}
\label {smimeconf}

S/Sympa configuration is very simple. If you are used to Apache SSL,
you should not feel lost. If you are an OpenSSL guru, you will
feel at home, and there may even be changes you will wish to suggest to us.
 
The basic requirement is to let \Sympa know where to find the binary file for the OpenSSL program
and the certificates of the trusted certificate authority. 
This is done using the optional parameters \unixcmd {openSSL} and
\cfkeyword {trusted\_ca\_options}.
\begin{itemize}

  \item \cfkeyword {openSSL} : the path for the OpenSSL binary file,
         usually \texttt {/usr/local/ssl/bin/openSSL}
  \item \cfkeyword {trusted\_ca\_options} : the option used by OpenSSL
        for trusted CA certificates. 
        The file \cfkeyword {/home/sympa/bin/etc/ca-bundle.crt} is distributed
        with Sympa and describes a well known set of CA's, such as the default Netscape
        navigator configuration. You can declare this set of certificates as trusted
        by setting \texttt {trusted\_ca\_options -CAfile /home/sympa/bin/etc/ca-bundle.crt}.
        You can also use the \cfkeyword {-CApath} \unixcmd {openSSL} option, or both 
        \cfkeyword {-CApath} and \cfkeyword {-CAfile}. Example :       
        \texttt {trusted\_ca\_options -CApath /home/sympa/etc/ssl.crt -CAfile /home/sympa/bin/etc/ca-bundle.crt}.

	Both the \cfkeyword {-CAfile} file and the \cfkeyword {-CApath} directory
        should be shared with your Apache+mod\_ssl configuration. This is useful
	for the S/Sympa web interface.  Please refer to the OpenSSL documentation for details.
  \item \cfkeyword {key\_password} : the password used to protect all list private keys. xxxxxxx	
\end{itemize}


\subsection {configuration to recognize S/MIME signatures}
\label {smimeforsign}

Once  \texttt {OpenSSL} has been installed, and \texttt {sympa.conf} configured,
your S/Sympa is ready to use S/Mime signatures for any authentication operation. You simply need
to use the appropriate scenario for the operation you want to secure. 
(see \ref {scenarii}, page~\pageref {scenarii}).

When receiving a message, \Sympa applies
the scenario with the appropriate authentication method parameter.
In most cases the authentication method is ``\texttt {smtp}'', but in cases
where the message is signed and the signature has been checked and matches the
sender e-mail, \Sympa applies the ``\texttt {smime}'' authentication
method.

It is vital to ensure that if the scenario does not recognize this authentication method, the
operation requested will be rejected. Consequently, scenarii distributed
prior to version 2.7 are not compatible with the OpenSSL configuration of Sympa. 
All
standard scenarii (those distributed with sympa)
now include the \texttt {smime} method. The following example is
named \texttt {send.private\_smime}, and restricts sends to subscribers using an S/mime signature :

\begin {quote}
\begin{verbatim}
title.us restricted to subscribers check smime signature
title.fr limit� aux abonn�s, v�rif de la signature smime

is_subscriber([listname],[sender])             smime  -> do_it
is_editor([listname],[sender])                 smime  -> do_it
is_owner([listname],[sender])                  smime  -> do_it
\end{verbatim}
\end {quote}

It as also possible to mix various authentication methods in a single scenario. The following
example, \texttt {send.private\_key}, requires either an md5 return key or an S/Mime signature :
\begin {quote}
\begin{verbatim}
title.us restricted to subscribers with previous md5 authentication
title.fr r�serv� aux abonn�s avec authentification MD5 pr�alable

is_subscriber([listname],[sender]) smtp          -> request_auth
true()                             md5,smime     -> do_it
\end{verbatim}
\end {quote}

\subsection {distributing encrypted messages}
\label {smimeforencrypt}

In this section we describe S/Sympa encryption features. The goal is to use
S/MIME encryption for distribution of a message to subscribers whenever the message has been
received encrypted from the sender. 

Why is S/Sympa concerned by the S/MIME encryption distribution process ?
It is because encryption is performed using the \textbf {recipient} X509
certificate, whereas the signature requires the sender's private key. Thus, an encrypted
message can be read by the recipient only if he or she is the owner of the private
key associated with the certificate.
Consequently, the only way to encrypt a message for a list of recipients is
to encrypt and send the message for each recipient. This is what S/Sympa
does when distributing a encrypted message.

The S/Sympa encryption feature in the distribution process supposes that sympa
has received an encrypted message for some list. To be able to encrypt a message
for a list, the sender must have some access to an X509 certificate for the list.
So the first requirement is to install a certificate and a private key for
the list.
The mechanism whereby certificates are obtained and managed is complex. Current versions
of S/Sympa assume that list certificates and private keys are installed by
the listmaster.
It is a good idea to have a look at the OpenCA (http://www.openca.org)
documentation and/or PKI providers' web documentation.
You can use commercial certificates or home-made ones. Of course, the
certificate must be approved for e-mail applications, and issued by one of
the trusted CA's described in the \cfkeyword {-CAfile} file or the
\cfkeyword {-CApath} OpenSSL option. 


The list private key must be installed in a file named
\tildedir {sympa/expl/\samplelist/private\_key}. All the list private
keys must be encrypted using a single password defined by the
\cfkeyword {password} parameter in \cfkeyword {sympa.conf}.


\subsubsection {Use of Netscape navigator to obtain X509 list certificates}

In many cases e-mail X509 certificates are distributed via a web server and
loaded into the browser using your mouse :) Netscape allows
certificates to be exported to a file. So one way to get a list certificate is to obtain an e-mail
certificate for the canonical list address in your browser, and then to export and install it for Sympa :
\begin {enumerate}
\item browse the net and load a certificate for the list address on some
PKI provider (your own OpenCa pki server , thawte, verisign, ...). Be
careful :  the e-mail certificate must be correspond exactly to the canonical address of
your  list, otherwise, the signature will be incorrect (sender e-mail will
not match signer e-mail).
\item in the security menu, select the intended certificate and export
it. Netscape will prompt you for a password and a filename to encrypt
the output file. The format used by Netscape is  ``pkcs\#12''. 
Copy this file to the list home directory.
\item convert the pkcs\#12 file into a pair of pem files :
\cfkeyword {cert.pem} and \cfkeyword {private\_key} using
the \unixcmd {~sympa/bin/p12topem.pl} script. Use \unixcmd
{p12topem.pl -help} for details.
\item be sure that \cfkeyword {cert.pem} and \cfkeyword {private\_key}
are owned by sympa with ``r'' access.
\item As soon as a certificate is installed for a list, the list  home page
includes a new link to load the certificate to the user's browser, and the welcome
message is signed by the list.
\end {enumerate} 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Customization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Customizing \Sympa/\WWSympa}
    \label {customization}

\section {Template file format}
\label{tpl-format}
\index{templates format}

Template files within \Sympa and \WWSympa are text files containing 
programming elements (variables, conditions, loops, file inclusions)
that will be parsed in order to adapt to the runtime context. These 
templates are an extension of programs and therefore give access to 
a limited list of variables (those defined in the '\textit {hash}' 
parameter given to the parser). 

Review the Site template files (\ref {site-tpl}, page~\pageref {site-tpl}) 
and List template files (\ref {list-tpl}, page~\pageref {list-tpl}).

The following describes the syntactical elements of templates.

\subsection {Variables}

Variables are enclosed between brackets '\textit {[]}'. The variable name
is composed of alphanumerics (0-1a-zA-Z) or underscores (\_).
The syntax for accessing an element in a '\textit{hash}' is [hash-$>$elt].

\textit {Examples:} 
\begin {quote}
\begin{verbatim}
[url]
[is_owner]
[list->name]
[user->lang]
\end{verbatim}
\end {quote}

For each template you wish to customize, check the available variables in the
documentation.

\subsection {Conditions}

Conditions include variable comparisons (= and <>), or existence.
Syntactical elements for conditions are [IF xxx], [ELSE], [ELSIF xxx] and
[ENDIF].

\textit {Examples:} 
\begin {quote}
\begin{verbatim}
[IF  user->lang=fr]
Bienvenue dans la liste [list->name]
[ELSIF user->lang=es]
Bienvenida en la lista [list->name]
[ELSE]
Welcome in list [list->name]
[ENDIF]

[IF is_owner]
The following commands are available only 
for lists owners or moderators:
....
[ENDIF]
\end{verbatim}
\end {quote}

\subsection {Loops}

Loops make it possible to traverse a list of elements (internally represented by a 
'\textit{hash}' or an '\textit{array}'). 

\texttt{Example :}
\begin {quote}
\begin{verbatim}
A review of public lists

[FOREACH l IN lists]
   [l->NAME] 
   [l->subject]
[END]
\end{verbatim}
\end {quote}

\texttt {[elt-$>$NAME]} is a special element of the current entry providing 
the key in the '\textit{hash}' (in this example the name of the list). When traversing
an '\textit{array}', \texttt{[elt-$>$INDEX]} is the index of the current
entry.

\subsection {File inclusions}

You can include another file within a template . The specified file can be 
included as is, or itself parsed (there is no loop detection). The file 
path is either specified in the directive or accessed in a variable.

Inclusion of a text file :

\begin {quote}
\begin{verbatim}
[INCLUDE 'archives/last_message']
[INCLUDE file_path]
\end{verbatim}
\end {quote}

The first example includes a file whose relative path is \file {archives/last\_message}.
The second example includes a file whose path is in file\_path variable.

Inclusion and parsing of a template file :

\begin {quote}
\begin{verbatim}
[PARSE 'welcome.tpl']
[PARSE file_path]
\end{verbatim}
\end {quote}

The first example includes the template file \file {welcome.tpl}.
The second example includes a template file whose path is in file\_path variable.

\subsection {Stop parsing}

You may need to exclude certain lines in a template from the parsing
process. You can perform this by stopping and restarting the
parsing.

Escaping sensitive JavaScript functions :

\begin {quote}
\begin{verbatim}
<HEAD>
<SCRIPT LANGUAGE="JavaScript">
<!-- for other browsers
  function toggle_selection(myfield) {
    for (i = 0; i < myfield.length; i++) {
    [STOPPARSE]
       if (myfield[i].checked) {
            myfield[i].checked = false;
       }else {
	    myfield[i].checked = true;
       }
    [escaped_start]
    }
  }
// end browsers -->
</SCRIPT>
</HEAD>
\end{verbatim}
\end {quote}


\section {Site template files}
\label{site-tpl}
\index{templates, site}

These files are used by Sympa as service messages for the \mailcmd {HELP}, 
\mailcmd {LISTS} and \mailcmd {REMIND *} commands. These files are interpreted 
(parsed) by \Sympa and respect the template format ; every file has a .tpl extension. 
See \ref {tpl-format}, 
page~\pageref {tpl-format}. 

Sympa looks for these files in the following order (where $<$list$>$ is the
listname if defined, $<$action$>$ is the name of the command, and $<$lang$>$ is
the preferred language of the user) :
\begin {enumerate}
	\item \tildedir {sympa/expl/$<$list$>$/$<$action$>$.$<$lang$>$.tpl}. 
	\item \tildedir {sympa/expl/$<$list$>$/$<$action$>$.tpl}. 
	\item \tildedir {sympa/etc/templates/$<$action$>$.$<$lang$>$.tpl}. 
	\item \tildedir {sympa/etc/templates/$<$action$>$.tpl}. 
	\item \tildedir {sympa/bin/etc/templates/$<$action$>$.$<$lang$>$.tpl}.
	\item \tildedir {sympa/bin/etc/templates/$<$action$>$.tpl}.
\end {enumerate}

If the file starts with a From: line, it is considered as
a full message and will be sent (after parsing) without adding SMTP
headers. Otherwise the file is treated as a text/plain message body.

The following variables may be used in these template files :

\begin {itemize}

	\item[-] [conf-$>$email] : sympa e-mail address local part

	\item[-] [conf-$>$host] : sympa host name

	\item[-] [conf-$>$sympa] : sympa's complete e-mail address

	\item[-] [conf-$>$wwsympa\_url] : \WWSympa root URL

	\item[-] [conf-$>$listmaster] : listmaster e-mail addresses

	\item[-] [user-$>$email] : user e-mail address

	\item[-] [user-$>$gecos] : user gecos field (usually his/her name)

	\item[-] [user-$>$password] : user password

	\item[-] [user-$>$lang] : user language	

\end {itemize}

\subsection {helpfile.tpl} 


	This file is sent in response to a \mailcmd {HELP} command. 
	You may use additional variables
\begin {itemize}

	\item[-] [is\_owner] : TRUE if the user is list owner

	\item[-] [is\_editor] : TRUE if the user is list editor

\end {itemize}

\subsection {lists.tpl} 

	File returned by \mailcmd {LISTS} command. 
	An additional variable is available :
\begin {itemize}

	\item[-] [lists] : this is a hash table indexed by list names and
			containing lists' subjects. Only lists visible
			to this user (according to the \lparam {visibility} 
			list parameter) are listed.
\end {itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
These are the public lists for [conf->email]@[conf->host]

[FOREACH l IN lists]
	
 [l->NAME]: [l->subject]

[END]

\end{verbatim}
\end {quote}

\subsection {global\_remind.tpl} 

	This file is sent in response to a \mailcmd {REMIND *} command. 
	(see~\ref {cmd-remind}, page~\pageref {cmd-remind})
	You may use additional variables
\begin {itemize}

	\item[-] [lists] : this is an array containing the list names the user
			is subscribed to.
\end {itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}

This is a subscription reminder.

You are subscribed to the following lists :
[FOREACH l IN lists
	
 [l] : [conf->wwsympa\_url]/info/[l]

[END]

Your subscriber e-mail : [user->email]
Your password : [user->password]

\end{verbatim}
\end {quote}

\subsection {your\_infected\_msg.tpl} 

This message is sent to warn the sender of a virus infected mail,
indicating the name of the virus found 
(see~\ref {Antivirus}, page~\pageref {Antivirus}).

\section {Web template files}
\label{web-tpl}
\index{templates, web}

You may define your own web template files, different from the standard
ones. \WWSympa first looks for list specific web templates, then for
site web templates, before falling back on its defaults. 

Your list web template files should be placed in the \tildedir {sympa/expl/\samplelist/wws\_templates} 
directory ; your site web templates in \tildedir {sympa/expl/wws\_templates} directory.

Note that web colors are defined in \Sympa's main Makefile (see \ref {makefile},
page~\pageref {makefile}).


\section {Sharing data with other applications}

You may extract subscribers for a list from any of :
\begin{itemize}

\item a text file

\item a Relational database

\item a n LDAP directory

\end{itemize}

See lparam {user\_data\_source} liste parameter \ref {user-data-source}, page~\pageref {user-data-source}.

The \textbf {subscriber\_table} and \textbf {user\_table} can have more fields than
the one used by \Sympa. by defining these additional fields, they will be available
from within \Sympa's scenario and templates (see \ref {db-additional-subscriber-fields}, 
page~\pageref {db-additional-subscriber-fields} and \ref {db-additional-user-fields}, page~\pageref {db-additional-user-fields}).


\section {Sharing \WWSympa authentication with other applications}

You might want to make other web applications collaborate with \Sympa,
and share the same authentication system. \Sympa uses
HTTP cookies to carry users' auth information from page to page.
This cookie carries no information concerning privileges. To make your application
work with \Sympa, you have two possibilities :

\begin {itemize}

\item Delegating authentication operations to \WWSympa \\
If you want to avoid spending a lot of time programming a CGI to do Login, Logout
and Remindpassword, you can copy \WWSympa's login page to your 
application, and then make use of the cookie information within your application. 
The cookie format is :
\begin{verbatim}
user=<user_email>:<md5>
\end{verbatim}

where <user\_email> is the user's complete e-mail address, and
<md5> is a MD5 checksum of the <user\_email>+\Sympa \cfkeyword {cookie}
configuration parameter.
Your application needs to know what the \cfkeyword {cookie} parameter
is, so it can check the HTTP cookie validity ; this is a secret shared
between \WWSympa and your application.
\WWSympa's \textit {loginrequest} page can be called to return to the
referrer URL when an action is performed. Here is a sample HTML anchor :

\begin{verbatim}
<A HREF="/wws/loginrequest/referrer">Login page</A>
\end{verbatim}


\item Using \WWSympa's HTTP cookie format within your auth module \\
To cooperate with \WWSympa, you simply need to adopt its HTTP
cookie format and share the secret it uses to generate MD5 checksums,
i.e. the \cfkeyword {cookie} configuration parameter. In this way, \WWSympa
will accept users authenticated through your application without
further authentication.

\end {itemize}


\section {Internationalization}
\label {internationalization}
\index{internationalization}
\index{localization}

\Sympa was originally designed as a multilingual Mailing List
Manager. Even in its earliest versions, \Sympa separated messages from
the code itself, messages being stored in NLS catalogues (according 
to the XPG4 standard). Later a \lparam{lang} list parameter was introduced.
Nowadays \Sympa is able to keep track of individual users' language preferences.


\subsection {\Sympa internationalization}

Every message sent by \Sympa to users, owners and editors is outside
the code, in a message catalog. These catalogs are located in the
\tildedir{sympa/nls/} directory. Messages have currently been
translated into 10 different languages : 

\begin{itemize}

\item cn-big5: BIG5 Chinese (Honk Kong, Taiwan)

\item cn-gb: GB Chinese (Mainland China)

\item cz: Czech

\item de: German

\item es: Spanish

\item fi: Finnish

\item fr: French

\item hu: hungarian

\item it: Italian

\item pl: Polish

\item us: US English

\end{itemize}

To tell \Sympa to use a particular message catalog, you can either set 
the \cfkeyword{lang} parameter in \file{sympa.conf}, or
set the \file{sympa.pl} \texttt{-l} option on the command line.

\subsection {List internationalization}

The \lparam{lang} list parameter defines the language for a list.
It is currently used by \WWSympa and to initialize users'
language preferences at subscription time.

In future versions, all messages returned by \Sympa concerning
a list should be in the list's language. 

\subsection {User internationalization}

The user language preference is currently used by \WWSympa
only. There is no e-mail-based command for a user to set his/her
language. The language preference is initialized when the user
subscribes to his/her first list. \WWSympa allows the user to change 
it.

\section {Topics}
\label{topics}
\index{topics}

\WWSympa's homepage shows a list of topics for classifying
mailing lists. This is dynamically generated using the different lists'
\lparam {topics} configuration parameters. A list may appear 
in multiple categories.

The list of topics is defined in the \file {topics.conf} configuration
file, located in the \tildedir {sympa/etc} directory. The format of this file is 
as follows :
\begin{quote}
\begin{verbatim}
<topic1_name>
title	<topic1 title>
visibility <topic1 visibility>
....
<topicn_name/subtopic_name>
title	<topicn title>
\end{verbatim}
\end{quote}

You will notice that subtopics can be used, the separator being \textit {/}.
The topic name is composed of alphanumerics (0-1a-zA-Z) or underscores (\_).
The order in which the topics are listed is respected in \WWSympa's homepage.
The \textbf {visibility} line defines who can view the topic (now available for subtopics).
It refers to the associated topics\_visibility scenario.
You will find a sample \file {topics.conf} in the \dir {sample} 
directory ; NONE is installed as the default. 

A default topic is hard-coded in \Sympa : \textit {default}. This default topic
contains all lists for which a topic has not been specified.

\section {Scenarii}
    \label {scenarii}
    \index{scenario}

List parameters controlling the behavior of commands are linked to different scenarii.
For example : the \cfkeyword {send private} parameter is related to the send.private scenario.
There are three possible locations for a scenario. When \Sympa seeks to apply a scenario, it
looks first in the related list directory \tildedir {sympa/expl/$<$list$>$/scenari}. If it
does not find the file there, it scans \tildedir {sympa/etc/scenari},
and finally \tildedir {sympa/bin/etc/scenari}, which is the directory installed by the Makefile.

A scenario is a small configuration language to describe who
can perform an operation and which authentication method is requested for it.
A scenario is an ordered set of rules. The goal is to provide a simple and
flexible way to configure authorization and authentication for each operation.


Each scenario rule contains :
\begin{itemize}
\item a condition : the condition is evaluated by \Sympa. It can use
  variables such as $[$sender$]$ for the sender e-mail, $[$list$]$ for the listname etc.
\item an authentication method. The authentication method can be \cfkeyword {smtp},
\cfkeyword {md5} or \cfkeyword {smime}. The rule is applied by \Sympa if both condition
and authentication method match the runtime context. \cfkeyword {smtp} is used if
\Sympa use the SMTP \cfkeyword {from:} header , \cfkeyword {md5} is used if a unique
md5 key as been returned by the requestor to validate her message, \cfkeyword {smime}
is used for signed messages (see \ref {smimeforsign}, page~\pageref {smimeforsign}).
\item a returned atomic action that will be executed by \Sympa if the rule matches

\end{itemize}

 
Example

\begin{quote}
del.auth
\begin{verbatim}
title.us deletion performed only by list owners, need authentication
title.fr suppression r�serv�e au propri�taire avec authentification
title.es eliminaci�n reservada s�lo para el propietario, necesita autentificaci�n


  is_owner([listname],[sender])  smtp       -> request_auth
  is_listmaster([sender])        smtp       -> request_auth
  true()                         md5,smime  -> do_it
\end{verbatim}
\end{quote}

Scenarii can also contain includes :

\begin{quote}
\begin{verbatim}
    subscribe
        include commonreject
        match([sender], /cru\.fr$/)          smtp,smime -> do_it
	true()                               smtp,smime -> owner
\end{verbatim}
\end{quote}
	    

In this case sympa applies recursively the scenario named \texttt {include.commonreject}
before introducing the other rules. This possibility was introduced in
order to facilitate the administration of common rules.

A bunch of scenarii is provided with the \Sympa distribution ; they provide
all possible configurations as defined in previous releases of \Sympa
($<$= 2.3) without any change in your list configuration files. 

These standard scenarii are located in the \tildedir {sympa/bin/scenari/}
directory. Default scenarii are named <command>.default.

You may also define and name your own scenarii. Store them in the
\tildedir {sympa/etc/scenari} directory. 
Example:

Copy the previous scenario to \file {scenari/subscribe.rennes1} :

\begin {quote}
\begin{verbatim}
equal([sender], 'userxxx@univ-rennes1.fr') smtp,smime -> reject
match([sender], /univ-rennes1\.fr$/) smtp,smime -> do_it
true()                               smtp,smime -> owner
\end{verbatim}
\end{quote}

You may now refer to this scenario in any list configuration file, for example :

\begin {quote}
\begin{verbatim}
subscribe rennes1
\end{verbatim}
\end{quote}

A scenario consists of rules, evaluated in order beginning with the first. 
Rules are defined as follows :
\begin {quote}
\begin{verbatim}
<rule> ::= <condition> <auth_list> -> <action>

<condition> ::= [!] <condition
		| true ()
                | equal (<var>, <var>)
                | match (<var>, /perl_regexp/)
                | is_subscriber (<listname>, <var>)
                | is_owner (<listname>, <var>)
                | is_editor (<listname>, <var>)
                | is_listmaster (<var>)
<var> ::= [email] | [sender] | [subscriber-><subscriber_key_word>] | [list-><list_key_word>] | [conf-><conf_key_word>] | [msg_header-><smtp_key_word>] | [msg_body] | [msg_part->type] | [msg_part->body] | <string>

<listname> ::= [listname] | <listname_string>

<auth_list> ::= <auth>,<auth_list> | <auth>

<auth> ::= smtp|md5|smime

<action> ::=   do_it [,notify]
             | do_it [,quiet]
             | reject
             | request_auth
             | owner

<subscriber_key_word> ::= email | gecos | bounce | reception | visibility | date <additional_subscriber_fields>

<list_key_word> ::= name | host | lang | max_size | priority | reply_to | 
		    status | subject | account | 

<conf_key_word> ::= host | email | listmaster | default_list_priority | 
		      sympa_priority | request_priority | lang | max_size
	 	      
\end{verbatim}
\end{quote}

perl\_regexp can contain the string [host] (interpreted at run time as the list or robot domain).
The variable notation [msg\_header-$>$<smtp\_key\_word>] is interpreted as the SMTP header value only when performing
the sending message scenario. It can be used, for example, to require editor validation for multipart messages.
[msg\_part-$>$type] and [msg\_part-$>$body] are the MIME parts content-types and bodies ; the body is available
for MIME parts in text/xxx format only.

%[idees de scenario]

\section {Loop detection}
    \label {loop-detection}
    \index{loop-detection}

\Sympa uses multiple tools to avoid loops in Mailing lists

First, it rejects messages coming from a robot (as indicated by the
From: and other header fields), and messages containing commands.

Secondly, every message sent by \Sympa includes an X-Loop header field set to
the listname. If the message comes back, \Sympa will detect that
it has already been sent (unless X-Loop header fields have been
erased).

Thirdly, \Sympa keeps track of Message IDs and will refuse to send multiple
messages with the same message ID to the same mailing list.

Finally, \Sympa detect loops arising from command reports (i.e. sympa-generated replies to commands). 
This sort of loop might occur as follows:

\begin {quote}
\begin{verbatim}
1 - X sends a command to Sympa
2 - Sympa sends a command report to X
3 - X has installed a home-made vacation program replying to programs
4 - Sympa processes the reply and sends a report
5 - Looping to step 3
\end{verbatim}
\end {quote}

\Sympa keeps track (via an internal counter) of reports sent to any particular address.
The loop detection algorithm is :

\begin {itemize}

	\item Increment the counter

	\item If we are within the sampling period (as defined by the
	\cfkeyword {loop\_command\_sampling\_delay} parameter)

	\begin {itemize}
		\item If the counter exceeds the 
		\cfkeyword {loop\_command\_max} parameter, then 
		do not send the report, and notify the listmaster

		\item Else, start a new sampling period and reinitialize
		the counter,  i.e. multiply it by the 
		\cfkeyword {loop\_command\_decrease\_factor} parameter
	\end {itemize}


\end {itemize}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mailing list definition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Mailing list definition}
    \label {ml-creation}

The mailing list creation tool is Sympa's web interface. However, this
web feature has only been available from version 2.7 onwards. Users of previous versions
will need to create new lists using their favorite text file editor.  

This chapter describe how to create a mailing list without using
web tools. See~\ref {web-ml-creation}, page~\pageref {web-ml-creation} for
instructions on the use of WWSympa, which is no doubt the easier method.

The only part of list creation requiring system privileges is the declaration of new
system-wide mail aliases. All the other steps should be performed by the \texttt {sympa} user,
which will ensure that the files created have the correct access permissions.


\begin {itemize}
        \item add aliases in the alias file

        \item create the list directory \tildedir {sympa/expl/\samplelist}

        \item create the configuration file in the \tildedir
            {sympa/expl/\samplelist} directory

        \item create customized message files (welcome, bye, removed
          remind, message.header, message.footer) if needed ; in most cases you will probably need at least to create the welcome message.

\end {itemize}


\section {Mail aliases}
    \label {list-aliases}
    \index{aliases}
    \index{mail aliases}

For each new list, it is necessary to create three mail aliases
(the location of the \unixcmd {sendmail} alias file varies from
one system to another).

For example, to create the \mailaddr {\samplelist} list, the following
aliases must be added:

\begin {quote}
    \tt
    \begin {tabular} {ll}
        \mailaddr {\samplelist}:         &
            "|/home/sympa/bin/queue \samplelist"
            \\
        \mailaddr {\samplelist-request}: &
            "|/home/sympa/bin/queue \samplelist-request"
            \\
        \mailaddr {\samplelist-editor}:  &
            "|/home/sympa/bin/queue \samplelist-editor"
            \\
        \mailaddr {\samplelist-owner}:   &
            "|/home/sympa/bin/bouncequeue \samplelist
            \\
        \mailaddr {\samplelist-subscribe}:   &
            "|/home/sympa/bin/queue \samplelist-subscribe"
            \\
        \mailaddr {\samplelist-unsubscribe}: &
            "|/home/sympa/bin/queue \samplelist-unsubscribe"
            \\

    \end {tabular}
\end {quote}

%This example demonstrates how to define a list with the low priority
%level 2. Messages for editor and owner will be processed by \Sympa
%with greater priority (level 1) than messages to the list itself.

The address \mailaddr {\samplelist-request} should correspond
to the person responsible for managing \mailaddr {\samplelist}
(the \textindex {owner}).  \Sympa will forward messages for
\mailaddr {\samplelist-request} to the owner of \mailaddr {\samplelist},
as defined in the \tildefile {sympa/expl/\samplelist/config}
file.  Using this feature means you would not need to modify the
alias file if the owner of the list were to change.

Similarly, the address \mailaddr {\samplelist-editor} can be used
to contact the list editors if any are defined in
\tildefile {sympa/expl/\samplelist/config}.  This address definition
is not compulsory.

The address \mailaddr {\samplelist-owner} is the address receiving
non-delivery reports. The \file {bouncequeue} program stores these messages 
in the \dir {queuebounce} directory. \WWSympa ((see~\ref {wwsympa}, page~\pageref {wwsympa})
may then analyze them and provide a web access to them.

The address \mailaddr {\samplelist-subscribe} is an address enabling
users to subscribe in a manner which can easily be explained to them.
Beware: subscribing this way is so straightforward that you may find spammers
subscribing to your list by accident.

The address \mailaddr {\samplelist-unsubscribe} is the equivalent for
unsubscribing. By the way, the easier it is for users to unsubscribe, the easier it will
be for you to manage your list!


\section {List directory}
\label {list-directory}

Each list has its own directory whose name defines the list name. We
recommend creating it with the same name as the alias. This directory is
located in \tildedir {sympa/expl} (or any other \cfkeyword{home}
which you might have defined in the\file {/etc/sympa.conf} file).

Here is a list of files/directories you may find in the list directory :

\begin {quote}
\begin{verbatim}
archives/
bye.tpl
config
info
invite.tpl
homepage
message.header
message.footer
reject.tpl
remind.tpl
removed.tpl
stats
subscribers
welcome.tpl
\end{verbatim}
\end {quote}

\section {List configuration file}
    \label {exp-config}


The configuration file for the \mailaddr {\samplelist} list is named
\tildefile {sympa/expl/\samplelist/config}. \Sympa reads it into memory
the first time the list is referred to. This file is not rewritten by 
\Sympa, so you may put comment lines in it. 
It is possible to change this file when the program is running. 
Changes are taken into account the next time the list is
accessed. Be careful to provide read access for \Sympa to this file !

You will find a few configuration files in the \dir {sample} directory. Copy
one of them to \tildefile {sympa/expl/\samplelist/config} and customize it.

List configuration parameters are described in the list creation section, \ref {list-configuration-param}, page~\pageref {list-configuration-param}.

\section {Examples of configuration files}

This first example is for a list open to everyone:

\begin {quote}
\begin{verbatim}
subject First example (an open list)

visibility noconceal

owner
email Pierre.David@prism.uvsq.fr

send public

review public
\end{verbatim}
\end {quote}

The second example is for a moderated list with authenticated subscription:
\index{moderation}
\index{authentication}

\begin {quote}
\begin{verbatim}
subject Second example (a moderated list)

visibility noconceal

owner
email moi@ici.fr

editor
email big.prof@ailleurs.edu

send editor

subscribe auth

review owner

reply_to_header
value list

cookie 142cleliste
\end{verbatim}
\end {quote}

The third example is for a moderated list, with subscription
controlled by the owner, and running in digest mode. Subscribers
who are in \textindex {digest} mode receive messages on Mondays and
Thursdays.

\begin {quote}
\begin{verbatim}
owner
email moi@ici.fr

editor
email prof@ailleurs.edu

send editor

subscribe owner

review owner

reply_to_header
value list

digest 1,4 12:00
\end{verbatim}
\end {quote}

\section {Subscribers file}
    \label {file-subscribers}
    \index{subscriber file}

\textbf {WARNING}: \Sympa will not use this file if the list is configured with \texttt {include} or \texttt {database} \lparam{user\_data\_source}.

The \tildefile {sympa/expl/\samplelist/subscribers} file is automatically created and
populated. It contains information about list
subscribers.  It is not advisable to edit this file.  Main parameters
are:

\begin {itemize}
    \item \lparam {email} \textit {address}

        E-mail address of subscriber.

    \item  \lparam {gecos} \textit {data} 

        Information about subscriber (last name, first name,
        etc.) This parameter is optional at subscription time.

    \item \lparam {reception}
            \texttt {nomail} $|$
            \texttt {digest} $|$
            \texttt {summary} $|$
            \texttt {notice} $|$
 	    \texttt {txt} $|$
	    \texttt {html} $|$
 	    \texttt {urlize} $|$
	    \texttt {not\_me} $|$
        \label {par-reception} 

        Special receive modes which the subscriber may select.
        Special modes can be either \textit {nomail},  \textit
        {digest}, \textit {summary}, \textit {notice}, \textit {txt},
        \textit {html}, \textit {urlize}, \textit {not\_me} .
        In normal receive mode, the receive attribute
        for a subscriber is not displayed.  See the \mailcmd
        {SET~LISTNAME~SUMMARY} (\ref {cmd-setsummary}, 
        page~\pageref {cmd-setsummary}),
        the \mailcmd {SET~LISTNAME~NOMAIL} command (\ref {cmd-setnomail},
        page~\pageref {cmd-setnomail}), and the \lparam {digest}
        parameter (\ref {par-digest}, page~\pageref {par-digest}).

    \item \lparam {visibility} \texttt {conceal}  
        \label {par-visibility-conceal}

        Special mode which allows the subscriber to remain invisible when
        a \mailcmd {REVIEW} command is issued for the list.  If this
        parameter is not declared, the subscriber will be visible
        for \mailcmd {REVIEW}.  Note: this option does not affect
        the results of a \mailcmd {REVIEW} command issued by an
        owner.  See the \mailcmd {SET~LISTNAME~MAIL} command (\ref
        {cmd-setconceal}, page~\pageref {cmd-setconceal}) for
        details.

\end {itemize}


\section {Info file}

\tildefile {sympa/expl/\samplelist/info} should contain a detailed text
description of the list, to be displayed by the \mailcmd {INFO} command. 
It can also be referenced from template files for service messages.

\section {Homepage file}

\tildefile {sympa/expl/\samplelist/homepage} is the HTML text 
on the \WWSympa info page for the list.

\section {List template files}
\label{list-tpl}
\index{templates, list}

These files are used by Sympa as service messages for commands such as
\mailcmd {SUB}, \mailcmd {ADD}, \mailcmd {SIG}, \mailcmd {DEL}, \mailcmd {REJECT}. 
These files are interpreted (parsed) by \Sympa and respect the template 
format ; every file has the .tpl extension. See \ref {tpl-format}, 
page~\pageref {tpl-format}. 

Sympa looks for these files in the following order :
\begin {enumerate}
 	\item \tildedir {sympa/expl/\samplelist/<file>.tpl} 
	\item \tildedir {sympa/etc/templates/<file>.tpl}. 
	\item \tildedir {sympa/bin/etc/templates/<file>.tpl}.
\end {enumerate}

If the file starts with a From: line, it is taken to be
a full message and will be sent (after parsing) without the addition of SMTP
headers. Otherwise the file is treated as a text/plain message body.

The following variables may be used in list template files :

\begin {itemize}

	\item[-] [conf-$>$email] : sympa e-mail address local part

	\item[-] [conf-$>$host] : sympa host name

	\item[-] [conf-$>$sympa] : sympa's complete e-mail address

	\item[-] [conf-$>$wwsympa\_url] : \WWSympa root URL

	\item[-] [conf-$>$listmaster] : listmaster e-mail addresses

	\item[-] [list-$>$name] : list name

	\item[-] [list-$>$host] : list hostname

	\item[-] [list-$>$lang] : list language

	\item[-] [list-$>$subject] : list subject

	\item[-] [list-$>$owner] : list owners table hash

	\item[-] [user-$>$email] : user e-mail address

	\item[-] [user-$>$gecos] : user gecos field (usually his/her name)

	\item[-] [user-$>$password] : user password

	\item[-] [user-$>$lang] : user language
	

\end {itemize}

You may also dynamically include a file from a template using the
[INCLUDE] directive.


\textit {Example:} 

\begin {quote}
\begin{verbatim}
Dear [user->email],

Welcome to list [list->name.@[list->host].

Presentation of the list :
[INCLUDE 'info']

The owners of [list->name] are :
[FOREACH ow IN list->owner]
   [ow->gecos] <[ow->email]>
[END]


\end{verbatim}
\end {quote}

\subsection {welcome.tpl} 

\Sympa will send a welcome message for every subscription. The welcome 
message can be customized for each list.

\subsection {bye.tpl} 

Sympa will send a farewell message for each SIGNOFF 
mail command received.

\subsection {removed.tpl} 

This message is sent to users who have been deleted (using the \mailcmd {DELETE} 
command) from the list by the list owner.


\subsection {reject.tpl} 

\Sympa will send a reject message to the senders of messages rejected
by the list editor. If the editor prefixes her \mailcmd {REJECT} with the
keyword QUIET, the reject message will not be sent.


\subsection {invite.tpl} 

This message is sent to users who have been invited (using the \mailcmd {INVITE} 
command) to subscribe to a list. 

You may use additional variables
\begin {itemize}

	\item[-] [requested\_by] : e-mail of the person who sent the 
		\mailcmd{INVITE} command

	\item[-] [url] : the mailto: URL to subscribe to the list

\end {itemize}

\subsection {remind.tpl}

This file contains a message sent to each subscriber
when one of the list owners sends the \mailcmd {REMIND} command
 (see~\ref {cmd-remind}, page~\pageref {cmd-remind}).

\subsection {summary.tpl}

Template for summaries (reception mode close to digest), 
see~\ref {cmd-setsummary}, page~\pageref {cmd-setsummary}.

\section {Stats file}
    \label {stats-file}
    \index{statistics}

\tildefile {sympa/expl/\samplelist/stats} is a text file containing 
statistics about the list. Data are numerics separated
by white space within a single line :

\begin {itemize}

	\item Number of messages sent, used to generate X-sequence headers

	\item Number of messages X number of recipients 

	\item Number of bytes X number of messages

	\item Number of bytes X number of messages X number of recipients

	\item Number of subscribers

\end {itemize}

\section {Message header and footer} 
\label {messagefooter}

You may create \tildefile {sympa/expl/\samplelist/message.header} and
\tildefile {sympa/expl/\samplelist/message.footer} files. Their content
is added, either at the beginning or at the end of each message 
before the distribution process. 

The \lparam {footer\_type} list parameter defines whether to attach the 
header/footer content as a MIME part (except for multipart/alternative 
messages), or to append them to the message body (for text/plain messages).

\subsection {Archive directory} 

The \tildedir {sympa/expl/\samplelist/archives/} directory contains the 
archived messages for lists which are archived; see \ref {par-archive}, 
page~\pageref {par-archive}. The files are named in accordance with the 
archiving frequency defined by the \lparam {archive} parameter.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Virtual robot how to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\chapter {Virtual robot}
    \label {virtual-robot}

Sympa is designed to manage multiple distinct mailing list servers on
a single host with a single Sympa installation. Sympa virtual robots
are likely Apache virtual hosting. Sympa virtual robot definition include
a specific email adress for the robot itself and its lists and also a virtual
http server. Each robot provide access to a set of lists, each list are
related to only one robot.

All configuration parameters can be define for each robot except Sympa
installation parameters such as binary and spool location, smtp engine,
antivirus plugging etc.

\section {Robot definition}

A robot is named by its domain, let's say \samplerobot and and defined by a directory 
\tildedir {sympa/etc/\samplerobot}. This directory must contain at least a 
\file {robot.conf} file. This files as the same format as  \file {/etc/sympa.conf}
(have a look at robot.conf in the sample dir).
Only the following parameters can be redefined for a particular robot :

\begin {itemize}
\item http\_host
\item title
\item default\_home
\item lang
\item listmaster
\item max\_size
\item dark\_color, light\_color, text\_color, bg\_color, error\_color, selected\_color, shaded\_color 
\end {itemize}

Thoses settings overwrite the equivalent global parameter as defined in \file {/etc/sympa.conf}
for \samplerobot robot. The http\_host parameter is compared by wwsympa with the HTTP\_HOST
envirronement variable to recognize which robot is in used. 

\subsection {Robot customization}

If exists \tildedir {sympa/etc/\samplerobot/wws\_templates/},
\tildedir {sympa/etc/\samplerobot/templates/}, 
\tildedir {sympa/etc/\samplerobot/scenari/} directries are applied when
loading templates or scenarii before searching into \tildedir {sympa/etc} and  \tildedir {sympa/bin/etc}. this allow to define specific access and specific look for a particular robot.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List configuration parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Creating and editing mailing using the web}
    \label {web-ml-creation}

The management of mailing lists by list owners will usually be
done via the web interface. This is based on a strict definition
of privileges which pertain respectively to the
listmaster, to the main list owner, and to basic list owners. The goal is to
allow each listmaster to define who can create lists, and which
parameters may be set by owners. Therefore, a complete
installation requires some careful planning, although default
values should be acceptable for most sites.

Some features are already available, others will be shortly, as specified
in the documentation.

\section {List creation}


Listmasters have all privileges. Currently the listmaster
is defined in \file {sympa.conf} but in the future, it might be possible to
define one listmaster per virtual robot. By default, newly created
lists must be activated by the listmaster. List creation is possible for all intranet users 
(i.e. : users with an e-mail address within the same domain as Sympa).
This is controlled by the \cfkeyword {create\_list} scenario.

\subsection {Who can create lists}

It is defined by \cfkeyword {create\_list} sympa.conf parameter (see \ref {create-list},  
page~\pageref {create-list}). This parameter refers to a \textbf {create\_list} scenario.
It will determine if the \textit {create list} button is displayed, if it requires
a listmaster confirmation.

The scenario can accepts any condition concerning the [sender]
(ie WWSympa user), and it returns \cfkeyword {reject}, \cfkeyword {do\_it}
or \cfkeyword {listmaster} as an action.

Only in cases where a user is authorized by the create\_list scenario
will the "create" button be available in the main menu.
If the scenario returns \cfkeyword {do\_it}, the list will be created and installed.
If the scenario returns "listmaster", the user is allowed to create a list, but
the list is created with the \cfkeyword {pending} status,
which means that only the list owner may view or use it.
The listmaster will need to open the list of pending lists
using the "pending list" button in the "server admin"
menu in order to install or refuse a pending list.

\subsection {typical list profile}

Mailing lists can have many different uses. \Sympa offers a
wide choice of parameters to adapt a list's behavior
to different situations. Users might have difficulty selecting all the
correct parameters, so instead the create list form asks
the list creator simply to choose a profile for the list, and to fill in
the owner's e-mail and the list subject together with a short description.

List profiles can be stored in \tildedir {sympa/etc/create\_list\_templates} or
\tildedir {sympa/bin/etc/create\_list\_templates}, which are part of the Sympa
distribution and should not be modified.  
\tildedir {sympa/etc/create\_list\_templates}, which will not be
overwritten by make install, is intended to contain site customizations.


A list profile is an almost complete list configuration, but with a number of missing fields
(such as owner e-mail)
to be replaced by WWSympa at installation time. It is easy to create new list 
templates by modifying existing ones. Contributions to the distribution are welcome.

You might want to hide or modify profiles (not useful, or dangerous 
for your site). If a profile exists both in the local site directory
\tildedir {sympa/etc/create\_list\_templates} and
\tildedir {sympa/bin/etc/create\_list\_templates} directory, then the local profile 
will be used by WWSympa. 

Another way to control publicly available profiles is to
edit the \cfkeyword {create\_list.conf} file (the default for this file is in
the \tildedir {sympa/bin/etc/} directory, and you may create your own customized
version in \tildedir {sympa/etc/}).
This file controls which of the available list templates are to be displayed. Example :
\begin {quote}
\begin{verbatim}
# Do not allow the public_anonymous profile
public_anonymous hidden
* read
\end{verbatim}
\end{quote}


When a list is created, whatever its status (\cfkeyword {pending} or
\cfkeyword {open}), the owner can use WWSympa admin features to modify list
parameters, or to edit the welcome message, and so on.

WWSympa logs the creation and all modifications to a list as part of the list's
\file {config} file (and old configuration files are saved).

\subsection {creating list alias}

If you defined an alias\_manager in \file {wwsympa.conf} 
(see \ref {alias-manager}, page~\pageref {alias-manager}), \WWSympa
will run this script for installing aliases. You can write your
own alias\_manager script, adapted to your MTA or mail configuration,
provided that it recognizes the same set of parameters.

\section {List edition}
\label {list-edition}

For each parameter, you may specify (via the \tildefile {sympa/etc/edit\_list.conf}
configuration file) who has the right to edit the parameter concerned ; the default 
\tildefile {sympa/bin/etc/edit\_list.conf} is reasonably safe.

\begin {quote}
\begin{verbatim}
     examples :

         \# only listmaster can edit user\_data\_source, priority, ...
         user\_data\_source listmaster  

         priority listmaster
      
         \# only privileged owner can modify  editor parameter, send, ...
         editor privileged\_owner

         send privileged\_owner

         \# other parameters can be changed by simple owners
         default owner
\end{verbatim}
\end {quote}

      Privileged owners are defined in the list's \file {config} file as follows :
	\begin {quote}
	\begin{verbatim}
		owner
		email owners.email@foo.bar
      		profile privileged
	\end{verbatim}
	\end {quote}

      The following rules are hard coded in WWSympa :
\begin {itemize}

\item listmaster is privileged owner of any list 

\item only listmaster can edit the "profile privileged"
      owner attribute 

\item owners can edit their own attributes (except profile and e-mail)

\item the requestor creating a new list becomes privileged owner

\item privileged owners can edit any gecos/reception/info attribute
of any owner

\item privileged owners can edit owners' e-mail addresses (but not privileged owners' e-mail addresses)

\end {itemize}

      Sympa aims to define two levels of trust for owners (some being entitled 
      simply to edit secondary parameters such as "custom\_subject", others having
      the right to manage more important parameters), while leaving control of
      crucial parameters (such as the list of privileged owners and user\_data\_sources)
      in the hands of the listmaster.
      Consequently, privileged owners can change owners' e-mails,
      but they cannot grant the responsibility of list management to others without
      referring to the listmaster.




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List configuration parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {List configuration parameters}
    \label {list-configuration-param}


The configuration file is composed of paragraphs separated by blank
lines and introduced by a keyword.

% [sa] Incomplet, �num�ration mal pr�sent�e et non cliquable
% [pda] : c'est maintenant cliquable. Pour la pr�sentation, on verra plus tard, lorsque ce sera complet

Even though there are a very large number of possible parameters, the minimal list
definition is very short. The only required parameters are  \lparam {owner} and \lparam {subject}.
All other parameters have a default value.

\begin {quote}
    \textit {keyword value}
\end {quote}

\textbf {WARNING}: configuration parameters must be separated by
blank lines and BLANK LINES ONLY !

\section {List description}

\subsection {editor}
    \label {par-editor}
    \index{moderation}

The \file {config} file contains one \lparam {editor} paragraph
per \textindex {moderator} (or editor).

\textit {Example:} 

\begin {quote}
\begin{verbatim}
editor
email Pierre.David@prism.uvsq.fr
gecos Pierre (Universit� de Versaille St Quentin)
\end{verbatim}
\end {quote}

Only the editor of a list is authorized to send messages
to the list when the \lparam {send} parameter (see~\ref {par-send},
page~\pageref {par-send}) is set to either \lparam {editor}, \lparam
{editorkey}, or \lparam {editorkeyonly}.
The \lparam {editor} parameter is also consulted in certain other cases
( \lparam {privateoreditorkey} ).

The syntax of this directive is the same as that of the \lparam
{owner} parameter (see~\ref {par-owner}, page~\pageref {par-owner}),
even when several moderators are defined.

\subsection {host}
 \label {par-host}
 \index{host}

	\default {\cfkeyword {host} robot parameter}

\lparam {host} \textit {fully-qualified-domain-name}

Domain name of the list, mainly used on the web interface. 
The default value is set in the \file {/etc/sympa.conf} file.

\subsection {lang}
    \label {par-lang}

	\default {\cfkeyword {lang} robot parameter}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
lang cn-big5
\end{verbatim}
\end {quote}

This parameter defines the language used for the list. It is
used to initialize a user's lang preference ; \Sympa command
reports are extracted from the associated message catalog.

See \ref {internationalization}, page~\pageref {internationalization}
for available languages.

\subsection {owner}
    \label {par-owner}


The \file {config} file contains one \lparam {owner} paragraph per owner. 

\textit {Example:} 

\begin {quote}
\begin{verbatim}
owner
email serge.aumont@cru.fr
gecos C.R.U.
info Tel: 02 99 76 45 34
reception nomail
\end{verbatim}
\end {quote}

The list owner is usually the person who has the authorization to send
\mailcmd {ADD} (see~\ref {cmd-add}, page~\pageref {cmd-add}) and
\mailcmd {DELETE} (see~\ref {cmd-delete}, page~\pageref {cmd-delete})
commands on behalf of other users.

When the \lparam {subscribe} parameter (see~\ref {par-subscribe},
page~\pageref {par-subscribe}) specifies a restricted list, it is
the owner who has the exclusive right to subscribe users, and
it is therefore to the owner that \mailcmd {SUBSCRIBE} requests
will be forwarded.

There may be several owners of a single list; in this case, each
owner is declared in a paragraph starting with the \lparam {owner}
keyword.

The \lparam {owner} directive is followed by one or several lines
giving details regarding the owner's characteristics:

\begin {itemize}
    \item  \lparam {email} \textit {address}

        Owner's e-mail address

    \item  \lparam {reception nomail}

        Optional attribute for an owner who does not wish to receive
        mails.  Useful to define an owner with multiple e-mail
        addresses: they are all recognized when \Sympa receives
        mail, but thanks to \lparam {reception nomail}, not all of
	these addresses need receive administrative mail from \Sympa.

    \item  \lparam {gecos} \textit {data}

        Public information on the owner

    \item \lparam {info} \textit {data}

	Available since release 2.3

	Private information on the owner

    \item \lparam {profile} \texttt {privileged} $|$
	                    \texttt {normal}

	Available since release 2.3.5

	Profile of the owner. This is currently used to restrict
	access to some features of WWSympa, such as adding new owners
	to a list.

\end {itemize}

\subsection {subject}
    \label {par-subject}

\lparam {subject} \textit {subject-of-the-list}

This parameter indicates the subject of the list, which is sent in
response to the \mailcmd {LISTS} mail command. The subject is
a free form text limited to one line.
This parameter is \emph {not} used by \Sympa if the \tildefile
{sympa/expl/lists} file (a static list of lists) exists.

\subsection {topics}
    \label {par-topics}

\lparam {topics} computing/internet,education/university

This parameter allows the classification of lists. You may define multiple 
topics as well as hierarchical ones. \WWSympa's list of public lists 
uses this parameter.

\subsection {visibility }
    \label {par-visibility}

	\default {conceal}

	\scenarized {visibility}

This parameter indicates whether the list should feature in the
output generated in response to a \mailcmd {LISTS} command. This
parameter is \emph {not} used by \Sympa if the \tildefile
{sympa/expl/lists} file (a static list of lists) exists.

\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->visibility]
     \item \lparam {visibility} \texttt {[s->name]}
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/visibility.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


\section {Data source related}

\subsection {user\_data\_source}

    	\label {par-user-data-source}
	\index{user-data-source}

	\default {file|database, if using an RDBMS}

\lparam {user\_data\_source}
   \texttt {file} $|$
   \texttt {database} $|$
   \texttt {include}

Sympa allows the mailing list manager to choose how \Sympa loads
subscriber data. Subscriber information can be stored in a text 
file or relational database, or included from various external
sources (list, flat file, result of LDAP or SQL query).

\begin {itemize}
\item  \lparam {user\_data\_source} \texttt {file}

       When this value is used, subscriber data
       are stored in a file whose name is defined by the
       \cfkeyword {subscribers} parameter in \file
       {sympa.conf}. This is maintained for backward compatibility.

\item  \lparam {user\_data\_source} \texttt {database} 

       This mode was been introduced to enable data to be stored
       in a relational database, in order, for example, for subscriber
       data to be shared with an HTTP interface, or simply to facilitate
       the administration of very large mailing lists. It has been
       tested with MySQL, using a list of 200 000 subscribers. 
       We strongly recommend the use of database in place of text files.
       It will improve performance, and solve possible conflicts between
       \Sympa and \WWSympa. Please refer to the 
       \"Using \Sympa with a relational database\" section
       (\ref {sec-rdbms}, page~\pageref {sec-rdbms}).

\item \lparam {user\_data\_source} \texttt {include} 
\label {user-data-source}       

       Here, subscribers are not defined \emph {extensively} (enumeration
       of their e-mail addresses) but \emph {intensively} (definition of criteria
       subscribers must satisfy). Includes can be performed 
       by extracting e-mail addresses using an SQL or LDAP query, or 
       by including other mailing lists. At least one include 
       paragraph, defining a data source, is needed. Valid include paragraphs (see
       below) are \lparam {include\_file}, \lparam {include\_list}, 
	\lparam {include\_sql\_query} and \lparam {include\_ldap\_query}. 
\end {itemize}


\subsection {ttl}

    	\label {ttl}
	\index{ttl}

	\default {3600}

\lparam {ttl} \texttt {delay\_in\_seconds} 

\Sympa caches user data extracted using the include parameter.
Their TTL (time-to-live) within \Sympa can be controlled using this
parameter. The default value is 3600.

\subsection {include\_list}

    	\label {include-list}
	\index{include-list}

\lparam {include\_list} \texttt {listname}

This parameter will be interpreted only if 
\lparam {user\_data\_source} is set to \texttt {include}.
All subscribers of list \texttt {listname} become subscribers 
of the current list. You may include as many lists as required, using one
\lparam {include\_list} \texttt {listname} line for each included
list. Any list at all may be included ; the \lparam {user\_data\_source} definition
of the included list is irrelevant, and you may therefore
include lists which are also defined by the inclusion of other lists. 
Be careful, however, not to include list \texttt {A} in list \texttt {B} and
then list \texttt {B} in list \texttt {A}, since this will give rise an 
infinite loop.


\subsection {include\_sql\_query}
    \label {include-sql-query}

\lparam {include\_sql\_query}

This parameter will be interpreted only if the
\lparam {user\_data\_source} value is set to  \texttt {include}, and
is used to begin a paragraph defining the SQL query parameters :

\begin{itemize}

\item
\label {db-type}
\lparam {db\_type} \textit {dbd\_name} 

The type of database (Oracle, MySQL , PostgreSQL, Sybase ...). This value identifies the PERL
DataBase Driver (DBD) to be used, and is therefore case-sensitive.

\item
\label {host}
\lparam {host} \textit {hostname}

The Database Server \Sympa will try to connect to.

\item
\label {db-name}
\lparam {db\_name} \textit {sympa\_db\_name}

The hostname of the database system.

\item
\label {connect-options}
\lparam {connect\_options} \textit {option1=x;option2=y}

These options ar appended to the connect string.
This parameter is optional.


\item 
\label {user}
\lparam {user} \textit {user\_id}

The user id to be used when connecting to the database.

\item 
\label {passwd}
\lparam {passwd} \textit {some secret}

The user passwd for \lparam {user}.


\item
\label {sql-query}
\lparam {sql\_query} \textit {a query string}
The SQL query string. No fields other than e-mail addresses should be returned
by this query!


\end{itemize}

Example :

\begin {quote}
\begin{verbatim}

user_data_source include

include_sql_query
      db_type oracle
      host sqlserv.admin.univ-x.fr
      user stduser
      passwd mysecret
      db_name studentbody
      sql_query SELECT DISTINCT email FROM student

\end{verbatim}
\end{quote}

\subsection {include\_ldap\_query}
    \label {include-ldap-query}

\lparam {include\_ldap\_query}

This paragraph defines parameters for a LDAP query returning a
list of subscribers. This paragraph is used only if \lparam
{user\_data\_source} is set to \texttt {include}. This feature
requires the Net::LDAP (perlldap) PERL module.

\begin{itemize}

\item
\label {host}
\lparam {host} \textit {ldap\_directory\_hostname} 

Name of the LDAP directory host.

\item
\label {port}
\lparam {port} \textit {ldap\_directory\_port} (Default 389) 

Port on which the Directory accepts connections.

\item
\label {user}
\lparam {user} \textit {ldap\_user\_name}

Username with read access to the LDAP directory.

\item
\label {passwd}
\lparam {passwd} \textit {LDAP\_user\_password}

Password for \lparam {user}.


\item
\label {suffix}
\lparam {suffix} \textit {directory name}

Defines the naming space covered by the search (optional, depending on
the LDAP server).

\item
\label {filter}
\lparam {filter} \textit {search\_filter}

Defines the LDAP search filter (RFC 2254 compliant).

\item
\label {attrs}
\lparam {attrs} \textit {mail\_attribute} 
\default {mail}

The attribute containing the e-mail address(es) in the returned object.

\item
\label {select}
\lparam {select} \textit {first $|$ all}
\default {first}

Defines whether to use only the first address, or all the addresses, in
cases where multiple values are returned.

\end{itemize}

Example :

\begin{quote}
\begin{verbatim}

    include_ldap_query
    host ldap.cru.fr
    suffix dc=cru, dc=fr
    filter (&(cn=aumont) (c=fr))
    attrs mail
    select first

\end{verbatim}
\end{quote}


\subsection {include\_file}
    \label {include-file}

\lparam {include\_file} \texttt {path to file} 

This parameter will be interpreted only if the
\lparam {user\_data\_source} value is set to  \texttt {include}.
The file should contain one e-mail address per line
(lines beginning with a "\#" are ignored).

\section {Command related}

\subsection {subscribe}
    \label {par-subscribe}

	\default {open}

	\scenarized {subscribe}

The \lparam {subscribe} parameter defines the rules for subscribing to the list. 
Predefined scenarii are :

\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->subscribe]
     \item \lparam {subscribe} \texttt {[s->name]}
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/subscribe.[s->name]})
	\end {htmlonly}\\
[s->title]

[END]
[STOPPARSE]
\end {itemize}

\subsection {unsubscribe}
    \label {par-unsubscribe}

	\default {open}

	\scenarized {unsubscribe}

This parameter specifies the unsubscription method for the list.
Use \texttt {open\_notify} or \texttt {auth\_notify} to allow owner
notification of each unsubscribe command. 
Predefined scenarii are :

\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->unsubscribe]
     \item \lparam {unsubscribe} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/unsubscribe.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}

\subsection {add}
    \label {par-add}

	\default {owner}

	\scenarized {add}

This parameter specifies who is authorized to use the \mailcmd {ADD} command.
Predefined scenarii are :


\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->add]
     \item \lparam {add} \texttt {[s->name]}
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/add.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


\subsection {del}
    \label {par-del}

	\default {owner}

	\scenarized {del}

This parameter specifies who is authorized to use the \mailcmd {DEL} command.
Predefined scenarii are :


\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->del]
     \item \lparam {del} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/del.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


\subsection {remind}
    \label {par-remind}

	\default {owner}

	\scenarized {remind}

This parameter specifies who is authorized to use the \mailcmd {remind} command.
Predefined scenarii are :


\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->remind]
     \item \lparam {remind} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/remind.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


\subsection {send}
    \label {par-send}

	\default {private}

	\scenarized {send}

This parameter specifies who can send messages to the list. Valid values for this
parameter are pointers to \emph {scenarii}.

\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->send]
     \item \lparam {send} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/send.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


\subsection {review}
    \label {par-review}

	\default {owner}

	\scenarized {review}

This parameter specifies who can use
\mailcmd {REVIEW} (see~\ref {cmd-review}, page~\pageref {cmd-review}),
administrative requests. 

Predefined scenarii are :

\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->review]
     \item \lparam {review} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/review.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


\subsection {shared\_doc}
    \label {par-shared}
    \index{shared}

This paragraph defines read and edit access to the shared document 
repository.

\subsubsection {Read access}

	\default {private}

	\scenarized {d\_read}

This parameter specifies who can read shared documents
(access the contents of a list's \dir {shared} directory).

Predefined scenarii are :

\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->d_read]
     \item \lparam {d\_read} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/d_read.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


\subsubsection {Edit access}

	\default {owner}

	\scenarized {d\_edit}

This parameter specifies who can perform changes
within a list's \dir {shared} directory (i.e. upload files
and create subdirectories).

Predefined scenarii are :

\begin {itemize}
[STARTPARSE]
[FOREACH s IN scenari->d_edit]
     \item \lparam {d\_edit} \texttt {[s->name]} 
	\begin {htmlonly}
	  (\htmladdnormallink {view} {http://listes.cru.fr/sympa/distribution/current/src/etc/scenari/d_edit.[s->name]})
	\end {htmlonly}\\
	[s->title]

[END]
[STOPPARSE]
\end {itemize}


Example:
\begin {quote}
\begin{verbatim}
shared_doc
d_read		public
d_edit		private
\end{verbatim}
\end {quote}

\section {List tuning}

\subsection {reply\_to\_header}
    \label {par-reply-to-header}

The \lparam {reply\_to} parameter starts a paragraph defining
	what \Sympa will place in the \rfcheader {Reply-To} SMTP header field of
	the messages it distributes.

\begin {itemize}

\item \lparam {value}   \texttt {sender} $|$
    			\texttt {list}   $|$
    			\texttt {other\_email}
	\default {sender}

	This parameter indicates whether the \rfcheader {Reply-To} field
	should indicate the sender of the message (\texttt {sender}),
	the list itself (\texttt {list}) or an arbitrary e-mail address (defined by the
	\lparam {other\_email} parameter).

Note: it is inadvisable to change this parameter, and particularly inadvisable to
set it to \texttt {list}. Experience has shown it to be almost inevitable that users,
mistakenly believing that they are replying only to the sender, will send private
messages to a list. This can lead, at the very least, to embarrassment, and sometimes
to more serious consequences.

\item \lparam {other\_email} \textit {an\_email\_address}

	If \lparam {value} was set to \texttt {other\_email}, this parameter
	defines the e-mail address used.

\item \lparam {apply}   \texttt {respect} $|$
    			\texttt {forced}  
	\default {respect}

	The default is to respect (preserve) the existing \rfcheader {Reply-To} SMTP header field
	in incoming messages. If set to \texttt {forced}, \rfcheader {Reply-To} SMTP header
	field will be overwritten.

\end {itemize}

\subsection {max\_size}
 \label {par-max-size}
 \index{max-size}

	\default {\cfkeyword {max\_size} robot parameter}

\lparam {max\_size} \textit {number-of-bytes}

Maximum size of a message in 8-bit bytes. The default value is set in
 the \file {/etc/sympa.conf} file.


\subsection {anonymous\_sender}
    	\label {par-anonymous-sender}
    	\index{anonymous\_sender}

	\lparam {anonymous\_sender} \textit {value}

If this parameter is set for a list, all messages distributed via the list are
rendered anonymous. SMTP \texttt {From:} headers in distributed messages are altered
to contain the value of the \lparam {anonymous\_sender} parameter. Various other
fields are removed (\texttt {Received:, Reply-To:, Sender:, 
X-Sender:, Message-id:, Resent-From:}

\subsection {custom\_header}
    	\label {par-custom-header}
    	\index{custom-header}

	\lparam {custom\_header} \textit {header-field}\texttt {:} \textit {value}

This parameter is optional. The headers specified
will be added to the headers of messages distributed via the
list. As of release 1.2.2 of \Sympa, it is possible to put several
custom header lines in the configuration file at the same time.

% [pda] : faudrait le mettre en anglais
% [sa] A voir laisse le commentaire
\example {custom\_header X-url: http://www.cru.fr/listes/apropos/sedesabonner.faq.html}.

\subsection {custom\_subject}

	\label {par-custom-subject}
	\index{custom-subject}

	\lparam {custom\_subject} \textit {value}

This parameter is optional. It specifies a string which is
added to the subject of distributed messages (intended to help
users who do not use automatic tools to sort incoming messages).

\example {custom\_subject [sympa-users]}.

\subsection {footer\_type}
    	\label {par-footer-type}
	\index{footer-type}

	\default {mime}

\lparam {footer\_type (optional, default value is mime)}
   \texttt {mime} $|$
   \texttt {append}

List owners may decide to add message headers or footers to messages
sent via the list. This parameter defines the way a footer/header is
added to a message.

\begin {itemize}
\item  \lparam {footer\_type} \texttt {mime}

       The default value. Sympa will add the
       footer/header as a new MIME part. If the message is in
       multipart/alternative format, no action is taken (since this would require another
       level of MIME encapsulation).


\item  \lparam {footer\_type} \texttt {append} 

        Sympa will not create new MIME parts, but
        will try to append the header/footer to the body of the
        message. \tildefile
        {sympa/expl/\samplelist/message.footer.mime} will be
        ignored. Headers/footers may be appended to text/plain
        messages only.


\end {itemize}

\subsection {digest}

    	\label {par-digest}
    	\index{digest}

	\lparam {digest} \textit {daylist} \textit {hour}\texttt {:}\textit {minutes}

Definition of \lparam {digest} mode. If this parameter is present,
subscribers can select the option of receiving messages in multipart/digest
MIME format.  Messages are then grouped together, and compilations of messages
are sent to subscribers in accordance with the rhythm selected
with this parameter.

\textit {Daylist} designates a list of days in the week in number
format (from 0 for Sunday to 6 for Saturday), separated by commas.

\example {digest 1,2,3,4,5 15:30} 

In this example, \Sympa sends digests at 3:30 PM from Monday to Friday.

\textbf {WARNING}: if the sending time is too late, \Sympa may not
be able to process it. It is essential that \Sympa should scan the digest
queue at least once between the time laid down for sending the
digest and 12:00~AM (midnight). As a rule of thumb, do not use a digest time
later than 11:00~PM.

\subsection {available\_user\_options}

    	\label {par-available-user-options}
	\index{available-user-options}

	The \lparam {available\_user\_options} parameter starts a paragraph to
	define available options for the subscribers of the list.

\begin {itemize}
   \item \lparam {reception} \textit {modelist}

	\default {\cfkeyword {reception} mail,notice,digest,summary,nomail}

\textit {modelist} is a list of modes (mail, notice, digest, summary, nomail),
separated by commas. Only these modes will be allowed for the subscribers of
this list. If a subscriber has a reception mode not in the list, sympa uses
the mode specified in the \textit {default\_user\_options} paragraph.

\end {itemize}

Example :
\begin {quote}
\begin{verbatim}
## Nomail reception mode is not available
available_user_options
reception  	digest,mail
\end{verbatim}
\end {quote}


\subsection {default\_user\_options}

    	\label {par-default-user-options}
	\index{default-user-options}

	The \lparam {default\_user\_options} parameter starts a paragraph to
	define a default profile for the subscribers of the list.

\begin {itemize}
    \item \lparam {reception}
            \texttt {notice} $|$
            \texttt {digest} $|$
            \texttt {summary} $|$
            \texttt {nomail} $|$
            \texttt {mail}

        Mail reception mode.

    \item \lparam {visibility}
            \texttt {conceal} $|$
            \texttt {noconceal} 

        Visibility of the subscriber with the \mailcmd {REVIEW}
        command.

\end {itemize}

Example :
\begin {quote}
\begin{verbatim}
default_user_options
reception  	digest
visibility	noconceal
\end{verbatim}
\end {quote}


\subsection {cookie}

    	\label {par-cookie}
	\index{cookie}

	\default {\cfkeyword {cookie} robot parameter}

\lparam {cookie} \textit {random-numbers-or-letters}

This parameter is a confidential item for generating \textindex
{authentication} keys for administrative commands (\mailcmd {ADD},
\mailcmd {DELETE}, etc.).  This parameter should remain concealed,
even for owners. The cookie is applied to all list owners, and is
only taken into account when the owner has the \lparam {auth}
parameter (\lparam {owner} parameter, see~\ref {par-owner},
page~\pageref {par-owner}).

\example {cookie secret22}

\subsection {priority}
    \label {par-priority}

	\default {\cfkeyword {default\_list\_priority} robot parameter}

\lparam {priority} \textit {0-9}

The priority with which \Sympa will process messages for this list.
This level of priority is applied while the message is going through the spool. 

0 is the highest priority. The following priorities can be used:  
\texttt {0...9~z}.
\texttt {z} is a special priority causing messages to
remain spooled indefinitely (useful to hang up a list).

Available since release 2.3.1.

\section {Bounce related}

\subsection {bounce}
    \label {bounce}

This paragraph defines bounce management parameters :

\begin{itemize}

\item
\label {warn-rate}
\lparam {warn\_rate} 

	\default {\cfkeyword {bounce\_warn\_rate} robot parameter}

	The list owner receives a warning whenever a message is distributed and
	the number (percentage) of bounces exceeds this value.

\item
\label {halt-rate}
\lparam {halt\_rate} 

	\default {\cfkeyword {bounce\_halt\_rate} robot parameter}

	\texttt {NOT USED YET}

	If bounce rate reaches the \texttt {halt\_rate}, messages 
	for the list will be halted, i.e. they are retained for subsequent 
	moderation. Once the number of bounces exceeds this value,
	messages for the list are no longer distributed. 
	
\end{itemize}

\textit {Example:} 

\begin {quote}
\begin{verbatim}
## Owners are warned with 10% bouncing addresses
## message distribution is halted with 20% bouncing rate
bounce
warn_rate	10
halt_rate	20
\end{verbatim}
\end {quote}

\subsection {welcome\_return\_path}
\label {welcome-return-path}

	\default {\cfkeyword {welcome\_return\_path} robot parameter}

	If set to \cfkeyword {unique}, the welcome message is sent using
        a unique return path in order to remove the subscriber immediately in
	the case of a bounce. 

\subsection {remind\_return\_path} 
\label {remind-return-path}

	\default {\cfkeyword {remind\_return\_path} robot parameter}

	Same as \cfkeyword {welcome\_return\_path}, but applied to remind
        messages.


\section {Archive related}

\Sympa maintains 2 kinds of archives: mail archives and web archives.

Mail archives can be retreived via a mail command send to the robot,
they are stored in \tildedir {sympa/expl/\samplelist/archives/} directory.

Web archives are accessed via the web interface (with access control), they
are stored in a directory defined in \file {wwsympa.conf}.

\subsection {archive}
    \label {par-archive}
    \index{archive}

If the \file {config} file contains an \lparam {archive} paragraph
\Sympa will manage an archive for this list.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
archive
period week
access private
\end{verbatim}
\end {quote}

If the \lparam {archive} parameter is specified, archives are
accessible to users through the \mailcmd {GET} command, 
and the index of the list archives is provided in reply to the \mailcmd {INDEX}
command (the last message of a list can be consulted using the \mailcmd {LAST} command).


\lparam {period}
    \texttt {day} $|$
    \texttt {week} $|$
    \texttt {month} $|$
    \texttt {quarter} $|$
    \texttt {year}


This parameter specifies how archiving is organized: by \texttt
{day}, \texttt {week}, \texttt {month}, \texttt {quarter},
or \texttt {year}.  Generation of automatic list archives requires
the creation of an archive directory at the root of the list directory (\tildedir
{sympa/expl/\samplelist/archives/}), used to store these documents.

\lparam {access}
    \texttt {private} $|$
    \texttt {public} $|$
    \texttt {owner} $|$
    \texttt {closed} $|$


This parameter specifies who is authorized to use the \mailcmd {GET}, \mailcmd {LAST} and \mailcmd {INDEX} commands.



\subsection {web\_archive}
    \label {par-web-archive}
    \index{web\_archive}

If the \file {config} file contains a \lparam {web\_archive} paragraph
\Sympa will copy all messages distributed via the list to the
"queueoutgoing"  spool. It is intended to be used with WWSympa html
archive tools. This paragraph must contain at least the access
parameter to control who can browse the web archive.

\textit {Example:} 

\begin {quote}
\begin{verbatim}
web_archive
access private
\end{verbatim}
\end {quote}


The value of the \lparam {web\_archive} access parameter must be one of the following :
\lparam {access}
    \texttt {private} $|$
    \texttt {public} $|$
    \texttt {owner} $|$
    \texttt {closed} $|$
    \texttt {listmaster} 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Shared documents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Shared documents}
    \label {shared}
    \index{shared}

Shared documents are documents that different users can manipulate
on-line via the web interface of \Sympa, provided that the are authorized
to do so. A shared space is associated with a list, and users of the list 
can upload, download, delete, etc, documents in the shared space.

\WWSympa shared web features are fairly rudimentary. It is not our aim to provide
a sophisticated tool for web publishing, such as are provided by products
like \textit {Rearsite}.
It is nevertheless very useful to be able to define privilege on
web documents in relation to list attributes such as \textit {subscribers},
\textit {list owners}, or \textit {list editors}. 

All file and directory names are lowercased by Sympa. It is consequently
impossible to create two different documents whose names differ only
in their case. The reason Sympa does this is to allow correct URL links
even when using an HTML document generator (typically Powerpoint) which uses 
random case for file names!

In order to have better control over the documents in
the shared space, each document is linked to a set of specific control information : 
its access rights. Security is thus ensured.

A list's shared documents are stored in the \tildedir {sympa/expl/\samplelist/shared}
directory. 

This chapter describes how the shared documents are managed, 
especially as regards their access rights. 
We shall see :  

\begin {itemize}
       	\item the kind of operations which can be performed on shared documents 

        \item access rights management  

        \item access rights control specifications
	
	\item actions on shared documents
        
	\item template files
\end {itemize}

\section {The three kind of operations on a document}
    \label {shared-operations}
Where shared documents are concerned, there are three kinds of operation which
have the same constraints relating to access control :
\begin{itemize}
	\item The read operation :\\
	\begin{itemize}
		\item If a directory, open it and list its contents (only those
		sub-documents the user is authorized to ``see'').
		\item If a file, download it, and if a viewable file (\textit {text/plain}, \textit {text/html},
		or image), display it. 
	\end{itemize}
	\item The edit operation :\\
		\begin{itemize}
		\item Subdirectory creation	
		\item File uploading
		\item Description of a document (title and basic information)
		\item On-line editing of a text file
		\item Document (file or directory) removal. If a directory, it must be empty.
		\end{itemize}
	These different edit actions are equivalent as regards access rights. Users who are
	authorized to edit a directory can create a subdirectory or upload a file to it,
	as well as describe or delete it. Users authorized to edit a file can edit
	it on-line, describe it, replace or remove it.  
	\item The control operation :\\
	The control operation is directly linked to the notion of access rights. If we wish
	shared documents to be secure, we have to control the access to them. Not everybody
	must be authorized to do everything to them. Consequently, each document has
	specific access rights for reading and editing. Performing a control action on a document
	involves changing its Read/Edit rights.\\
	The control operation has more restrictive access rights than the other two operations.
	Only the owner of a document, the privileged owner of the list and the listmaster have
	control rights on a document. Another possible control action on a document is therefore
	specifying who owns it.  
\end{itemize}
	


\section {The description file}
\label {shared-desc-file}
The information (title, owner, access rights...) relative to each document must be stored, and so
each shared document is linked to a special file called a description file, whose name includes
the \file {.desc} prefix.

The description file of a directory having the path \dir {mydirectory/mysubdirectory} has the path
\dir {mydirectory/mysubdirectory/.desc} .
The description file of a file having the path \dir {mydirectory/mysubdirectory/myfile.myextension} has the path
\dir {mydirectory/mysubdirectory/.desc.myfile.myextension} .

\subsection {Structure of description files}

The structure of a document (file or directory) description file is given below.
You should \textit {never} have to edit a description file.
 
\begin {quote}
\begin{verbatim}
title
  <description of the file in a few words>

creation
  email        <e-mail of the owner of the document> 
  date_epoch   <date_epoch of the creation of the document>

access
 read <access rights for read>
 edit <access rights for edit>
\end{verbatim}
\end {quote}

The following example is for a document that subscribers can read, but which only the owner of the document
and the owner of the list can edit.
\begin {quote}
\begin{verbatim}
title
  module C++ which uses the class List

creation
  email foo@some.domain.com
  date_epoch 998698638

access
 read  private
 edit  owner
\end{verbatim}
\end {quote}

\section {The predefined scenarii}
    \label {shared-scenarii}

\subsection {The public scenario}
The \textbf {public} scenario is the most permissive scenario. It enables anyone (including
unknown users) to perform the corresponding action.

\subsection {The private scenario}
The \textbf {private} scenario is the basic scenario for a shared space. Every subscriber of
the list is authorized to perform the corresponding action. The \textbf {private} scenario is the default
read scenario for \dir {shared} when this shared space is created. This can be modified by editing
the list configuration file.

\subsection {The scenario owner}
The scenario \textbf {owner} is the most restrictive scenario for a shared space.
Only the listmaster, list owners and the owner of the document
(or those of a parent document) are allowed to perform the corresponding action.
The \textbf {owner} scenario is the default scenario for editing. 

\section {Access control}
    \label {shared-access}
Access control is an important operation performed
every time a document within the shared space is accessed.

The access control relative to a document in the hierarchy involves an iterative
operation on all its parent directories. 

\subsection {Listmaster and privileged owners}
The listmaster and privileged list owners are special users in the shared
web. They are allowed to perform every action on every document in
the shared space. This privilege enables control over
the shared space to be maintained. It is impossible to prevent the listmaster and
privileged owners from performing whatever action they please on any document
in the shared space.
 
\subsection {Special case of the \dir {shared} directory}
In order to allow access to a root directory to be more restrictive than
that of its subdirectories, the \dir {shared} directory (root directory) is
a special case as regards access control.
The access rights for read and edit are those specified in the list configuration file.
Control of the root directory is specific. 
Only those users authorized to edit a list's configuration may change access rights on
its \dir {shared} directory. 
 
\subsection {General case}
\dir {mydirectory/mysubdirectory/myfile} is an arbitrary document in the shared space,
but {not} in the \textit {root} directory. A user \textbf {X} wishes to perform one
of the three operations (read, edit, control) on this document.
The access control will proceed as follows :
\begin{itemize}
	\item Read operation\\
	To be authorized to perform a read action on
	\dir {mydirectory/mysubdirectory/myfile}, \textbf {X} must be
	authorized to read every document making up the path; in other words, she
	must be allowed to read \dir {myfile} (the scenario of the description file
	of \dir {myfile} must return \textit {do\_it} for user \textbf {X}), and the
	same goes for \dir {mysubdirectory} and \dir {mydirectory}).\\
	In addition, given that the owner of a document or one of its parent directories
	is allowed to perform \textbf {all actions on that document},
	\dir {mydirectory/mysubdirectory/myfile} may also have read operations performed
	on it by the owners of \dir {myfile}, \dir {mysubdirectory},
	and \dir {mydirectory}.

	This can be schematized as follows :
\begin {quote}
\begin{verbatim}
	X can read <a/b/c> 

	if			  

	(X can read <c>
	AND X can read <b>
	AND X can read <a>)
					
	OR

	(X owner of <c>
	OR X owner of <b>
	OR X owner of <a>)
\end{verbatim}			
\end {quote}

	\item Edit operation\\
	The access algorithm for edit is identical to the algorithm for read :
\begin {quote}
\begin{verbatim}
	X can edit <a/b/c> 
	
	if 
		
	(X can edit <c>
	AND X can edit <b>				
	AND X can edit <a>)
					
	OR

	(X owner of <c>
	OR X owner of <b>
	OR X owner of <a>)
\end{verbatim}			
\end {quote}

	\item Control operation\\
	The access control which precedes a control action (change rights
	or set the owner of a document) is much more restrictive.
	Only the owner of a document or the owners of a parent
	document may perform a control action :
\begin {quote}
\begin{verbatim}
	X can control <a/b/c> 

	if
					
	(X owner of <c>
	OR X owner of <b>
	OR X owner of <a>)
\end{verbatim}			
\end {quote}

\end{itemize}

\section {Shared document actions}

The shared web feature has called for some new actions.
\begin{itemize}
	\item action D\_ADMIN\\
	Create the shared web, close it or restore it. The d\_admin action is accessible
	from a list's \textbf {admin} page.
	\item action D\_READ\\
	Reads the document after read access control. If a folder, lists all the subdocuments that can
	be read. If a file, displays it if it is viewable, else downloads it to disk.
	If the document to be read contains a file named \file {index.html} or \file {index.htm}, and if
	the user has no permissions other than read on all contained subdocuments, the read action will
	consist in displaying the index.
	The d\_read action is accessible from a list's \textbf {info} page.
	\item action D\_CREATE\_DIR\\
	Creates a new subdirectory in a directory that can be edited. 
	The creator is the owner of the directory. The access rights are
	those of the parent directory.
	\item action D\_DESCRIBE\\
	Describes a document that can be edited.
	\item action D\_DELETE\\
	Deletes a document after edit access control. If a folder, it has to be empty.
	\item action D\_UPLOAD\\
	Uploads a file into a directory that can be edited.  
	\item action D\_OVERWRITE\\
	Overwrites a file if it can be edited. The new owner of the file is the one who has done
	the overwriting operation.
	\item actions D\_EDIT\_FILE and D\_SAVE\_FILE\\
	Edits a file and saves it after edit access control. The new owner of the file is the one 
	who has done the saving operation. 
	\item action D\_CHANGE\_ACCESS\\
	Changes the access rights of a document (read or edit), provided that control of this document is
	authorized. 
	\item action D\_SET\_OWNER\\
	Changes the owner of a directory, provided that control of this document is
	authorized. The directory must be empty. The new owner can be anyone, but authentication is necessary
	before any action may be performed on the document.

\end{itemize}

\section {Template files}
The following template files have been created for the shared web:

\subsection {d\_read.tpl} 
The default page for reading a document. If a file, displays it (if 
viewable) or downloads it. If a directory, displays all readable
subdocuments, each of which will feature buttons corresponding
to the different actions this sub document allows. If the directory is
editable, displays buttons to describe it, upload a file to it
and, create a new subdirectory. If access to the document is editable,
displays a button to edit the access to it. 

\subsection {d\_editfile.tpl} 
The page used to edit a file. If a text file, allows it to be edited on-line.
This page also enables the description of the file to be edited, or another file
to be substituted in its place.

\subsection {d\_control.tpl}
The page to edit the access rights and the owner of a document. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Bounce management}

\Sympa allows bounce (non-delivery report) management. This
prevents list owners from receiving each bounce (1 per message
sent to a bouncing subscriber) in their own mailbox. Without
automatic processing of bounces, list owners either go
mad, or just delete them without further attention.

Bounces are received at \samplelist-owner address, which should
be sent to the \file {bouncequeue} program via aliases :

\begin {quote}
\begin{verbatim}
	\samplelist-owner: "|/home/sympa/bin/bouncequeue \samplelist"
\end{verbatim}
\end {quote}

\file {bouncequeue} (see \ref{binaries}, page~\pageref{binaries}) stores bounces in a
\tildedir {sympa/spool/bounce/} spool.

Bounces are then processed by the \file {bounced.pl} daemon.
This daemon analyses bounces to find out which
e-mail addresses are concerned and what kind of error was generated.
If bouncing addresses match a subscriber's address, information 
is stored in the \Sympa database (in subscriber\_table). Moreover, the most recent
bounce itself is archived in \dir {bounce\_path/\samplelist/email}
(where bounce\_path is defined in a \file {wwsympa.conf} parameter and
email is the user e-mail address).

When reviewing a list, bouncing addresses are tagged as bouncing.
You may access further information such as dates of first and last bounces,
number of received bounces for the address, the last bounce itself.

Future development of \Sympa should include the automatic deletion
of bouncing addresses.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Antivirus}
\label {Antivirus}

\Sympa lets you use an external antivirus solution to check incoming mails.
In this case you must set the \cfkeyword {antivirus\_path} and 
\cfkeyword {antivirus\_args} configuration parameters
 (see \ref {Antivirus plug-in}, page~\pageref {Antivirus plug-in}.
\Sympa is already compatible with McAfee/uvscan, Fsecure/fsav and Trend Micro/VirusWall.
For each mail received, \Sympa deposits its component parts in the \tildedir {sympa/spool/tmp/antivirus} directory and
then calls the antivirus software to check them.
When a virus is detected, \Sympa looks for the virus name in the virus scanner STDOUT and sends a
\file {your\_infected\_msg.tpl} warning to the sender of the mail.
The mail is saved as 'bad' and the working directory is deleted (except if \Sympa is running in debug mode).
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using Sympa commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\chapter {Using \Sympa commands}

Users interact with \Sympa, of course, when they send messages to
one of the lists, but also indirectly through administrative requests
(subscription, list of users, etc.).

This section describes administrative requests, as well as interaction
modes in the case of private and moderated lists.  Administrative
requests are messages whose body contains commands understood by
\Sympa, one per line. These commands can be indiscriminately placed
in the \rfcheader {Subject} or in the body of the message. The
\rfcheader {To} address is generally the \mailaddr {sympa{\at}domain}
alias, although it is also advisable to recognize the \mailaddr
{listserv{\at}domain} address.

Example:

\begin {quote}
\begin{verbatim}
From: pda@prism.uvsq.fr
To: sympa@cru.fr

LISTS
INFO sympa-users
REVIEW sympa-users
QUIT
\end{verbatim}
\end {quote}

Most user commands can have three-letter abbreviations (e.g. \texttt
{REV} instead of \mailcmd {REVIEW}).

\section {User commands}

\begin {itemize}
    \item  \mailcmd {HELP}

        Provides instructions for the use of \Sympa commands.  The
        result is the content of the \file {helpfile.tpl} template
        file. 

    \item  \mailcmd {INFO} \textit {listname}

        Provides the welcome message for the specified list. The
        result is the content of \tildefile {welcome[.mime]}.

    \item  \mailcmd {LISTS}
        \label {cmd-lists}

        Provides the names of lists managed by \Sympa.  This list
        can either be generated dynamically, using the \lparam {visibility}
        (see \ref {par-visibility}, page~\pageref {par-visibility})
        and \texttt {subject} list parameters (\ref {par-subject},
        page~\pageref {par-subject}), as well as \tildefile
        {sympa/expl/lists.header} and \tildefile
        {sympa/expl/lists.footer}). It can also be generated
        statically by including the contents of the \tildefile
        {sympa/expl/lists} file, which must be updated manually by
        the robot \textindex {administrator}.

    \item  \mailcmd {REVIEW} \textit {listname}
        \label {cmd-review}

        Provides the parameters of the specified list (owner,
        subscription mode, etc.), as well as the addresses of
        subscribers if the run mode authorizes it. See the \lparam
        {review} parameter (\ref {par-review}, page~\pageref
        {par-review}) for the configuration file of each list,
        which controls consultation authorizations for the subscriber
        list. Since subscriber addresses can be abused by spammers,
        it is strongly recommended that you \textbf {only authorize owners
        to access the subscriber list}.

    \item  \mailcmd {WHICH}
         \label {cmd-which}

        Returns the list of lists to which one is subscribed,
        as well as the configuration of his or her subscription to
        each of the lists (DIGEST, NOMAIL, SUMMARY, CONCEAL).

\item  \mailcmd {STATS} \textit {listname}
        \label {cmd-stats}

        Provides statistics for the specified list:
        number of messages received, number of messages sent,
        megabytes received, megabytes sent. This is the contents
        of the \tildefile {sympa/expl/stats} file.

    \item  \mailcmd {INDEX} \textit {listname}
        \label {cmd-index}

        Provides index of archives for specified list. Access rights
        to this function are the same as for the \mailcmd {GET}
        command. 

    \item  \mailcmd {GET} \textit {listname} \textit {archive}
        \label {cmd-get}

        To retrieve archives for list (see above).  Access
        rights are the same as for the \mailcmd {REVIEW} command.
        See \lparam {review} parameter (\ref {par-review},
        page~\pageref {par-review}).

    \item  \mailcmd {LAST} \textit {listname}
        \label {cmd-last}

        To receive the last message distributed in a list (see above).  Access
        rights are the same as for the \mailcmd {GET} command.

    \item  \mailcmd {SUBSCRIBE} \textit {listname firstname name}
        \label {cmd-subscribe}

        Requests sign-up to the specified list. The \textit
        {firstname} and \textit {name} are optional. If the
        list is parameterized with a restricted subscription (see
        \lparam {subscribe} parameter, \ref {par-subscribe},
        page~\pageref {par-subscribe}), this command is sent to the
        list owner for approval.

    \item  \mailcmd {INVITE} \textit {listname user@host name}
        \label {cmd-invite}

        Invite someone to subscribe to the specified list. The 
        \textit {name} is optional. The command is similar to the
        \mailcmd {ADD} but the specified person is not added to the
        list but invited to subscribe to it in accordance with the 
        \lparam {subscribe} parameter, \ref {par-subscribe},
        page~\pageref {par-subscribe}).


    \item  \mailcmd {SIGNOFF} \textit {listname} [ \textit {user@host} ]
        \label {cmd-signoff}

        Requests unsubscription from the specified list.
        \mailcmd {SIGNOFF *} means unsubscription from all lists.

    \item  \mailcmd {SET} \textit {listname} \texttt {DIGEST}
        \label {cmd-setdigest}

        Puts the subscriber in \textit {digest} mode for the \textit
        {listname} list.  Instead of receiving mail from the list
        in a normal manner, the subscriber will periodically receive
        it in a DIGEST. This DIGEST compiles a group of messages
        from the list, using multipart/digest mime format.

        The sending period for these DIGESTS is regulated by the
        list owner using the \lparam {digest} parameter (see~\ref
        {par-digest}, page~\pageref {par-digest}).  See the \mailcmd
        {SET~LISTNAME~MAIL} command (\ref {cmd-setmail}, page~\pageref
        {cmd-setmail}) and the \lparam {reception} parameter (\ref
        {par-reception}, page~\pageref {par-reception}).

    \item  \mailcmd {SET} \textit {listname} \texttt {SUMMARY}
        \label {cmd-setsummary}

        Puts the subscriber in \textit {summary} mode for the \textit
        {listname} list.  Instead of receiving mail from the list
        in a normal manner, the subscriber will periodically receive
        the list of messages. This mode is very close to the DIGEST
        reception mode but the subscriber receives only the list of messages.

        This option is available only if the digest mode is set.

    \item  \mailcmd {SET} \textit {listname} \texttt {NOMAIL}
        \label {cmd-setnomail}

        Puts subscriber in \textit {nomail} mode for the \textit
        {listname} list.  This mode is used when a subscriber no longer wishes
        to receive mail from the list, but nevertheless wishes to retain
        the possibility of posting to the list.
        This mode therefore prevents the subscriber from unsubscribing
        and subscribing later on.  See the \mailcmd {SET~LISTNAME~MAIL}
        command (\ref {cmd-setmail}, page~\pageref {cmd-setmail}) and
        the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {TXT}
        \label {cmd-settxt}

        Puts subscriber in \textit {txt} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        to receive mails sent in both format txt/html and txt/plain 
        only in txt/plain format.
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {HTML}
        \label {cmd-sethtml}

        Puts subscriber in \textit {html} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        to receive mails sent in both format txt/html and txt/plain 
        only in txt/html format.
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {URLIZE}
        \label {cmd-seturlize}

        Puts subscriber in \textit {urlize} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        not to receive attached files. The attached files are replaced by an URL	leading to the file stored on the list site. 
        
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {NOT\_ME}
        \label {cmd-not-me}

        Puts subscriber in \textit {not\_me} mode for the \textit
        {listname} list.  This mode is used when a subscriber wishes
        not to receive back the message that he has sent to the list. 
        
        See the \lparam {reception} (\ref {par-reception}, page~\pageref
        {par-reception}). 

    \item  \mailcmd {SET} \textit {listname} \texttt {MAIL}
        \label {cmd-setmail}

        Puts the subscriber in normal mode (default) for the \textit
        {listname} list.  This option is mainly used to cancel the
        \textit {nomail}, \textit {summary} or \textit {digest} modes. If the subscriber
        was in \textit {nomail} mode, he or she will again receive
        mail from the list in a normal manner.  See the \mailcmd
        {SET~LISTNAME~NOMAIL} command (\ref {cmd-setnomail},
        page~\pageref {cmd-setnomail}) and the \lparam {reception}
        parameter (\ref {par-reception}, page~\pageref {par-reception}).

    \item  \mailcmd {SET} \textit {listname} \texttt {CONCEAL}
        \label {cmd-setconceal}

        Puts the subscriber in \textit {conceal} mode for the
        \textit {listname} list.  The subscriber will then become
        invisible during \mailcmd {REVIEW} on this list. Only owners
        will see the whole subscriber list.

        See the \mailcmd {SET~LISTNAME~NOCONCEAL} command (\ref
        {cmd-setnoconceal}, page~\pageref {cmd-setnoconceal}) and
        the \lparam {visibility} parameter (\ref {par-visibility},
        page~\pageref {par-visibility}).


    \item  \mailcmd {SET} \textit {listname} \texttt {NOCONCEAL}
        \label {cmd-setnoconceal}

        Puts the subscriber in \textit {noconceal} mode (default)
        for \textit {listname} list. The subscriber will then
        become visible during \mailcmd {REVIEW} of this list. The
        \textit {conceal} mode is then cancelled.

        See \mailcmd {SET~LISTNAME~CONCEAL} command (\ref
        {cmd-setconceal}, page~\pageref {cmd-setconceal}) and
        \lparam {visibility} parameter (\ref {par-visibility},
        page~\pageref {par-visibility}).


    \item  \mailcmd {QUIT}
        \label {cmd-quit}

        Ends acceptance of commands. This can prove useful when
        the message contains additional lines, as for example in
        the case where a signature is automatically added by the
        user's mail program (MUA).

    \item  \mailcmd {CONFIRM} \textit {key}
        \label {cmd-confirm}

        If the \lparam {send} parameter of a list is set to \texttt
        {privatekey, publickey} or \texttt {privateorpublickey},
        messages are only distributed in the list after an
        \textindex {authentication} phase by return mail, using a
        one-time password (numeric key). For this authentication,
        the sender of the message is requested to post the ``\mailcmd
        {CONFIRM}~\textit {key}'' command to \Sympa.

    \item  \mailcmd {QUIET}

        This command is used for silent (mute) processing: no
        performance report is returned for commands prefixed with
        \mailcmd {QUIET}).

\end {itemize}

\section {Owner commands}

Some administrative requests are only available to list owner(s).
They are indispensable for all procedures in limited access mode,
and to perform requests in place of users.
These requests are:

\begin {itemize}
    \item \mailcmd {ADD} \textit {listname user@host firstname name}
        \label {cmd-add}

        Add command similar to \mailcmd {SUBSCRIBE}

    \item \mailcmd {DELETE} \textit {listname user@host}
        \label {cmd-delete}

        Delete command similar to \mailcmd {SIGNOFF}

    \item \mailcmd {REMIND} \textit {listname} or \mailcmd {REMIND} \textit {*}
	\label {cmd-remind}

        \mailcmd {REMIND} is used usually by list owner in order to send
        an individual service message to each subscriber. This
        message is make by parsing the remind.tpl file.

        \mailcmd {REMIND} is used to send to each subscriber of any list a single
        message with a summary of his/her subscriptions. In this case the 
        message sent is constructed by parsing the global\_remind.tpl file.
        For each list, \Sympa tests whether the list is configured as hidden 
	to each subscriber (parameter lparam {visibility}). By default the use 
	of this command is restricted to listmasters. 
	Processing may take a lot of time !
	
    \item  \mailcmd {EXPIRE}
        \label {cmd-expire}

        % [pda] : huh ???
        % [sa] on touche pas la doc avant d'avoir revu le code
        \textit {listname}
        \textit {age (in days)}
        \textit {deadline (in days)}
        (listname) (age (in days)) (deadline (in days))
        \textit {explanatory text to be sent to the subscribers concerned}

        This command activates an \textindex {expiration} process
        for former subscribers of the designated list. Subscribers
        for which no procedures have been enabled for more than
        \textit {age} days receive the explanatory text appended
        to the \mailcmd {EXPIRE} command. This text, which must be
        adapted by the list owner for each subscriber population,
        should explain to the people receiving this message that
        they can update their subscription date so as to not be
        deleted from the subscriber list, within a deadline of
        \textit {deadline} days.

        Past this deadline, the initiator of the \mailcmd {EXPIRE}
        command receives the list of persons who have not confirmed
        their subscription.  It is up to the initiator to send
        \Sympa the corresponding \mailcmd {DELETE} commands.

        Any operation updating the subscription date of an address
        serves as confirmation of subscription. This is also the
        case for \mailcmd {SET} option selecting commands and for
        the \mailcmd {SUBSCRIBE} subscription command itself. The fact
        of sending a message to the list also updates the subscription
        date.

        The explanatory message should contain at least 20 words;
        it is possible to delimit it by the word \mailcmd {QUIT},
        in particular in order not to include a signature, which
        would systematically end the command message.

        A single expiration process can be activated at any given
        time for a given list. The \mailcmd {EXPIRE} command
        systematically gives rise to \textindex {authentication}
        by return mail.  The \mailcmd {EXPIRE} command has \textbf
        {no effect on the subscriber list}.

    \item  \mailcmd {EXPIREINDEX} \textit {listname}
       \label {cmd-expireindex}

       Makes it possible, at any time, for an expiration process
       activated using an \mailcmd {EXPIRE} command to receive the
       list of addresses for which no enabling has been received.

    \item  \mailcmd {EXPIREDEL} \textit {listname}
       \label {cmd-expiredel}

       Deletion of a process activated using the \mailcmd {EXPIRE}
       command.  The \mailcmd {EXPIREDEL} command has no effect on
       subscribers, but it possible to activate a new expiration
       process with new deadlines.

\end {itemize}

As above, these commands can be prefixed with \mailcmd {QUIET} to
indicate processing without acknowledgment of receipt.


\section {Moderator commands}
    \label {moderation}

If a list is moderated, \Sympa only distributes messages enabled by one of
its moderators (editors). Moderators have several
methods for enabling message distribution, depending on the \lparam
{send} list parameter (\ref {par-send}, page~\pageref {par-send}).

\begin {itemize}
    \item  \mailcmd {DISTRIBUTE} \textit {listname} \textit {key}
        \label {cmd-distribute}

        If the \lparam {send} parameter of a list is set to \texttt
        {editorkey} or \texttt {editorkeyonly}, each message queued
        for \textindex {moderation} is stored in a spool (see~\ref
        {cf:queuemod}, page~\pageref {cf:queuemod}), and linked
        to a key.

        The \textindex {moderator} must use this command to enable
        message distribution.

    \item  \mailcmd {REJECT} \textit {listname} \textit {key}
        \label {cmd-reject}

        The message with the \textit {key} key is deleted from the
        moderation \textindex {spool} of the \textit {listname}
        list.

    \item  \mailcmd {MODINDEX} \textit {listname}
        \label {cmd-modindex}

        This command returns the list of messages queued for
        moderation for the \textit {listname} list.

        The result is presented in the form of an index, which
        supplies, for each message, its sending date, its sender,
        its size, and its associated key, as well as all
        messages in the form of a digest.

\end {itemize}

% [pda] : c'est int�ressant, mais c'est en fran�ais et ce n'est pas dans cette doc. Je pense que le mieux serait de le traduire en anglais et de l'inclure dans cette doc
% [sa] : OK a faire laisse le commentaire.
% [pda] : et de renvoyer l'URL ci-dessus vers la page HTML correspondante dans la doc
See also the
\htmladdnormallinkfoot {recommendations for moderators} {http://listes.cru.fr/admin/moderation.html}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Appendices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Index
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\cleardoublepage
\printindex

\end {document}

