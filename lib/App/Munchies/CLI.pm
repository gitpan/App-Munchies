# @(#)$Id: CLI.pm 1291 2012-03-31 22:48:18Z pjf $

package App::Munchies::CLI;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1291 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::CLI);

1;

__END__

=pod

=head1 Name

App::Munchies::CLI - Subroutines accessed from the command line

=head1 Version

0.6.$Revision: 1291 $

=head1 Synopsis

   #!/usr/bin/perl

   use App::Munchies::CLI;

   exit App::Munchies::CLI->new( appclass => q(App::Munchies) )->run;

=head1 Description

Implements methods available to the command line interface. Inherits from
L<CatalystX::Usul::CLI> which contains all of the available methods

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Configuration and Environment

None

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::CLI>

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

Copyright (c) 2012 Peter Flanigan. All rights reserved

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
