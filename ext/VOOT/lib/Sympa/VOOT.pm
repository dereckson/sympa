package Sympa::VOOT;
use base 'Sympa::Plugin';

use warnings;
use strict;

our $VERSION = '0.10';

use JSON           qw/decode_json/;
use List::Util     qw/first/;

# Sympa modules
use report;
use Site;
use Sympa::Plugin::Util   qw/:functions/;
use Sympa::VOOT::Consumer ();

my $default_server = 'Net::VOOT::Renater';

=head1 NAME

Sympa::VOOT - manage VOOT use in Sympa

=head1 SYNOPSIS

  my $voot = Sympa::VOOT->new(config => $filename);

=head1 DESCRIPTION

Intergrate VOOT with Sympa.  This module handles the web interface, and
the various VOOT backends.

=cut

# This object is used everywhere.  It shall not contains information
# about a specific user session.  Instantiation is also needed to make
# configuration of the data_source work.
my $me = __PACKAGE__->new;

#
## register plugin
#

my @url_commands =
  ( opensocial =>
      { handler   => sub { $me->doOpenSocial(@_) }
      , path_args => 'list'
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  , select_voot_provider_request =>
      { handler   => sub { $me->doSelectProvider(@_) }
      , path_args => 'list'
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  , select_voot_groups_request  =>
      { handler   => sub { $me->doListVootGroups(@_) }
      , path_args => [ qw/list voot_provider/ ]
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  , select_voot_groups =>
      { handler   => sub { $me->doAcceptVootGroup(@_) }
      , path_args => [ qw/list voot_provider/ ]
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  , voot =>
      { handler   => sub { $me->doVoot(@_) }
      , path_args => '@voot_path'
      }
  );

my @validate =
  ( voot_path     => '[^<>\\\*\$\n]+'
  , voot_provider => '[\w-]+'
  );  

my @fragments =
  ( list_menu     => 'list_menu_opensocial.tt2'
  , help_editlist => 'help_editlist_voot.tt2'
  );

my @provider_names;
my %include_voot_form =
  ( group      => 'data_source'
  , gettext_id => 'VOOT group inclusion'
  , occurrence => '0-n'
  , format     =>
     [ name =>
        { gettext_id => 'short name for this source'
        , format     => '.+'
        , length     => 15
        }
     , provider => 
        { gettext_id => 'provider'
        , format     => \@provider_names
        }
     , user =>
        { gettext_id => 'user'
        , format     => '\S+'
        }
     , group =>
        { gettext_id => 'group'
        , format     => '\S+'
        }
     ]
  );

sub registerPlugin($)
{   my ($class, $args) = @_;
    push @{$args->{url_commands}}, @url_commands;
    push @{$args->{validate}}, @validate;

    (my $templ_dir = __FILE__) =~ s,\.pm$,/web_tt2,;
    push @{$args->{templates}},
     +{ tt2_path      => $templ_dir
      , tt2_fragments => \@fragments
      };
    push @{$args->{listdef}},
      ( include_voot_group => \%include_voot_form
      );

    $class->SUPER::registerPlugin($args);
}

=head1 METHODS

=head2 Constructors

=head3 $class->new(OPTIONS)

OPTIONS:
 config FILENAME|HASH   voot configuration file (default voot.conf)

=cut

sub new(@)
{   my ($class, %args) = @_;
    (bless {}, $class)->init(\%args);
}

sub init($)
{   my ($self, $args) = @_;

    my $config = $args->{config} || Site->get_etc_filename('voot.conf');

    if(ref $config eq 'HASH')
    {   $self->{SV_config}    = $config;
        $self->{SV_config_fn} = 'HASH';
    }
    else
    {   $self->{SV_config}    = $self->readConfig($config);
        $self->{SV_config_fn} = $config;
    }

    # for config chooser
    @provider_names = $self->providers;

    $self;
}


=head3 my $obj = $class->instance

=cut

sub instance() { $me }

=head2 Accessors

=head3 $obj->config

=head3 $obj->configFilename

=cut

sub config() { shift->{SV_config} }
sub configFilename() { shift->{SV_config_fn} }


=head2 Configuration handling

=head3 $thing->readConfig(FILENAME)

=cut

sub readConfig($)
{   my ($thing, $filename) = @_;
    local *IN;

    open IN, '<:encoding(utf8)', $filename
        or fatal "cannot read VOOT config from $filename";

    local $/;
    my $config = eval { decode_json <IN> };
    $@ and fatal "parse errors in VOOT config $filename: $@";

    close IN
        or fatal "read errors in VOOT config $filename: $@";

    $config;
}

=head3 $obj->consumer(PARAM, ID|NAME, OPTIONS)

Returns the object which handles the selected provider, an extension
of L<Net::VOOT>.

The OPTIONS are passed to the L<Sympa::VOOT::Consumer> constructor.
=cut

sub consumer($$@)
{   my ($self, $param, $ref, @args) = @_;

    my $fn   = $self->configFilename;
    my $info = first {   $_->{'voot.ProviderID'}   eq $ref
                      || $_->{'voot.ProviderName'} eq $ref
                     } $self->providerConfigs;

    $info
        or fatal "cannot find VOOT provider $ref in $fn";

    my $prov_id  = $info->{'voot.ProviderID'};
    my %provider = 
       ( id     => $prov_id
       , name   => $info->{'voot.ProviderName'}
       , server => ($info->{'voot.ServerClass'} || $default_server)
       );

    # old style (6.2-devel): flat list on top-level
    my $auth1 = $info->{oauth1};
    /^x?oauth\.(.*)/ && ($auth1->{$1} = $info->{$_})
         for keys %$info;

    my $auth = $auth1 && keys %$auth1 ? $auth1 : $info->{oauth2};

    # MO: ugly, only used for oauth2 right now.
    $auth->{redirect_uri} ||=
     "$param->{base_url}$param->{path_cgi}/oauth2_ready/$prov_id";

    my $consumer = eval {
        Sympa::VOOT::Consumer->new
          ( provider => \%provider
          , auth     => $auth
          , user     => $param->{user}
          , @args
          )};

    $consumer
        or fatal "cannot start VOOT consumer to $ref: $@";

    $consumer;
}

=head3 $obj->providerConfigs

=head3 $obj->providers

=cut

sub providerConfigs() { @{shift->config} }

sub providers()
{   map +($_->{'voot.ProviderName'} || $_->{'voot.ProviderID'})
      , shift->providerConfigs;
}


=head2 Web interface actions

=head3 $obj->doOpenSocial

=cut

sub doOpenSocial {
    # Currently nice interface to select groups
    return 'select_voot_provider_request';
}

=head3 $obj->doSelectProvider

=cut

sub doSelectProvider(%)
{   my ($self, %args) = @_;
    my $param = $args{param};

    my @providers;
    foreach my $info ($self->providerConfigs)
    {   my $id   = $info->{'voot.ProviderID'};
        my $name = $info->{'voot.ProviderName'} || $id;
        push @providers,
          +{id => $id, name => $name, next => 'select_voot_groups_request'};
    }
    $param->{voot_providers} = [ sort {$a->{name} cmp $b->{name}} @providers ];
    return 1;
}

=head3 $obj->doListVootGroups

=cut

sub doListVootGroups(%)
{   my ($self, %args) = @_;

    my $in       = $args{in};
    my $param    = $args{param};
    my $robot_id = $args{robot};
  
    my $prov_id  = $in->{voot_provider};

    wwslog(info => "get voot groups of $param->{user}{email} for provider $prov_id");

    my $consumer = $self->consumer($param, $prov_id);
    unless($consumer->hasAccess)
    {   my $here = "select_voot_groups_request/$param->{list}/$prov_id";
        return $self->getAccessFor($consumer, $param, $here);
    }

    $param->{voot_provider} = $consumer->provider;

    # Request groups
    my $groups   = eval { $consumer->voot->userGroups };
    if($@)
    {   $param->{error} = 'failed to get user groups';
        return 1;
    }

    # Keep all previously selected groups selected
    $_->{selected} = 0 for values %$groups;
    if(my $list  = this_list)
    {   foreach my $gid ($list->include('voot_groups'))
        {   my $group = $groups->{$gid} or next;
            $group->{selected} = 1;
        }
    }

    # XXX: needs to become language specific sort
    $param->{voot_groups} = [sort {$a->{name} cmp $b->{name}} values %$groups]
        if $groups && keys %$groups;

use Data::Dumper;
log(info => "VOOT got ".Dumper $param->{voot_groups});
    1;
}

sub getAccessFor($$$)
{   my ($self, $consumer, $param, $here) = @_;
    my $goto  = $consumer->startAuth(param => $param, next_page => $here);
    log(info => "going for access at $goto");
    $goto ? main::do_redirect($goto) : 1;
}

# VOOT request
sub doVoot(%)
{   my ($self, %args) = @_;

    my $param = $args{param};
    my $in    = $args{in};

    $param->{bypass} = 'extreme';
    
    my $voot_path = $in->{voot_path};

my $prov_id;
    my $consumer  = $self->consumer($param, $prov_id);

    $consumer->get
      ( method    => $ENV{REQUEST_METHOD}
      , voot_path => $voot_path
      , url       => "$param->{base_url}$param->{path_cgi}/voot/$voot_path"
      , authorization_header => $ENV{HTTP_AUTHORIZATION}
      , request_parameters   => $in
      , robot     => $args{robot_id}
      );
    
    my ($http_code, $http_str)
       = $consumer ? $consumer->checkRequest : (400, 'Bad Request');
    
    my $r      = $consumer->response;
    my $err    = $consumer->{error};
    my $status = $err || "$http_code $http_str";
    
    print <<__HEADER;
Status: $status
Cache-control: no-cache
Content-type: text/plain
__HEADER

    print $r unless $err;
    return 1;
}

=head3 $obj->doAcceptVootGroup
=cut

# VOOT groups choosen, generate config
sub doAcceptVootGroup(%)
{   my ($self, %args) = @_;
    my $param    = $args{param};
    my $in       = $args{in};
    my $list     = $args{list};
    my $robot_id = $args{robot_id};

    my $provider = $param->{voot_provider} = $in->{voot_provider};
    my $email    = $param->{user}{email};

    # Get all the voot_groups fields from the form
    my @groups;
    foreach my $k (keys %$in)
    {   $k =~ /^voot_groups\[([^\]]+)\]$/ or next;
        push @groups, $1 if $in->{$k}==1;
    }
    $param->{voot_groups}  = \@groups;

    my $list     = $main::list;
    my @include_voot_group = @{$list->include_voot_group};    
    foreach my $gid (@groups)
    {   push @include_voot_group,
         +{ name     => $provider.'::'.$gid
          , user     => $email
          , provider => $provider
          , group    => $gid
          };

        # XXX MO: ???
        # No save otherwise ...
        $list->defaults(include_voot_group => undef);
    }
    $list->include_voot_group(\@include_voot_group);

    my $action = $param->{action};
    unless($list->save_config($email))
    {   report::reject_report_web('intern', 'cannot_save_config', {}
          , $action, $list, $email, $robot_id);

        wwslog(info => 'cannot save config file');
        web_db_log({status => 'error', error_type => 'internal'});
        return undef;
    }    

    if($list->on_the_fly_sync_include(use_ttl => 0))
    {   report::notice_report_web('subscribers_updated', {}, $action);
    }
    else
    {   report::reject_report_web('intern', 'sync_include_failed'
           , {}, $action, $list, $email, $robot_id);
    }

    'review';
}

1;

__END__

=head1 DETAILS

The VOOT protocol is a subset of OpenSocial, used to share information
about users and groups of users between organisations.  You may find
more information at L<http://www.openvoot.org>.

=head2 Using VOOT

To be able to use VOOT with Sympa, you need to

=over 4

=item * install the plugins,

=item * create a configuration file F<voot.conf>, and

=item * configure to use some VOOT group for a mailinglist.

=back

=head2 Using a VOOT group

Go, as administrator of a mailinglist first to the OpenSocial menu-entry at
the left.  If you do not see that "OpenSocial" entry, the software is not
installed (correctly).  Search the logs for errors while loading the
plugins.

Then pick a provider.  Authenticate yourself for that provider.  Then select
a group you are member of.

Per list you need the group for, go to tab 'admin/Edit List Config/Data
sources setup' block VOOT.

=head2 Setting-up VOOT

There are few VOOT server implementations.  Read more about how
to use them with Sympa in their specific man-pages:

=over 4

=item L<Sympa::VOOT::SURFconext>, SURFnet NL using OAuth2

=item L<Sympa::VOOT::Renater>, Renater FR using OAuth (v1)

=back

=head2 Description of the VOOT file

By default, the VOOT configuration is found in the Site's etc directory,
with name 'voot.conf'.  This is a JSON file which contains an ARRAY of
provider descriptions.

The OAuth and OAuth2 standards which are used, are weak standards: they
are extremely flexible.  You may need to configure a lot yourself to get
it to work.  This means that you have to provider loads of details about
your VOOT server.

Fields:

   voot.ProviderID     your abbreviation
   voot.ProviderName   beautified name (defaults to ID)
   voot.ServerClass    implementation (defaults to Net::VOOT::Renater)
   oauth  => HASH      parameters to Sympa::OAuth1::new()
   oauth2 => HASH      parameters to Sympa::OAuth2::new()

=cut
