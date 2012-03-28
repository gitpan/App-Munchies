# @(#)$Id: Catalog.pm 1233 2011-10-23 01:24:42Z pjf $

package App::Munchies::Model::Catalog;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1233 $ =~ /\d+/gmx );
use parent qw(CatalystX::Usul::Model::Schema);

use CatalystX::Usul::Constants;
use CatalystX::Usul::Functions qw(is_member split_on__ throw);
use Data::CloudWeights;
use HTML::Accessors;
use MRO::Compat;
use TryCatch;

__PACKAGE__->config( database           => q(library),
                     domain_model_class => q(MealMaster),
                     hits_per_page      => 16,
                     schema_class       => q(App::Munchies::Schema::Catalog) );

__PACKAGE__->mk_accessors( qw(domain_model_class hits_per_page) );

sub COMPONENT {
   my ($class, $app, $cfg) = @_; my $ac = $app->config;

   $cfg->{database    } ||= $class->config->{database};
   $cfg->{encoding    } ||= $ac->{encoding};
   $cfg->{connect_info} ||= $class->get_connect_info( $ac, $cfg->{database} );

   return $class->next::method( $app, $cfg );
}

sub add_links_to_subject {
   my ($self, $args) = @_; my $count = 0;

   my $subject = $args->{subject} or throw 'Subject not specified';

   my $links = $self->links; my $nodes = $self->nodes; my $msg;

   for my $lid (@{ $args->{items} }) {
      $nodes->create( { gid => $subject, nid => 1, lid => $lid } );
      $msg .= ($msg ? q(, ) : NUL).$links->find( $lid )->text;
      $count++;
   }

   $count > 0 and $self->add_result_msg( 'Subject [_1] links added: [_2]',
                                         $self->names_list->{ $subject },
                                         $msg );
   return $count;
}

sub add_search_hit {
   my ($self, @args) = @_; my $c = $self->context;

   return $c->model( $self->domain_model_class )->add_search_hit( @args );
}

sub catalog_form {
   my ($self, $args) = @_; my $data = {};

   try        { $data = $self->_get_catalog_data( $args ) }
   catch ($e) { return $self->add_error( $e ) }

   my $c     = $self->context;
   my $s     = $c->stash;
   my $ns    = $c->action->namespace;
   my $form  = $s->{form}->{name};
   my $size  = $s->{size}    || 10;
   my $span  = $s->{columns} || 3;
   my $width = int (int ($s->{width} - (50 * $span)) / $span);

   $width < 100 and $width = 100;

   if ($args->{catalog_type} eq q(cloud)) {
      my $ref   = $args->{colour_type} eq q(pallet)
                ? { cold_colour => NUL } : {};
      my $cloud = Data::CloudWeights->new( $ref );

      $cloud->sort_field( $args->{sort_field} );

      if ($args->{sort_field} eq q(count)) {
         $cloud->sort_type( q(numeric) ); $cloud->sort_order( q(desc) );
      }

      for my $subject (@{ $data->{subjects} }) {
         my $num_subjects = $data->{counts}->{ $subject };

         $num_subjects > $args->{min_count} or next;

         $cloud->add( $data->{labels}->{ $subject },
                      $num_subjects,
                      { class_pref => $ns,
                        id_pref    => $c->action->name,
                        labels     => $data->{labels},
                        name       => $subject,
                        table_len  => $size,
                        total      => $num_subjects,
                        width      => $width } );
      }

      $self->add_field( { class     => $ns.q(Cloud),
                          container => FALSE,
                          data      => $cloud->formation,
                          type      => q(cloud) } );
   }
   else {
      my $name = $c->action->name;

      for my $subject (@{ $data->{subjects} }) {
         $self->add_field( {
            container   => FALSE,
            frame_class => q(library_item),
            id          => $name.$subject,
            name        => q(catalog_field),
            type        => q(template) } );
         $s->{template_data}->{ $name.$subject } = {
            labels    => $data->{labels},
            name      => $name,
            namespace => $ns,
            size      => $size,
            value     => $subject,
            width     => $width };
      }
   }

   # Add fields to the append div
   $self->add_append( { default => $args->{catalog},
                        labels  => $data->{labels},
                        id      => $form.q(.catalog),
                        pwidth  => 6,
                        sep     => NBSP,
                        values  => $data->{catalogs} } );
   $self->add_append( { default => $args->{catalog_type},
                        id      => $form.q(.catalog_type),
                        labels  => { cloud => q(Cloud), normal => q(Normal) },
                        pwidth  => 10,
                        sep     => NBSP,
                        values  => [ qw(cloud normal) ] } );

   if ($args->{catalog_type} eq q(cloud)) {
      $self->add_append( { default => $args->{sort_field},
                           id      => $form.q(.sort_field),
                           labels  => { count => q(Count), tag => q(Subject) },
                           pwidth  => 8,
                           sep     => NBSP,
                           values  => [ qw(tag count) ] } );
      $self->add_append( { default => $args->{min_count},
                           id      => $form.q(.min_count),
                           pwidth  => 9,
                           sep     => NBSP,
                           values  => [ qw(0 1 2 4 8 16 32 64
                                           125 250 500 1000) ] } );
      $self->add_append( { default => $args->{colour_type},
                           id      => $form.q(.colour_type),
                           labels  => { calculated => q(Calculated),
                                        pallet     => q(Pallette) },
                           pwidth  => 10,
                           sep     => NBSP,
                           values  => [ qw(calculated pallet) ] } );
   }

   return;
}

