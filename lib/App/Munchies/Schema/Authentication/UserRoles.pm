# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-03-04 02:50:46
# @(#)$Id: UserRoles.pm 1178 2011-05-25 00:43:17Z pjf $

package App::Munchies::Schema::Authentication::UserRoles;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1178 $ =~ /\d+/gmx );
use parent qw(App::Munchies::Schema::Base);

__PACKAGE__->table( 'user_roles' );
__PACKAGE__->add_columns( 'user_id', { data_type         => 'MEDIUMINT',
                                       default_value     => undef,
                                       is_nullable       => 0,
                                       size              => 8, },
                          'role_id', { data_type         => 'MEDIUMINT',
                                       default_value     => undef,
                                       is_nullable       => 0,
                                       size              => 8, } );
__PACKAGE__->set_primary_key( qw(user_id role_id) );
__PACKAGE__->belongs_to(
   user_rel => 'App::Munchies::Schema::Authentication::Users', 'user_id' );
__PACKAGE__->belongs_to(
   role_rel => 'App::Munchies::Schema::Authentication::Roles', 'role_id' );

1;

__END__

=pod

=head1 Name

App::Munchies::Schema::Authentication::UserRoles - Class definition for the user_roles table

=head1 Version

0.5.$Revision: 1178 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

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

