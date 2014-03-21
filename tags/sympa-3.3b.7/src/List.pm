# This module is part of ML and does all list processing functions

package List;

use strict;
require Exporter;
require 'tools.pl';
my @ISA = qw(Exporter);
my @EXPORT = qw(%list_of_lists);

=head1 CONSTRUCTOR

=item new( [PHRASE] )

 List->new();

Creates a new object which will be used for a list and
eventually loads the list if a name is given. Returns
a List object.

=back

=head1 METHODS

=over 4

=item load ( LIST )

Loads the indicated list into the object.

=item save ( LIST )

Saves the indicated list object to the disk files.

=item savestats ()

Saves updates the statistics file on disk.

=item update_stats( BYTES )

Updates the stats, argument is number of bytes, returns the next
sequence number. Does nothing if no stats.

=item send_sub_to_owner ( WHO, COMMENT )
Send a message to the list owners telling that someone
wanted to subscribe to the list.

=item send_to_editor ( MSG )

Send a Mail::Internet type object to the editor (for approval).

=item send_msg ( MSG )

Sends the Mail::Internet message to the list.

=item send_file ( FILE, USER, GECOS )

Sends the file to the USER. FILE may only be welcome for now.

=item delete_user ( ARRAY )

Delete the indicated users from the list.
 
=item get_cookie ()

Returns the cookie for a list, if available.

=item get_max_size ()

Returns the maximum allowed size for a message.

=item get_reply_to ()

Returns an array with the Reply-To values.

=item get_default_user_options ()

Returns a default option of the list for subscription.

=item get_total ()

Returns the number of subscribers to the list.

=item get_user ( USER )

Returns a hash with the informations regarding the indicated
user.

=item get_first_user ()

Returns a hash to the first user on the list.

=item get_next_user ()

Returns a hash to the next users, until we reach the end of
the list.

=item update_user ( USER, HASHPTR )

Sets the new values given in the hash for the user.

=item add_user ( USER, HASHPTR )

Adds a new user to the list. May overwrite existing
entries.

=item is_user ( USER )

Returns true if the indicated user is member of the list.
 
=item am_i ( FUNCTION, USER )

Returns true is USER has FUNCTION (owner, editor) on the
list.

=item get_state ( FLAG )

Returns the value for a flag : sig or sub.

=item may_do ( ACTION, USER )

Chcks is USER may do the ACTION for the list. ACTION can be
one of following : send, review, index, getm add, del,
reconfirm, purge.

=item is_moderated ()

Returns true if the list is moderated.

=item archive_exist ( FILE )

Returns true if the indicated file exists.

=item archive_send ( WHO, FILE )

Send the indicated archive file to the user, if it exists.

=item archive_ls ()

Returns the list of available files, if any.

=item archive_msg ( MSG )

Archives the Mail::Internet message given as argument.

=item is_archived ()

Returns true is the list is configured to keep archives of
its messages.

=item get_stats ( OPTION )

Returns either a formatted printable strings or an array whith
the statistics. OPTION can be 'text' or 'array'.

=item print_info ( FDNAME )

Print the list informations to the given file descriptor, or the
currently selected descriptor.

=cut

use Carp;

use Mail::Header;
use Mail::Internet;
use Archive;
use Language;
use Log;
use Conf;
use mail;
use Time::Local;
use MIME::Entity;
use MIME::Words;
use MIME::Parser;

## Database and SQL statement handlers
my ($dbh, $sth, @sth_stack, $use_db);

my %list_cache;
my %persistent_cache;

my %date_format = (
		   'read' => {
		       'Pg' => 'date_part(\'epoch\',%s)',
		       'mysql' => 'UNIX_TIMESTAMP(%s)',
		       'Oracle' => '((to_number(to_char(%s,\'J\')) - to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) * 86400) +to_number(to_char(%s,\'SSSSS\'))',
		       'Sybase' => 'datediff(second, "01/01/1970",%s)'
		       },
		   'write' => {
		       'Pg' => '\'epoch\'::datetime + \'%d sec\'',
		       'mysql' => 'FROM_UNIXTIME(%d)',
		       'Oracle' => 'to_date(to_char(round(%s/86400) + to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) || \':\' ||to_char(mod(%s,86400)), \'J:SSSSS\')',
		       'Sybase' => 'dateadd(second,%s,"01/01/1970")'
		       }
	       );

## Regexps for list params
my %regexp = ('email' => '(\S+|\".*\")(@\S+)',
	      'host' => '[\w\.\-]+',
	      'listname' => '[a-z0-9][a-z0-9\-\._]+',
	      'sql_query' => 'SELECT.*',
	      'scenario' => '[\w,\.\-]+',
	      'task' => '\w+'
	      );

## List parameters defaults
my %default = ('occurrence' => '0-1',
	       'length' => 25
	       );

my @param_order = qw (subject visibility info subscribe add unsubscribe del owner send editor 
		      account topics 
		      host lang web_archive archive digest available_user_options 
		      default_user_options reply_to_header reply_to forced_reply_to * 
		      welcome_return_path remind_return_path user_data_source include_file 
		      include_list include_ldap_query include_ldap_2level_query include_sql_query ttl creation update 
		      status serial);

## List parameters aliases
my %alias = ('reply-to' => 'reply_to',
	     'replyto' => 'reply_to',
	     'forced_replyto' => 'forced_reply_to',
	     'forced_reply-to' => 'forced_reply_to',
	     'custom-subject' => 'custom_subject',
	     'custom-header' => 'custom_header',
	     'subscription' => 'subscribe',
	     'unsubscription' => 'unsubscribe',
	     'max-size' => 'max_size');

##############################################################
## This hash COMPLETELY defines ALL list parameters     
## It is then used to load, save, view, edit list config files
##############################################################
## List parameters format accepts the following keywords :
## format :      Regexp aplied to the configuration file entry; 
##               some common regexps are defined in %regexp
## file_format : Config file format of the parameter might not be
##               the same in memory
## split_char:   Character used to separate multiple parameters 
## length :      Length of a scalar variable ; used in web forms
## scenario :    tells that the parameter is a scenario, providing its name
## default :     Default value for the param ; may be a configuration parameter (conf)
## synonym :     Defines synonyms for parameter values (for compatibility reasons)
## unit :        Unit of the parameter ; this is used in web forms
## occurrence :  Occurerence of the parameter in the config file
##               possible values: 0-1 | 1 | 0-n | 1-n
##               example : a list may have multiple owner 
## title_id :    Title reference in NLS catalogues
## group :       Group of parameters
## obsolete :    Obsolete parameter ; should not be displayed 
##               nor saved
## order :       Order of parameters within paragraph
###############################################################
%::pinfo = ('account' => {'format' => '\S+',
			  'length' => 10,
			  'title_id' => 1,
			  'group' => 'other'
			  },
	    'add' => {'scenario' => 'add',
		      'title_id' => 2,
		      'group' => 'command'
		      },
	    'anonymous_sender' => {'format' => '.+',
				   'title_id' => 3,
				   'group' => 'tuning'
				   },
	    'archive' => {'format' => {'period' => {'format' => ['day','week','month','quarter','year'],
						    'synonym' => {'weekly' => 'week'},
						    'title_id' => 5,
						    'order' => 1
						},
				       'access' => {'format' => ['open','private','public','owner','closed'],
						    'synonym' => {'open' => 'public'},
						    'title_id' => 6,
						    'order' => 2
						}
				   },
			  'title_id' => 4,
			  'group' => 'archives'
		      },
	    'available_user_options' => {'format' => {'reception' => {'format' => ['mail','notice','digest','summary','nomail','txt','html','urlize','not_me'],
								      'occurrence' => '1-n',
								      'split_char' => ',',
								      'default' => 'mail,notice,digest,summary,nomail,txt,html,urlize,not_me',
								      'title_id' => 89
								      }
						  },
					 'title_id' => 88
				     },

	    'bounce' => {'format' => {'warn_rate' => {'format' => '\d+',
						      'length' => 3,
						      'unit' => '%',
						      'default' => {'conf' => 'bounce_warn_rate'},
						      'title_id' => 8,
						      'order' => 1
						  },
				      'halt_rate' => {'format' => '\d+',
						      'length' => 3,
						      'unit' => '%',
						      'default' => {'conf' => 'bounce_halt_rate'},
						      'title_id' => 9,
						      'order' => 2
						  }
				  },
			 'title_id' => 7,
			 'group' => 'bounces'
		     },
	    'clean_delay_queuemod' => {'format' => '\d+',
				       'length' => 3,
				       'unit' => 'days',
				       'default' => {'conf' => 'clean_delay_queuemod'},
				       'title_id' => 10,
				       'group' => 'other'
				       },
	    'cookie' => {'format' => '\S+',
			 'length' => 15,
			 'default' => {'conf' => 'cookie'},
			 'title_id' => 11,
			 'group' => 'other'
		     },
	    'creation' => {'format' => {'date_epoch' => {'format' => '\d+',
							 'occurrence' => '1',
							 'title_id' => 13,
							 'order' => 3
						     },
					'date' => {'format' => '.+',
						   'title_id' => 14,
						   'order' => 2
						   },
					'email' => {'format' => $regexp{'email'},
						    'occurrence' => '1',
						    'title_id' => 15,
						    'order' => 1
						    }
				    },
			   'title_id' => 12,
			   'group' => 'other'

		       },
	    'custom_header' => {'format' => '\S+:\s+.*',
				'length' => 30,
				'occurrence' => '0-n',
				'title_id' => 16,
				'group' => 'tuning'
				},
	    'custom_subject' => {'format' => '.*',
				 'length' => 15,
				 'title_id' => 17,
				 'group' => 'tuning'
				 },
	    'default_user_options' => {'format' => {'reception' => {'format' => ['digest','mail','nomail','summary','notice','txt','html','urlize','not_me'],
								    'default' => 'mail',
								    'title_id' => 19,
								    'order' => 1
								    },
						    'visibility' => {'format' => ['conceal','noconceal'],
								     'default' => 'noconceal',
								     'title_id' => 20,
								     'order' => 2
								     }
						},
				       'title_id' => 18,
				       'group' => 'other'
				   },
	    'del' => {'scenario' => 'del',
		      'title_id' => 21,
		      'group' => 'command'
		      },
	    'digest' => {'file_format' => '\d+(\s*,\s*\d+)*\s+\d+:\d+',
			 'format' => {'days' => {'format' => [1..7],
						 'file_format' => '1|2|3|4|5|6|7',
						 'occurrence' => '1-n',
						 'title_id' => 23,
						 'order' => 1
						 },
				      'hour' => {'format' => '\d+',
						 'length' => 2,
						 'occurrence' => '1',
						 'title_id' => 24,
						 'order' => 2
						 },
				      'minute' => {'format' => '\d+',
						   'length' => 2,
						   'occurrence' => '1',
						   'title_id' => 25,
						   'order' => 3
						   }
				  },
			 'title_id' => 22,
			 'group' => 'tuning'
		     },

	    'editor' => {'format' => {'email' => {'format' => $regexp{'email'},
						  'length' => 30,
						  'occurrence' => '1',
						  'title_id' => 27,
						  'order' => 1
						  },
				      'reception' => {'format' => ['mail','nomail'],
						      'default' => 'mail',
						      'title_id' => 28,
						      'order' => 4
						      },
				      'gecos' => {'format' => '.+',
						  'length' => 30,
						  'title_id' => 29,
						  'order' => 2
						  },
				      'info' => {'format' => '.+',
						 'length' => 30,
						 'title_id' => 30,
						 'order' => 3
						 }
				  },
			 'occurrence' => '0-n',
			 'title_id' => 26,
			 'group' => 'description'
			 },
	    'expire_task' => {'task' => 'expire',
			      'title_id' => 95
			 },
	    'footer_type' => {'format' => ['mime','append'],
			      'default' => 'mime',
			      'title_id' => 31,
			      'group' => 'tuning'
			      },
	    'forced_reply_to' => {'format' => '\S+',
				  'title_id' => 32,
				  'group' => 'tuning',
				  'obsolete' => 1
			 },
	    'host' => {'format' => $regexp{'host'},
		       'length' => 20,
		       'title_id' => 33,
		       'group' => 'description'
		   },
	    'include_file' => {'format' => '\S+',
			       'length' => 20,
			       'occurrence' => '0-n',
			       'title_id' => 34,
			       'group' => 'data_source'
			       },

#	    'include_admin' => {'format' => ['owners','editors','privileged_owners'],
#				 'occurrence' => '0-n'
#				 },

	    'include_ldap_query' => {'format' => {'host' => {'format' => $regexp{'host'},
							     'occurrence' => '1',
							     'title_id' => 36,
							     'order' => 1
							     },
						  'port' => {'format' => '\d+',
							     'default' => 389,
							     'length' => 4,
							     'title_id' => 37,
							     'order' => 2
							     },
						  'user' => {'format' => '.*',
							     'title_id' => 38,
							     'order' => 3
							     },
						  'passwd' => {'format' => '.*',
							       'length' => 10,
							       'title_id' => 39,
							       'order' => 3
							       },
						  'suffix' => {'format' => '.*',
							       'title_id' => 40,
							       'order' => 4
							       },
						  'filter' => {'format' => '.*',
							       'length' => 50,
							       'occurrence' => '1',
							       'title_id' => 41,
							       'order' => 7
							       },
						  'attrs' => {'format' => '\w+',
							      'length' => 15,
							      'default' => 'mail',
							      'title_id' => 42,
							      'order' => 8
							      },
						  'select' => {'format' => ['all','first'],
							       'default' => 'first',
							       'title_id' => 43,
							       'order' => 9
							       },
					          'scope' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'title_id' => 97,
							      'order' => 5
							      },
						  'timeout' => {'format' => '\w+',
								'default' => 30,
								'unit' => 'seconds',
								'title_id' => 98,
								'order' => 6
								}
					      },
				     'occurrence' => '0-n',
				     'title_id' => 35,
				     'group' => 'data_source'
				     },
	    'include_ldap_2level_query' => {'format' => {'host' => {'format' => $regexp{'host'},
							     'occurrence' => '1',
							     'title_id' => 136,
							     'order' => 1
							     },
						  'port' => {'format' => '\d+',
							     'default' => 389,
							     'length' => 4,
							     'title_id' => 137,
							     'order' => 2
							     },
						  'user' => {'format' => '.*',
							     'title_id' => 138,
							     'order' => 3
							     },
						  'passwd' => {'format' => '.*',
							       'length' => 10,
							       'title_id' => 139,
							       'order' => 3
							       },
						  'suffix1' => {'format' => '.*',
							       'title_id' => 140,
							       'order' => 4
							       },
						  'filter1' => {'format' => '.*',
							       'length' => 50,
							       'occurrence' => '1',
							       'title_id' => 141,
							       'order' => 7
							       },
						  'attrs1' => {'format' => '\w+',
							      'length' => 15,
							      'default' => 'mail',
							      'title_id' => 142,
							      'order' => 8
							      },
						  'select1' => {'format' => ['all','first','regex'],
							       'default' => 'first',
							       'title_id' => 143,
							       'order' => 9
							       },
					          'scope1' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'title_id' => 197,
							      'order' => 5
							      },
						  'timeout1' => {'format' => '\w+',
								'default' => 30,
								'unit' => 'seconds',
								'title_id' => 198,
								'order' => 6
								},
						  'regex1' => {'format' => '.+',
								'length' => 50,
								'default' => '',
								'title_id' => 201,
								'order' => 10
								},
						  'suffix2' => {'format' => '.*',
							       'title_id' => 144,
							       'order' => 11
							       },
						  'filter2' => {'format' => '.*',
							       'length' => 50,
							       'occurrence' => '1',
							       'title_id' => 145,
							       'order' => 14
							       },
						  'attrs2' => {'format' => '\w+',
							      'length' => 15,
							      'default' => 'mail',
							      'title_id' => 146,
							      'order' => 15
							      },
						  'select2' => {'format' => ['all','first','regex'],
							       'default' => 'first',
							       'title_id' => 147,
							       'order' => 16
							       },
					          'scope2' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'title_id' => 199,
							      'order' => 12
							      },
						  'timeout2' => {'format' => '\w+',
								'default' => 30,
								'unit' => 'seconds',
								'title_id' => 200,
								'order' => 13
								},
						  'regex2' => {'format' => '.+',
								'length' => 50,
								'default' => '',
								'title_id' => 201,
								'order' => 17
								}
					      },
				     'occurrence' => '0-n',
				     'title_id' => 135,
				     'group' => 'data_source'
				     },
	    'include_list' => {'format' => $regexp{'listname'},
			       'occurrence' => '0-n',
			       'title_id' => 44,
			       'group' => 'data_source'
			       },
	    'include_sql_query' => {'format' => {'db_type' => {'format' => ['mysql','Pg','Oracle','Sybase'],
							       'occurrence' => '1',
							       'title_id' => 46,
							       'order' => 1
							       },
						 'host' => {'format' => $regexp{'host'},
							    'occurrence' => '1',
							    'title_id' => 47,
							    'order' => 2
							    },
						 'db_name' => {'format' => '\S+',
							       'occurrence' => '1',
							       'title_id' => 48,
							       'order' => 3 
							       },
						 'connect_options' => {'format' => '.+',
								       'title_id' => 94,
								       'order' => 4
								       },
						 'user' => {'format' => '\S+',
							    'occurrence' => '1',
							    'title_id' => 49,
							    'order' => 5
							    },
						 'passwd' => {'format' => '.+',
							      'title_id' => 50,
							      'order' => 6
							      },
						 'sql_query' => {'format' => $regexp{'sql_query'},
								 'length' => 50,
								 'occurrence' => '1',
								 'title_id' => 51,
								 'order' => 7
								 },
						 'f_dir' => {'format' => '.+',
							     'title_id' => 52,
							     'order' => 8
							     }
					     },
				    'occurrence' => '0-n',
				    'title_id' => 45,
				    'group' => 'data_source'
				    },
	    'info' => {'scenario' => 'info',
		       'title_id' => 53,
		       'group' => 'command'
		       },
	    'invite' => {'scenario' => 'invite',
			 'title_id' => 54,
			 'group' => 'command'
			 },
	    'lang' => {'format' => ['fr','us','de','it','fi','es','tw','cn','pl','cz','hu'],
		       'default' => {'conf' => 'lang'},
		       'title_id' => 55,
		       'group' => 'description'
		   },
	    'max_size' => {'format' => '\d+',
			   'length' => 8,
			   'unit' => 'bytes',
			   'default' => {'conf' => 'max_size'},
			   'title_id' => 56,
			   'group' => 'tuning'
		       },
	    'owner' => {'format' => {'email' => {'format' => $regexp{'email'},
						 'length' =>30,
						 'occurrence' => '1',
						 'title_id' => 58,
						 'order' => 1
						 },
				     'reception' => {'format' => ['mail','nomail'],
						     'default' => 'mail',
						     'title_id' => 59,
						     'order' =>5
						     },
				     'gecos' => {'format' => '.+',
						 'length' => 30,
						 'title_id' => 60,
						 'order' => 2
						 },
				     'info' => {'format' => '.+',
						'length' => 30,
						'title_id' => 61,
						'order' => 3
						},
				     'profile' => {'format' => ['privileged','normal'],
						   'default' => 'normal',
						   'title_id' => 62,
						   'order' => 4
						   }
				 },
			'occurrence' => '1-n',
			'title_id' => 57,
			'group' => 'description'
			},
	    'priority' => {'format' => [0..9,'z'],
			   'length' => 1,
			   'default' => {'conf' => 'default_list_priority'},
			   'title_id' => 63,
			   'group' => 'tuning'
		       },
	    'remind' => {'scenario' => 'remind',
			 'title_id' => 64,
			 'group' => 'command'
			  },
	    'remind_return_path' => {'format' => ['unique','owner'],
				     'default' => {'conf' => 'remind_return_path'},
				     'title_id' => 65,
				     'group' => 'bounces'
				 },
	    'remind_task' => {'task' => 'remind',
			      'tilte-id' => 96
			      },
	    'reply_to' => {'format' => '\S+',
			   'default' => 'sender',
			   'title_id' => 66,
			   'group' => 'tuning',
			   'obsolete' => 1
			   },
	    'reply_to_header' => {'format' => {'value' => {'format' => ['sender','list','all','other_email'],
							   'default' => 'sender',
							   'title_id' => 91,
							   'occurrence' => '1',
							   'order' => 1
							   },
					       'other_email' => {'format' => $regexp{'email'},
								 'title_id' => 92,
								 'order' => 2
								 },
					       'apply' => {'format' => ['forced','respect'],
							   'default' => 'respect',
							   'title_id' => 93,
							   'order' => 3
							   }
					   },
				  'title_id' => 90,
				  'group' => 'tuning'
				  },		
	    'review' => {'scenario' => 'review',
			 'synonym' => {'open' => 'public'},
			 'title_id' => 67,
			 'group' => 'command'
			 },
	    'send' => {'scenario' => 'send',
		       'title_id' => 68
		       },
	    'serial' => {'format' => '\d+',
			 'default' => 0,
			 'length' => 3,
			 'default' => 0,
			 'title_id' => 69,
			 'group' => 'other'
			 },
	    'shared_doc' => {'format' => {'d_read' => {'scenario' => 'd_read',
						       'title_id' => 86,
						       'order' => 1
						       },
					  'd_edit' => {'scenario' => 'd_edit',
						       'title_id' => 87,
						       'order' => 2
						       }
				      },
			     'title_id' => 70,
			     'group' => 'command'
			 },
	    'status' => {'format' => ['open','closed','pending'],
			 'default' => 'open',
			 'title_id' => 71,
			 'group' => 'other'
			  },
	    'subject' => {'format' => '.+',
			  'length' => 50,
			  'occurrence' => '1',
			  'title_id' => 72,
			  'group' => 'description'
			   },
	    'subscribe' => {'scenario' => 'subscribe',
			    'title_id' => 73,
			    'group' => 'command'
			    },
	    'topics' => {'format' => '\w+(\/\w+)?',
			 'split_char' => ',',
			 'occurrence' => '0-n',
			 'title_id' => 74,
			 'group' => 'description'
			 },
	    'ttl' => {'format' => '\d+',
		      'length' => 6,
		      'unit' => 'seconds',
		      'default' => 3600,
		      'title_id' => 75,
		      'group' => 'data_source'
		      },
	    'unsubscribe' => {'scenario' => 'unsubscribe',
			      'title_id' => 76,
			      'group' => 'command'
			      },
	    'update' => {'format' => {'date_epoch' => {'format' => '\d+',
						       'length' => 8,
						       'occurrence' => '1',
						       'title_id' => 78,
						       'order' => 3
						       },
				      'date' => {'format' => '.+',
						 'length' => 30,
						 'title_id' => 79,
						 'order' => 2
						 },
				      'email' => {'format' => $regexp{'email'},
						  'length' => 30,
						  'occurrence' => '1',
						  'title_id' => 80,
						  'order' => 1
						  }
				  },
			 'title_id' => 77,
			 'group' => 'other'
		     },
	    'user_data_source' => {'format' => ['database','file','include'],
				   'default' => 'file',
				   'title_id' => 81,
				   'group' => 'data_source'
				   },
	    'visibility' => {'scenario' => 'visibility',
			     'synonym' => {'public' => 'noconceal'},
			     'title_id' => 82,
			     'group' => 'description'
			     },
	    'web_archive'  => {'format' => {'access' => {'scenario' => 'access_web_archive',
							 'title_id' => 84
							 }
					},
			       'title_id' => 83,
			       'group' => 'archives'

			   },
	    'welcome_return_path' => {'format' => ['unique','owner'],
				      'default' => {'conf' => 'welcome_return_path'},
				      'title_id' => 85,
				      'group' => 'bounces'
				  },
	    
	    'export' => {'format' => '\w+',
			 'split_char' => ',',
			 'occurrence' => '0-n',
			 'default' =>'',
		     }
	    
	    );

## This is the generic hash which keeps all lists in memory.
my %list_of_lists = ();
my %list_of_robots = ();
my %list_of_topics = ();
my %edit_list_conf = ();

## Last modification times
my %mtime;

use Fcntl;
use DB_File;

$DB_BTREE->{compare} = '_compare_addresses';

sub LOCK_SH {1};
sub LOCK_EX {2};
sub LOCK_NB {4};
sub LOCK_UN {8};

## Connect to Database
sub db_connect {
    do_log('debug2', 'List::db_connect');

    my $connect_string;

    unless (require DBI) {
	do_log ('info',"Unable to use DBI library, install DBI (CPAN) first");
	return undef;
    }

    ## Do we have db_xxx required parameters
    foreach my $db_param ('db_type','db_name','db_host','db_user') {
	unless ($Conf{$db_param}) {
	    do_log ('info','Missing parameter %s for DBI connection', $db_param);
	    return undef;
	}
    }

    ## Used by Oracle (ORACLE_HOME)
    if ($Conf{'db_env'}) {
	foreach my $env (keys %{$Conf{'db_env'}}) {
	    $ENV{$env} = $Conf{'db_env'}{$env};
	}
    }

    if ($Conf{'db_type'} eq 'Oracle') {
	## Oracle uses sids instead of dbnames
	$connect_string = sprintf 'DBI:%s:sid=%s;host=%s', $Conf{'db_type'}, $Conf{'db_name'}, $Conf{'db_host'};

    }elsif ($Conf{'db_type'} eq 'Sybase') {
	$connect_string = sprintf 'DBI:%s:dbname=%s;server=%s', $Conf{'db_type'}, $Conf{'db_name'}, $Conf{'db_host'};

    }else {
	$connect_string = sprintf 'DBI:%s:dbname=%s;host=%s', $Conf{'db_type'}, $Conf{'db_name'}, $Conf{'db_host'};
    }

    if ($Conf{'db_port'}) {
	$connect_string .= ';port=' . $Conf{'db_port'};
    }

    if ($Conf{'db_options'}) {
	$connect_string .= ';' . $Conf{'db_options'};
    }

    unless ( $dbh = DBI->connect($connect_string, $Conf{'db_user'}, $Conf{'db_passwd'}) ) {
	do_log ('err','Can\'t connect to Database %s as %s', $connect_string, $Conf{'db_user'});

	&send_notify_to_listmaster('no_db', $Conf{'domain'});
	&fatal_err('Sympa cannot connect to database %s, dying', $Conf{'db_name'});

#	return undef;
    }

    if ($Conf{'db_type'} eq 'Pg') { # Configure Postgres to use ISO format dates
       $dbh->do ("SET DATESTYLE TO 'ISO';");
    }

    ## added sybase support
    if ($Conf{'db_type'} eq 'Sybase') { # Configure to use sympa database 
	my $dbname;
	$dbname="use $Conf{'db_name'}";
        $dbh->do ($dbname);
    }

    do_log('debug','Connected to Database %s',$Conf{'db_name'});

    return 1;
}

