# @(#)$Id: MealMaster.pm 1288 2012-03-29 00:20:38Z pjf $

package App::Munchies::Model::MealMaster;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1288 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Model CatalystX::Usul::IPC);

use App::Munchies::MealMaster;
use CatalystX::Usul::Constants;
use CatalystX::Usul::Functions qw(exception is_member throw);
use MRO::Compat;
use TryCatch;

__PACKAGE__->mk_accessors( qw(template_dir) );

sub build_per_context_instance {
   my ($self, $c, $config) = @_;

   my $new   = $self->next::method( $c, $config );
   my $attrs = { %{ $new->domain_attributes || {} } };

   $attrs->{rootdir     } ||= $c->config->{root};
   $attrs->{template_dir} ||= $new->template_dir;

   $new->domain_model( App::Munchies::MealMaster->new( $c, $attrs ) );

   return $new;
}

sub add_search_hit {
   my ($self, $hit, $link_num, $field) = @_;

   my $c    = $self->context;
   my $form = $c->stash->{form}->{name};
   my $href = $c->uri_for_action( $c->action->namespace.SEP.q(recipes_view),
                                  $hit->{key}, $hit->{file} );

   $self->add_field( { href   => $href,
                       id     => $form.q(.title),
                       stepno => $link_num,
                       text   => $hit->{title} } );

   $field ne q(title) and $self->add_field( { id   => $form.q(.excerpt),
                                              text => $hit->{excerpt} } );

   $self->add_field( { id     => $form.q(.score),
                       pwidth => 0,
                       stepno => 0,
                       text   => sprintf '%0.3f', $hit->{score} } );

   $self->add_field( { id     => $form.q(.file),
                       pwidth => 0,
                       text   => $hit->{file} } );

   $self->add_field( { id     => $form.q(.key),
                       pwidth => 0,
                       text   => $hit->{key} } );
   return;
}

sub conversion {
   my $self = shift;

   $self->stash_content( $self->loc( q(conversion) ) );
   $self->stash_meta( { id => q(conversion) } );
   return;
}

sub create_or_update {
   my $self   = shift; my ($msg, $path);
   my $s      = $self->context->stash;
   my $file   = $self->query_value( q(file) )
      or throw 'File path not specified';
   my $recipe = $self->query_value( q(recipe) )
      or throw 'Recipe name not specified';
   my $title  = $self->query_value( q(title) )
      or throw 'Recipe title not specified';
   my @flds   = qw(title yield directions);
   my $attrs  = { categories => [], ingredients => [] };
   my $form   = $s->{form}->{name};

   $attrs->{ $_ } = $self->query_value( $_ ) for (@flds);

   $attrs->{categories} = $self->query_array( q(categories) );
   $attrs->{categories}->[ 0 ]
      or throw error => 'Recipe [_1] has no categories', args => [ $recipe ];

   if (my $nrows = $self->query_value( q(_ingredients_nrows) )) {
      for my $i (0 .. $nrows - 1) {
         push @{ $attrs->{ingredients} },
            { measure  => $self->query_value( q(ingredients_).$i.q(_1) ),
              product  => $self->query_value( q(ingredients_).$i.q(_2) ),
              quantity => $self->query_value( q(ingredients_).$i.q(_0) ) };
      }
   }

   $attrs = $self->check_form( $attrs );

   my $res = $self->domain_model->retrieve( $s->{newtag}, $file, $recipe );

   if ($res->found) {
      $path = $self->domain_model->update( $file, $attrs );
      $msg  = 'Updated [_1] in [_2]';
   }
   else {
      $path = $self->domain_model->create( $file, $attrs );
      $msg  = 'Created [_1] in [_2]';
   }

   $self->add_result( $self->loc( $msg, $recipe, $path ) );
   return $recipe;
}

sub delete {
   my $self = shift;

   my $file     = $self->query_value( q(file) )
      or throw 'File path not specified';
   my $unwanted = $self->query_value( q(recipe) )
      or throw 'Recipe name not specified';
   my $path     = $self->domain_model->delete( $file, $unwanted );

   $self->add_result_msg( 'Deleted [_1] from [_2]', $unwanted, $path );
   return;
}

sub extension {
   return shift->domain_model->extension;
}

