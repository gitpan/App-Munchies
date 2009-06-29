# @(#)$Id: DemoText.pm 757 2009-06-11 16:42:06Z pjf $

package App::Munchies::Model::DemoText;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 757 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Model);

use Date::Discordian;
use DateTime::Event::Sunrise;
use DateTime::Fiction::JRRTolkien::Shire;
use Encode;
use Text::Lorem::More;
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
   my $self = shift;
   my $c    = $self->context;
   my $path = $c->uri_for( q(/static/svg/SiemensClock.svg) );

   $self->add_field( { class   => q(centre fullWidth),
                       path    => $path,
                       style   => q(margin-left: -256px;),
                       subtype => q(html),
                       type    => q(file) } );
   return;
}

sub information {
   my $self   = shift; my ($day, $fdate, $month, $sun_riset, $text, $year);

   my $data   = { values => [] }; my $c = $self->context;

   ($year, $month, $day) = split q( ), $self->time2str( q(%Y %m %d), time );
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
   $text      = $res ? $res->out : q();
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
   $text      = $res ? $res->out : q();
   $text      =~ s{ [\n] }{ }gmx;

   push @{ $data->{values} }, { text => $text };

   $text      = 'Sunset  '.$sun_riset->end->datetime.q(.);
   $text      =~ s{ T }{ }mx;

   push @{ $data->{values} }, { text => $text };

   $self->add_field(  { data => $data, id => $c->action->name.q(.data) } );
   $self->stash_meta( { id   => $c->action->name } );
   delete $c->stash->{token};
   return;
}

sub lorem {
   my ($self, $cnt) = @_;

   return scalar Text::Lorem::More::lorem->paragraph( $cnt || 3, q(</p><p>) );
}

sub sampler {
   # A page containing an example of each form widget
   my $self = shift; my $c = $self->context; my $s = $c->stash;

   my $nitems = 0; my $step = 1;

   $s->{pwidth} -= 15; my $params = $c->req->parameters || {};

   $self->add_field( { clear     => q(left),
                       default   => q(%),
                       name      => q(textfield),
                       prompt    => 'This is a text field',
                       stepno    => $step++,
                       tip       => 'All fields come with optional hints',
                       type      => q(textfield) } ); $nitems++;
   $self->add_field( { button    => q(Choose),
                       clear     => q(left),
                       field     => q(textfield),
                       height    => 500,
                       href      => $s->{form}->{action}.q(_chooser),
                       key       => q(Save),
                       name      => q(chooser),
                       prompt    => 'This is a popup window selector',
                       stepno    => $step++,
                       tip       =>
                          'Press the button to popup the selection window',
                       tiptype   => q(normal),
                       type      => q(chooser),
                       width     => 400 } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       href      => $s->{form}->{action},
                       name      => q(anchor),
                       prompt    => 'This is an anchor',
                       stepno    => $step++,
                       text      => q(Click),
                       tip       => 'Where do you want to go today?',
                       type      => q(anchor) } ); $nitems++;
   $self->add_field( { checked   => q(checked),
                       clear     => q(left),
                       labels    => { 1 => q(Label) },
                       name      => q(checkbox),
                       prompt    => 'This is a checkbox',
                       stepno    => $step++,
                       type      => q(checkbox),
                       value     => 1 } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       name      => q(date),
                       prompt    => 'This is a date field',
                       stepno    => $step++,
                       type      => q(date) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       name      => q(file),
                       path      => q(/etc/motd),
                       prompt    => 'This is a file',
                       stepno    => $step++,
                       subtype   => q(logfile),
                       type      => q(file) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       labels    => { 1 => q(Item1), 2 => q(Item2) },
                       name      => q(freelist),
                       prompt    => 'This is a free list',
                       stepno    => $step++,
                       type      => q(freelist),
                       values    => [ qw(1 2) ] } ); $nitems++;
   $self->add_field( { all       => [ qw(Item1 Item2) ],
                       clear     => q(left),
                       current   => [ qw(Item3 Item4) ],
                       name      => q(groupmembership),
                       prompt    => 'This is group membership',
                       stepno    => $step++,
                       type      => q(groupMembership) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       name      => q(Save),
                       prompt    => 'This is an image button',
                       src       => q(Save.png),
                       stepno    => $step++,
                       tip       => 'Handy Hint ~ This is a handy hint',
                       type      => q(button) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       name      => q(label),
                       prompt    => 'This is a label',
                       stepno    => $step++,
                       text      => 'An informative label',
                       type      => q(label) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       name      => q(note),
                       align     => q(right),
                       stepno    => $step++,
                       text      => 'An informative note',
                       type      => q(note),
                       width     => q(40%) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       id        => q(password1),
                       prompt    => 'This is a password',
                       stepno    => $step++,
                       subtype   => q(verify),
                       type      => q(password) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       labels    => { 1 => q(Label1), 2 => q(Label2) },
                       name      => q(popupMenu),
                       prompt    => 'This is a popup menu',
                       stepno    => $step++,
                       tip       => q(Handy Hint ~ This is a handy hint),
                       type      => q(popupMenu),
                       values    => [ q(), 1, 2 ] } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       columns   => 3,
                       labels    => { 1 => q(One),   2 => q(Two),
                                      3 => q(Three), 4 => q(Four),
                                      5 => q(Five),  6 => q(Six) },
                       name      => q(radiogroup),
                       prompt    => 'This is a radio group',
                       stepno    => $step++,
                       type      => q(radioGroup),
                       values    => [ 1, 2, 3, 4, 5, 6 ] } ); $nitems++;
   $self->add_field( { class     => q(footer),
                       clear     => q(left),
                       name      => q(rule),
                       prompt    => 'This is a rule',
                       stepno    => $step++,
                       type      => q(rule) } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       labels    => { 1 => q(Label1), 2 => q(Label2) },
                       name      => q(scrollinglist),
                       prompt    => 'This is a scrolling list',
                       stepno    => $step++,
                       type      => q(scrollingList),
                       values    => [ q(), 1, 2 ] } ); $nitems++;
   $self->add_field( { clear     => q(left),
                       default   => 50,
                       name      => q(slider),
                       prompt    => 'This is a slider',
                       stepno    => $step++,
                       type      => q(slider) } ); $nitems++;
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
                           edit      => 1,
                       name      => q(table),
                       prompt    => 'This is a table',
                       stepno    => $step++,
                       select    => q(right),
                       type      => q(table) } ); $nitems++;
