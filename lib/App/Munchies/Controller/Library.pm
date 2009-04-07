package App::Munchies::Controller::Library;

# @(#)$Id: Library.pm 639 2009-04-05 17:47:16Z pjf $

use strict;
use warnings;
use base qw(CatalystX::Usul::Controller);
use Class::C3;

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 639 $ =~ /\d+/gmx );

sub base : Chained(lang) CaptureArgs(0) {
   # PathPart set in global configuration
}

sub begin : Private {
   return shift->next::method( @_ );
}

sub check_field : Chained(base) Args(0) HasActions Public {
   return shift->next::method( @_ );
}

sub common : Chained(base) PathPart('') CaptureArgs(0) {
   my ($self, $c) = @_;

   $self->next::method( $c, $c->model( q(Catalog) ) );
   $self->load_keys( $c );
   $self->add_sidebar_panel( $c, { name => q(conversion) } );
   return;
}

sub lang : Chained(/) PathPart('') CaptureArgs(1) {
   # Capture the language selection from the requested url
}

sub reception : Chained(common) Args(0) Public {
   my ($self, $c) = @_;

   $c->model( q(Base) )->simple_page( q(reception) );
   return;
}

sub redirect_to_default : Chained(base) PathPart('') Args {
   my ($self, $c) = @_;

   return $self->redirect_to_path( $c, q(/reception) );
}

sub version {
   return $VERSION;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Library - A server side bookmark manager and food recipe database

=head1 Version

$Revision: 639 $

=head1 Synopsis

=head1 Description

=head1 Subroutines/Methods

=head2 base

=head2 begin

=head2 check_field

=head2 common

=head2 lang

=head2 reception

=head2 redirect_to_default

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

