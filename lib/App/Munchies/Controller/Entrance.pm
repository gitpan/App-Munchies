# @(#)$Id: Entrance.pm 1318 2012-04-22 17:10:47Z pjf $

package App::Munchies::Controller::Entrance;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Controller::Entrance);

use CatalystX::Usul::Constants;

__PACKAGE__->config( clock_uri  => q(/static/svg/SiemensClock.svg),
                     demo_class => q(DemoText), );

__PACKAGE__->mk_accessors( qw(clock_uri demo_class) );

sub common : Chained(base) PathPart('') CaptureArgs(0) {
   my ($self, $c) = @_;

   $self->next::method( $c ); $self->_add_sidebar_panels( $c );
   $c->stash->{is_administrator} and $self->_add_display_lock( $c );
   return;
}

sub clock : Chained(common) Args(0) Public {
   my ($self, $c) = @_;

   return $c->model( $self->demo_class )->deskclock( $self->clock_uri );
}

sub custom : Chained(reception_base) Args {
   my ($self, $c, $count) = @_; $c->stash->{count} = $count || 3; return;
}

sub empty : Chained(common) Args(0) Public {
}

sub information : Chained(base) Args(0) NoToken Public {
   my ($self, $c) = @_; return $c->model( $self->demo_class )->information;
}

sub lock_display : Chained(/) Args(0) {
   my ($self, $c) = @_; return $c->model( $self->demo_class )->lock_display;
}

sub overview : Chained(base) Args(0) NoToken Public {
   # Respond to the ajax call for some info about the side bar accordion
   my ($self, $c) = @_; return $c->model( q(Help) )->overview;
}

sub sampler : Chained(reception_base) Args(0) HasActions {
   my ($self, $c) = @_; return $c->model( $self->demo_class )->sampler;
}

sub sampler_chooser : Chained(reception_base) Args(0)
                      HasActions NoToken Public {
   my ($self, $c) = @_; return $c->model( $self->demo_class )->sampler_chooser;
}

sub sampler_result : ActionFor(sampler.save) {
   my ($self, $c) = @_; my $model = $c->model( $self->demo_class );

   $model->add_result( $model->query_value( q(textfield) ) );
   return TRUE;
}

sub test_card : Chained(common) Args(0) {
   my ($self, $c) = @_; return $c->model( $self->demo_class )->test_card;
}

sub version {
   return $VERSION;
}

sub wikipedia : Chained(doc_base) Args NoToken {
   my ($self, $c) = @_; return $c->model( $self->demo_class )->wikipedia;
}

# Private methods

sub _add_display_lock {
   my ($self, $c) = @_; my $s = $c->stash;

   my $tools  = $s->{menus}->{items}->[ 1 ]->{content}->{data};
   my $action = $c->action->namespace.SEP.q(lock_display);
   my $url    = $c->uri_for_action( $action );
   my $data   = q(display=:0);
   my $name   = q(tools);
   my $menu   = 3;

   $s->{nav_model}->_push_menu_link( $tools, $menu, {
      class    => $name.q(_title fade submit),
      config   => {
         args  => "[ '${url}', '${data}' ]", method => "'postData'" },
      href     => '#top',
      id       => $name.$menu.q(item0),
      imgclass => q(lock_icon),
      sep      => NUL,
      text     => NUL,
      tip      => DOTS.TTS.$self->loc( $s, 'Lock the display' ) } );

   return;
}

sub _add_sidebar_panels {
   my ($self, $c) = @_; my $model = $c->model( $self->model_base_class );

   $model->add_sidebar_panel( { name => q(default)     } );
   $model->add_sidebar_panel( { name => q(overview)    } );
   $model->add_sidebar_panel( { name => q(information) } );
   return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Entrance - Welcome to this application framework

=head1 Version

$Revision: 1318 $

=head1 Synopsis

Since it inherits from Catalyst::Controller via a custom base class
this COMPONENT will be instantiated when the application starts

=head1 Description

The entrance level (controller) welcomes you to the application
framework. It's rooms (methods) contain information that will help you
get the most from this system. Rooms on the entrance level are (by
default) accessable to anyone.

=head1 Context Help

=head2 Authentication

Authenticate with the system to reveal the hidden levels

=head2 Clock

SVG Animated system clock. Lifted from Stefan Oskamp http://oskamp.dyndns.org/

=head2 Custom

Demonstrates the use of the custom template widget by displaying
paragraphs of Lorem text

=head2 Documentation

List the documentation for the application

=head2 Reception

Application splash screen

=head2 Sampler

List the availables widgets in the form building library

=head2 SiteMap

Jump to any page within the application

=head2 Wikipedia

Looks up the search term in the URI argument on Wikipedia

=head1 Subroutines/Methods

=head2 clock

=head2 common

Overrides base class (which it calls) and then adds the data to the stash
that creates the sidebar panels

=head2 custom

Multiple pages of Lorem text

=head2 empty

Empty (hidden) room. Try typing it's path into the address field of
your browser

=head2 information

This private action provides the content for the information panel of
the accordian widget on side bar. It demonstrates user demand loaded content.

=head2 lock_display

Locks the display. Silly but I couldn't resist

=head2 overview

Displays some descritptive text. Demonstrates how to use the side bar.

=head2 sampler

The widgets in the form widget library

=head2 sampler_chooser

=head2 sampler_result

=head2 test_card

Displays a test card

=head2 version

=head2 wikipedia

=head1 Diagnostics

Debug can be turned on/off from the tools menu

=head1 Configuration and Environment

The reception method in the Controller module displays text items from
this modules configuration file (entrance.xml). The records are keyed
receptionSubHeading<n> and receptionText<n> where <n> = 0, 1, 2
... The message editor on the Admin level can be used to maintain these
records.

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::Controller::Entrance>

=back

=head1 Incompatibilities

None known

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2009 Peter Flanigan. All rights reserved

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
