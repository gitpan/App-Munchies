# @(#)$Id: Admin.pm 1288 2012-03-29 00:20:38Z pjf $

package App::Munchies::Admin;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1288 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Admin);

1;

__END__

=pod

=head1 Name

App::Munchies::Admin - Subroutines that run as the super user

=head1 Version

0.6.$Revision: 1288 $

=head1 Synopsis

   use App::Munchies::Admin;
   use English qw(-no_match_vars);

   my $prog = App::Munchies::Admin->new( appclass => q(App::Munchies),
                                         arglist  => q(e) );

   $EFFECTIVE_USER_ID  = 0; $REAL_USER_ID  = 0;
   $EFFECTIVE_GROUP_ID = 0; $REAL_GROUP_ID = 0;

   unless ($prog->is_authorised) {
      my $text = 'Permission denied to '.$prog->method.' for '.$prog->logname;

      $prog->error( $text );
      exit 1;
   }

   exit $prog->run;

=head1 Description

Inherits all from L<CatalystX::Usul::Admin>

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::Admin>

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

Copyright (c) 2011 Peter Flanigan. All rights reserved

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
