# @(#)$Id: Bob.pm 1285 2012-03-28 10:58:59Z pjf $

package Bob;

use strict;
use warnings;
use inc::CPANTesting;

# For stopping the tool chain early and quietly
sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

BEGIN {
   eval { require 5.008; }; $@ and whimper 'Perl minimum 5.8';
   my $reason; $reason = CPANTesting::broken and whimper $reason;
}

# If we are using local::lib find and source the environment script
use English qw( -no_match_vars );
use File::Spec::Functions;
use FindBin qw( $Bin );

BEGIN {
   my $path = catfile( $Bin, qw(bin munchies_localenv) );

   if (-f $path) { do $path or whimper $EVAL_ERROR }
}

# Back to the normal program declarations
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1285 $ =~ /\d+/gmx );

use CatalystX::Usul::Build;
use Config;

sub new {
   # Instantiate and return an instance of an inline subclass of
   # CX::U::B an explicite subclass of Module::Build
   my ($class, $params) = @_; $params ||= {};

   my $module      = $params->{module} or whimper 'No module name';
   my $distname    = $module; $distname =~ s{ :: }{-}gmx;
   my $class_path  = catfile( q(lib), split m{ :: }mx, $module.q(.pm) );
   my $build_class = __get_build_class( $params );
   my $sub_class   = $build_class->subclass( code => q{
      # Application specific inline custom methods

      sub hook_local_deps {
         # Patch the locally installed copy of M::B
         my ($self, $cfg) = @_; my $cli = $self->cli; my ($patch, $path);

         $path  = $cli->io( [ $cfg->{local_libperl},
                              qw(Module Build Base.pm) ] );
         $patch = $cli->io( [ qw(inc M_B_Base.patch) ] );
         $self->patch_file( $path, $patch );

         $path  = $cli->io( [ $cfg->{local_libperl},
                              qw(Module Build PodParser.pm) ] );
         $patch = $cli->io( [ qw(inc M_B_PodParser.patch) ] );
         $self->patch_file( $path, $patch );
         return;
      }

      sub hook_local_perlbrew {
         # Patch the locally installed copy of Perlbrew
         my ($self, $cfg) = @_; my $cli = $self->cli;

         # TODO: Report these two bugs
         my $perlbrew = $cli->catfile( $cfg->{local_libperl},
                                       qw(App perlbrew.pm));

         $cli->run_cmd( 'chmod u+w '.$perlbrew );
         $cli->run_cmd( 'sed -ie "s/ba|z/ba|k|pdk|z/" '.$perlbrew );

         my $cmd = 's/s (\$select eq \'m\')/s (ref \$select eq \'HASH\')/';

         $cli->run_cmd( 'sed -ie "'.$cmd.'" '.$perlbrew );
         return;
      }

      sub hook_post_install {
         # Final permission tweaks at the end of the post installation process
         my ($self, $cfg) = @_; my $cli = $self->cli;

         my $bind = $self->install_destination( q(bin) );
         my $vard = $self->install_destination( q(var) );
         my $etcd = $cli->catdir( $vard, q(etc) );
         my $tmpd = $cli->tempdir;

         chmod oct q(02770), $etcd;
         chmod oct q(0440),  $cli->catfile( $etcd, q(build.xml) );
         chmod oct q(0660),  $cli->catfile( $vard, qw(logs cli.log) );
         chmod oct q(0640),  $cli->catfile( $bind, $cli->prefix.q(_suenv) );

         my $gid  = getgrnam( $cfg->{group} ) || 0;
         my $uid  = getpwnam( $cfg->{owner} ) || 0;

         chown $uid, $gid, $cli->catfile( $etcd, q(META.yml) );
         chown $uid, $gid, $cli->catfile( $etcd, q(library.xml) );
         chown $uid, $gid, $cli->catfile( $vard, qw(logs server.log) );
         chown $uid, $gid, $cli->catfile( $vard, qw(logs schema.log) );
         chown $uid, $gid, $cli->catfile( $tmpd, q(file-dataclass-schema.dat) );
         return;
      }

      sub process_data_files {
         # Copy the one file into the distro skipped in process_var_files
         my $self = shift; my $cli = $self->cli; $self->skip_pattern( 0 );

         return $self->process_files( $cli->catfile( qw(var db recipes.tgz) ) );
      }

      sub process_var_files {
         # Will copy some of the var tree into the distro
         my $self = shift; my $cli = $self->cli; my $pattern;

         for (qw(.git .svn hist html logs recipes reports tmp)) {
            $pattern .= ($pattern ? ' | ' : q()).$cli->catdir( q(), $_ );
         }

         $self->skip_pattern( qr{ (?: $pattern ) }mx );

         return $self->process_files( q(var) );
      }
   } ); # End of subclass

   # Create an instance of the CX::Usul::Build subclass
   my $builder = $sub_class->new
   ( add_to_cleanup     => [ qw(Debian_CPANTS.txt blib), $distname.q(-*),
                             map { ( q(*/) x $_ ).q(*~) } 0..5 ],
     build_requires     => $params->{build_requires},
     configure_requires => $params->{configure_requires},
     create_license     => 1,
     create_packlist    => 0,
     create_readme      => 1,
     dist_suffix        => __get_dist_suffix( $params ),
     dist_version_from  => $class_path,
     license            => $params->{license} || q(perl),
     meta_merge         => __get_resources( $params, $distname ),
     module_name        => $module,
     no_index           => __get_no_index( $params ),
     notes              => __get_notes( $params ),
     recommends         => $params->{recommends},
     release_status     => $params->{release_status},
     requires           => $params->{requires},
     sign               => defined $params->{sign} ? $params->{sign} : 1, );

   # Add additional elements to the distro
   $builder->add_build_element( q(data)  );
   $builder->add_build_element( q(xml)   );
   $builder->add_build_element( q(var)   );
   $builder->add_build_element( q(local) );

   return $builder;
}

