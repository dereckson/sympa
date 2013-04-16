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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 NAME

Sympa::Log::Database - Database-oriented log functions

=head1 DESCRIPTION

This module provides database-oriented logging functions

=cut

package Sympa::Log::Database;

use strict;

use English qw(-no_match_vars);
use POSIX qw();

use Sympa::Datasource::SQL;
use Sympa::Log::Syslog;

my ($sth, @sth_stack, $rows_nb);

my %action_type = (
	message => [ qw/
		arc_delete	arc_download	d_remove_arc	distribute
		DoCommand	DoFile		DoForward	DoMessage
		reject		rebuildarc	record_email	remind
		remove		send_me		send_mail	SendDigest
		sendMessage
	/ ],
	authentication => [ qw/
		choosepasswd	login			logout
		loginrequest	remindpasswd		sendpasswd
		ssologin	ssologin_succeses
	/ ],
	subscription => [ qw/
		add		del	ignoresub	signoff
		subscribe	subindex
	/ ],
	list_management => [ qw/
		admin		blacklist		close_list
		copy_template	create_list		edit_list
		edit_template	install_pending_list	purge_list
		remove_template	rename_list
	/ ],
	bounced => [ qw/
		get_bounce	resetbounce
	/ ],
	preferences => [ qw/
		change_email	editsubscriber	pref
		set		setpasswd	setpref
	/ ],
	shared => [ qw/
		change_email	creation_shared_file	d_admin
		d_change_access	d_control		d_copy_file
		d_copy_rec_dir	d_create_dir		d_delete
		d_describe	d_editfile		d_install_shared
		d_overwrite	d_properties		d_reject_shared
		d_rename	d_savefile		d_set_owner
		d_upload	d_unzip			d_unzip_shared_file
		d_read		install_file_hierarchy	new_d_read
		set_lang
	/ ],
);

my %queries = (
	get_min_date => "SELECT min(date_logs) FROM logs_table",
	get_max_date => "SELECT max(date_logs) FROM logs_table",

	get_subscriber    =>
		'SELECT number_messages_subscriber ' .
		'FROM subscriber_table '             .
		'WHERE ('                            .
			'robot_subscriber = ? AND '  .
			'list_subscriber  = ? AND '  .
			'user_subscriber  = ?'       .
		')',
	update_subscriber =>
		'UPDATE subscriber_table '            .
		'SET number_messages_subscriber = ? ' .
		'WHERE ('                             .
			'robot_subscriber = ? AND '   .
			'list_subscriber  = ? AND '   .
			'user_subscriber  = ?'        .
		')',

	get_data =>
		'SELECT * '                                .
		'FROM stat_table '                         .
		'WHERE '                                   .
			'(date_stat BETWEEN ? AND ?) AND ' .
			'(read_stat = 0)',
	update_data =>
		'UPDATE stat_table '                     .
		'SET read_stat = 1 '                     .
		'WHERE (date_stat BETWEEN ? AND ?)',

	add_log_message =>
		'INSERT INTO logs_table ('                                  .
			'id_logs, date_logs, robot_logs, list_logs, '       .
			'action_logs, parameters_logs, target_email_logs, ' .
			'msg_id_logs, status_logs, error_type_logs, '       .
			'user_email_logs, client_logs, daemon_logs'         .
		') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
	delete_log_message =>
		'DELETE FROM logs_table '           .
		'WHERE (logs_table.date_logs <= ?)',

	add_stat_message =>
		'INSERT INTO stat_table ('                                   .
			'id_stat, date_stat, email_stat, operation_stat, '   .
			'list_stat, daemon_stat, user_ip_stat, robot_stat, ' .
			'parameter_stat, read_stat'                          .
		') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
	add_counter_message =>
		'INSERT INTO stat_counter_table ('                        .
			'id_counter, beginning_date_counter, '            .
			'end_date_counter, data_counter, robot_counter, ' .
			'list_counter, variation_counter, total_counter'  .
		') VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
);

my $source;

=head1 FUNCTIONS

=over

=cut

sub init {
	my (%params) = @_;

	$source = $params{source};
}

=item get_log_date()

Parameters:

None.

Return:

=cut

