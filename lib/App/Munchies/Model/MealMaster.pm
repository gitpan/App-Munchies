# @(#)$Id: MealMaster.pm 754 2009-06-09 23:50:51Z pjf $

package App::Munchies::Model::MealMaster;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 754 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Model);

use App::Munchies::Model::Catalog;
use App::Munchies::MealMaster::KinoSearch;
use Class::C3;
use English qw(-no_match_vars);
use MealMaster;
use Template::Stash;

my $NUL = q();
my $SEP = q(/);

__PACKAGE__->config
   ( alpha_cat_offset   => 7,
     catalog_model      => q(App::Munchies::Model::Catalog),
     dir                => q(recipes),
     ingredients_fields => {
        align           => { quantity => q(right) },
        flds            => [ qw(quantity measure product) ],
        labels          => { measure  => 'Measure', product  => 'Product',
                             quantity => 'Quantity' },
        maxlengths      => { measure  => 2, product => 29, quantity => 7 },
        sizes           => { measure  => 2, product => 29, quantity => 7 },
        widths          => { measure  => '1%', quantity => '1%' } },
     INTERPOLATE        => 0,
     invindex           => q(index),
     readTT             => q(recipe.tt),
     search_model       => q(App::Munchies::MealMaster::KinoSearch),
     writeTT            => q(mealMaster.tt) );

__PACKAGE__->mk_accessors( qw(alpha_cat_offset app binsdir
                              catalog_model catalog_schema database
                              dir file files flds found ingredients
                              ingredients_fields invindex labels
                              readTT recipes search_model writeTT) );

sub new {
   my ($self, $app, @rest) = @_;

   my $new      = $self->next::method( $app, @rest );
   my $app_conf = $app->config || {};

   $new->app     ( $app                                          );
   $new->binsdir ( $app_conf->{binsdir}                          );
   $new->dir     ( $new->catdir ( $app_conf->{root}, $new->dir ) );
   $new->invindex( $new->catfile( $new->dir, $new->invindex    ) );

   $Template::Stash::SCALAR_OPS->{sprintf} = sub {
      my ($val, $format) = @_; return sprintf $format, $val;
   };

   return $new;
}

sub browse {
   my ($self, $id, $url) = @_; my ($base, $e, $file, $pos, $title);

   my $c = $self->context; my $s = $c->stash;

   $self->clear_form;

   $c->model( q(Navigation) )->select_this( 0, 1, {
      href => $s->{form}->{action}.$SEP.$id,
      text => $self->loc( 'Browse' ),
      tip  => $url } );

   ($file, $pos) = split m{ \? }mx, $url, 2;
   $file         = $self->basename( $file );
   ($base        = $file) =~ s{ \.mmf \z }{}mx;
   $self->add_field(  { class => q(libraryFade),
                        href  => $s->{url}.q(recipes).$SEP.$base.q(?).$pos,
                        text  => $self->loc( q(Edit Recipe) ),
                        type  => q(anchor) } );

   eval { $self->render( $s->{sdata}->{items}, $file, $pos ) };

   return $self->add_error( $e ) if ($e = $self->catch);

   $pos =~ m{ \A recipe=(.*) }mx; $title = $1 || $pos; $title =~ s{ _ }{ }gmx;
   $s->{title} = $title;
   return;
}