## Disconnect from Database
sub db_disconnect {
    do_log('debug2', 'List::db_disconnect');

    unless ($dbh->disconnect()) {
	do_log ('notice','Can\'t disconnect from Database %s : %s',$Conf{'db_name'}, $dbh->errstr);
	return undef;
    }

    return 1;
}

## Get database handler
sub db_get_handler {
    do_log('debug2', 'List::db_get_handler');


    return $dbh;
}

## Creates an object.
sub new {
    my($pkg, $name) = @_;
    my $liste={};
    do_log('debug2', 'List::new(%s)', $name);

    ## Only process the list if the name is valid.
    unless ($name and ($name =~ /^[a-z0-9][a-z0-9\-\+\._]*$/io) ) {
	&do_log('info', 'Incorrect listname "%s"',  $name);
	return undef;
    }
    ## Lowercase the list name.
    $name =~ tr/A-Z/a-z/;
    
    if ($list_of_lists{$name}){
	# use the current list in memory and update it
	$liste=$list_of_lists{$name};
    }else{
	do_log('debug', 'List object %s creation', $name) if $main::options{'debug'}; ##TEMP

	# create a new object list
	bless $liste, $pkg;
    }
    return undef unless ($liste->load($name));

    return $liste;
}

## Saves the statistics data to disk.
sub savestats {
    my $self = shift;
    do_log('debug2', 'List::savestats');
   
    ## Be sure the list has been loaded.
    my $name = $self->{'name'};
    my $dir = $self->{'dir'};
    return undef unless ($list_of_lists{$name});
    
   _save_stats_file("$dir/stats", $self->{'stats'}, $self->{'total'});
    
    ## Changed on disk
    $self->{'mtime'}[2] = time;

    return 1;
}

## Update the stats struct 
## Input  : num of bytes of msg
## Output : num of msgs sent
sub update_stats {
    my($self, $bytes) = @_;
    do_log('debug2', 'List::update_stats(%d)', $bytes);

    my $stats = $self->{'stats'};
    $stats->[0]++;
    $stats->[1] += $self->{'total'};
    $stats->[2] += $bytes;
    $stats->[3] += $bytes * $self->{'total'};
    return $stats->[0];
}

## Dumps a copy of lists to disk, in text format
sub dump {
    my @listnames = @_;
    do_log('debug2', 'List::dump(%s)', @listnames);

    foreach my $l (@listnames) {
	
	my $list = new List($l);
	my $user_file_name;
	
	if ($list->{'admin'}{'user_data_source'} eq 'database') {
            do_log('debug', 'Dumping list %s',$l);
	    $user_file_name = "$list->{'dir'}/subscribers.db.dump";
	    $list->_save_users_file($user_file_name);
	    $list->{'mtime'} = [ (stat("$list->{'dir'}/config"))[9], (stat("$list->{'dir'}/subscribers"))[9], (stat("$list->{'dir'}/stats"))[9] ];
	}elsif ($list->{'admin'}{'user_data_source'} eq 'include') {
            do_log('debug', 'Dumping list %s',$l);
	    $user_file_name = "$list->{'dir'}/subscribers.incl.dump";
	    $list->_save_users_file($user_file_name);
	    $list->{'mtime'} = [ (stat("$list->{'dir'}/config"))[9], (stat("$list->{'dir'}/subscribers"))[9], (stat("$list->{'dir'}/stats"))[9] ];
	} 

    }
    return 1;
}

## Saves a copy of the list to disk. Does not remove the
## data.
sub save {
    my $self = shift;
    do_log('debug2', 'List::save');

    my $name = $self->{'name'};    
 
    return undef 
	unless ($list_of_lists{$name});
 
    my $user_file_name;

    if ($self->{'admin'}{'user_data_source'} eq 'file') {
	$user_file_name = "$self->{'dir'}/subscribers";

        unless ($self->_save_users_file($user_file_name)) {
	    &do_log('info', 'unable to save user file %s', $user_file_name);
	    return undef;
	}
        $self->{'mtime'} = [ (stat("$self->{'dir'}/config"))[9], (stat("$self->{'dir'}/subscribers"))[9], (stat("$self->{'dir'}/stats"))[9] ];
    }
    
    return 1;
}

## Saves the configuration file to disk
sub save_config {
    my ($self, $email) = @_;
    do_log('debug2', 'List::save_config()');

    my $name = $self->{'name'};    
    my $old_serial = $self->{'admin'}{'serial'};
    my $config_file_name = "$self->{'dir'}/config";
    my $old_config_file_name = "$self->{'dir'}/config.$old_serial";

    return undef 
	unless ($list_of_lists{$name});
 
    ## Update management info
    $self->{'admin'}{'serial'}++;
    $self->{'admin'}{'defaults'}{'serial'} = 0;
    $self->{'admin'}{'update'} = {'email' => $email,
				  'date_epoch' => time,
				  'date' => &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time))
				  };
    $self->{'admin'}{'defaults'}{'update'} = 0;
    
    unless (&_save_admin_file($config_file_name, $old_config_file_name, $self->{'admin'})) {
	&do_log('info', 'unable to save config file %s', $config_file_name);
	return undef;
    }
#    $self->{'mtime'}[0] = (stat("$list->{'dir'}/config"))[9];
    
    return 1;
}

## Loads the administrative data for a list
sub load {
    my ($self, $name) = @_;
    do_log('debug2', 'List::load(%s)', $name);
    
    my $users;
    my $robot;
#    foreach my $r (&get_robots) {
    foreach my $r (keys %{$Conf{'robots'}}) {
	if ((-d "$Conf{'home'}/$r/$name") && (-f "$Conf{'home'}/$r/$name/config")) {
	    $robot=$r;
	    last;
	}
    }
    if ($robot) {
	$self->{'domain'} = $robot ;
	$self->{'dir'} = "$Conf{'home'}/$robot/$name";
    }elsif((!($robot)) && (-d "$Conf{'home'}/$name") && (-f "$Conf{'home'}/$name/config")) {
	$self->{'domain'} = $Conf{'host'};
	$self->{'dir'} = "$Conf{'home'}/$name";
    }else{
	&do_log('info', 'No such list %s', $name);
	return undef ;
    }    

    $self->{'name'}  = $name ;

    
    my $m1 = (stat("$self->{'dir'}/config"))[9];
    my $m2; $m2 = (stat("$self->{'dir'}/subscribers"))[9] if (-f "$self->{'dir'}/subscribers");
    my $m3 = (stat("$self->{'dir'}/stats"))[9];
    
    my $admin;
    
    if ($self->{'name'} ne $name || $m1 > $self->{'mtime'}->[0]) {
	$admin = _load_admin_file($self->{'dir'}, $self->{'domain'}, 'config');
    }
    
    $self->{'admin'} = $admin if ($admin);
    
    # default list host is robot domain
    $self->{'admin'}{'host'} ||= $self->{'domain'};
    # uncomment the following line if you want virtual robot to overwrite list->host
    # $self->{'admin'}{'host'} = $self->{'domain'} if ($self->{'domain'} ne $Conf{'host'});


    $self->{'as_x509_cert'} = 1  if (-r "$self->{'dir'}/cert.pem");
    

    
    ## Only load total of users from a Database
    if ($self->{'admin'}{'user_data_source'} eq 'database') {
#	$users->{'total'} = _load_total_db($name)
#	    unless (defined $self->{'total'});
    }elsif($self->{'admin'}->{'user_data_source'} eq 'file') { 
	
	## Touch subscribers file if not exists
	unless ( -r "$self->{'dir'}/subscribers") {
	    open L, ">$self->{'dir'}/subscribers" or return undef;
	    close L;
	    do_log('info','No subscribers file, creating %s',"$self->{'dir'}/subscribers");
	}

	if ($self->{'name'} ne $name || $m2 > $self->{'mtime'}[1]) {
	    $users = _load_users("$self->{'dir'}/subscribers");
	    $m2 = (stat("$self->{'dir'}/subscribers"))[9];
	}
    }elsif($self->{'admin'}{'user_data_source'} eq 'include') {

    ## include other subscribers as defined in include directives (list|ldap|sql|file|owners|editors)
	unless ( defined $self->{'admin'}{'include_file'}
		 || defined $self->{'admin'}{'include_list'}
		 || defined $self->{'admin'}{'include_sql_query'}
		 || defined $self->{'admin'}{'include_ldap_query'}
		 || defined $self->{'admin'}{'include_ldap_2level_query'}
#		 || defined $self->{'admin'}{'include_admin'}
		 ) {
	    &do_log('notice', 'Include paragraph missing in configuration file');
	    return undef;
	}

	my $last_include = (stat("$self->{'dir'}/subscribers.db"))[9];

	$m2 = $self->{'mtime'}->[1]; 
	## Update 'subscriber.db'
	if ( ## 'config' is more recent than 'subscribers.db'
	     ($m1 > $last_include) || 
	     ## 'ttl'*2 is NOT over
	     (time > ($last_include + $self->{'admin'}{'ttl'} * 2)) ||
	     ## 'ttl' is over AND not Web context
	     ((time > ($last_include + $self->{'admin'}{'ttl'})) &&
	      !($ENV{'HTTP_HOST'} && (-f "$self->{'dir'}/subscribers.db")))) {
	    
	    $users = _load_users_include($name, $self->{'admin'}, "$self->{'dir'}/subscribers.db", 0);
	    unless (defined $users) {
		return undef;
	    }

	    $m2 = time;
	}elsif (## First new()
		! $self->{'users'} ||
		## 'subscribers.db' is more recent than 'config'
		($last_include > $m1)) {
	    ## Use cache
	    $users = _load_users_include($name, $self->{'admin'}, "$self->{'dir'}/subscribers.db", 1);

	    unless (defined $users) {
		return undef;
	    }
	}
	
    }else { 
	do_log ('notice','Wrong value for user_data_source');
	return undef;
    }
    
## Load stats file if first new() or stats file changed
    my ($stats, $total);
    ($stats, $total) = _load_stats_file("$self->{'dir'}/stats");
    
    $self->{'stats'} = $stats if ($stats);
    $self->{'users'} = $users->{'users'} if ($users);
    $self->{'ref'}   = $users->{'ref'} if ($users);
        
#    my $previous_total = $self->{'total'};
    if ($users && defined($users->{'total'})) {
	$self->{'total'} = $users->{'total'};
    }elsif ($total) {
	$self->{'total'} = $total;
    }

    $self->{'mtime'} = [ $m1, $m2, $m3 ];

    $list_of_lists{$name} = $self;
    return $self;
}

## Alert owners
sub send_alert_to_owner {
    my($self, $alert, $data) = @_;
    do_log('debug2', 'List::send_alert_to_owner(%s)', $alert);
 
    my ($i, @rcpt);
    my $admin = $self->{'admin'}; 
    my $name = $self->{'name'};
    my $host = $admin->{'host'};

    return unless ($name && $admin);
    
    foreach $i (@{$admin->{'owner'}}) {
	next if ($i->{'reception'} eq 'nomail');
	push(@rcpt, $i->{'email'}) if ($i->{'email'});
    }

    unless (@rcpt) {
	do_log('notice', 'Warning : no owner defined or  all of them use nomail option in list %s', $name );
	return undef;
    }

    my $to = sprintf (Msg(8, 1, "Owners of list %s :"), $name)." <$name-request\@$host>";

    if ($alert eq 'bounce_rate') {
	my $rate = int ($data->{'rate'} * 10) / 10;

	my $subject = sprintf(Msg(8, 28, "WARNING: bounce rate too high in list %s"), $name);
	my $body = sprintf Msg(8, 27, "Bounce rate in list %s is %d%%.\nYou should delete bouncing subscribers : %s/reviewbouncing/%s"), $name, $rate, $Conf{'wwsympa_url'}, $name ;
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);
    }else {
	do_log('info', 'Unknown alert %s', $alert);
    }
    
    return 1;
}

## Send a sub/sig notice to the owners.
sub send_notify_to_listmaster {
    my ($operation, $robot, @param) = @_;
    do_log('debug2', 'List::send_notify_to_listmaster(%s,%s )', $operation, $robot );

    ## No DataBase
    if ($operation eq 'no_db') {
        my $body = "Cannot connect to database $Conf{'db_name'}, Sympa dying." ; 
	my $to = sprintf "Listmaster <%s>", $Conf{'listmaster'};
	mail::mailback (\$body, {'Subject' => 'No DataBase'}, 'sympa', $to, $robot, $Conf{'listmaster'});

    ## creation list requested
    }elsif ($operation eq 'request_list_creation') {
	my $list = new List $param[0];

	$list->send_file('listmaster_notification', $Conf{'listmaster'}, $robot,
			 {'to' => "listmaster\@$Conf{'host'}",
			  'type' => 'request_list_creation',
			  'email' => $param[1]});

    ## Loop detected in Sympa
    }elsif ($operation eq 'loop_command') {
	my $file = $param[0];

	my $notice = build MIME::Entity (From => $Conf{'sympa'},
					 To => $Conf{'listmaster'},
					 Subject => 'Loop detected',
					 Data => 'A loop has been detected with the following message');

	$notice->attach(Path => $file,
			Type => 'message/rfc822');

	## Send message
	my $rcpt = $Conf{'listmaster'};
	*FH = &smtp::smtpto($Conf{'request'}, \$rcpt);
	$notice->print(\*FH);
	close FH;
    }elsif ($operation eq 'virus_scan_failed') {
	&send_global_file('listmaster_notification', $Conf{'listmaster'}, $robot,
			 {'to' => "listmaster\@$Conf{'host'}",
			  'type' => 'virus_scan_failed',
			  'filename' => $param[0],
			  'error_msg' => $param[1]});	
    }else {
	my $data = {'to' => "listmaster\@$Conf{'host'}",
		 'type' => $operation
		 };
	
	for my $i(0..$#param) {
	    $data->{"param$i"} = $param[$i];
	}

	&send_global_file('listmaster_notification', $Conf{'listmaster'}, $robot, $data);
    }
    
    return 1;
}

## Send a sub/sig notice to the owners.
sub send_notify_to_owner {
    my($self, $who, $gecos, $operation, $by) = @_;
    do_log('debug2', 'List::send_notify_to_owner(%s, %s, %s, %s)', $who, $gecos, $operation, $by);
    
    my ($i, @rcpt);
    my $admin = $self->{'admin'}; 
    my $name = $self->{'name'};
    my $host = $admin->{'host'};

    return unless ($name && $admin && $who);
    
    foreach $i (@{$admin->{'owner'}}) {
	next if ($i->{'reception'} eq 'nomail');
	push(@rcpt, $i->{'email'}) if ($i->{'email'});
    }

    ## Use list lang
    &Language::SetLang($self->{'admin'}{'lang'});

    unless (@rcpt) {
	do_log('notice', 'Warning : no owner defined or  all of them use nomail option in list %s', $name );
	return undef;
    }

    my $to = sprintf (Msg(8, 1, "Owners of list %s :"), $name)." <$name-request\@$host>";

    if ($operation eq 'warn-signoff') {
	my ($body, $subject);
	$subject = sprintf (Msg(8, 21, "WARNING: %s list %s from %s %s"), $operation, $name, $who, $gecos);
	$body = sprintf (Msg(8, 23, "WARNING : %s %s failed to signoff from %s\nbecause his address was not found in the list\n (You may help this person)\n"),$who, $gecos, $name);
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);
    }else {
	my ($body, $subject);
	$subject = sprintf(Msg(8, 21, "FYI: %s list %s from %s %s"), $operation, $name, $who, $gecos);
	if ($by) {
	    $body = sprintf Msg(8, 26, "FYI command %s list %s from %s %s validated by %s\n (no action needed)\n"),$operation, $name, $who, $gecos, $by;
	}else {
	    $body = sprintf Msg(8, 22, "FYI command %s list %s from %s %s \n (no action needed)\n"),$operation, $name, $who, $gecos ;
	}
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to,$self->{'domain'}, @rcpt);
    }
    
}

## Send a subscription request to the owners.
sub send_sub_to_owner {
   my($self, $who, $keyauth, $replyto, $gecos) = @_;
   do_log('debug2', 'List::send_sub_to_owner(%s, %s, %s, %s)', $who, $keyauth, $replyto, $gecos);

   my($i, @rcpt);
   my $admin = $self->{'admin'}; 
   my $name = $self->{'name'};
   my $host = $admin->{'host'};

   return unless ($name && $admin && $who);

   foreach $i (@{$admin->{'owner'}}) {
        next if ($i->{'reception'} eq 'nomail');
        push(@rcpt, $i->{'email'}) if ($i->{'email'});
   }

   unless (@rcpt) {
       do_log('notice', 'Warning : no owner defined or  all of them use nomail option in list %s', $name );
       return undef;
   }

   ## Replace \s by %20 in gecos and email
   my $escaped_gecos = $gecos;
   $escaped_gecos =~ s/\s/\%20/g;
   my $escaped_who = $who;
   $escaped_who =~ s/\s/\%20/g;

   my $subject = sprintf(Msg(8, 2, "%s subscription request"), $name);
   my $to = sprintf (Msg(8, 1, "Owners of list %s :"), $name)." <$name-request\@$host>";
   my $body = sprintf Msg(8, 3, $msg::sub_owner), $name, $replyto, $keyauth, $name, $escaped_who, $escaped_gecos, $replyto, $keyauth, $name, $who, $gecos;
   &mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);

}

## Send a notification to authors of messages sent to editors
sub notify_sender{
   my($self, $sender) = @_;
   do_log('debug2', 'List::notify_sender(%s)', $sender);

   my $admin = $self->{'admin'}; 
   my $name = $self->{'name'};
   return unless ($name && $admin && $sender);

   my $subject = sprintf Msg(4, 40, 'Moderating your message');
   my $body = sprintf Msg(4, 38, "Your message for list %s has been forwarded to editor(s)\n"), $name;
   &mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $sender, $self->{'domain'}, $sender);
}

## Send a Unsubscription request to the owners.
sub send_sig_to_owner {
    my($self, $who, $keyauth) = @_;
    do_log('debug2', 'List::send_sig_to_owner(%s)', $who);
    
    my($i, @rcpt);
    my $admin = $self->{'admin'}; 
    my $name = $self->{'name'};
    my $host = $admin->{'host'};
    
    return unless ($name && $admin && $who);
    
    foreach $i (@{$admin->{'owner'}}) {
        next if ($i->{'reception'} eq 'nomail');
        push(@rcpt, $i->{'email'}) if ($i->{'email'});
    }

    unless (@rcpt) {
	do_log('notice', 'Warning : no owner defined or  all of them use nomail option in list %s', $name );
    }

   ## Replace \s by %20 in email
   my $escaped_who = $who;
   $escaped_who =~ s/\s/\%20/g;

    my $subject = sprintf(Msg(8, 24, "%s UNsubscription request"), $name);
    my $to = sprintf (Msg(8, 1, "Owners of list %s :"), $name)." <$name-request\@$host>";
    my $body = sprintf Msg(8, 25, $msg::sig_owner), $name, $Conf{'sympa'}, $keyauth, $name, $escaped_who, $Conf{'sympa'}, $keyauth, $name, $who;
    &mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);
}

## Send a message to the editor
sub send_to_editor {
   my($self, $method, $msg, $file, $encrypt) = @_;
   do_log('debug2', "List::send_to_editor, msg: $msg, file: $file method : $method, encrypt : $encrypt");

   my($i, @rcpt);
   my $admin = $self->{'admin'};
   my $name = $self->{'name'};
   my $host = $admin->{'host'};
   my $modqueue = $Conf{'queuemod'};
   return unless ($name && $admin);
  
   my @now = localtime(time);
   my $messageid=$now[6].$now[5].$now[4].$now[3].$now[2].$now[1]."."
                 .int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6))."\@".$host;
   my $modkey=Digest::MD5->md5_hex(join('/', $self->get_cookie(),$messageid));
   my $boundary ="__ \<$messageid\>";
   
   ## Keeps a copy of the message
   if ($method eq 'md5'){  
       unless (open(OUT, ">$modqueue\/$name\_$modkey")) {
	   do_log('notice', 'Could Not open %s', "$modqueue\/$name\_$modkey");
	   return undef;
       }

       ## Always copy the original, not the MIME::Entity
       ## This prevents from message alterations
       if ($encrypt eq 'smime_crypted') {
	   ## $file is a reference to a scalar containing the raw message
	   print MSG ${$file};
       }else {
	   unless (open (MSG, $file)) {
	       do_log('notice', 'Could not open %s', $file);
	       return undef;   
	   }
	   while (<MSG>) {
	       print OUT ;
	   }
	   close MSG ;
       }

       close(OUT);
   }
   foreach $i (@{$admin->{'editor'}}) {
      next if ($i->{'reception'} eq 'nomail');
      push(@rcpt, $i->{'email'}) if ($i->{'email'});
   }
   unless (@rcpt) {
       foreach $i (@{$admin->{'owner'}}) {
	   next if ($i->{'reception'} eq 'nomail');
	   push(@rcpt, $i->{'email'}) if ($i->{'email'});
       }

       do_log('notice','Warning : no editor defined for list %s, contacting owners', $name );
   }

   if ($encrypt eq 'smime_crypted') {

       ## Send a different crypted message to each moderator
       foreach my $recipient (@rcpt) {

	   my $cryptedmsg = &tools::smime_encrypt($msg->head, $msg->body_as_string, $recipient); 
	   unless ($cryptedmsg) {
	       &do_log('notice', 'Failed encrypted message for moderator');
	       # xxxx send a generic error message : X509 cert missing
	       return undef;
	   }

	   my $crypted_file = "$Conf{'tmpdir'}/$name.moderate.$$";
	   unless (open CRYPTED, ">$crypted_file") {
	       &do_log('notice', 'Could not create file %s', $crypted_file);
	       return undef;
	   }
	   print CRYPTED $cryptedmsg;
	   close CRYPTED;
	   
	   $self->send_file('moderate', $recipient, $self->{'domain'}, {'modkey' => $modkey,
									'boundary' => $boundary,
									'msg' => $crypted_file,
									'method' => $method,
									## From the list because it is signed
									'from' => $self->{'name'}.'@'.$self->{'domain'}
									});
       }
   }else{
       $self->send_file('moderate', \@rcpt, $self->{'domain'}, {'modkey' => $modkey,
								'boundary' => $boundary,
								'msg' => $file,
								'method' => $method,
								'from' => $Conf{'email'}.'@'.$Conf{'host'}
								});
   }
   return $modkey;
}

## Send an authentication message
sub send_auth {
   my($self, $sender, $msg, $file) = @_;
   do_log('debug2', 'List::send_auth(%s, %s)', $sender, $file);

   ## Ensure 1 second elapsed since last message
   sleep (1);

   my($i, @rcpt);
   my $admin = $self->{'admin'};
   my $name = $self->{'name'};
   my $host = $admin->{'host'};
   my $authqueue = $Conf{'queueauth'};
   return undef unless ($name && $admin);
  
   my @now = localtime(time);
   my $messageid = $now[6].$now[5].$now[4].$now[3].$now[2].$now[1]."."
                   .int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6))
		   .int(rand(6)).int(rand(6))."\@".$host;
   my $modkey = Digest::MD5->md5_hex(join('/', $self->get_cookie(),$messageid));
   my $boundary = "----------------- Message-Id: \<$messageid\>" ;
   my $contenttype = "Content-Type: message\/rfc822";
     
   unless (open OUT, ">$authqueue\/$name\_$modkey") {
       &do_log('notice', 'Cannot create file %s', "$authqueue/$name/$modkey");
       return undef;
   }

   unless (open IN, $file) {
       &do_log('notice', 'Cannot open file %s', $file);
       return undef;
   }
   
   while (<IN>) {
       print OUT;
   }
   close IN; close OUT;
 
   my $hdr = new Mail::Header;
   $hdr->add('From', sprintf Msg(12, 4, 'SYMPA <%s>'), $Conf{'sympa'});
   $hdr->add('To', $sender );
#   $hdr->add('Subject', Msg(8, 16, "Authentication needed"));
   $hdr->add('Subject', "confirm $modkey");
   $hdr->add('MIME-Version', "1.0");
   $hdr->add('Content-Type',"multipart/mixed; boundary=\"$boundary\"") ;
   $hdr->add('Content-Transfert-Encoding', "8bit");
   
   *DESC = smtp::smtpto($Conf{'request'}, \$sender);
   $hdr->print(\*DESC);
   print DESC "\n";
   print DESC "--$boundary\n";
   print DESC "Content-Type: text/plain\n\n";
   printf DESC Msg(8, 12,"In order to broadcast the following message into list %s, either click on this link:\nmailto:%s?subject=CONFIRM%%20%s\nOr reply to %s with this subject :\nCONFIRM %s"), $name, $Conf{'sympa'}, $modkey, $Conf{'sympa'}, $modkey;
   print DESC "--$boundary\n";
   print DESC "Content-Type: message/rfc822\n\n";
   
   unless (open IN, $file) {
       &do_log('notice', 'Cannot open file %s', $file);
       return undef;
   }
   while (<IN>) {
       print DESC <IN>;
   }
   close IN;
   close(DESC);

   return $modkey;
}

