package App::Munchies::Model::Catalog;

# @(#)$Id: Catalog.pm 639 2009-04-05 17:47:16Z pjf $

use strict;
use warnings;
use base qw(CatalystX::Usul::Model::Schema);
use Class::C3;
use Data::CloudWeights;
use HTML::Accessors;

use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 639 $ =~ /\d+/gmx );

__PACKAGE__->config( connect_info => [],
                     database     => q(library),
                     schema_class => q(App::Munchies::Schema::Catalog) );

__PACKAGE__->mk_accessors( qw(binsdir) );

my $NUL = q();
my $SEP = q(/);

sub new {
   my ($class, $app, @rest) = @_;

   my $database = $rest[0]->{database} || $class->config->{database};

   $class->config( connect_info => $class->connect_info( $app, $database ) );

   my $self = $class->next::method( $app, @rest );

   $self->binsdir(  $app->config->{binsdir} );
   $self->encoding( $app->config->{encoding} );
   return $self;
}

sub add_links_to_subject {
   my ($self, $args) = @_; my $s = $self->context->stash; my ($msg, $subject);

   $self->throw( q(eNoSubject) ) unless ($subject = $args->{subject});

   for my $lid (@{ $self->query_array( $args->{field} ) }) {
      my $ref  = { gid => $subject, nid => 1, lid => $lid };
      my $res  = $s->{model}->{nodes}->create( $ref );
      my $link = $s->{model}->{links}->find( $lid )->text;

      $msg .= $msg ? q(, ).$link : $link;
   }

   $subject = $s->{model}->{names}->{ $subject };
   $self->add_result_msg( q(links_added), $subject, $msg );
   return;
}

sub browse {
   my ($self, $id, $url) = @_; my $s = $self->context->stash;

   $self->clear_form; $s->{menus}->[0]->{selected} = 1;

   # TODO: Move this to Navigation plugin
   # Create a menu item for ourselves on the fly
   unshift @{ $s->{menus}->[1]->{items} }, {
      content => { class     => q(menuSelectedFade),
                   container => 0,
                   href      => $s->{form}->{action}.$SEP.$id,
                   text      => 'Browse',
                   tip       => $url,
                   type      => q(anchor),
                   widget    => 1 } };

   $self->add_field( { path => $url, subtype => q(html), type => q(file) } );
   return;
}