sub collection_view_form {
   my ($self, $cat, $subject) = @_;

   my $c        = $self->context;
   my $s        = $c->stash;
   my $nodes    = $self->nodes;
   my $names    = $self->names_list;
   my $form     = $s->{form}->{name}; $s->{pwidth} -= 10;
   my $catalogs = $nodes->catalogs; unshift @{ $catalogs }, 0;
   my $subjects = $nodes->subjects( $cat ); unshift @{ $subjects }, 0;
   my ($current, $labels) = $nodes->current( $subject );
   my $all      = $self->links->list( $cat, $labels, $current );

   $self->clear_form( { firstfld => $form.'.catalog' } );
   $self->add_field(  { default  => $cat,
                        id       => $form.'.catalog',
                        labels   => $names,
                        values   => $catalogs } );
   $self->add_field(  { default  => $subject,
                        id       => $form.'.subject',
                        labels   => $names,
                        values   => $subjects } );

   if ($subject and is_member $subject, $subjects) {
      $s->{subject} = $names->{ $subject };
      $self->add_field( { all     => $all,
                          current => $current,
                          id      => $form.'.links',
                          labels  => $labels } );
      $self->add_buttons( qw(Update) );
   }

   $self->group_fields( { id => $form.'.edit' } );
   return;
}

sub get_link_url {
   my ($self, @args) = @_; my $s = $self->context->stash;

   if (($args[ 0 ] and $args[ 0 ] eq $s->{newtag})
       or (($args[ 1 ] and $args[ 1 ] eq $s->{newtag}))) {
      return $args[ 0 ].SEP.$args[ 1 ];
   }

   my $link = $self->links->search_for_field( q(url), 2, @args );

   return $link ? $link->url : undef;
}

sub grid_rows {
   my $self        = shift;
   my $row_no      = 0;
   my $seq_no      = 1;
   my $prev        = NUL;
   my $l           = q(library);
   my $r           = q(catalog);
   my $view_action = q(recipes_view);
   my $c           = $self->context;
   my $s           = $c->stash;
   my $links       = $self->links;
   my $hacc        = HTML::Accessors->new( content_type => $s->{content_type} );
   (my $id         = $self->query_value( q(id) )) =~ s{ \A $r }{}msx;
       $id         =~ s{ _grid \z }{}msx;
   my $gid         = split_on__ $id, 1;
   my $page        = $self->query_value( q(page) )      || 0;
   my $page_size   = $self->query_value( q(page_size) ) || 10;
   my $start       = $page * $page_size;
   my @nodes       = $self->nodes->search( { gid      => $gid },
                                           { join     => [ qw(links) ],
                                             order_by => q(links.text),
                                             page     => $page + 1,
                                             rows     => $page_size } );

   $self->stash_meta( { offset => $start } );

   for my $node (@nodes) {
      my ($html, $lid, $link, $text);

      if ($lid = $node->lid and $link = $links->find( $lid )) {
         (not $prev or $link->text ne $prev) and $seq_no = 1;

         my @args = __get_uri_args( $link, $seq_no );
         my $href = $c->uri_for_action( $l.SEP.$view_action, @args );
         my $ref  = { class => $l.q( fade), href => $href };

         $text = $link->text." (${lid})";
         $html = $hacc->a( $ref, "\n".$hacc->escape_html( $text, 0 ) );

         if ($link->info) {
            $ref  = { class => q(tips),
                      title => $hacc->escape_html( $link->info, 0 ) };
            $html = $hacc->span( $ref, "\n".$html )."\n";
         }

         $prev = $link->text; $seq_no++;
      }
      else { $html = $hacc->span( NBSP ) }

      my $cells  = $hacc->td( { class => q(grid_cell first lineNumber) },
                              $start + $row_no + 1 );
         $cells .= $hacc->td( { class => q(grid_cell) }, $html );

      $self->stash_content( $hacc->tr( { class => q(grid) }, $cells ) );
      $self->stash_meta( { id => $start + $row_no++ } );
   }

   delete $s->{token};
   return;
}

sub grid_table {
   my $self   = shift;
   my $c      = $self->context;
   my $s      = $c->stash;
   my $l      = q(library);
   my $r      = q(catalog);
   my $hacc   = HTML::Accessors->new( content_type => $s->{content_type} );
   my $gid    = $self->query_value( q(id) );
   my $size   = $self->query_value( q(page_size) ) || 10;
   my $span   = $s->{columns} || 3;
   my $width  = int( ($s->{width} - (50 * $span)) / $span );
   my $nodes  = $self->nodes->search( { gid => $gid } );
   my $id     = $r.q(_).$gid;
   my $rows   = NUL;
   my $row_no = 0;
   my ($cells, $divs, $tabs);

   while ($row_no < $nodes->count && $row_no < $size) {
      $cells  = $hacc->td( { class => q(grid_cell first lineNumber) },
                           $row_no + 1 );
      $cells .= $hacc->td( { class => q(grid_cell) }, q(...) );
      $rows  .= $hacc->tr( { class => q(grid) }, $cells );
      $row_no++;
   }

   $tabs   = $hacc->table( {
      cellpadding => 0,
      cellspacing => 0,
      class       => q(grid),
      id          => $id.q(_grid) }, $rows )."\n";
   $tabs   = $hacc->div( { class => q(grid_container),
                           style => 'width: '.($width - 15).'px;' }, $tabs );
   $tabs   = $hacc->div( $tabs );
   $cells  = $hacc->th( { class => q(grid_header first) }, chr 35 )."\n";
   $cells .= $hacc->th( { class => q(grid_header) }, 'Select link' )."\n";
   $tabs   = $hacc->table( { class => q(grid), id => $id.q(_grid_header) },
                           $hacc->tr( $cells ))."\n".$tabs;
   $divs   = $hacc->a( { class => $l.q(_subheader),
                         id    => $id.q(_header) }, 'Loading'.DOTS )."\n";
   $self->stash_content( $divs.$tabs );
   $self->stash_meta( { totalcount => $nodes->count } );
   delete $s->{token};
   return;
}

sub links {
   return shift->resultset( q(Links) );
}

sub links_delete {
   my $self = shift;
   my $id   = $self->query_value( q(link) ) or throw 'Link id not specified';
   my $link = $self->links->find( $id )
      or throw error => 'Link id [_1] unknown', args => [ $id ];

   $link->delete;
   $self->add_result_msg( 'Link [_1] deleted', $link->name );
   return TRUE;
}

sub links_insert {
   my $self  = shift;
   my $text  = $self->query_value( q(title) );
   my $name  = $self->query_value( q(name) ) || $text; $name =~ s{ \s }{_}gmx;
   my $links = $self->links;

   $links->search( text => $text )->next
      and throw error => 'Link [_1] already exists', args => [ $name ];

   my $id = $links->create
      ( { nid  => $self->query_value( q(nid) ),
          name => $name,
          text => $text,
          url  => $self->query_value( q(url) ),
          info => $self->query_value( q(desc) ) } )->id;

   $self->add_result_msg( 'Link [_1] created with id [_2]', $name, $id );
   return $id;
}

sub links_save {
   my $self = shift;
   my $id   = $self->query_value( q(link) ) or throw 'Link id not specified';
   my $text = $self->query_value( q(title) );
   my $name = $self->query_value( q(name) ) || $text; $name =~ s{ \s }{_}gmx;
   my $link = $self->links->find( $id )
      or throw error => 'Link [_1] unknown', args => [ $name ];

   $link->name( $name );
   $link->text( $text );
   $link->nid ( $self->query_value( q(nid)  ) );
   $link->url ( $self->query_value( q(url)  ) );
   $link->info( $self->query_value( q(desc) ) );
   $link->update;
   $self->add_result_msg( 'Link [_1] updated', $name );
   return TRUE;
}

sub links_view_form {
   my ($self, $cat, $id) = @_;

   my $labels    = {};
   my $s         = $self->context->stash;
   my $form      = $s->{form}->{name};
   my $names     = $self->names_list;
   my $links     = $self->links;
   my $list      = [ '0', '-1', @{ $links->list( $cat, $labels ) } ];
   my $link      = $links->find( $id );
   my $cats      = $self->nodes->catalogs;
   my $cats_copy = [ '0', '2', @{ $cats } ];
      $cats      = [ '0', @{ $cats } ];

   $labels->{ 0 } = NUL; $labels->{ '-1' } = $s->{newtag};

   $s->{catalog}  = $names->{ $cat }; $s->{link} = $labels->{ $id || 0 };
   $s->{pwidth } -= 15;

   $self->clear_form  ( { firstfld => $form.'.link' } );
   $self->add_field   ( { default  => $cat,
                          id       => $form.'.catalog',
                          labels   => $names,
                          values   => $cats } );
   $self->add_field   ( { default  => $id,
                          id       => $form.'.link',
                          labels   => $labels,
                          values   => $list } );
   $self->group_fields( { id       => $form.'.select' } );

   ($id and is_member $id, -1, @{ $list }) or return;

   my $def = $link && defined $link->name ? $link->name : NUL;

   $self->add_field   ( { ajaxid   => $form.'.linkName',
                          default  => $def,
                          name     => 'name' } );

   $def = $link && defined $link->nid ? $link->nid : 1;

   $self->add_field   ( { default  => $def,
                          id       => $form.'.nid',
                          labels   => $names,
                          values   => $cats_copy } );

   $def = $link && defined $link->text ? $link->text : NUL;

   $self->add_field   ( { ajaxid   => $form.'.title', default => $def } );

   $def = $link && defined $link->url ? $link->url : NUL;

   $self->add_field   ( { ajaxid   => $form.'.linkURL',
                          default  => $def,
                          name     => 'url' } );

   $def = $link && defined $link->info ? $link->info : NUL;

   $self->add_field   ( { default  => $def, id => $form.'.desc' } );
   $self->group_fields( { id       => $form.'.edit' } );

   if ($id > 0) { $self->add_buttons( qw(Save Delete) ) }
   else { $self->add_buttons( qw(Insert) ) }

   return;
}

sub names {
   return shift->resultset( q(Names) );
}

sub names_list {
   my $self  = shift;
   my $names = { map { $_->id => $_->text } $self->names->search() };

   $names->{0} = NUL; $names->{ '-1' } = $self->context->stash->{newtag};

   return $names;
}

sub nodes {
   return shift->resultset( q(Nodes) );
}

sub nodes_delete {
   my $self    = shift;
   my $catalog = $self->query_value( q(catalog) )
      or throw 'Catalog not specified';
   my $subject = $self->query_value( q(subject) )
      or throw 'Subject not specified';
   my $names   = $self->names;

   $self->add_result( $names->cascade_delete( $subject )->out );

   for my $res ($self->nodes->search
                ( { gid => $catalog }, { columns => [ qw(nid) ] } )) {
      $names->cascade_delete( $res->nid );
   }

   $names->cascade_delete( $catalog );
   $self->add_result_msg( 'Nodes deleted' );
   return TRUE;
}

sub nodes_insert {
   my $self    = shift;
   my $catalog = $self->query_value( q(catalog) )
      or throw 'Catalog not specified';
   my $subject = $self->query_value( q(subject) )
      or throw 'Subject not specified';
   my $gid     = $subject != -1 ? 1 : $catalog;
   my $desc    = $self->query_value( q(subjectDesc) );
   my $names   = $self->names;

   $names->search( { text => $desc } )->next
      and throw error => 'Node [_1] already exists', args => [ $desc ];

   my $name = $names->create( { text => $desc } );

   $self->nodes->create( { gid => $gid, nid => $name->id, lid => 0 } );
   $self->add_result_msg( 'Node [_1] created', $desc );
   return TRUE;
}

sub nodes_save {
   my $self = shift; my $res;

   my $catalog = $self->query_value( q(catalog) )
      or throw 'Catalog not specified';
   my $subject = $self->query_value( q(subject) )
      or throw 'Subject not specified';
   my $desc    = $self->query_value( q(catalogDesc) );
   my $names   = $self->names;

   unless ($res = $names->find( $catalog )) {
      $self->add_result( "Catalog $desc does not exist" );
      return FALSE;
   }

   $res->text( $desc ); $res->update;
   $self->add_result( "Catalog $desc updated" );
   $desc = $self->query_value( q(subjectDesc) );

   unless ($res = $names->find( $subject )) {
      $self->add_result( "Subject $desc does not exist" );
      return FALSE;
   }

   $res->text( $desc ); $res->update;
   $self->add_result( "Subject $desc updated" );
   return TRUE;
}

sub nodes_view_form {
   my ($self, $cat, $subject) = @_; $cat ||= 0;

   my $nodes    = $self->nodes;
   my $s        = $self->context->stash;
   my $names    = $self->names_list; $names->{-2} = '..Catalog..';
   my $catalogs = $nodes->catalogs; unshift @{ $catalogs }, 0, -1;
   my $subjects = $nodes->subjects( $cat ); unshift @{ $subjects }, 0, -1, -2;
   my $form     = $s->{form}->{name}; $s->{pwidth} -= 10;

   $self->clear_form( { firstfld => $form.'.catalog' } );
   $self->add_field(  { default  => $cat,
                        id       => $form.'.catalog',
                        labels   => $names,
                        values   => $catalogs } );

   if ($cat > 0) {
      $self->add_field( { default => $subject,
                          id      => $form.'.subject',
                          labels  => $names,
                          values  => $subjects } );
   }

   if ($cat < 0 or ($subject and $subject == -2)) {
      $self->add_field( { ajaxid  => $form.'.catalogDesc',
                          default => $cat > 0 ? $names->{ $cat } : NUL,
                          name    => 'desc' } );
   }

   if ($subject and $subject > -2 and is_member $subject, $subjects) {
      $self->add_field( { ajaxid  => $form.'.subjectDesc',
                          default => $subject > 0 ? $names->{ $subject } : NUL,
                          name    => 'desc' } );
   }

   $self->group_fields( { id => $form.'.select' } );

   if ($cat < 0 or is_member $subject, -1, @{ $subjects }) {
      if ($cat > 0 and $subject > 0) { $self->add_buttons( qw(Save Delete) ) }
      else { $self->add_buttons( qw(Insert) ) }
   }

   return;
}

sub recatalog_exec {
   my $self = shift;

   return $self->context->model( $self->domain_model_class )->index;
}

sub recatalog_form {
   my $self = shift;

   my $c = $self->context; $c->stash->{token} = $c->config->{token};

   $self->add_buttons( qw(Execute) );
   return;
}

sub remove_links_from_subject {
   my ($self, $args) = @_; my $count = 0;

   my $subject = $args->{subject} or throw 'Subject not specified';

   my $nodes = $self->nodes; my $links = $self->links; my $msg;

   for my $lid (@{ $args->{items} }) {
      my $res = $nodes->search( gid => $subject, lid => $lid );
      my $cat = $res->next or next;

      $cat->delete; $msg .= ($msg ? q(, ) : NUL).$links->find( $lid )->text;
      $count++;
   }

   $count > 0 and $self->add_result_msg( 'Subject [_1] links removed: [_2]',
                                         $self->names_list->{ $subject },
                                         $msg );
   return $count;
}

sub search_for {
   my ($self, @args) = @_; my $c = $self->context;

   return $c->model( $self->domain_model_class )->search_for( @args );
}

sub search_form {
   my ($self, $action_name, $id_field, $value_field) = @_;

   $self->add_field ( { id => "${action_name}.${action_name}_instructions" } );
   $self->add_field ( { default => $self->query_value( $value_field ),
                        id => $action_name.q(.search_expression) } );
   $self->add_field ( { id => $action_name.q(.search) } );
   $self->add_field ( { id => $action_name.q(.clear) } );
   $self->stash_meta( { id => $self->query_value( $id_field ) } );
   return;
}