## Distribute a message to the list
sub distribute_msg {
    my($self, $msg, $bytes, $msg_file, $encrypt) = @_;
    do_log('debug2', 'List::distribute_msg(%s, %s, %s, %s, %s)', $self->{'name'}, $msg, $bytes, $msg_file, $encrypt);

    my $hdr = $msg->head;
    my ($name, $host) = ($self->{'name'}, $self->{'admin'}{'host'});

    ## Update the stats, and returns the new X-Sequence, if any.
    my $sequence = $self->update_stats($bytes);
    
    ## Hide the sender if the list is anonymoused
    if ( $self->{'admin'}{'anonymous_sender'} ) {
	foreach my $field (@{$Conf{'anonymous_header_fields'}}) {
	    $hdr->delete($field);
	}
	
	$hdr->add('From',"$self->{'admin'}{'anonymous_sender'}");
	$hdr->add('Message-id',"<$self->{'name'}.$sequence\@anonymous>");

	## xxxxxx Virer eventuelle signature S/MIME
    }

    ## Archives
    my $msgtostore = $msg;
    if ($encrypt eq 'smime_crypted'){
	$msgtostore = &tools::smime_encrypt($msg->head, $msg->body_as_string,$self->{'name'},'list');
    }
    $self->archive_msg($msgtostore);

    ## Change the reply-to header if necessary. 
    if ($self->{'admin'}{'reply_to_header'}) {
	unless ($hdr->get('Reply-To') && ($self->{'admin'}{'reply_to_header'}{'apply'} ne 'forced')) {
	    my $reply;

	    $hdr->delete('Reply-To');

	    if ($self->{'admin'}{'reply_to_header'}{'value'} eq 'list') {
		$reply = "$name\@$host";
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'sender') {
		$reply = undef;
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'all') {
		$reply = "$name\@$host,".$hdr->get('From');
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'other_email') {
		$reply = $self->{'admin'}{'reply_to_header'}{'other_email'};
	    }

	    $hdr->add('Reply-To',$reply) if $reply;
	}
    }
    
    ## Remove unwanted headers if present.
    if ($Conf{'remove_headers'}) {
        foreach my $field (@{$Conf{'remove_headers'}}) {
            $hdr->delete($field);
        }
    }

    ## Add useful headers
    $hdr->add('X-Loop', "$name\@$host");
    $hdr->add('X-Sequence', $sequence);
    $hdr->add('Precedence', 'list');
    $hdr->add('X-no-archive', 'yes');
    foreach my $i (@{$self->{'admin'}{'custom_header'}}) {
	$hdr->add($1, $2) if ($i=~/^([\S\-\:]*)\s(.*)$/);
    }

    ## Add RFC 2919 header field
    if ($hdr->get('List-Id')) {
	&do_log('notice', 'Found List-Id: %s', $hdr->get('List-Id'));
	$hdr->delete('List-ID');
    }
    $hdr->add('List-Id', sprintf ('<%s@%s>', $self->{'name'}, $self->{'admin'}{'host'}));

    ## Add RFC 2369 header fields
    foreach my $field (@{$Conf{'rfc2369_header_fields'}}) {
	if ($field eq 'help') {
	    $hdr->add('List-Help', sprintf ('<mailto:%s@%s?subject=help>', $Conf{'email'}, $Conf{'host'}));
	}elsif ($field eq 'unsubscribe') {
	    $hdr->add('List-Unsubscribe', sprintf ('<mailto:%s@%s?subject=unsubscribe%%20%s>', $Conf{'email'}, $Conf{'host'}, $self->{'name'}));
	}elsif ($field eq 'subscribe') {
	    $hdr->add('List-Subscribe', sprintf ('<mailto:%s@%s?subject=subscribe%%20%s>', $Conf{'email'}, $Conf{'host'}, $self->{'name'}));
	}elsif ($field eq 'post') {
	    $hdr->add('List-Post', sprintf ('<mailto:%s@%s>', $self->{'name'}, $self->{'admin'}{'host'}));
	}elsif ($field eq 'owner') {
	    $hdr->add('List-Owner', sprintf ('<mailto:%s-request@%s>', $self->{'name'}, $self->{'admin'}{'host'}));
	}elsif ($field eq 'archive') {
	    if (defined ($Conf{'wwsympa_url'}) and $self->is_web_archived()) {
		$hdr->add('List-Archive', sprintf ('<%s/arc/%s>', $Conf{'wwsympa_url'}, $self->{'name'}));
	    }
	}
    }
    
    ## Does the list accept digest mode
    if ($self->is_digest()){
	$self->archive_msg_digest($msgtostore);
    }

    ## Blindly send the message to all users.
    my $numsmtp = $self->send_msg($msg, $msg_file, $encrypt);
    unless (defined ($numsmtp)) {
	return $numsmtp;
    }
    
    $self->savestats();
    
    return $numsmtp;
}

## Send a message to the list
sub send_msg {
    my($self, $msg, $msg_file, $encrypt) = @_;
    do_log('debug2', 'List::send_msg(%s, %s)', $msg_file, $encrypt);
    
    my $hdr = $msg->head;
    my $name = $self->{'name'};
    my $admin = $self->{'admin'};
    my $total = $self->{'total'};
    my @sender_hdr = Mail::Address->parse($hdr->get('From'));
  

   
    unless ($total > 0) {
	&do_log('info', 'No subscriber in list %s', $name);
	return undef;
    }

    ## Bounce rate
    ## Available in database mode only
    if ($admin->{'user_data_source'} eq 'database') {
	my $rate = $self->get_total_bouncing() * 100 / $total;
	if ($rate > $self->{'admin'}{'bounce'}{'warn_rate'}) {
	    $self->send_alert_to_owner('bounce_rate', {'rate' => $rate});
	}
    }

    ## Add Custom Subject
    if ($admin->{'custom_subject'}) {
	my $tag = '['.$admin->{'custom_subject'}.']';
	my $subject_field = $msg->head->get('Subject');
	$subject_field =~ s/^\s*(.*)\s*$/$1/;
	if (index(&MIME::Words::decode_mimewords($subject_field), $tag) <0) {
	    $msg->head->delete('Subject');
	    $msg->head->add('Subject', $tag." ".$subject_field);
	}
    }
 
    ## Who is the enveloppe sender ?
    my $host = $self->{'admin'}{'host'};
    my $from = "$name-owner\@$host";
    
    my (@tabrcpt, @tabrcpt_notice, @tabrcpt_txt, @tabrcpt_html, @tabrcpt_url);
    my $mixed = ($msg->head->get('Content-Type') =~ /multipart\/mixed/i);
    my $alternative = ($msg->head->get('Content-Type') =~ /multipart\/alternative/i);
 
    my $sender;
    my $me; 
   for ( my $user = $self->get_first_user(); $user; $user = $self->get_next_user() ){
       if ($user->{'reception'} =~ /^digest|summary|nomail$/i) {
	   next;
       } elsif ($user->{'reception'} eq 'not_me'){
	   $me =  0;
	   foreach $sender (@sender_hdr) {
	       if ($user->{'email'} eq $sender->address){
		   $me = 1;
		   next;
	       }	   
	       if ($me) {        
		   next;
	       }	   
	  }
       } elsif ($user->{'reception'} eq 'notice') {
           push @tabrcpt_notice, $user->{'email'}; 
       } elsif ($alternative and ($user->{'reception'} eq 'txt')) {
           push @tabrcpt_txt, $user->{'email'};
       } elsif ($alternative and ($user->{'reception'} eq 'html')) {
           push @tabrcpt_html, $user->{'email'};
       } elsif ($mixed and ($user->{'reception'} eq 'urlize')) {
           push @tabrcpt_url, $user->{'email'};
       } else {
	   push @tabrcpt, $user->{'email'};
       }
   }    

    ## sa  return 0  = Pb  ?
    unless (@tabrcpt || @tabrcpt_notice || @tabrcpt_txt || @tabrcpt_html || @tabrcpt_url) {
	&do_log('info', 'No subscriber for sending msg in list %s', $name);
	return 0;
    }
    #save the message before modifying it
    my $saved_msg = $msg->dup;
    my $nbr_smtp;

    ##Send message for normal reception mode
    if (@tabrcpt) {
	## Add a footer
	unless ($msg->head->get('Content-Type') =~ /multipart\/signed/i) {
	    my $new_msg = _add_parts($msg,  $name, $self->{'admin'}{'footer_type'});
	    if (defined $new_msg) {
		$msg = $new_msg;
		$msg_file = '_ALTERED_';
	    }
	}
	 $nbr_smtp = &smtp::mailto($msg, $from, $encrypt, $msg_file, @tabrcpt);
    }

    ##Prepare and send message for notice reception mode
    if (@tabrcpt_notice) {
	my $notice_msg = $saved_msg->dup;
        $notice_msg->bodyhandle(undef);    
	$notice_msg->parts([]);
	$nbr_smtp += &smtp::mailto($notice_msg, $from, $encrypt, '_ALTERED_', @tabrcpt_notice);
    }

    ##Prepare and send message for txt reception mode
    if (@tabrcpt_txt) {
	my $txt_msg = $saved_msg->dup;
	if (&tools::as_singlepart($txt_msg, 'text/plain')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
	
	## Add a footer
	my $new_msg = _add_parts($txt_msg,  $name, $self->{'admin'}{'footer_type'});
	if (defined $new_msg) {
	    $txt_msg = $new_msg;
        }
	$nbr_smtp += &smtp::mailto($txt_msg, $from, $encrypt, '_ALTERED_', @tabrcpt_txt);
    }

   ##Prepare and send message for html reception mode
    if (@tabrcpt_html) {
	my $html_msg = $saved_msg->dup;
	if (&tools::as_singlepart($html_msg, 'text/html|multipart/related')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
        ## Add a footer
	my $new_msg = _add_parts($html_msg,  $name, $self->{'admin'}{'footer_type'});
	if (defined $new_msg) {
	    $html_msg = $new_msg;
        }
	$nbr_smtp += &smtp::mailto($html_msg, $from, $encrypt, '_ALTERED_', @tabrcpt_html);
    }

   ##Prepare and send message for urlize reception mode
    if (@tabrcpt_url) {
	my $url_msg = $saved_msg->dup;
 
	my $expl = $Conf{'home'}.'/'.$name.'/urlized';
    
	unless ((-d $expl) ||( mkdir $expl, 0775)) {
	    do_log('err', "Unable to create urlize directory $expl");
	    printf "Unable to create urlized directory $expl";
	    return 0;
	}

	my $dir1 = $url_msg->head->get('Message-ID');
	chomp($dir1);

	## Clean up Message-ID
	$dir1 =~ s/^\<(.+)\>$/$1/;
	$dir1 = &tools::escape_chars($dir1);
	$dir1 = '/'.$dir1;

	unless ( mkdir ("$expl/$dir1", 0775)) {
	    do_log('err', "Unable to create urlize directory $expl/$dir1");
	    printf "Unable to create urlized directory $expl/$dir1";
	    return 0;
	}
	my $mime_types = &tools::load_mime_types();
	for (my $i=0 ; $i < $url_msg->parts ; $i++) {
	    &_urlize_part ($url_msg->parts ($i), $expl, $dir1, $i, $mime_types, $name) ;
	}
        ## Add a footer
	my $new_msg = _add_parts($url_msg,  $name, $self->{'admin'}{'footer_type'});
	if (defined $new_msg) {
	    $url_msg = $new_msg;
	} 
	$nbr_smtp += &smtp::mailto($url_msg, $from, $encrypt, '_ALTERED_', @tabrcpt_url);
    }

    return $nbr_smtp;
    
   }

## Add footer/header to a message
sub _add_parts {
    my ($msg, $listname, $type) = @_;
    do_log('debug2', 'List:_add_parts(%s, %s, %s)', $msg, $listname, $type);

    my ($header, $headermime);
    foreach my $file ("$listname/message.header", 
		      "$listname/message.header.mime",
		      "$Conf{'etc'}/templates/message.header", 
		      "$Conf{'etc'}/templates/message.header.mime") {
	if (-f $file) {
	    unless (-r $file) {
		&do_log('notice', 'Cannot read %s', $file);
		next;
	    }
	    $header = $file;
	    last;
	} 
    }

    my ($footer, $footermime);
    foreach my $file ("$listname/message.footer", 
		      "$listname/message.footer.mime",
		      "$Conf{'etc'}/templates/message.footer", 
		      "$Conf{'etc'}/templates/message.footer.mime") {
	if (-f $file) {
	    unless (-r $file) {
		&do_log('notice', 'Cannot read %s', $file);
		next;
	    }
	    $footer = $file;
	    last;
	} 
    }
    
    ## No footer/header
    unless (-f $footer or -f $header) {
 	return undef;
    }
    
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);

    ## Msg Content-Type
    my $content_type = $msg->head->get('Content-Type');
    
    ## MIME footer/header
    if ($type eq 'append'){

	my (@footer_msg, @header_msg);
	if ($header) {
	    open HEADER, $header;
	    @header_msg = <HEADER>;
	    close HEADER;
	}
	
	if ($footer) {
	    open FOOTER, $footer;
	    @footer_msg = <FOOTER>;
	    close FOOTER;
	}
	
	if (!$content_type or $content_type =~ /^text\/plain/i) {
		    
	    my @body = $msg->bodyhandle->as_lines;
	    $msg->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );

	}elsif ($content_type =~ /^multipart\/mixed/i) {
	    ## Append to first part if text/plain
	    
	    if ($msg->parts(0)->head->get('Content-Type') =~ /^text\/plain/i) {
		
		my $part = $msg->parts(0);
		my @body = $part->bodyhandle->as_lines;
		$part->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );
	    }else {
		&do_log('notice', 'First part of message not in text/plain ; ignoring footers and headers');
	    }

	}elsif ($content_type =~ /^multipart\/alternative/i) {
	    ## Append to first text/plain part

	    foreach my $part ($msg->parts) {
		&do_log('debug2', 'TYPE: %s', $part->head->get('Content-Type'));
		if ($part->head->get('Content-Type') =~ /^text\/plain/i) {

		    my @body = $part->bodyhandle->as_lines;
		    $part->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );
		    next;
		}
	    }
	}

    }else {
	if ($content_type =~ /^multipart\/alternative/i) {

	    &do_log('notice', 'Cannot add header/footer to message in multipart/alternative format');
	}else {
	    
	    if ($header) {
		if ($header =~ /\.mime$/) {
		    
		    my $header_part = $parser->parse_in($header);    
		    $msg->make_multipart unless $msg->is_multipart;
		    $msg->add_part($header_part, 0); ## Add AS FIRST PART (0)
		    
		    ## text/plain header
		}else {
		    
		    $msg->make_multipart unless $msg->is_multipart;
		    my $header_part = build MIME::Entity Path        => $header,
		    Type        => "text/plain",
		    Encoding    => "8bit";
		    $msg->add_part($header_part, 0);
		}
	    }
	    
	    if ($footer) {
		if ($footer =~ /\.mime$/) {
		    
		    my $footer_part = $parser->parse_in($footer);    
		    $msg->make_multipart unless $msg->is_multipart;
		    $msg->add_part($footer_part);
		    
		    ## text/plain footer
		}else {
		    
		    $msg->make_multipart unless $msg->is_multipart;
		    $msg->attach(Path        => $footer,
				 Type        => "text/plain",
				 Encoding    => "8bit"
				 );
		}
	    }
	}
    }

    return $msg;
}

