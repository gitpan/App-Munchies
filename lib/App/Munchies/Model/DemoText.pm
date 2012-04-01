# @(#)$Id: DemoText.pm 1288 2012-03-29 00:20:38Z pjf $

package App::Munchies::Model::DemoText;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 1288 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Model CatalystX::Usul::IPC);

use CatalystX::Usul::Constants;
use CatalystX::Usul::Time;
use Date::Discordian;
use DateTime::Event::Sunrise;
use DateTime::Fiction::JRRTolkien::Shire;
use Encode;
use Text::Lorem::More;
use TryCatch;
use WWW::Wikipedia;

__PACKAGE__->config( fortune => q(fortune), insultd => q(insultd), );

__PACKAGE__->mk_accessors( qw(fortune insultd name) );

sub build_per_context_instance {
   my ($self, $c, @rest) = @_; my $s = $c->stash;

   my $new = $self->next::method( $c, @rest );

   $new->fortune( $s->{os}->{fortune}->{value} || $new->fortune );
   $new->insultd( $s->{os}->{insultd}->{value} || $new->insultd );

   return $new;
}

sub deskclock {
   my ($self, $path) = @_;

   $self->add_field( { frame_class => q(deskclock),
                       path        => $self->context->uri_for( $path ),
                       subtype     => q(html),
                       type        => q(file) } );
   return;
}

sub information {
   my $self   = shift; my ($fdate, $sun_riset, $text);

   my $c      = $self->context;
   my $data   = { values => [] };
   my ($year, $month, $day) = split SPC, time2str( q(%Y %m %d) );
   my $dt     = DateTime->new( year => $year, month => $month, day => $day );
   my $dtes   = DateTime::Event::Sunrise->new( altitude  => '-0.833',
                                               iteration => '1',
                                               longitude => '0',
                                               latitude  => '51.52' );

   $sun_riset = $dtes->sunrise_sunset_span( $dt );
   $text      = 'Sunrise '.$sun_riset->start->datetime.q(.);
   $text      =~ s{ T }{ }mx;

   push @{ $data->{values} }, { text => $text };

   my $res    = eval { $self->run_cmd( $self->fortune, { err => q(out) } ) };
   $text      = $res ? $res->out : NUL;
   $text      =~ s{ [\n] }{ }gmx;

   push @{ $data->{values} }, { text => $text };

   $fdate     = DateTime::Fiction::JRRTolkien::Shire->today();
   $fdate     = $fdate->on_date(); chomp $fdate;
   $fdate     =~ s{ [\n] }{.}gmx; $fdate =~ s{ \.\. }{. }gmx;
   $text      = "And in the Shire its $fdate";

   push @{ $data->{values} }, { text => $text };

   $fdate     = Date::Discordian->new( epoch => time );
   $fdate     = $fdate->discordian(); chomp $fdate;
   $text      = "According to the Discordians its ${fdate}.";

   push @{ $data->{values} }, { text => $text };

   $res       = eval { $self->run_cmd( $self->insultd, { err => q(out) } ) };
   $text      = $res ? $res->out : NUL;
   $text      =~ s{ [\n] }{ }gmx;

   push @{ $data->{values} }, { text => $text };

   $text      = 'Sunset  '.$sun_riset->end->datetime.q(.);
   $text      =~ s{ T }{ }mx;

   push @{ $data->{values} }, { text => $text };

   $self->add_field(  { data => $data, id => $c->action->name.q(.data) } );
   $self->stash_meta( { id   => $c->action->name } );
   return;
}

sub lock_display {
   my $self = shift; my $c = $self->context;

   $self->run_cmd( q(xdg-screensaver lock), { err => q(out) } );
   $c->res->status( 204 );
   $c->detach;
   return;
}

sub lorem {
   my ($self, $cnt, $class) = @_; my $text;

   my $sep = $class ? '</p><p class="'.$class.'">' : q(</p><p>);

   try {
      $text = scalar Text::Lorem::More::lorem->paragraph( $cnt || 3, $sep );
   }
   catch ($e) { $text = NUL.$e }

   return $text;
}