sub get_log_date {
	my @dates;

	my $min_handle = $source->get_query_handle($queries{get_min_date});
	my $min_result = $min_handle->execute();
	unless ($min_result) {
		Sympa::Log::Syslog::do_log('err','Unable to get minimal date from logs_table');
		return undef;
	}
	push @dates, ($min_handle->fetchrow_array)[0];

	my $max_handle = $source->get_query_handle($queries{get_max_date});
	my $max_result = $max_handle->execute();
	unless ($max_result) {
		Sympa::Log::Syslog::do_log('err','Unable to get maximal date from logs_table');
		return undef;
	}
	push @dates, ($max_handle->fetchrow_array)[0];

	return @dates;
}

=item do_log(%parameters)

Add log in RDBMS.

Parameters:

=over

=item C<list> => FIXME

=item C<robot> => FIXEM

=item C<action> => FIXME

=item C<parameter> => FIXME

=item C<target_email> => FIXME

=item C<user_email> => FIXME

=item C<msg_id> => FIXME

=item C<status> => FIXME

=item C<error_type> => FIXME

=item C<client> => FIXME

=item C<daemon> => FIXME

=back

Return:

=cut

sub do_log {
	my (%params) = @_;

	unless ($params{daemon} =~ /^(task|archived|sympa|wwsympa|bounced|sympa_soap)$/) {
		Sympa::Log::Syslog::do_log ('err',"Internal_error : incorrect process value $params{daemon}");
		return undef;
	}

	$params{parameters} = Sympa::Tools::clean_msg_id($params{parameters});
	$params{msg_id}     = Sympa::Tools::clean_msg_id($params{msg_id});
	$params{user_email} = Sympa::Tools::clean_msg_id($params{user_email});

	my $date   = time;
	my $random = int(rand(1000000));
	my $id     = $date.$random;

	unless($params{user_email}) {
		$params{user_email} = 'anonymous';
	}
	unless($params{list}) {
		$params{list} = '';
	}
	#remove the robot name of the list name
	if($params{list} =~ /(.+)\@(.+)/) {
		$params{list} = $1;
		unless($params{robot}) {
			$params{robot} = $2;
		}
	}

	## Insert in log_table

	my $handle = $source->get_query_handle(
		$queries{add_log_message},
	);
	my $result = $handle->execute(
		$id,
		$date,
		$params{robot},
		$params{list},
		$params{action},
		substr($params{parameters},0,100),
		$params{target_email},
		$params{msg_id},
		$params{status},
		$params{error_type},
		$params{user_email},
		$params{client},
		$params{daemon}
	);
	unless($result) {
		Sympa::Log::Syslog::do_log('err','Unable to insert new db_log entry in the database');
		return undef;
	}

	return 1;
}

=item do_stat_log($parameters)

Insert data in stats table.

Parameters:

=over

=item C<list> => FIXME

=item C<robot> => FIXEM

=item C<mail> => FIXME

=item C<operation> => FIXME

=item C<daemon> => FIXME

=item C<ip> => FIXME

=item C<parameter> => FIXME

=back

Return:

=cut

sub do_stat_log {
	my (%params) = @_;

	my $date   = time;
	my $random = int(rand(1000000));
	my $id     = $date.$random;

	if (ref($params{list}) && $params{list}->isa('Sympa::List')) {
		$params{list} = $params{list}->{'name'};
	}
	if($params{list} =~ /(.+)\@(.+)/) {#remove the robot name of the list name
		$params{list} = $1;
		unless($params{robot}) {
			$params{robot} = $2;
		}
	}

	my $handle = $source->get_query_handle(
		$queries{add_stat_message},
	);
	my $result = $handle->execute(
		$id,
		$date,
		$params{mail},
		$params{operation},
		$params{list},
		$params{daemon},
		$params{ip},
		$params{robot},
		$params{parameter},
		0
	);
	unless($result) {
		Sympa::Log::Syslog::do_log('err','Unable to insert new stat entry in the database');
		return undef;
	}
	return 1;
}

sub _db_stat_counter_log {
	my (%params) = @_;

	my $random = int(rand(1000000));
	my $id = $params{begin_date}.$random;

	if($params{list} =~ /(.+)\@(.+)/) {#remove the robot name of the list name
		$params{list} = $1;
		unless($params{robot}) {
			$params{robot} = $2;
		}
	}

	my $handle = $source->get_query_handle(
		$queries{add_counter_message},
	);
	my $result = $handle->execute(
		$id,
		$params{begin_date},
		$params{end_date},
		$params{data},
		$params{robot},
		$params{list},
		$params{variation},
		$params{total}
	);
	unless($result) {
		Sympa::Log::Syslog::do_log('err','Unable to insert new stat counter entry in the database');
		return undef;
	}
	return 1;

}

