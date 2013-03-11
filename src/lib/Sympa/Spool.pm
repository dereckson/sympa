# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
# Copyrigh (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
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

Sympa::Spool - Mail spool object

=head1 DESCRIPTION

This class implements a mail spool.

=cut

package Sympa::Spool;

use strict;

require Encode;
use English qw(-no_match_vars);
use IO::Scalar;
use Fcntl qw(LOCK_SH LOCK_EX LOCK_NB LOCK_UN);
use Mail::Header;
use MIME::Entity;
use MIME::EncWords;
use MIME::Parser;
use Storable;
use Sys::Hostname;
use Time::Local;

use Sympa::Constants;
use Sympa::DatabaseDescription;
use Sympa::Log;
use Sympa::Message;
use Sympa::SDM;
use Sympa::Tools::Time;

## Database and SQL statement handlers
my ($dbh, $sth, $db_connected, @sth_stack, $use_db);

=head1 CLASS METHODS

=head2 Sympa::Spool->new($name, $selectionstatus)

Creates a new L<Sympa::Spool> object.

=head3 Parameters

=over

=item * I<$name>

=item * I<$selection_status>

=back

=head3 Return

A new L<Sympa::Spool> object, or I<undef>, if something went wrong.

=cut

sub new {
    my ($class, $spoolname, $selection_status) = @_;
   Sympa::Log::do_log('debug2', '(%s)', $spoolname);

    my $self={};
    unless ($spoolname =~ /^(auth)|(bounce)|(digest)|(bulk)|(expire)|(mod)|(msg)|(archive)|(automatic)|(subscribe)|(topic)|(validated)|(task)$/){
Sympa::Log::do_log('err','internal error unknown spool %s',$spoolname);
	return undef;
    }
    $self->{'spoolname'} = $spoolname;
    if (($selection_status eq 'bad')||($selection_status eq 'ok')) {
	$self->{'selection_status'} = $selection_status;
    }else{
	$self->{'selection_status'} =  'ok';
    }

    bless $self, $class;

    return $self;
}

# total spool_table count : not object oriented, just a subroutine
sub global_count {
    my ($message_status) = @_;

    push @sth_stack, $sth;
    $sth = Sympa::SDM::do_query ("SELECT COUNT(*) FROM spool_table where message_status_spool = '".$message_status."'");

    my @result = $sth->fetchrow_array();
    $sth->finish();
    $sth = pop @sth_stack;

    return $result[0];
}

sub count {
    my ($self) = @_;

    return ($self->get_content({'selection'=>'count'}));
}

#######################
#
#  get_content return the content an array of hash describing the spool content
#
sub get_content {
    my ($self, $data) = @_;

    my $selector=$data->{'selector'};     # hash field->value used as filter  WHERE sql query
    my $selection=$data->{'selection'};   # the list of field to select. possible values are :
                                          #    -  a comma separated list of field to select.
                                          #    -  '*'  is the default .
                                          #    -  '*_but_message' mean any field except message which may be hugue and unusefull while listing spools
                                          #    - 'count' mean the selection is just a count.
                                          # should be used mainly to select all but 'message' that may be huge and may be unusefull
    my $ofset = $data->{'ofset'};         # for pagination, start fetch at element number = $ofset;
    my $page_size = $data->{'page_size'}; # for pagination, limit answers to $page_size
    my $orderby = $data->{'sortby'};      # sort
    my $way = $data->{'way'};             # asc or desc


    my $sql_where = _sqlselector($selector);
    if ($self->{'selection_status'} eq 'bad') {
	$sql_where = $sql_where."AND message_status_spool = 'bad' " ;
    }else{
	$sql_where = $sql_where."AND message_status_spool != 'bad' " ;
    }
    $sql_where =~s/^AND//;

    my $statement ;
    if ($selection eq 'count'){
	# just return the selected count, not all the values
	$statement = 'SELECT COUNT(*) ';
    }else{
	$statement = 'SELECT '._selectfields($selection);
    }

    $statement = $statement . sprintf " FROM spool_table WHERE %s AND spoolname_spool = %s ",$sql_where,Sympa::SDM::quote($self->{'spoolname'});

    if ($orderby) {
	$statement = $statement. ' ORDER BY '.$orderby.'_spool ';
	$statement = $statement. ' DESC' if ($way eq 'desc') ;
    }
    if ($page_size) {
	$statement = $statement . ' LIMIT '.$ofset.' , '.$page_size;
    }

    push @sth_stack, $sth;
    $sth = Sympa::SDM::do_query($statement);
    if($selection eq 'count') {
	my @result = $sth->fetchrow_array();
	return $result[0];
    }else{
	my @messages;
	while (my $message = $sth->fetchrow_hashref('NAME_lc')) {
	    $message->{'date_asstring'} = Sympa::Tools::Time::epoch2yyyymmjj_hhmmss($message->{'date'});
	    $message->{'lockdate_asstring'} = Sympa::Tools::Time::epoch2yyyymmjj_hhmmss($message->{'lockdate'});
	    $message->{'messageasstring'} = MIME::Base64::decode($message->{'message'}) if ($message->{'message'}) ;
	    $message->{'listname'} = $message->{'list'}; # duplicated because "list" is a tt2 method that convert a string to an array of chars so you can't test  [% IF  message.list %] because it is always defined!!!
	    $message->{'status'} = $self->{'selection_status'};
	    push @messages, $message;
	}
	$sth->finish();
	$sth = pop @sth_stack;
	return @messages;
    }
}