sub catalog_form {
   my ($self, $args) = @_;
   my ($catalogs, $labels, $nid, $node, $subject, $subjects);

   my $c         = $self->context;
   my $s         = $c->stash;
   my $nodes     = $args->{nodes};
   my $namespace = $c->action->namespace;
   my $form      = $s->{form}->{name};
   my $size      = $s->{size}    || 10;
   my $span      = $s->{columns} || 3;
   my $width     = int (int ($s->{width} - (50 * $span)) / $span);

   $width = 100 if ($width < 100);

   # Read data from model
   for $node ($nodes->search({ gid => 2 }, { join     => [ qw(names) ],
                                             order_by => q(names.text) })) {
      if ($nid = $node->nid) {
         $labels->{ $nid } = $node->names->text if ($node->names->text);
         push @{ $catalogs }, $nid;
      }
   }

   unshift @{ $catalogs }, 0; $labels->{0} = $NUL;

   for $node ($nodes->search( { gid      => $args->{catalog} },
                              { join     => [ qw(names) ],
                                order_by => q(names.text) } )) {
      if ($nid = $node->nid) {
         $labels->{ $nid } = $node->names->text if ($node->names->text);
         push @{ $subjects }, $nid;
      }
   }

   my $text = $self->loc( q(catalogInstructions) );

   $self->clear_form( { subHeading => { content => $text } } );

   if ($args->{cat_type} eq q(cloud)) {
      my $ref   = $args->{col_type} eq q(pallet)
                ? { cold_colour => $NUL } : {};
      my $cloud = Data::CloudWeights->new( $ref );

      $cloud->sort_field( $args->{sort_field} );

      if ($args->{sort_field} eq q(count)) {
         $cloud->sort_type( q(numeric) ); $cloud->sort_order( q(desc) );
      }

      for $subject (@{ $subjects }) {
         my $num_subjects = $nodes->count( { gid => $subject } );

         next unless ($num_subjects > $args->{min_count});

         $cloud->add( $labels->{ $subject },
                      $num_subjects,
                      { class_pref => $namespace,
                        id_pref    => $c->action->name,
                        labels     => $labels,
                        name       => $subject,
                        table_len  => $size,
                        total      => $num_subjects,
                        width      => $width } );
      }

      $self->add_field( { class => $namespace.q(Cloud),
                          data  => $cloud->formation,
                          type  => q(cloud) } );
   }
   else {
      my $fld_no = 0;

      for $subject (@{ $subjects }) {
         $self->add_field( $self->normal_field( { fld_no => $fld_no,
                                                  labels => $labels,
                                                  size   => $size,
                                                  span   => $span,
                                                  value  => $subject,
                                                  width  => $width } ) );
         $fld_no++;
      }
   }

   # Add fields to the append div
   $self->add_append( { default => $args->{catalog},
                        labels  => $labels,
                        id      => $form.q(.catalog),
                        pwidth  => 6,
                        sep     => q(&nbsp;),
                        values  => $catalogs } );
   $self->add_append( { default => $args->{cat_type},
                        id      => $form.q(.catalog_type),
                        labels  => { cloud => q(Cloud), normal => q(Normal) },
                        pwidth  => 10,
                        sep     => q(&nbsp;),
                        values  => [ qw(cloud normal) ] } );

   if ($args->{cat_type} eq q(cloud)) {
      $self->add_append( { default => $args->{sort_field},
                           id      => $form.q(.sort_field),
                           labels  => { count => q(Count), tag => q(Subject) },
                           pwidth  => 8,
                           sep     => q(&nbsp;),
                           values  => [ qw(tag count) ] } );
      $self->add_append( { default => $args->{min_count},
                           id      => $form.q(.min_count),
                           pwidth  => 9,
                           sep     => q(&nbsp;),
                           values  => [ qw(0 1 2 4 8 16 32 64
                                           125 250 500 1000) ] } );
      $self->add_append( { default => $args->{col_type},
                           id      => $form.q(.colour_type),
                           labels  => { calculated => q(Calculated),
                                        pallet     => q(Pallette) },
                           pwidth  => 10,
                           sep     => q(&nbsp;),
                           values  => [ qw(calculated pallet) ] } );
   }

   return;
}

sub collection_view_form {
   my ($self, $cat, $subject) = @_; my ($current, $labels, $links, $nitems);

   my $s        = $self->context->stash;
   my $form     = $s->{form}->{name};
   my $catalogs = $s->{model}->{catalogs}; unshift @{ $catalogs }, 0;
   my $subjects = $s->{model}->{nodes}->subjects( $cat );
   my $names    = $s->{model}->{names};

   $s->{pwidth} -= 10;
   unshift @{ $subjects }, 0;
   ($current, $labels) = $s->{model}->{nodes}->current( $subject );
   $links = $s->{model}->{links}->list( $cat, $labels, $current );

   $self->clear_form( { firstfld => $form.'.catalog' } ); $nitems = 0;
   $self->add_field(  { default  => $cat,
                        id       => $form.'.catalog',
                        labels   => $names,
                        values   => $catalogs } ); $nitems++;
   $self->add_field(  { default  => $subject,
                        id       => $form.'.subject',
                        labels   => $names,
                        values   => $subjects } ); $nitems++;

   if ($subject && $self->is_member( $subject, @{ $subjects } )) {
      $s->{subject} = $names->{ $subject };
      $self->add_field( { all     => $links,
                          current => $current,
                          id      => $form.'.links',
                          labels  => $labels } ); $nitems++;
      $self->add_buttons( qw(Update) );
   }

   $self->group_fields( { id => $form.'.edit', nitems => $nitems } );
   return;
}