=item delete_messages($parameters)

Delete logs in RDBMS.

Parameters:

Return:

=cut

sub delete_messages {
	my ($exp) = @_;
	my $date = time - ($exp * 30 * 24 * 60 * 60);

	my $handle = $source->get_query_handle(
		$queries{delete_log_message},
	);
	my $result = $handle->execute(
		$date
	);
	unless ($result) {
		Sympa::Log::Syslog::do_log('err','Unable to delete db_log entry from the database');
		return undef;
	}
	return 1;

}

=item get_first_db_log($parameters)

Scan log_table with appropriate select.

Parameters:

Return:

=cut

sub get_first_db_log {
	my ($select) = @_;


	my $statement = sprintf "SELECT date_logs, robot_logs AS robot, list_logs AS list, action_logs AS action, parameters_logs AS parameters, target_email_logs AS target_email,msg_id_logs AS msg_id, status_logs AS status, error_type_logs AS error_type, user_email_logs AS user_email, client_logs AS client, daemon_logs AS daemon FROM logs_table WHERE robot_logs=%s ", $source->quote($select->{'robot'});

	#if a type of target and a target are specified
	if (($select->{'target_type'}) && ($select->{'target_type'} ne 'none')) {
		if($select->{'target'}) {
			$select->{'target_type'} = lc ($select->{'target_type'});
			$select->{'target'} = lc ($select->{'target'});
			$statement .= 'AND ' . $select->{'target_type'} . '_logs = ' . $source->quote($select->{'target'}).' ';
		}
	}

	#if the search is between two date
	if ($select->{'date_from'}) {
		my @tab_date_from = split(/\//,$select->{'date_from'});
		my $date_from = POSIX::mktime(0,0,-1,$tab_date_from[0],$tab_date_from[1]-1,$tab_date_from[2]-1900);
		unless($select->{'date_to'}) {
			my $date_from2 = POSIX::mktime(0,0,25,$tab_date_from[0],$tab_date_from[1]-1,$tab_date_from[2]-1900);
			$statement .= sprintf "AND date_logs BETWEEN '%s' AND '%s' ",$date_from, $date_from2;
		}
		if($select->{'date_to'}) {
			my @tab_date_to = split(/\//,$select->{'date_to'});
			my $date_to = POSIX::mktime(0,0,25,$tab_date_to[0],$tab_date_to[1]-1,$tab_date_to[2]-1900);

			$statement .= sprintf "AND date_logs BETWEEN '%s' AND '%s' ",$date_from, $date_to;
		}
	}

	#if the search is on a precise type
	if ($select->{'type'}) {
		if(($select->{'type'} ne 'none') && ($select->{'type'} ne 'all_actions')) {
			my $first = 'false';
			foreach my $type(@{$action_type{$select->{'type'}}}) {
				if($first eq 'false') {
					#if it is the first action, put AND on the statement
					$statement .= sprintf "AND (logs_table.action_logs = '%s' ",$type;
					$first = 'true';
				}
				#else, put OR
				else {
					$statement .= sprintf "OR logs_table.action_logs = '%s' ",$type;
				}
			}
			$statement .= ')';
		}

	}

	#if the listmaster want to make a search by an IP adress.    if($select->{'ip'}) {
	$statement .= sprintf "AND client_logs = '%s'",$select->{'ip'};


	## Currently not used
	#if the search is on the actor of the action
	if ($select->{'user_email'}) {
		$select->{'user_email'} = lc ($select->{'user_email'});
		$statement .= sprintf "AND user_email_logs = '%s' ",$select->{'user_email'};
	}

	#if a list is specified -just for owner or above-
	if($select->{'list'}) {
		$select->{'list'} = lc ($select->{'list'});
		$statement .= sprintf "AND list_logs = '%s' ",$select->{'list'};
	}

	$statement .= sprintf "ORDER BY date_logs ";

	push @sth_stack, $sth;
	$sth = $source->do_query($statement);
	unless($sth) {
		Sympa::Log::Syslog::do_log('err','Unable to retrieve logs entry from the database');
		return undef;
	}

	my $log = $sth->fetchrow_hashref('NAME_lc');
	$rows_nb = $sth->rows;

	## If no rows returned, return an empty hash
	## Required to differenciate errors and empty results
	if ($rows_nb == 0) {
		return {};
	}

	## We can't use the "AS date" directive in the SELECT statement because "date" is a reserved keywork with Oracle
	$log->{date} = $log->{date_logs} if defined($log->{date_logs});
	return $log;


}

=item return_rows_nb()

Parameters:

None.

Return:

=cut

sub return_rows_nb {
	return $rows_nb;
}

=item get_next_db_log()

Parameters:

None.

Return:

=cut

sub get_next_db_log {

	my $log = $sth->fetchrow_hashref('NAME_lc');

	unless (defined $log) {
		$sth->finish;
		$sth = pop @sth_stack;
	}

	## We can't use the "AS date" directive in the SELECT statement because "date" is a reserved keywork with Oracle
	$log->{date} = $log->{date_logs} if defined($log->{date_logs});

	return $log;
}

=item aggregate_data($begin_date, $end_date)

Aggregate date from stat_table to stat_counter_table.

Dates must be in epoch format.

Parameters:

Return:

=cut

sub aggregate_data {
	my ($begin_date, $end_date) = @_;

	# retrieve new stats (read_stat value is 0)
	my $get_handle = $source->get_query_handle(
		$queries{get_data},
	);
	my $get_result = $get_handle->execute(
		$begin_date,
		$end_date
	);
	unless ($get_result) {
		Sympa::log::Syslog::do_log('err','Unable to retrieve stat entries between date % and date %s', $begin_date, $end_date);
		return undef;
	}

	my $raw_stats = $get_handle->fetchall_hashref('id_stat');

	# mark stats as read (flip read_stat value to 1)
	my $update_handle = $source->get_query_handle(
		$queries{update_data},
	);
	my $update_result = $update_handle->execute(
		$begin_date,
		$end_date
	);
	unless ($update_result) {
		Sympa::Log::Syslog::do_log('err','Unable to set stat entries between date % and date %s as read', $begin_date, $end_date);
		return undef;
	}

	my $aggregated_stats = _get_aggregated_stats($raw_stats);
	_store_aggregated_stats($aggregated_stats, $begin_date, $end_date);

	my $local_begin_date = localtime($begin_date);
	my $local_end_date   = localtime($end_date);
	Sympa::Log::Syslog::do_log('debug2', 'data aggregated from %s to %s', $local_begin_date, $local_end_date);

	return 1;
}

sub _store_aggregated_stats {
	my ($stats, $begin_date, $end_date) = @_;

	foreach my $operation (keys %{$stats}) {
		my $stat = $stats->{$operation};

		if ($operation eq 'send_mail') {
			foreach my $robot (keys %{$stat}) {
				foreach my $list (keys %{$stat->{$robot}}) {
					_db_stat_counter_log(
						begin_date => $begin_date,
						end_date   => $end_date,
						data       => $operation,
						list       => $list,
						variation  => $stat->{$robot}->{$list}->{'count'},
						total      => '',
						robot      => $robot
					);

					foreach my $mail (keys %{$stat->{$robot}->{$list}}) {
						next if $mail eq 'count';
						next if $mail eq 'size';

						_update_subscriber_msg_send(
							mail    => $mail,
							list    => $list,
							robot   => $robot,
							counter => $stat->{$robot}->{$list}->{$mail}
						);
					}
				}
			}
		}

		if ($operation eq 'add_subscriber') {
			foreach my $robot (keys %{$stat}) {
				foreach my $list (keys %{$stat->{$robot}}) {
					_db_stat_counter_log(
						begin_date => $begin_date,
						end_date   => $end_date,
						data       => $operation,
						list       => $list,
						variation  => $stat->{$robot}->{$list}->{count},
						total      =>   '',
						robot      => $robot
					);
				}
			}
		}

		if ($operation eq 'del_subscriber') {
			foreach my $robot (keys %{$stat}) {
				foreach my $list (keys %{$stat->{$robot}}) {
					foreach my $param (keys %{$stat->{$robot}->{$list}}) {
						_db_stat_counter_log(
							begin_date => $begin_date,
							end_date   => $end_date,
							data       => $param,
							list       => $list,
							variation  => $stat->{$robot}->{$list}->{$param},
							total      => '',
							robot      => $robot
						);
					}
				}
			}
		}

		if ($operation eq 'create_list') {
			foreach my $robot (keys %{$stat}) {
				_db_stat_counter_log(
					begin_date => $begin_date,
					end_date   => $end_date,
					data       => $operation,
					list       => '',
					variation  => $stat->{$robot},
					total      => '',
					robot      => $robot
				);
			}
		}

		if ($operation eq 'copy_list') {
			foreach my $robot (keys %{$stat}) {
				_db_stat_counter_log(
					begin_date => $begin_date,
					end_date   => $end_date,
					data       => $operation,
					list       => '',
					variation  => $stat->{$robot},
					total      => '',
					robot      => $robot
				);
			}
		}

		if ($operation eq 'close_list') {
			foreach my $robot (keys %{$stat}) {
				_db_stat_counter_log(
					begin_date => $begin_date,
					end_date   => $end_date,
					data       => $operation,
					list       => '',
					variation  => $stat->{$robot},
					total      => '',
					robot      => $robot
				);
			}
		}

		if ($operation eq 'purge_list') {
			foreach my $robot (keys %{$stat}) {
				_db_stat_counter_log(
					begin_date => $begin_date,
					end_date   => $end_date,
					data       => $operation,
					list       => '',
					variation  => $stat->{$robot},
					total      => '',
					robot      => $robot
				);
			}
		}

		if ($operation eq 'reject') {
			foreach my $robot (keys %{$stat}) {
				foreach my $list (keys %{$stat->{$robot}}) {
					_db_stat_counter_log(
						begin_date => $begin_date,
						end_date   => $end_date,
						data       => $operation,
						list       => $list,
						variation  => $stat->{$robot}->{$list},
						total      => '',
						robot      => $robot
					);
				}
			}
		}

		if ($operation eq 'list_rejected') {
			foreach my $robot (keys %$stat) {
				_db_stat_counter_log(
					begin_date => $begin_date,
					end_date   => $end_date,
					data       => $operation,
					list       => '',
					variation  => $stat->{$robot},
					total      => '',
					robot      => $robot
				);
			}
		}

		if ($operation eq 'd_upload') {
			foreach my $robot (keys %{$stat}) {
				foreach my $list (keys %{$stat->{$robot}}) {
					_db_stat_counter_log(
						begin_date => $begin_date,
						end_date   => $end_date,
						data       => $operation,
						list       => $list,
						variation  => $stat->{$robot}->{$list},
						total      => '',
						robot      => $robot
					);
				}
			}
		}

		if ($operation eq 'd_create_directory') {
			foreach my $robot (keys %{$stat}) {
				foreach my $list (keys %{$stat->{$robot}}) {
					_db_stat_counter_log(
						begin_date => $begin_date,
						end_date   => $end_date,
						data       => $operation,
						list       => $list,
						variation  => $stat->{$robot}->{$list},
						total      => '',
						robot      => $robot
					);
				}
			}
		}

		if ($operation eq 'd_create_file') {
			foreach my $robot (keys %{$stat}) {
				foreach my $list (keys %{$stat->{$robot}}) {
					_db_stat_counter_log(
						begin_date => $begin_date,
						end_date   => $end_date,
						data       => $operation,
						list       => $list,
						variation  => $stat->{$robot}->{$list},
						total      => '',
						robot      => $robot
					);
				}
			}
		}
	}
}

sub _get_aggregated_stats {
	my ($input_stats) = @_;

	my $output_stats;

	foreach my $input_stat (values %{$input_stats}) {
		my $operation = $input_stat->{operation_stat};

		if ($operation eq 'send_mail') {
			my $robot = $input_stat->{robot_stat};
			my $list  = $input_stat->{list_stat};
			my $email = $input_stat->{email_stat};

			if (!$output_stats->{send_mail}{$robot}{$list}) {
				$output_stats->{send_mail}{$robot}{$list} = {
					size  => 0,
					count => 0,
				};
			}
			my $output_stat = $output_stats->{send_mail}{$robot}{$list};
			$output_stat->{size} += $input_stat->{parameter_stat};
			$output_stat->{count}++;
			$output_stat->{$email} = $output_stat->{$email} ?
				$output_stat->{$email} + 1 : 1;
			next;
		}

		if ($operation eq 'add_subscriber') {
			my $robot = $input_stat->{robot_stat};
			my $list  = $input_stat->{list_stat};
			my $count =
				$output_stats->{add_subscriber}{$robot}{$list}{count};
			$output_stats->{add_subscriber}{$robot}{$list}{count} =
				$count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'del subscriber') {
			my $robot = $input_stat->{robot_stat};
			my $list  = $input_stat->{list_stat};
			my $param = $input_stat->{parameter_stat};
			my $count =
				$output_stats->{del_subscriber}{$robot}{$list}{$param};
			$output_stats->{del_subscriber}{$robot}{$list}{$param} =
				$count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'create_list') {
			my $robot = $input_stat->{robot_stat};
			my $count = $output_stats->{create_list}{$robot};
			$output_stats->{create_list}{$robot} = $count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'copy_list') {
			my $robot = $input_stat->{robot_stat};
			my $count = $output_stats->{copy_list}{$robot};
			$output_stats->{copy_list}{$robot} = $count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'close_list') {
			my $robot = $input_stat->{robot_stat};
			my $count = $output_stats->{close_list}{$robot};
			$output_stats->{close_list}{$robot} = $count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'purge list') {
			my $robot = $input_stat->{robot_stat};
			my $count = $output_stats->{purge_list}{$robot};
			$output_stats->{purge_list}{$robot} = $count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'reject') {
			my $robot = $input_stat->{'robot_stat'};
			my $list  = $input_stat->{'list_stat'};
			my $count = $output_stats->{reject}{$robot}{$list};
			$output_stats->{reject}{$robot}{$list} = $count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'list_rejected') {
			my $robot = $input_stat->{robot_stat};
			my $count = $output_stats->{liste_rejected}{$robot};
			$output_stats->{list_rejected}{$robot} = $count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'd_upload') {
			my $robot = $input_stat->{robot_stat};
			my $list  = $input_stat->{list_stat};
			my $count = $output_stats->{d_upload}{$robot}{$list};
			$output_stats->{d_upload}{$robot}{$list} =
				$count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'd_create_dir(directory)') {
			my $robot = $input_stat->{robot_stat};
			my $list  = $input_stat->{list_stat};
			my $count = $output_stats->{d_create_directory}{$robot}{$list};
			$output_stats->{d_create_directory}{$robot}{$list} =
				$count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'd_create_dir(file)') {
			my $robot = $input_stat->{robot_stat};
			my $list  = $input_stat->{list_stat};
			my $count = $output_stats->{d_create_file}{$robot}{$list};
			$output_stats->{d_create_file}{$robot}{$list} =
				$count ? $count + 1 : 1;
			next;
		}

		if ($operation eq 'arc') {
			my $robot = $input_stat->{robot_stat};
			my $list  = $input_stat->{list_stat};
			my $count = $output_stats->{archive_visited}{$robot}{$list};
			$output_stats->{archive_visited}{$robot}{$list} =
				$count ? $count + 1 : 1;
			next;
		}
	}

	return $output_stats;
}

# subroutine to Update subscriber_table about message send,
# upgrade field number_messages_subscriber
sub _update_subscriber_msg_send {
	my (%params) = @_;
	Sympa::Log::Syslog::do_log('debug2','%s,%s,%s,%s',$params{mail}, $params{list}, $params{robot}, $params{counter});

	my $get_handle = $source->get_query_handle(
		$queries{get_subscribers},
	);
	my $get_result = $get_handle->execute(
		$params{robot},
		$params{list},
		$params{mail}
	);
	unless ($get_result) {
		Sympa::Log::Syslog::do_log('err','Unable to retrieve message count for user %s, list %s@%s',$params{mail}, $params{list}, $params{robot});
		return undef;
	}

	my $nb_msg =
		$get_handle->fetchrow_hashref('number_messages_subscriber') +
		$params{counter};

	my $update_handle = $source->get_query_handle(
		$queries{update_subscribers},
	);
	my $update_result = $update_handle->execute(
		$nb_msg,
		$params{robot},
		$params{list},
		$params{mail}
	);
	unless ($update_result) {
		Sympa::Log::Syslog::do_log('err','Unable to update message count for user %s, list %s@%s',$params{mail}, $params{list}, $params{robot});
		return undef;
	}
	return 1;

}

=back

=cut

1;
