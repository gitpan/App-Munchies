# @(#)$Id: Admin.pm 790 2009-06-30 02:51:12Z pjf $

package App::Munchies::Controller::Library::Admin;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.4.%d', q$Rev: 790 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Controller);

__PACKAGE__->config( catalog_class => q(Catalog),
                     links_class   => q(Catalog::Links),
                     names_class   => q(Catalog::Names),
                     namespace     => q(library),
                     nodes_class   => q(Catalog::Nodes) );

__PACKAGE__->mk_accessors( qw(catalog_class links_class
                              names_class namespace nodes_class) );

sub admin : Chained(common) CaptureArgs(0) {
   my ($self, $c) = @_; my $s = $c->stash;

   my $model    = $c->model( $self->names_class );
   my $names    = { map { $_->id => $_->text } $model->search() };

   $names->{0}  = q(); $names->{'-1'} = $s->{newtag};

   $s->{model}->{catalog } = $c->model( $self->catalog_class );
   $s->{model}->{catalogs} = $c->model( $self->nodes_class )->catalogs();
   $s->{model}->{links   } = $c->model( $self->links_class );
   $s->{model}->{names   } = $names;
   $s->{model}->{nodes   } = $c->model( $self->nodes_class );
   return;
}

sub collection_update : ActionFor(collection_view.update) {
   my ($self, $c) = @_; my $s = $c->stash; my $model = $s->{model}->{catalog};

   my $args = { subject => $self->get_key( $c, q(subject) ) };

   if ($model->query_value( q(links_n_added) )) {
      $args->{field} = q(links_added);
      $model->add_links_to_subject( $args );
   }

   if ($model->query_value( q(links_n_deleted) )) {
      $args->{field} = q(links_deleted);
      $model->remove_links_from_subject( $args );
   }

   return 1;
}

sub collection_view : Chained(admin) PathPart(collection) Args HasActions {
   my ($self, $c, $cat, $subject) = @_;

   $cat     = $self->set_key( $c, q(catalog), $cat );
   $subject = $self->set_key( $c, q(subject), $subject );
   $c->stash->{model}->{catalog}->form( $cat, $subject );
   return;
}

sub links_delete : ActionFor(links_view.delete) {
   my ($self, $c) = @_;

   $c->stash->{model}->{catalog}->links_delete( $self->get_key( $c, q(link) ));
   $self->set_key( $c, q(link), -1 );
   return 1;
}

sub links_insert : ActionFor(links_view.insert) {
   my ($self, $c) = @_;

   my $id = $c->stash->{model}->{catalog}->links_insert;

   $self->set_key( $c, q(link), $id );
   return 1;
}

sub links_save : ActionFor(links_view.save) {
   my ($self, $c) = @_;

   $c->stash->{model}->{catalog}->links_save( $self->get_key( $c, q(link) ) );
   return 1;
}

sub links_view : Chained(admin) PathPart(links) Args HasActions {
   my ($self, $c, $cat, $link) = @_;

   $cat  = $self->set_key( $c, q(catalog), $cat  );
   $link = $self->set_key( $c, q(link),    $link );
   $c->stash->{model}->{catalog}->form( $cat, $link );
   return;
}

sub nodes_delete : ActionFor(nodes_view.delete) {
   my ($self, $c) = @_;

   my $args = { catalog => $self->get_key( $c, q(catalog) ),
                names   => $c->model( $self->names_class ),
                subject => $self->get_key( $c, q(subject) ) };

   $c->stash->{model}->{catalog}->nodes_delete( $args );
   return 1;
}

sub nodes_insert : ActionFor(nodes_view.insert) {
   my ($self, $c) = @_;

   my $args = { catalog => $self->get_key( $c, q(catalog) ),
                names   => $c->model( $self->names_class ),
                subject => $self->get_key( $c, q(subject) ) };

   $c->stash->{model}->{catalog}->nodes_insert( $args );
   return 1;
}

sub nodes_save : ActionFor(nodes_view.save) {
   my ($self, $c) = @_; my $s = $c->stash;

   $s->{model}->{catalog}->nodes_save( $c->model( $self->names_class ) );
   return 1;
}

sub nodes_view : Chained(admin) PathPart(nodes) Args HasActions {
   my ($self, $c, $cat, $subject) = @_;

   $cat     = $self->set_key( $c, q(catalog), $cat );
   $subject = $self->set_key( $c, q(subject), $subject );
   $c->stash->{model}->{catalog}->form( $cat, $subject );
   return;
}

sub recatalog : Chained(admin) PathPart('') Args(0) Public {
   my ($self, $c) = @_;

   return $self->redirect_to_path( $c, q(/recatalog_view) );
}

sub recatalog_view : Chained(admin) PathPart(recatalog) Args(0) HasActions {
   my ($self, $c) = @_; $c->stash->{model}->{catalog}->recatalog_form; return;
}

sub recatalog_exec : ActionFor(recatalog_view.execute) {
   my ($self, $c) = @_; $c->stash->{model}->{catalog}->recatalog_exec; return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library::Admin - Manage server side bookmarks database

=head1 Version

0.4.$Revision: 790 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 admin

=head2 collection_update

=head2 collection_view

=head2 links_delete

=head2 links_insert

=head2 links_save

=head2 links_view

=head2 nodes_delete

=head2 nodes_insert

=head2 nodes_save

=head2 nodes_view

=head2 recatalog

=head2 recatalog_exec

=head2 recatalog_view

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
