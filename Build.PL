# @(#)$Id: Build.PL 791 2009-06-30 11:08:00Z pjf $

my $PREFIX     = q(/opt);
my $APPNAME    = q(App::Munchies);
my $HOME_PAGE  = q(http://www.roxsoft.co.uk);
my $LICENSE    = q(http://dev.perl.org/licenses/);
my $TRACKER    = q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=);
my $DBNAME     = q(library);
my $RECOMMENDS = { 'Authen::Simple::PAM' => q(0.2) };
my $REQUIRES   = {
   'perl'                                                 => q(5.008),
   'parent'                                               => q(0.221),
   'version'                                              => q(0.74),
   'Authen::Simple'                                       => q(0.4),
   'Catalyst::Authentication::Credential::Authen::Simple' => q(0.02),
   'CatalystX::Usul'                                      => q(0.3.613),
   'Data::CloudWeights'                                   => q(0.3.103),
   'Date::Discordian'                                     => q(1.36),
   'DateTime::Event::Sunrise'                             => q(0.0501),
   'DateTime::Fiction::JRRTolkien::Shire'                 => q(0.02),
   'DBI'                                                  => q(1.607),
   'IO::Interactive'                                      => q(0.0.3),
   'KinoSearch'                                           => q(0.20_04),
   'MealMaster'                                           => q(0.28),
   'Template::Stash'                                      => q(2.9),
   'Text::Lorem::More'                                    => q(0.12),
   'WWW::Wikipedia'                                       => q(1.94),
};

use Carp;
use English qw(-no_match_vars);

sub say {
   my @arg = @ARG; chomp( @arg ); local ($OFS, $ORS) = ("\n", "\n");

   return print {*STDOUT} @arg or croak "IO error\n";
}

sub whimper { say @ARG; exit 0 }

BEGIN {
   eval { require 5.008; }; $EVAL_ERROR && whimper 'Perl minimum 5.008';
   # Old versions of CPANPLUS::Dist::Build do not support configure_requires
   # Stop chris from smoke testing with old CPANPLUS::Dist::Build on darwin
   qx(uname -a) =~ m{ bingosnet.co.uk }mx && whimper 'Bingos stopped';
}

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.4.%d', q$Rev: 791 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, q(lib) );

use CatalystX::Usul::Build;

my $build_class = q(CatalystX::Usul::Build);
my $class_path  = catfile( q(lib), split m{ :: }mx, $APPNAME.q(.pm) );
my $distname    = $APPNAME; $distname =~ s{ :: }{-}gmx;
my $repository  = $build_class->repository;
my $resources   = { license => $LICENSE, bugtracker => $TRACKER.$distname, };

$resources->{homepage  } = $HOME_PAGE  if ($HOME_PAGE);
$resources->{repository} = $repository if ($repository);

my $sub_class   = $build_class->subclass( class => q(Bob), code => <<'EOB' );

use File::Copy qw(copy);

sub ACTION_install {
   my $self = shift;
   my $cli  = $self->cli;
   my $cfg  = $self->next::method();
   my $bind = $self->install_destination( q(bin) );
   my $libd = $self->install_destination( q(lib) );
   my $vard = $self->install_destination( q(var) );

   # Fix hard coded path in suid program
   my $name = (split m{ :: }mx, lc $self->module_name)[-1];
   my $pref = $self->notes      ( q(prefix) );
   my $appl = $cli->class2appdir( $self->module_name );
   my $from = $cli->catdir      ( $pref, $appl, qw(default lib) );
   my $path = $cli->catfile     ( $bind, $name.q(_admin) );

   $self->replace( $from, $libd, $path );

   my $gid  = $cfg->{gid}; my $uid = $cfg->{uid};

   chown 0, $gid, $path;
   chmod oct q(04750), $path if ($cfg->{setuid_root});

   # Restrict access for these files to root only
   my $secd = $cli->catdir( $vard, q(secure) );

   chown 0, $gid, $secd;
   chown 0, $gid, $cli->catfile( $secd, $cfg->{admin_role}.q(.sub) );
   chown 0, $gid, $cli->catfile( $secd, q(apache.sub) );

   # Final permission tweaks
   my $etcd = $cli->catdir( $vard, q(etc) );

   chmod oct q(02770), $etcd;
   chmod oct q(0660),  $cli->catfile( $vard, qw(logs cli.log) );
   chmod oct q(0640),  $cli->catfile( $bind, $name.q(_suenv) );

   # Save the META.yml file so get_meta works for pod2html
   my $base = $self->base_dir;

   $from = $cli->catfile( $base, q(META.yml) );
   $path = $cli->catfile( $etcd, q(META.yml) );

   copy( $from, $path ); chown $uid, $gid, $path;

   # Custom post installation commands
   $self->post_install( $cfg );

   $cli->info( 'Installation complete' );
   return;
}

sub process_data_files {
   my $self = shift; my $cli = $self->cli; $self->skip_pattern( 0 );

   return $self->process_files( $cli->catfile( qw(var db recipes.tgz) ) );
}

sub process_var_files {
   my $self = shift; my $cli = $self->cli;

   my $recipes = $cli->catdir( q(), q(recipes) );
   my $reports = $cli->catdir( q(), q(reports) );

   $self->skip_pattern( qr{ (?: $recipes | $reports ) }mx );

   return $self->process_files( q(var) );
}
EOB
# End of Bob

my $builder = $sub_class->new
   ( add_to_cleanup     => [ q(Debian_CPANTS.txt),
                             $distname.q(-*), q(Makefile),
                             map { ( q(*/) x $_ ) . q(*~) } 0..5 ],
     build_requires     => { 'Test::More'      => q(0.74) },
     configure_requires => { 'Module::Build'   => q(0.31),
                             'CatalystX::Usul' => q(0.1.437),
                             'version'         => q(0.74) },
     create_packlist    => 0,
     create_readme      => 1,
     dist_version_from  => $class_path,
     license            => q(perl),
     module_name        => $APPNAME,
     no_index           => { directory => [ qw(t var/root) ] },
     notes              => { dbname    => $DBNAME,
                             prefix    => $PREFIX, },
     recommends         => $RECOMMENDS,
     requires           => $REQUIRES,
     resources          => $resources,
     sign               => 1, );

$builder->add_build_element( q(data) );
$builder->add_build_element( q(xml)  );
$builder->add_build_element( q(var)  );
$builder->create_build_script;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
