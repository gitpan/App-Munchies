# @(#)$Id: Build.PL 1301 2012-04-04 08:10:52Z pjf $

use strict;
use warnings;
use inc::Bob; # Module::Build subclass
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1301 $ =~ /\d+/gmx );

use File::Spec::Functions;

Bob->new( {
   module    => q(App::Munchies),
   home_page => q(http://www.roxsoft.co.uk/munchies),
   requires  => {
      'perl'                                 => 5.010,
      'namespace::autoclean'                 => 0.09,
      'parent'                               => 0.221,
      'version'                              => 0.87,
      'Catalyst'                             => 5.90010,
      'CatalystX::RoleApplicator'            => 0.005,
      'CatalystX::Usul'                      => q(0.6.0),
      'Class::Accessor'                      => 0.31,
      'Class::Null'                          => 1.09,
      'DBIx::Class'                          => 0.08112,
      'Data::CloudWeights'                   => q(0.6.0),
      'Date::Discordian'                     => 1.36,
      'DateTime::Event::Sunrise'             => 0.0501,
      'DateTime::Fiction::JRRTolkien::Shire' => 0.02,
      'File::DataClass'                      => q(0.8.0),
      'HTML::Accessors'                      => q(0.6.0),
      'HTML::Entities'                       => 3.68,
      'KinoSearch'                           => 0.3,
      'Moose'                                => 2.0402,
      'Plack'                                => 0.9985,
      'Starman'                              => 0.3000,
      'Text::Lorem::More'                    => 0.13,
      'TryCatch'                             => 1.002000,
      'WWW::Wikipedia'                       => 2.00, },
   recommends                                => {
      'local::lib'                           => 1.008004,
      'Plack::Middleware::Debug'             => 0.11,
      'SVN::Class'                           => 0.16, },
   configure_requires        => {
      'version'              => 0.87,
      'CatalystX::Usul'      => q(0.5.1151),
      'Module::Build'        => 0.37, },
   build_requires            => {
      'version'              => 0.87,
      'CatalystX::Usul'      => q(0.5.1151),
      'Test::More'           => 0.74, },
   no_index_dir              => [ qw(examples inc t), catdir( qw(var root) ) ],
   notes                     => {
      'admin_role'           => q(support),
      'copy_files'           => [ {
         from                => [ qw(META.yml)         ],
         to                  => [ qw(var etc META.yml) ] }, {
         from                => [ qw(var etc etc_default) ],
         to                  => [ q(), qw(etc default app-munchies) ] }, ],
      'create_dirs'          => [ [ q(), qw(etc default) ],
                                  [ qw(var hist) ],
                                  [ qw(var logs) ],
                                  [ qw(var root recipes) ],
                                  [ qw(var root reports) ],
                                  [ qw(var run) ],
                                  [ qw(var tmp) ], ],
      'create_files'         => [ [ qw(var etc  aliases) ],
                                  [ qw(var logs cli.log) ],
                                  [ qw(var logs admin.log) ],
                                  [ qw(var logs server.log) ], ],
      'database_name'        => q(library),
      'debian_depends'       => [ qw(libexpat1-dev perl-suid) ],
      'deploy_server'        => q(plack),
      'group'                => q(munchies),
      'll_author'            => q(A/AP/APEIRON),
      'll_ver_dir'           => q(local-lib-1.008004),
      'make_default'         => 1,
      'min_perl_ver'         => q(5.008),
      'owner'                => q(munchies),
      'perl_mirror'          => q(http://ftp.plig.net/pub/CPAN/),
      'post_install_cmd'     => q(munchies_admin -nc post_install),
      'post_install_methods' => [ { admin  => q(create_ugrps)    },
                                  { admin  => q(set_owner)       },
                                  { admin  => q(set_permissions) },
                                  { admin  => q(init_suid)       },
                                  { schema => q(create_schema)   },
                                  { admin  => q(make_default)    },
                                  { admin  => q(deploy_server)   },
                                  { admin  => q(restart_server)  },
                                  { cli    => q(pod2html)        },
                                  { schema => q(catalog_mmf)     }, ],
      'prefix'               => q(munchies),
      'process_owner'        => q(munchies),
      'restart_server'       => 1,
      'restart_server_cmd'   => q(/usr/sbin/invoke-rc.d app-munchies restart),
      'shell'                => q(/bin/ksh),
      'uninstall_cmd'        => q(munchies_admin -nc uninstall),
   },
} )->create_build_script; # Goal!

# Local Variables:
# mode: perl
# tab-width: 3
# End:
