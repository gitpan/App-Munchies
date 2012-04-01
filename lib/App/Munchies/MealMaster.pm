# @(#)$Id: MealMaster.pm 1288 2012-03-29 00:20:38Z pjf $

package App::Munchies::MealMaster;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1288 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul);

use App::Munchies::Model::Catalog;
use App::Munchies::MealMaster::KinoSearch;
use CatalystX::Usul::Constants;
use CatalystX::Usul::Functions qw(create_token throw trim);
use English qw(-no_match_vars);
use File::MealMaster;
use MRO::Compat;
use TryCatch;
use Scalar::Util qw(blessed);

__PACKAGE__->mk_accessors( qw(alpha_offset app binsdir catalog_class
                              catalog_schema database datadir
                              files flds found ingredients
                              ingredients_fields indexdir labels
                              meal_master recipes search_class
                              subject_offset) );

sub new {
   my ($class, $app, $attrs) = @_;

   $attrs->{alpha_offset      } ||= 7;
   $attrs->{binsdir           } ||= $app->config->{binsdir};
   $attrs->{catalog_class     } ||= q(App::Munchies::Model::Catalog);
   $attrs->{ingredients_fields} ||= {
      align      => { quantity => q(right) },
      flds       => [ qw(quantity measure product) ],
      hclass     => { measure  => q(minimal), quantity => q(minimal), },
      labels     => { measure  => 'Measure',
                      product  => 'Product',
                      quantity => 'Quantity' },
      maxlengths => { measure  => 2, product => 29, quantity => 7 },
      sizes      => { measure  => 2, product => 29, quantity => 7 }, };
   $attrs->{search_class      } ||= q(App::Munchies::MealMaster::KinoSearch);
   $attrs->{subject_offset    } ||= 5;

   $attrs->{app     } ||= $app;
   $attrs->{datadir } ||= $class->catdir ( $attrs->{rootdir}, q(recipes) );
   $attrs->{indexdir} ||= $class->catfile( $attrs->{datadir}, q(index)   );

   my $new = $class->next::method( $app, $attrs );

   $attrs = { ioc_obj => $new, template_dir => $attrs->{template_dir} };
   $new->meal_master( File::MealMaster->new( $attrs ) );

   return $new;
}

sub catalog_mmf {
   my ($self, @args) = @_; my $class = $self->search_class; my $indexer;

   try        { $indexer = $class->new( $self->indexdir ) }
   catch ($e) { throw $e }

   defined $indexer or throw "Class $class new returned undefined";

   my $cfg     = $self->_catalog_entry_config( $indexer );
   my $mm      = $self->meal_master;
   my $n_files = 0;
   my $total   = 0;
   my $out;

   for my $path (@{ $self->_read_recipe_paths( @args ) }) {
      my $cnt = 0; my $dup = 0; my $file = $path->filename; $mm->path( $path );

      $self->_catalog_entry_delete( $cfg, $file );

      for my $recipe ($mm->resultset->search->all) {
         next unless ($recipe->title and $recipe->directions);

         $self->_catalog_entry_create( $cfg, $file, $recipe, \$dup );
         $cnt++;
      }

      $out   .= "Cataloged $cnt duplicates $dup from $file\n";
      $total += ($cnt - $dup); $n_files++;
   }

   $out .= "Total $total cataloged from $n_files files";
   $indexer->commit;
   return $out;
}

sub create {
   my ($self, $file, $attrs) = @_;

   my $title = $attrs->{title} or throw 'Recipe title not specified';
   my $mm    = $self->meal_master;
   my $path  = $mm->path( $self->get_recipe_io( $file ) );

   $attrs->{name} = $mm->make_key( $title ); $mm->resultset->create( $attrs );

   return $path;
}

sub delete {
   my ($self, $file, $unwanted) = @_; my $mm = $self->meal_master;

   my $path = $mm->path( $self->get_recipe_io( $file ) );

   $mm->resultset->delete( { name => $unwanted } );

   return $path;
}

sub extension {
   return shift->meal_master->source->storage->extn;
}

sub get_recipe_io {
   my ($self, $path) = @_; my $extn = $self->extension;

   $path or throw 'Recipe file pathname not specified';

   unless ($self->io( $path )->is_absolute) {
      my $dir = $self->datadir || NUL;

      -d $dir or throw error => 'Directory [_1] not found', args => [ $dir ];

      $path = $self->catfile( $dir, $path );
   }

   $path !~ m{ \. [a-z0-9]+ \z }imx and $path .= $extn;

   return $self->io( $path );
}