#######################
#
#  next : return next spool entry ordered by priority next lock the message_in_spool that is returned
#
sub next {
    my ($self, $selector) = @_;

    Sympa::Log::do_log('debug', '(%s,%s)',$self->{'spoolname'},$self->{'selection_status'});

    my $sql_where = _sqlselector($selector);

    if ($self->{'selection_status'} eq 'bad') {
	$sql_where = $sql_where."AND message_status_spool = 'bad' " ;
    }else{
	$sql_where = $sql_where."AND message_status_spool != 'bad' " ;
    }
    $sql_where =~ s/^\s*AND//;

    my $lock = $PID.'@'.hostname();
    my $epoch=time; # should we use milli or nano seconds ?

    my $statement = sprintf "UPDATE spool_table SET messagelock_spool=%s, lockdate_spool =%s WHERE messagelock_spool IS NULL AND spoolname_spool =%s AND %s ORDER BY priority_spool, date_spool LIMIT 1", Sympa::SDM::quote($lock),Sympa::SDM::quote($epoch),Sympa::SDM::quote($self->{'spoolname'}),$sql_where;
    push @sth_stack, $sth;

    $sth = Sympa::SDM::do_query($statement);
    return undef unless ($sth->rows); # spool is empty

    my $star_select = _selectfields();
    my $statement = sprintf "SELECT %s FROM spool_table WHERE spoolname_spool = %s AND message_status_spool= %s AND messagelock_spool = %s AND lockdate_spool = %s AND (priority_spool != 'z' OR priority_spool IS NULL) ORDER by priority_spool LIMIT 1", $star_select ,Sympa::SDM::quote($self->{'spoolname'}),Sympa::SDM::quote($self->{'selection_status'}),Sympa::SDM::quote($lock),Sympa::SDM::quote($epoch);

    $sth = Sympa::SDM::do_query($statement);
    my $message = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish();
    $sth = pop @sth_stack;

    unless ($message->{'message'}){
Sympa::Log::do_log('err',"INTERNAL Could not find message previouly locked");
	return undef;
    }
    $message->{'messageasstring'} = MIME::Base64::decode($message->{'message'});
    unless ($message->{'messageasstring'}){
Sympa::Log::do_log('err',"Could not decode %s",$message->{'message'});
	return undef;
    }
    return $message  ;
}

#################"
# return one message from related spool using a specified selector
#
sub get_message {
    my ($self, $selector) = @_;
    Sympa::Log::do_log('debug', "($self->{'spoolname'},messagekey = $selector->{'messagekey'}, listname = $selector->{'listname'},robot = $selector->{'robot'})");


    my $sqlselector = '';

    foreach my $field (keys %$selector){
#	unless (defined %{$db_struct{'mysql'}{'spool_table'}{$field.'_spool'}}) {
#	   Sympa::Log::do_log ('err',"internal error : invalid selector field $field locking for message in spool_table");
#	    return undef;
#	}

	$sqlselector = $sqlselector.' AND ' unless ($sqlselector eq '');

	if ($field eq 'messageid') {
	    $selector->{'messageid'} = substr $selector->{'messageid'}, 0, 95;
	}
	$sqlselector = $sqlselector.' '.$field.'_spool = '.Sympa::SDM::quote($selector->{$field});
    }
    my $all = _selectfields();
    my $statement = sprintf "SELECT %s FROM spool_table WHERE spoolname_spool = %s AND ".$sqlselector.' LIMIT 1',$all,Sympa::SDM::quote($self->{'spoolname'});

    push @sth_stack, $sth;
    $sth = Sympa::SDM::do_query($statement);

    my $message = $sth->fetchrow_hashref('NAME_lc');
    if ($message) {
	$message->{'lock'} =  $message->{'messagelock'};
	$message->{'messageasstring'} = MIME::Base64::decode($message->{'message'});
    }

    $sth-> finish;
    $sth = pop @sth_stack;
    return $message;
}

