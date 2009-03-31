package App::Munchies::Model::MealMaster;

# @(#)$Id: MealMaster.pm 624 2009-03-31 00:15:12Z pjf $

use strict;
use warnings;
use parent qw(CatalystX::Usul::Model);
use Class::C3;
use English qw(-no_match_vars);
use MealMaster;
use Template::Stash;

use App::Munchies::Model::Catalog;
use App::Munchies::Model::MealMaster::KinoSearch;

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 624 $ =~ /\d+/gmx );

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
     search_model       => q(App::Munchies::Model::MealMaster::KinoSearch),
     writeTT            => q(mealMaster.tt) );

__PACKAGE__->mk_accessors( qw(alpha_cat_offset app binsdir
                              catalog_model catalog_schema database
                              dir file files flds found ingredients
                              ingredients_fields invindex labels
                              readTT recipes search_model writeTT) );

my $SEP = q(/);

sub new {
   my ($self, $app, @rest) = @_;

   my $new    = $self->next::method( $app, @rest );
   my $config = $app->config || {};

   $new->app(      $app );
   $new->binsdir(  $config->{binsdir} );
   $new->dir(      $new->catdir( $config->{root}, $new->dir ) );
   $new->invindex( $new->catfile( $new->dir, $new->invindex ) );

   $Template::Stash::SCALAR_OPS->{sprintf} = sub {
      my ($val, $format) = @_; return sprintf $format, $val;
   };

   return $new;
}

sub browse {
   my ($self, $id, $url) = @_; my ($base, $e, $file, $pos, $title);

   my $s = $self->context->stash;

   $self->clear_form; $s->{menus}->[0]->{selected} = 1;

   unshift @{ $s->{menus}->[1]->{items} }, {
      content => { class     => q(menuSelectedFade),
                   container => 0,
                   href      => $s->{form}->{action}.$SEP.$id,
                   text      => 'Browse',
                   tip       => $url,
                   type      => q(anchor),
                   widget    => 1 } };

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
      $self->throw( error => q(eNoRecipeDir), arg1 => $self->dir );
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
                     url => $url, info => q() };

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
            $self->throw( 'Failed to create node' );
         }

         for $cat (@{ $recipe->categories }) {
            $cat =~ s{ [^a-zA-Z0-9 \/] }{}gmsx;
            $cat =~ s{ [/] }{ }gmsx;
            $cat =~ s{ \s+ }{ }gmsx;
            $cat =~ s{ \A \s+ }{}msx;
            $cat =~ s{ \s+ \z }{}msx;
            $cat = join q( ), map { ucfirst $_ } split q( ), lc $cat;
            $cat = $replace->{ $cat } if (exists $replace->{ $cat });
            $cat = q()                if (exists $suppress->{ $cat });

            next unless ($cat);

            unless ($gid = $cats{ $cat }) {
               $ref = { text => $cat };

               unless (($res = $names->create( $ref )) && ($gid = $res->id)) {
                  $self->throw( 'Failed to create name' );
               }

               $cats{ $cat } = $gid;
               $ref = { gid => $cid, nid => $gid, lid => 1 };

               unless ($nodes->create( $ref )) {
                  $self->throw( 'Failed to create node' );
               }
            }

            $ref = { gid => $gid, nid => 1, lid => $lid };

            unless ($nodes->create( $ref )) {
               $self->throw( 'Failed to create node' );
            }
         }

         $cnt++;
      }

      $out   .= 'Cataloged '.$cnt.' duplicates '.$dup.' from ';
      $out   .= $self->basename( $path )."\n";
      $total += $cnt;
   }

   $out .= 'Total '.$total.' cataloged';
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
   my ($self, $file, $attrs) = @_; my ($cmd, $e, $mode, $path, $text, $tmplt);

   $self->throw( q(eNoRecipeFile) ) unless ($file);

   $path = $self->catfile( $self->dir, $file.'.mmf' );

   $self->throw( $Template::ERROR ) unless ($tmplt = Template->new( $self ));

   unless ($tmplt->process( $self->writeTT, $attrs, \$text )) {
      $self->throw( $tmplt->error() );
   }

   $self->lock->set( k => $path );
   $mode = -f $path ? q(a) : q(w);

   eval { $self->io( $path, $mode )->print( $text ) };

   if ($e = $self->catch) {
      $self->lock->reset( k => $path ); $self->throw( $e );
   }

   $self->lock->reset( k => $path );
   return ($mode eq q(a) ? 'Appended to ' : 'Wrote ').$path;
}