sub index {
   my ($self, $path) = @_;

   $path and
      return $self->catalog_mmf( $self->get_recipe_io( $path )->pathname );

   my $cmd  = $self->catfile( $self->binsdir, $self->prefix.q(_schema) );
      $cmd .= ($self->debug ? ' -D' : ' -n').q( -c catalog_mmf);
   my $args = { async => TRUE,   debug => $self->debug,
                err   => q(out), out   => $self->tempname };

   return $self->run_cmd( $cmd, $args )->out;
}

sub render {
   my ($self, $items, $file, $wanted) = @_;

   my $mm = $self->meal_master; my $rs = $mm->resultset;

   $mm->path( $self->get_recipe_io( $file ) );

   for my $recipe ($wanted ? $rs->find( { name => $wanted } )
                           : $rs->search->all) {
      push @{ $items }, { class => q(clearLeft), content => $recipe->render };
      $wanted and return $recipe->title;
   }

   $wanted and throw error => 'File [_1] recipe [_2] unknown',
                     args  => [ $mm->path->pathname, $wanted ];

   return;
}

sub retrieve {
   my ($self, $newtag, $file, $wanted) = @_;

   my $new  = bless { files       => [],
                      flds        => {},
                      found       => FALSE,
                      ingredients => { %{ $self->ingredients_fields } },
                      labels      => {},
                      recipes     => [] }, ref $self;

   @{ $new->files } = map { $_->filename } @{ $self->_read_recipe_paths };

   (not $file or $file eq $newtag) and return $new;

   my $mm = $self->meal_master; $mm->path( $self->get_recipe_io( $file ) );

   my $rs = $mm->resultset; my $extn = $rs->storage->extn;

   for my $recipe ($rs->search->all) {
      my $key = $recipe->name; push @{ $new->recipes }, $key;

      $new->labels->{ $key } = substr $recipe->title, 0, 40;

      if ($wanted and $key eq $wanted) {
         $new->flds( $recipe ); $new->found( TRUE );
         push @{ $new->ingredients->{values} }, @{ $recipe->ingredients };
      }
   }

   @{ $new->recipes } = sort { lc $a cmp lc $b } @{ $new->recipes };

   return $new;
}

sub search_for {
   my ($self, $args) = @_;

   $args->{invindex} = $self->indexdir;

   return $self->search_class->search_for( $args );
}

sub update {
   my ($self, $file, $attrs) = @_;

   my $title = $attrs->{title} or throw 'Recipe title not specified';
   my $mm    = $self->meal_master;
   my $path  = $mm->path( $self->get_recipe_io( $file ) );

   $attrs->{name} = $mm->make_key( $title ); $mm->resultset->update( $attrs );

   return $path;
}

# Private methods

sub _catalog_entry_config {
   my ($self, $indexer) = @_;

   my $model = $self->catalog_class->COMPONENT
      ( $self->app, { database     => $self->database,
                      schema_class => $self->catalog_schema } );

   my %cats  = (); $cats{ $_->text } = $_->id for ($model->names->search);

   return { catalogs => \%cats,
            indexer  => $indexer,
            links    => $model->links,
            names    => $model->names,
            nodes    => $model->nodes,
            replace  => $self->_read_replace_file,
            suppress => $self->_read_suppress_file };
}

sub _catalog_entry_create {
   my ($self, $cfg, $file, $recipe, $dup_ref) = @_; my ($lid, $res);

   my $title  = $recipe->title;
   my $key    = $self->meal_master->make_key( $title );
  (my $text   = substr $recipe->directions, 0, 100) =~ s{ [ ] }{}gmsx;
   my $digest = create_token $key.$text;
   my $sid    = $self->subject_offset;
   my $url    = $key.SEP.$file;
   my $args   = { nid => $sid, name => $digest, text => $title,
                  url => $url, info => NUL };
   my $links  = $cfg->{links};

   unless ($res = eval { $links->create( $args ) } and $lid = $res->id) {
      ${ $dup_ref }++;
      return;
   }

   my $ingredients = join SPC, map { $_->product } @{ $recipe->ingredients };

   $cfg->{indexer}->add_doc( { title       => $title,
                               ingredients => $ingredients,
                               file        => $file,
                               key         => $key } );

   $self->_catalog_entry_create_nodes( $cfg, $recipe->categories, $key, $lid );
   return;
}

