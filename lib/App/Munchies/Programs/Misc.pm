# @(#)$Id: Misc.pm 738 2009-06-09 16:42:23Z pjf $

package App::Munchies::Programs::Misc;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 738 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Programs);

use CatalystX::Usul::FileSystem;
use CatalystX::Usul::ProjectDocs;
use CatalystX::Usul::TapeDevice;
use Class::C3;
use English qw(-no_match_vars);
use File::Find;
use File::Path;
use File::Spec;
use XML::Simple;

my $NUL = q();

__PACKAGE__->mk_accessors( qw(delete_after file_class intfdir
                              rel_class rprtdir tape_class version) );

sub new {
   my ($class, @rest) = @_;

   my $self = $class->next::method( @rest );

   $self->delete_after( $self->delete_after || 35 );
   $self->file_class  ( q(CatalystX::Usul::FileSystem) );
   $self->intfdir     ( $self->catfile( $self->vardir, q(transfer) ) );
   $self->rprtdir     ( $self->catfile( $self->vardir, q(root), q(reports) ) );
   $self->tape_class  ( q(CatalystX::Usul::TapeDevice) );
   $self->version     ( $VERSION );

   return $self;
}

sub archive {
   my ($self, @rest) = @_;

   @rest = @ARGV unless (defined $rest[ 0 ]);

   $self->output( $self->file_ref->archive( @rest ) );
   return 0;
}

sub file_ref {
   my ($self, @rest) = @_; return $self->file_class->new( $self, @rest );
}

sub house_keeping {
   my $self = shift; my ($dir, $delete_after, $entry, $io, $path, $rdr);

   # This is a safety feature
   chdir File::Spec->tmpdir if (-d File::Spec->tmpdir);

   # Delete old files from the application tmp directory
   if (-d $self->tempdir) {
      $self->purge_tree( $self->tempdir, 0, 3 );
   }

   # Delete old html reports from the web server's document area
   if (-d $self->rprtdir) {
      find( { no_chdir => 1, wanted => \&__match_dot_files }, $self->rprtdir );
      $self->purge_tree( $self->rprtdir, 0, $self->delete_after );
   }

   # Purge old feed files from the interface directory structure
   $dir = $self->intfdir;

   if (-d $dir) {
      $self->info( 'Deleting old Transporter files' );
      find( { no_chdir => 1, wanted => \&__match_dot_files }, $dir );
      $io = $self->io( $dir );

      while ($entry = $io->next) {
         next unless ($entry->is_dir
                      && $entry->filename ne File::Spec->curdir
                      && $entry->filename ne File::Spec->updir);

         $delete_after = $self->delete_after;
         $path         = $self->catfile( $entry->pathname, '.house' );

         if (-f $path) {
            for (grep { m{ \A mtime= }imsx }
                 $self->io( $path )->chomp->getlines) {
               $delete_after = (split m{ = }mx, $_)[1];
               last;
            }
         }

         $self->info( "Transport $entry mod time $delete_after" );
         $self->purge_tree( $entry->name, 0, $delete_after );
      }

      $io->close;
   }

   $self->rotate_logs;
   return 0;
}

sub pod2html {
   my $self     = shift;
   my $libroot  = $ARGV[0] || $self->catdir( $self->appldir, q(lib) );
   my $rootdir  = $ARGV[1] || $self->root;
   my $metafile = $self->catfile( $self->ctrldir, q(META.yml) );
   my $meta     = $self->get_meta( $metafile );
   my $htmldir  = $self->catdir( $rootdir, 'html' );

   $self->info( 'Creating HTML from POD for '.$meta->name.' '.$meta->version );

   $libroot = [ split m{ \s+ }mx, $libroot ] if ($libroot =~ m{ \s+ }mx);

   my $pd = CatalystX::Usul::ProjectDocs->new( outroot => $htmldir,
                                               libroot => $libroot,
                                               title   => $meta->name,
                                               desc    => $meta->abstract,
                                               lang    => q(en), );

   $pd->gen(); my $uid = $self->vars->{uid}; my $gid = $self->vars->{gid};

   if (defined $uid and defined $gid) {
      $self->run_cmd( q(chown -R ).$uid.q(:).$gid.q( ).$htmldir );
      chown $uid, $gid, $htmldir;
   }

   return 0;
}

sub purge_tree {
   my ($self, @rest) = @_;

   @rest = @ARGV unless (defined $rest[ 0 ]);

   $self->info( $self->file_ref->purge_tree( @rest ) );
   return 0;
}

sub rotate_logs {
   my ($self, @rest) = @_;

   @rest = @ARGV unless (defined $rest[ 0 ]);

   $self->info( $self->file_ref->rotate_logs( @rest ) );
   return 0;
}

sub tape_backup {
   my ($self, @rest) = @_;

   @rest = @ARGV unless (defined $rest[ 0 ]);

   my $tape_obj = $self->tape_class->new( $self, $self->vars );

   $self->info( $tape_obj->process( @rest ) );
   return 0;
}

sub unarchive {
   my ($self, @rest) = @_;

   @rest = @ARGV unless (defined $rest[ 0 ]);

   $self->output( $self->file_ref->unarchive( @rest ) );
   return 0;
}

sub wait_for {
   my ($self, @rest) = @_;

   @rest = @ARGV unless (defined $rest[ 0 ]);

   my $text     = $self->io( $self->ctlfile )->all;
      $text     = join "\n", grep { !m{ <! .+ > }mx } split  m{ \n }mx, $text;
   my $xs       = XML::Simple->new( ForceArray => [ qw(wait_for) ] );
   my $data     = $xs->xml_in( $text );
   my $file_obj = $self->file_ref
      ( { fuser => $self->os->{fuser}->{value}, ctldata => $data } );

   $self->info( $file_obj->wait_for( $self->vars, @rest ) );
   return 0;
}

# Private subroutines

sub __match_dot_files {
   my $now = time;

   utime $now, $now, $_ if (-f $_ && $_ =~ m{ \A \.\w+ }msx);

   return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Programs::Misc - A collection of miscellaneous subroutines

=head1 Version

0.1.$Revision: 738 $

=head1 Synopsis

   #!/usr/bin/perl

   use App::Munchies::Programs::Misc;

   my $prog = App::Munchies::Programs::Misc->new( appclass => q(App::Munchies) );

   exit $prog->dispatch;

=head1 Description

=head1 Subroutines/Methods

=head2 new

=head2 archive

=head2 file_ref

=head2 house_keeping

=head2 __match_dot_files

=head2 pod2html

=head2 purge_tree

=head2 rotate_logs

=head2 tape_backup

=head2 unarchive

=head2 wait_for

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::Programs>

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
