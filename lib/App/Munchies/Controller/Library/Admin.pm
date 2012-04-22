# @(#)$Id: Admin.pm 1318 2012-04-22 17:10:47Z pjf $

package App::Munchies::Controller::Library::Admin;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use parent qw(App::Munchies::Controller::Library);

use CatalystX::Usul::Constants;

sub admin_base : Chained(common) PathPart(admin) CaptureArgs(0) {
   my ($self, $c) = @_;

   $c->stash->{catalog_model} = $c->model( $self->catalog_class );
   return;
}

sub admin : Chained(admin_base) PathPart('') Args(0) Public {
   my ($self, $c) = @_;

   return $self->redirect_to_path( $c, SEP.q(recatalog_view) );
}

sub collection_update : ActionFor(collection_view.update) {
   my ($self, $c) = @_; return $c->stash->{catalog_model}->update_links;
}

sub collection_view : Chained(admin_base)
                      PathPart(collection) Args HasActions {
   my ($self, $c, @args) = @_; return $c->stash->{catalog_model}->form( @args );
}

sub links_delete : ActionFor(links_view.delete) {
   my ($self, $c, $cat) = @_;

   $c->stash->{catalog_model}->links_delete;
   $self->set_uri_args( $c, $cat, -1 );
   return TRUE;
}

sub links_insert : ActionFor(links_view.insert) {
   my ($self, $c, $cat) = @_;

   my $id = $c->stash->{catalog_model}->links_insert;

   $self->set_uri_args( $c, $cat, $id );
   return TRUE;
}

sub links_save : ActionFor(links_view.save) {
   my ($self, $c) = @_; return $c->stash->{catalog_model}->links_save;
}

sub links_view : Chained(admin_base) PathPart(links) Args HasActions {
   my ($self, $c, @args) = @_; return $c->stash->{catalog_model}->form( @args );
}

sub nodes_delete : ActionFor(nodes_view.delete) {
   my ($self, $c) = @_; return $c->stash->{catalog_model}->nodes_delete;
}

sub nodes_insert : ActionFor(nodes_view.insert) {
   my ($self, $c) = @_; return $c->stash->{catalog_model}->nodes_insert;
}

sub nodes_save : ActionFor(nodes_view.save) {
   my ($self, $c) = @_; return $c->stash->{catalog_model}->nodes_save;
}

sub nodes_view : Chained(admin_base) PathPart(nodes) Args HasActions {
   my ($self, $c, @args) = @_; return $c->stash->{catalog_model}->form( @args );
}

sub recatalog_view : Chained(admin_base)
                     PathPart(recatalog) Args(0) HasActions {
   my ($self, $c) = @_; return $c->stash->{catalog_model}->recatalog_form;
}

sub recatalog_exec : ActionFor(recatalog_view.execute) {
   my ($self, $c) = @_; return $c->stash->{catalog_model}->recatalog_exec;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library::Admin - Manage server side bookmarks database

=head1 Version

0.7.$Revision: 1318 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 admin

=head2 admin_base

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