## Send a digest message to the subscribers with reception digest or summary
sub send_msg_digest {
    my ($self,$robot) = @_;
    my $listname = $self->{'name'};
    do_log('debug2', 'List:send_msg_digest(%s)', $listname);
    
    my $filename = "$Conf{'queuedigest'}/$listname";
    my $param = {'host' => $self->{'admin'}{'host'},
		 'name' => "$self->{'name'}",
		 'from' => "$self->{'name'}-request\@$self->{'admin'}{'host'}",
		 'return_path' => "$self->{'name'}-owner\@$self->{'admin'}{'host'}",
		 'reply' => "$self->{'name'}-request\@$self->{'admin'}{'host'}",
		 'to' => "$self->{'name'}\@$self->{'admin'}{'host'}",
		 'table_of_content' => sprintf(Msg(8, 13, "Table of content"))
		 };
    
    if ($self->get_reply_to() =~ /^list$/io) {
	$param->{'reply'} = "$param->{'to'}";
    }
    
    my @tabrcpt ;
    my @tabrcptsummary;
    my $i;
    
    my ($mail, @list_of_mail);

    ## Check the list
    return undef unless ($listname eq $param->{'name'});

    ## Create the list of subscribers in digest mode
    for (my $user = $self->get_first_user(); $user; $user = $self->get_next_user()) {
	push @tabrcpt, $user->{'email'} 
	     if $user->{'reception'} eq "digest";
    }

    ## Create the list of subscribers in summary mode
    for (my $user = $self->get_first_user(); $user; $user = $self->get_next_user()) {
	push @tabrcptsummary, $user->{'email'} 
	     if $user->{'reception'} eq "summary";
    }

    return if (($#tabrcptsummary == -1) and ($#tabrcpt == -1));

    my $old = $/;
    $/ = "\n\n" . $msg::separator . "\n\n";

    ## Digest split in individual messages
    open DIGEST, $filename or return undef;
    foreach (<DIGEST>){
	
	my @text = split /\n/;
	pop @text; pop @text;

	## Restore carriage returns
	foreach $i (0 .. $#text) {
	    $text[$i] .= "\n";
	}

	$mail = new Mail::Internet \@text;

	push @list_of_mail, $mail;
	
    }
    close DIGEST;
    $/ = $old;

    ## Deletes the introduction part
    splice @list_of_mail, 0, 1;

    ## Index construction
    foreach $i (0 .. $#list_of_mail){
	my $mail = $list_of_mail[$i];
	my ($subject, $from);

	## Subject cleanup
	if ($subject = &MIME::Words::decode_mimewords($mail->head->get('Subject'))) {
	    $mail->head->replace('Subject', $subject);
	}

	## From cleanup
	if ($from = &MIME::Words::decode_mimewords($mail->head->get('From'))) {
	    $mail->head->replace('From', $from);
	}
    }

    my @topics;
    push @topics, sprintf(Msg(8, 13, "Table of content"));
    push @topics, sprintf(" :\n\n");

    ## Digest index
    foreach $i (0 .. $#list_of_mail){
	my $mail = $list_of_mail[$i];	
	my $subject = $mail->head->get('Subject') || "\n";
        my $msg = {};
        $msg->{'subject'} = $subject;	
        $msg->{'from'} = $mail->head->get('From');
	chomp $msg->{'from'};
	$msg->{'month'} = &POSIX::strftime("%Y-%m", localtime(time)); ## Should be extracted from Date:
	$msg->{'message_id'} = $mail->head->get('Message-Id');
	
	## Clean up Message-ID
	$msg->{'message_id'} =~ s/^\<(.+)\>$/$1/;
	$msg->{'message_id'} = &tools::escape_chars($msg->{'message_id'});

        push @{$param->{'msg'}}, $msg ;

	push @topics, sprintf ' ' x (2 - length($i)) . "%d. %s", $i+1, $subject;
    }
    
    ## Prepare Digest
    if (@tabrcpt) {
	my $msg = MIME::Entity->build (To         => $param->{'to'},
				       From       => $param->{'from'},
				       'Reply-to' => $param->{'reply'},
				       Type       => 'multipart/mixed',
				       Subject    => MIME::Words::encode_mimewords(sprintf(Msg(8, 9, "Digest of list %s"),$listname))
				       );
	
	my $charset = sprintf Msg(12, 2, 'us-ascii');
	my $table_of_content = MIME::Entity->build (Type        => "text/plain; charset=$charset",
						    Description => sprintf(Msg(8, 13, 'Table of content')),
						    Data        => \@topics
						    );
	
	$msg->add_part($table_of_content);
	
	my $digest = MIME::Entity->build (Type     => 'multipart/digest',
					  Boundary => '__--__--'
					  );
	## Digest messages
	foreach $mail (@list_of_mail) {
	    $mail->tidy_body;
	    $mail->remove_sig;
	    
	    $digest->attach(Type     => 'message/rfc822',
			    Disposition => 'inline',
			    Data        => $mail->as_string
			    );
	}
	
	my @now  = localtime(time);
	my $footer = sprintf Msg(8, 14, "End of %s Digest"), $listname;
	$footer .= sprintf " - %s\n", POSIX::strftime("%a %b %e %H:%M:%S %Y", @now);
	
	$digest->attach(Type        => 'text/plain',
			Disposition => 'inline',
			Data        => $footer
			);
	$msg->add_part($digest); 
	
	## Add a footer
	my $new_msg = _add_parts($msg, $param->{'name'}, $self->{'admin'}{'footer_type'});
	if (defined $new_msg) {
	    $msg = $new_msg;
	}
	
	## Send digest
	&smtp::mailto($msg, $param->{'return_path'}, 'none', '_ALTERED_', @tabrcpt );
    }
    
    ## send summary
    if (@tabrcptsummary) {
	$param->{'subject'} = sprintf Msg(8, 31, 'Summary of list %s'), $self->{'name'};
	
	$self->send_file('summary', \@tabrcptsummary, $robot, $param);
    }
    return 1;
}

## Send a global (not relative to a list) file to a user
sub send_global_file {
    my($action, $who, $robot, $context) = @_;
    do_log('debug2', 'List::send_global_file(%s, %s, %s)', $action, $who, $robot);

    my $filename;
    my $data = $context;

    unless ($data->{'user'}) {
	unless ($data->{'user'} = &get_user_db($who)) {
	    $data->{'user'}{'email'} = $who;
	}
    }
    unless ($data->{'user'}{'lang'}) {
	$data->{'user'}{'lang'} = $Language::default_lang;
    }
    
    unless ($data->{'user'}{'password'}) {
	$data->{'user'}{'password'} = &tools::tmp_passwd($who);
    }

    ## Lang
    my $lang = $data->{'user'}{'lang'} || $Conf{'lang'};

    ## What file   
    foreach my $f ("$Conf{'etc'}/$robot/templates/$action.$lang.tpl","$Conf{'etc'}/$robot/templates/$action.tpl",
		   "$Conf{'etc'}/templates/$action.$lang.tpl","$Conf{'etc'}/templates/$action.tpl",
		   "--ETCBINDIR--/templates/$action.$lang.tpl","--ETCBINDIR--/templates/$action.tpl") {
	if (-r $f) {
	    $filename = $f;
	    last;
	}
    }

    unless ($filename) {
	do_log ('err',"Unable to open file $Conf{'etc'}/$robot/templates/$action.tpl NOR  $Conf{'etc'}/templates/$action.tpl NOR --ETCBINDIR--/templates/$action.tpl");
    }

    $data->{'conf'}{'email'} = $Conf{'robots'}{$robot}{'email'} || $Conf{'email'};
    $data->{'conf'}{'host'} = $Conf{'robots'}{$robot}{'host'} || $Conf{'host'};
    $data->{'conf'}{'sympa'} = $Conf{'robots'}{$robot}{'sympa'} || $Conf{'sympa'};
    $data->{'conf'}{'request'} = $Conf{'robots'}{$robot}{'request'} || $Conf{'request'};
    $data->{'conf'}{'listmaster'} = $Conf{'robots'}{$robot}{'listmaster'} || $Conf{'listmaster'};
    $data->{'conf'}{'wwsympa_url'} = $Conf{'robots'}{$robot}{'wwsympa_url'} || $Conf{'wwsympa_url'};
    $data->{'conf'}{'version'} = $main::Version;
    $data->{'from'} = $Conf{'robots'}{$robot}{'request'} || $Conf{'request'};
    $data->{'robot_domain'} = $robot;
    $data->{'return_path'} = $Conf{'request'};

    mail::mailfile($filename, $who, $data, $robot);

    return 1;
}

## Send a file to a user
sub send_file {
    my($self, $action, $who, $robot, $context) = @_;
    do_log('debug2', 'List::send_file(%s, %s, %s, %s)', $action, $who, $robot);

    my $name = $self->{'name'};
    my $filename;
    my $sign_mode;

    my $data = $context;

    ## Any recepients
    if ((ref ($who) && ($#{$who} < 0)) ||
	(!ref ($who) && ($who eq ''))) {
	&do_log('debug', 'No recipient for sending %s', $action);
	return undef;
    }

    ## Unless multiple recepients
    unless (ref ($who)) {
	unless ($data->{'user'}) {
	    unless ($data->{'user'} = &get_user_db($who)) {
		$data->{'user'}{'email'} = $who;
		$data->{'user'}{'lang'} = $self->{'admin'}{'lang'};
	    }
	}
	
	$data->{'subscriber'} = $self->get_subscriber($who);

	if ($data->{'subscriber'}) {
	    $data->{'subscriber'}{'date'} = &POSIX::strftime("%d %b %Y", localtime($data->{'subscriber'}{'date'}));
	    $data->{'subscriber'}{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($data->{'subscriber'}{'update_date'}));
	}
	
	unless ($data->{'user'}{'password'}) {
	    $data->{'user'}{'password'} = &tools::tmp_passwd($who);
	}
	
	## Unique return-path
	if ((($self->{'admin'}{'welcome_return_path'} eq 'unique') && ($action eq 'welcome')) ||
	    (($self->{'admin'}{'remind_return_path'} eq 'unique') && ($action eq 'remind')))  {
	    my $escapercpt = $who ;
	    $escapercpt =~ s/\@/\=\=a\=\=/;
	    $data->{'return_path'} = "bounce+$escapercpt\=\=$name\@$self->{'admin'}{'host'}";
	}
    }

    $data->{'return_path'} ||= "$name-owner\@$self->{'admin'}{'host'}";

    ## Lang
    my $lang = $data->{'user'}{'lang'} || $self->{'lang'} || $Conf{'lang'};

    ## What file   
    foreach my $f ("$self->{'dir'}/$action.$lang.tpl",
		   "$self->{'dir'}/$action.tpl",
		   "$self->{'dir'}/$action.mime","$self->{'dir'}/$action",
		   "$Conf{'etc'}/$robot/templates/$action.$lang.tpl",
		   "$Conf{'etc'}/$robot/templates/$action.tpl",
		   "$Conf{'etc'}/templates/$action.$lang.tpl",
		   "$Conf{'etc'}/templates/$action.tpl",
		   "$Conf{'home'}/$action.mime",
		   "$Conf{'home'}/$action",
		   "--ETCBINDIR--/templates/$action.$lang.tpl",
		   "--ETCBINDIR--/templates/$action.tpl") {
	if (-r $f) {
	    $filename = $f;
	    last;
	}
    }

    unless ($filename) {
	do_log ('err',"Unable to find '$action' template in list directory NOR $Conf{'etc'}/templates/ NOR --ETCBINDIR--/templates/");
    }
    
    $data->{'conf'}{'email'} = $Conf{'robots'}{$robot}{'email'} || $Conf{'email'};
    $data->{'conf'}{'host'} = $Conf{'robots'}{$robot}{'host'} || $Conf{'host'};
    $data->{'conf'}{'sympa'} = $Conf{'robots'}{$robot}{'sympa'} || $Conf{'sympa'};
    $data->{'conf'}{'listmaster'} = $Conf{'robots'}{$robot}{'listmaster'} || $Conf{'listmaster'};
    $data->{'conf'}{'wwsympa_url'} = $Conf{'robots'}{$robot}{'wwsympa_url'} || $Conf{'wwsympa_url'};
    $data->{'list'}{'lang'} = $self->{'admin'}{'lang'};
    $data->{'list'}{'name'} = $name;
    $data->{'robot_domain'} = $robot;
    $data->{'list'}{'host'} = $self->{'admin'}{'host'};
    $data->{'list'}{'subject'} = $self->{'admin'}{'subject'};
    $data->{'list'}{'owner'} = $self->{'admin'}{'owner'};
    $data->{'list'}{'dir'} = $self->{'dir'};

    ## Sign mode
    if ($Conf{'openssl'} &&
	(-r $Conf{'home'}.'/'.$self->{'name'}.'/cert.pem') && 
	(-r $Conf{'home'}.'/'.$self->{'name'}.'/private_key')) {
	$sign_mode = 'smime';
    }

    # if the list have it's private_key and cert sign the message
    # . used only for the welcome message, could be usefull in other case ? 
    # . a list should have several certificats and use if possible a certificat
    #   issued by the same CA as the receipient CA if it exists 
    if ($sign_mode eq 'smime') {
	$data->{'from'} = "$name\@$data->{'list'}{'host'}";
	$data->{'replyto'} = "$name-request\@$data->{'list'}{'host'}";
    }else{
	$data->{'from'} = "$name-request\@$data->{'list'}{'host'}";
    }

    foreach my $key (keys %{$context}) {
	$data->{'context'}{$key} = $context->{$key};
    }

    ## 2.7b
    if ($filename) {
        mail::mailfile($filename, $who, $data, $self->{'domain'}, $sign_mode);
    }
    chdir $Conf{'home'};

    return 1;
}

## Delete a new user to Database (in User table)
sub delete_user_db {
    my($who) = lc(shift);
    do_log('debug2', 'List::delete_user_db');
    
    my ($field, $value);
    my ($user, $statement, $table);
    
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    
    return undef unless $who;
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    ## Update field
    $statement = sprintf "DELETE FROM user_table WHERE (email_user =%s)"
	, $dbh->quote($who); 
    
    unless ($dbh->do($statement)) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    return 1;
}

## Delete the indicate users from the list.
sub delete_user {
    my($self, @u) = @_;
    do_log('debug2', 'List::delete_user');

    my $name = $self->{'name'};

    foreach my $who (@u) {
	$who = lc($who);
	if ($self->{'admin'}{'user_data_source'} eq 'database') {
	    my $statement;
	    
	    $list_cache{'is_user'}{$name}{$who} = undef;    
	    
	    ## Check database connection
	    unless ($dbh and $dbh->ping) {
		return undef unless &db_connect();
	    }
	    
	    ## Delete record in SUBSCRIBER
	    $statement = sprintf "DELETE FROM subscriber_table WHERE (user_subscriber=%s AND list_subscriber=%s)",$dbh->quote($who), $dbh->quote($name);
	    
	    unless ($dbh->do($statement)) {
		do_log('debug','Unable to execute SQL statement %s : %s', $statement, $dbh->errstr);
		return undef;
	    }   

	    $self->{'total'}--;

	    ## Is it his/her last subscription
	    my @which;
	    foreach my $role ('member','editor','owner') {
		@which = (@which, &get_which ($who,'*',$role));
	    }

	    ## Cleanup in user_table
	    if ($#which < 0) {
		$statement = sprintf "DELETE FROM user_table WHERE (email_user=%s)",$dbh->quote($who);
		
		unless ($dbh->do($statement)) {
		    do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		    return undef;
		}   
	    }
	    
	}else {
	    my $users = $self->{'users'};

	    delete $self->{'users'}{$who};
	    $self->{'total'}-- unless (exists $users->{$who});
	}
    }

    $self->savestats();

    return 1;
}

## Returns the cookie for a list, if any.
sub get_cookie {
   return shift->{'admin'}{'cookie'};
}

## Returns the maximum size allowed for a message to the list.
sub get_max_size {
   return shift->{'admin'}{'max_size'};
}

## Returns an array with the Reply-To data
sub get_reply_to {
    my $admin = shift->{'admin'};

    my $value = $admin->{'reply_to_header'}{'value'};

    $value = $admin->{'reply_to_header'}{'other_email'} if ($value eq 'other_email');

    return $value
}

## Returns a default user option
sub get_default_user_options {
    my $self = shift->{'admin'};
    my $what = shift;
    do_log('debug2', 'List::get_default_user_options(%s)', $what);

    if ($self) {
	return $self->{'default_user_options'};
    }
    return undef;
}

## Returns the number of subscribers to the list
sub get_total {
    my $self = shift;
    my $name = $self->{'name'};
    &do_log('debug2','List::get_total(%s)', $name);

#    if ($self->{'admin'}{'user_data_source'} eq 'database') {
	## If stats file was updated
#	my $time = (stat("$name/stats"))[9];
#	if ($time > $self->{'mtime'}[0]) {
#	    $self->{'total'} = _load_total_db($self->{'name'});
#	}
#    }
    
    return $self->{'total'};
}

## Returns a hash for a given user
sub get_user_db {
    my $who = lc(shift);
    do_log('debug2', 'List::get_user_db(%s)', $who);

    my $statement;
 
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    ## Additional subscriber fields
    my $additional;
    if ($Conf{'db_additional_user_fields'}) {
	$additional = ',' . $Conf{'db_additional_user_fields'};
    }

    if ($Conf{'db_type'} eq 'Oracle') {
	## "AS" not supported by Oracle
	$statement = sprintf "SELECT email_user \"email\", gecos_user \"gecos\", password_user \"password\", cookie_delay_user \"cookie_delay\", lang_user \"lang\" %s FROM user_table WHERE email_user = %s ", $additional, $dbh->quote($who);
    }else {
	$statement = sprintf "SELECT email_user AS email, gecos_user AS gecos, password_user AS password, cookie_delay_user AS cookie_delay, lang_user AS lang %s FROM user_table WHERE email_user = %s ", $additional, $dbh->quote($who);
    }
    
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref;
 
    $sth->finish();

    $sth = pop @sth_stack;

    ## decrypt password
    if ((defined $user) && $user->{'password'}) {
	$user->{'password'} = &tools::decrypt_password($user->{'password'});
    }

    return $user;
}

## Returns a subscriber of the list.
sub get_subscriber {
    my  $self= shift;
    my  $email = lc(shift);
    
    do_log('debug2', 'List::get_subscriber(%s)', $email);

    if ($self->{'admin'}{'user_data_source'} eq 'database') {

	my $name = $self->{'name'};
	my $statement;
	my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_subscriber', 'date_subscriber';
	my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_subscriber', 'update_subscriber';	

	## Use session cache
	if (defined $list_cache{'get_subscriber'}{$name}{$email}) {
	    &do_log('debug2', 'xxx Use cache(get_subscriber, %s,%s)', $name, $email);
	    return $list_cache{'get_subscriber'}{$name}{$email};
	}

	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}

	## Additional subscriber fields
	my $additional;
	if ($Conf{'db_additional_subscriber_fields'}) {
	    $additional = ',' . $Conf{'db_additional_subscriber_fields'};
	}

	if ($Conf{'db_type'} eq 'Oracle') {
	    ## "AS" not supported by Oracle
	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", bounce_subscriber \"bounce\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", %s \"date\", %s \"update_date\"  %s FROM subscriber_table WHERE (user_subscriber = %s AND list_subscriber = %s)", $date_field, $update_field, $additional, $dbh->quote($email), $dbh->quote($name);
	}else {
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, bounce_subscriber AS bounce, reception_subscriber AS reception, visibility_subscriber AS visibility, %s AS date, %s AS update_date %s FROM subscriber_table WHERE (user_subscriber = %s AND list_subscriber = %s)", $date_field, $update_field, $additional, $dbh->quote($email), $dbh->quote($name);
	}

	push @sth_stack, $sth;

	unless ($sth = $dbh->prepare($statement)) {
	    do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}
	
	unless ($sth->execute) {
	    do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	my $user = $sth->fetchrow_hashref;

	$user->{'reception'} ||= 'mail';
	$user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	  unless ($self->is_available_reception_mode($user->{'reception'}));

	$user->{'update_date'} ||= $user->{'date'};

	$sth->finish();

	$sth = pop @sth_stack;

	## Set session cache
	$list_cache{'get_subscriber'}{$name}{$email} = $user;

	return $user;
    }else {
	my $i;
	return undef 
	    unless $self->{'users'}{$email};

	my %user = split(/\n/, $self->{'users'}{$email});

	$user{'reception'} ||= 'mail';
	$user{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	     unless ($self->is_available_reception_mode($user{'reception'}));
	
	return \%user;
    }
}


## Returns the first user for the list.
sub get_first_user {
    my ($self, $data) = @_;

    my ($sortby, $offset, $rows, $sql_regexp);
    $sortby = $data->{'sortby'};
    $offset = $data->{'offset'};
    $rows = $data->{'rows'};
    $sql_regexp = $data->{'sql_regexp'};

    do_log('debug2', 'List::get_first_user(%s,%d,%d)', $sortby, $offset, $rows);
    
    ## Sort may be domain, email, date
    $sortby ||= 'domain';
    
    if ($self->{'admin'}{'user_data_source'} eq 'database') {

	my $name = $self->{'name'};
	my $statement;
	my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_subscriber', 'date_subscriber';
	my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_subscriber', 'update_subscriber';
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}

	## SQL regexp
	my $selection;
	if ($sql_regexp) {
	    $selection = sprintf " AND (user_subscriber LIKE %s OR comment_subscriber LIKE %s)"
		,$dbh->quote($sql_regexp), $dbh->quote($sql_regexp);
	}

	## Additional subscriber fields
	my $additional;
	if ($Conf{'db_additional_subscriber_fields'}) {
	    $additional = ',' . $Conf{'db_additional_subscriber_fields'};
	}
	
	## Oracle
	if ($Conf{'db_type'} eq 'Oracle') {

	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", %s \"date\", %s \"update_date\" %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;

	    ## SORT BY
	    if ($sortby eq 'domain') {
		$statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", %s \"date\", %s \"update_date\", substr(user_subscriber,instr(user_subscriber,'\@')+1) \"dom\" %s FROM subscriber_table WHERE (list_subscriber = %s ) ORDER BY \"dom\"", $date_field, $update_field, $additional, $dbh->quote($name);

	    }elsif ($sortby eq 'email') {
		$statement .= " ORDER BY \"email\"";

	    }elsif ($sortby eq 'date') {
		$statement .= " ORDER BY \"date\" DESC";

	    }

	## Sybase
	}elsif ($Conf{'db_type'} eq 'Sybase'){

	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", %s \"date\", %s \"update_date\" %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		$statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", %s \"date\", %s \"update_date\", substring(user_subscriber,charindex('\@',user_subscriber)+1,100) \"dom\" %s FROM subscriber_table WHERE (list_subscriber = %s) ORDER BY \"dom\"", $date_field, $update_field, $additional, $dbh->quote($name);
		
	    }elsif ($sortby eq 'email') {
		$statement .= " ORDER BY \"email\"";

	    }elsif ($sortby eq 'date') {
		$statement .= " ORDER BY \"date\" DESC";

	    }

	## mysql
	}elsif ($Conf{'db_type'} eq 'mysql') {
	    
    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, %s AS date, %s AS update_date %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		## Redefine query to set "dom"

		$statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, %s AS date, %s AS update_date, SUBSTRING(user_subscriber FROM position('\@' IN user_subscriber) FOR 50) AS dom %s FROM subscriber_table WHERE (list_subscriber = %s) ORDER BY dom", $date_field, $update_field, $additional, $dbh->quote($name);

	    }elsif ($sortby eq 'email') {
		## Default SORT
		#$statement .= ' ORDER BY email';

	    }elsif ($sortby eq 'date') {
		$statement .= ' ORDER BY date DESC';

	    }
	    
	    ## LIMIT clause
	    if (defined($rows) and defined($offset)) {
		$statement .= sprintf " LIMIT %d, %d", $offset, $rows;
	    }
	    
	## Pg    
	}else {
	    
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, %s AS date, %s AS update_date %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		## Redefine query to set "dom"

		$statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, %s AS date, %s AS update_date, SUBSTRING(user_subscriber FROM position('\@' IN user_subscriber) FOR 50) AS dom %s FROM subscriber_table WHERE (list_subscriber = %s) ORDER BY dom", $date_field, $update_field, $additional, $dbh->quote($name);

	    }elsif ($sortby eq 'email') {
		$statement .= ' ORDER BY email';

	    }elsif ($sortby eq 'date') {
		$statement .= ' ORDER BY date DESC';

	    }
	    
	    ## LIMIT clause
	    if (defined($rows) and defined($offset)) {
		$statement .= sprintf " LIMIT %d, %d", $rows, $offset;
	    }
	}
	push @sth_stack, $sth;

	unless ($sth = $dbh->prepare($statement)) {
	    do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}
	
	unless ($sth->execute) {
	    do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	my $user = $sth->fetchrow_hashref;
	if (defined $user) {
	    $user->{'reception'} ||= 'mail';
	    $user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	    unless ($self->is_available_reception_mode($user->{'reception'}));
	    $user->{'update_date'} ||= $user->{'date'};
	}

	## If no LIMIT was used, update total of subscribers
#	unless ($offset || $rows) {
	    $self->{'total'} = &_load_total_db($self->{'name'});
	    $self->savestats();
#	}
	
	return $user;
    }else {
	my ($i, $j);
	my $ref = $self->{'ref'};
	
	 if (defined($ref) && $ref->seq($i, $j, R_FIRST) == 0)  {
	    my %user = split(/\n/, $j);

	    $self->{'_loading_total'} = 1;

	    $user{'reception'} ||= 'mail';
	    $user{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	    unless ($self->is_available_reception_mode($user{'reception'}));
	    return \%user;
	}
	return undef;
    }
}

## Loop for all subsequent users.
sub get_next_user {
    my $self = shift;
#    do_log('debug2', 'List::get_next_user');

    if ($self->{'admin'}{'user_data_source'} eq 'database') {
	my $user = $sth->fetchrow_hashref;

	if (defined $user) {
	    $user->{'reception'} ||= 'mail';
	    unless ($self->is_available_reception_mode($user->{'reception'})){
		$user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	    }
	    $user->{'update_date'} ||= $user->{'date'};
	}
	else {
	    $sth->finish;
	    $sth = pop @sth_stack;
	}

#	$self->{'total'}++;

	return $user;
    }else {
	my ($i, $j);
	my $ref = $self->{'ref'};
	
	if ($ref->seq($i, $j, R_NEXT) == 0) {
	    my %user = split(/\n/, $j);

	    $self->{'_loading_total'}++;

	    $user{'reception'} ||= 'mail';
	    $user{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	      unless ($self->is_available_reception_mode($user{'reception'}));
	    return \%user;
	}
	## Update total
	$self->{'total'} = $self->{'_loading_total'}; 
	$self->{'_loading_total'} = undef;
	$self->savestats();

	return undef;
    }
}

## Returns the first bouncing user
sub get_first_bouncing_user {
    my $self = shift;
    do_log('debug2', 'List::get_first_bouncing_user');

    unless ($self->{'admin'}{'user_data_source'} eq 'database') {
	&do_log('info', 'Function available for lists in database mode only');
	return undef;
    }
    
    my $name = $self->{'name'};
    my $statement;
    my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_subscriber', 'date_subscriber';
    my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_subscriber', 'update_subscriber';
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    ## Additional subscriber fields
    my $additional;
    if ($Conf{'db_additional_subscriber_fields'}) {
	$additional = ',' . $Conf{'db_additional_subscriber_fields'};
    }

    if ($Conf{'db_type'} eq 'Oracle') {
	## "AS" not supported by Oracle
	$statement = sprintf "SELECT user_subscriber \"email\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", %s \"date\", %s \"update_date\" %s FROM subscriber_table WHERE (list_subscriber = %s AND bounce_subscriber is not NULL)", $date_field, $update_field, $additional, $dbh->quote($name);
    }else {
	$statement = sprintf "SELECT user_subscriber AS email, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, %s AS date, %s AS update_date %s FROM subscriber_table WHERE (list_subscriber = %s AND bounce_subscriber is not NULL)", $date_field, $update_field, $additional, $dbh->quote($name);
    }

    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref;
    
    return $user;
}

## Loop for all subsequent bouncing users.
sub get_next_bouncing_user {
    my $self = shift;
#    do_log('debug2', 'List::get_next_bouncing_user');

    unless ($self->{'admin'}{'user_data_source'} eq 'database') {
	&do_log('info', 'Function available for lists in database mode only');
	return undef;
    }

    my $user = $sth->fetchrow_hashref;
    
    unless (defined $user) {
	$sth->finish;
	$sth = pop @sth_stack;
    }

    return $user;
}

sub get_info {
    my $self = shift;

    my $info;
    
    unless (open INFO, "$self->{'dir'}/info") {
	&do_log('err', 'Could not open %s : %s', $self->{'dir'}.'/info', $!);
	return undef;
    }
    
    while (<INFO>) {
	$info .= $_;
    }
    close INFO;

    return $info;
}

## Total bouncing subscribers
sub get_total_bouncing {
    my $self = shift;
    do_log('debug2', 'List::get_total_boucing');

    unless ($self->{'admin'}{'user_data_source'} eq 'database') {
	&do_log('info', 'Function available for lists in database mode only');
	return undef;
    }

    my $name = $self->{'name'};
    my $statement;
   
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    ## Query the Database
    $statement = sprintf "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s  AND bounce_subscriber is not NULL)", $dbh->quote($name);
    
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $total =  $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    return $total;
}

## Is the person in user table (db only)
sub is_user_db {
   my $who = lc(pop);
   do_log('debug2', 'List::is_user_db(%s)', $who);

   return undef unless ($who);

   unless ($List::use_db) {
       &do_log('info', 'Sympa not setup to use DBI');
       return undef;
   }

   my $statement;
   
   ## Check database connection
   unless ($dbh and $dbh->ping) {
       return undef unless &db_connect();
   }	   
   
   ## Query the Database
   $statement = sprintf "SELECT count(*) FROM user_table WHERE email_user = %s", $dbh->quote($who);
   
   push @sth_stack, $sth;

   unless ($sth = $dbh->prepare($statement)) {
       do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
       return undef;
   }
   
   unless ($sth->execute) {
       do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
       return undef;
   }
   
   my $is_user = $sth->fetchrow();
   $sth->finish();
   
   $sth = pop @sth_stack;

   return $is_user;
}

## Is the indicated person a subscriber to the list ?
sub is_user {
    my ($self, $who) = @_;
    $who= lc($who);
    do_log('debug2', 'List::is_user(%s)', $who);
    
    return undef unless ($self && $who);
    
    if ($self->{'admin'}{'user_data_source'} eq 'database') {
	
	my $statement;
	my $name = $self->{'name'};
	
	## Use cache
	if (defined $list_cache{'is_user'}{$name}{$who}) {
	    # &do_log('debug2', 'Use cache(%s,%s): %s', $name, $who, $list_cache{'is_user'}{$name}{$who});
	    return $list_cache{'is_user'}{$name}{$who};
	}
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   
	
	## Query the Database
	$statement = sprintf "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s AND user_subscriber = %s)",$dbh->quote($name), $dbh->quote($who);
	
	push @sth_stack, $sth;
	
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}
	
	unless ($sth->execute) {
	    do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	my $is_user = $sth->fetchrow;
	
	$sth->finish();
	
	$sth = pop @sth_stack;

	## Set cache
	$list_cache{'is_user'}{$name}{$who} = $is_user;

       return $is_user;
   }else {
       my $users = $self->{'users'};
       return 0 unless ($users);
       
       return 1 if ($users->{$who});
       return 0;
   }
}

## Sets new values for the given user (except gecos)
sub update_user {
    my($self, $who, $values) = @_;
    do_log('debug2', 'List::update_user(%s)', $who);
    $who = lc($who);    

    my ($field, $value);
    
    ## Subscribers extracted from external data source
    if ($self->{'admin'}{'user_data_source'} eq 'include') {
	&do_log('notice', 'Cannot update user in list %s, user_data_source include', $self->{'admin'}{'user_data_source'});
	return undef;

	## Subscribers stored in database
    } elsif ($self->{'admin'}{'user_data_source'} eq 'database') {
	
	my ($user, $statement, $table);
	my $name = $self->{'name'};
	
	## mapping between var and field names
	my %map_field = ( reception => 'reception_subscriber',
			  visibility => 'visibility_subscriber',
			  date => 'date_subscriber',
			  update_date => 'update_subscriber',
			  gecos => 'comment_subscriber',
			  password => 'password_user',
			  bounce => 'bounce_subscriber',
			  email => 'user_subscriber'
			  );
	
	## mapping between var and tables
	my %map_table = ( reception => 'subscriber_table',
			  visibility => 'subscriber_table',
			  date => 'subscriber_table',
			  update_date => 'subscriber_table',
			  gecos => 'subscriber_table',
			  password => 'user_table',
			  bounce => 'subscriber_table',
			  email => 'subscriber_table'
			  );
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   
	
	## Update each table
	foreach $table ('user_table','subscriber_table') {
	    
	    my @set_list;
	    while (($field, $value) = each %{$values}) {

		next unless ($map_field{$field} and $map_table{$field});

		if ($map_table{$field} eq $table) {
		    if ($field eq 'date') {
			$value = sprintf $date_format{'write'}{$Conf{'db_type'}}, $value, $value;
		    }elsif ($field eq 'update_date') {
			$value = sprintf $date_format{'write'}{$Conf{'db_type'}}, $value, $value;
		    }elsif ($value eq 'NULL'){
			if ($Conf{'db_type'} eq 'mysql') {
			    $value = '\N';
			}
		    }else {
			$value = $dbh->quote($value);
		    }
		    my $set = sprintf "%s=%s", $map_field{$field}, $value;
		    push @set_list, $set;
		}
	    }
	    next unless @set_list;
	    
	    ## Update field
	    if ($table eq 'user_table') {
		$statement = sprintf "UPDATE %s SET %s WHERE (email_user=%s)", $table, join(',', @set_list), $dbh->quote($who); 

	    }elsif ($table eq 'subscriber_table') {

		    $statement = sprintf "UPDATE %s SET %s WHERE (user_subscriber=%s AND list_subscriber=%s)", $table, join(',', @set_list), $dbh->quote($who), $dbh->quote($name);
	    }
	    
	    unless ($dbh->do($statement)) {
		do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		return undef;
	    }
	}

	## Subscribers in text file
    }else {
	my $user = $self->{'users'}->{$who};
	return undef unless $user;
	
	my %u = split(/\n/, $user);
	my ($i, $j);
	$u{$i} = $j while (($i, $j) = each %{$values});
	
	while (($field, $value) = each %{$values}) {
	    $u{$field} = $value;
	}
	
	$user = join("\n", %u);      
	if ($values->{'email'}) {

	    ## Decrease total if new email was already subscriber
	    if ($self->{'users'}->{$values->{'email'}}) {
		$self->{'total'}--;
	    }
	    delete $self->{'users'}{$who};
	    $self->{'users'}->{$values->{'email'}} = $user;
	}else {
	    $self->{'users'}->{$who} = $user;
	}
    }
    
    return 1;
}

## Sets new values for the given user in the Database
sub update_user_db {
    my($who, $values) = @_;
    do_log('debug2', 'List::update_user_db(%s)', $who);
    $who = lc($who);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    ## encrypt password   
    $values->{'password'} = &tools::crypt_password($values->{'password'}) if ($values->{'password'});

    my ($field, $value);
    
    my ($user, $statement, $table);
    
    ## mapping between var and field names
    my %map_field = ( gecos => 'gecos_user',
		      password => 'password_user',
		      cookie_delay => 'cookie_delay_user',
		      lang => 'lang_user',
		      email => 'email_user'
		      );
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    ## Update each table
    my @set_list;
    while (($field, $value) = each %{$values}) {
	next unless ($map_field{$field});
	my $set;
	
	if ($map_field{$field} eq 'cookie_delay_user')  {
	    $set = sprintf '%s=%s', $map_field{$field}, $value;
	}else { 
	    $set = sprintf '%s=%s', $map_field{$field}, $dbh->quote($value);
	}

	push @set_list, $set;
    }
    
    return undef 
	unless @set_list;
    
    ## Update field

    $statement = sprintf "UPDATE user_table SET %s WHERE (email_user=%s)"
	    , join(',', @set_list), $dbh->quote($who); 
    
    unless ($dbh->do($statement)) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    return 1;
}

## Adds a new user to Database (in User table)
sub add_user_db {
    my($values) = @_;
    do_log('debug2', 'List::add_user_db');

    my ($field, $value);
    my ($user, $statement, $table);
    
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
 
    ## encrypt password   
    $values->{'password'} = &tools::crypt_password($values->{'password'}) if $values->{'password'};
    
    return undef unless (my $who = lc($values->{'email'}));
    
    return undef if (is_user_db($who));
    
    ## mapping between var and field names
    my %map_field = ( email => 'email_user',
		      gecos => 'gecos_user',
		      password => 'password_user',
		      cookie_delay => 'cookie_delay_user',
		      lang => 'lang_user'
		      );
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    ## Update each table
    my (@insert_field, @insert_value);
    while (($field, $value) = each %{$values}) {
	
	next unless ($map_field{$field});
	
	my $insert = sprintf "%s", $dbh->quote($value);
	push @insert_value, $insert;
	push @insert_field, $map_field{$field}
    }
    
    return undef 
	unless @insert_field;
    
    ## Update field
    $statement = sprintf "INSERT INTO user_table (%s) VALUES (%s)"
	, join(',', @insert_field), join(',', @insert_value); 
    
    unless ($dbh->do($statement)) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    return 1;
}

## Adds a new user, no overwrite.
sub add_user {
    my($self, $values) = @_;
    do_log('debug2', 'List::add_user');
    my $who;

    my $date_field = sprintf $date_format{'write'}{$Conf{'db_type'}}, $values->{'date'}, $values->{'date'};
    my $update_field = sprintf $date_format{'write'}{$Conf{'db_type'}}, $values->{'update'}, $values->{'update'};

    return undef
	unless ($who = lc($values->{'email'}));
    
    if ($self->{'admin'}{'user_data_source'} eq 'database') {
	
	my $name = $self->{'name'};
	
	$list_cache{'is_user'}{$name}{$who} = undef;

	my $statement;
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   
	
	## Is the email in user table ?
	if (! is_user_db($who)) {
	    ## Insert in User Table
	    $statement = sprintf "INSERT INTO user_table (email_user, gecos_user, lang_user, password_user) VALUES (%s,%s,%s,%s)",$dbh->quote($who), $dbh->quote($values->{'gecos'}), $dbh->quote($values->{'lang'}), $dbh->quote($values->{'password'});
	    
	    unless ($dbh->do($statement)) {
		do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	       return undef;
	    }
	}

	## Update Subscriber Table
	$statement = sprintf "INSERT INTO subscriber_table (user_subscriber, comment_subscriber, list_subscriber, date_subscriber, update_subscriber, reception_subscriber, visibility_subscriber) VALUES (%s, %s, %s, %s, %s, %s, %s)", $dbh->quote($who), $dbh->quote($values->{'gecos'}), $dbh->quote($name), $date_field, $update_field, $dbh->quote($values->{'reception'}), $dbh->quote($values->{'visibility'});
       
	unless ($dbh->do($statement)) {
	    do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}

	$self->{'total'}++;
	
    }else {
	my (%u, $i, $j);
	
	$self->{'total'}++ unless ($self->{'users'}->{$who});
	$u{$i} = $j while (($i, $j) = each %{$values});
	$self->{'users'}->{$who} = join("\n", %u);
    }

   $self->savestats();

   return 1;
}

## Is the user listmaster
sub is_listmaster {
    my $who = shift;
    my $robot = shift;

    $who =~ y/A-Z/a-z/;

    return 0 unless ($who);

    if ($robot && $Conf{'robots'}{$robot}{'listmasters'}) {
	foreach my $listmaster (@{$Conf{'robots'}{$robot}{'listmasters'}}){
	    return 1 if ($listmaster =~ /^\s*$who\s*$/i);
	} 
    }
	
    foreach my $listmaster (@{$Conf{'listmasters'}}){
	    return 1 if ($listmaster =~ /^\s*$who\s*$/i);
	}    

    return 0;
}

## Does the user have a particular function in the list ?
sub am_i {
    my($self, $function, $who) = @_;
    do_log('debug2', 'List::am_i(%s, %s)', $function, $who);

    my $u;
    
    return undef unless ($self && $who);
    $function =~ y/A-Z/a-z/;
    $who =~ y/A-Z/a-z/;
    chomp($who);
    
    ## Listmaster has all privileges except editor
    # sa contestable.
    return 1 if (($function eq 'owner') and &is_listmaster($who,$self->{'domain'}));

    if ($function =~ /^editor$/i){
	if ($self->{'admin'}{$function} && ($#{$self->{'admin'}{$function}} >= 0)) {
	    foreach $u (@{$self->{'admin'}{$function}}) {
		return 1 if ($u->{'email'} =~ /^$who$/i);
	    }
	    ## if no editor defined, owners has editor privilege
	}else{
	    foreach $u (@{$self->{'admin'}{'owner'}}) {
		return 1 if ($u->{'email'} =~ /^$who$/i);
	    } 
	}
	return undef;
    }
    ## Check owners
    if ($function =~ /^owner$/i){
	return undef unless ($self->{'admin'} && $self->{'admin'}{'owner'});
	
	foreach $u (@{$self->{'admin'}{'owner'}}) {
	    return 1 if ($u->{'email'} =~ /^$who$/i);
	}
    }
    elsif ($function =~ /^privileged_owner$/i) {
	foreach $u (@{$self->{'admin'}{'owner'}}) {
	    return 1 if (($u->{'email'} =~ /^$who$/i) && ($u->{'profile'} =~ 'privileged'));
	}
    }
    return undef;
}

## Return the state for simple functions
sub get_state {
    my($self, $action) = @_;
    do_log('debug2', 'List::get_state(%s)', $action);
    
    my $i;
    
    my $admin = $self->{'admin'};
    if ($action =~ /^sig$/io) {
	$i = $admin->{'unsubscribe'}{'name'};
	return 'open' if ($i =~ /^(open|public)$/io);
	return 'closed' if ($i =~ /^closed$/io);
	return 'auth' if ($i =~ /^auth$/io);
	return 'owner' if ($i =~ /^owner$/io);
	
    }elsif ($action =~ /^sub$/io) {
	$i = $admin->{'subscribe'}{'name'};
	return 'open' if ($i =~ /^(open|public)$/io);
	return 'auth' if ($i =~ /^auth$/io);
	return 'owner' if ($i =~ /^owner$/io);
	return 'closed' if ($i =~ /^closed$/io);
    }
    
    return undef;
}



## Return the action to perform for 1 sender using 1 auth method to perform 1 operation
sub request_action {
    my $operation = shift;
    my $auth_method = shift;
    my $robot=shift;
    my $context = shift;
    my $debug = shift;
    do_log('debug2', 'List::request_action %s,%s,%s',$operation,$auth_method,$robot);

    $context->{'sender'} ||= 'nobody' ;
    $context->{'email'} ||= $context->{'sender'};
    $context->{'remote_host'} ||= 'unknown_host' ;
    $context->{'robot_domain'} = $robot ;


    unless ( $auth_method =~ /^(smtp|md5|pgp|smime)/) {
	do_log ('info',"fatal error : unknown auth method $auth_method in List::get_action");
	return undef;
    }
    my (@rules, $name) ;
    my $list;
    if ($context->{'listname'}) {
        unless ( $list = new List ($context->{'listname'}) ){
	    do_log ('info',"request_action :  unable to create object $context->{'listname'}");
	    return undef ;
	}

	## provide subscriber information
	$context->{'subscriber'} = $list->get_subscriber($context->{'sender'});

	my @operations = split /\./, $operation;
	my $data_ref;
	if ($#operations == 0) {
	    $data_ref = $list->{'admin'}{$operation};
	}else{
	    $data_ref = $list->{'admin'}{$operations[0]}{$operations[1]};
	}
	
	unless (defined $data_ref) {
	    do_log ('info',"request_action: no entry $operation defined for list");
	    return undef ;
	}

	## pending/closed lists => send/visibility are closed
	unless ($list->{'admin'}{'status'} eq 'open') {
	    if ($operation =~ /^send|visibility$/) {
		return 'undef';
	    }
	}

	### the following lines are used by the document sharing action 
	if (defined $context->{'scenario'}) { 
	    # information about the  scenario to load
	    my $s_name = $context->{'scenario'}; 
	    
	    # loading of the structure
	    my $scenario;
	    return undef
		unless($scenario = &_load_scenario_file ($operations[$#operations], $robot, $s_name,$list->{'dir'}));
	    @rules = @{$scenario->{'rules'}};
	    $name = $scenario->{'name'}; 
	    $data_ref = $scenario;
	}

	@rules = @{$data_ref->{'rules'}};
	$name = $data_ref->{'name'};

    }elsif ($context->{'topicname'}) {
	my $scenario = $list_of_topics{$robot}{$context->{'topicname'}}{'visibility'};
	@rules = @{$scenario->{'rules'}};
	$name = $scenario->{'name'};

    }else{	
	my $scenario;
	return undef 
	    unless ($scenario = &_load_scenario_file ($operation, $robot, $Conf{'robots'}{$robot}{$operation} || $Conf{$operation}));
        @rules = @{$scenario->{'rules'}};
	$name = $scenario->{'name'};
    }

    unless ($name) {
	do_log ('err',"internal error : configuration for operation $operation is not yet performed by scenario");
	return undef;
    }
    foreach my $rule (@rules) {
	next if ($rule eq 'scenario');
	if ($auth_method eq $rule->{'auth_method'}) {
	    my $result =  &verify ($context,$rule->{'condition'});

	    if (! defined ($result)) {
		do_log ('info',"error in $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'}" );

#		if (defined $context->{'listname'}) {
		&do_log('info', 'Error in %s scenario, in list %s', $context->{'scenario'}, $context->{'listname'});
#		}

		if ($debug) {
		    return ("error-performing-condition : $rule->{'condition'}",$rule->{'auth_method'},'reject') ;
		}
		#return 'reject';
		return undef;
	    }
	    if ($result == -1) {
		do_log ('debug2',"rule $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'} rejected");
		next;
	    }
	    if ($result == 1) {
		do_log ('debug2',"rule $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'} accepted");
		if ($debug) {
		    return ($rule->{'condition'},$rule->{'auth_method'},$rule->{'action'});
		}
		return $rule->{'action'};
	    }
	}
    }
    do_log ('debug2',"no rule match, reject");
    return ('default','default','reject');
}

## Initialize internal list cache
sub init_list_cache {
    &do_log('debug2', 'List::init_list_cache()');
    
    undef %list_cache;
}

## Initialize internal list cache
sub init_list_cache {
    &do_log('debug2', 'List::init_list_cache()');
    
    undef %list_cache;
}

## check if email respect some condition
sub verify {
    my ($context, $condition) = @_;
    do_log('debug2', 'List::verify(%s)', $condition);

#    while (my($k,$v) = each %{$context}) {
#	do_log ('debug2',"verify: context->{$k} = $v");
#    }

    unless (defined($context->{'sender'} )) {
	do_log('info',"internal error, no sender find in List::verify, report authors");
	return undef;
    }

    $context->{'execution_date'} = time unless ( defined ($context->{'execution_date'}) );

    if (defined ($context->{'msg'})) {
	my $header = $context->{'msg'}->head;
	unless (($header->get('to') && ($header->get('to') =~ /$context->{'listname'}/i)) || 
		($header->get('cc') && ($header->get('cc') =~ /$context->{'listname'}/i))) {
	    $context->{'is_bcc'} = 1;
	}else{
	    $context->{'is_bcc'} = 0;
	}
	
    }
    my $list;
    if (defined ($context->{'listname'})) {
	$list = new List ($context->{'listname'});
	unless ($list) {
	    do_log('err','Unable to create list object %s', $context->{'listname'});
	    return undef;
	}

	$context->{'host'} = $list->{'admin'}{'host'};
    }

    unless ($condition =~ /(\!)?\s*(true|is_listmaster|is_editor|is_owner|is_subscriber|match|equal|message|older|newer|all|search)\s*\(\s*(.*)\s*\)\s*/i) {
	&do_log('err', "error rule syntaxe: unknown condition $condition");
	return undef;
    }
    my $negation = 1 ;
    if ($1 eq '!') {
	$negation = -1 ;
    }

    my $condition_key = lc($2);
    my $arguments = $3;
    my @args;

    while ($arguments =~ s/^\s*(
				\[\w+(\-\>[\w\-]+)?\]
				|
				([\w\-\.]+)
				|
				'[^,)]*'
				|
				"[^,)]*"
				|
				\/([^\/\\]+|\\\/|\\)+[^\\]+\/
				|(\w+)\.ldap
				)\s*,?//x) {
	my $value=$1;

	## Config param
	if ($value =~ /\[conf\-\>([\w\-]+)\]/i) {
	    if ($Conf{$1}) {
		$value =~ s/\[conf\-\>([\w\-]+)\]/$Conf{$1}/;
	    }else{
		do_log('err',"unknown variable context $value in rule $condition");
		return undef;
	    }

	    ## List param
	}elsif ($value =~ /\[list\-\>([\w\-]+)\]/i) {
	    if ($1 eq 'name' and $list->{'name'}) {
		$value =~ s/\[list\-\>([\w\-]+)\]/$list->{'name'}/;
	    }elsif ($list->{'admin'}{$1} and (!ref($list->{'admin'}{$1})) ) {
		$value =~ s/\[list\-\>([\w\-]+)\]/$list->{'admin'}{$1}/;
	    }else{
		do_log('err','Unknown list parameter %s in rule %s', $value, $condition);
		return undef;
	    }

	    ## Sender's user/subscriber attributes (if subscriber)
	}elsif (($value =~ /\[(user|subscriber)\-\>([\w\-]+)\]/i) && defined ($context->{$1})) {

	    $value =~ s/\[(user|subscriber)\-\>([\w\-]+)\]/$context->{$1}{$2}/;

	    ## SMTP Header field
	}elsif ($value =~ /\[(msg_header|header)\-\>([\w\-]+)\]/i) {
	    if (defined ($context->{'msg'})) {
		my $header = $context->{'msg'}->head;
		my $field = $header->get($2);
		$value =~ s/\[header\-\>([\w\-]+)\]/$field/;
	    }else {
		return -1;
	    }
	    
	}elsif ($value =~ /\[msg_body\]/i) {
	    return -1 unless (defined ($context->{'msg'}));
	    return -1 unless (defined ($context->{'msg'}->effective_type() =~ /^text/));
	    return -1 unless (defined $context->{'msg'}->bodyhandle);

	    $value = $context->{'msg'}->bodyhandle->as_string();

	}elsif ($value =~ /\[msg_part\-\>body\]/i) {
	    return -1 unless (defined ($context->{'msg'}));
	    
	    my @bodies;
	    my @parts = $context->{'msg'}->parts();
	    foreach my $i (0..$#parts) {
		next unless ($parts[$i]->effective_type() =~ /^text/);
		next unless ($parts[$i]->bodyhandle);

		push @bodies, $parts[$i]->bodyhandle->as_string();
	    }
	    $value = \@bodies;

	}elsif ($value =~ /\[msg_part\-\>type\]/i) {
	    return -1 unless (defined ($context->{'msg'}));
	    
	    my @types;
	    my @parts = $context->{'msg'}->parts();
	    foreach my $i (0..$#parts) {
		push @types, $parts[$i]->effective_type();
	    }
	    $value = \@types;

	    ## Quoted string
	}elsif ($value =~ /\[(\w+)\]/i) {

	    if (defined ($context->{$1})) {
		$value =~ s/\[(\w+)\]/$context->{$1}/i;
	    }else{
		do_log('err',"unknown variable context $value in rule $condition");
		return undef;
	    }
	    
	}elsif ($value =~ /^'(.*)'$/ || $value =~ /^"(.*)"$/) {
	    $value = $1;
	}
	push (@args,$value);
	
    }
    # condition that require 0 argument
    if ($condition_key =~ /^true|all$/i) {
	unless ($#args == -1){ 
	    do_log('err',"error rule syntaxe : incorrect number of argument or incorrect argument syntaxe $condition") ; 
	    return undef ;
	}
	# condition that require 1 argument
    }elsif ($condition_key eq 'is_listmaster') {
	unless ($#args == 0) { 
	     do_log ('err',"error rule syntaxe : incorrect argument number for condition $condition_key") ; 
	    return undef ;
	}
	# condition that require 2 args
#
    }elsif ($condition_key =~ /^is_owner|is_editor|is_subscriber|match|equal|message|newer|older|search$/i) {
	unless ($#args == 1) {
	    do_log ('err',"error rule syntaxe : incorrect argument number for condition $condition_key") ; 
	    return undef ;
	}
    }else{
	do_log('err', "error rule syntaxe : unknown condition $condition_key");
	return undef;
    }
    ## Now eval the condition
    ##### condition : true
    if ($condition_key =~ /\s*(true|any|all)\s*/i) {
	return $negation;
    }
    ##### condition is_listmaster
    if ($condition_key eq 'is_listmaster') {
	
	if ($args[0] eq 'nobody') {
	    return -1 * $negation ;
	}

	if ( &is_listmaster($args[0],$context->{'robot_domain'})) {
	    return $negation;
	}else{
	    return -1 * $negation;
	}
    }

    ##### condition older
    if ($condition_key =~ /older|newer/) {
	 
	$negation *= -1 if ($condition_key eq 'newer');
 	my $arg0 = &tools::epoch_conv($args[0]);
 	my $arg1 = &tools::epoch_conv($args[1]);
 
 	if ($arg0 <= $arg1 ) {
 	    return $negation;
 	}else{
 	    return -1 * $negation;
 	}
     }


    ##### condition is_owner, is_subscriber and is_editor
    if ($condition_key =~ /is_owner|is_subscriber|is_editor/i) {

	my ($list2);

	if ($args[1] eq 'nobody') {
	    return -1 * $negation ;
	}

	$list2 = new List ($args[0]);
	if (! $list2) {
	    do_log('err',"unable to create list object \"$args[0]\"");
	    return undef;
	}

	if ($condition_key eq 'is_subscriber') {

	    if ($list2->is_user($args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }

	}elsif ($condition_key eq 'is_owner') {
	    if ($list2->am_i('owner',$args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }

	}elsif ($condition_key eq 'is_editor') {
	    if ($list2->am_i('editor',$args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }
	}
    }
    ##### match
    if ($condition_key eq 'match') {
	unless ($args[1] =~ /^\/(.*)\/$/) {
	    &do_log('err', 'Match parameter %s is not a regexp', $args[1]);
	    return undef;
	}
	my $regexp = $1;
	
	if ($regexp =~ /\[host\]/) {
	    my $reghost = $Conf{'host'};
            $reghost =~ s/\./\\./g ;
            $regexp =~ s/\[host\]/$reghost/g ;
	}

	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		return $negation 
		    if ($arg =~ /$regexp/i);
	    }
	}else {
	    if ($args[0] =~ /$regexp/i) {
		return $negation ;
	    }
	}
	
	return -1 * $negation ;

    }
    
    ##search
    if ($condition_key eq 'search') {
	my $val_search = &search($args[0],$args[1],$context->{'robot_domain'});
	if($val_search == 1) { 
	    return $negation;
	}else {
	    return -1 * $negation;
    	}
    }

    ## equal
    if ($condition_key eq 'equal') {
	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		&do_log('debug2', 'ARG: %s', $arg);
		return $negation 
		    if ($arg =~ /^$args[1]$/i);
	    }
	}else {
	    if ($args[0] =~ /^$args[1]$/i) {
		return $negation ;
	    }
	}

	return -1 * $negation ;
    }
    return undef;
}

## Verify if a given user is part of an LDAP search filter
sub search{
    my $ldap_file = shift;
    my $sender = shift;
    my $robot = shift;

    &do_log('debug2', 'List::search(%s,%s,%s)', $ldap_file, $sender, $robot);

    my $file;

    unless ($file = &tools::get_filename('etc',"search_filters/$ldap_file", $robot)) {
	&do_log('err', 'Could not find LDAP filter %s', $ldap_file);
	return undef;
    }   

    my $timeout = 3600;

    my $var;
    my $time = time;
    my $value;

    my %ldap_conf;

    return undef unless (%ldap_conf = &Ldap::load($file));

 
    my $filter = $ldap_conf{'filter'};	
    $filter =~ s/\[sender\]/$sender/;
    
    if (defined ($persistent_cache{'named_filter'}{$ldap_file}{$filter}) &&
	(time <= $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'update'} + $timeout)){ ## Cache has 1hour lifetime
        &do_log('notice', 'Using previous LDAP named filter cache');
        return $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'};
    }

    unless (require Net::LDAP) {
	do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
	return undef;
    }
    
    my $ldap = Net::LDAP->new($ldap_conf{'host'},port => $ldap_conf{'port'} );
    
    unless ($ldap) {	
    	do_log('notice','Unable to connect to the LDAP server %s',$ldap_conf{'host'});
	return undef;
    }
    
    $ldap->bind();
    my $mesg = $ldap->search(base => "$ldap_conf{'suffix'}" ,
			     filter => "$filter",
			     scope => "$ldap_conf{'scope'}");
    	

    if ($mesg->count() == 0){
   	$persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'} = 0;
	
    }else {
   	$persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'} = 1;
    }
      	
    $ldap->unbind or do_log('notice','List::search_ldap.Unbind impossible');
    $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'update'} = time;

    return $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'};
}

## May the indicated user edit the indicated list parameter or not ?
sub may_edit {

    my($self,$parameter, $who) = @_;
    do_log('debug2', 'List::may_edit(%s, %s)', $parameter, $who);

    my $role;

    return undef unless ($self);

    my $edit_conf;
    
    if (! $edit_list_conf{$self->{'domain'}} || ((stat(&tools::get_filename('etc','edit_list.conf',$self->{'domain'})))[9] > $mtime{'edit_list_conf'}{$self->{'domain'}})) {

        $edit_conf = $edit_list_conf{$self->{'domain'}} = &tools::load_edit_list_conf($self->{'domain'});
	$mtime{'edit_list_conf'}{$self->{'domain'}} = time;
    }else {
        $edit_conf = $edit_list_conf{$self->{'domain'}};
    }

    ## What privilege ?
    if (&is_listmaster($who,$self->{'domain'})) {
	$role = 'listmaster';
    }elsif ( $self->am_i('privileged_owner',$who) ) {
	$role = 'privileged_owner';
	
    }elsif ( $self->am_i('owner',$who) ) {
	$role = 'owner';
	
    }elsif ( $self->am_i('editor',$who) ) {
	$role = 'editor';
	
#    }elsif ( $self->am_i('subscriber',$who) ) {
#	$role = 'subscriber';
#	
    }else {
	return 'hidden';
    }

    ## What privilege does he/she has ?
    my ($what, @order);

    if (($parameter =~ /^(\w+)\.(\w+)$/) &&
	($parameter !~ /\.tpl$/)) {
	my $main_parameter = $1;
	@order = ($edit_conf->{$parameter}{$role},
		  $edit_conf->{$main_parameter}{$role}, 
		  $edit_conf->{'default'}{$role}, 
		  $edit_conf->{'default'}{'default'})
    }else {
	@order = ($edit_conf->{$parameter}{$role}, 
		  $edit_conf->{'default'}{$role}, 
		  $edit_conf->{'default'}{'default'})
    }
    
    foreach $what (@order) {
	if (defined $what) {
	    return $what;
	}
    }
    
    return 'hidden';
}


## May the indicated user edit a paramter while creating a new list
# sa cette proc�dure est appel�e nul part, je lui ajoute malgr�s tout le param�tre robot
# edit_conf devrait �tre aussi d�pendant du robot
sub may_create_parameter {

    my($parameter, $who,$robot) = @_;
    do_log('debug2', 'List::may_create_parameter(%s, %s, %s)', $parameter, $who,$robot);

    if ( &is_listmaster($who,$robot)) {
	return 1;
    }
    my $edit_conf = &tools::load_edit_list_conf($robot);
    $edit_conf->{$parameter} ||= $edit_conf->{'default'};
    if (! $edit_conf->{$parameter}) {
	do_log('notice','tools::load_edit_list_conf privilege for parameter $parameter undefined');
	return undef;
    }
    if ($edit_conf->{$parameter}  =~ /^(owner)||(privileged_owner)$/i ) {
	return 1;
    }else{
	return 0;
    }

}


## May the indicated user do something with the list or not ?
## Action can be : send, review, index, get
##                 add, del, reconfirm, purge
sub may_do {
   my($self, $action, $who) = @_;
   do_log('debug2', 'List::may_do(%s, %s)', $action, $who);

   my $i;

   ## Just in case.
   return undef unless ($self && $action);
   my $admin = $self->{'admin'};
   return undef unless ($admin);

   $action =~ y/A-Z/a-z/;
   $who =~ y/A-Z/a-z/;

   if ($action =~ /^(index|get)$/io) {
       my $arc_access = $admin->{'archive'}{'access'};
       if ($arc_access =~ /^public$/io)  {
	   return 1;
       }elsif ($arc_access =~ /^private$/io) {
	   return 1 if ($self->is_user($who));
	   return $self->am_i('owner', $who);
       }elsif ($arc_access =~ /^owner$/io) {
	   return $self->am_i('owner', $who);
       }
       return undef;
   }

   if ($action =~ /^(review)$/io) {
       foreach $i (@{$admin->{'review'}}) {
	   if ($i =~ /^public$/io) {
	       return 1;
	   }elsif ($i =~ /^private$/io) {
	       return 1 if ($self->is_user($who));
	       return $self->am_i('owner', $who);
	   }elsif ($i =~ /^owner$/io) {
	       return $self->am_i('owner', $who);
	   }
	   return undef;
       }
   }

   if ($action =~ /^send$/io) {
      if ($admin->{'send'} =~/^(private|privateorpublickey|privateoreditorkey)$/i) {

         return undef unless ($self->is_user($who) || $self->am_i('owner', $who));
      }elsif ($admin->{'send'} =~ /^(editor|editorkey|privateoreditorkey)$/i) {
         return undef unless ($self->am_i('editor', $who));
      }elsif ($admin->{'send'} =~ /^(editorkeyonly|publickey|privatekey)$/io) {
         return undef;
      }
      return 1;
   }

   if ($action =~ /^(add|del|remind|reconfirm|purge|expire)$/io) {
      return $self->am_i('owner', $who);
   }

   if ($action =~ /^(modindex)$/io) {
       return undef unless ($self->am_i('editor', $who));
       return 1;
   }

   if ($action =~ /^auth$/io) {
       if ($admin->{'send'} =~ /^(privatekey)$/io) {
	   return 1 if ($self->is_user($who) || $self->am_i('owner', $who));
       } elsif ($admin->{'send'} =~ /^(privateorpublickey)$/io) {
	   return 1 unless ($self->is_user($who) || $self->am_i('owner', $who));
       }elsif ($admin->{'send'} =~ /^(publickey)$/io) {
	   return 1;
       }
       return undef; #authent
   } 
   return undef;
}

## Is the list moderated ?
sub is_moderated {
    return 1 if (defined shift->{'admin'}{'editor'});

    return 0;
}

## Is the list moderated with a key?
sub is_moderated_key {
   return (shift->{'admin'}->{'send'}{'name'}=~/^(editorkeyonly|editorkey|privateoreditorkey)$/);
}

## Is the list moderated with a key?
sub is_privateoreditorkey {
   return (shift->{'admin'}{'send'}{'name'}=~/^privateoreditorkey$/);
}

## Is the list auth with a key?
sub is_private_key {
   return (shift->{'admin'}->{'send'}{'name'}=~/^privatekey$/);
}

## Is the list auth with a key?
sub is_public_key {
   return (shift->{'admin'}{'send'}{'name'}=~/^publickey$/);
}

## Is the list auth with a key?
sub is_authentified {
   return (shift->{'admin'}{'send'}{'name'}=~/^(publickey|privatekey|privateorpublickey)$/);
}

## Does the list support digest mode
sub is_digest {
   return (shift->{'admin'}{'digest'});
}

## Does the file exist ?
sub archive_exist {
   my($self, $file) = @_;
   do_log('debug2', 'List::archive_exist(%s)', $file);

   return undef unless ($self->is_archived());
   Archive::exist("$self->{'dir'}/archives", $file);
}

## Send an archive file to someone
sub archive_send {
   my($self, $who, $file) = @_;
   do_log('debug2', 'List::archive_send(%s, %s)', $who, $file);

   return unless ($self->is_archived());
   my $i;
   if ($i = Archive::exist("$self->{'dir'}/archives", $file)) {
      mail::mailarc($i, Msg(8, 7, "File") . " $self->{'name'} $file",$who );
   }
}

## List the archived files
sub archive_ls {
   my $self = shift;
   do_log('debug2', 'List::archive_ls');

   Archive::list("$self->{'dir'}/archives") if ($self->is_archived());
}

## Archive 
sub archive_msg {
    my($self, $msg ) = @_;
    do_log('debug2', 'List::archive_msg for %s',$self->{'name'});

    my $is_archived = $self->is_archived();
    Archive::store("$self->{'dir'}/archives",$is_archived, $msg)  if ($is_archived);

    Archive::outgoing("$Conf{'queueoutgoing'}","$self->{'name'}\@$self->{'admin'}{'host'}",$msg) 
      if ($self->is_web_archived());
}

sub archive_msg_digest {
   my($self, $msg) = @_;
   do_log('debug2', 'List::archive_msg_digest');

   $self->store_digest( $msg) if ($self->{'name'});
}

## Is the list archived ?
sub is_archived {
    do_log('debug2', 'List::is_archived');
    return (shift->{'admin'}{'archive'}{'period'});
}

## Is the list web archived ?
sub is_web_archived {
    return 1 if (shift->{'admin'}{'web_archive'}{'access'}) ;
    return undef;
   
}

## Returns 1 if the  digest  must be send 
sub get_nextdigest {
    my $self = shift;
    do_log('debug2', 'List::get_nextdigest (%s)');

    my $digest = $self->{'admin'}{'digest'};
    my $listname = $self->{'name'};

    unless (-f "$Conf{'queuedigest'}/$listname") {
	return undef;
    }

    unless ($digest) {
	return undef;
    }
    
    my @days = @{$digest->{'days'}};
    my ($hh, $mm) = ($digest->{'hour'}, $digest->{'minute'});
     
    my @now  = localtime(time);
    my $today = $now[6]; # current day
    my @timedigest = localtime( (stat "$Conf{'queuedigest'}/$listname")[9]);

    ## Should we send a digest today
    my $send_digest = 0;
    foreach my $d (@days){
	if ($d == $today) {
	    $send_digest = 1;
	    last;
	}
    }

    return undef
	unless ($send_digest == 1);

    if (($now[2] * 60 + $now[1]) >= ($hh * 60 + $mm) and 
	(timelocal(0, $mm, $hh, $now[3], $now[4], $now[5]) > timelocal(0, $timedigest[1], $timedigest[2], $timedigest[3], $timedigest[4], $timedigest[5]))
        ){
	return 1;
    }

    return undef;
}

## load a scenario if not inline (in the list configuration file)
sub _load_scenario_file {
    my ($function, $robot, $name, $directory)= @_;
    do_log('debug2', 'List::_load_scenario_file(%s, %s, %s, %s)', $function, $robot, $name, $directory);

    my $structure;
    
    ## List scenario

   
    # sa tester le chargement de scenario sp�cifique � un r�pertoire du shared
    my $scenario_file = $directory.'/scenari/'.$function.'.'.$name ;
    unless (($directory) && (open SCENARI, $scenario_file)) {
	## Robot scenario
	$scenario_file = "$Conf{'etc'}/$robot/scenari/$function.$name";
	unless (($robot) && (open SCENARI, $scenario_file)) {

	    ## Site scenario
	    $scenario_file = "$Conf{'etc'}/scenari/$function.$name";
	    unless (($robot) && (open SCENARI, $scenario_file)) {
		
		## Distrib scenario
		$scenario_file = "--ETCBINDIR--/scenari/$function.$name";
		unless (open SCENARI,$scenario_file) {
		    do_log ('err',"Unable to open scenario file $function.$name, please report to listmaster") unless ($name =~ /\.header$/) ;
		    return &_load_scenario ($function,$robot,$name,'true() smtp -> reject', $directory) unless ($function eq 'include');
		}
	    }
	}
    }
    my $paragraph= join '',<SCENARI>;
    close SCENARI;
    unless ($structure = &_load_scenario ($function,$robot,$name,$paragraph, $directory)) { 
	do_log ('err',"error in $function scenario $scenario_file ");
    }
    return $structure ;
}

sub _load_scenario {
    my ($function, $robot,$scenario_name, $paragraph, $directory ) = @_;
    # do_log('debug2', 'List::_load_scenario(%s,%s,%s)', $function,$robot,$scenario_name);

    my $structure = {};
    $structure->{'name'} = $scenario_name ;
    my @scenario;
    my @rules = split /\n/, $paragraph;

    ## Following lines are ordered
    push(@scenario, 'scenario');
    unless ($function eq 'include') {
	my $include = &_load_scenario_file ('include',$robot,"$function.header", $directory);
	
	push(@scenario,@{$include->{'rules'}}) if ($include);
    }
    foreach (@rules) {
	next if (/^\s*\w+\s*$/o); # skip paragraph name
	my $rule = {};
	s/\#.*$//;         # remove comments
        next if (/^\s*$/); # reject empty lines
	if (/^\s*title\.(\w+)\s+(.*)\s*$/i) {
	    $structure->{'title'}{$1} = $2;
	    next;
	}
        
        if (/^\s*include\s*(.*)\s*$/i) {
        ## introducing in few common rules using include
	    my $include = &_load_scenario_file ('include',$robot,$1, $directory);
            push(@scenario,@{$include->{'rules'}}) if ($include) ;
	    next;
	}

#	unless (/^\s*(.*)\s+(md5|pgp|smtp|smime)\s*->\s*(.*)\s*$/i) {
	unless (/^\s*(.*)\s+(md5|pgp|smtp|smime)((\s*,\s*(md5|pgp|smtp|smime))*)\s*->\s*(.*)\s*$/i) {
	    do_log ('notice', "error rule syntaxe in scenario $function rule line $. expected : <condition> <auth_mod> -> <action>");
	    do_log ('debug',"error parsing $rule");
	    return undef;
	}
	$rule->{condition}=$1;
	$rule->{auth_method}=$2 || 'smtp';
	$rule->{'action'} = $6;

	
#	## Make action an ARRAY
#	my $action = $6;
#	my @actions;
#	while ($action =~ s/^\s*((\w+)(\s?\([^\)]*\))?)(\s|\,|$)//) {
#	    push @actions, $1;
#	}
#	$rule->{action} = \@actions;
	       
	push(@scenario,$rule);
#	do_log ('debug2', "load rule 1: $rule->{'condition'} $rule->{'auth_method'} ->$rule->{'action'}");

        my $auth_list = $3 ; 
        while ($auth_list =~ /\s*,\s*(md5|pgp|smtp|smime)((\s*,\s*(md5|pgp|smtp|smime))*)\s*/i) {
	    push(@scenario,{'condition' => $rule->{condition}, 
                            'auth_method' => $1,
                            'action' => $rule->{action}});
	    $auth_list = $2;
#	    do_log ('debug2', "load rule ite: $rule->{'condition'} $1 -> $rule->{'action'}");
	}
	
    }
    
    ## Restore paragraph mode
    $structure->{'rules'} = \@scenario;
    return $structure; 
}

## Loads all scenari for an action
sub load_scenario_list {
    my ($self, $action,$robot) = @_;
    do_log('debug2', 'List::load_scenario_list(%s,%s)', $action,$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_scenario;

    foreach my $dir ("$directory/scenari", "$Conf{'etc'}/$robot/scenari", "$Conf{'etc'}/scenari", "--ETCBINDIR--/scenari") {

	next unless (-d $dir);

	while (<$dir/$action.*>) {
	    next unless (/$action\.($regexp{'scenario'})$/);
	    my $name = $1;
	    
	    next if (defined $list_of_scenario{$name});

	    my $scenario = &List::_load_scenario_file ($action, $robot, $name, $directory);
	    $list_of_scenario{$name} = $scenario;
	}
    }

    return \%list_of_scenario;
}

sub load_task_list {
    my ($self, $action,$robot) = @_;
    do_log('debug', 'List::load_task_list(%s,%s)', $action,$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_task;
    
    foreach my $dir ("$directory/list_task_models", "$Conf{'etc'}/$robot/list_task_models", "$Conf{'etc'}/list_task_models", "--ETCBINDIR--/list_task_models") {

	next unless (-d $dir);

	foreach my $file (<$dir/$action.*>) {
	    next unless ($file =~ /$action\.(\w+)\.task$/);
	    my $name = $1;
	    
	    next if (defined $list_of_task{$name});
	    
	    $list_of_task{$name}{'title'} = &List::_load_task_title ($file);
	    $list_of_task{$name}{'name'} = $name;
	}
    }

    return \%list_of_task;
}

sub _load_task_title {
    my $file = shift;
    do_log('debug2', 'List::_load_task_title(%s)', $file);
    my $title = {};

    unless (open TASK, $file) {
	do_log('err', 'Unable to open file "%s"' , $file);
	return undef;
    }

    while (<TASK>) {
	last if /^\s*$/;

	if (/^title\.([\w-]+)\s+(.*)\s*$/) {
	    $title->{$1} = $2;
	}
    }

    close TASK;

    return $title;
}

## Loads the statistics informations
sub _load_stats_file {
    my $file = shift;
    do_log('debug2', 'List::_load_stats_file(%s)', $file);

   ## Create the initial stats array.
   my ($stats, $total);
 
   if (open(L, $file)){     
       if (<L> =~ /^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
	   $stats = [ $1, $2, $3, $4];
	   $total = $5;
       } else {
	   $stats = [ 0, 0, 0, 0];
	   $total = 0;
       }
       close(L);
   } else {
       $stats = [ 0, 0, 0, 0];
       $total = 0;
   }

   ## Return the array.
   return ($stats, $total);
}

## Loads the list of subscribers as a tied hash
sub _load_users {
    my $file = shift;
    do_log('debug2', 'List::_load_users(%s)', $file);

    ## Create the in memory btree using DB_File.
    my %users;
    my @users_list = (&_load_users_file($file)) ;     
    my $btree = new DB_File::BTREEINFO;
    return undef unless ($btree);
    $btree->{'compare'} = '_compare_addresses';
    $btree->{'cachesize'} = 200 * ( $#users_list + 1 ) ;
    my $ref = tie %users, 'DB_File', undef, O_CREAT|O_RDWR, 0600, $btree;
    return undef unless ($ref);

    ## Counters.
    my $total = 0;

    foreach my $user ( @users_list ) {
	my $email = $user->{'email'};
	unless ($users{$email}) {
	    $total++;
	    $users{$email} = join("\n", %{$user});
	    unless ( defined ( $users{$email} )) { 
		# $btree->{'cachesize'} under-sized
		&do_log('err', '_load_users : cachesise too small : (%d users)', $total);
		return undef;  
	    }
	}
    }

    my $l = {
	'ref'	=>	$ref,
	'users'	=>	\%users,
	'total'	=>	$total
	};
    
    $l;
}

## Loads the list of subscribers.
sub _load_users_file {
    my $file = shift;
    do_log('debug2', 'List::_load_users_file(%s)', $file);
    
    ## Open the file and switch to paragraph mode.
    open(L, $file) || return undef;
    my @old = ($*, $/);
    $* = 1; $/ = '';
    
    ## Process the lines
    my @users;
    while (<L>) {
	my(%user, $email);
	$user{'email'} = $email = $1 if (/^\s*email\s+(.+)\s*$/o);
	$user{'gecos'} = $1 if (/^\s*gecos\s+(.+)\s*$/o);
#	$user{'options'} = $1 if (/^\s*options\s+(.+)\s*$/o);
#	$user{'auth'} = $1 if (/^\s*auth\s+(\S+)\s*$/o);
#	$user{'password'} = $1 if (/^\s*password\s+(.+)\s*$/o);
#	$user{'stats'} = "$1 $2 $3" if (/^\s*stats\s+(\d+)\s+(\d+)\s+(\d+)\s*$/o);
#	$user{'firstbounce'} = $1 if (/^\s*firstbounce\s+(\d+)\s*$/o);
	$user{'date'} = $1 if (/^\s*date\s+(\d+)\s*$/o);
	$user{'update_date'} = $1 if (/^\s*update_date\s+(\d+)\s*$/o);
	$user{'reception'} = $1 if (/^\s*reception\s+(digest|nomail|summary|notice|txt|html|urlize|not_me)\s*$/o);
	$user{'visibility'} = $1 if (/^\s*visibility\s+(conceal|noconceal)\s*$/o);

	push @users, \%user;
    }
    close(L);
    
    ($*, $/) = @old;
    
    return @users;
}


## include a list as subscribers.
sub _include_users_list {
    my ($users, $includelistname, $default_user_options) = @_;
    do_log('debug2', 'List::_include_users_list');

    my $total = 0;
    
    my $includelist = new List ($includelistname);
    unless ($includelist) {
	do_log('info', 'Included list %s unknown' , $includelistname);
	return undef;
    }
    
    for (my $user = $includelist->get_first_user(); $user; $user = $includelist->get_next_user()) {
	my %u = %{$default_user_options};
	my $email =  $u{'email'} = $user->{'email'};
	$u{'gecos'} = $user->{'gecos'};
 	$u{'date'} = $user->{'date'};
	$u{'update_date'} = $user->{'update_date'};
 	$u{'reception'} = $user->{'reception'};
 	$u{'visibility'} = $user->{'visibility'};
	unless ($users->{$email}) {
	    $total++;
	    $users->{$email} = join("\n", %u);
	}
    }
    do_log ('info',"Include %d subscribers from list %s",$total,$includelistname);
    return $total ;
}

## include a lists owners lists privileged_owners or lists_editors.
sub _include_users_admin {
    my ($users, $admin_function,$mother_list) = @_;
    do_log('debug', 'List::_include_users_list (users,%s,%s)',$admin_function,$mother_list);

    my $total = 0;
    my $admin;

    my @depend
; 
    foreach my $listname (&List::get_lists('*') ) {

        if ($mother_list eq $listname) {
	    # upfully this proc is not ready to use 
            # sa ce truc ne peut pas marcher
	    $admin = _load_admin_file($listname, 'config');

	}else{
	    my $list = new List ($listname);
	    $admin = $list->{'admin'};
	}
	push @depend, $admin->{'name'};
	
	if ($admin_function =~ /owners/i) {
	    foreach my $owner (@{$admin->{'owner'}}) {
		if (($admin !~ /privileged/i) || ( $owner->{'profile'} eq 'privileged')) {
		    my %u;
		    my $email =  $u{'email'} = $owner->{'email'};
		    $u{'gecos'} = $owner->{'gecos'};
		    unless ($users->{$email}) {
			$total++;
			$users->{$email} = join("\n", %u);
		    }
		}
	    }
	}elsif ($admin =~ /editor/i) {
	    foreach my $editor (@{$admin->{'editor'}}) {
		my %u;
		my $email =  $u{'email'} = $editor->{'email'};
		$u{'gecos'} = $editor->{'gecos'};
		unless ($users->{$email}) {
		    $total++;
		    $users->{$email} = join("\n", %u);
		}
	    }
	}
    }
    my $result = {
	'total' => $total,
        'depend_on' => @depend
    };
    return $result ;
}
    
sub _include_users_file {
    my ($users, $filename, $default_user_options) = @_;
    do_log('debug2', 'List::_include_users_file');

    my $total = 0;
    
    unless (open(INCLUDE, "$filename")) {
	do_log('err', 'Unable to open file "%s"' , $filename);
	return undef;
    }
    do_log('debug','including file %s' , $filename) if ($main::options{'debug'});
    
    while (<INCLUDE>) {
	next if /^\s*$/;
	next if /^\s*\#/;

	unless (/^\s*((\S+|\".*\")@\S+)(\s*(\S.*))?\s*$/) {
	    &do_log('notice', 'Not an email address: %s', $_);
	}

	my $email = lc($1);
	my $gecos = $4;
	my %u = %{$default_user_options};
	$u{'email'} = $email;
	$u{'gecos'} = $gecos;

	if ($email) {
	    $total++;
	    $users->{$email} = join("\n", %u);
	}
    }
    close INCLUDE ;
    
    do_log ('info',"include %d subscribers from file %s",$total,$filename);
    return $total ;
}


## Returns a list of subscribers extracted from a remote LDAP Directory
sub _include_users_ldap {
    my ($users, $param, $default_user_options) = @_;
    do_log('debug2', 'List::_include_users_ldap');
    
    unless (require Net::LDAP) {
	do_log ('debug',"Unable to use LDAP library, install perl-ldap (CPAN) first");
	return undef;
    }

    my $host = $param->{'host'};
    my $port = $param->{'port'} || '389';
    my $user = $param->{'user'};
    my $passwd = $param->{'passwd'};
    my $ldap_suffix = $param->{'suffix'};
    my $ldap_filter = $param->{'filter'};
    my $ldap_attrs = $param->{'attrs'};
    my $ldap_select = $param->{'select'};
    
#    my $default_reception = $admin->{'default_user_options'}{'reception'};
#    my $default_visibility = $admin->{'default_user_options'}{'visibility'};

    ## LDAP and query handler
    my ($ldaph, $fetch);

    ## Connection timeout (default is 120)
    #my $timeout = 30; 
    
    unless ($ldaph = Net::LDAP->new($host, port => "$port", timeout => $param->{'timeout'})) {
	do_log ('notice',"Can\'t connect to LDAP server '$host' '$port' : $@");
	return undef;
    }
    
    do_log('debug', "Connected to LDAP server $host:$port") if ($main::options{'debug'});
    
    if ( defined $user ) {
	unless ($ldaph->bind ($user, password => "$passwd")) {
	    do_log ('notice',"Can\'t bind with server $host:$port as user '$user' : $@");
	    return undef;
	}
    }else {
	unless ($ldaph->bind ) {
	    do_log ('notice',"Can\'t do anonymous bind with server $host:$port : $@");
	    return undef;
	}
    }

    do_log('debug', "Binded to LDAP server $host:$port ; user : '$user'") if ($main::option{'debug'});
    
    do_log('debug', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', $host, $ldap_suffix, $ldap_filter, $ldap_attrs) if ($main::options{'debug'});
    unless ($fetch = $ldaph->search ( base => "$ldap_suffix",
                                      filter => "$ldap_filter",
				      attrs => "$ldap_attrs",
				      scope => "$param->{'scope'}")) {
        do_log('debug',"Unable to perform LDAP search in $ldap_suffix for $ldap_filter : $@");
        return undef;
    }
    
    ## Counters.
    my $total = 0;
    my $dn; 
   
    ## returns a reference to a HASH where the keys are the DNs
    ##  the second level hash's hold the attributes
    my $all_entries = $fetch->as_struct ;

    my @emails;
    foreach $dn (keys %$all_entries) { 
	my $entry = $all_entries->{$dn}{$ldap_attrs};
	
	## Multiple values
	if (ref($entry) eq 'ARRAY') {
	    foreach my $email (@{$entry}) {
		push @emails, $email;
		last if ($ldap_select eq 'first');
	    }
	}else {
	    push @emails, $entry;
	}
    }
    
    unless ($ldaph->unbind) {
	do_log('notice','Can\'t unbind from  LDAP server %s:%s',$host,$port);
	return undef;
    }
    
    foreach my $email (@emails) {
	next if ($email =~ /^\s*$/);
	my %u = %{$default_user_options};
	$u{'email'} = $email;
	$u{'date'} = time;
	$u{'update_date'} = time;
	## should consult user default options
	unless ($users->{$email}) {
	    $total++;
	    $users->{$email} = join("\n", %u);
	}
    }

    do_log ('debug',"unbinded from LDAP server %s:%s ",$host,$port) if ($main::options{'debug'});
    do_log ('debug','%d subscribers included from LDAP query',$total);

    return $total;
}

## Returns a list of subscribers extracted indirectly from a remote LDAP
## Directory using a two-level query
sub _include_users_ldap_2level {
    my ($users, $param, $default_user_options) = @_;
    do_log('debug2', 'List::_include_users_ldap_2level');
    
    unless (require Net::LDAP) {
	do_log ('debug',"Unable to use LDAP library, install perl-ldap (CPAN) first");
	return undef;
    }

    my $host = $param->{'host'};
    my $port = $param->{'port'} || '389';
    my $user = $param->{'user'};
    my $passwd = $param->{'passwd'};
    my $ldap_suffix1 = $param->{'suffix1'};
    my $ldap_filter1 = $param->{'filter1'};
    my $ldap_attrs1 = $param->{'attrs1'};
    my $ldap_select1 = $param->{'select1'};
    my $ldap_scope1 = $param->{'scope1'};
    my $ldap_regex1 = $param->{'regex1'};
    my $ldap_suffix2 = $param->{'suffix2'};
    my $ldap_filter2 = $param->{'filter2'};
    my $ldap_attrs2 = $param->{'attrs2'};
    my $ldap_select2 = $param->{'select2'};
    my $ldap_scope2 = $param->{'scope2'};
    my $ldap_regex2 = $param->{'regex2'};
    
#    my $default_reception = $admin->{'default_user_options'}{'reception'};
#    my $default_visibility = $admin->{'default_user_options'}{'visibility'};

    ## LDAP and query handler
    my ($ldaph, $fetch);

    ## Connection timeout (default is 120)
    #my $timeout = 30; 
    
    unless ($ldaph = Net::LDAP->new($host, port => "$port", timeout => $param->{'timeout'})) {
	do_log ('notice',"Can\'t connect to LDAP server '$host' '$port' : $@");
	return undef;
    }
    
    do_log('debug', "Connected to LDAP server $host:$port") if ($main::options{'debug'});
    
    if ( defined $user ) {
	unless ($ldaph->bind ($user, password => "$passwd")) {
	    do_log ('notice',"Can\'t bind with server $host:$port as user '$user' : $@");
	    return undef;
	}
    }else {
	unless ($ldaph->bind ) {
	    do_log ('notice',"Can\'t do anonymous bind with server $host:$port : $@");
	    return undef;
	}
    }

    do_log('debug', "Binded to LDAP server $host:$port ; user : '$user'") if ($main::option{'debug'});
    
    do_log('debug', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', $host, $ldap_suffix1, $ldap_filter1, $ldap_attrs1) if ($main::options{'debug'});
    unless ($fetch = $ldaph->search ( base => "$ldap_suffix1",
                                      filter => "$ldap_filter1",
				      attrs => "$ldap_attrs1",
				      scope => "$ldap_scope1")) {
        do_log('debug',"Unable to perform LDAP search in $ldap_suffix1 for $ldap_filter1 : $@");
        return undef;
    }
    
    ## Counters.
    my $total = 0;
    my $dn; 
   
    ## returns a reference to a HASH where the keys are the DNs
    ##  the second level hash's hold the attributes
    my $all_entries = $fetch->as_struct ;

    my (@attrs, @emails);
    foreach $dn (keys %$all_entries) { 
	my $entry = $all_entries->{$dn}{$ldap_attrs1};
	
	## Multiple values
	if (ref($entry) eq 'ARRAY') {
	    foreach my $attr (@{$entry}) {
		next if ($ldap_select1 eq 'regex' && ! $attr =~ /$ldap_regex1/);
		push @attrs, $attr;
		last if ($ldap_select1 eq 'first');
	    }
	}else {
	    push @attrs, $entry
		unless ($ldap_select1 eq 'regex' && ! $entry =~ /$ldap_regex1/);
	}
    }

    my ($suffix2, $filter2);
    foreach my $attr (@attrs) {
	($suffix2 = $ldap_suffix2) =~ s/\[attrs1\]/$attr/g;
	($filter2 = $ldap_filter2) =~ s/\[attrs1\]/$attr/g;

	do_log('debug', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', $host, $suffix2, $filter2, $ldap_attrs2) if ($main::options{'debug'});
	unless ($fetch = $ldaph->search ( base => "$suffix2",
					filter => "$filter2",
					attrs => "$ldap_attrs2",
					scope => "$ldap_scope2")) {
	    do_log('debug',"Unable to perform LDAP search in $suffix2 for $filter2 : $@");
	    return undef;
	}

	## returns a reference to a HASH where the keys are the DNs
	##  the second level hash's hold the attributes
	my $all_entries = $fetch->as_struct ;

	foreach $dn (keys %$all_entries) { 
	    my $entry = $all_entries->{$dn}{$ldap_attrs2};

	    ## Multiple values
	    if (ref($entry) eq 'ARRAY') {
		foreach my $email (@{$entry}) {
		    next if ($ldap_select2 eq 'regex' && ! $email =~ /$ldap_regex2/);
		    push @emails, $email;
		    last if ($ldap_select2 eq 'first');
		}
	    }else {
		push @emails, $entry
		    unless ($ldap_select2 eq 'regex' && ! $entry =~ /$ldap_regex2/);
	    }
	}
    }
    
    unless ($ldaph->unbind) {
	do_log('notice','Can\'t unbind from  LDAP server %s:%s',$host,$port);
	return undef;
    }
    
    foreach my $email (@emails) {
	next if ($email =~ /^\s*$/);
	my %u = %{$default_user_options};
	$u{'email'} = $email;
	$u{'date'} = time;
	$u{'update_date'} = time;
	## should consult user default options
	unless ($users->{$email}) {
	    $total++;
	    $users->{$email} = join("\n", %u);
	}
    }

    do_log ('debug',"unbinded from LDAP server %s:%s ",$host,$port) if ($main::options{'debug'});
    do_log ('debug','%d subscribers included from LDAP query',$total);

    return $total;
}

## Returns a list of subscribers extracted from an remote Database
sub _include_users_sql {
    my ($users, $param, $default_user_options) = @_;

    &do_log('debug2','List::_include_users_sql()');

    unless ( require DBI ){
	do_log('notice',"Intall module DBI (CPAN) before using include_sql_query");
	return undef ;
    }

    my $db_type = $param->{'db_type'};
    my $db_name = $param->{'db_name'};
    my $host = $param->{'host'};
    my $user = $param->{'user'};
    my $passwd = $param->{'passwd'};
    my $sql_query = $param->{'sql_query'};

    ## For CSV (Comma Separated Values) 
    my $f_dir = $param->{'f_dir'}; 

    my ($dbh, $sth);
    my $connect_string;

    if ($f_dir) {
	$connect_string = "DBI:CSV:f_dir=$f_dir";
    }elsif ($db_type eq 'Oracle') {
	$connect_string = "DBI:Oracle:";
	if ($host && $db_name) {
	    $connect_string .= "host=$host;sid=$db_name";
	}
    }elsif ($db_type eq 'Pg') {
	$connect_string = "DBI:Pg:dbname=$db_name;host=$host";
    }elsif ($db_type eq 'Sybase') {
	$connect_string = "DBI:Sybase:dbname=$db_name;server=$host";
    }else {
	$connect_string = "DBI:$db_type:$db_name:$host";
    }

    if ($param->{'connect_options'}) {
	$connect_string .= ';' . $param->{'connect_options'};
    }

    unless ($dbh = DBI->connect($connect_string, $user, $passwd)) {
	do_log ('notice','Can\'t connect to Database %s',$db_name);
	return undef;
    }
    do_log('debug','Connected to Database %s',$db_name);
    
    unless ($sth = $dbh->prepare($sql_query)) {
        do_log('debug','Unable to prepare SQL query : %s', $dbh->errstr);
        return undef;
    }
    unless ($sth->execute) {
        do_log('debug','Unable to perform SQL query %s : %s ',$sql_query, $dbh->errstr);
        return undef;
    }
    
    ## Counters.
    my $total = 0;
    
    ## Process the SQL results
    my $email;
    while (defined ($email = $sth->fetchrow)) {
	my %u = %{$default_user_options};

	## Empty value
	next if ($email =~ /^\s*$/);

	$u{'email'} = $email;

	$u{'date'} = time;
	$u{'update_date'} = time;
	unless ($users->{$email}) {
	    $total++;
	    $users->{$email} = join("\n", %u);
	}
    }
    $sth->finish ;
    $dbh->disconnect();

    do_log ('debug','%d included subscribers from SQL query', $total);
    return $total;
}

## Loads the list of subscribers from an external include source
sub _load_users_include {
    my $name = shift; 
    my $admin = shift ;
    my $db_file = shift;
    my $use_cache = shift;
    do_log('debug2', 'List::_load_users_include for list %s ; use_cache: %d',$name, $use_cache);

    my (%users, $depend_on, $ref);
    my $total = 0;

    ## Create in memory btree using DB_File.
    my $btree = new DB_File::BTREEINFO;
    return undef unless ($btree);
    $btree->{'compare'} = '_compare_addresses';

    if (!$use_cache && (-f $db_file)) {
        rename $db_file, $db_file.'old';
    }

    unless ($use_cache) {
	unless ($ref = tie %users, 'DB_File', $db_file, O_CREAT|O_RDWR, 0600, $btree) {
	    &do_log('err', 'Could not tie to DB_File');
	    return undef;
	}

	## Lock DB_File
	my $fd = $ref->fd;
	unless (open DB_FH, "+<&$fd") {
	    &do_log('err', 'Cannot open %s: %s', $db_file, $!);
	    return undef;
	}
	unless (flock (DB_FH, LOCK_EX | LOCK_NB)) {
	    &do_log('notice','Waiting for writing lock on %s', $db_file);
	    unless (flock (DB_FH, LOCK_EX)) {
		&do_log('err', 'Failed locking %s: %s', $db_file, $!);
		return undef;
	    }
	}
	&do_log('debug2', 'Got lock for writing on %s', $db_file);

	foreach my $type ('include_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query') {
	    last unless (defined $total);
	    
	    foreach my $incl (@{$admin->{$type}}) {
		my $included;
		
		## get the list of users
		if ($type eq 'include_sql_query') {
		    $included = _include_users_sql(\%users, $incl, $admin->{'default_user_options'});
		}elsif ($type eq 'include_ldap_query') {
		    $included = _include_users_ldap(\%users, $incl, $admin->{'default_user_options'});
		}elsif ($type eq 'include_ldap_2level_query') {
		    $included = _include_users_ldap_2level(\%users, $incl, $admin->{'default_user_options'});
		}elsif ($type eq 'include_list') {
		    $depend_on->{$name} = 1 ;
		    if (&_inclusion_loop ($name,$incl,$depend_on)) {
			do_log('notice','loop detection in list inclusion : could not include again %s in %s',$incl,$name);
		    }else{
			$depend_on->{$incl};
			$included = _include_users_list (\%users, $incl, $admin->{'default_user_options'});
		    }
		}elsif ($type eq 'include_file') {
		    $included = _include_users_file (\%users, $incl, $admin->{'default_user_options'});
		}
		unless (defined $included) {
		    &do_log('err', 'Inclusion %s failed in list %s', $type, $name);
		    $total = undef;
		    last;
		}
		
		$total += $included;
	    }
	}
  
	## Unlock
	flock(DB_FH,LOCK_UN);
	&do_log('debug2', 'Release lock on %s', $db_file);
	close DB_FH;
	
	untie %users;
    }

    unless ($ref = tie %users, 'DB_File', $db_file, O_CREAT|O_RDWR, 0600, $btree) {
	&do_log('err', 'Could not tie to DB_File');
	return undef;
    }

    ## Lock DB_File
    my $fd = $ref->fd;
    unless (open DB_FH, "+<&$fd") {
	&do_log('err', 'Cannot open %s: %s', $db_file, $!);
	return undef;
    }
    unless (flock (DB_FH, LOCK_SH | LOCK_NB)) {
	&do_log('notice','Waiting for reading lock on %s', $db_file);
	unless (flock (DB_FH, LOCK_SH)) {
	    &do_log('err', 'Failed locking %s: %s', $db_file, $!);
	    return undef;
	}
    }
    &do_log('debug2', 'Got lock for reading on %s', $db_file);

    ## Unlock DB_file
    flock(DB_FH,LOCK_UN);
    &do_log('debug2', 'Release lock on %s', $db_file);
    close DB_FH;
    
    ## Inclusion failed, clear cache
    unless (defined $total) {
	unlink $db_file;
	return undef;
    }

    my $l = {	 'ref'    => $ref,
		 'users'  => \%users
	     };
    $l->{'total'} = $total
	if $total;

    $l;
}

sub _inclusion_loop {

    my $name = shift;
    my $incl = shift;
    my $depend_on = shift;
    # do_log('debug', 'xxxxxxxxxxx _inclusion_loop(%s,%s)',$name,$incl);
    # do_log('debug', 'xxxxxxxxxxx DEPENDANCE :');
    # foreach my $dpe (keys  %{$depend_on}) {
    #   do_log('debug', "xxxxxxxxxxx ----$dpe----");
    # }

    return 1 if ($depend_on->{$incl}) ; 
    
    # do_log('notice', 'xxxxxxxx pas de PB pour inclure %s dans %s %s',$incl, $name);
    return undef;
}

sub _load_total_db {
    my $name = shift;
    do_log('debug2', 'List::_load_total_db(%s)', $name);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    my ($statement);

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    ## Query the Database
    $statement = sprintf "SELECT count(*) FROM subscriber_table WHERE list_subscriber = %s", $dbh->quote($name);
       
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $total = $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    return $total;
}

## Writes to disk the stats data for a list.
sub _save_stats_file {
    my $file = shift;
    my $stats = shift;
    my $total = shift;
    do_log('debug2', 'List::_save_stats_file(%s, %d)', $file, $total);
    
    open(L, "> $file") || return undef;
    printf L "%d %d %d %d %d\n", @{$stats}, $total;
    close(L);
}

## Writes the user list to disk
sub _save_users_file {
    my($self, $file) = @_;
    do_log('debug2', 'List::_save_users_file(%s)', $file);
    
    my($k, $s);
    
    do_log('debug','Saving user file %s', $file) if ($main::options{'debug'});
    
    rename("$file", "$file.old");
    open SUB, "> $file" or return undef;
    
    for ($s = $self->get_first_user(); $s; $s = $self->get_next_user()) {
	foreach $k ('date','update_date','email','gecos','reception','visibility') {
	    printf SUB "%s %s\n", $k, $s->{$k} unless ($s->{$k} eq '');
	    
	}
	print SUB "\n";
    }
    close SUB;
    return 1;
}

sub _compare_addresses {
   my ($a, $b) = @_;

   my ($ra, $rb);

   $a =~ tr/A-Z/a-z/;
   $b =~ tr/A-Z/a-z/;

   $ra = reverse $a;
   $rb = reverse $b;

   return ($ra cmp $rb);
}

sub _compare_addresses_old {
   my ($a, $b) = @_;
   my ($pa,$pb); 
   $a =~ tr/A-Z/a-z/;
   $b =~ tr/A-Z/a-z/;
   $a =~ /\.(\w*)$/;
   my $ra = $1;
   $b =~ /\.(\w*)$/;
   my $rb = $1;
   ($Conf{'poids'}{$ra} and $pa=$Conf{'poids'}{$ra}) or  $pa=$Conf{'poids'}{'*'};
   ($Conf{'poids'}{$rb} and $pb=$Conf{'poids'}{$rb}) or  $pb=$Conf{'poids'}{'*'};

   $pa != $pb and return ($pa cmp $pb);

   $ra = join('.', reverse(split(/[@\.]/, $a)));
   $rb = join('.', reverse(split(/[@\.]/, $b)));

   return ($ra cmp $rb);
}

## Does the real job : stores the message given as an argument into
## the digest of the list.
sub store_digest {
    my($self,$msg) = @_;
    do_log('debug2', 'List::store_digest');

    my($filename, $newfile);
    my $separator = $msg::separator;  

    unless ( -d "$Conf{'queuedigest'}") {
	return;
    }
    
    my @now  = localtime(time);
    $filename = "$Conf{'queuedigest'}/$self->{'name'}";
    $newfile = !(-e $filename);
    my $oldtime=(stat $filename)[9] unless($newfile);
  
    open(OUT, ">> $filename") || return;
    if ($newfile) {
	## create header
	printf OUT "\nThis digest for list has been created on %s\n\n",
      POSIX::strftime("%a %b %e %H:%M:%S %Y", @now);
	print OUT "------- THIS IS A RFC934 COMPLIANT DIGEST, YOU CAN BURST IT -------\n\n";
	print OUT "\n$separator\n\n";

       # send the date of the next digest to the users
    }
    #$msg->head->delete('Received') if ($msg->head->get('received'));
    $msg->print(\*OUT);
    print OUT "\n$separator\n\n";
    close(OUT);
    
    #replace the old time
    utime $oldtime,$oldtime,$filename   unless($newfile);
}

## List of lists hosted a robot
sub get_lists {
    my $robot_context = shift;

    my(@lists, $l,@robots);
    do_log('debug2', 'List::get_lists(%s)',$robot_context);

    if ($robot_context eq '*') {
	@robots = &get_robots ;
    }else{
	push @robots, $robot_context ;
    }

    
    foreach my $robot (@robots) {
    
	my $robot_dir =  $Conf{'home'}.'/'.$robot ;
	$robot_dir = $Conf{'home'}  unless ((-d $robot_dir) || ($robot ne $Conf{'host'}));
	
	unless (-d $robot_dir) {
	    do_log('err',"unknown robot $robot, Unable to open $robot_dir");
	    return undef ;
	}
	
	unless (opendir(DIR, $robot_dir)) {
	    do_log('err',"Unable to open $robot_dir");
	    return undef;
	}
	foreach $l (sort readdir(DIR)) {
	    next unless (($l !~ /^\./o) and (-d "$robot_dir/$l") and (-f "$robot_dir/$l/config"));
	    push @lists, $l;
	    
	}
    }
    return @lists;
}

## List of robots hosted by Sympa
sub get_robots {

    my(@robots, $r);
    do_log('debug2', 'List::get_robots()');

    unless (opendir(DIR, '--DIR--/etc')) {
	do_log('err',"Unable to open --DIR--/etc");
	return undef;
    }
    my $use_default_robot = 1 ;
    foreach $r (sort readdir(DIR)) {
	next unless (($r !~ /^\./o) && (-d "$Conf{'home'}/$r"));
	next unless (-r "--DIR--/etc/$r/robot.conf");
	push @robots, $r;
	undef $use_default_robot if ($r eq $Conf{'host'});
    }
    push @robots, $Conf{'host'} if ($use_default_robot);
    return @robots ;
}

# return true if the list is managed by the robot
sub list_by_robot {

    my($listname,$robot) = @_;

    my $list ;
    return undef unless ($list = new List ($listname));
    return 1 if ($list->{'domain'} eq $robot) ;
    # for compatibility with previous versions :
    # if 'domain' is undefined for this list but if the current robot is the default one
    return 1 if (($robot eq $Conf{'host'}) && (!$list->{'domain'}));
    return 1 if ($robot eq '*');
    return undef;
}

## List of lists in database mode which e-mail parameter is member of
sub get_which_db {
    my $email = shift;
    do_log('debug2', 'List::get_which_db(%s)', $email);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    my ($l, %which, $statement);

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    $statement = sprintf "SELECT list_subscriber FROM subscriber_table WHERE user_subscriber = %s",$dbh->quote($email);

    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }

    while ($l = $sth->fetchrow) {
	$l =~ s/\s*$//;  ## usefull for PostgreSQL
	$which{$l} = 1;
    }

    $sth->finish();

    $sth = pop @sth_stack;

    return \%which;
}

## List of lists where $1 (an email) is $3 (owner, editor or subscriber)
sub get_which {
    my $email = shift;
    my $robot =shift;
    my $function = shift;
    do_log('debug2', 'List::get_which(%s, %s)', $email, $function);

    my ($l, @which);

    ## WHICH in Database
    my $db_which = {};

    if (($function eq 'member') and (defined $Conf{'db_type'})) {
	if ($List::use_db) {
	    $db_which = &get_which_db($email);
	}
    }

    foreach $l (get_lists($robot)){
 
	my $list = new List ($l);
	next unless ($list);
	# next unless (($list->{'admin'}{'host'} eq $robot) || ($robot eq '*')) ;

        if ($function eq 'member') {
	    if ($list->{'admin'}{'user_data_source'} eq 'database') {
		if ($db_which->{$l}) {
		    push @which, $l ;
		}
	    }else {
		push @which, $list->{'name'} if ($list->is_user($email));
	    }
	}elsif ($function eq 'owner') {
	    push @which, $list->{'name'} if ($list->am_i('owner',$email));
	}elsif ($function eq 'editor') {
	    push @which, $list->{'name'} if ($list->am_i('editor',$email));
	}else {
	    do_log('debug',"Internal error, unknown or undefined parameter $function  in get_which");
            return undef ;
	}
    }
    
    return @which;
}


## send auth request to $request 
sub request_auth {
    do_log('debug2', 'List::request_auth(%s, %s, %s, %s)', @_);
    my $first_param = shift;
    my ($self, $email, $cmd, $robot, @param);

    if (ref($first_param) eq 'List') {
	$self = $first_param;
	$email= shift;
    }else {
	$email = $first_param;
    }
    $cmd = shift;
    $robot = shift;
    @param = @_;
    do_log('debug2', 'List::request_auth() List : %s,$email: %s cmd : %s',$self->{'name'},$email,$cmd);

    
    my $keyauth;
    my ($body, $command);
    my $robot_email = "$Conf{'email'}\@$robot";
    if (ref($self) eq 'List') {
	my $listname = $self->{'name'};

	if ($cmd =~ /signoff$/){
	    $keyauth = $self->compute_auth ($email, 'signoff');
	    $command = "auth $keyauth $cmd $listname $email";
	    my $url = "mailto:$robot_email?subject=$command";
	    $url =~ s/\s/%20/g;
	    $body = sprintf Msg(6, 261, $msg::signoff_need_auth ), $listname, $robot_email ,$command, $url;
	    
	}elsif ($cmd =~ /subscribe$/){
	    $keyauth = $self->compute_auth ($email, 'subscribe');
	    $command = "auth $keyauth $cmd $listname $param[0]";
	    my $url = "mailto:$robot_email?subject=$command";
	    $url =~ s/\s/%20/g;
	    $body = sprintf Msg(6, 260, $msg::subscription_need_auth)
		,$listname,  $robot_email, $command, $url ;
	}elsif ($cmd =~ /add$/){
	    $keyauth = $self->compute_auth ($param[0],'add');
	    $command = "auth $keyauth $cmd $listname $param[0] $param[1]";
	    $body = sprintf Msg(6, 39, $msg::adddel_need_auth),$listname
		, $robot_email, $command;
	}elsif ($cmd =~ /del$/){
	    my $keyauth = $self->compute_auth($param[0], 'del');
	    $command = "auth $keyauth $cmd $listname $param[0]";
	    $body = sprintf Msg(6, 39, $msg::adddel_need_auth),$listname
		, $robot_email, $command;
	}elsif ($cmd eq 'remind'){
	    my $keyauth = $self->compute_auth('','remind');
	    $command = "auth $keyauth $cmd $listname";
	    $body = sprintf Msg(6, 79, $msg::remind_need_auth),$listname
		, $robot_email, $command;
	}
    }else {
	if ($cmd eq 'remind'){
	    my $keyauth = &List::compute_auth('',$cmd);
	    $command = "auth $keyauth $cmd *";
	    $body = sprintf Msg(6, 79, $msg::remind_need_auth),'*'
		, $robot_email, $command;
	}
    }

    &mail::mailback (\$body, {'Subject' => $command}, 'sympa', $email, $robot, $email);

    return 1;
}

## genererate a md5 checksum using private cookie and parameters
sub compute_auth {
    do_log('debug2', 'List::compute_auth(%s, %s, %s)', @_);

    my $first_param = shift;
    my ($self, $email, $cmd);
    
    if (ref($first_param) eq 'List') {
	$self = $first_param;
	$email= shift;
    }else {
	$email = $email;
    }
    $cmd = shift;

    $email =~ y/[A-Z]/[a-z]/;
    $cmd =~ y/[A-Z]/[a-z]/;

    my ($cookie, $key, $listname) ;

    if ($self){
	$listname = $self->{'name'};
        $cookie = $self->get_cookie() || $Conf{'cookie'};
    }else {
	$cookie = $Conf{'cookie'};
    }
    
    $key = substr(Digest::MD5->md5_hex(join('/', $cookie, $listname, $email, $cmd)), -8) ;

    return $key;
}

## return total of messages awaiting moderation
sub get_mod_spool_size {
    my $self = shift;
    do_log('debug2', 'List::get_mod_spool_size()');    
    my @msg;
    
    unless (opendir SPOOL, $Conf{'queuemod'}) {
	&do_log('err', 'Unable to read spool %s', $Conf{'queuemod'});
	return undef;
    }

    @msg = sort grep(/^$self->{'name'}\_\w+$/, readdir SPOOL);

    return ($#msg + 1);
}

sub probe_db {
    do_log('debug2', 'List::probe_db()');    
    my (%checked, $table);

    ## Database structure
    my %db_struct = ('user_table' => 
		     {'email_user' => 'varchar(100)',
		      'gecos_user' => 'varchar(150)',
		      'password_user' => 'varchar(40)',
		      'cookie_delay_user' => 'int(11)',
		      'lang_user' => 'varchar(10)'},
		     'subscriber_table' => 
		     {'list_subscriber' => 'varchar(50)',
		      'user_subscriber' => 'varchar(100)',
		      'date_subscriber' => 'datetime',
		      'update_subscriber' => 'datetime',
		      'visibility_subscriber' => 'varchar(20)',
		      'reception_subscriber' => 'varchar(20)',
		      'bounce_subscriber' => 'varchar(30)',
		      'comment_subscriber' => 'varchar(150)'}
		     );

    ## Is the Database defined
    unless ($Conf{'db_name'}) {
	&do_log('info', 'No db_name defined in configuration file');
	return undef;
    }

    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }
	
    my (@tables, $fields, %real_struct);
    if ($Conf{'db_type'} eq 'mysql') {
	
	## Get tables
	unless (@tables = $dbh->func( '_ListTables' )) {
#	unless ($dbh->tables) {
	    &do_log('info', 'Can\'t load tables list from database %s : %s', $Conf{'db_name'}, $dbh->errstr);
	    return undef;
	}

	## Get fields
	foreach my $t (@tables) {

#	    unless ($sth = $dbh->table_info) {
#	    unless ($sth = $dbh->prepare("LISTFIELDS $t")) {
	    unless ($sth = $dbh->prepare("SHOW FIELDS FROM $t")) {
		do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
		return undef;
	    }

	    unless ($sth->execute) {
		do_log('err','Unable to execute SQL query : %s', $dbh->errstr);
		return undef;
	    }
	    
	    while (my $ref = $sth->fetchrow_hashref()) {
		$real_struct{$t}{$ref->{'Field'}} = $ref->{'Type'};
	    }
	}
	
    }elsif ($Conf{'db_type'} eq 'Pg') {
	
	unless (@tables = $dbh->tables) {
	    &do_log('info', 'Can\'t load tables list from database %s', $Conf{'db_name'});
	    return undef;
	}

    }elsif ($Conf{'db_type'} eq 'Oracle') {
 	
 	my $statement = "SELECT table_name FROM user_tables";	 

	push @sth_stack, $sth;

	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
	    return undef;
     	}

       	unless ($sth->execute) {
	    &do_log('err','Can\'t load tables list from database and Unable to perform SQL query %s : %s ',$statement, $dbh->errstr);
	    return undef;
     	}
 
	## Process the SQL results
     	while (my $table= $sth->fetchrow()) {
	    push @tables, lc ($table);   	
	}
	
     	$sth->finish();

	$sth = pop @sth_stack;

    }elsif ($Conf{'db_type'} eq 'Sybase') {
  
	my $statement = sprintf "SELECT name FROM %s..sysobjects WHERE type='U'",$Conf{'db_name'};
#	my $statement = "SELECT name FROM sympa..sysobjects WHERE type='U'";     
 
	push @sth_stack, $sth;
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
	    return undef;
	}
	unless ($sth->execute) {
	    &do_log('err','Can\'t load tables list from database and Unable to perform SQL query %s : %s ',$statement, $dbh->errstr);
	    return undef;
	}

	## Process the SQL results
	while (my $table= $sth->fetchrow()) {
	    push @tables, lc ($table);   
	}
	
	$sth->finish();
	$sth = pop @sth_stack;
    }
    
    foreach $table ( @tables ) {
	$checked{$table} = 1;
    }
    
    foreach $table('user_table', 'subscriber_table') {
	unless ($checked{$table}) {
	    &do_log('err', 'Table %s not found in database %s', $table, $Conf{'db_name'});
	    return undef;
	}
    }

    ## Check tables structure if we could get it
    if (%real_struct) {
	foreach my $t (keys %db_struct) {
	    unless ($real_struct{$t}) {
		&do_log('info', 'Table \'%s\' not found in database \'%s\' ; you should create it with create_db.%s script', $t, $Conf{'db_name'}, $Conf{'db_type'});
		return undef;
	    }
	    
	    foreach my $f (keys %{$db_struct{$t}}) {
		unless ($real_struct{$t}{$f}) {
		    &do_log('info', 'Field \'%s\' (table \'%s\' ; database \'%s\') was NOT found. Attempting to add it...', $f, $t, $Conf{'db_name'});
		    
		    unless ($dbh->do("ALTER TABLE $t ADD $f $db_struct{$t}{$f}")) {
			&do_log('err', 'Could not add field \'%s\' to table\'%s\'.', $f, $t);
			&do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			return undef;
		    }

		    &do_log('info', 'Database structure updated');
		    next;
		}
		
		unless ($real_struct{$t}{$f} eq $db_struct{$t}{$f}) {
		     &do_log('err', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s). Attempting to change it...', $f, $t, $Conf{'db_name'}, $db_struct{$t}{$f});

		     unless ($dbh->do("ALTER TABLE $t CHANGE $f $f $db_struct{$t}{$f}")) {
			 &do_log('err', 'Could not change field \'%s\' in table\'%s\'.', $f, $t);
			 &do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			 return undef;
		     }
		     
		     &do_log('info', 'Database structure updated');
		}
	    }
	}
    }
    
    return 1;
}

## Lowercase field from database
sub lowercase_field {
    my ($table, $field) = @_;

    my $total = 0;

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    unless ($sth = $dbh->prepare("SELECT $field from $table")) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement : %s', $dbh->errstr);
	return undef;
    }

    while (my $user = $sth->fetchrow_hashref) {
	my $lower_cased = lc($user->{$field});
	next if ($lower_cased eq $user->{$field});

	$total++;

	## Updating Db
	my $statement = sprintf "UPDATE $table SET $field=%s WHERE ($field=%s)", $dbh->quote($lower_cased), $dbh->quote($user->{$field});
	
	unless ($dbh->do($statement)) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
    }
    $sth->finish();

    return $total;
}

## Loads the list of topics if updated
sub load_topics {
    
    my $robot = shift ;
    do_log('debug2', 'List::load_topics(%s)',$robot);

    my $conf_file = &tools::get_filename('etc','topics.conf',$robot);

    my $topics = {};

    ## Load if not loaded or changed on disk
    if (! $list_of_topics{$robot} || ((stat($conf_file))[9] > $mtime{'topics'}{$robot})) {

	## delete previous list of topics
	%list_of_topics = undef;

	unless (-r $conf_file) {
	    &do_log('err',"Unable to read $conf_file");
	    return undef;
	}
	
	unless (open (FILE, $conf_file)) {
	    &do_log('err',"Unable to open config file $conf_file");
	    return undef;
	}
	
	## Raugh parsing
	my $index = 0;
	my (@raugh_data, $topic);
	while (<FILE>) {
	    if (/^([\w\/]+)\s*$/) {
		$index++;
		$topic = {'name' => $1,
			  'order' => $index
			  };
	    }elsif (/^([\w]+)\s+(.+)\s*$/) {
		next unless (defined $topic->{'name'});
		
		$topic->{$1} = $2;
	    }elsif (/^\s*$/) {
		if (defined $topic->{'name'}) {
		    push @raugh_data, $topic;
		    $topic = {};
		}
	    }	    
	}
	close FILE;

	## Last topic
	if (defined $topic->{'name'}) {
	    push @raugh_data, $topic;
	    $topic = {};
	}

	$mtime{'topics'}{$robot} = (stat($conf_file))[9];

	unless ($#raugh_data > -1) {
	    &do_log('notice', 'No topic defined in %s/topics.conf', $Conf{'etc'});
	    return undef;
	}

	## Analysis
	foreach my $topic (@raugh_data) {
	    my @tree = split '/', $topic->{'name'};
	    
	    if ($#tree == 0) {
		$list_of_topics{$robot}{$tree[0]}{'title'} = $topic->{'title'};
		$list_of_topics{$robot}{$tree[0]}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,$topic->{'visibility'}||'default');
		$list_of_topics{$robot}{$tree[0]}{'order'} = $topic->{'order'};
	    }else {
		my $subtopic = join ('/', @tree[1..$#tree]);
		$list_of_topics{$robot}{$tree[0]}{'sub'}{$subtopic} = &_add_topic($subtopic,$topic->{'title'},);
	    }
	}

	## Set undefined Topic (defined via subtopic)
	foreach my $t (keys %{$list_of_topics{$robot}}) {
	    unless (defined $list_of_topics{$robot}{$t}{'visibility'}) {
		$list_of_topics{$robot}{$t}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,'default');
	    }
	    
	    unless (defined $list_of_topics{$robot}{$t}{'title'}) {
		$list_of_topics{$robot}{$t}{'title'} = $t;
	    }	
	}
    }

    return %{$list_of_topics{$robot}};
}

## Inner sub used by load_topics()
sub _add_topic {
    my ($name, $title) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
	return {'title' => $title};
    }else {
	$topic->{'sub'}{$name} = &_add_topic(join ('/', @tree[1..$#tree]), $title);
	return $topic;
    }
}

############ THIS IS RELATED TO NEW LOAD_ADMIN_FILE #############

## Sort function for writing config files
sub by_order {
    ($::pinfo{$main::a}{'order'} <=> $::pinfo{$main::b}{'order'}) || ($main::a cmp $main::b);
}

## Apply defaults to parameters definition (%::pinfo)
sub _apply_defaults {
    do_log('debug2', 'List::_apply_defaults()');

    ## Parameter order
    foreach my $index (0..$#param_order) {
	if ($param_order[$index] eq '*') {
	    $default{'order'} = $index;
	}else {
	    $::pinfo{$param_order[$index]}{'order'} = $index;
	}
    }

    ## Parameters
    foreach my $p (keys %::pinfo) {

	## Apply defaults to %pinfo
	foreach my $d (keys %default) {
	    unless (defined $::pinfo{$p}{$d}) {
		$::pinfo{$p}{$d} = $default{$d};
	    }
	}

	## Scenario format
	if ($::pinfo{$p}{'scenario'}) {
	    $::pinfo{$p}{'format'} = $regexp{'scenario'};
	    $::pinfo{$p}{'default'} = 'default';
	}

	## Task format
	if ($::pinfo{$p}{'task'}) {
	    $::pinfo{$p}{'format'} = $regexp{'task'};
	}

	## Enumeration
	if (ref ($::pinfo{$p}{'format'}) eq 'ARRAY') {
	    $::pinfo{$p}{'file_format'} ||= join '|', @{$::pinfo{$p}{'format'}};
	}


	## Set 'format' as default for 'file_format'
	$::pinfo{$p}{'file_format'} ||= $::pinfo{$p}{'format'};
	
	if (($::pinfo{$p}{'occurrence'} =~ /n$/) 
	    && $::pinfo{$p}{'split_char'}) {
	    my $format = $::pinfo{$p}{'file_format'};
	    my $char = $::pinfo{$p}{'split_char'};
	    $::pinfo{$p}{'file_format'} = "($format)*(\\s*$char\\s*($format))*";
	}


	next unless ((ref $::pinfo{$p}{'format'} eq 'HASH')
		     && (ref $::pinfo{$p}{'file_format'} eq 'HASH'));
	
	## Parameter is a Paragraph)
	foreach my $k (keys %{$::pinfo{$p}{'format'}}) {
	    ## Defaults
	    foreach my $d (keys %default) {
		unless (defined $::pinfo{$p}{'format'}{$k}{$d}) {
		    $::pinfo{$p}{'format'}{$k}{$d} = $default{$d};
		}
	    }
	    
	    ## Scenario format
	    if (ref($::pinfo{$p}{'format'}{$k}) && $::pinfo{$p}{'format'}{$k}{'scenario'}) {
		$::pinfo{$p}{'format'}{$k}{'format'} = $regexp{'scenario'};
		$::pinfo{$p}{'format'}{$k}{'default'} = 'default' unless (($p eq 'web_archive') && ($k eq 'access'));
	    }

	    ## Task format
	    if (ref($::pinfo{$p}{'format'}{$k}) && $::pinfo{$p}{'format'}{$k}{'task'}) {
		$::pinfo{$p}{'format'}{$k}{'format'} = $regexp{'task'};
	    }

	    ## Enumeration
	    if (ref ($::pinfo{$p}{'format'}{$k}{'format'}) eq 'ARRAY') {
		$::pinfo{$p}{'file_format'}{$k}{'file_format'} ||= join '|', @{$::pinfo{$p}{'format'}{$k}{'format'}};
	    }

	    
	    if (($::pinfo{$p}{'file_format'}{$k}{'occurrence'} =~ /n$/) 
		&& $::pinfo{$p}{'file_format'}{$k}{'split_char'}) {
		my $format = $::pinfo{$p}{'file_format'}{$k}{'file_format'};
		my $char = $::pinfo{$p}{'file_format'}{$k}{'split_char'};
		$::pinfo{$p}{'file_format'}{$k}{'file_format'} = "($format)*(\\s*$char\\s*($format))*";
	    }

	}

	next unless (ref $::pinfo{$p}{'file_format'} eq 'HASH');

	foreach my $k (keys %{$::pinfo{$p}{'file_format'}}) {
	    ## Set 'format' as default for 'file_format'
	    $::pinfo{$p}{'file_format'}{$k}{'file_format'} ||= $::pinfo{$p}{'file_format'}{$k}{'format'};
	}
    }

    ## Default for user_data_source is 'file'
    ## if not using a RDBMS
    if ($List::use_db) {
	$::pinfo{'user_data_source'}{'default'} = 'database';
    }else {
	$::pinfo{'user_data_source'}{'default'} = 'file';
    }
    
    return \%::pinfo;
}

## Save a parameter
sub _save_list_param {
    my ($key, $p, $defaults, $fd) = @_;
    &do_log('debug2', '_save_list_param(%s)', $key);

#    my $old_fd = select;
#    select $fd; $| = 1;

    ## Ignore default value
    next if ($defaults == 1);

    next unless (defined ($p));

    if (defined ($::pinfo{$key}{'scenario'}) ||
        defined ($::pinfo{$key}{'task'})) {
	next if ($p->{'name'} eq 'default');

	printf $fd "%s %s\n", $key, $p->{'name'};
	print $fd "\n";

    }elsif (ref($::pinfo{$key}{'file_format'})) {
	printf $fd "%s\n", $key;
	foreach my $k (keys %{$p}) {

	    ## Multiple param in a single line
	    if (($::pinfo{$key}{'file_format'}{$k}{'occurrence'} =~ /n$/)
		&& $::pinfo{$key}{'file_format'}{$k}{'split_char'}) {
		$p->{$k} = join($::pinfo{$key}{'file_format'}{$k}{'split_char'}, @{$p->{$k}});
	    }

	    ## Ignore default value
#	    next if ($defaults->{$key}{$k} == 1);

	    if (defined ($::pinfo{$key}{'file_format'}{$k}{'scenario'})) {
		printf $fd "%s %s\n", $k, $p->{$k}{'name'};
	    }else {
		printf $fd "%s %s\n", $k, $p->{$k};
	    }
	}
	print $fd "\n";
    }else {
	printf $fd "%s %s\n", $key, $p;
	print $fd "\n";
    }
    
#    select $old_fd;

    return 1;
}

## Load a single line
sub _load_list_param {
    my ($robot,$key, $value, $p, $directory) = @_;
    # &do_log('debug2','_load_list_param(%s,\'%s\',\'%s\')', $robot,$key, $value);
    
    ## Empty value
    if ($value =~ /^\s*$/) {
	return undef;
    }

    ## Default
    if ($value eq 'default') {
	$value = $p->{'default'};
    }

    ## Search configuration file
    if (ref($value) && defined $value->{'conf'}) {
	$value = $Conf::Conf{$value->{'conf'}};
    }

    ## Synonyms
    if (defined $p->{'synonym'}{$value}) {
	$value = $p->{'synonym'}{$value};
    }
    
    ## Scenario
    if ($p->{'scenario'}) {
	$value =~ y/,/_/;
	$value = &List::_load_scenario_file ($p->{'scenario'},$robot, $value, $directory);
    }

    ## Do we need to split param
    if (($p->{'occurrence'} =~ /n$/)
	&& $p->{'split_char'}) {
	my @array = split /$p->{'split_char'}/, $value;
	foreach my $v (@array) {
	    $v =~ s/^\s*(.+)\s*$/$1/g;
	}
	
	return \@array;
    }else {
	return $value;
    }
}



## Load the certificat file
sub get_cert {

    my $self = shift;

    do_log('debug2', 'List::load_cert(%s)',$self->{'name'});


    my $certfile = "$self->{'name'}/cert.pem";
    do_log('info', 'List::load_cert certfile ');
    unless ( -r "$certfile") {
	do_log('info', 'List::load_cert(%s), unable to read %s',$self->{'name'},$certfile);
	return undef;
    }
    my $cert;
    open (CERT, $certfile) ;
    my @cert = <CERT>;
    close CERT ;
    return @cert;
}

## Load a config file
sub _load_admin_file {
    my ($directory,$robot, $file) = @_;
    do_log('debug2', 'List::_load_admin_file(%s, %s, %s)', $directory, $robot, $file);

    my $config_file = $directory.'/'.$file;

    my %admin;
    my (@paragraphs);

    ## Just in case...
    $/ = "\n";

    ## Set defaults to 1
    foreach my $pname (keys %::pinfo) {
	$admin{'defaults'}{$pname} = 1;
    }

    unless (open CONFIG, $config_file) {
	&do_log('info', 'Cannot open %s', $config_file);
    }

    ## Split in paragraphs
    my $i = 0;
    while (<CONFIG>) {
	if (/^\s*$/) {
	    $i++ if $paragraphs[$i];
	}else {
	    push @{$paragraphs[$i]}, $_;
	}
    }

    for my $index (0..$#paragraphs) {
	my @paragraph = @{$paragraphs[$index]};

	my $pname;

	## Clean paragraph, keep comments
	for my $i (0..$#paragraph) {
	    my $changed = undef;
	    for my $j (0..$#paragraph) {
		if ($paragraph[$j] =~ /^\s*\#/) {
		    chomp($paragraph[$j]);
		    push @{$admin{'comment'}}, $paragraph[$j];
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}elsif ($paragraph[$j] =~ /^\s*$/) {
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}

		last if $changed;
	    }

	    last unless $changed;
	}

	## Empty paragraph
	next unless ($#paragraph > -1);
	
	## Look for first valid line
	unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
	    &do_log('info', 'Bad paragraph "%s" in %s', @paragraph, $config_file);
	    next;
	}
	    
	$pname = $1;

	## Parameter aliases (compatibility concerns)
	if (defined $alias{$pname}) {
	    $paragraph[0] =~ s/^\s*$pname/$alias{$pname}/;
	    $pname = $alias{$pname};
	}
	
	unless (defined $::pinfo{$pname}) {
	    &do_log('info', 'Unknown parameter "%s" in %s', $pname, $config_file);
	    next;
	}

	## Uniqueness
	if (defined $admin{$pname}) {
	    unless (($::pinfo{$pname}{'occurrence'} eq '0-n') or
		    ($::pinfo{$pname}{'occurrence'} eq '1-n')) {
		&do_log('info', 'Multiple parameter "%s" in %s', $pname, $config_file);
	    }
	}
	
	## Line or Paragraph
	if (ref $::pinfo{$pname}{'file_format'} eq 'HASH') {
	    ## This should be a paragraph
	    unless ($#paragraph > 0) {
		&do_log('info', 'Expecting a paragraph for "%s" parameter in %s', $pname, $config_file);
	    }
	    
	    ## Skipping first line
	    shift @paragraph;

	    my %hash;
	    for my $i (0..$#paragraph) {	    
		next if ($paragraph[$i] =~ /^\s*\#/);
		
		unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
		    &do_log('info', 'Bad line "%s" in %s',$paragraph[$i], $config_file);
		}
		
		my $key = $1;
		
		unless (defined $::pinfo{$pname}{'file_format'}{$key}) {
		    &do_log('info', 'Unknown key "%s" in paragraph "%s" in %s', $key, $pname, $config_file);
		    next;
		}
		
		unless ($paragraph[$i] =~ /^\s*$key\s+($::pinfo{$pname}{'file_format'}{$key}{'file_format'})\s*$/i) {
		    &do_log('info', 'Bad value "%s" for parameter "%s" in paragraph "%s" in %s', $paragraph[$i], $key, $pname, $config_file);
		    next;
		}

		$hash{$key} = &_load_list_param($robot,$key, $1, $::pinfo{$pname}{'file_format'}{$key}, $directory);
	    }

	    ## Apply defaults & Check required keys
	    my $missing_required_field;
	    foreach my $k (keys %{$::pinfo{$pname}{'file_format'}}) {

		## Default value
		unless (defined $hash{$k}) {
		    if (defined $::pinfo{$pname}{'file_format'}{$k}{'default'}) {
			$hash{$k} = &_load_list_param($robot,$k, 'default', $::pinfo{$pname}{'file_format'}{$k}, $directory);
		    }
		}

		## Required fields
		if ($::pinfo{$pname}{'file_format'}{$k}{'occurrence'} eq '1') {
		    unless (defined $hash{$k}) {
			&do_log('info', 'Missing key "%s" in param "%s" in %s', $k, $pname, $config_file);
			$missing_required_field++;
		    }
		}
	    }

	    next if $missing_required_field;

	    delete $admin{'defaults'}{$pname};

	    ## Should we store it in an array
	    if (($::pinfo{$pname}{'occurrence'} =~ /n$/)) {
		push @{$admin{$pname}}, \%hash;
	    }else {
		$admin{$pname} = \%hash;
	    }
	}else {
	    ## This should be a single line
	    unless ($#paragraph == 0) {
		&do_log('info', 'Expecting a single line for "%s" parameter in %s', $pname, $config_file);
	    }

	    unless ($paragraph[0] =~ /^\s*$pname\s+($::pinfo{$pname}{'file_format'})\s*$/i) {
		&do_log('info', 'Bad value "%s" for parameter "%s" in %s', $paragraph[0], $pname, $config_file);
		next;
	    }

	    my $value = &_load_list_param($robot,$pname, $1, $::pinfo{$pname}, $directory);

	    delete $admin{'defaults'}{$pname};

	    if (($::pinfo{$pname}{'occurrence'} =~ /n$/)
		&& ! (ref ($value) =~ /^ARRAY/)) {
		push @{$admin{$pname}}, $value;
	    }else {
		$admin{$pname} = $value;
	    }
	}
    }
    
    close CONFIG;

    ## Apply defaults & check required parameters
    foreach my $p (keys %::pinfo) {

	## Defaults
	unless (defined $admin{$p}) {
	    if (defined $::pinfo{$p}{'default'}) {
		$admin{$p} = &_load_list_param($robot,$p, $::pinfo{$p}{'default'}, $::pinfo{$p}, $directory);

	    }elsif ((ref $::pinfo{$p}{'format'} eq 'HASH')
		    && ($::pinfo{$p}{'occurrence'} !~ /n$/)) {
		## If the paragraph is not defined, try to apply defaults
		my $hash = {};
		
		foreach my $key (keys %{$::pinfo{$p}{'format'}}) {

		    ## Only if all keys have defaults
		    unless (defined $::pinfo{$p}{'format'}{$key}{'default'}) {
			undef $hash;
			last;
		    }
		    
		    $hash->{$key} = &_load_list_param($robot,$key, $::pinfo{$p}{'format'}{$key}{'default'}, $::pinfo{$p}{'format'}{$key}, $directory);
		}

		$admin{$p} = $hash if (defined $hash);
	    }

#	    $admin{'defaults'}{$p} = 1;
	}
	
	## Required fields
	if ($::pinfo{$p}{'occurrence'} =~ /^1(-n)?$/ ) {
	    unless (defined $admin{$p}) {
		&do_log('info','Missing parameter "%s" in %s', $p, $config_file);
	    }
	}
    }

    ## "Original" parameters
    if (defined ($admin{'digest'})) {
	if ($admin{'digest'} =~ /^(.+)\s+(\d+):(\d+)$/) {
	    my $digest = {};
	    $digest->{'hour'} = $2;
	    $digest->{'minute'} = $3;
	    my $days = $1;
	    $days =~ s/\s//g;
	    @{$digest->{'days'}} = split /,/, $days;

	    $admin{'digest'} = $digest;
	}
    }
    # The 'host' parameter is ignored if the list is stored on a 
    #  virtual robot directory
   
    # $admin{'host'} = $self{'domain'} if ($self{'dir'} ne '.'); 

	
    if (defined ($admin{'custom_subject'})) {
	if ($admin{'custom_subject'} =~ /^\s*\[\s*(.+)\s*\]\s*$/) {
	    $admin{'custom_subject'} = $1;
	}
    }

    ## Format changed for reply_to parameter
    ## New reply_to_header parameter
    if (($admin{'forced_reply_to'} && ! $admin{'defaults'}{'forced_reply_to'}) ||
	($admin{'reply_to'} && ! $admin{'defaults'}{'reply_to'})) {
	my ($value, $apply, $other_email);
	$value = $admin{'forced_reply_to'} || $admin{'reply_to'};
	$apply = 'forced' if ($admin{'forced_reply_to'});
	if ($value =~ /\@/) {
	    $other_email = $value;
	    $value = 'other_email';
	}

	$admin{'reply_to_header'} = {'value' => $value,
				     'other_email' => $other_email,
				     'apply' => $apply};

	## delete old entries
	$admin{'reply_to'} = undef;
	$admin{'forced_reply_to'} = undef;
    }

    ############################################
    ## Bellow are constraints between parameters
    ############################################

    ## Subscription and unsubscribe add and del are closed 
    ## if subscribers are extracted via external include method
    ## (current version external method are SQL or LDAP query
    if ($admin{'user_data_source'} eq 'include') {
	foreach my $p ('subscribe','add','invite','unsubscribe','del') {
	    $admin{$p} = &_load_list_param($robot,$p, 'closed', $::pinfo{$p}, 'closed', $directory);
	}

    }

    ## Do we have a database config/access
    if ($admin{'user_data_source'} eq 'database') {
	unless ($List::use_db) {
	    &do_log('info', 'Sympa not setup to use DBI or no database access');
	    return undef;
	}
    }

    ## This default setting MUST BE THE LAST ONE PERFORMED
#    if ($admin{'status'} ne 'open') {
#	## requested and closed list are just list hidden using visibility parameter
#	## and with send parameter set to closed.
#	$admin{'send'} = &_load_list_param('.','send', 'closed', $::pinfo{'send'}, $directory);
#	$admin{'visibility'} = &_load_list_param('.','visibility', 'conceal', $::pinfo{'visibility'}, $directory);
#    }

    ## reception of default_user_options must be one of reception of
    ## available_user_options. If none, warning and put reception of
    ## default_user_options in reception of available_user_options
    if (! grep (/^$admin{'default_user_options'}{'reception'}$/,
		@{$admin{'available_user_options'}{'reception'}})) {
      push @{$admin{'available_user_options'}{'reception'}}, $admin{'default_user_options'}{'reception'};
      do_log('info','reception is not compatible between default_user_options and available_user_options in %s',$directory);
    }

    return \%admin;
}

## Save a config file
sub _save_admin_file {
    my ($config_file, $old_config_file, $admin) = @_;
    do_log('debug2', 'List::_save_admin_file(%s, %s, %s)', $config_file,$old_config_file, $admin);

    unless (rename $config_file, $old_config_file) {
	&do_log('notice', 'Cannot rename %s to %s', $config_file, $old_config_file);
	return undef;
    }

    unless (open CONFIG, ">$config_file") {
	&do_log('info', 'Cannot open %s', $config_file);
	return undef;
    }
    
    foreach my $c (@{$admin->{'comment'}}) {
	printf CONFIG "%s\n", $c;
    }
    print CONFIG "\n";

    foreach my $key (sort by_order keys %{$admin}) {

	next if ($key =~ /^comment|defaults$/);
	next unless (defined $admin->{$key});

	## Original parameters
	my @orig = ($admin->{'digest'}, $admin->{'topics'});

	## Multiple param in a single line
	if (($::pinfo{$key}{'occurrence'} =~ /n$/)
	    && $::pinfo{$key}{'split_char'}) {
	    $admin->{$key} = join($::pinfo{$key}{'split_char'}, @{$admin->{$key}});
	}

	if ($key eq 'digest') {
	    $admin->{'digest'} = sprintf '%s %d:%d', join(',', @{$admin->{'digest'}{'days'}})
		,$admin->{'digest'}{'hour'}, $admin->{'digest'}{'minute'};

#	}elsif ($key eq 'topics') {
#	    $admin->{'topics'} = sprintf '%s', join(',', @{$admin->{'topics'}});
	}elsif (($key eq 'user_data_source') && $admin->{'defaults'}{'user_data_source'}) {
	    $admin->{'user_data_source'} = 'database' if $List::use_db;
	}

	## Multiple parameter (owner, custom_header,...)
	if (ref ($admin->{$key}) eq 'ARRAY') {
	    foreach my $elt (@{$admin->{$key}}) {
		&_save_list_param($key, $elt, $admin->{'defaults'}{$key}, \*CONFIG);
	    }
	}else {
	    &_save_list_param($key, $admin->{$key}, $admin->{'defaults'}{$key}, \*CONFIG);
	}

	## Restore original parameters
	($admin->{'digest'}, $admin->{'topics'}) = @orig;

    }
    close CONFIG;

    return 1;
}

# Is a reception mode in the parameter reception of the available_user_options
# section ?
sub is_available_reception_mode {
  my ($self,$mode) = @_;
  $mode =~ y/[A-Z]/[a-z]/;
  
  return undef unless ($self && $mode);

  my @available_mode = @{$self->{'admin'}{'available_user_options'}{'reception'}};
  
  foreach my $m (@available_mode) {
    if ($m eq $mode) {
      return $mode;
    }
  }

  return undef;
}

# List the parameter reception of the available_user_options section 
sub available_reception_mode {
  my $self = shift;
  
  return join (' ',@{$self->{'admin'}{'available_user_options'}{'reception'}});
}

sub _urlize_part {
    my $message = shift;
    my $expl = shift;
    my $dir = shift;
    my $i = shift;
    my $mime_types = shift;
    my $list = shift;
      
    my $head = $message->head ;
    my $encoding = $head->mime_encoding ;

##  name of the linked file
    my $fileExt = $mime_types->{$head->mime_type};
    if ($fileExt) {
	$fileExt = '.'.$fileExt;
    }
    my $filename;

    if ($head->recommended_filename) {
	$filename = $head->recommended_filename;
    } else {
        $filename ="msg.$i".$fileExt;
    }
  
    ##create the linked file 	
    ## Store body in file 
    if (open OFILE, ">$expl/$dir/$filename") {
	my @ct = split(/;/,$head->get('Content-type'));
   	printf OFILE "Content-type: %s\n\n", $ct[0];
    } else {
	&do_log('notice', "Unable to open $expl/$dir/$filename") ;
	return undef ; 
    }
	    
    if ($encoding =~ /^binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64$/ ) {
	open TMP, ">$expl/$dir/$filename.$encoding";
	$message->print_body (\*TMP);
	close TMP;

	open BODY, "$expl/$dir/$filename.$encoding";
	my $decoder = new MIME::Decoder $encoding;
	$decoder->decode(\*BODY, \*OFILE);
	unlink "$expl/$dir/$filename.$encoding";
    }else {
	$message->print_body (\*OFILE) ;
    }
    close (OFILE);
    my $file = "$expl/$dir/$filename";
    my $size = (-s $file);
	    
    ## Delete files created twice or more (with Content-Type.name and Content-Disposition.filename)
    $message->purge ;	

    if ($i !=0) {
	## add the content type /external body
	## and the phantom body with content-type
	## and delete the 'old' body
	my $body = 'Content-type: '.$head->get('Content-type');
	$head->delete('Content-type');
	if ($head->get('Content-Transfer-Encoding')) {
	    $body .= 'Content-Transfer-Encoding: '.$head->get('Content-Transfer-Encoding');
	    $head->delete('Content-Transfer-Encoding');
	}
	$head->delete('Content-Disposition');
# it seems that the 'name=' option doesn't work if the file name has got an extension like '.xxx'-> '.' is replaced with '_'
	$filename =~ s/\./\_/g;
	$head->add('Content-type', "message/external-body; access-type=URL; URL=$Conf{'wwsympa_url'}/attach/$list$dir/$filename; name=\"$filename\"; size=\"$size\"");

	$message->parts([]);
	$message->bodyhandle (new MIME::Body::Scalar "$body" );

     }	
}

sub store_susbscription_request {
    my ($self, $email, $gecos) = @_;
    do_log('debug2', 'List::store_susbscription_request(%s, %s, %s)', $self->{'name'}, $email, $gecos);

    my $filename = $Conf{'queuesubscribe'}.'/'.$self->{'name'}.'.'.time.'.'.int(rand(1000));
    
    unless (open REQUEST, ">$filename") {
	do_log('notice', 'Could not open %s', $filename);
	return undef;
    }

    printf REQUEST "$email\t$gecos\n";
    close REQUEST;

    return 1;
} 

sub get_susbscription_requests {
    my ($self) = shift;
    do_log('debug2', 'List::get_susbscription_requests(%s)', $self->{'name'});

    my %subscriptions;

    unless (opendir SPOOL, $Conf{'queuesubscribe'}) {
	&do_log('info', 'Unable to read spool %s', $Conf{'queuemod'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}\.\d+\.\d+$/, readdir SPOOL)) {
	unless (open REQUEST, "$Conf{'queuesubscribe'}/$filename") {
	    do_log('notice', 'Could not open %s', $filename);
	    return undef;
	}
	my $line = <REQUEST>;
	$line =~ /^((\S+|\".*\")\@\S+)\s*(.*)$/;
	my $email = $1;
	$subscriptions{$email} = {'gecos' => $3};
	
	$filename =~ /^$self->{'name'}\.(\d+)\.\d+$/;
	$subscriptions{$email}{'date'} = $1;
	close REQUEST;
    }
    closedir SPOOL;

    return \%subscriptions;
} 

sub delete_susbscription_request {
    my ($self, $email) = @_;
    do_log('debug2', 'List::delete_susbscription_request(%s, %s)', $self->{'name'}, $email);

    unless (opendir SPOOL, $Conf{'queuesubscribe'}) {
	&do_log('info', 'Unable to read spool %s', $Conf{'queuemod'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}\.\d+\.\d+$/, readdir SPOOL)) {
	unless (open REQUEST, "$Conf{'queuesubscribe'}/$filename") {
	    do_log('notice', 'Could not open %s', $filename);
	    return undef;
	}
	my $line = <REQUEST>;
	close REQUEST;
	if ($line =~ /^$email\s/) {
	    unless (unlink "$Conf{'queuesubscribe'}/$filename") {
		do_log('notice', 'Could not delete file %s', $filename);
		next;
	    }
	}
    }
    closedir SPOOL;

    return 1;
} 

#################################################################

## Packages must return true.
1;



