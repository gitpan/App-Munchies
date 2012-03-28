# @(#)$Id: Catalog.pm 1269 2012-01-11 16:28:05Z pjf $

package App::Munchies::Controller::Library::Catalog;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1269 $ =~ /\d+/gmx );
use parent qw(App::Munchies::Controller::Library);

use CatalystX::Usul::Constants;

sub catalog : Chained(common) Args HasActions Public {
   my ($self, $c, @rest) = @_;

   $c->forward( q(add_search_panel), [ q(catalog), @rest ] ) and return;

   my $params = $self->get_uri_query_params( $c );

   return $c->model( $self->catalog_class )->form( $params );
}

sub catalog_clear_search : ActionFor(catalog.clear) {
   my ($self, $c) = @_;

   $c->req->params->{ $self->search_key } = NUL;
   $self->set_uri_args( $c, NUL );
   return TRUE;
}

sub catalog_grid_rows : Chained(base) Args(0) Public {
   my ($self, $c) = @_; return $c->model( $self->catalog_class )->grid_rows;
}

sub catalog_grid_table : Chained(base) Args(0) Public {
   my ($self, $c) = @_; return $c->model( $self->catalog_class )->grid_table;
}

sub catalog_search : ActionFor(catalog.search) {
   my ($self, $c) = @_; return $c->forward( q(redirect_to_search) );
}

sub reception : Chained(common) Args(0) Public {
}

sub redirect_to_default : Chained(base) PathPart('') Args(0) {
   my ($self, $c) = @_; return $self->redirect_to_path( $c, SEP.q(reception) );
}

sub search_base : Chained(base) PathPart('search') CaptureArgs(1) {
   my ($self, $c, $action_name) = @_; my $s = $c->stash;

   my $action_path = $c->action->namespace.SEP.$action_name;

   $s->{form} = { action => $c->uri_for_action( $action_path ),
                  name   => $action_name };

   return $self->init_uri_attrs( $c, $self->model_base_class );
}

sub search : Chained(search_base) PathPart('') Args Public {
   my ($self, $c) = @_; my $model = $c->model( $self->catalog_class );

   return $model->search_form( $c->req->captures->[ 0 ], q(id), q(val) );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library::Catalog - Server side bookmarks

=head1 Version

0.5.$Revision: 1269 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 catalog

=head2 catalog_clear_search

=head2 catalog_grid_rows

=head2 catalog_grid_table

=head2 catalog_search

=head2 reception

=head2 redirect_to_default

=head2 search

=head2 search_base

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

