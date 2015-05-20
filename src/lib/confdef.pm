# Conf.pm - This module does the sympa.conf and robot.conf parsing
# RCS Identication ; $Revision: 5688 $ ; $Date: 2009-04-30 14:49:42 +0200 (jeu, 30 avr 2009) $ 
#
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

package confdef;

use strict "vars";

use Sympa::Constants;

## This defines the parameters to be edited :
##   name   : Name of the parameter
##   file   : Conf file where the parameter is defined.  If omitted, the
##            parameter won't be added automatically to the config file, even
##            if a default is set.
##            "wwsympa.conf" is a synonym of "sympa.conf".  It remains there
##            in order to migrating older versions of config.
##   default: Default value : DON'T SET AN EMPTY DEFAULT VALUE ! It's useless
##            and can lead to errors on fresh install.
##   gettext_id : Description of the parameter
##   gettext_comment : FIXME FIXME
##   sample : FIXME FIXME
##   edit   : 1|0: FIXME FIXME
##   optional: 1|0: FIXME FIXME
##   vhost  : 1|0 : if 1, the parameter can have a specific value in a
##            virtual host
##   db     : 'db_first', 'file_first', 'no'
##   multiple: 1|0: If 1, the parameter can have mutiple values. Default is 0.
##   scenario: 1|0: If 1, the parameter is the name of scenario

