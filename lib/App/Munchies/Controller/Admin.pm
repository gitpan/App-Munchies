package App::Munchies::Controller::Admin;

# @(#)$Id: Admin.pm 481 2008-09-07 15:54:14Z pjf $

use strict;
use warnings;
use base qw(CatalystX::Usul::Controller::Admin);

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 481 $ =~ /\d+/gmx );

__PACKAGE__->build_subcontrollers;

1;

__END__

=pod

=head1 Name

App::Munchies::Controller::Admin - Cross application administrative functions

=head1 Version

$Revision: 481 $

=head1 Synopsis

=head1 Description

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::Controller::Admin>

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

Copyright (c) 2008 RoxSoft Limited. All rights reserved

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