sub grid_rows {
   my ($self, $node_model, $link_model) = @_;
   my ($cells, $hacc, $gid, $href, $l, $lid, $link, $node, @nodes);
   my ($page, $page_size, $r, $ref, $rNo, $row, $s, $start, $text);

   $rNo       = 0;
   $l         = q(library);
   $r         = q(catalog);
   $s         = $self->context->stash;
   $hacc      = HTML::Accessors->new( content_type => $s->{content_type} );
   ($gid      = $self->query_value( q(id) )) =~ s{ \A $r }{}msx;
   $gid       =~ s{ _grid \z }{}msx;
   $page      = $self->query_value( q(page) )      || 0;
   $page_size = $self->query_value( q(page_size) ) || 10;
   $start     = $page * $page_size;
   @nodes     = $node_model->search( { gid      => $gid },
                                     { join     => [ qw(links) ],
                                       order_by => q(links.text),
                                       page     => $page + 1,
                                       rows     => $page_size } );
   $self->stash_meta( { offset => $start } );

   for $node (@nodes) {
      if (($lid = $node->lid) && ($link = $link_model->find( $lid ))) {
         $href  = $self->uri_for( $l.$SEP.q(browse), $s->{lang}, $lid );
         $ref   = { class => $l.q(Fade), href => $href };
         $text  = $hacc->escape_html( $link->text, 0 );
         $text  =~ s{ _ }{ }gmx;
         $text  = $hacc->a( $ref, "\n".$text );

         if ($link->info) {
            $ref  = { class => q(tips),
                      title => $hacc->escape_html( $link->info, 0 ) };
            $text = $hacc->span( $ref, "\n".$text )."\n";
         }
      }
      else { $text = $hacc->span( q(&nbsp;) ) }

      $cells  = $hacc->td( { class => q(grid_cell first lineNumber) },
                             $start + $rNo + 1 );
      $cells .= $hacc->td( { class => q(grid_cell) }, $text );
      $row    = $hacc->tr( { class => q(grid) }, $cells );
      $self->stash_form( $row );
      $self->stash_meta( { id => $start + $rNo++ } );
   }

   delete $self->context->stash->{token};
   return;
}

sub grid_table {
   my ($self, $node_model) = @_;
   my ($cells, $divs, $hacc, $id, $l, $r, $rNo, $rows, $tabs, $text);
   my ($gid, $nodes, $ref, $s, $size, $span, $width);

   $s     = $self->context->stash;
   $l     = q(library);
   $r     = q(catalog);
   $hacc  = HTML::Accessors->new( content_type => $s->{content_type} );
   $gid   = $self->query_value( q(id) );
   $size  = $self->query_value( q(page_size) ) || 10;
   $span  = $s->{columns} || 3;
   $width = int( ($s->{width} - (50 * $span)) / $span );
   $nodes = $node_model->search( gid => $gid );
   $rows  = $NUL; $rNo = 0;

   while ($rNo < $nodes->count && $rNo < $size) {
      $cells  = $hacc->td( { class => q(grid_cell first lineNumber) }, $rNo+1);
      $cells .= $hacc->td( { class => q(grid_cell) }, q(...));
      $rows  .= $hacc->tr( { class => q(grid) }, $cells);
      $rNo++;
   }

   $tabs   = $hacc->table( { cellpadding => 0,
                             cellspacing => 0,
                             class       => q(grid),
                             id          => $r.$gid.q(_grid) }, $rows)."\n";
   $tabs   = $hacc->div( { class => q(grid_container),
                           style => 'width: '.($width - 15).'px;' }, $tabs );
   $tabs   = $hacc->div( $tabs );
   $cells  = $hacc->th({ class => q(grid_header first) }, chr 35)."\n";
   $cells .= $hacc->th({ class => q(grid_header) }, ' Select link')."\n";
   $tabs   = $hacc->table({ cellpadding => 0,
                            cellspacing => 0,
                            id          => $r.$gid.q(_grid_header) },
                          $hacc->tr( $cells ))."\n".$tabs;
   $divs   = $hacc->a({ class => $l.q(SubHeader),
                        id    => $r.$gid.q(_header) }, 'Loading&hellip;')."\n";
   $self->stash_form( $divs.$tabs );
   $self->stash_meta( { totalcount => $nodes->count } );
   delete $s->{token};
   return;
}

sub links_delete {
   my ($self, $link) = @_; my $s = $self->context->stash; my $res;

   $self->throw( q(eNoLink) ) unless ($link);

   unless ($res = $s->{model}->{links}->find( $link ) ) {
      $self->throw( error => q(eUnknownLink),
                    arg1  => $self->query_value( q(name) ) );
   }

   $res->delete; $self->add_result_msg( q(linkDeleted), $res->name );
   return;
}

