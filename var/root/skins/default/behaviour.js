/* $Id: behaviour.js 1272 2012-02-06 16:11:54Z pjf $ */

var Behaviour = new Class( {
   Implements: [ Events, Options ],

   options             : {
      config           : {
         anchors       : {},
         calendars     : {},
         lists         : {},
         liveGrids     : {
            iconClasses: [ 'down_point_icon', 'up_point_icon' ] },
         scrollPins    : { fadeInDuration: 1500, showDelay: 1000,
                           trayPadding   : 0 },
         server        : {},
         sidebars      : {},
         sliders       : {},
         spinners      : {
            defaults   : { hideOnClick   : true, shadow: true,
                           useIframeShim : false } },
         tables        : {},
         tabSwappers   : {
            defaults   : { smooth        : true, smoothSize: true } },
         tips          : { fadeInDuration: 500,  showDelay : 666  } },
      contentId        : 'content',
      cookieDomain     : '',
      cookiePath       : '/',
      cookiePrefix     : 'behaviour',
      defaultURL       : null,
      formName         : null,
      minMarginBottom  : 5,
      minMarginLeft    : 0,
      minMarginRight   : 10,
      popup            : false,
      target           : null
   },

   initialize: function( options ) {
      this.setOptions( options ); this.collection = [];

      this.config = Object.merge( this.options.config );

      window.addEvent( 'load',   function() {
         this.load( options.firstField ) }.bind( this ) );
      window.addEvent( 'resize', function() { this.resize() }.bind( this ) );
   },

   collect: function( object ) {
      this.collection.include( object ); return object;
   },

   getContentMarginBottom: function() {
      var content; if (! (content = $( this.options.contentId ))) return 0;

      return content.getStyle( 'marginBottom' ).toInt();
   },

   load: function( first_field ) {
      var cfg = this.config, el, opt = this.options;

      this.cookies = new Cookies( { domain: opt.cookieDomain,
                                    path  : opt.cookiePath,
                                    prefix: opt.cookiePrefix } );

      this.stylesheet = new PersistantStyleSheet( { cookies: this.cookies } );

      this._restoreStateFromCookie();

      this.checkboxReplacements = new CheckboxReplace( { callbacks: this } );

      var f_replace_boxes = function() {
         this.build() }.bind( this.checkboxReplacements );

      this.submit      = new SubmitUtils( {
         callbacks     : this,
         config        : cfg.anchors,
         formName      : opt.formName } );
      this.window      = new WindowUtils( {
         callbacks     : this,
         config        : cfg.anchors,
         cookieDomain  : opt.cookieDomain,
         cookiePath    : opt.cookiePath,
         cookiePrefix  : opt.cookiePrefix,
         target        : opt.target } );

      this.autosizer   = new AutoSize( { callbacks: this } );
      this.calendars   = new Calendars( {
         callbacks     : this,
         config        : cfg.calendars } );
      this.freeList    = new FreeList( { callbacks: this } );
      this.groupMember = new GroupMember( { callbacks: this } );
      this.liveGrids   = new LiveGrids( {
         callbacks     : this,
         config        : cfg.liveGrids,
         url           : opt.defaultURL } );
      this.rotateList  = new RotateList( {
         callbacks     : this,
         config        : cfg.lists } );
      this.server      = new ServerUtils( {
         callbacks     : this,
         config        : cfg.server,
         url           : opt.defaultURL } );
      this.sidebar     = new Sidebar ( {
         callbacks     : this,
         config        : cfg.sidebars } );
      this.sliders     = new Sliders( {
         callbacks     : this,
         config        : cfg.sliders } );
      this.spinners    = new Spinners( {
         callbacks     : this,
         config: cfg.spinners } );
      this.tables      = new TableUtils( {
         callbacks     : this,
         config        : cfg.tables,
         formName      : opt.formName,
         onRowAdded    : f_replace_boxes } );
      this.tableSort   = new TableSort( {
         callbacks     : this,
         onSortComplete: f_replace_boxes } );
      this.tabSwappers = new TabSwappers( {
         callbacks     : this,
         config        : cfg.tabSwappers } );
      this.togglers    = new Togglers( {
         callbacks     : this,
         config        : cfg.anchors } );
      this.trees       = new Trees( {
         callbacks     : this,
         cookieDomain  : opt.cookieDomain,
         cookiePath    : opt.cookiePath,
         cookiePrefix  : opt.cookiePrefix } );
      this.wysiwyg     = new WYSIWYG( { callbacks: this } );
      this.linkFade    = new LinkFader( { callbacks: this } );

      // TODO: This is clumsy and needs fixing
      if (window.Chosens  != undefined)
         this.chosens  = new Chosens( { callbacks: this } );
      if (window.Typeface != undefined)
         this.typeface = this.collect( window._typeface_js );

      this.resize();

      this.columnizers = new Columnizers( { callbacks: this } );
      this.scrollPins  = new ScrollPins( {
         config        : cfg.scrollPins,
         log           : this.window.log,
         onAttach      : function( el ) {
            this.addEvent( 'build', function() {
               this.set( 'opacity', 0 )
                   .set( 'tween', { duration: cfg.scrollPins.fadeInDuration } );
            }.bind( el.pin.markup ) );

            this.addEvent( 'show', function() {
               this.tween( 'opacity', 1 ) }.bind( el.pin.markup ) );
         },
         onInitialize  : function() {
            this.fireEvent.delay( cfg.scrollPins.showDelay, this, [ 'show' ] ) }
      } );
      this.tips        = new Tips( {
         callbacks     : this,
         onHide        : function() { this.fx.start( 0 ) },
         onInitialize  : function() {
            this.fx    = new Fx.Tween( this.tip, {
               duration: cfg.tips.fadeInDuration,
               property: 'opacity' } ).set( 0 ); },
         onShow        : function() { this.fx.start( 1 ) },
         showDelay     : cfg.tips.showDelay } );

      if (first_field && (el = $( first_field ))) el.focus();
   },

   rebuild: function() {
      this.collection.each( function( object ) { object.build() } );
   },

   resize: function() {
      var opt = this.options, h = window.getHeight(), w = window.getWidth();

      if (! opt.popup) {
         this.cookies.set( 'height', h ); this.cookies.set( 'width',  w );
         window.defaultStatus = 'w: ' + w + ' h: ' + h;
      }

      var content; if (! (content = $( opt.contentId ))) return;

      var foot_height = 0, margin_bottom = opt.minMarginBottom;

      var footer; if (footer = $( 'footerDisp' )) {
         foot_height = footer.isDisplayed()
                     ? footer.getStyle( 'height' ).toInt() : 0;
         margin_bottom += foot_height;
      }

      var append; if (append = $( 'appendDisp' )) {
         margin_bottom += append.getStyle( 'height' ).toInt();

         if (footer) append.setStyle( 'marginBottom', foot_height + 'px' );
      }

      content.setStyle( 'marginBottom', margin_bottom + 'px' );

      var sb = this.sidebar, margin_left = opt.minMarginLeft;

      if (sb) { sb.resize(); margin_left = sb.getWidth() }

      content.setStyle( 'marginLeft', margin_left + 'px' );

      var buttons = $( 'buttonDisp' ), margin_right = opt.minMarginRight;

      if (buttons) margin_right = buttons.getStyle( 'width' ).toInt();

      content.setStyle( 'marginRight', margin_right + 'px' );
      content.fireEvent( 'resize' );
   },

   _restoreStateFromCookie: function() {
      /* Use state cookie to restore the visual state of the page */
      var cookie_str; if (! (cookie_str = this.cookies.get())) return;

      var cookies = cookie_str.split( '+' ), el;

      for (var i = 0, cl = cookies.length; i < cl; i++) {
         if (! cookies[ i ]) continue;

         var pair = cookies[ i ].split( '~' );
         var p0   = unescape( pair[ 0 ] ), p1 = unescape( pair[ 1 ] );

         /* Restore the state of any elements whose ids end in Disp */
         if (el = $( p0 + 'Disp' )) { p1 != 'false' ? el.show() : el.hide(); }

         /* Restore the className for elements whose ids end in Icon */
         if (el = $( p0 + 'Icon' )) { if (p1) el.className = p1; }

         /* Restore the source URL for elements whose ids end in Img */
         if (el = $( p0 + 'Img'  )) { if (p1) el.src = p1; }
      }
   }
} );

/* Local Variables:
 * mode: javascript
 * tab-width: 3
 * End:
 */
