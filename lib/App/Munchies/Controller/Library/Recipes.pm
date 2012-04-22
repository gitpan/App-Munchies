# @(#)$Id: Recipes.pm 1318 2012-04-22 17:10:47Z pjf $

package App::Munchies::Controller::Library::Recipes;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use parent qw(App::Munchies::Controller::Library);

use CatalystX::Usul::Constants;

__PACKAGE__->config( recipe_class => q(MealMaster), );

__PACKAGE__->mk_accessors( qw(recipe_class) );

sub conversion : Chained(base) Args(0) HasActions NoToken Public {
   my ($self, $c) = @_; return $c->model( $self->recipe_class )->conversion;
}

sub ingredients : Chained(common) Args HasActions {
   my ($self, $c, @rest) = @_;

   $c->forward( q(add_search_panel), [ q(ingredients), @rest ] ) and return;
   $c->stash->{display_instructions} = TRUE;
   return;
}

sub ingredients_clear_search : ActionFor(ingredients.clear) {
   my ($self, $c) = @_;

   $c->req->params->{ $self->search_key } = NUL;
   $self->set_uri_args( $c, NUL );
   return TRUE;
}

sub ingredients_search : ActionFor(ingredients.search) {
   my ($self, $c) = @_; return $c->forward( q(redirect_to_search) );
}

sub recipes : Chained(common) PathPart('') CaptureArgs(0) {
   my ($self, $c) = @_;

   $c->stash->{model} = $c->model( $self->recipe_class );
   return;
}

sub recipes_delete : ActionFor(recipes_edit.delete) {
   my ($self, $c) = @_; my $s = $c->stash;

   $s->{model}->delete; $self->set_uri_args( $c, $s->{newtag} );
   return TRUE;
}

sub recipes_edit : Chained(recipes) PathPart(edit) Args HasActions {
   my ($self, $c, @args) = @_; $self->close_sidebar( $c );

   return $c->stash->{model}->form( $self->_get_model_args( $c, @args ) );
}

sub recipes_index : ActionFor(recipes_edit.index) {
   my ($self, $c) = @_; return $c->stash->{model}->index( q(file) );
}

sub recipes_show : ActionFor(recipes_edit.list) {
   my ($self, $c) = @_;

   return $self->redirect_to_path( $c, SEP.q(recipes_view) );
}

sub recipes_save : ActionFor(recipes_edit.save) {
   my ($self, $c) = @_;

   $self->set_uri_args( $c, $c->stash->{model}->create_or_update );
   return TRUE;
}

sub recipes_view : Chained(recipes) PathPart(view) Args HasActions Public {
   my ($self, $c, @args) = @_;

   my @model_args = $self->_get_model_args( $c, @args );

   __is_recipe( $c, $model_args[ 0 ] )
      and return $c->stash->{model}->form( @model_args );

   $self->close_sidebar( $c );

   $model_args[ 0 ]
      and return $c->model( $self->catalog_class )->view( @model_args );

   return $self->default( $c );
}

# Private methods

sub _get_model_args {
   my ($self, $c, @args) = @_;

   my $link_url = $c->model( $self->catalog_class )->get_link_url( @args );

   if (__is_recipe( $c, $link_url )) {
      my $sep = SEP; return reverse split m{ $sep }mx, $link_url || NUL, 2;
   }

   $link_url and return ($link_url);

   __is_recipe( $c, $args[ 1 ] ) and return ($args[ 1 ]);

   return ();
}

# Private subroutines

sub __is_recipe {
   my ($c, $candidate) = @_; my $extn = $c->stash->{model}->extension;

   return $candidate && $candidate =~ m{ \Q$extn\E \z }mx ? TRUE : FALSE;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library::Recipes - Food recipe management

=head1 Version

0.7.$Revision: 1318 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 conversion

=head2 ingredients

=head2 ingredients_clear_search

=head2 ingredients_search

=head2 recipes

=head2 recipes_delete

=head2 recipes_edit

=head2 recipes_index

=head2 recipes_show

=head2 recipes_save

=head2 recipes_view

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<App::Munchies::Controller::Library>

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
