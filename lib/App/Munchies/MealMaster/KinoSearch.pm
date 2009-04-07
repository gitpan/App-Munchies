package App::Munchies::MealMaster::KinoSearch;

# @(#)$Id: KinoSearch.pm 643 2009-04-06 23:07:37Z pjf $

use strict;
use warnings;

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 643 $ =~ /\d+/gmx );

package # Hide from indexer
   MealMaster::KinoSearch::Schema::NoAnalNoVector;

use base qw(KinoSearch::Schema::FieldSpec);

sub analyzed   { return 0 }

sub vectorized { return 0 }

package # Hide from indexer
   MealMaster::KinoSearch::Schema::NoAnalNoIndexNoVector;

use base qw(KinoSearch::Schema::FieldSpec);

sub analyzed   { return 0 }

sub indexed    { return 0 }

sub vectorized { return 0 }

package # Hide from indexer
   MealMaster::KinoSearch::Schema;

use base qw(KinoSearch::Schema);
use KinoSearch::Analysis::PolyAnalyzer;

our %fields = (
    title       => __PACKAGE__.q(::NoAnalNoVector),
    ingredients => q(KinoSearch::Schema::FieldSpec),
    url         => __PACKAGE__.q(::NoAnalNoIndexNoVector),
    file        => __PACKAGE__.q(::NoAnalNoIndexNoVector),
    key         => __PACKAGE__.q(::NoAnalNoIndexNoVector),
);

sub analyzer {
   return KinoSearch::Analysis::PolyAnalyzer->new( language => q(en) );
}

package # Hide from indexer
   App::Munchies::MealMaster::KinoSearch;

use KinoSearch::Highlight::Highlighter;
use KinoSearch::InvIndexer;
use KinoSearch::Search::SortSpec;
use KinoSearch::Searcher;

sub new {
   my ($self, @rest) = @_;

   return KinoSearch::InvIndexer->new(
      invindex => MealMaster::KinoSearch::Schema->open( @rest ) );
}

sub search_for {
   my ($self, $args, $expression, $hits_per_page, $offset) = @_;
   my ($highlighter, $hits, $searcher, $sort_spec);

   $expression    ||= q();
   $offset        ||= 0;
   $hits_per_page ||= 64;
   $searcher  = KinoSearch::Searcher->new(
       invindex => MealMaster::KinoSearch::Schema->read( $args->{invindex} ) );
   $sort_spec = KinoSearch::Search::SortSpec->new();
   $sort_spec->add( field => $args->{sort_field} );
   $hits = $searcher->search( num_wanted => $hits_per_page,
                              offset     => $offset * $hits_per_page,
                              query      => $expression,
                              sort_spec  => $sort_spec  );
   $highlighter = KinoSearch::Highlight::Highlighter->new();
   $highlighter->add_spec( field => $args->{highlight_field} );
   $hits->create_excerpts( highlighter => $highlighter );
   return $hits;
}

1;

__END__

=pod

=head1 Name

App::Munchies::MealMaster::KinoSearch - Text search model for food recipes in MMF format

=head1 Version

0.1.$Revision: 643 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 new

=head2 search_for

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
