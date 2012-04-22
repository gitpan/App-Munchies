# @(#)$Id: Schema.pm 1318 2012-04-22 17:10:47Z pjf $

package App::Munchies::Schema;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Programs CatalystX::Usul::Schema);

use App::Munchies::MealMaster;
use App::Munchies::Schema::Authentication;
use App::Munchies::Schema::Catalog;
use CatalystX::Usul::Constants;
use CatalystX::Usul::Functions qw(arg_list);

my %CONFIG = ( auth_schema    => q(App::Munchies::Schema::Authentication),
               catalog_schema => q(App::Munchies::Schema::Catalog),
               database       => q(library),
               preversion     => NUL,
               rdbms          => [ qw(MySQL PostgreSQL) ],
               recipe_class   => q(App::Munchies::MealMaster),
               schema_version => q(0.1),
               unlink         => FALSE, );

sub new {
   my ($self, @rest) = @_; my $attrs = arg_list @rest;

   $attrs->{config} = { %CONFIG, %{ $attrs->{config} || {} } };

   my $new = $self->next::method( $attrs );

   $new->schema_init( $new->config, $new->vars );
   $new->version    ( $VERSION );

   return $new;
}

sub catalog_mmf : method {
   my $self   = shift;
   my $cfg    = $self->config;
   my $dir    = $self->catdir( $cfg->{root}, q(recipes) );
   my $path   = $self->catfile( $cfg->{dbasedir}, q(recipes.tgz) );
   my $domain = $cfg->{recipe_class}->new
      ( $self, { catalog_schema => $cfg->{catalog_schema},
                 database       => $self->database,
                 rootdir        => $cfg->{root},
                 template_dir   => $cfg->{template_dir} } );

   umask 007;

   if (-f $path and -d $dir and not -f $self->catfile( $dir, q(replace) )) {
      $self->run_cmd( q(cd ).$cfg->{root}.q(; tar -xzf ).$path );
   }

   $self->info  ( 'Cataloging started...' );
   $self->output( $domain->catalog_mmf( @ARGV ) );

   my ($uid, $gid) = $self->get_owner( $self->read_post_install_config );

   if (defined $uid and defined $gid) {
      $self->run_cmd( q(chown -R ).$uid.q(:).$gid.SPC.$dir );
      $self->run_cmd( q(chmod -R g+rw ).$dir );
      $self->run_cmd( q(chmod g+s ).$dir );
      chown $uid, $gid, $dir;
   }

   return OK;
}

sub create_ddl : method {
   my $self = shift; my $cfg = $self->config;

   $self->output( 'Creating DDL for '.$self->dsn );

   for my $schema (map { $cfg->{ $_ } } qw(auth_schema catalog_schema)) {
      my $dbh = $schema->connect( $self->dsn, $self->user,
                                  $self->password, $self->attrs );

      $self->next::method( $dbh, $self->config->{dbasedir} );
   }

   return OK;
}

sub deploy_and_populate : method {
   my $self = shift; my $cfg = $self->config;

   $self->output( 'Deploy and populate for '.$self->dsn );

   for my $schema (map { $cfg->{ $_ } } qw(auth_schema catalog_schema)) {
      my $dbh = $schema->connect( $self->dsn, $self->user,
                                  $self->password, $self->attrs );

      $self->next::method( $dbh, $self->config->{dbasedir}, $schema );
   }

   return OK;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Schema - Command line database utility methods

=head1 Version

0.7.$Revision: 1318 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head2 new

=head2 BUILD

=head2 catalog_mmf

=head2 create_database

=head2 create_ddl

=head2 deploy_and_populate

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<App::Munchies::MealMaster>

=item L<App::Munchies::Schema::Authentication>

=item L<App::Munchies::Schema::Catalog>

=item L<CatalystX::Usul::Constants>

=item L<CatalystX::Usul::Programs>

=item L<CatalystX::Usul::Schema>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2011 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
