# @(#)$Id: Schema.pm 790 2009-06-30 02:51:12Z pjf $

package App::Munchies::Schema;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.4.%d', q$Rev: 790 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Programs CatalystX::Usul::Schema);

use App::Munchies::Model::MealMaster;
use App::Munchies::Schema::Authentication;
use App::Munchies::Schema::Catalog;
use DBI;

__PACKAGE__->mk_accessors( qw(auth_schema catalog_schema ctlfile
                              database driver dsn host password
                              recipe_model schema_version user unlink
                              version) );

sub new {
   my ($class, @rest) = @_; my $dbs;

   my $self = $class->next::method( @rest );

   $self->attrs    ( { add_drop_table => 1, no_comments => 1 } );
   $self->databases( [ qw(MySQL) ]                             );

   if ($dbs = $self->vars->{databases}) {
      push @{ $self->databases }, ref $dbs eq q(ARRAY) ? @{ $dbs } : $dbs;
   }

   $self->auth_schema   ( q(App::Munchies::Schema::Authentication) );
   $self->catalog_schema( q(App::Munchies::Schema::Catalog)        );
   $self->database      ( $self->vars->{dbname } || q(library)     );
   $self->recipe_model  ( q(App::Munchies::Model::MealMaster)      );
   $self->schema_version( $self->vars->{version} || q(0.1)         );
   $self->unlink        ( $self->vars->{unlink } || 0              );
   $self->version       ( $VERSION                                 );

   $self->ctlfile( $self->catfile( $self->ctrldir, $self->database.'.xml' ) );

   my $info = $self->connect_info( $self->ctlfile,
                                   $self->database, $self->secret );
   my $dsn  = $self->vars->{dsn     } || $info->[0];
   my $user = $self->vars->{user    } || $info->[1];
   my $pass = $self->vars->{password} || $info->[2];
   my $host = (split q(=), grep { m{ \A host= }mx } split q(;), $dsn)[1];

   $self->driver  ( (split q(:), $dsn)[1] );
   $self->dsn     ( $dsn  );
   $self->host    ( $host );
   $self->password( $pass );
   $self->user    ( $user );

   return $self;
}

sub catalog_mmf {
   my $self  = shift;
   my $dir   = $self->catdir( $self->root, 'recipes' );
   my $gid   = $self->vars->{gid};
   my $model = $self->recipe_model->new
      ( $self, { catalog_schema => $self->catalog_schema,
                 database       => $self->database } );
   my $path  = $self->catfile( $self->dbasedir, 'recipes.tgz' );
   my $uid   = $self->vars->{uid};

   umask 007;

   if (-f $path && -d $dir && ! -f $self->catfile( $dir, 'replace' )) {
      $self->run_cmd( 'cd '.$self->root.'; tar -xzf '.$path );
   }

   $self->output( 'Cataloging started' );
   $self->output( $model->catalog_mmf( @ARGV ) );

   if (defined $uid and defined $gid) {
      $self->run_cmd( q(chown -R ).$uid.q(:).$gid.q( ).$dir );
      $self->run_cmd( q(chmod -R g+rw ).$dir );
      $self->run_cmd( q(chmod g+s ).$dir );
      chown $uid, $gid, $dir;
   }

   return 0;
}

sub create_database {
   my $self = shift; my ($drh, $res);

   if ($self->driver eq q(mysql)) {
      $self->output( 'Creating database '.$self->database );
      $drh = DBI->install_driver( $self->driver );
      $res = $drh->func( q(createdb), $self->database, $self->host,
                         $self->user, $self->password, q(admin) );
   }

   return 0;
}

sub create_ddl {
   my $self = shift;

   $self->output( 'Creating DDL for '.$self->dsn );
   my $dbh = $self->catalog_schema->connect( $self->dsn, $self->user,
                                             $self->password, $self->attrs );
   $self->next::method( $dbh, $self->schema_version,
                        $self->dbasedir, $self->unlink );
   return;
}

sub deploy_and_populate {
   my $self = shift; my $dbh;

   $self->output( 'Connecting to '.$self->dsn );
   $dbh = $self->catalog_schema->connect( $self->dsn, $self->user,
                                          $self->password, $self->attrs );
   $self->next::method( $dbh, $self->dbasedir, $self->catalog_schema );
   $dbh = $self->auth_schema->connect( $self->dsn, $self->user,
                                       $self->password, $self->attrs );
   $self->next::method( $dbh, $self->dbasedir, $self->auth_schema );
   return 0;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Schema - Command line database utility methods

=head1 Version

0.4.$Revision: 790 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head2 new

=head2 catalog_mmf

=head2 create_database

=head2 create_ddl

=head2 deploy_and_populate

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<Class::Accessor::Fast>

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

Copyright (c) 2008 Peter Flanigan. All rights reserved

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