sub sampler {
   # A page containing an example of each form widget
   my $self = shift; my $c = $self->context; my $s = $c->stash;

   my $params = $c->req->parameters || {}; $s->{pwidth} -= 15;

   $self->add_field( { class     => q(ifield pintarget),
                       default   => q(%),
                       name      => q(textfield),
                       prompt    => 'This is a text field',
                       stepno    => -1,
                       tip       => 'All fields come with optional hints',
                       type      => q(textfield) } );
   $self->add_field( { field     => q(textfield),
                       href      => $s->{form}->{action}.q(_chooser),
                       name      => q(chooser),
                       stepno    => q(none),
                       tip       =>
                          'Press the button to popup the selection window',
                       tiptype   => q(normal),
                       type      => q(chooser) } );
   $self->add_field( { clear     => q(left),
                       href      => $s->{form}->{action},
                       name      => q(anchor),
                       prompt    => 'This is an anchor',
                       stepno    => -1,
                       text      => q(Click),
                       tip       => 'Where do you want to go today?',
                       type      => q(anchor) } );
   $self->add_field( { checked   => q(checked),
                       clear     => q(left),
                       labels    => { 1 => q(Label) },
                       name      => q(checkbox),
                       prompt    => 'This is a checkbox',
                       stepno    => -1,
                       type      => q(checkbox),
                       value     => 1 } );
   $self->add_field( { clear     => q(left),
                       name      => q(date),
                       prompt    => 'This is a date field',
                       stepno    => -1,
                       type      => q(date) } );
   $self->add_field( { clear     => q(left),
                       name      => q(file),
                       path      => q(/etc/motd),
                       pclass    => q(prompt_compact),
                       prompt    => 'This is a file',
                       sep       => q(break),
                       stepno    => -1,
                       subtype   => q(text),
                       type      => q(file) } );
   $self->add_field( { clear     => q(left),
                       name      => q(freelist),
                       prompt    => 'This is a free list',
                       stepno    => -1,
                       type      => q(freelist),
                       values    => [ qw(Item1 Item2) ] } );
   $self->add_field( { all       => [ qw(Item1 Item2) ],
                       clear     => q(left),
                       current   => [ qw(Item3 Item4) ],
                       name      => q(groupmembership),
                       prompt    => 'This is group membership',
                       stepno    => -1,
                       type      => q(groupMembership) } );
   $self->add_field( { clear     => q(left),
                       name      => q(Save),
                       prompt    => 'This is an image button',
                       src       => q(Save.png),
                       stepno    => -1,
                       tip       => 'This is a handy hint',
                       type      => q(button) } );
   $self->add_field( { class     => q(label_text pintarget),
                       clear     => q(left),
                       name      => q(label),
                       prompt    => 'This is a label',
                       stepno    => -1,
                       text      => 'An informative label',
                       type      => q(label) } );
   $self->add_field( { class     => q(note pintarget),
                       clear     => q(left),
                       name      => q(note),
                       stepno    => -1,
                       text      => 'An informative note',
                       type      => q(note), } );

   my $data = [ { content => 'List item one',   },
                { content => 'List item two',   },
                { content => 'List item three', },
                { content => 'List item four',  },
                { content => 'List item five',  },
                { content => 'List item six',   },
                { content => 'List item seven', },
                { content => 'List item eight', },
                { content => 'List item nine',  },
                { content => 'List item ten',   }, ];

   $self->add_field( { class     => q(rotate),
                       clear     => q(left),
                       config    => { direction => 'down', nitems => 1,
                                      speed     => 2000 },
                       data      => $data,
                       name      => q(list),
                       prompt    => 'This is a rotating list',
                       stepno    => -1,
                       type      => q(list), } );

   $self->add_field( { clear     => q(left),
                       id        => q(password1),
                       prompt    => 'This is a password',
                       stepno    => -1,
                       subtype   => q(verify),
                       type      => q(password) } );
   $self->add_field( { clear     => q(left),
                       labels    => { 1 => q(Label1), 2  => q(Label2),
                                      3 => q(Label3), 4  => q(Label4),
                                      5 => q(Label5), 6  => q(Label6),
                                      7 => q(Label7), 8  => q(Label8),
                                      9 => q(Label9), 10 => q(Label10), },
                       name      => q(popupMenu1),
                       prompt    => 'This is a popup menu',
                       stepno    => -1,
                       tip       => 'This is a handy hint',
                       type      => q(popupMenu),
                       values    => [ NUL, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] } );
   $self->add_field( { class     => q(chzn-select ifield),
                       clear     => q(left),
                       labels    => { 1 => q(Label1), 2  => q(Label2),
                                      3 => q(Label3), 4  => q(Label4),
                                      5 => q(Label5), 6  => q(Label6),
                                      7 => q(Label7), 8  => q(Label8),
                                      9 => q(Label9), 10 => q(Label10), },
                       name      => q(popupMenu2),
                       prompt    => 'This is a Javascript popup menu',
                       stepno    => -1,
                       tip       => 'This is a handy hint',
                       type      => q(popupMenu),
                       values    => [ NUL, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] } );
   $self->add_field( { clear     => q(left),
                       columns   => 3,
                       labels    => { 1 => q(One),   2 => q(Two),
                                      3 => q(Three), 4 => q(Four),
                                      5 => q(Five),  6 => q(Six) },
                       name      => q(radiogroup),
                       prompt    => 'This is a radio group',
                       stepno    => -1,
                       type      => q(radioGroup),
                       values    => [ 1, 2, 3, 4, 5, 6 ] } );
   $self->add_field( { class     => q(cut_here),
                       clear     => q(left),
                       name      => q(rule),
                       prompt    => 'This is a rule',
                       stepno    => -1,
                       type      => q(rule) } );
   $self->add_field( { clear     => q(left),
                       labels    => { 1 => q(Label1), 2  => q(Label2),
                                      3 => q(Label3), 4  => q(Label4),
                                      5 => q(Label5), 6  => q(Label6),
                                      7 => q(Label7), 8  => q(Label8),
                                      9 => q(Label9), 10 => q(Label10), },
                       name      => q(scrollinglist1),
                       prompt    => 'This is a scrolling list',
                       stepno    => -1,
                       type      => q(scrollingList),
                       values    => [ NUL, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] } );
   $self->add_field( { class     => q(chzn-select ifield),
                       clear     => q(left),
                       labels    => { 1 => q(Label1), 2  => q(Label2),
                                      3 => q(Label3), 4  => q(Label4),
                                      5 => q(Label5), 6  => q(Label6),
                                      7 => q(Label7), 8  => q(Label8),
                                      9 => q(Label9), 10 => q(Label10), },
                       name      => q(scrollinglist2),
                       prompt    => 'This is a Javascript scrolling list',
                       stepno    => -1,
                       type      => q(scrollingList),
                       values    => [ NUL, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] } );
   $self->add_field( { clear     => q(left),
                       default   => 50,
                       name      => q(slider),
                       prompt    => 'This is a slider',
                       stepno    => -1,
                       type      => q(slider) } );
   $self->add_field( { clear     => q(left),
                       data      => {
                          flds   => [ qw(field1 field2) ],
                          labels => { field1 => q(Label1),
                                      field2 => q(Label2) },
                          sizes  => { field1 => 20,
                                      field2 => 20 },
                          values => [ { field1 => q(Row1 Value1),
                                        field2 => q(Row1 Value2) },
                                      { field1 => q(Row2 Value1),
                                        field2 => q(Row2 Value2) } ] },
                       edit      => q(right),
                       name      => q(table),
                       prompt    => 'This is a table',
                       select    => q(right),
                       sortable  => TRUE,
                       stepno    => -1,
                       type      => q(table) } );
   $self->add_field( { class     => q(autosize ifield),
                       clear     => q(left),
                       name      => q(textarea),
                       prompt    => 'This is a text area',
                       stepno    => -1,
                       type      => q(textarea) } );

   $data = {
      'Root Folder'           => {
         'Label One'          => {
            _tip              => q(Help text for label one),
            'Label Three'     => {
               _tip           => q(Help text for label three),
               'Label Four'   => {
                  _tip        => q(Help text for label four),
                  'Label Six' => {
                     _tip     => q(Help text for label six) }, },
               'Label Five'   => {
                  _tip        => q(Help text for label five) },
               'Label Seven'  => {
                  _tip        => q(Help text for label seven) }, },
            'Label Eight'     => {
               _tip           => q(Help text for label eight) }, },
         'Label Two'          => {
            _tip              => q(Help text for label two) },
      } };

   $self->add_field( { class     => q(pintarget),
                       clear     => q(left),
                       data      => $data,
                       name      => q(tree),
                       prompt    => 'This is a tree',
                       selected  => $params->{tree_node},
                       stepno    => -1,
                       type      => q(tree) } );

   $self->group_fields( { text   => q(Sample Widgets) } );
   $self->add_field   ( { id     => q(content_pintray),
                          type   => q(scrollPin) } );
   $self->add_buttons ( qw(Markup Text Energise) );
   return;
}

