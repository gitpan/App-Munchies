package App::Munchies::Model::Authentication;

# @(#)$Id: Authentication.pm 563 2008-12-11 00:06:12Z pjf $

use strict;
use warnings;
use base qw(CatalystX::Usul::Model::Schema);
use Class::C3;

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 563 $ =~ /\d+/gmx );

__PACKAGE__->config
   ( connect_info => [],
     database     => q(library),
     schema_class => q(App::Munchies::Schema::Authentication) );

sub new {
   my ($class, $app, @rest) = @_;

   my $database = $rest[0]->{database} || $class->config->{database};

   $class->config( connect_info => $class->connect_info( $app, $database ) );

   return $class->next::method( $app, @rest );
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::Authentication - Database authentication class

=head1 Version

0.1.$Revision: 563 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 new

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
