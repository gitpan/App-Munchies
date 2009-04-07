package App::Munchies::Schema::Authentication::Users;

# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-03-04 02:50:46
# @(#)$Id: Users.pm 636 2009-04-01 11:51:05Z pjf $

use strict;
use warnings;
use base qw(App::Munchies::Schema::Base);

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 636 $ =~ /\d+/gmx );

__PACKAGE__->table( 'users' );
__PACKAGE__->add_columns( qw(id active username password email_address
                             first_name last_name home_phone location
                             project work_phone pwlast pwnext pwafter
                             pwwarn pwexpires pwdisable) );
__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->add_unique_constraint([ 'username' ]);
__PACKAGE__->has_many(
   roles => 'App::Munchies::Schema::Authentication::UserRoles', 'user_id' );

1;

__END__

=pod

=head1 Name

App::Munchies::Schema::Authentication::Users - Class definitions for the users table

=head1 Version

0.1.$Revision: 636 $

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