sub links_insert {
   my $self = shift; my ($link, $model, $name, $res, $s, $text);

   $s     = $self->context->stash;
   $model = $s->{model}->{links};
   $name  = $self->query_value( q(name) );
   $text  = $self->query_value( q(title) );
   $name  = $text unless ($name); $name =~ s{ \s }{_}gmx;
   $res   = $model->search( text => $text );

   if ($link = $res->next) {
      $self->throw( error => q(eLinkAlreadyExists), arg1 => $name );
   }

   $res = $model->create( { nid  => $self->query_value( q(nid) ),
                            name => $name,
                            text => $text,
                            url  => $self->query_value( q(url) ),
                            info => $self->query_value( q(desc) ) } );
   $self->add_result_msg( q(linkCreated), $name, $res->id );
   return $res->id;
}

sub links_save {
   my ($self, $link) = @_; my $s = $self->context->stash; my $res;

   $self->throw( q(eNoLink) ) unless ($link);

   my $text = $self->query_value( q(title) );
   my $name = $self->query_value( q(name) ) || $text; $name =~ s{ \s }{_}gmx;

   unless ($res = $s->{model}->{links}->find( $link )) {
      $self->throw( error => q(eUnknownLink), arg1 => $name );
   }

   $res->name( $name );
   $res->text( $text );
   $res->nid(  $self->query_value( q(nid)  ) );
   $res->url(  $self->query_value( q(url)  ) );
   $res->info( $self->query_value( q(desc) ) );
   $res->update;
   $self->add_result_msg( q(linkUpdated), $name );
   return;
}

sub links_view_form {
   my ($self, $cat, $link) = @_;

   my $labels   = {};
   my $s        = $self->context->stash;
   my $form     = $s->{form}->{name};
   my $cats     = $s->{model}->{catalogs};
   my $cats2    = [ @{ $cats } ];
   my $links    = $s->{model}->{links}->list( $cat, $labels );
   my $link_ref = $s->{model}->{links}->find( $link );
   my $names    = $s->{model}->{names};
   my $nitems   = 0;
   my $step     = 1;

   unshift @{ $cats  }, '0';
   unshift @{ $cats2 }, '0', '2';
   unshift @{ $links }, '0', '-1';
   $labels->{ 0 }    = $NUL;
   $labels->{ '-1' } = $s->{newtag};
   $s->{catalog}     = $names->{ $cat };
   $s->{link   }     = $labels->{ $link };
   $s->{pwidth }    -= 15;

   $self->clear_form(   { firstfld => $form.'.link' } );
   $self->add_field(    { default  => $cat,
                          id       => $form.'.catalog',
                          labels   => $names,
                          stepno   => 0,
                          values   => $cats } ); $nitems++;
   $self->add_field(    { default  => $link,
                          id       => $form.'.link',
                          labels   => $labels,
                          stepno   => 0,
                          values   => $links } ); $nitems++;
   $self->group_fields( { id       => $form.'.select',
                          nitems   => $nitems } ); $nitems = 0;

   return unless ($link && $self->is_member( $link, -1, @{ $links } ));

   my $def = $link_ref && defined $link_ref->name ? $link_ref->name : $NUL;

   $self->add_field(    { ajaxid   => $form.'.linkName',
                          default  => $def,
                          name     => 'name',
                          stepno   => $step++ } ); $nitems++;

   $def = $link_ref && defined $link_ref->nid ? $link_ref->nid : 1;

   $self->add_field(    { default  => $def,
                          id       => $form.'.nid',
                          labels   => $names,
                          stepno   => $step++,
                          values   => $cats2 } ); $nitems++;

   $def = $link_ref && defined $link_ref->text ? $link_ref->text : $NUL;

   $self->add_field(    { ajaxid   => $form.'.title',
                          default  => $def,
                          stepno   => $step++ } ); $nitems++;

   $def = $link_ref && defined $link_ref->url ? $link_ref->url : $NUL;

   $self->add_field(    { ajaxid   => $form.'.linkURL',
                          default  => $def,
                          name     => 'url',
                          stepno   => $step++ } ); $nitems++;

   $def = $link_ref && defined $link_ref->info ? $link_ref->info : $NUL;

   $self->add_field(    { default  => $def,
                          id       => $form.'.desc',
                          stepno   => $step++ } ); $nitems++;

   $self->group_fields( { id       => $form.'.edit', nitems => $nitems } );

   if ($link > 0) { $self->add_buttons( qw(Save Delete) ) }
   else { $self->add_buttons( qw(Insert) ) }

   return;
}