sub create_or_update {
   my $self = shift;
   my ($attrs, $categories, $file, @flds, $i, $name, $nrows, $res, $title);

   unless ($name = $self->query_value( q(recipe) )) {
      $self->throw( q(eNoRecipeName) );
   }

   unless ($file = $self->query_value( q(file) )) {
      $self->throw( q(eNoRecipeFile) );
   }

   unless ($title = $self->query_value( q(title) )) {
      $self->throw( q(eNoRecipeTitle) );
   }

   @flds  = qw(title yield directions);
   $attrs = { categories => [], ingredients => [] };

   for (@flds) { $attrs->{ $_ } = $self->query_value( $_ ) }

   $attrs->{categories} = $self->query_array( q(categories) );

   $self->throw( q(eNoCategories) ) unless ($attrs->{categories}->[0]);

   if ($nrows = $self->query_value( q(ingredients_nrows) )) {
      for $i (0 .. $nrows - 1) {
         push @{ $attrs->{ingredients} },
           { measure  => $self->query_value( q(ingredients_measure).$i ),
             product  => $self->query_value( q(ingredients_product).$i ),
             quantity => $self->query_value( q(ingredients_quantity).$i )
             };
      }
   }

   $attrs = $self->check_form( $attrs );
   $res   = $self->retrieve(   $file, $self->make_key( $title ) );

   if (!$res->found) {
      $self->add_result( $self->create( $file, $attrs ) );
   }
   else { $self->add_result( $self->update( $file, $attrs ) ) }

   return $name;
}