# TODO: Add Template example
   $self->add_field( { clear     => q(left),
                       name      => q(textarea),
                       prompt    => 'This is a text area',
                       stepno    => $step++,
                       type      => q(textarea) } ); $nitems++;

   my $data = {
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

   $self->add_field( { clear     => q(left),
                       data      => $data,
                       name      => q(tree),
                       prompt    => 'This is a tree',
                       selected  => $params->{tree_node},
                       stepno    => $step++,
                       type      => q(tree) } ); $nitems++;

   $self->group_fields( { nitems => $nitems, text => q(Sample Widgets) } );
   $self->add_buttons(  qw(Save) );
   return;
}

sub sampler_chooser {
   my $self  = shift;
   my $field = q(textfield);
   my $form  = $self->query_value( q(form) ) || q();
   my $value = $self->query_value( q(value) ) || q();

   $self->add_chooser( { attr      => q(name),
                         button    => q(Select),
                         class     => q(chooserFade),
                         field     => $field,
                         form      => $form,
                         method    => q(sampler_search),
                         value     => $value,
                         where_fld => q(),
                         where_val => q() } );

   my $nav_model = $self->context->model( q(Navigation) );
   my $jscript   = "behaviour.submit.returnValue('";
      $jscript  .= "${form}', '${field}', '${value}') ";
   my $tip = 'Close this popup window and leave the field value unchanged';
   my $e;

   eval {
      $nav_model->clear_controls;
      $nav_model->add_menu_close( { onclick => $jscript,
                                    tip     => $self->loc( $tip ) } );
   };

   $self->add_error( $e ) if ($e = $self->catch);

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
         push @{ $data->{values} }, { text => $para }; $para = q();
      }
   }

   push @{ $data->{values} }, { text => $para } if ($para);

   my $columns   = 2;
   my $col_class = ($columns > 1 ? q(multi) : q(one)).q(Column);
   my $heading   = 'Wiki entry for '.(ucfirst $term);

   $self->clear_form( { heading         => $heading } );
   $self->add_field ( { class           => q(fullWidth),
                        column_class    => $col_class,
                        columns         => $columns,
                        container       => 1,
                        container_class => q(paragraphs centre),
                        data            => $data,
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

0.3.$Revision: 757 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 build_per_context_instance

=head2 deskclock

=head2 information

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