our @params = (

    { 'gettext_id' => 'Site customization' },

    {
        'name'     => 'domain',
        'gettext_id'    => 'Main robot hostname',
        'sample'   => 'domain.tld',
        'edit'     => '1',
        'file'     => 'sympa.conf',
        'vhost'    => '1',
    },
    {
        'name'     => 'host',
        'optional' => 1,
        'vhost'    => '1',
    },
    {
        'name'     => 'email',
        'default'  => 'sympa',
        'gettext_id'    => 'Local part of sympa email address',
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'Effective address will be [EMAIL]@[HOST]',
    },
    {
        'name'     => 'email_gecos',
        'default'  => 'SYMPA',
        'gettext_id'    => 'Gecos for service mail sent by Sympa itself',
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'This parameter is used for display name in the "From:" header',
    },
    {
        'name'     => 'listmaster',
        'default'  => 'your_email_address@domain.tld',
        'gettext_id'    => 'Listmasters email list comma separated',
        'file'     => 'sympa.conf',
        'vhost'    => '1',
        'edit'     => '1',
        'gettext_comment'   => 'Sympa will associate listmaster privileges to these email addresses (mail and web interfaces). Some error reports may also be sent to these addresses.',
    },
    {
        'name'     => 'listmaster_email',
        'default'  => 'listmaster',
        'gettext_id'    => 'Local part of listmaster email address',
        'vhost'    => '1',
    },
    {
        'name'     => 'wwsympa_url',
        'sample'   => 'http://host.domain.tld/sympa',
        'gettext_id'    => 'URL of main Web page',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'soap_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'voot_feature',
        'default'  => 'off',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'max_wrong_password',
        'default'  => '19',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'spam_protection',
        'default'  => 'javascript',
        'vhost'    => '1',
    },
    {
        'name'     => 'web_archive_spam_protection',
        'default'  => 'cookie',
        'vhost'    => '1',
    },
    {
        'name'     => 'color_0',
        'default'  => '#ffcd9d', # very light grey use in tables,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_1',
        'default'  => '#999', # main menu button color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_2',
        'default'  => '#333',  # font color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_3',
        'default'  => '#ffffce', # top boxe and footer box bacground color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_4',
        'default'  => '#f77d18', #  page backgound color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_5',
        'default'  => '#fff',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_6',
        'default'  => '#99ccff', # list menu current button,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_7',
        'default'  => '#ff99cc', # errorbackground color,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_8',
        'default'  => '#3366CC',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_9',
        'default'  => '#DEE7F7',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_10',
        'default'  => '#777777', # inactive button,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_11',
        'default'  => '#ccc',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_12',
        'default'  => '#000',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_13',
        'default'  => '#ffffce',  # input backgound  | transparent,
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_14',
        'default'  => '#f4f4f4',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'color_15',
        'default'  => '#000',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'dark_color',
        'default'  => 'silver',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'light_color',
        'default'  => '#aaddff',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'text_color',
        'default'  => '#000000',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'bg_color',
        'default'  => '#ffffcc',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'error_color',
        'default'  => '#ff6666',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'selected_color',
        'default'  => 'silver',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'shaded_color',
        'default'  => '#66cccc',
        'vhost'    => '1',
        'db'       => 'db_first',
    },
    {
        'name'     => 'logo_html_definition',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'favicon_url',
        'optional' => '1',
        'vhost'    => '1',
        'optional' => '1',
    },
    {
        'name'     => 'main_menu_custom_button_1_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_1_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_1_target',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_2_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_2_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_2_target',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_3_title',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_3_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'main_menu_custom_button_3_target',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'css_path',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'css_url',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'static_content_path',
        'default'  => Sympa::Constants::STATICDIR,
        'gettext_id'    => 'Directory for storing static contents (CSS, members pictures, documentation) directly delivered by Apache',
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'static_content_url',
        'default'  => '/static-sympa',
        'gettext_id'    => 'URL mapped with the static_content_path directory defined above',
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'pictures_feature',
        'default'  => 'on',
    },
    {
        'name'     => 'pictures_max_size',
        'default'  => 102400, ## 100 kiB,
        'vhost'    => '1',
    },
    {
        'name'     => 'cookie',
        'sample'   => '123456789',
        'gettext_id'    => 'Secret used by Sympa to make MD5 fingerprint in web cookies secure',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'Should not be changed ! May invalid all user password',
        'optional' => '1',
    },
    {
        'name'     => 'create_list',
        'default'  => 'public_listmaster',
        'gettext_id'    => 'Who is able to create lists',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'This parameter is a scenario, check sympa documentation about scenarios if you want to define one',
	'scenario' => '1',
    },
    {
        'name'     => 'global_remind',
        'default'  => 'listmaster',
	'scenario' => '1',
    },
    {
        'name'     => 'allow_subscribe_if_pending',
        'default'  => 'on',
        'vhost'    => '1',
    },
    {
        'name'     => 'custom_robot_parameter',
        'gettext_id'    => 'Used to define a custom parameter for your server. Do not forget the semicolon between the param name and the param value.',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'multiple' => '1',
        'optional' => '1',
    },

    { 'gettext_id' => 'Directories' },

    {
        'name'     => 'home',
        'default'  => Sympa::Constants::EXPLDIR,
        'gettext_id'    => 'Directory containing mailing lists subdirectories',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'etc',
        'default'  => Sympa::Constants::SYSCONFDIR,
        'gettext_id'    => 'Directory for configuration files; it also contains scenari/ and templates/ directories',
        'file'     => 'sympa.conf',
    },

    { 'gettext_id' => 'System related' },

    {
        'name'     => 'syslog',
        'default'  => 'LOCAL1',
        'gettext_id'    => 'Syslog facility for sympa',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'Do not forget to edit syslog.conf',
    },
    {
        'name'     => 'log_level',
        'default'  => '0',
        'gettext_id'    => 'Log verbosity',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'gettext_comment'   => '0: normal, 2,3,4: for debug',
    },
    {
        'name'     => 'log_socket_type',
        'default'  => 'unix',
        'gettext_id'    => 'Communication mode with syslogd (unix | inet)',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'log_condition',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'log_module',
        'optional' => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'umask',
        'default'  => '027',
        'gettext_id'    => 'Umask used for file creation by Sympa',
        'file'     => 'sympa.conf',
    },

    { 'gettext_id' => 'Sending related' },

    {
        'name'     => 'sendmail',
        'default'  => '/usr/sbin/sendmail',
        'gettext_id'    => 'Path to the MTA (sendmail, postfix, exim or qmail)',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'should point to a sendmail-compatible binary (eg: a binary named "sendmail" is distributed with Postfix)',
    },
    {
        'name'     => 'sendmail_args',
        'default'  => '-oi -odi -oem',
    },
    {
        'name'     => 'distribution_mode',
        'default'  => 'single',
    },
    {
        'name'     => 'maxsmtp',
        'default'  => '40',
        'gettext_id'    => 'Max. number of Sendmail processes (launched by Sympa) running simultaneously',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'Proposed value is quite low, you can rise it up to 100, 200 or even 300 with powerfull systems.',
    },
    {
        'name'     => 'merge_feature',
        'default'  => 'off',
    },
    {
        'name'    => 'automatic_list_removal',
        'default' => 'none',
        'vhost'   => '1',
    },
    {
        'name'    => 'automatic_list_feature',
        'default' => 'off',
        'vhost'   => '1',
    },
    {
        'name'    => 'automatic_list_creation',
        'default' => 'public',
        'vhost'   => '1',
	'scenario' => '1',
    },
    {
        'name'    => 'automatic_list_families',
        'gettext_id'   => 'Defines the name of the family the automatic lists are based on.', 
        'file'    => 'sympa.conf',
        'optional' => '1',
        vhost   => '1',
    },
    {
        'name'    => 'automatic_list_prefix',
        'gettext_id'   => 'Defines the prefix allowing to recognize that a list is an automatic list.', 
        'file'    => 'sympa.conf',
        'optional' => '1',
    },
    {
        'name'     => 'log_smtp',
        'default'  => 'off',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'use_blacklist',
        'gettext_id'    => 'comma separated list of operations for which blacklist filter is applied',
        'default'  => 'send,create_list',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'Setting this parameter to "none" will hide the blacklist feature',
    },
    {
        'name'     => 'reporting_spam_script_path',
        'optional'  => '1',
        'gettext_id'    => 'If set, when a list editor report a spam, this external script is run by wwsympa or sympa, the spam is sent into script stdin',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'max_size',
        'gettext_id'    => 'Default maximum size (in bytes) for messages (can be re-defined for each list)',
        'default'  => '5242880', ## 5 MiB
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'misaddressed_commands',
        'default'  => 'reject',
    },
    {
        'name'     => 'misaddressed_commands_regexp',
        'default'  => '(subscribe|unsubscribe|signoff|set\s+(\S+)\s+(mail|nomail|digest))',
    },
    {
        'name'     => 'nrcpt',
        'default'  => '25',
        'gettext_id'    => 'Maximum number of recipients per call to Sendmail. The nrcpt_by_domain.conf file allows a different tuning per destination domain.',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'avg',
        'default'  => '10',
        'gettext_id'    => 'Max. number of different domains per call to Sendmail',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'alias_manager',
        'default'  => Sympa::Constants::SBINDIR . '/alias_manager.pl',
    },
    {
        name    => 'db_list_cache',
        default => 'off',
        'gettext_comment'  => 'Whether or not to cache lists in the database',
    },
    {
        'name'     => 'sendmail_aliases',
        'default'  => Sympa::Constants::SENDMAIL_ALIASES,
    },
    {
        'name'     => 'rfc2369_header_fields',
        'gettext_id'    => 'Specify which rfc2369 mailing list headers to add',
        'default'  => 'help,subscribe,unsubscribe,post,owner,archive',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'remove_headers',
        'gettext_id'    => 'Specify header fields to be removed before message distribution',
        'default'  => 'X-Sympa-To,X-Family-To,Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To,Sender',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'remove_outgoing_headers',
        'default'  => 'none',
    },
    {
        'name'     => 'reject_mail_from_automates_feature',
        'gettext_id'    => 'Reject mail from automates (crontab, etc) sent to a list?',
        'default'  => 'on',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'ignore_x_no_archive_header_feature',
        'default'  => 'off',
    },
    {
        'name'     => 'anonymous_header_fields',
        'default'  => 'Sender,X-Sender,Received,Message-id,From,DKIM-Signature,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender',
    },
    {
        'name'     => 'list_check_smtp',
        'optional' => '1',
        'gettext_id'    => 'SMTP server to which Sympa verify if alias with the same name as the list to be created',
        'vhost'    => '1',
        'gettext_comment'   => 'Default value is real FQDN of host. Set [HOST]:[PORT] to specify non-standard port.',
    },
    {
        'name'     => 'list_check_suffixes',
        'default'  => 'request,owner,editor,unsubscribe,subscribe',
        'vhost'    => '1',
    },
    {
        'name'     => 'list_check_helo',
        'optional' => '1',
        'gettext_id'    => 'SMTP HELO (EHLO) parameter used for alias verification',
        'vhost'    => '1',
        'gettext_comment'   => 'Default value is the host part of list_check_smtp parameter.',
    },
    {
        'name'     => 'urlize_min_size',
        'default'  => 10240, ## 10 kiB,
    },
    {
	'name'     => 'sender_headers',
	'default'  => 'Resent-From,From,From_,Resent-Sender,Sender',
	'gettext_id'    => 'Header field names used to determine sender of the messages.  "From_" means envelope sender (a.k.a. "UNIX From")',
    },

    { 'gettext_id' => 'Bulk mailer' },

    {
        'name'     => 'sympa_packet_priority',
        'gettext_id'    => 'Default priority for a packet to be sent by bulk.',
        'file'     => 'sympa.conf',
        'default'  => '5',
        'vhost'    => '1',
    },
    {
        'name'     => 'bulk_fork_threshold',
        'default'  => '1',
        'gettext_id'    => 'Minimum number of packets in database before the bulk forks to increase sending rate',
        'file'     => 'sympa.conf',
        'gettext_comment'   => '',
    },
    {
        'name'     => 'bulk_max_count',
        'default'  => '3',
        'gettext_id'    => 'Max number of bulks that will run on the same server',
        'file'     => 'sympa.conf',
        'gettext_comment'   => '',
    },
    {
        'name'     => 'bulk_lazytime',
        'default'  => '600',
        'gettext_id'    => 'The number of seconds a slave bulk will remain running without processing a message before it spontaneously dies.',
        'file'     => 'sympa.conf',
        'gettext_comment'   => '',
    },
    {
        'name'     => 'bulk_sleep',
        'default'  => '1',
        'gettext_id'    => "The number of seconds a bulk sleeps between starting a new loop if it didn't find a message to send.",
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'Keep it small if you want your server to be reactive.',
    },
    {
        'name'     => 'bulk_wait_to_fork',
        'default'  => '10',
        'gettext_id'    => 'Number of seconds a master bulk waits between two packets number checks.',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'Keep it small if you expect brutal increases in the message sending load.',
    },

    { 'gettext_id' => 'Quotas' },

    {
        'name'     => 'default_max_list_members',
        'default'  => '0',
        'optional' => '1',
        'gettext_id'    => 'Default limit for the number of subscribers per list (0 means no limit)',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'default_shared_quota',
        'optional' => '1',
        'gettext_id'    => 'Default disk quota for shared repository',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'default_archive_quota',
        'optional' => '1',
    },

    { 'gettext_id' => 'Spool related' },

    {
        'name'     => 'spool',
        'default'  => Sympa::Constants::SPOOLDIR,
        'gettext_id'    => 'Directory containing various specialized spools',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'All spool are created at runtime by sympa.pl',
    },
    {
        'name'     => 'queue',
        'default'  => Sympa::Constants::SPOOLDIR . '/msg',
        'gettext_id'    => 'Directory for incoming spool',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuedistribute',
        'default'  => Sympa::Constants::SPOOLDIR . '/distribute',
        'file'     => 'sympa.conf',
	'version_validity' => '6.3', # valid before version 6.3
	'upgrade'          => 1,     # used by upgrade process after validy
    },
    {
        'name'     => 'queuemod',
        'default'  => Sympa::Constants::SPOOLDIR . '/moderation',
        'gettext_id'    => 'Directory for moderation spool',
        'file'     => 'sympa.conf',
        'version_validity' => '6.3', # valid before version 6.3
        'upgrade'          => 1,      # used by upgrade process after validy
    },
    {
        'name'     => 'queuedigest',
        'default'  => Sympa::Constants::SPOOLDIR . '/digest',
        'gettext_id'    => 'Directory for digest spool',
        'file'     => 'sympa.conf',
        'version_validity' => '6.3', # valid before version 6.3
        'upgrade'          => 1,      # used by upgrade process after validy
    },
    {
        'name'     => 'queueauth',
        'default'  => Sympa::Constants::SPOOLDIR . '/auth',
        'gettext_id'    => 'Directory for authentication spool',
        'file'     => 'sympa.conf',
        'version_validity' => '6.3', # valid before version 6.3
        'upgrade'          => 1,      # used by upgrade process after validy
    },
    {
        'name'     => 'queueoutgoing',
        'default'  => Sympa::Constants::SPOOLDIR . '/outgoing',
        'gettext_id'    => 'Directory for outgoing spool',
        'file'     => 'sympa.conf',
        'version_validity' => '6.3', # valid before version 6.3
        'upgrade'          => 1,      # used by upgrade process after validy
    },
    {
        'name'     => 'queuesubscribe',
        'default'  => Sympa::Constants::SPOOLDIR . '/subscribe',
        'gettext_id'    => 'Directory for subscription spool',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuetopic',
        'default'  => Sympa::Constants::SPOOLDIR . '/topic',
        'gettext_id'    => 'Directory for topic spool',
        'file'     => 'sympa.conf',
        'version_validity' => '6.3', # valid before version 6.3
        'upgrade'          => 1,      # used by upgrade process after validy
    {   'name'       => 'queuesignoff',
	'default'    => Sympa::Constants::SPOOLDIR . '/signoff',
	'gettext_id' => 'Directory for unsubscription spool',
	'file'       => 'sympa.conf',
    },
    {
        'name'     => 'queuebounce',
        'default'  => Sympa::Constants::SPOOLDIR . '/bounce',
        'gettext_id'    => 'Directory for bounce incoming spool',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queuetask',
        'default'  => Sympa::Constants::SPOOLDIR . '/task',
        'gettext_id'    => 'Directory for task spool',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'queueautomatic',
        'default'  => Sympa::Constants::SPOOLDIR . '/automatic',
        'gettext_id'    => 'Directory for automatic list creation spool',
        'file'     => 'sympa.conf',
        'version_validity' => '6.3', # valid before version 6.3
        'upgrade'          => 1,      # used by upgrade process after validy
    },
    {
        'name'     => 'sleep',
        'default'  => '5',
        'gettext_comment'   => 'Must not be 0.',
    },
    {
        'name'     => 'tmpdir',
        'default'  => Sympa::Constants::SPOOLDIR . '/tmp',
        'gettext_id'    => 'Temporary directory used by OpenSSL, antivirus plugins, mhonarc etc',
    },
    {
        name    => 'viewmail_dir',
        default => Sympa::Constants::EXPLDIR . '/viewmail',
        'gettext_id'   => 'Directory containing html file generated by mhonarc while diplay messages others than archives',
        file    => 'sympa.conf',
    },
    {
        'name'     => 'clean_delay_queue',
        'default'  => '7',
    },
    {
        'name'     => 'clean_delay_queueoutgoing',
        'default'  => '7',
    },
    {
        'name'     => 'clean_delay_queuebounce',
        'default'  => '7',
    },
    {
        'name'     => 'clean_delay_queuemod',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queueauth',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queuesubscribe',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queuesignoff',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queuetopic',
        'default'  => '30',
    },
    {
        'name'     => 'clean_delay_queueautomatic',
        'default'  => '10',
    },
    {
        'name'     => 'clean_delay_tmpdir',
        'default'  => '7,',
    },

    { 'gettext_id' => 'Internationalization related' },

    {   'name' => 'supported_lang',
	'default' =>
	    'ca,cs,de,el,en-US,es,et,fr,fi,hu,it,ja,ko,nb,nl,oc,pl,pt-BR,ru,sv,tr,vi,zh-CN,zh-TW',
	'gettext_id' => 'Supported languages',
	'vhost'      => '1',
	'file'       => 'sympa.conf',
	'edit'       => '1',
	'gettext_comment' =>
	    "This is the set of language that will be proposed to your users for the Sympa GUI. Don't select a language if you don't have the proper locale packages installed.",
    },
    {   'name'            => 'lang',
	'default'         => 'en-US',
	'gettext_id'      => 'Default language (one of supported languages)',
	'vhost'           => '1',
	'file'            => 'sympa.conf',
	'edit'            => '1',
	'gettext_comment' => 'This is the default language used by Sympa',
    },
    {
        'name'     => 'legacy_character_support_feature',
        'default'  => 'off',
        'gettext_id'    => 'If set to "on", enables support of legacy character set',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'In some language environments, legacy encoding (character set) is preferred for e-mail messages: for example iso-2022-jp in Japanese language.',
    },
    {
        'name'     => 'filesystem_encoding',
        'default'  => 'utf-8',
    },

    { 'gettext_id' => 'Bounce related' },

    {
        'name'     => 'verp_rate',
        'default'  => '0%',
        'vhost'    => '1',
    },
    {
        'name'     => 'welcome_return_path',
        'default'  => 'owner',
        'gettext_id'    => 'Welcome message return-path ( unique | owner )',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'If set to unique, new subcriber is removed if welcome message bounce',
    },
    {
        'name'     => 'remind_return_path',
        'default'  => 'owner',
        'gettext_id'    => 'Remind message return-path ( unique | owner )',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'If set to unique, subcriber is removed if remind message bounce, use with care',
    },
    {
        'name'     => 'return_path_suffix',
        'default'  => '-owner',
    },
    {
        'name'     => 'expire_bounce_task',
        'default'  => 'daily',
        'gettext_id'    => 'Task name for expiration of old bounces',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'purge_orphan_bounces_task',
        'default'  => 'monthly',
    },
    {
        'name'     => 'eval_bouncers_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'process_bouncers_task',
        'default'  => 'weekly',
    },
    {
        'name'     => 'minimum_bouncing_count',
        'default'  => '10',
    },
    {
        'name'     => 'minimum_bouncing_period',
        'default'  => '10',
    },
    {
        'name'     => 'bounce_delay',
        'default'  => '0',
    },
    {
        'name'     => 'default_bounce_level1_rate',
        'default'  => '45',
        'vhost'    => '1',
    },
    {
        'name'     => 'default_bounce_level2_rate',
        'default'  => '75',
        'vhost'    => '1',
    },
    {
        'name'     => 'bounce_email_prefix',
        'default'  => 'bounce',
    },
    {
        'name'     => 'bounce_warn_rate',
        'default'  => '30',
        'gettext_id'    => 'Bouncing email rate for warn list owner',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'bounce_halt_rate',
        'default'  => '50',
        'gettext_id'    => 'Bouncing email rate for halt the list (not implemented)',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'Not yet used in current version, Default is 50',
    },
    {
        'name'     => 'tracking_default_retention_period',
        'default'  => '90',
    },
    {
        'name'     => 'tracking_delivery_status_notification',
        'default'  => 'off',
    },
    {
        'name'     => 'tracking_message_delivery_notification',
        'default'  => 'off',
    },
    {
        'name'     => 'default_remind_task',
        'optional' => '1',
    },

    { 'gettext_id' => 'Tuning' },

    {   'name'    => 'cache_list_config',
	'default' => 'none',
	'gettext_id' =>
	    'Use of binary version of the list config structure on disk (none | binary_file | database)',
	'file' => 'sympa.conf',
	'edit' => '1',
	'gettext_comment' =>
	    'Set this parameter to "binary_file" or "database" if you manage a big amount of lists (1000+); it should make the web interface startup faster.  Note that Oracle earlier than 8 and Sybase do not support "database"',
    },
    {
        'name'     => 'lock_method',
        'default'  => 'flock',
        'gettext_comment'   => 'flock | nfs',
    },
    {
        'name'     => 'sympa_priority',
        'gettext_id'    => 'Sympa commands priority',
        'file'     => 'sympa.conf',
        'default'  => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'request_priority',
        'default'  => '0',
        'file'     => 'sympa.conf',
        'vhost'    => '1',
    },
    {
        'name'     => 'owner_priority',
        'default'  => '9',
        'file'     => 'sympa.conf',
        'vhost'    => '1',
    },
    {
        'name'     => 'default_list_priority',
        'gettext_id'    => 'Default priority for list messages',
        'file'     => 'sympa.conf',
        'default'  => '5',
        'vhost'    => '1',
    },

    { 'gettext_id' => 'Database related' },

    {
        'name'     => 'update_db_field_types',
        'default'  => 'auto',
    },
    {
        'name'     => 'db_type',
        'default'  => 'mysql',
        'gettext_id'    => 'Type of the database (mysql|Pg|Oracle|Sybase|SQLite)',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'Be careful to the case',
    },
    {
        'name'     => 'db_name',
        'default'  => 'sympa',
        'gettext_id'    => 'Name of the database',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'With SQLite, the name of the DB corresponds to the DB file',
    },
    {
        'name'     => 'db_host',
        'default'  => 'localhost',
        'sample'   => 'localhost',
        'gettext_id'    => 'Hostname of the database server',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'db_port',
        'default'  => undef,
        'gettext_id'    => 'Port of the database server',
        'file'     => 'sympa.conf',
        'optional' => '1',
    },
    {
        'name'     => 'db_user',
        'default'  => 'user_name',
        'sample'   => 'sympa',
        'gettext_id'    => 'User for the database connection',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'db_passwd',
        'default'  => 'user_password',
        'sample'   => 'your_passwd',
        'gettext_id'    => 'Password for the database connection',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'What ever you use a password or not, you must protect the SQL server (is it not a public internet service ?)',
    },
    {
        'name'     => 'db_timeout',
        'optional' => '1',
    },
    {
        'name'     => 'db_options',
        'optional' => '1',
    },
    {
        'name'     => 'db_env',
        'gettext_id'    => 'Environment variables setting for database',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'This is useful for defining ORACLE_HOME ',
        'optional' => '1',
    },
    {
        'name'     => 'db_additional_subscriber_fields',
        'sample'   => 'billing_delay,subscription_expiration',
        'gettext_id'    => 'Database private extention to subscriber table',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'You need to extend the database format with these fields',
        'optional' => '1',
    },
    {
        'name'     => 'db_additional_user_fields',
        'sample'   => 'age,address',
        'gettext_id'    => 'Database private extention to user table',
        'file'     => 'sympa.conf',
        'gettext_comment'   => 'You need to extend the database format with these fields',
        'optional' => '1',
    },
    {
        'name'     => 'purge_user_table_task',
        'default'  => 'monthly',
    },
    {
        'name'     => 'purge_tables_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'purge_logs_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'logs_expiration_period',
        'gettext_id'    => 'Number of months that elapse before a log is expired',
        'default'  => '3',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'purge_one_time_ticket_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'one_time_ticket_table_ttl',
        'default'  => '10d',
    },
    {
        'name'     => 'purge_session_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'session_table_ttl',
        'default'  => '2d',
    },
    {
        'name'     => 'anonymous_session_table_ttl',
        'default'  => '1h',
    },
    {
        'name'     => 'purge_challenge_table_task',
        'default'  => 'daily',
    },
    {
        'name'     => 'challenge_table_ttl',
        'default'  => '5d',
    },
    {
        'name'     => 'default_ttl',
        'gettext_id'    => 'Default timeout between two scheduled synchronizations of list members with data sources.',
        'file'     => 'sympa.conf',
        'default'  => '3600',
    },
    {
        'name'     => 'default_distribution_ttl',
        'gettext_id'    => 'Default timeout between two action-triggered synchronizations of list members with data sources.',
        'file'     => 'sympa.conf',
        'default'  => '300',
    },
    {
        'name'     => 'default_sql_fetch_timeout',
        'gettext_id'    => 'Default timeout while performing a fetch for an include_sql_query sync',
        'file'     => 'sympa.conf',
        'default'  => '300',
    },

    { 'gettext_id' => 'Loop prevention' },

    {
        'name'     => 'loop_command_max',
        'default'  => '200',
    },
    {
        'name'     => 'loop_command_sampling_delay',
        'default'  => '3600',
    },
    {
        'name'     => 'loop_command_decrease_factor',
        'default'  => '0.5',
    },
    {
        'name'     => 'loop_prevention_regex',
        'default'  => 'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
        'vhost'    => '1',
    },
    {
        'name'     => 'msgid_table_cleanup_ttl',
        'default'  => '86400',
    },
    {
        'name'     => 'msgid_table_cleanup_frequency',
        'default'  => '3600',
    },

    { 'gettext_id' => 'S/MIME configuration' },

    {
        'name'     => 'openssl',
        'sample'   => '/usr/bin/ssl',
        'gettext_id'    => 'Path to OpenSSL',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'Sympa recognizes S/MIME if OpenSSL is installed',
        'optional' => '1',
    },
    {
        'name'     => 'capath',
        'optional' => '1',
        'sample'   => Sympa::Constants::SYSCONFDIR . '/ssl.crt',
        'gettext_id'    => 'Directory containing trusted CA certificates',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },
    {
        'name'     => 'cafile',
        'sample'   => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
        'gettext_id'    => 'File containing bundled trusted CA certificates',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },
    {
        'name'     => 'crl_dir',
        'default'  => Sympa::Constants::EXPLDIR . '/crl',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'ssl_cert_dir',
        'default'  => Sympa::Constants::EXPLDIR . '/X509-user-certs',
        'gettext_id'    => 'Directory containing user certificates',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'key_passwd',
        'sample'   => 'your_password',
        'gettext_id'    => 'Password used to crypt lists private keys',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'optional' => '1',
    },

    { 'gettext_id' => 'DKIM' },

    {
        'name'     => 'dkim_feature',
        'default'  => 'off',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_add_signature_to',
        'default'  => 'robot,list',
        'gettext_comment'   => 'Insert a DKIM signature to message from the robot, from the list or both',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_signature_apply_on',
        'default'  => 'md5_authenticated_messages,smime_authenticated_messages,dkim_authenticated_messages,editor_validated_messages',
        'gettext_comment'   => 'Type of message that is added a DKIM signature before distribution to subscribers. Possible values are "none", "any" or a list of the following keywords: "md5_authenticated_messages", "smime_authenticated_messages", "dkim_authenticated_messages", "editor_validated_messages".',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_private_key_path',
        'vhost'    => '1',
        'gettext_id'    => 'Location of the file where DKIM private key is stored',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_signer_domain',
        'vhost'    => '1',
        'gettext_id'    => 'The "d=" tag as defined in rfc 4871, default is virtual host domain name',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_selector',
        'vhost'    => '1',
        'gettext_id'    => 'The selector',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'dkim_signer_identity',
        'vhost'    => '1',
        'gettext_id'    => 'The "i=" tag as defined in rfc 4871, default is null',
        'optional' => '1',
        'file'     => 'sympa.conf',
    },

    { 'gettext_id' => 'Antivirus plug-in' },

    {
        'name'     => 'antivirus_path',
        'optional' => '1',
        'sample'   => '/usr/local/uvscan/uvscan',
        'gettext_id'    => 'Path to the antivirus scanner engine',
        'file'     => 'sympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'supported antivirus: McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall',
    },
    {
        'name'     => 'antivirus_args',
        'optional' => '1',
        'sample'   => '--secure --summary --dat /usr/local/uvscan',
        'gettext_id'    => 'Antivirus plugin command argument',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'antivirus_notify',
        'default'  => 'sender',
    },

    { 'gettext_id' => 'Tag based spam filtering' },

    {
        'name'     => 'antispam_feature',
        'default'  => 'off',
        'vhost'    => '1',
    },
    {
        'name'     => 'antispam_tag_header_name',
        'default'  => 'X-Spam-Status',
        'gettext_id'    => 'If a spam filter (like spamassassin or j-chkmail) add a smtp headers to tag spams, name of this header (example X-Spam-Status)',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'antispam_tag_header_spam_regexp',
        'default'  => '^\s*Yes',
        'gettext_id'    => 'Regexp applied on this header to verify message is a spam (example Yes)',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'antispam_tag_header_ham_regexp',
        'default'  => '^\s*No',
        'gettext_id'    => 'Regexp applied on this header to verify message is NOT a spam (example No)',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'spam_status',
        'default'  => 'x-spam-status',
        'gettext_id'    => 'Messages are supposed to be filtered by an antispam that add one more headers to messages. This parameter is used to select a special scenario in order to decide the message spam status: ham, spam or unsure. This parameter replace antispam_tag_header_name, antispam_tag_header_spam_regexp and antispam_tag_header_ham_regexp.',
        'vhost'    => '1',
        'file'     => 'sympa.conf',
        'edit'     => '1',
	'scenario' => '1',
    },

    { 'gettext_id' => 'Web interface parameters' },

    {
        'name'     => 'arc_path',
        'default'  => Sympa::Constants::ARCDIR,
        'gettext_id'    => 'Directory for storing HTML archives',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'Better if not in a critical partition',
        'vhost'     => '1',
    },
    {
        'name'     => 'archive_default_index',
        'default'  => 'thrd',
        'gettext_id'    => 'Default index organization when entering the web archive: either threaded or in chronological order',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'bounce_path',
        'default'  => Sympa::Constants::BOUNCEDIR ,
        'gettext_id'    => 'Directory for storing bounces',
        'file'     => 'wwsympa.conf',
        'gettext_comment'   => 'Better if not in a critical partition',
    },
    {
        'name'     => 'cookie_expire',
        'default'  => '0',
        'gettext_id'    => 'HTTP cookies lifetime',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'cookie_domain',
        'default'  => 'localhost',
        'gettext_id'    => 'HTTP cookies validity domain',
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
    },
    {   'name'       => 'cookie_refresh',
	'default'    => '60',
	'gettext_id' => 'Average interval to refresh HTTP session ID.',
	'file'       => 'sympa.conf', # added after migration of wwsympa.conf
    },
    {
        'name'     => 'custom_archiver',
        'optional' => '1',
        'gettext_id'    => 'Activates a custom archiver to use instead of MHonArc. The value of this parameter is the absolute path on the file system to the script of the custom archiver.',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'default_home',
        'default'  => 'home',
        'gettext_id'    => 'Type of main Web page ( lists | home )',
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'edit_list',
        'default'  => 'owner',
        'file'     => 'sympa.conf',
    },
    {
        'name'     => 'ldap_force_canonical_email',
        'default'  => '1',
        'gettext_id'    => 'When using LDAP authentication, if the identifier provided by the user was a valid email, if this parameter is set to false, then the provided email will be used to authenticate the user. Otherwise, use of the first email returned by the LDAP server will be used.',
        'file'     => 'wwsympa.conf',
        'vhost'    => '1',
    },
    {
        'name'     => 'log_facility',
        'default'  => 'LOCAL1',
        'gettext_id'    => 'Syslog facility for wwsympa, archived and bounced',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'Default is to use previously defined sympa log facility.',
    },
    {
        'name'     => 'mhonarc',
        'default'  => '/usr/bin/mhonarc',
        'gettext_id'    => 'Path to MHonArc mail2html plugin',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'This is required for HTML mail archiving',
    },
    {
        'name'     => 'one_time_ticket_lifetime',
        'default'  => '2d',
        'gettext_id'    => 'Duration before the one time tickets are expired',
    },
    {
        'name'     => 'one_time_ticket_lockout',
        'default'  => 'one_time',
        'gettext_id'    => 'Is access to the one time ticket restricted, if any users previously accessed? (one_time | remote_addr | open)',
        'edit'     => '1',
        'vhost'    => '1',
    },
    {
        'name'     => 'password_case',
        'default'  => 'insensitive',
        'gettext_id'    => 'Password case (insensitive | sensitive)',
        'file'     => 'wwsympa.conf',
        'gettext_comment'   => 'Should not be changed ! May invalid all user password',
    },
    {
        'name'     => 'review_page_size',
        'gettext_id'    => 'Default number of lines of the array displaying users in the review page',
        'vhost'    => '1',
        'default'  => 25,
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'title',
        'default'  => 'Mailing lists service',
        'gettext_id'    => 'Title of main Web page',
        'vhost'    => '1',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
    },
    {
        'name'     => 'use_html_editor',
        'gettext_id'    => 'If set to "on", users will be able to post messages in HTML using a javascript WYSIWYG editor.',
        'vhost'    => '1',
        'default'  => '0',
        'edit'     => '1',
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'html_editor_url',
        'gettext_id'    => 'URL path to the javascript file making the WYSIWYG HTML editor available.  Relative path under <static_content_url> or absolute path',
        'gettext_comment' => 'Default value is an example of TinyMCE installed under <static_content_path>/js/tinymce/.',
        'vhost'    => '1',
        'default'  => 'js/tinymce/jscripts/tiny_mce/tiny_mce.js',
        'file'     => 'sympa.conf', # added after migration of wwsympa.conf
    },
    {   'name' => 'html_editor_init',
	'gettext_id' =>
	    'Javascript excerpt that enables and configures the WYSIWYG HTML editor.',
	'vhost' => '1',
	'default' =>
	    'tinyMCE.init({mode:"exact",elements:"body",language:lang.toLowerCase()});',
	'file' => 'wwsympa.conf',
    },
    {   'name' => 'html_editor_hide',
	'gettext_id' =>
	    'Javascript excerpt that disable the WYSIWYG HTML editor.',
	'gettext_comment' =>
	    'If this is empty, HTML editor cannot be disabled.',
	'vhost'   => '1',
	'default' => 'tinyMCE.get("body").hide();',
	'file' => 'sympa.conf',    # added after migration of wwsympa.conf
    },
    {   'name' => 'html_editor_show',
	'gettext_id' =>
	    'Javascript excerpt that re-enable the WYSIWYG HTML editor.',
	'gettext_comment' =>
	    'If this is empty, HTML editor cannot be disabled.',
	'vhost'   => '1',
	'default' => 'tinyMCE.get("body").show();',
	'file' => 'sympa.conf',    # added after migration of wwsympa.conf
    },
    {
        'name'     => 'use_fast_cgi',
        'default'  => '1',
        'gettext_id'    => 'Is fast_cgi module for Apache (or Roxen) installed (0 | 1)',
        'file'     => 'wwsympa.conf',
        'edit'     => '1',
        'gettext_comment'   => 'This module provide much faster web interface',
    },
    {
        'name'     => 'viewlogs_page_size',
        'gettext_id'    => 'Default number of lines of the array displaying the log entries in the logs page',
        'vhost'    => '1',
        'default'  => 25,
        'file'     => 'wwsympa.conf',
    },
    {
        'name'     => 'your_lists_size',
        'gettext_id'    => 'Maximum number of lists listed in "Your lists" menu.  0 lists none.  negative value means unlimited.',
        'vhost'    => '1',
        'default'  => '10',
    },

    {
        'name'     => 'http_host',
        'gettext_id'    => 'URL of a virtual host',
        'sample'   => 'http://host.domain.tld',
        'default'  => 'http://host.domain.tld',
        'vhost'    => '1',
        'edit'     => '1',
        'file'     => 'sympa.conf',
    },

    { 'gettext_id' => 'NOT CATEGORIZED' },

    {
        'name'     => 'ldap_export_connection_timeout',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_dnmanager',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_host',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_name',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_password',
        'optional' => '1',
    },
    {
        'name'     => 'ldap_export_suffix',
        'optional' => '1',
    },
    {
        'name'     => 'sort',
        'default'  => 'fr,ca,be,ch,uk,edu,*,com',
    },
## Not implemented yet.
##    {   'name'     => 'chk_cert_expiration_task',
##	'optional' => '1',
##    },
##    {   'name'     => 'crl_update_task',
##	'optional' => '1',
##    },
);

