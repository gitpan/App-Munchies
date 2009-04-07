package App::Munchies::Controller::Library::Catalog;

# @(#)$Id: Catalog.pm 639 2009-04-05 17:47:16Z pjf $

use strict;
use warnings;
use base qw(CatalystX::Usul::Controller);

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 639 $ =~ /\d+/gmx );

__PACKAGE__->config( catalog_class => q(Catalog),
                     data_class    => q(MealMaster),
                     hits_per_page => 16,
                     links_class   => q(Catalog::Links),
                     names_class   => q(Catalog::Names),
                     namespace     => q(library),
                     nodes_class   => q(Catalog::Nodes) );

__PACKAGE__->mk_accessors( qw(catalog_class data_class hits_per_page
                              links_class namespace nodes_class) );

my $SEP = q(/);

sub browse : Chained(common) Args Public {
   my ($self, $c, $id) = @_; my $s = $c->stash; my ($class, $res);

   $self->redirect_to_path( $c, $SEP.q(catalog) ) unless ($id);

   unless ($res = $c->model( $self->links_class )->find( $id )) {
      $self->log_error( $self->loc( q(eNoLink), $id ) );
      return;
   }

   unless ($res->url) {
      $self->log_error( $self->loc( q(eBadLink), $id ) );
      return;
   }

   my ($file, $pos) = split m{ \? }mx, $res->url, 2;
   $class = $file && $file =~ m{ \.mmf \z }msx
          ? $self->data_class : $self->catalog_class;
   $c->model( $class )->browse( $id, $res->url );
   return;
}

sub catalog : Chained(common) Args HasActions Public {
   my ($self, $c) = @_;

   my $args = { cat_type   => $self->get_key( $c, q(catalog_type) ),
                catalog    => $self->get_key( $c, q(catalog)      ),
                col_type   => $self->get_key( $c, q(colour_type)  ),
                min_count  => $self->get_key( $c, q(min_count)    ),
                nodes      => $c->model( $self->nodes_class  ),
                sort_field => $self->get_key( $c, q(sort_field)   ) };

   $c->model( $self->catalog_class )->form( $args );
   return;
}

sub catalog_grid_rows : Chained(base) Args(0) HasActions Public {
   my ($self, $c) = @_; my $model = $c->model( $self->catalog_class );

   $model->grid_rows( $c->model( $self->nodes_class ),
                      $c->model( $self->links_class ) );
   return;
}

sub catalog_grid_table : Chained(base) Args(0) HasActions Public {
   my ($self, $c) = @_; my $model = $c->model( $self->catalog_class );

   $model->grid_table( $c->model( $self->nodes_class ) );
   return;
}

sub ingredients : Chained(common) Args HasActions {
   my ($self, $c, $expr, $hits_per, $offset) = @_; my $s = $c->stash; my $pno;

   $pno = $self->add_sidebar_panel( $c, { name => q(search), value => $expr });

   $self->select_sidebar_panel( $c, $pno );
   $self->open_sidebar( $c );

   $c->forward( q(search_view), [ $expr, $hits_per, $offset ] ) if ($expr);

   return if ($s->{sdata});

   $c->model( $self->data_class )->simple_page( q(ingredients) );
   $s->{token} = $c->config->{token};
   return;
}

sub search : Chained(base) Args(0) HasActions Public {
   my ($self, $c) = @_; my $s = $c->stash;

   $s->{form} = {
      action => $self->uri_for( $c, $SEP.q(ingredients), $s->{lang} ),
      name   => q(ingredients) };
   $self->load_keys( $c );

   my $expr  = $self->get_key( $c, q(search_expression) );
   my $model = $c->model( $self->catalog_class );

   $model->search_form( $model->query_value( q(id) ), $expr );
   return;
}

sub search_results : ActionFor(ingredients.search) {
   my ($self, $c) = @_;

   my $expr = $c->model( $self->catalog_class )->query_value( q(expression) );

   $c->forward( q(search_view), [ $expr, 0, 0 ] );
   return 1;
}

sub search_view : Private {
   my ($self, $c, $expr, $hits_per, $offset) = @_;

   my $key = q(search_expression); $expr ||= q();

   $self->set_key( $c, $key, $expr );
   $hits_per ||= $self->hits_per_page;
   $offset     = $offset && $offset =~ m{ \d+ }mx ? $offset - 1 : 0;

   my $ref = { data_model => $c->model( $self->data_class ),
               excerpts   => q(ingredients),
               expression => $expr,
               hits_per   => $hits_per,
               key        => $key,
               offset     => $offset };
   $c->model( $self->catalog_class )->search_page( $ref );
   return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library::Catalog - Server side bookmarks

=head1 Version

0.1.$Revision: 639 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 browse

=head2 catalog

=head2 catalog_grid_rows

=head2 catalog_grid_table

=head2 ingredients

=head2 search

=head2 search_results

=head2 search_view

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