sub nodes_delete {
   my ($self, $args) = @_; my ($cat, $name, $res, $subject);

   my $s = $self->context->stash; my $names_model = $args->{names};

   $self->throw( q(eNoCatalog) ) unless ($cat = $args->{catalog});
   $self->throw( q(eNoSubject) ) unless ($subject = $args->{subject});

   $self->add_result( $names_model->cascade_delete( $subject )->out );

   for $res ($s->{model}->{nodes}->search( { gid     => $cat },
                                           { columns => [ qw(nid) ] } )) {
      $names_model->cascade_delete( $res->nid );
   }

   $names_model->cascade_delete( $cat );
   $self->add_result_msg( q(nodesDeleted) );
   return 1;
}

sub nodes_insert {
   my ($self, $args) = @_; my ($gid, $model, $nid);

   my $names_model = $args->{names};
   my $cat         = $args->{catalog};
   my $subject     = $args->{subject};
   my $s           = $self->context->stash;
   my $desc        = $self->query_value( q(desc) );
   my $res         = $names_model->search( { text => $desc } );

   $self->throw( error => q(eNodeExists), arg1 => $desc ) if ($res->next);

   $names_model->create( { text => $desc } );
   $gid = $subject != -1 ? 1 : $cat;
   $s->{model}->{nodes}->create( { gid => $gid, nid => $res->id, lid => 0 } );
   $self->add_result_msg( q(nodeInserted), $desc );
   return 1;
}

sub nodes_save {
   my ($self, $names_model) = @_; my $res;

   my $cat     = $self->query_value( q(catalog) );
   my $desc    = $self->query_value( q(catalogDesc) );
   my $subject = $self->query_value( q(subject) );

   unless ($res = $names_model->find( $cat )) {
      $self->add_result( 'Catalog '.$desc.' does not exist' );
      return 0;
   }

   $res->text( $desc ); $res->update;
   $self->add_result( 'Catalog '.$desc.' updated' );
   $desc = $self->query_value( q(subjectDesc) );

   unless ($res = $names_model->find( $subject )) {
      $self->add_result( 'Subject '.$desc.' does not exist' );
      return 0;
   }

   $res->text( $desc ); $res->update;
   $self->add_result( 'Subject '.$desc.' updated' );
   return 1;
}

sub nodes_view_form {
   my ($self, $cat, $subject) = @_; my $def;

   my $s        = $self->context->stash;
   my $catalogs = $s->{model}->{catalogs};
   my $names    = $s->{model}->{names};
   my $subjects = $s->{model}->{nodes}->subjects( $cat );
   my $form     = $s->{form}->{name};
   my $nitems   = 0;
   my $step     = 1;

   unshift @{ $catalogs }, 0, -1;
   unshift @{ $subjects }, 0, -1, -2;
   $names->{-2}  = '..Catalog..';
   $s->{pwidth} -= 10;

   $self->clear_form( { firstfld => $form.'.catalog' } );
   $self->add_field(  { default  => $cat,
                        id       => $form.'.catalog',
                        labels   => $names,
                        stepno   => 0,
                        values   => $catalogs } ); $nitems++;

   if ($cat > 0) {
      $self->add_field( { default => $subject,
                          id      => $form.'.subject',
                          labels  => $names,
                          stepno  => 0,
                          values  => $subjects } ); $nitems++;
   }

   if ($cat < 0 || ($subject && $subject == -2)) {
      $def   = $cat > 0 ? $names->{ $cat } : $NUL;
      $self->add_field( { ajaxid  => $form.'.catalogDesc',
                          default => $def,
                          name    => 'desc',
                          stepno  => $step++ } ); $nitems++;
   }

   if ($subject && $subject > -2
       && $self->is_member( $subject, @{ $subjects } )) {
      $def   = $subject > 0 ? $names->{ $subject } : $NUL;
      $self->add_field( { ajaxid  => $form.'.subjectDesc',
                          default => $def,
                          name    => 'desc',
                          stepno  => $step++ } ); $nitems++;
   }

   $self->group_fields( { id => $form.'.select', nitems => $nitems } );

   if ($cat < 0 || $self->is_member( $subject, '-1', @{ $subjects } )) {
      if ($cat > 0 && $subject > 0) {
         $self->add_buttons( qw(Save Delete) );
      }
      else { $self->add_buttons( qw(Insert) ) }
   }

   return;
}