sub sampler_chooser {
   my $self  = shift;
   my $c     = $self->context;
   my $nav   = $c->model( q(Navigation) );
   my $field = $self->query_value( q(field) ) || NUL;
   my $form  = $self->query_value( q(form)  ) || NUL;
   my $value = $self->query_value( q(value) ) || NUL;
   my $tip   = 'Close this window and leave the field value unchanged';

   $nav->clear_controls;
   $nav->add_menu_close( { field     => $field,
                           form      => $form,
                           tip       => $self->loc( $tip ),
                           value     => $value } );
   $self->add_chooser  ( { attr      => q(name),
                           field     => $field,
                           form      => $form,
                           method    => q(sampler_search),
                           value     => $value,
                           where_fld => NUL,
                           where_val => NUL } );
   return;
}

sub sampler_search {
   my ($self, $args) = @_; my @rows;

   for my $name ( qw(One Two Three) ) {
      push @rows, bless { name => $name }, __PACKAGE__;
   }

   return @rows
}

sub test_card {
   my $self = shift;

   $self->add_field( { class => q(centre),
                       name  => q(test_card), type => q(label) } );
   return;
}

sub wikipedia {
   my $self = shift;
   my $c    = $self->context;
   my $s    = $c->stash;
   my $wiki = WWW::Wikipedia->new();
   my $term = (join q(+), @{ $c->req->arguments }) || q(perl);
   my $res  = $wiki->search( $term );
   my $text = $res ? decode( q(utf-8), $res->text ) : q(duh);
   my $data = { values => [] };
   my $para;

   $text =~ s{ <!-- [^>]+ > }{ }gmx;
   $text =~ s{ <ref [^>]+ > }{ }gmx;
   $text =~ s{ <ref>        }{ }gmx;
   $text =~ s{ </ref>       }{ }gmx;
   $text =~ s{ \{\{         }{ }gmx;
   $text =~ s{ \}\}         }{ }gmx;

   for my $line (split m{ \n }mx, $text) {
      if    (length $line) { $para .= q( ).$line }
      elsif ($para) {
         push @{ $data->{values} }, { text => $para }; $para = NUL;
      }
   }

   $para and push @{ $data->{values} }, { text => $para };

   my $col_class = $self->get_para_col_class( 2 );
   my $heading   = $self->loc( 'Wiki entry for [_1]', ucfirst $term );

   $self->clear_form( { heading         => $heading } );
   $self->add_field ( { column_class    => $col_class,
                        container_class => q(paragraphs),
                        data            => $data,
                        frame_class     => q(prominent),
                        name            => q(wiki),
                        type            => q(paragraphs) } );
   return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::DemoText - Demonstration model

=head1 Version

0.6.$Revision: 1288 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 build_per_context_instance

=head2 deskclock

=head2 information

=head2 lock_display

Locks the display by running the external screensaver command

=head2 lorem

=head2 sampler

=head2 sampler_chooser

=head2 sampler_search

=head2 test_card

=head2 wikipedia

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<CatalsyX::Usul::Model>

=item L<Date::Discordian>

=item L<DateTime::Event::Sunrise>

=item L<DateTime::Fiction::JRRTolkien::Shire>

=item L<Text::Lorem::More>

=item L<WWW::Wikipedia>

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
