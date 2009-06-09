package App::Munchies::Schema::Catalog::ResultSet::Links;

# @(#)$Id: Links.pm 738 2009-06-09 16:42:23Z pjf $

use strict;
use warnings;
use base qw(DBIx::Class::ResultSet);
use List::Util qw(first);

use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 738 $ =~ /\d+/gmx );

sub list {
   my ($self, $cat, $labels, $current) = @_; my ($links, $ref);

   for $ref ($self->search({ nid => [ 2, $cat ] }, { order_by => 'text' } )) {
      push @{$links}, $ref->id
         unless ($current && _is_member( $ref->id, $current ));

      unless (exists $labels->{ $ref->id }) {
         $ref->text( $ref->id ) unless ($ref->text);
         ($labels->{ $ref->id } = substr $ref->text, 0, 40) =~ s{ _ }{ }gmx;
      }
   }

   return $links;
}

sub _is_member {
   my ($candidate, $list) = @_;

   return unless ($candidate && $list);

   return (first { $_ eq $candidate } @{ $list }) ? 1 : 0;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Schema::Catalog::ResultSet::Links - Canned queries against the links table

=head1 Version

0.1.$Revision: 738 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 list

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
