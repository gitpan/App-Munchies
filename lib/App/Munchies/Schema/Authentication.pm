# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-03-04 02:50:46
# @(#)$Id: Authentication.pm 1318 2012-04-22 17:10:47Z pjf $

package App::Munchies::Schema::Authentication;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use parent qw(DBIx::Class::Schema);

use File::Spec;

__PACKAGE__->load_classes;

sub ddl_filename {
    my ($self, $type, $version, $dir, $preversion) = @_;

    ($dir, $version) = ($version, $dir) if ($DBIx::Class::VERSION < 0.08100);

    (my $filename = (ref $self || $self)) =~ s{ :: }{-}gmx;
    $version = join q(.), (split m{ [.] }mx, $version)[ 0, 1 ];
    $preversion and $version = $preversion.q(-).$version;
    return File::Spec->catfile( $dir, "$filename-$version-$type.sql" );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Schema::Authentication - Schema base class

=head1 Version

0.7.$Revision: 1318 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 ddl_filename

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