sub index {
   my ($self, $attr) = @_; my $path;

   ($attr and $path = $self->query_value( $attr ))
      or throw 'File path not specified';

   $self->add_result( $self->domain_model->index( $path ) );
   return TRUE;
}

sub recipes_edit_form {
   my ($self, $file, $recipe) = @_; my $data;

   my $s = $self->context->stash; my $dm = $self->domain_model;

   try        { $data = $dm->retrieve( $s->{newtag}, $file, $recipe ) }
   catch ($e) { return $self->add_error( exception $e ) }

   my $extn    = $self->extension;
   my $form    = $s->{form}->{name}; $s->{pwidth} -= 15;
   my $labels  = { map { (my $x = $_) =~ s{ \Q$extn\E \z }{}mx; $_ => $x }
                      @{ $data->files } };
   my $files   = $data->files;   unshift @{ $files   }, NUL, $s->{newtag};
   my $recipes = $data->recipes; unshift @{ $recipes }, NUL, $s->{newtag};
   my $fields  = $data->flds;

   $self->clear_form  ( { firstfld => $form.q(.file) } );
   $self->add_field   ( { default  => $file,
                          id       => $form.q(.file),
                          labels   => $labels,
                          values   => $files } );

   if ($file and $file eq $s->{newtag}) {
      $self->add_field( { default  => $self->query_value( q(name) ) || NUL,
                          id       => $form.q(.name),
                          name     => q(recipe) } );
   }
   elsif ($file) {
      $self->add_field( { default  => $recipe,
                          id       => $form.q(.recipe),
                          labels   => $data->labels,
                          values   => $recipes } );
   }

   $self->group_fields( { id       => $form.q(.select) } );

   ($recipe and is_member $recipe, $recipes) or return;

   $self->add_field   ( { default  => $fields->{title},
                          id       => $form.q(.title)       } );
   $self->add_field   ( { id       => $form.q(.categories),
                          values   => $fields->{categories} } );
   $self->add_field   ( { default  => $fields->{yield},
                          id       => $form.q(.yield)       } );
   $self->add_field   ( { data     => $data->ingredients,
                          id       => $form.q(.ingredients) } );
   $self->add_field   ( { default  => $fields->{directions},
                          id       => $form.q(.directions)  } );
   $self->group_fields( { id       => $form.q(.edit)        } );

   if ($recipe eq $s->{newtag}) { $self->add_buttons( qw(Insert Index) ) }
   else { $self->add_buttons( qw(Save Delete Index List) ) }

   return;
}

sub recipes_view_form {
   my ($self, $file, $recipe) = @_; $file or return; $recipe ||= NUL;

   my $c      = $self->context;
   my $dm     = $self->domain_model;
   my $action = $c->action->namespace.SEP.q(recipes_edit);
   my $tip    = "Recipe ${recipe} from ${file}";
   my $s      = $c->stash;
   my $title;

   $self->clear_form;

   $s->{nav_model}->select_this( 0, 1, {
      href => $c->uri_for_action( $c->action, $recipe, $file ),
      text => $self->loc( 'View' ),
      tip  => $self->loc( 'Navigation' ).TTS.$tip } );

   $self->add_field( { class => q(anchor_button fade nudge-right),
                       href  => $c->uri_for_action( $action, $recipe, $file ),
                       text  => $self->loc( 'Edit Recipe' ),
                       type  => q(anchor) } );

   try { $title = $dm->render( $s->{sdata}->{items}, $file, $recipe ) }
   catch ($e) { return $self->add_error( exception $e ) }

   $title and $s->{title} = $title;
   return;
}

sub search_for {
   my ($self, $args) = @_; return $self->domain_model->search_for( $args );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::MealMaster - Manipulate food recipes stored in MMF format

=head1 Version

0.6.$Revision: 1288 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 COMPONENT

=head2 add_search_hit

=head2 build_per_context_instance

=head2 conversion

=head2 create

=head2 create_or_update

=head2 delete

=head2 extension

=head2 index

=head2 recipes_edit_form

=head2 recipes_view_form

=head2 search_for

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<Class::Accessor::Fast>

=item L<CatalystX::Usul::Model>

=item L<App::Munchies::MealMaster>

=item L<CatalystX::Usul::Constants>

=item L<CatalystX::Usul::Functions>

=item L<MRO::Compat>

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
