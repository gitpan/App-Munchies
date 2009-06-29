# @(#)$Id: Authentication.pm 757 2009-06-11 16:42:06Z pjf $

package App::Munchies::Model::Authentication;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 757 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Model::Schema);

use Class::C3;

__PACKAGE__->config
   ( connect_info => [],
     database     => q(library),
     schema_class => q(App::Munchies::Schema::Authentication) );

sub new {
   my ($self, $app, $config) = @_;

   my $database = $config->{database} || $self->config->{database};

   $config->{connect_info} = $self->connect_info( $app, $database );

   return $self->next::method( $app, $config );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::Authentication - Database authentication class

=head1 Version

0.3.$Revision: 757 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 new

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
