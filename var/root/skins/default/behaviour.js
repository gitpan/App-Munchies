/* $Id: behaviour.js 599 2009-03-11 18:22:58Z pjf $ */

var State = new Class( {
   initialize: function( options ) {
      this.popup   = options.popup;
      this.assets  = options.assets;
      this.cookies = new Cookies( { path  : options.path,
                                    prefix: options.prefix } );
   },

   getAccordionHeight: function( elem ) {
      var togglers_len = $$( 'div.sidebarHeader' ).length;
      var height       = elem.getSize().size.y - ( 25 * togglers_len ) - 15;
      return Math.max( 1, height );
   },

   resize: function( changed ) {
      var append, content, elem;
      var elemHeight, elemWidth, grippy_height, offset, sb_height;
      var height = 5, h = window.getHeight(), w = window.getWidth();

      if (!this.popup) {
         this.cookies.set( 'width',  w );
         this.cookies.set( 'height', h );
      }

      window.defaultStatus = 'w: ' + w + ' h: ' + h;

      if (! (content = $( 'content' ))) return;

      if (elem = $( 'footerDisp' )) {
         elemHeight = elem.getStyle( 'height' ).toInt();
         height    += elem.getStyle( 'display' ) != 'none' ? elemHeight : 0;
      }

      if (append = $( 'append' )) {
         height += append.getStyle( 'height' ).toInt();

         if (elem = $( 'footerDisp' )) {
            if (elem.getStyle( 'display' ) != 'none') {
               elemHeight = elem.getStyle( 'height' ).toInt();
               append.setStyle( 'marginBottom', elemHeight + 'px' );
            }
            else { append.setStyle( 'marginBottom', '0px' ) }
         }
      }

      content.setStyle( 'marginBottom', height + 'px' );

      if (elem = $( 'sidebarDisp' )) {
         if (this.cookies.get( 'sidebar' )) elem.setStyle( 'display', '' );

         elem.setStyle( 'marginBottom', height + 'px' );

         // Calculate and set vertical offset for side bar grippy
         sb_height = elem.getSize().size.y;
         grippy_height = $( 'sidebarGrippy' ).getSize().size.y;
         offset = Math.max( 1, Math.round( sb_height / 2 )
                            - Math.round( grippy_height / 2 ) );
         $( 'sidebarGrippy' ).setStyle( 'marginTop', offset + 'px' );

         if (this.accordion) {
            this.accordion.resize( this.getAccordionHeight( elem ), null );
         }

         if (this.cookies.get( 'sidebar' )) {
            if (changed) {
               elemWidth = elem.getStyle( 'width' ).toInt();
               this.cookies.set( 'sidebarWidth',  elemWidth );
               this.slider.wrapper.setStyle( 'width', elemWidth + 'px' );
            }
            else {
               elemWidth = this.cookies.get( 'sidebarWidth' );
            }
         }
         else { elemWidth = 0 }

         elem.setStyle( 'width', elemWidth + 'px' );
         content.setStyle( 'marginLeft', elemWidth + 'px' );
      }
      else { content.setStyle( 'marginLeft', '0px' ) }

      if (elem = $( 'buttonDisp' )) {
         elemWidth = elem.getStyle( 'width' ).toInt();
         content.setStyle( 'marginRight', elemWidth + 'px' );
      }
      else { content.setStyle( 'marginRight', '0px' ) }

      return;
   },

   setState: function( first_fld ) {
      var cookie_ref, cookies, elem, height, i, p0, p1, pair;
      var sb_panel = 0, sb_state = false, sb_width = 150;

      /* Initialize the fading links event handlers */
      this.linkFade  = new LinkFader( { links: document.links,
                                        view : document.defaultView } );

      /* Use state cookie to restore the visual state of the page */
      if (cookie_ref = this.cookies.get()) {
         cookies = cookie_ref.split( '+' );

         for (i = 0; i < cookies.length; i++) {
            if (cookies[i]) {
               pair = cookies[ i ].split( '~' );
               p0 = unescape( pair[ 0 ] );
               p1 = unescape( pair[ 1 ] );

               /* Restore state of any checkboxes whose ids end in Box */
               if (elem = $( p0 + 'Box' )) {
                  elem.checked = (p1 == 'true' ? true : false);
               }

               /* Restore the state of any elements whose ids end in Disp */
               if (elem = $( p0 + 'Disp' )) {
                  elem.setStyle( 'display', (p1 != 'false' ? '' : 'none') );
               }

               /* Restore the source URL for elements whose ids end in Img */
               if (elem = $( p0 + 'Img' )) { if (p1) elem.src = p1; }

               /* Recover the width and panel number of the sidebar */
               if (p0 == 'sidebar') sb_state = true;
               if (p0 == 'sidebarWidth') sb_width = p1;
               if (p0 == 'sidebarPanel') sb_panel = p1;
            }
         }
      }

      /* If this page has a side bar */
      if (elem = $( 'sidebarDisp' )) {
         if (!this.cookies.get( 'sidebarWidth' )) {
            this.cookies.set( 'sidebarWidth', '150' );
         }

         height = this.getAccordionHeight( elem );

         /* Setup the slide in/out effect */
         this.slider = new Fx.Slide( 'sidebarContainer', {
            mode: 'horizontal',
            onComplete: function() {
               var sb_image = $( 'sidebarImg' );

               /* When the effect is complete toggle the state */
               if (this.cookies.get( 'sidebar' )) {
                  if (sb_image) sb_image.src = this.assets + 'pushedpin.gif';

                  panel = this.cookies.get( 'sidebarPanel' );
                  this.accordion.reload( panel );
                  this.accordion.display( panel );
               }
               else {
                  if (sb_image) sb_image.src = this.assets + 'pushpin.gif';

                  this.resize();
               }
            }.bind( this ),
         } );

         /* Setup the event handler to turn the side bar on/off */
         $( 'sidebar' ).addEvent( 'click', function( e ) {
            if (!this.cookies.get( 'sidebar' )) {
               this.cookies.set( 'sidebar', this.assets + 'pushedpin.gif' );
               this.resize();
               e = Event( e );
               this.slider.slideIn();
               e.stop();
            }
            else {
               this.cookies.delete( 'sidebar' );
               e = Event( e );
               this.slider.slideOut();
               e.stop();
            }
         }.bind( this ) );

         /* Setup the horizontal resize grippy for the side bar */
         $( 'sidebarGrippy' ).addEvent( 'mousedown', function( sidebar ) {
            sidebar.makeResizable( {
               modifiers:             { x: 'width', y: false },
               limit:                 { x: [ 150, 450 ] },
               onComplete: function() { this.detach() },
               onDrag:     function() { this.resize( true ) }.bind( this )
            } );
         }.bind( this, elem ) );

         /* Create an Accordion widget in the side bar */
         this.accordion
            = new Accordion( 'div.sidebarHeader', 'div.sidebarPanel', {
               fixedHeight : height,
               opacity     : false,
               onActive    : function( toggler, element ) {
                  toggler.setStyle( 'background-color', '#663' );
                  toggler.setStyle( 'color', '#FFC' );
                  behaviour.state.cookies.set
                     ( 'sidebarPanel', this.togglers.indexOf( toggler ) );
               },
               onBackground: function( toggler, element ) {
                  toggler.setStyle( 'background-color', '#CC9' );
                  toggler.setStyle( 'color', '#000' );
               }
            }, $( 'accordionDiv' ) );

         /* Redisplay and reload the last accordion side bar panel */
         if (sb_state) this.accordion.reload( sb_panel );

         this.accordion.display( sb_panel );
      }

      this.tips = new Tips( $$( '.tips' ), {
         initialize: function() {
		      this.fx = new Fx.Style( this.toolTip, 'opacity',
               { duration: 500, wait: false } ).set( 0 );
         },
	      onShow:     function( toolTip ) { this.fx.start( 1 ) },
         onHide:     function( toolTip ) { this.fx.start( 0 ) },
         showDelay:  666
      } );

      if (this.scroller) {
         this.scroller
            = new Scroller( 'content', { area: 150, velocity: 1 });

         $( 'content' ).addEvent( 'mousedown', function() {
            this.setStyle( 'cursor',
                           'url(/static/images/closedhand.cur), move' );
            this.scroller.start();
         } );

         $( 'content' ).addEvent( 'mouseup', function() {
            this.setStyle( 'cursor',
                           'url(/static/images/openhand.cur), move' );
            this.scroller.stop();
         } );
      }

      this.resize();

      if (first_fld && (elem = $( first_fld ))) elem.focus();
   },

   toggle: function( e ) {
      var elem = $( e.id + 'Disp' );

      if (elem.getStyle( 'display' ) != 'none') {
         elem.setStyle( 'display', 'none' ); this.cookies.delete( e.id );
      }
      else {
         elem.setStyle( 'display', '' ); this.cookies.set( e.id, 'true' );
      }

      this.resize();
   },

   toggleState: function( id ) {
      var elem = $( id + 'Box' );

      this.cookies.set( id, (elem.checked ? 'true' : 'false') );
   },

   toggleSwap: function( e, s1, s2 ) {
      var elem;

      if (elem = $( e.id + 'Disp' )) {
         if (elem.getStyle( 'display' ) !=  'none') {
            elem.setStyle( 'display', 'none' );
            this.cookies.delete( e.id );

            if (elem = $( e.id )) elem.setHTML( s2 );
         }
         else {
            elem.setStyle( 'display', '' );
            this.cookies.set( e.id, s2 );

            if (elem = $( e.id )) elem.setHTML( s1 );
         }
      }

      this.resize();
   },

   toggleSwapImg: function( e, s1, s2 ) {
      var elem;

      if (elem = $( e.id + 'Disp' )) {
         if (elem.getStyle( 'display' ) != 'none') {
            elem.setStyle( 'display', 'none' );
            this.cookies.delete( e.id );

            if (elem = $( e.id + 'Img' )) elem.src = s1;
         }
         else {
            elem.setStyle( 'display', '' );
            this.cookies.set( e.id, s2 );

            if (elem = $( e.id + 'Img' )) elem.src = s2;
         }
      }

      this.resize();
   },

   toggleSwapText: function( id, cookie, s1, s2 ) {
      var elem = $( id );

      if (this.cookies.get( cookie ) == 'true') {
         this.cookies.set( cookie, 'false' );

         if (elem) elem.setHTML( s2 );

         if (elem = $( cookie + 'Disp' )) elem.setStyle( 'display', 'none' );
      }
      else {
         this.cookies.set( cookie, 'true' );

         if (elem) elem.setHTML( s1 );

         if (elem = $( cookie + 'Disp' )) elem.setStyle( 'display', '' );
      }

      this.resize();
   }
} );

behaviour.freeList    = new FreeList(    { form  : behaviour.formName } );
behaviour.groupMember = new GroupMember( { form  : behaviour.formName } );
behaviour.loadMore    = new LoadMore(    { url   : behaviour.url } );
behaviour.server      = new ServerUtils( { url   : behaviour.url } );
behaviour.state       = new State(       { assets: behaviour.assetsPath,
                                           path  : behaviour.sessionPath,
                                           popup : behaviour.isPopup,
                                           prefix: behaviour.sessionPrefix } );
behaviour.submit      = new SubmitUtils( { form  : behaviour.formName,
                                           path  : behaviour.sessionPath,
                                           prefix: behaviour.sessionPrefix } );
behaviour.table       = new TableUtils(  { form  : behaviour.formName,
                                           url   : behaviour.url } );
behaviour.window      = new WindowUtils( { path  : behaviour.sessionPath,
                                           prefix: behaviour.sessionPrefix } );

function Expand_Collapse() {}

if (behaviour.target == 'top') behaviour.window.placeOnTop();

onresize = behaviour.state.resize( true );