sub delete {
   my $self = shift;
   my ($e, $file, $found, $key, $mm, $path, $recipe, @recipes);
   my ($ref, $text, $tmplt, $wtr);

   unless ($file = $self->query_value( q(file) )) {
      $self->throw( q(eNoRecipeFile) );
   }

   unless ($recipe = $self->query_value( q(recipe) )) {
      $self->throw( q(eNoRecipeName) );
   }

   $path = $self->catfile( $self->dir, $file.'.mmf' );
   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => q(eNotFound), arg1 => $path );
   }

   $mm      = MealMaster->new();
   @recipes = $mm->parse( $path );
   $wtr     = $self->io( $path )->atomic;

   eval {
      for $ref (@recipes) {
         $key  = $self->make_key( $ref->{title} );
         $text = q();

         if ($key eq $recipe && !$found) { $found = 1 }
         else {
            if ($tmplt = Template->new( $self )) {
               if ($tmplt->process( $self->writeTT, $ref, \$text )) {
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
      $self->throw( error => q(eNoRecipeFound),
                    arg1  => $recipe, arg2 => $path );
   }

   $self->add_result_msg( q(recipeDeleted), $recipe, $path );
   return;
}

sub index {
   my $self = shift; my ($args, $cmd, $file);

   unless ($file = $self->query_value( q(file) )) {
      $self->throw( q(eNoRecipeFile) );
   }

   $cmd  = $self->catfile( $self->binsdir, $self->prefix.q(_schema) );
   $cmd .= ' -n -c catalog_mmf -- '.$self->catfile( $self->dir, $file.'.mmf' );
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
   my $files   = $data->files;   unshift @{ $files   }, q(), $s->{newtag};
   my $recipes = $data->recipes; unshift @{ $recipes }, q(), $s->{newtag};
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
         my $name = $self->query_value( q(name) ) || q();

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

   if ($recipe eq $s->{newtag}) {
      $self->add_buttons( qw(Insert Index) );
   }
   else { $self->add_buttons( qw(Save Delete Index) ) }

   return;
}

sub render {
   my ($self, $items, $file, $recipe) = @_;
   my ($key, $mm, $path, @recipes, $ref, $text, $tmplt);

   $recipe
      = $recipe =~ m{ \A recipe= }msx ? (split m{ = }msx, $recipe)[1] : q();
   $path = $self->catfile( $self->dir, $file );
   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => q(eNotFound), arg1 => $path );
   }

   $mm = MealMaster->new();
   @recipes = $mm->parse( $path );
   $self->lock->reset( k => $path );

   for $ref (@recipes) {
      $key  = $self->make_key( $ref->{title} );
      $text = q();

      if (!$recipe || $recipe eq $key) {
         if ($tmplt = Template->new( $self )) {
            unless ($tmplt->process( $self->readTT, $ref, \$text )) {
               $text = $tmplt->error();
            }
         }
         else { $text = $Template::ERROR }

         push @{ $items }, { content => $text };

         return if ($recipe);
      }
   }

   if ($recipe) {
      $self->throw( error => q(eNoRecipeFound),
                    arg1  => $recipe, arg2 => $file );
   }

   return;
}

sub retrieve {
   my ($self, $file, $recipe) = @_;
   my ($data, $key, $mm, $new, $path, @recipes, $ref, $s);

   $s   = $self->context->stash;
   $new = bless { files       => [],
                  flds        => {},
                  found       => 0,
                  ingredients => { %{ $self->config->{ingredients_fields} } },
                  labels      => {},
                  recipes     => [] }, ref $self;

   $self->throw( q(eNoDirectory) ) unless ($self->dir);

   @{ $new->files } = sort { lc $a cmp lc $b        }
                      map  { s{ \.mmf \z }{}msx; $_ }
                      grep { m{ \.mmf \z }msx       }
                      $self->io( $self->dir )->read_dir;

   return $new if (!$file || $file eq $s->{newtag});

   $path = $self->catfile( $self->dir, $file.'.mmf' );
   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => q(eNotFound), arg1 => $path );
   }

   $mm      = MealMaster->new();
   @recipes = $mm->parse( $path );
   $self->lock->reset( k => $path );

   for $ref (@recipes) {
      $key = $self->make_key( $ref->{title} );
      push @{ $new->recipes }, $key;
      ($new->labels->{ $key } = substr $key, 0, 40) =~ s{_}{ }gmsx;

      if ($recipe && $recipe eq $key) {
         push @{ $new->ingredients->{values} }, @{ $ref->{ingredients} };

         $new->flds( $ref ); $new->found( 1 );
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
   my ($self, $file, $attrs) = @_;
   my ($e, $key, $mm, $path, $recipe, @recipes, $ref, $text, $tmplt, $wtr);

   $self->throw( q(eNoRecipeFile) ) unless ($file);
   $self->throw( q(eNoRecipeName) ) unless ($attrs->{title});

   $path   = $self->catfile( $self->dir, $file.'.mmf' );
   $recipe = $self->make_key ( $attrs->{title} );
   $self->lock->set( k => $path );

   unless (-f $path) {
      $self->lock->reset( k => $path );
      $self->throw( error => q(eNotFound), arg1 => $path );
   }

   $mm      = MealMaster->new();
   @recipes = $mm->parse( $path );
   $wtr     = $self->io( $path );

   eval {
      for $ref (@recipes) {
         $key  = $self->make_key( $ref->{title} );
         $text = q();

         if ($tmplt = Template->new( $self )) {
            if ($key eq $recipe) {
               unless ($tmplt->process( $self->writeTT, $attrs, \$text )) {
                  $self->throw( $tmplt->error() );
               }
            }
            else {
               unless ($tmplt->process( $self->writeTT, $ref, \$text )) {
                  $self->throw( $tmplt->error() );
               }
            }

            $wtr->print( $text );
         }
         else { $self->throw( $Template::ERROR ) }
      }
   };

   if ($e = $self->catch) {
      $self->lock->reset( k => $path ); $self->throw( $e );
   }

   $wtr->close;
   $self->lock->reset( k => $path );
   return $self->loc( 'Updated [_1] in [_2]', $attrs->{title}, $path );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::MealMaster - Manipulate food recipes stored in MMF format

=head1 Version

0.1.$Revision: 624 $

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