#################"
# lock one message from related spool using a specified selector
#
sub unlock_message {
    my ($self, $messagekey) = @_;

    Sympa::Log::do_log('debug', '(%s,%s)', $self->{'spoolname'}, $messagekey);
    return ( $self->update({'messagekey' => $messagekey},
			   {'messagelock' => 'NULL'}));
}

#################"
#
#  update spool entries that match selector with values
sub update {
    my ($self, $selector, $values) = @_;
    Sympa::Log::do_log('debug', "($self->{'spoolname'}, list = $selector->{'list'}, robot = $selector->{'robot'}, messagekey = $selector->{'messagekey'}");

    my $where = _sqlselector($selector);

    my $set = '';

    # hidde B64 encoding inside spool database.
    if ($values->{'message'}) {
	$values->{'size'} =  length($values->{'message'});
	$values->{'message'} =  MIME::Base64::encode($values->{'message'})  ;
    }
    # update can used in order to move a message from a spool to another one
    $values->{'spoolname'} = $self->{'spoolname'} unless($values->{'spoolname'});

    foreach my $meta (keys %$values) {
	next if ($meta =~ /^(messagekey)$/);
	if ($set) {
	    $set = $set.',';
	}
	if (($meta eq 'messagelock')&&($values->{$meta} eq 'NULL')){
	    # SQL set  xx = NULL and set xx = 'NULL' is not the same !
	    $set = $set .$meta.'_spool = NULL';
	}else{
	    $set = $set .$meta.'_spool = '.Sympa::SDM::quote($values->{$meta});
	}
	if ($meta eq 'messagelock') {
	    if ($values->{'messagelock'} eq 'NULL'){
		# when unlock always reset the lockdate
		$set =  $set .', lockdate_spool = NULL ';
	    }else{
		# when setting a lock always set the lockdate
		$set =  $set .', lockdate_spool = '.Sympa::SDM::quote(time);
	    }
	}
    }

    unless ($set) {
Sympa::Log::do_log('err',"No value to update"); return undef;
    }
    unless ($where) {
Sympa::Log::do_log('err',"No selector for an update"); return undef;
    }

    ## Updating Db
    my $statement = sprintf "UPDATE spool_table SET %s WHERE (%s)", $set,$where ;

    unless (Sympa::SDM::do_query($statement)) {
Sympa::Log::do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    return 1;
}

################"
# store a message in database spool
#
#    I<$metadata>: a set of attributes related to the spool
#   I<$locked>: if define message must stay locked after store
sub store {
    my ($self, $message_asstring, $metadata, $locked) = @_;

    my $sender = $metadata->{'sender'};
    $sender |= '';

   Sympa::Log::do_log('debug',"($self->{'spoolname'},$self->{'selection_status'}, <message_asstring> ,list : $metadata->{'list'},robot : $metadata->{'robot'} , date: $metadata->{'date'}), lock : $locked");

    my $b64msg = MIME::Base64::encode($message_asstring);
    my $message;
    if ($self->{'spoolname'} ne 'task') {
	$message = Sympa::Message->new({'messageasstring'=>$message_asstring});
    }

    if($message) {
	$metadata->{'spam_status'} = $message->{'spam_status'};
	$metadata->{'subject'} = $message->{'msg'}->head->get('Subject'); chomp $metadata->{'subject'} ;
	$metadata->{'subject'} = substr $metadata->{'subject'}, 0, 109;
	$metadata->{'messageid'} = $message->{'msg'}->head->get('Message-Id'); chomp $metadata->{'messageid'} ;
	$metadata->{'messageid'} = substr $metadata->{'messageid'}, 0, 295;
	$metadata->{'headerdate'} = substr $message->{'msg'}->head->get('Date'), 0, 78;

	my @sender_hdr = Mail::Address->parse($message->{'msg'}->get('From'));
	if ($#sender_hdr >= 0){
	    $metadata->{'sender'} = lc($sender_hdr[0]->address) unless ($sender);
	    $metadata->{'sender'} = substr $metadata->{'sender'}, 0, 109;
	}
    }else{
	$metadata->{'subject'} = '';
	$metadata->{'messageid'} = '';
	$metadata->{'sender'} = $sender;
    }
    $metadata->{'date'}= int(time) unless ($metadata->{'date'}) ;
    $metadata->{'size'}= length($message_asstring) unless ($metadata->{'size'}) ;
    $metadata->{'message_status'} = 'ok';

    my $insertpart1; my $insertpart2;
    foreach my $meta ('list','robot','message_status','priority','date','type','subject','sender','messageid','size','headerdate','spam_status','dkim_privatekey','dkim_d','dkim_i','dkim_selector','create_list_if_needed','task_label','task_date','task_model','task_object') {
	$insertpart1 = $insertpart1. ', '.$meta.'_spool';
	$insertpart2 = $insertpart2. ', '.Sympa::SDM::quote($metadata->{$meta});
    }
    my $lock = $PID.'@'.hostname() ;

    push @sth_stack, $sth;
    my $statement        = sprintf "INSERT INTO spool_table (spoolname_spool, messagelock_spool, message_spool %s ) VALUES (%s,%s,%s %s )",$insertpart1,Sympa::SDM::quote($self->{'spoolname'}),Sympa::SDM::quote($lock),Sympa::SDM::quote($b64msg), $insertpart2;

    $sth = Sympa::SDM::do_query ($statement);

    $statement = sprintf "SELECT messagekey_spool as messagekey FROM spool_table WHERE messagelock_spool = %s AND date_spool = %s",Sympa::SDM::quote($lock),Sympa::SDM::quote($metadata->{'date'});
    $sth = Sympa::SDM::do_query ($statement);
    # this query returns the autoinc primary key as result of this insert

    my $inserted_message = $sth->fetchrow_hashref('NAME_lc');
    my $messagekey = $inserted_message->{'messagekey'};

    $sth-> finish;
    $sth = pop @sth_stack;

    unless ($locked) {
	$self->unlock_message($messagekey);
    }
    return $messagekey;
}

################"
# remove a message in database spool using (messagekey,list,robot) which are a unique id in the spool
#
sub remove_message {
    my ($self, $selector) = @_;

    my $robot = $selector->{'robot'};
    my $messagekey = $selector->{'messagekey'};
    my $listname = $selector->{'listname'};
   Sympa::Log::do_log('debug',"remove_message ($self->{'spoolname'},$listname,$robot,$messagekey)");

    ## search if this message is already in spool database : mailfile may perform multiple submission of exactly the same message
    unless ($self->get_message($selector)){
	Sympa::Log::do_log('err',"message not in spool");
		return undef;
    }

    my $sqlselector = _sqlselector($selector);
    #my $statement  = sprintf "DELETE FROM spool_table WHERE spoolname_spool = %s AND messagekey_spool = %s AND list_spool = %s AND robot_spool = %s AND bad_spool IS NULL",Sympa::SDM::quote($self->{'spoolname'}),Sympa::SDM::quote($messagekey),Sympa::SDM::quote($listname),Sympa::SDM::quote($robot);
    my $statement  = sprintf "DELETE FROM spool_table WHERE spoolname_spool = %s AND %s",Sympa::SDM::quote($self->{'spoolname'}),$sqlselector;

    push @sth_stack, $sth;
    $sth = Sympa::SDM::do_query ($statement);

    $sth-> finish;
    $sth = pop @sth_stack;
    return 1;
}


################"
# Clean a spool by removing old messages
#

sub clean {
    my ($self, $filter) = @_;

    my $delay = $filter->{'delay'};
    my $bad =  $filter->{'bad'};


    Sympa::Log::do_log('debug', '(%s,$delay)',$self->{'spoolname'},$delay);
    my $spoolname = $self->{'spoolname'};
    return undef unless $spoolname;
    return undef unless $delay;

    my $freshness_date = time - ($delay * 60 * 60 * 24);

    my $sqlquery = sprintf "DELETE FROM spool_table WHERE spoolname_spool = %s AND date_spool < %s ",Sympa::SDM::quote($spoolname),Sympa::SDM::quote($freshness_date);
    if ($bad) {
	$sqlquery  = 	$sqlquery . " AND bad_spool IS NOTNULL ";
    }else{
	$sqlquery  = 	$sqlquery . " AND bad_spool IS NULL ";
    }

    push @sth_stack, $sth;
    Sympa::SDM::do_query($sqlquery);
    $sth-> finish;
   Sympa::Log::do_log('debug',"%s entries older than %s days removed from spool %s" ,$sth->rows,$delay,$self->{'spoolname'});
    $sth = pop @sth_stack;
    return 1;
}


# test the maximal message size the database will accept
sub store_test {
    my ($value_test) = @_;

    my $divider = 100;
    my $steps = 50;
    my $maxtest = $value_test/$divider;
    my $size_increment = $divider*$maxtest/$steps;
    my $barmax = $size_increment*$steps*($steps+1)/2;
    my $even_part = $barmax/$steps;

    Sympa::Log::do_log('debug', '()');

    print "maxtest: $maxtest\n";
    print "barmax: $barmax\n";
    my $progress = Term::ProgressBar->new({name  => 'Total size transfered',
                                         count => $barmax,
                                         ETA   => 'linear', });

    my $testing = Sympa::Spool->new('bad');

    my $msg = sprintf "From: justeatester\@notadomain\nMessage-Id:yep\@notadomain\nSubject: this a test\n\n";
    $progress->max_update_rate(1);
    my $next_update = 0;
    my $total = 0;

    my $result = 0;

    for (my $z=1;$z<=$steps;$z++){
	for(my $i=1;$i<=1024*$size_increment;$i++){
	    $msg .=  'a';
	}
	my $time = time();
        $progress->message(sprintf "Test storing and removing of a %5d kB message (step %s out of %s)", $z*$size_increment, $z, $steps);
	#
	unless ($testing->store($msg,{list=>'notalist',robot=>'notaboot'})) {
	    return (($z-1)*$size_increment);
	}
	my $messagekey = get_messagekey($msg);
	unless ( $testing->remove_message({'messagekey'=>$messagekey,'listname'=>'notalist','robot'=>'notarobot'}) ) {
	    Sympa::Log::do_log('err','Unable to remove test message (key = %s) from spool_table',$messagekey);
	}
	$total += $z*$size_increment;
        $progress->message(sprintf ".........[OK. Done in %.2f sec]", time() - $time);
	$next_update = $progress->update($total+$even_part)
	    if $total > $next_update && $total < $barmax;
	$result = $z*$size_increment;
    }
    $progress->update($barmax)
	if $barmax >= $next_update;
    return $result;
}




#######################
# Internal to ease SQL
# return a SQL SELECT substring in ordder to select choosen fields from spool table
# selction is comma separated list of field, '*' or '*_but_message'. in this case skip message_spool field
sub _selectfields{
    my ($selection) = @_;

    $selection = '*' unless $selection;
    my $select ='';

    if (($selection eq '*_but_message')||($selection eq '*')) {

	my %db_struct = Sympa::DatabaseDescription::db_struct();

	foreach my $field ( keys %{ $db_struct{'mysql'}{'spool_table'}} ) {
	    next if (($selection eq '*_but_message') && ($field eq 'message_spool')) ;
	    my $var = $field;
	    $var =~ s/\_spool//;
	    $select = $select . $field .' AS '.$var.',';
	}
    }else{
	my @fields = split (/,/,$selection);
	foreach my $field (@fields){
	    $select = $select . $field .'_spool AS '.$field.',';
	}
    }

    $select =~ s/\,$//;
    return $select;
}

#######################
# Internal to ease SQL
# return a SQL WHERE substring in order to select chosen fields from the spool table
# selector is a hash where key is a column name and value is column value expected.****
#   **** value can be prefixed with <,>,>=,<=, in that case the default comparator operator (=) is changed, I known this is dirty but I'm lazy :-(
sub _sqlselector {
    my ($selector) = @_;

    my $sqlselector = '';

    foreach my $field (keys %$selector) {
	my $compare_operator = '=';
	my $select_value = $selector->{$field};
	if ($select_value =~ /^([\<\>]\=?)\.(.*)$/){
	    $compare_operator = $1;
	    $select_value = $2;
	}

	if ($sqlselector) {
	    $sqlselector .= ' AND '.$field.'_spool '.$compare_operator.' '.Sympa::SDM::quote($selector->{$field});
	}else{
	    $sqlselector = ' '.$field.'_spool '.$compare_operator.' '.Sympa::SDM::quote($selector->{$field});
	}
    }
    return $sqlselector;
}

1;
