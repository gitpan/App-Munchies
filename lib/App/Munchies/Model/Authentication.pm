# @(#)$Id: Authentication.pm 1129 2011-04-04 10:42:50Z pjf $

package App::Munchies::Model::Authentication;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1129 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Model::Schema);

use MRO::Compat;

__PACKAGE__->config
   ( database     => q(library),
     schema_class => q(App::Munchies::Schema::Authentication) );

sub COMPONENT {
   my ($class, $app, $config) = @_;

   $config->{database}     ||= $class->config->{database};
   $config->{connect_info} ||=
      $class->get_connect_info( $app->config, $config->{database} );

   return $class->next::method( $app, $config );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::Authentication - Database authentication class

=head1 Version

0.5.$Revision: 1129 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 COMPONENT

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
