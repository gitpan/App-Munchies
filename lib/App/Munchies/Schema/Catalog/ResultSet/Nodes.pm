package App::Munchies::Schema::Catalog::ResultSet::Nodes;

# @(#)$Id: Nodes.pm 541 2008-11-11 21:48:51Z pjf $

use strict;
use warnings;
use base qw(DBIx::Class::ResultSet);

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 541 $ =~ /\d+/gmx );

sub catalogs {
   my $self = shift;

   return [ map { $_->nid } $self->search( { gid      => 2 },
                                           { columns  => [ qw(nid) ],
                                             join     => [ qw(names) ],
                                             order_by => q(names.text) } ) ];
}

sub current {
   my ($self, $subject) = @_; my ($current, $labels, $ref) = ([], {}, undef);

   if ($subject) {
      for $ref ($self->search( { gid      => $subject },
                               { columns  => [ qw(lid links.text) ],
                                 join     => [ qw(links) ],
                                 order_by => q(links.text) } )) {
         push @{$current}, $ref->lid;

         if ($ref->links->text) {
            ($labels->{ $ref->lid }
                = substr $ref->links->text, 0, 40) =~ s{ _ }{ }gmx;
         }
      }
   }

   return ($current, $labels);
}

sub subjects {
   my ($self, $cat) = @_;

   return [ map { $_->nid } $self->search( { gid      => $cat },
                                           { columns  => [ qw(nid) ],
                                             join     => [ qw(names) ],
                                             order_by => q(names.text) } ) ];
}

1;

__END__

=pod

=head1 Name

<Module::Name> - <One-line description of module's purpose>

=head1 Version

0.1.$Revision: 541 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 catalogs

=head2 current

=head2 subjects

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