sub normal_field {
   my ($self, $ref) = @_; my ($class, $href, $html, $jscript, $style);

   my $c         = $self->context;
   my $s         = $c->stash;
   my $namespace = $c->action->namespace;
   my $name      = $c->action->name;
   my $hacc      = HTML::Accessors->new( content_type => $s->{content_type} );

   $jscript   = "behaviour.table.liveGrid('".$name."', '";
   $jscript  .= $ref->{value}."', '".$s->{assets}."downPoint.gif~";
   $jscript  .= $s->{assets}."upPoint.gif', ".$ref->{size}.", 1)";
   $html      = $hacc->span( { class => $namespace.q(Header) },
                             $ref->{labels}->{ $ref->{value} } )."\n";
   $html     .= $hacc->img(  { alt   => 'Down Arrow',
                               class => $namespace.q(Header),
                               id    => $name.$ref->{value}.'Img',
                               src   => $s->{assets}.'downPoint.gif' } );
   $href      = "javascript:Expand_Collapse()";
   $html      = $hacc->a( { class   => $namespace.q(HeaderFade),
                            href    => $href,
                            id      => $name.$ref->{value},
                            onclick => $jscript }, "\n".$html )."\n";
   $html      = $hacc->div( { class => $namespace.q(Header),
                              style => "width: ".$ref->{width}."px;" },
                            "\n".$html )."\n";
   $style     = "clear: left; display: none; width: ".$ref->{width}."px;";
   $html     .= $hacc->div( { class => $namespace.q(Panel),
                              id    => $name.$ref->{value}.q(Disp),
                              style => $style }, 'Loading' );
   $class     = $ref->{fld_no} % $ref->{span} == 0 ? q( clearLeft) : $NUL;
   $ref       = { class => $namespace.q(Subject ).$class,
                  text  => $html,
                  type  => q(label) };
   return $ref;
}

sub recatalog_exec {
   my $self = shift; my $s = $self->context->stash; my ($cmd, $out);

   $cmd  = $self->catfile( $self->binsdir, $self->prefix.'_schema' );
   $cmd .= ' -c catalog_mmf '.($s->{debug} ? '-D' : '-n');
   $cmd .= ' -L '.$s->{lang};
   $out  = $self->run_cmd( $cmd, { async => 1,
                                   debug => $s->{debug},
                                   err   => q(out),
                                   out   => $self->tempname } )->out;
   $self->add_result( $out );
   return 1;
}

sub recatalog_form {
   my $self = shift;

   $self->simple_page( q(recatalog) );
   $self->add_buttons( qw(Execute) );
   return;
}

sub remove_links_from_subject {
   my ($self, $args) = @_; my $s = $self->context->stash; my ($msg, $subject);

   $self->throw( q(eNoSubject) ) unless ($subject = $args->{subject});

   for my $lid (@{ $self->query_array( $args->{field} ) }) {
      my $res = $s->{model}->{nodes}->search( gid => $subject, lid => $lid );
      my $cat;

      if ($cat = $res->next) {
         my $link = $s->{model}->{links}->find( $lid )->text;

         $cat->delete; $msg .= $msg ? q(, ).$link : $link;
      }
   }

   $subject = $s->{model}->{names}->{ $subject };
   $self->add_result_msg( q(links_removed), $subject, $msg );
   return;
}

sub search_form {
   my ($self, $id, $default) = @_;

   $self->stash_form( { default => $default,
                        id      => $id.q(.expression), widget => 1 } );
   $self->stash_form( { id      => $id.q(.search),     widget => 1 } );
   $self->stash_meta( { id      => $id } );
   return;
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::Catalog - Manipulate the library catalog database

=head1 Version

0.1.$Revision: 639 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 add_links_to_subject

=head2 browse

=head2 catalog_form

=head2 collection_view_form

=head2 grid_rows

=head2 grid_table

=head2 links_delete

=head2 links_view_form

=head2 links_insert

=head2 links_save

=head2 new

=head2 nodes_delete

=head2 nodes_view_form

=head2 nodes_insert

=head2 nodes_save

=head2 normal_field

=head2 recatalog_exec

=head2 recatalog_form

=head2 remove_links_from_subject

=head2 search_form

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
