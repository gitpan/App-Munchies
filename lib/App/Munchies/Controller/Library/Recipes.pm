# @(#)$Id: Recipes.pm 754 2009-06-09 23:50:51Z pjf $

package App::Munchies::Controller::Library::Recipes;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 754 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Controller);

__PACKAGE__->config( recipe_class => q(MealMaster),
                     namespace    => q(library), );

__PACKAGE__->mk_accessors( qw(recipe_class) );

sub conversion : Chained(base) Args(0) HasActions Public {
   my ($self, $c) = @_;

   $c->model( $self->recipe_class )->conversion;
   return;
}

sub recipes : Chained(common) CaptureArgs(0) {
   my ($self, $c) = @_;

   $c->stash->{model} = $c->model( $self->recipe_class );
   return;
}

sub recipes_delete : ActionFor(recipes_view.delete) {
   my ($self, $c) = @_; my $s = $c->stash;

   $s->{model}->delete; $self->set_key( $c, q(recipe), $s->{newtag} );
   return 1;
}

sub recipes_index : ActionFor(recipes_view.index) {
   my ($self, $c) = @_; $c->stash->{model}->index; return 1;
}

sub recipes_save : ActionFor(recipes_view.save) {
   my ($self, $c) = @_;

   my $name = $c->stash->{model}->create_or_update;

   $self->set_key( $c, q(recipe), $name );
   return 1;
}

sub recipes_view : Chained(recipes) PathPart('') Args HasActions {
   my ($self, $c, $file, $recipe) = @_;

   $file   = $self->set_key( $c, q(file),   $file   );
   $recipe = $self->set_key( $c, q(recipe), $recipe );
   $c->stash->{model}->form( $file, $recipe );
   return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library::Recipes - Food recipe management

=head1 Version

0.3.$Revision: 754 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 conversion

=head2 recipes

=head2 recipes_delete

=head2 recipes_index

=head2 recipes_save

=head2 recipes_view

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
