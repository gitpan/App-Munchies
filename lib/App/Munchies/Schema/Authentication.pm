package App::Munchies::Schema::Authentication;

# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-03-04 02:50:46
# @(#)$Id: Authentication.pm 515 2008-10-04 14:20:40Z pjf $

use strict;
use warnings;
use base qw(DBIx::Class::Schema);

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 515 $ =~ /\d+/gmx );

__PACKAGE__->load_classes;

# Must send patch to mst

sub ddl_filename {
    my ($self, $type, $dir, $version) = @_;

    (my $filename = (ref $self || $self)) =~ s{ :: }{-}gmx;
    $version = join q(.), (split m{ [.] }mx, $version)[ 0, 1 ];
    return "$dir$filename-$version-$type.sql";
}

1;

__END__

=pod

=head1 Name

<Module::Name> - <One-line description of module's purpose>

=head1 Version

0.1.$Revision: 515 $

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