sub search_view {
   my ($self, $action, $query, $hits_per, $offset) = @_;

   $action or throw 'No action in search view';

   $query ||= NUL; $query =~ s{ \" }{}gmx; $query or return;

   $hits_per = $hits_per && $hits_per =~ m{ \d+ }mx ? $hits_per   : undef;
   $offset   = $offset   && $offset   =~ m{ \d+ }mx ? $offset - 1 : 0;

   my $args  = { hits_per     => $hits_per || $self->hits_per_page,
                 key          => $action.q(_search_heading),
                 offset       => $offset,
                 query        => $query,
                 search_field => $action eq q(catalog) ? q(title) : $action, };

   $self->search_page( $args );
   return $query;
}

sub update_links {
   my $self = shift;

   $self->update_group_membership( {
      add_method    => sub { $self->add_links_to_subject( @_ ) },
      delete_method => sub { $self->remove_links_from_subject( @_ ) },
      field         => q(links),
      method_args   => { subject => $self->query_value( q(subject) ) },
   } ) or throw 'Links not selected';

   return TRUE;
}

sub view {
   my ($self, $path) = @_; my $c = $self->context;

   $self->clear_form;

   $c->model( q(Navigation) )->select_this( 0, 1, {
      href => $c->uri_for_action( $c->action, $path ),
      text => $self->loc( 'View' ),
      tip  => $self->loc( 'Navigation' ).TTS.$path } );

   $self->add_field( { path => $path, subtype => q(html), type => q(file) } );
   return;
}

# Private methods

sub _get_catalog_data {
   my ($self, $args) = @_; my $nodes = $self->nodes;

   my $data = { catalogs => [], counts => {}, labels => {}, subjects => [] };

   # Read data from model
   for my $node ($nodes->search( { gid      => 2 },
                                 { join     => [ qw(names) ],
                                   order_by => q(names.text) } )) {
      if (my $nid = $node->nid) {
         $node->names->text and $data->{labels}->{ $nid } = $node->names->text;
         push @{ $data->{catalogs} }, $nid;
      }
   }

   unshift @{ $data->{catalogs} }, 0; $data->{labels}->{0} = NUL;

   for my $node ($nodes->search( { gid      => $args->{catalog} },
                                 { join     => [ qw(names) ],
                                   order_by => q(names.text) } )) {
      if (my $nid = $node->nid) {
         $node->names->text and $data->{labels}->{ $nid } = $node->names->text;
         $data->{counts}->{ $nid } = $nodes->count( { gid => $nid } );
         push @{ $data->{subjects} }, $nid;
      }
   }

   return $data;
}

# Private subroutines

sub __get_uri_args {
   my ($link, $seq_no) = @_; my @args = ();

   $link       and push @args, __split_on_sep( $link );
   $seq_no > 1 and push @args, $seq_no;

   return @args;
}

sub __split_on_sep {
   my $link = shift; my $url = $link->url; my $sep = SEP;

   $sep eq substr $url, 0, 1 and $url =~ s{ \A $sep }{%2F}mx;

   return $url ? split m{ $sep }mx, $url : ();
}

1;

__END__

=pod

=head1 Name

App::Munchies::Model::Catalog - Manipulate the library catalog database

=head1 Version

0.5.$Revision: 1233 $

=head1 Synopsis

   use <Module::Name>;
   # Brief but working code examples

=head1 Description

=head1 Subroutines/Methods

=head2 COMPONENT

=head2 add_links_to_subject

=head2 add_search_hit

=head2 catalog_form

=head2 collection_view_form

=head2 get_keys

=head2 get_link_url

=head2 grid_rows

=head2 grid_table

=head2 links

=head2 links_delete

=head2 links_view_form

=head2 links_insert

=head2 links_save

=head2 names

=head2 names_list

=head2 nodes

=head2 nodes_delete

=head2 nodes_view_form

=head2 nodes_insert

=head2 nodes_save

=head2 recatalog_exec

=head2 recatalog_form

=head2 remove_links_from_subject

=head2 search_for

=head2 search_form

=head2 search_view

=head2 update_links

=head2 view

=head1 Diagnostics

=head1 Configuration and Environment

=head1 Dependencies

=over 3

=item L<CatalystX::Usul::Model::Schema>

=item L<CatalystX::Usul::Constants>

=item L<CatalystX::Usul::Functions>

=item L<Data::CloudWeights>

=item L<HTML::Accessors>

=item L<MRO::Compat>

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