sub _catalog_entry_create_nodes {
   my ($self, $cfg, $categories, $key, $lid) = @_;

  (my $text  = $key) =~ s{ \A \d+ }{}msx;
   # TODO: Make this less crap
   my $gid   = (ord substr $text, 0, 1) - 65 + $self->alpha_offset;
   my $sid   = $self->subject_offset;
   my $names = $cfg->{names};
   my $nodes = $cfg->{nodes};
   my $res;

   # Alphabetical catalog
   $nodes->create( { gid => $gid, nid => 1, lid => $lid } )
      or throw 'Failed to create node object';

   for my $cat (grep { length }
                map  { $self->_strangle_cat( $cfg, $_ ) }
                    @{ $categories }) {
      unless ($gid = $cfg->{catalogs}->{ $cat }) {
         my $args = { text => $cat };

         ($res = $names->create( $args ) and $gid = $res->id)
            or throw 'Failed to create name object';

         # Subject category
         $nodes->create( { gid => $sid, nid => $gid, lid => 1 } )
            or throw 'Failed to create node object';
         $cfg->{catalogs}->{ $cat } = $gid;
      }

      # Category catalog
      $nodes->create( { gid => $gid, nid => 1, lid => $lid } )
         or throw 'Failed to create node object';
   }

   return;
}

sub _catalog_entry_delete {
   my ($self, $cfg, $file) = @_;

   my $rs1 = $cfg->{links}->search( { url => { like => q(%).SEP.$file } } );

   while (my $link = $rs1->next) {
      my $rs2 = $cfg->{nodes}->search( { lid => $link->id } );

      $_->delete while ($_ = $rs2->next);

      $link->delete;
   }

   return;
}

sub _read_recipe_paths {
   my ($self, @args) = @_; my $dir = $self->datadir; my @paths = ();

   unless ($args[ 0 ]) {
      my $io = $self->io( $dir ); my $extn = $self->extension;

      $io->is_dir or throw error => 'Directory [_1] not found',
                           args  => [ $dir ];

      @paths = $io->filter( sub { m{ \Q$extn\E \z }msx } )->all_files(1);
   }
   else { push @paths, map { blessed $_ ? $_ : $self->io( $_ ) } @args }

   return \@paths;
}

sub _read_replace_file {
   my $self    = shift;
   my $io      = $self->io( $self->catfile( $self->datadir, q(replace) ) );
   my %replace = ();

   for (grep { length } $io->chomp->getlines) {
      my ($k, $v) = map { trim $_ } split m{ = }msx, $_;

      $replace{ $k } = $v;
   }

   return \%replace;
}

sub _read_suppress_file {
   my $self     = shift;
   my $io       = $self->io( $self->catfile( $self->datadir, q(suppress) ) );
   my %suppress = map  { (trim $_) => TRUE }
                  grep { length } $io->chomp->getlines;

   return \%suppress;
}

sub _strangle_cat {
   my ($self, $args, $cat) = @_;

   $cat =~ s{ [^a-zA-Z0-9 \/] }{}gmsx;
   $cat =~ s{ [/] }{ }gmsx;
   $cat =~ s{ \s+ }{ }gmsx;
   $cat =  join SPC, map { ucfirst $_ } split SPC, lc trim $cat;
   $cat =  $args->{replace}->{ $cat } if (exists $args->{replace }->{ $cat });
   $cat =  NUL                        if (exists $args->{suppress}->{ $cat });

   return $cat;
}

1;

__END__

=pod

=head1 Name

App::Munchies::MealMaster - Domain model for food recipes stored in MMF format

=head1 Version

0.6.$Revision: 1288 $

=head1 Synopsis

   use App::Munchies::MealMaster;

=head1 Description

=head1 Subroutines/Methods

=head2 new

=head2 catalog_mmf

=head2 create

=head2 delete

=head2 extension

=head2 get_recipe_io

=head2 index

=head2 render

=head2 retrieve

=head2 search_for

=head2 update

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<App::Munchies::Model::Catalog>

=item L<App::Munchies::MealMaster::KinoSearch>

=item L<CatalystX::Usul>

=item L<File::MealMaster>

=item L<TryCatch>

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