# Private subroutines
# Is this an attempted install on a CPAN testing platform?
sub __cpan_testing { !! ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CR_SMOKER_CURRENT}
                     || ($ENV{PERL5OPT} || q()) =~ m{ CPAN-Reporter }mx) }

sub __is_src {
   # Is this the developer authoring a module?
   return -f q(MANIFEST.SKIP);
}

sub __get_build_class {
   # Which subclass of M::B should we create?
   my $params = shift;
   my $notes  = exists $params->{notes} ? $params->{notes} : {};

   return exists $notes->{build_class}
        ? $notes->{build_class} : q(CatalystX::Usul::Build);
}

sub __get_dist_suffix {
   # If there is a local lib then the dist will contain shared objects
   my $params = shift; not __is_src and return q();

   return -d q(local) ? $Config{myarchname} : q();
}

sub __get_no_index {
   # Instruct the CPAN indexer to ignore these directories
   my $params = shift;

   return { directory => $params->{no_index_dir} || [ qw(examples inc t) ] };
}

sub __get_notes {
   my $params = shift; my $notes = $params->{notes} || {};

   # Optionally create a README.pod file
   $notes->{create_readme_pod} = $params->{create_readme_pod} || 0;
   # Add a note to stop CPAN testing if requested in Build.PL
   $notes->{stop_tests} = ($params->{stop_tests} || 0) && __cpan_testing()
                        ? 'CPAN Testing stopped' : 0;

   return $notes;
}

sub __get_repository {
   # SVN repository information. Only called when building a distribution
   require SVN::Class;

   my $file = SVN::Class->svn_dir( q(.) ) or return;
   my $info = $file->info or return;
   my $repo = $info->root !~ m{ \A file: }mx ? $info->root : undef;

   return $repo;
}

sub __get_resources {
   # Assemble a hash ref of resource string for the META data file
   my $params     = shift;
   my $distname   = shift;
   my $tracker    = defined $params->{bugtracker}
                  ? $params->{bugtracker}
                  : q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=);
   my $resources  = $params->{resources} || {};

   $tracker and $resources->{bugtracker} = $tracker.$distname;
   $params->{home_page} and $resources->{homepage} = $params->{home_page};
   $resources->{license} ||= q(http://dev.perl.org/licenses/);

   my $repo; __is_src and $repo = __get_repository
      and $resources->{repository} = $repo;

   return { resources => $resources };
}

1;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
