# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-03-04 02:50:46
# @(#)$Id: Nodes.pm 741 2009-06-09 19:29:57Z pjf $

package App::Munchies::Schema::Catalog::Result::Nodes;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 741 $ =~ /\d+/gmx );
use parent qw(App::Munchies::Schema::Base);

__PACKAGE__->table('nodes');
__PACKAGE__->add_columns( 'id',  { data_type         => 'MEDIUMINT',
                                   default_value     => undef,
                                   is_auto_increment => 1,
                                   is_nullable       => 0,
                                   size              => 8, },
                          'gid', { data_type         => 'MEDIUMINT',
                                   default_value     => 0,
                                   is_nullable       => 0,
                                   size              => 8 },
                          'nid', { data_type         => 'MEDIUMINT',
                                   default_value     => 0,
                                   is_nullable       => 0,
                                   size              => 8 },
                          'lid', { data_type         => 'MEDIUMINT',
                                   default_value     => 0,
                                   is_nullable       => 0,
                                   size              => 8 } );
__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->belongs_to
   ( groups => 'App::Munchies::Schema::Catalog::Result::Names', 'gid' );
__PACKAGE__->belongs_to
   ( names  => 'App::Munchies::Schema::Catalog::Result::Names', 'nid' );
__PACKAGE__->belongs_to
   ( links  => 'App::Munchies::Schema::Catalog::Result::Links', 'lid' );

1;

__END__

=pod

=head1 Name

App::Munchies::Schema::Catalog::Result::Nodes - Class definition for the nodes table

=head1 Version

0.1.$Revision: 741 $

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
