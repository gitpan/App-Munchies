# @(#)$Id: Lock.pm 738 2009-06-09 16:42:23Z pjf $

package App::Munchies::Programs::Lock;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 738 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Programs);

sub list {
   my $self = shift; my $line;

   for my $ref (@{ $self->lock->list || [] }) {
      $line  = $ref->{key}.q(,).$ref->{pid}.q(,);
      $line .= $self->time2str( '%Y-%m-%d %H:%M:%S', $ref->{stime} ).q(,);
      $line .= $ref->{timeout};
      $self->say( $line );
   }

   return 0;
}

sub reset {
   my $self = shift; $self->lock->reset( %{ $self->args } ); return 0;
}

sub set {
   my $self = shift; $self->lock->set( %{ $self->args } ); return 0;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Programs::Lock - CLI to the IPC::SRLock module

=head1 Version

0.1.$Revision: 738 $

=head1 Synopsis

   #!/usr/bin/perl

   use App::Munchies::Programs::Lock;

   my $prog = App::Munchies::Programs::Lock->new( appclass => q(App::Munchies) );

   exit $prog->dispatch;

=head1 Description

=head1 Subroutines/Methods

=head2 list

=head2 reset

=head2 set

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::Programs>

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