sub catalog_mmf {
   my ($self, @args) = @_;
   my ($cat, %cats, $cid, $cnt, $digest, $dup, $file, $gid);
   my ($indexer, $ingredients, $key, $lid, $link, $links, $model);
   my ($name, $names, $nodes, $out, $path, @paths, $recipe, @recipes);
   my ($ref, $replace, $res, $rs1, $rs2, $suppress);
   my ($text, $title, $total, $url, $val);

   %cats = (); $cid = 5; @paths = (); $replace = {}; $suppress = {};

   unless (-d $self->dir) {
      $self->throw( error => 'Directory [_1] not found',
                    args  => [ $self->dir ] );
   }

   if ($args[0]) { push @paths, @args }
   else {
      @paths = map  { $self->catdir( $self->dir, $_ ) }
               grep { m{ \.mmf \z }msx } $self->io( $self->dir )->read_dir;
   }

   $path = $self->catfile( $self->dir, 'replace' );

   for $text ($self->io( $path )->chomp->getlines) {
      if ($text) {
         ($key, $val) = split m{ = }xms, $text;
         $key =~ s{ \A \s+ }{}msx; $key =~ s{ \s+ \z }{}msx;
         $val =~ s{ \A \s+ }{}msx; $val =~ s{ \s+ \z }{}msx;
         $replace->{ $key } = $val;
      }
   }

   $path = $self->catfile( $self->dir, 'suppress' );

   for $val ($self->io( $path )->chomp->getlines) {
      $suppress->{ $val } = 1 if ($val);
   }

   $indexer = $self->search_model->new( $self->invindex );
   $model   = $self->catalog_model->new
      ( $self->app, { database     => $self->database,
                      schema_class => $self->catalog_schema } );
   $names   = $model->resultset( q(Names) );
   $links   = $model->resultset( q(Links) );
   $nodes   = $model->resultset( q(Nodes) );
   $total   = 0;

   $cats{ $_->text } = $_->id for ($names->search());

   for $path (sort @paths) {
      $cnt     = 0; $dup = 0;
      @recipes = MealMaster->new()->parse( $path );
      $url     = $self->basename( $path ).q(\?%);
      $rs1     = $links->search( { url => { like => $url } } );

      while ($link = $rs1->next) {
         $rs2 = $nodes->search({ lid => $link->id });

         while ($_ = $rs2->next) { $_->delete }

         $link->delete;
      }

      for $recipe (@recipes) {
         next unless ($recipe->title && $recipe->directions);

         $title  = $key = $self->make_key( $recipe->title );
         ($text  = substr $recipe->directions, 0, 100) =~ s{ [ ] }{}gmsx;
         $digest = $self->create_token( $key.$text );
         $key    =~ s{ [ ] }{_}gmsx;
         $url    = $self->basename( $path ).q(?recipe=).$key;
         $ingredients
                 = join q( ), map { $_->product } @{ $recipe->ingredients };
         $ref    = { nid => $cid, name => $digest, text => $title,
                     url => $url, info => $NUL };

         unless (($res = eval { $links->create($ref) }) && ($lid = $res->id)) {
            $dup++; next;
         }

         $indexer->add_doc( { title       => $recipe->title,
                              ingredients => $ingredients,
                              url         => q(browse).$SEP.$lid,
                              file        => $self->basename( $path ),
                              key         => $key } );

         ($text = $title) =~ s{ \A \d+ }{}msx;
         # TODO: Make this less crap
         $gid   = (ord substr $text, 0, 1) - 65 + $self->alpha_cat_offset;
         $ref   = { gid => $gid, nid => 1, lid => $lid };

         unless ($nodes->create( $ref )){
            $self->throw( 'Failed to create node object' );
         }

         for $cat (@{ $recipe->categories }) {
            $cat =~ s{ [^a-zA-Z0-9 \/] }{}gmsx;
            $cat =~ s{ [/] }{ }gmsx;
            $cat =~ s{ \s+ }{ }gmsx;
            $cat =~ s{ \A \s+ }{}msx;
            $cat =~ s{ \s+ \z }{}msx;
            $cat = join q( ), map { ucfirst $_ } split q( ), lc $cat;
            $cat = $replace->{ $cat } if (exists $replace->{ $cat });
            $cat = $NUL               if (exists $suppress->{ $cat });

            next unless ($cat);

            unless ($gid = $cats{ $cat }) {
               $ref = { text => $cat };

               unless (($res = $names->create( $ref )) && ($gid = $res->id)) {
                  $self->throw( 'Failed to create name object' );
               }

               $cats{ $cat } = $gid;
               $ref = { gid => $cid, nid => $gid, lid => 1 };

               unless ($nodes->create( $ref )) {
                  $self->throw( 'Failed to create node object' );
               }
            }

            $ref = { gid => $gid, nid => 1, lid => $lid };

            unless ($nodes->create( $ref )) {
               $self->throw( 'Failed to create node object' );
            }
         }

         $cnt++;
      }

      $out   .= "Cataloged $cnt duplicates $dup from ";
      $out   .= $self->basename( $path )."\n";
      $total += $cnt;
   }

   $out .= "Total $total cataloged";
   $indexer->finish( optimize => 1 );
   return $out;
}

