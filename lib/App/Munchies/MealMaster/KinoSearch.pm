# @(#)$Id: KinoSearch.pm 1318 2012-04-22 17:10:47Z pjf $

package App::Munchies::MealMaster::KinoSearch;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.7.%d', q$Rev: 1318 $ =~ /\d+/gmx );
use parent qw(Class::Accessor::Fast);

use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::FieldType::FullTextType;
use KinoSearch::FieldType::StringType;
use KinoSearch::Highlight::Highlighter;
use KinoSearch::Indexer;
use KinoSearch::QueryParser;
use KinoSearch::Schema;
use KinoSearch::Search::SortRule;
use KinoSearch::Search::SortSpec;
use KinoSearch::Searcher;
use Scalar::Util qw(blessed);

__PACKAGE__->mk_accessors( qw(list total_hits) );

sub new {
   my ($self, $path) = @_;

   my $schema       =  KinoSearch::Schema->new;
   my $polyanalyzer =  KinoSearch::Analysis::PolyAnalyzer->new
      ( language    => q(en) );
   my $full_text    =  KinoSearch::FieldType::FullTextType->new
      ( analyzer    => $polyanalyzer, highlightable => 1 );
   my $non_indexed  =  KinoSearch::FieldType::StringType->new
      ( indexed     => 0 );
   my $sortable     =  KinoSearch::FieldType::StringType->new
      ( sortable    => 1 );

   $schema->spec_field( name => q(title),       type => $full_text   );
   $schema->spec_field( name => q(ingredients), type => $full_text   );
   $schema->spec_field( name => q(key),         type => $sortable    );
   $schema->spec_field( name => q(file),        type => $non_indexed );

   return KinoSearch::Indexer->new
      ( create => 1, index => $path, schema => $schema );
}

sub search_for {
   my ($self, $args) = @_; $args ||= {};

   my $hits_per     =  $args->{hits_per} || 64;
   my $page         =  $args->{page    } || 0;
   my $searcher     =  KinoSearch::Searcher->new( index => $args->{invindex} );
   my $field_rule   =  KinoSearch::Search::SortRule->new( field => q(key)    );
   my $score_rule   =  KinoSearch::Search::SortRule->new( type  => q(score)  );
   my $doc_id_rule  =  KinoSearch::Search::SortRule->new( type  => q(doc_id) );
   my $sort_spec    =  KinoSearch::Search::SortSpec->new
      ( rules       => [ $field_rule, $score_rule, $doc_id_rule ], );
   my $query_parser =  KinoSearch::QueryParser->new
      ( fields      => [ $args->{search_field} ],
        schema      => $searcher->get_schema );
   my $query        =  $query_parser->parse( '"'.($args->{query} || q()).'"' );
   my $hits         =  $searcher->hits( num_wanted => $hits_per,
                                        offset     => $hits_per * $page,
                                        query      => $query,
                                        sort_spec  => $sort_spec );
   my $highlighter  =  $args->{search_field} ne q(title)
                    ?  KinoSearch::Highlight::Highlighter->new
                        ( field    => $args->{search_field},
                          query    => $query,
                          searcher => $searcher, )
                    :  0;
   my $class        =  blessed $self || $self;
   my $new          =  bless { list       => [],
                               total_hits => $hits->total_hits }, $class;

   while (my $hit = $hits->next) {
      my $hash = $hit->get_fields;

      $highlighter and $hash->{excerpt} = $highlighter->create_excerpt( $hit );
      $hash->{score} = $hit->get_score;
      push @{ $new->list }, $hash;
   }

   return $new;
}

1;

__END__

=pod

=head1 Name

App::Munchies::MealMaster::KinoSearch - Text search model for food recipes in MMF format

=head1 Version

0.7.$Revision: 1318 $

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
