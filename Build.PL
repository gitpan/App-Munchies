#!/usr/bin/perl

# @(#)$Id: Build.PL 656 2009-04-09 21:22:45Z pjf $

sub _error { my $text = shift; print {*STDOUT} $text."\n"; exit 0 }

# Stop chris from smoke testing with broken CPANPLUS
# [MSG] [Wed Apr  8 07:00:49 2009] CPANPLUS is prefering Build.PL
# [ERROR] [Wed Apr  8 07:00:50 2009] Build.PL failed: Can't locate Class/C3.pm
# Class::C3 is in both requires and configure_requires and META.yml

BEGIN {
   eval { require 5.008; }; _error( 'Perl minimum 5.008' ) if ($@);
   _error( 'Bingos stopped' )   if (qx(uname -a) =~ m{ bingosnet.co.uk }mx);
   _error( 'CPANPLUS stopped' ) if ($ENV{PERL5_CPANPLUS_IS_RUNNING});
}

use strict;
use warnings;
use File::Spec::Functions;
use FindBin  qw( $Bin );
use lib (catdir( $Bin, q(lib) ));
use CatalystX::Usul::Build;
use Class::C3;

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 656 $ =~ /\d+/gmx );

my $DBNAME  = 'library';
my $PREFIX  = '/opt';
my $APPNAME = 'App::Munchies';
my $APPLREL = 'v0.1p3';

my $builder = q(CatalystX::Usul::Build);
my $class   = $builder->subclass( class => 'Bob', code => <<'EOB' );

use File::Copy;
use File::Spec::Functions;

sub ACTION_install {
   my $self = shift; my $text;

   $self->next::method();

   my $base = $self->{cfg}->{base};
   my $prog = $self->{cfg}->{prog};
   my @path = split m{ :: }mx, lc $self->module_name;
   my $name = $path[-1];
   my $from = catdir( $self->notes( q(prefix) ), $name, 'default', 'lib' );
   my $path = catfile( $self->{cfg}->{binsdir}, $name.'_suid' );

   # Fix hard coded path in suid program
   $self->replace( $self->{cfg}->{prog},
                   $from, $self->{cfg}->{libsdir}, $path );

   my $gid  = $self->{cfg}->{gid};
   my $uid  = $self->{cfg}->{uid};

   chown 0, $gid, $path;
   chmod oct q(04750), $path if ($self->{cfg}->{set_uid_root});

   # Restrict access for these files to root only
   my $var  = catdir( $base, 'var' );
   my $dir  = catdir( $var,  'secure' );

   chown 0, $gid, $dir;
   chown 0, $gid, catfile( $dir, $self->{cfg}->{admin_role}.'.sub' );
   chown 0, $gid, catfile( $dir, 'apache.sub' );

   # Final permission tweaks
   chmod oct q(02770), catdir(  $var, 'etc' );
   chmod oct q(0660),  catfile( $var, 'logs', 'misc.log' );
   chmod oct q(0640),  catfile( $self->{cfg}->{binsdir}, $name.'_suenv' );

   # Save the META.yml file so get_meta works for pod2html
   copy( catfile( $self->base_dir, 'META.yml' ), catdir( $var, 'etc' ) );
   chown $uid, $gid, catfile( $var, 'etc', 'META.yml' );

   # Announce application availability
   $text  = 'You can connect to the application at http://';
   $text .= $prog->{hostname}.q(/).$name;
   $prog->info( $text );
   $text  = 'The following commands may take a *long* time to complete:';
   $prog->info( $text );

   # Run custom commands. Can take a *long* time so leave til now
   my $pattern = '['.rootdir.curdir.']';

   if ($self->{cfg}->{run_cmd} eq q(yes)) {
      for $path (@{ $self->{cfg}->{run_cmds} }) {
         $path = catdir( $self->{cfg}->{binsdir}, $path )
            unless ($path =~ m{ \A $pattern }xms);
         $path =~ s{ \[% \s uid \s %\] }{$uid}gmx;
         $path =~ s{ \[% \s gid \s %\] }{$gid}gmx;
         $prog->info( 'Running '.$path );
         $prog->info( $prog->run_cmd( $path )->out );
      }
   }
   else {
      for $path (@{ $self->{cfg}->{run_cmds} }) {
         $path = catdir( $self->{cfg}->{binsdir}, $path )
            unless ($path =~ m{ \A $pattern }xms);
         $prog->info( 'Would run '.$path );
      }
   }

   return;
}

sub process_data_files {
   my $self = shift;

   return $self->process_files( catdir( 'var', 'db', 'recipes.tgz' ), 'blib' );
}

sub process_var_files {
   my $self = shift;

   $Bob::skip_pattern = qr{/recipes|/reports};

   return $self->process_files( 'var', catdir( 'blib', 'var' ) );
}
EOB
# End of Bob

# Main
my $requires = {
   'perl'                                                 => q(5.008),
   'version'                                              => q(0.74),
   'Authen::Simple'                                       => q(0.4),
   'Catalyst::Authentication::Credential::Authen::Simple' => q(0.02),
   'CatalystX::Usul'                                      => q(0.1.437),
   'Class::C3'                                            => q(0.19),
   'Data::CloudWeights'                                   => q(0.1.3),
   'Date::Discordian'                                     => q(1.36),
   'DateTime::Event::Sunrise'                             => q(0.0501),
   'DateTime::Fiction::JRRTolkien::Shire'                 => q(0.02),
   'DBI'                                                  => q(1.602),
   'IO::Interactive'                                      => q(0.0.3),
   'KinoSearch'                                           => q(0.20_04),
   'MealMaster'                                           => q(0.28),
   'Template::Stash'                                      => q(2.9),
   'Text::Lorem::More'                                    => q(0.12),
   'WWW::Wikipedia'                                       => q(1.94),
};
my $recommends = {
   'Authen::Simple::PAM' => q(0.2),
};
my $build = $class->new
   ( add_to_cleanup     => [ 'Debian_CPANTS.txt',
                             'App-Munchies-*',
                             map { ( '*/' x $_ ) . '*~' } 0..5 ],
     build_requires     => { 'Test::Harness'       => q(2.64),
                             'Test::More'          => q(0.74),
                             'Test::Pod'           => q(1.14),
                             'Test::Pod::Coverage' => q(1.08) },
     configure_requires => { 'CatalystX::Usul'     => q(0.1.437),
                             'Class::C3'           => q(0.19),
                             'version'             => q(0.74) },
     create_readme      => 1,
     create_packlist    => 0,
     dist_version_from  => catfile( q(lib), split m{ :: }mx, $APPNAME.q(.pm) ),
     license            => q(perl),
     module_name        => $APPNAME,
     notes              => { applrel => $APPLREL,
                             dbname  => $DBNAME,
                             prefix  => $PREFIX },
     recommends         => $recommends,
     requires           => $requires,
     sign               => 1 );

$build->add_build_element( q(data) );
$build->add_build_element( q(xml) );
$build->add_build_element( q(var) );
$build->create_build_script();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
