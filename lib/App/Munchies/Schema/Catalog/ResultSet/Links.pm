# @(#)$Id: Links.pm 1199 2011-06-18 16:34:30Z pjf $

package App::Munchies::Schema::Catalog::ResultSet::Links;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1199 $ =~ /\d+/gmx );
use parent qw(DBIx::Class::ResultSet);

use CatalystX::Usul::Constants;
use CatalystX::Usul::Functions;

sub list {
   my ($self, $cat, $labels, $current) = @_; my ($links, $ref);

   for $ref ($self->search( { nid => [ 2, $cat ] }, { order_by => 'text' } )) {
      ($current and is_member $ref->id, $current) or push @{ $links }, $ref->id;

      unless (exists $labels->{ $ref->id }) {
         $ref->text or $ref->text( $ref->id );
         ($labels->{ $ref->id } = substr $ref->text, 0, 40) =~ s{ _ }{ }gmx;
      }
   }

   return $links;
}

sub search_for_field {
   my ($self, $field, $depth, @args) = @_; $args[ 0 ] or return;

   $args[ 0 ] =~ m{ \A \d+ \z }mx and return $self->find( $args[ 0 ] );

   my $index = 0; my $value = $args[ $index++ ];

   $depth == 1 and $value .= q(%);

   while ($depth > 1) {
      $args[ $index ] and $args[ $index ] !~ m{ \A \d+ \z }mx
         and $value .= SEP.$args[ $index ];
      $depth--; $index++;
   }

   my $instance =  $args[ $index ] || 1;
      $instance =~ m{ \A \d+ \z }mx or $instance = 1;
   my $res      =  (q(%) eq substr $value, -1)
                ?  $self->search( { $field => { like => $value } } )
                :  $self->search( { $field => $value } );
   my $count    =  1;

   while (my $row = $res->next) { $count++ == $instance and return $row; }

   return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Schema::Catalog::ResultSet::Links - Canned queries against the links table

=head1 Version

0.5.$Revision: 1199 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 list

=head2 search_for_field

   $obj = $self->search_for_field( $field_name, $depth, @search_args );

Searches for C<$field_name>. Extracts search values from human
readable url search args

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
