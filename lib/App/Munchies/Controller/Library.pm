# @(#)$Id: Library.pm 1318 2012-04-22 17:10:47Z pjf $

package App::Munchies::Controller::Library;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Controller);

use CatalystX::Usul::Constants;

__PACKAGE__->config( catalog_class => q(Catalog),
                     search_key    => q(search_expression), );

__PACKAGE__->mk_accessors( qw(catalog_class search_key) );

sub begin : Private {
   return shift->next::method( @_ );
}

sub base : Chained(/) CaptureArgs(0) {
   # PathPart set in global configuration
   my ($self, $c) = @_;

   return $self->init_uri_attrs( $c, $self->model_base_class );
}

sub check_field : Chained(base) Args(0) HasActions NoToken Public {
   return shift->next::method( @_ );
}

sub common : Chained(base) PathPart('') CaptureArgs(0) {
   my ($self, $c) = @_; my $s = $c->stash; my $nav = $s->{nav_model};

   $nav->add_header; $nav->add_footer;

   my $model = $c->model( $self->model_base_class );

   $model->add_sidebar_panel( { name => q(conversion) } );
   return;
}

sub add_search_panel : Private {
   my ($self, $c, $action, @rest) = @_;

   my @args  = ($action, @rest);
   my $model =  $c->model( $self->catalog_class );
   my $query =  $model->search_view( @args );
   my $pno   =  $model->add_sidebar_panel( {
      action      => $action,
      name        => q(search),
      on_complete => 'function() { this.tips.build() }',
      value       => $query,
      unshift     => TRUE } );

   $self->select_sidebar_panel( $c, $pno );
   $self->open_sidebar( $c );

   return $c->stash->{sdata} ? TRUE : FALSE;
}

sub footer : Chained(base) Args(0) NoToken Public {
   my ($self, $c) = @_; return $c->model( $self->help_class )->add_footer;
}

sub redirect_to_search : Private {
   my ($self, $c) = @_;

   my $model = $c->model( $self->catalog_class );
   my $query = $model->query_value( $self->search_key );

   $c->res->redirect( $c->uri_for_action( $c->action->reverse, $query ) );
   $c->detach(); # Never returns
   return TRUE;
}

sub version : Private {
   return $VERSION;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library - A server side bookmark manager and food recipe database

=head1 Version

$Revision: 1318 $

=head1 Synopsis

=head1 Description

=head1 Subroutines/Methods

=head2 add_search_panel

=head2 base

=head2 begin

=head2 check_field

=head2 common

=head2 footer

=head2 redirect_to_search

=head2 version

=head1 Diagnostics

=head1 Configuration and Environment

The reception method in the Controller module displays text items from
this modules configuration file (entrance.xml). The records are keyed
receptionSubHeading<n> and receptionText<n> where <n> = 0, 1, 2
... The message editor on the Bridge can be used to maintain these
records.

=head1 Dependencies

=over 4

=item L<CatalystX::Usul::Controller>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module.

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome.

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2009 Peter Flanigan. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

