#! --PERL--
##
## This module is part of "Sympa" software

package Log;

require Exporter;
use Sys::Syslog;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(fatal_err do_log do_openlog);

## RCS identification.
my $id = '@(#)$Id$';

sub fatal_err {
   my $m  = shift;
   my $errno  = $!;

   syslog('err', $m, @_);
   syslog('err', "Exiting.");
#   if ($main::opt_d || $main::opt_F) {
      $m =~ s/%m/$errno/g;
      printf STDERR "$m\n", @_;
#   }
   exit(1);   
}

sub do_log {
    my $fac = shift;
    my $m = shift;
    my $errno = $!;
    my $debug = 0;

    if ($fac eq 'debug2') {
	$fac = 'debug';
	$debug = 1;
	
    }
    else{
         syslog($fac, $m, @_);
    }

    $m =~ s/%m/$errno/g;
    
    if ($main::opt_D) {
	printf STDERR "%s\t$m\n", time, @_;
    }elsif($debug){
	return ;
    }elsif ($main::opt_d || $main::opt_F)   {
	printf STDERR "$m\n", @_;
	
    }
    
}


sub do_list_log {
   my $list = shift;
   my $message = shift;

   syslog($fac, $m, @_);
   if ($main::opt_d || $main::opt_F) {
      $m =~ s/%m/$errno/g;
      printf STDERR "$m\n", @_;
   }
}

sub do_openlog {
   my ($fac, $socket_type, $service) = @_;
   $service ||= 'sympa';

   if ($socket_type =~ /^(unix|inet)$/i) {
      Sys::Syslog::setlogsock(lc($socket_type));
   }
   openlog("$service\[$$\]", 'ndelay', $fac);
}

1;