sub conversion {
   my $self = shift;

   $self->stash_form( $self->loc( q(conversion) ) );
   $self->stash_meta( { id => q(conversion) } );
   delete $self->context->stash->{token};
   return;
}

sub create {
   my ($self, $file, $attrs) = @_; my ($e, $text, $tmplt);

   $self->throw( 'No file path specified' ) unless ($file);

   my $path = $self->_get_recipe_path( $file );

   $self->throw( $Template::ERROR ) unless ($tmplt = Template->new( $self ));

   unless ($tmplt->process( $self->writeTT, $attrs, \$text )) {
      $self->throw( $tmplt->error() );
   }

   $self->lock->set( k => $path );

   my $mode = -f $path ? q(a) : q(w);

   eval { $self->io( $path, $mode )->print( $text ) };

   if ($e = $self->catch) {
      $self->lock->reset( k => $path ); $self->throw( $e );
   }

   $self->lock->reset( k => $path );
   return ($mode eq q(a) ? 'Appended to ' : 'Wrote ').$path;
}

sub create_or_update {
   my $self = shift; my ($file, $name, $nrows, $res, $title);

   unless ($name = $self->query_value( q(recipe) )) {
      $self->throw( 'No recipe name specified' );
   }

   unless ($file = $self->query_value( q(file) )) {
      $self->throw( 'No file path specified' );
   }

   unless ($title = $self->query_value( q(title) )) {
      $self->throw( 'No recipe title specified' );
   }

   my @flds  = qw(title yield directions);
   my $attrs = { categories => [], ingredients => [] };

   for (@flds) { $attrs->{ $_ } = $self->query_value( $_ ) }

   $attrs->{categories} = $self->query_array( q(categories) );

   unless ($attrs->{categories}->[0]) {
      $self->throw( error => 'Recipe [_1] has no categories',
                    args  => [ $name ] );
   }

   if ($nrows = $self->query_value( q(ingredients_nrows) )) {
      for my $i (0 .. $nrows - 1) {
         push @{ $attrs->{ingredients} },
           { measure  => $self->query_value( q(ingredients_measure).$i ),
             product  => $self->query_value( q(ingredients_product).$i ),
             quantity => $self->query_value( q(ingredients_quantity).$i )
             };
      }
   }

   $attrs = $self->check_form( $attrs );
   $res   = $self->retrieve(   $file, $self->make_key( $title ) );

   unless ($res->found) { $self->add_result( $self->create( $file, $attrs ) ) }
   else { $self->add_result( $self->update( $file, $attrs ) ) }

   return $name;
}

sub delete {
   my $self = shift; my ($e, $file, $found, $unwanted, $tmplt);

   unless ($file = $self->query_value( q(file) )) {
      $self->throw( 'No file path specified' );
   }

   unless ($unwanted = $self->query_value( q(recipe) )) {
      $self->throw( 'No recipe name specified' );
   }

   my $path = $self->_get_recipe_path( $file );

   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => 'File [_1] not found', args => [ $path ] );
   }

   my $mm  = MealMaster->new(); my @recipes = $mm->parse( $path );

   my $wtr = $self->io( $path )->atomic;

   eval {
      for my $recipe (@recipes) {
         my $key = $self->make_key( $recipe->{title} ); my $text = $NUL;

         if (not $found and $key eq $unwanted) { $found = 1 }
         else {
            if ($tmplt = Template->new( $self )) {
               if ($tmplt->process( $self->writeTT, $recipe, \$text )) {
                  $wtr->print( $text );
               }
               else { $self->throw( $tmplt->error() ) }
            }
            else { $self->throw( $Template::ERROR ) }
         }
      }
   };

   if ($e = $self->catch) {
      $self->lock->reset( k => $path ); $self->throw( $e );
   }

   $wtr->close(); $self->lock->reset( k => $path );

   unless ($found) {
      $self->throw( error => 'File [_1] recipe [_2] unknown',
                    args  => [ $path, $unwanted ] );
   }

   $self->add_result_msg( q(recipeDeleted), $unwanted, $path );
   return;
}

