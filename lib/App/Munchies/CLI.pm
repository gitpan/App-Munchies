# @(#)$Id: CLI.pm 1261 2011-11-30 17:05:50Z pjf $

package App::Munchies::CLI;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1261 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::CLI);

use CatalystX::Usul::Constants;
use CatalystX::Usul::Time;
use File::Gettext;
use File::Spec;

sub convert_messages : method {
   my $self     = shift;
   my $lang     = q(en);
   my $rev_date = time2str "%Y-%m-%d %H:%M +%Z";
   my $charset  = q(UTF-8);
   my $header   = {
      'translator_comment' =>
         [ '@(#)$Id'.'$',
           'GNU Gettext Portable Object.',
           'Copyright (C) 2011 RoxSoft.',
           'Lazarus Long <Support@RoxSoft.co.uk>, 2011.',
           '', ],
      flags     => [ 'fuzzy', ],
      msgstr    => {
         'project_id_version'        => "App::Munchies ${VERSION}",
         'po_revision_date'          => $rev_date,
         'last_translator'           => 'Athena <Support@RoxSoft.co.uk>',
         'language_team'             => 'English <Support@RoxSoft.co.uk>',
         'language'                  => $lang,
         'mime_version'              => '1.0',
         'content_type'              => 'text/plain; charset='.$charset,
         'content_transfer_encoding' => '8bit',
         'plural_forms'              => 'nplurals=2; plural=(n != 1);', }, };

   for my $dn (qw(default entrance admin library)) {
      my $order  = 1;
      my $data   = { po => {}, po_header => $header };
      my $file   = "${dn}_${lang}";
      my $schema = File::DataClass::Schema->new
         ( path                     => [ qw(var etc), "${file}.xml" ],
           result_source_attributes => {
              action                => {
                 attributes         => [ qw(keywords text tip) ], },
              buttons               => {
                 attributes         => [ qw(error help prompt) ], },
              fields                => {
                 attributes         => [ qw(atitle ctitle fhelp
                                            prompt text tip) ], },
              messages              => {
                 attributes         => [ qw(text) ], },
              namespace             => {
                 attributes         => [ qw(text tip) ], }, },
           tempdir                  => q(t), );
      my $rs     = $schema->resultset( q(messages) )->search( {} );

      for my $msg (sort { $a->name cmp $b->name } $rs->all) {
         my $v = $msg->text or next;

         $data->{po}->{ $msg->name } = { msgid  => $msg->name,
                                         msgstr => [ $msg->text ] };
      }

      my $path    = [ qw(var etc), "${file}.po" ];
      my $gettext = File::Gettext->new( charset => $charset, path => $path,
                                        tempdir => q(t), );

      for my $source (qw(action buttons fields namespace)) {
         $rs = $schema->resultset( $source )->search( {} );

         for my $msg (sort { $a->name cmp $b->name } $rs->all) {
            for my $attr (@{ $schema->source( $source )->attributes }) {
               my $v    = $msg->$attr() or next;
               my $rec  = { msgctxt => $source.q(.).$attr,
                            msgid   => $msg->name,
                            msgstr  => [ $v ] };
               my $k    = $gettext->storage->make_key( $rec );

               exists $data->{po}->{ $k } and warn "Duplicate ${k}\n";
               $data->{po}->{ $k } = $rec;
            }
         }
      }

      for my $k (sort keys %{ $data->{po} }) {
         $data->{po}->{ $k }->{_order} = $order++;
      }

      $gettext->dump( { data => $data } );

      my $cmd  = q(msgfmt --no-hash -o );
         $cmd .= $self->catfile( qw(var locale),
                                 $lang, q(LC_MESSAGES), "${dn}.mo" );
         $cmd .= SPC.$self->catfile( @{ $path } );

      qx( $cmd );
   }

   unlink $self->catfile( qw(t ipc_srlock.lck) );
   unlink $self->catfile( qw(t ipc_srlock.shm) );
   unlink $self->catfile( qw(t file-dataclass-schema.dat) );
   return OK;
}

1;

__END__

=pod

=head1 Name

App::Munchies::CLI - Subroutines accessed from the command line

=head1 Version

0.5.$Revision: 1261 $

=head1 Synopsis

   #!/usr/bin/perl

   use App::Munchies::CLI;

   exit App::Munchies::CLI->new( appclass => q(App::Munchies) )->run;

=head1 Description

Implements methods available to the command line interface. Inherits from
L<CatalystX::Usul::CLI>

=head1 Subroutines/Methods

=head2 convert_messages

=head1 Diagnostics

None

=head1 Configuration and Environment

None

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::CLI>

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

Copyright (c) 2011 Peter Flanigan. All rights reserved

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