sub index {
   my $self = shift; my ($args, $cmd, $file);

   unless ($file = $self->query_value( q(file) )) {
      $self->throw( 'No file path specified' );
   }

   $cmd  = $self->catfile( $self->binsdir, $self->prefix.q(_schema) );
   $cmd .= ' -n -c catalog_mmf -- '.$self->_get_recipe_path( $file );
   $args = { debug => $self->debug, err => q(out) };
   $self->add_result( $self->run_cmd( $cmd, $args )->out );
   return;
}

sub make_key {
   my ($self, $title) = @_; my $key;

   $key = $title;
   $key =~ s{ [^a-zA-Z0-9 ] }{}gmsx;
   $key =~ s{ \s+ }{ }gmsx;
   $key =~ s{ \A \s+ }{}msx;
   $key =~ s{ \s+ \z }{}msx;
   $key = join q(_), map { ucfirst $_ } split q( ), lc $key;
   return $key;
}

sub recipes_view_form {
   my ($self, $file, $recipe) = @_;

   my $data    = eval { $self->retrieve( $file, $recipe ) }; my $e;

   return $self->add_error( $e ) if ($e = $self->catch);

   my $s       = $self->context->stash;
   my $files   = $data->files;   unshift @{ $files   }, $NUL, $s->{newtag};
   my $recipes = $data->recipes; unshift @{ $recipes }, $NUL, $s->{newtag};
   my $fields  = $data->flds;
   my $form    = $s->{form}->{name};
   my $id      = $form.q(.file);
   my $nitems  = 0;
   my $step    = 1;

   $s->{pwidth} -= 12;
   $self->clear_form( { firstfld => $id } );
   $self->add_field(  { default  => $file,
                        id       => $id,
                        values   => $files } ); $nitems++;

   if ($file) {
      if ($file eq $s->{newtag}) {
         my $name = $self->query_value( q(name) ) || $NUL;

         $self->add_field( { default => $name, id => $form.q(.name) } );
         $nitems++;
      }
      else { $self->add_hidden( q(name), $file ) }

      $self->add_field( { default => $recipe,
                          id      => $form.q(.recipe),
                          labels  => $data->labels,
                          values  => $recipes } ); $nitems++;
   }

   $self->group_fields( { id => $form.q(.select), nitems => $nitems } );

   return unless ($recipe && $self->is_member( $recipe, @{ $recipes } ));

   $self->add_field(    { default => $fields->{title},
                          id      => $form.q(.title),
                          stepno  => $step++ } );
   $self->add_field(    { id      => $form.q(.categories),
                          stepno  => $step++,
                          values  => $fields->{categories} } );
   $self->add_field(    { default => $fields->{yield},
                          id      => $form.q(.yield),
                          stepno  => $step++ } );
   $self->add_field(    { data    => $data->ingredients,
                          id      => $form.q(.ingredients),
                          stepno  => $step++ } );
   $self->add_field(    { default => $fields->{directions},
                          id      => $form.q(.directions),
                          stepno  => $step++ } );
   $self->group_fields( { id      => $form.q(.edit), nitems => 5 } );

   if ($recipe eq $s->{newtag}) { $self->add_buttons( qw(Insert Index) ) }
   else { $self->add_buttons( qw(Save Delete Index) ) }

   return;
}

sub render {
   my ($self, $items, $file, $wanted) = @_; my $tmplt;

   my $path = $self->catfile( $self->dir, $file );

   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => 'File [_1] not found', args => [ $path ] );
   }

   my $mm = MealMaster->new(); my @recipes = $mm->parse( $path );

   $self->lock->reset( k => $path );

   $wanted = $wanted =~ m{ \A recipe= }msx
           ? (split m{ = }msx, $wanted)[1] : $NUL;

   for my $recipe (@recipes) {
      my $key = $self->make_key( $recipe->{title} ); my $text = $NUL;

      if (not $wanted or $key eq $wanted) {
         if ($tmplt = Template->new( $self )) {
            unless ($tmplt->process( $self->readTT, $recipe, \$text )) {
               $text = $tmplt->error();
            }
         }
         else { $text = $Template::ERROR }

         push @{ $items }, { class => q(clearLeft), content => $text };

         return if ($wanted);
      }
   }

   if ($wanted) {
      $self->throw( error => 'File [_1] recipe [_2] unknown',
                    args  => [ $file, $wanted ] );
   }

   return;
}

sub retrieve {
   my ($self, $file, $wanted) = @_;

   my $s      = $self->context->stash;
   my $path   = $self->_get_recipe_path( $file );
   my %fields = %{ $self->config->{ingredients_fields} };
   my $new    = bless { files       => [],
                        flds        => {},
                        found       => 0,
                        ingredients => { %fields },
                        labels      => {},
                        recipes     => [] }, ref $self;

   @{ $new->files } = sort { lc $a cmp lc $b        }
                      map  { s{ \.mmf \z }{}msx; $_ }
                      grep { m{ \.mmf \z }msx       }
                      $self->io( $self->dir )->read_dir;

   return $new if (not $file or $file eq $s->{newtag});

   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => 'File [_1] not found', args => [ $path ] );
   }

   my $mm = MealMaster->new(); my @recipes = $mm->parse( $path );

   $self->lock->reset( k => $path );

   for my $recipe (@recipes) {
      my $key = $self->make_key( $recipe->{title} );

      push @{ $new->recipes }, $key;
      ($new->labels->{ $key } = substr $key, 0, 40) =~ s{_}{ }gmsx;

      if ($wanted and $key eq $wanted) {
         push @{ $new->ingredients->{values} }, @{ $recipe->{ingredients} };

         $new->flds( $recipe ); $new->found( 1 );
      }
   }

   @{ $new->recipes } = sort { lc $a cmp lc $b } @{ $new->recipes };

   return $new;
}

sub search_for {
   my ($self, @rest) = @_;

   my $args = { highlight_field => q(ingredients),
                invindex        => $self->invindex,
                sort_field      => q(title) };

   return $self->search_model->search_for( $args, @rest );
}

sub update {
   my ($self, $file, $attrs) = @_; my ($e, $tmplt);

   $self->throw( 'No file path specified'    ) unless ($file);
   $self->throw( 'No recipe title specified' ) unless ($attrs->{title});

   my $path = $self->catfile( $self->dir, $file.q(.mmf) );

   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => 'File [_1] not found', args => [ $path ] );
   }

   my $mm      = MealMaster->new();
   my @recipes = $mm->parse( $path );
   my $wtr     = $self->io( $path )->atomic;
   my $wanted  = $self->make_key( $attrs->{title} );

   eval {
      for my $recipe (@recipes) {
         my $key = $self->make_key( $recipe->{title} ); my $text = $NUL;

         unless ($tmplt = Template->new( $self )) {
            $self->throw( $Template::ERROR );
         }

         if ($key eq $wanted) {
            unless ($tmplt->process( $self->writeTT, $attrs, \$text )) {
               $self->throw( $tmplt->error() );
            }
         }
         else {
            unless ($tmplt->process( $self->writeTT, $recipe, \$text )) {
               $self->throw( $tmplt->error() );
            }
         }

         $wtr->print( $text );
      }
   };

   if ($e = $self->catch) {
      $self->lock->reset( k => $path ); $self->throw( $e );
   }

   $wtr->close;
   $self->lock->reset( k => $path );
   return $self->loc( 'Updated [_1] in [_2]', $attrs->{title}, $path );
}

# Private methods

sub _get_recipe_path {
   my ($self, $file) = @_; my $dir = $self->dir; $file ||= q(default);

   unless ($dir and -d $dir) {
      $self->throw( error => 'Directory [_1] not found', args => [ $dir ] );
   }

   return $self->catfile( $dir, $file.q(.mmf) );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::MealMaster - Manipulate food recipes stored in MMF format

=head1 Version

0.3.$Revision: 754 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 browse

=head2 catalog_mmf

=head2 conversion

=head2 create

=head2 create_or_update

=head2 delete

=head2 index

=head2 make_key

=head2 new

=head2 recipes_view_form

=head2 render

=head2 retrieve

=head2 search_for

=head2 update

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
