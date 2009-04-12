// @(#)$Id: 30ourtools.js 659 2009-04-10 11:39:14Z pjf $

/* Property: setHTML
      Sets the innerHTML of the Element. Should work for application/xhtml+xml

   Arguments:
      html - string; the new innerHTML for the element.

   Example:
      $('myElement').setHTML(newHTML) //the innerHTML of myElement
                                        is now = newHTML
*/

Element.extend({
   setHTML: function( html ) {
      while (this.firstChild) this.removeChild( this.firstChild );

      return HTMLtoDOM( html, this );
   }
});

/* Script: String.js
      Contains String prototypes.

   License:
      MIT-style license.

   Class: String
      A collection of The String Object prototype methods.
*/

String.extend({
   escapeHTML: function() {
      var text = this;
      text = text.replace( /\</g, '&lt;'   );
      text = text.replace( /\>/g, '&gt;'   );
      text = text.replace( /\"/g, '&quot;' );
      text = text.replace( /\&/g, '&amp;'  );
      return text;
   },

   unescapeHTML: function() {
      var text = this;
      text = text.replace( /\&lt\;/g,   '<' );
      text = text.replace( /\&gt\;/g,   '>' );
      text = text.replace( /\&quot\;/g, '"' );
      text = text.replace( /\&amp\;/g,  '&' );
      return text;
   }
});

/*
Script: Accordion.js
   Contains <Accordion>

License:
   MIT-style license.

Class: Accordion
   The Accordion class creates a group of elements that
   are toggled when their handles are clicked. When one elements
   toggles in, the others toggles back.  Inherits methods, properties,
   options and events from <Fx.Elements>.

Note:
   The Accordion requires an XHTML doctype.

Arguments:
   togglers - required, a collection of elements, the elements handlers
              that will be clickable.
   elements - required, a collection of elements the transitions will
              be applied to.
   options  - optional, see options below, and <Fx.Base> options and events.

Options:
   show - integer, the Index of the element to show at start.
   display - integer, the Index of the element to show at start (with
             a transition). defaults to 0.
   fixedHeight - integer, if you want the elements to have a fixed
                 height. defaults to false.
   fixedWidth - integer, if you want the elements to have a fixed
                width. defaults to false.
   height - boolean, will add a height transition to the accordion if
            true. defaults to true.
   opacity - boolean, will add an opacity transition to the accordion
             if true. defaults to true.
   width - boolean, will add a width transition to the accordion if
           true. defaults to false, css mastery is required to make this work!
   alwaysHide - boolean, will allow to hide all elements if true,
                instead of always keeping one element shown. defaults to false.
Events:
   onActive - function to execute when an element starts to show
   onBackground - function to execute when an element starts to hide
*/

var Accordion = Fx.Elements.extend({
   options: {
      onActive: Class.empty,
      onBackground: Class.empty,
      display: 0,
      show: false,
      height: true,
      width: false,
      opacity: true,
      fixedHeight: false,
      fixedWidth: false,
      wait: false,
      alwaysHide: false
   },

   initialize: function() {
      var options, togglers, elements, container;

      $each( arguments, function( argument, i ) {
         switch( $type( argument ) ) {
            case 'object' : options   = argument;      break;
            case 'element': container = $( argument ); break;
            default       : var temp = $$( argument );
                            if (!togglers) togglers = temp;
                            else elements = temp;
         }
      } );

      this.previous  = -1;
      this.togglers  = togglers || [];
      this.elements  = elements || [];
      this.container = $( container );
      this.setOptions( options );

      if (this.options.alwaysHide) this.options.wait = true;

      if ($chk( this.options.show )){
         this.options.display = false; this.previous = this.options.show;
      }

      if (this.options.start){
         this.options.display = false; this.options.show = false;
      }

      this.effects = {};

      if (this.options.opacity) this.effects.opacity = 'fullOpacity';

      if (this.options.width)
         this.effects.width = this.options.fixedWidth
                            ? 'fullWidth' : 'offsetWidth';

      if (this.options.height)
         this.effects.height = this.options.fixedHeight
                             ? 'fullHeight' : 'scrollHeight';

      for (var i = 0, l = this.togglers.length; i < l; i++)
         this.addSection( this.togglers[ i ], this.elements[ i ] );

      this.elements.each( function( el, i ) {
         if (this.options.show === i){
            this.fireEvent( 'onActive', [ this.togglers[ i ], el ] );
         }
         else {
            for (var fx in this.effects) el.setStyle( fx, 0 );
         }
      }, this );

      this.parent( this.elements );

      if ($chk( this.options.display )) this.display( this.options.display );
   },

   /*
   Property: addSection
      Dynamically adds a new section into the accordion at the
      specified position.

   Arguments:
      toggler - (dom element) the element that toggles the accordion
                section open.
      element - (dom element) the element that stretches open when the
                toggler is clicked.
      pos     - (integer) the index where these objects are to be inserted
                within the accordion.
   */

   addSection: function(toggler, element, pos){
      toggler = $(toggler);
      element = $(element);
      var test = this.togglers.contains(toggler);
      var len = this.togglers.length;
      this.togglers.include(toggler);
      this.elements.include(element);
      if (len && (!test || pos)){
         pos = $pick(pos, len - 1);
         toggler.injectBefore(this.togglers[pos]);
         element.injectAfter(toggler);
      }
      else if (this.container && !test){
         toggler.inject(this.container);
         element.inject(this.container);
      }
      var idx = this.togglers.indexOf(toggler);
      toggler.addEvent('click', this.display.bind(this, idx));
      if (this.options.height)
         element.setStyles({ 'padding-top': 0, 'padding-bottom': 0 });
      if (this.options.width)
         element.setStyles({ 'padding-left': 0, 'padding-right': 0 });
      element.fullOpacity = 1;
      if (this.options.fixedWidth)
         element.fullWidth = this.options.fixedWidth;
      if (this.options.fixedHeight)
         element.fullHeight = this.options.fixedHeight;
      element.setStyle('overflow', 'hidden');
      if (!test){
         for (var fx in this.effects) element.setStyle(fx, 0);
      }
      return this;
   },

   /*
   Property: display
      Shows a specific section and hides all others. Useful when
      triggering an accordion from outside.

   Arguments:
      index - integer, the index of the item to show, or the actual
              element to show.
   */

   display: function(index){
      index = ($type(index) == 'element')
            ? this.elements.indexOf(index) : index;

      if (index >= this.elements.length) index = 0;

      if ((this.timer && this.options.wait)
          || (index === this.previous
              && !this.options.alwaysHide)) return this;

      var obj = {};
      this.previous = index;
      this.elements.each(function(el, i){
         obj[i] = {};
         var hide = (i != index)
            || (this.options.alwaysHide && (el.offsetHeight > 0));
         this.fireEvent(hide ? 'onBackground' : 'onActive',
                        [this.togglers[i], el]);
         for (var fx in this.effects)
            obj[i][fx] = hide ? 0 : el[this.effects[fx]];
      }, this);
      return this.start(obj);
   },

   showThisHideOpen: function( index ) { return this.display( index ) },

   redisplay: function() {
      var index = this.previous;
      this.previous = -1;
      return this.display( index );
   },

   reload: function( index ) {
      if (!index || index >= this.togglers.length) index = 0;
      if (!($defined( this.togglers[ index ] )
            && $defined( this.togglers[ index ].onclick ))) return;
      this.togglers[ index ].onclick();
   },

   resize: function( height, width ) {
      this.elements.each( function( el ) {
         if (height) el.fullHeight = this.options.fixedHeight = height;
         if (width)  el.fullWidth  = this.options.fixedWidth  = width;
      }, this );
      return this.redisplay();
   }
});

Fx.Accordion = Accordion;

var Cookies = new Class({
   options: {
      domain: '',
      expire: 90,
      name  : 'state',
      path  : '/',
      secure: false
   },

   initialize: function( options ) {
      this.setOptions( options );

      if (options.prefix)
         this.cname = options.prefix + '_' + this.options.name;
      else this.cname = this.options.name;

      this.copts = { duration: this.options.expire,
                     path    : this.options.path,
                     domain  : this.options.domain,
                     secure  : this.options.secure };
   },

   delete: function( name ) {
      var i, j, opts, pair, val = Cookie.get( this.cname );

      if (val && name) name = escape(name);
      else return false;

      if ((i = val.indexOf( name + '~' )) < 0) return false;

      j = val.substring(i).indexOf( '+' );

      if (i == 0) val = (j < 0) ? '' : val.substring( j + 1 );

      if (i > 0) {
         val = (j < 0) ? val.substring( 0, i - 1 )
                       : val.substring( 0, i - 1 ) + val.substring( i + j );
      }

      return Cookie.set( this.cname, val, this.copts );
   },

   get: function( name ) {
      var cookies, i, pair, val = Cookie.get( this.cname );

      if (name && val) {
         cookies = val.split( '+' );

         for (i = 0; i < cookies.length; i++) {
            pair = cookies[i].split( '~' );

            if (unescape( pair[0] ) == name) return unescape( pair[1] );
         }

         return '';
      }

      return val;
   },

   set: function( name, cookie ) {
      var i, j, opts, pair, val = Cookie.get( this.cname );

      if (name) name = escape( name );
      else return;

      if (cookie) cookie = escape( cookie );

      if (val) {
         if ((i = val.indexOf( name + '~' )) >= 0) {
            j = val.substring( i ).indexOf( '+' );

            if (i == 0) {
               val = (j < 0) ? name + '~' + cookie
                             : name + '~' + cookie + val.substring( j );
            }
            else {
               val = (j < 0) ? val.substring( 0, i ) + name + '~' + cookie
                             : val.substring( 0, i ) + name + '~' + cookie
                               + val.substring( i + j );
            }
         }
         else { val += '+' + name + '~' + cookie }
      }
      else { val = name + '~' + cookie }

      return Cookie.set( this.cname, val, this.copts );
   }
});

Cookies.implement( new Options );

var FreeList = new Class({
   initialize: function( options ) {
      this.form = options.form;
   },

   addItem: function( name ) {
      var form     = document.forms[ this.form ];
      var new_elem = form.elements[ name + '_new' ];
      var cur_elem = form.elements[ name + '_current' ];

      cur_elem.options[ cur_elem.length ] = new Option( new_elem.value );
      this.createHidden( form, name, new_elem.value );
      new_elem.value = '';
      return false;
   },

   createHidden: function( form, name, val ) {
      var row_elem = form.elements[ name + '_n_rows' ];
      var nrows    = parseInt( row_elem.value, 10 );

      hidden = document.createElement( 'input' );
      hidden.setAttribute( 'type', 'hidden' );
      hidden.setAttribute( 'id', name + nrows );
      hidden.setAttribute( 'name', name );
      hidden.setAttribute( 'value', val );
      $( 'body' ).appendChild( hidden );
      row_elem.value = nrows + 1;
      return;
   },

   deleteHidden: function( form, name, val ) {
      var row_elem = form.elements[ name + '_n_rows' ];
      var nrows    = parseInt( row_elem.value, 10 );
      var hidden;

      for (var i = 0; i < nrows; i++) {
         if ((hidden = $( name + i )) && (hidden.value == val)) {
            hidden.remove(); row_elem.value = nrows - 1;
            return true;
         }
      }

      return false;
   },

   removeItem: function(name) {
      var form     = document.forms[ this.form ];
      var cur_elem = form.elements[ name + '_current' ];

      for (var i = cur_elem.length - 1; i >= 0; i--) {
         if (cur_elem.options[ i ].selected == true) {
            this.deleteHidden( form, name, cur_elem.options[ i ].value );
            cur_elem.options[ i ] = null;
         }
      }

      return false;
   }
});

var GroupMember = new Class({
   initialize: function( options ) {
      this.form = options.form;
   },

   addItem: function( name ) {
      var form     = document.forms[ this.form ];
      var all_elem = form.elements[ name + '_all' ];
      var cur_elem = form.elements[ name + '_current' ];

      for (var i = all_elem.length - 1; i >= 0; i--) {
         if (all_elem.options[ i ].selected == true) {
            var val = all_elem.options[ i ].value;
            cur_elem.options[ cur_elem.length ] = all_elem.options[ i ];

            if(!this.deleteHidden( form, name, 'deleted', val )) {
               this.createHidden( form, name, 'added', val );
            }

            // This suddenly started happening, weird but works after v0.1.657
            //            all_elem.options[ i ] = null;
         }
      }

      return false;
   },

   createHidden: function( form, name, type, val ) {
      var row_elem = form.elements[ name + '_n_' + type ];
      var nrows    = parseInt( row_elem.value, 10 );

      hidden = document.createElement( 'input' );
      hidden.setAttribute( 'type', 'hidden' );
      hidden.setAttribute( 'id', name + '_' + type + nrows );
      hidden.setAttribute( 'name', name + '_' + type );
      hidden.setAttribute( 'value', val );
      $( 'body' ).appendChild( hidden );
      row_elem.value = nrows + 1;
      return;
   },

   deleteHidden: function( form, name, type, val ) {
      var row_elem = form.elements[ name + '_n_' + type ];
      var nrows    = parseInt( row_elem.value, 10 );
      var hidden;

      for (var i = 0; i < nrows; i++) {
         if ((hidden = $( name + '_' + type + i )) && (hidden.value == val)) {
            hidden.remove(); row_elem.value = nrows - 1;
            return true;
         }
      }

      return false;
   },

   removeItem: function( name ) {
      var form     = document.forms[ this.form ];
      var all_elem = form.elements[ name + '_all' ];
      var cur_elem = form.elements[ name + '_current' ];

      for (var i = cur_elem.length - 1; i >= 0; i--) {
         if (cur_elem.options[ i ].selected == true) {
            var val = cur_elem.options[ i ].value;
            all_elem.options[ all_elem.length ] = cur_elem.options[ i ];

            if (!this.deleteHidden( form, name, 'added', val )) {
               this.createHidden( form, name, 'deleted', val );
            }

            // This suddenly started happening, weird but works after v0.1.657
            //            cur_elem.options[ i ] = null;
         }
      }

      return false;
   }
});

var LinkFader = new Class({
   options: {
      cn   : 'Fade',             // Class name matching links to fade
      inBy : 6,                  // Fade in colour inc/dec by
      outBy: 6,                  // Fade out colour inc/dec by
      speed: 20,                 // Millisecs between colour changes
      fc   : 'ff0000'            // Fade to colour
   },

   initialize: function( options ) {
      var i, ignoreIt, link;

      this.setOptions( options );
      this.links  = options.links || document.links;
      this.view   = options.view  || document.defaultView;
      this.colour = null;        // Store links original colour
      this.linkNo = 0;           // Index of currently fading link
      this.timer  = null;        // Interval object

      for (i = 0; i < this.links.length; i++) {
         link     = this.links[ i ];
         ignoreIt = link.className.indexOf( this.options.cn ) < 0;

         if (!ignoreIt) {
            if (!link.id) link.id = 'link' + i;

            if (!link.onmouseover && !link.onmouseout) {
               link.onmouseover = this.startFade.bind( this, link.id );
               link.onmouseout  = this.clearFade.bind( this, link.id );
            }
         }
      }
   },

   clearFade: function( id ) {
      if (this.timer) { clearInterval( this.timer ); this.timer = null }

      this.timer = setInterval( this.fade.bind( this ), this.options.speed, 0);
   },

   currentColour: function( index ) {
      var cc, i, style, temp = '';

      style = this.view.getComputedStyle( this.links[index], '' );
      cc    = style.getPropertyValue( 'color' );

      if (cc.length == 4 && cc.substring( 0, 1 ) == '#') {
         for (i = 0; i < 3; i++) {
            temp += cc.substring( i + 1, i + 2 ) + cc.substring( i + 1, i + 2);
         }

         cc = temp;
      }
      else if (cc.indexOf('rgb') != -1) { cc = cc.rgbToHex().substring(1, 7) }
      else if (cc.length == 7)          { cc = cc.substring( 1, 7 ) }
      else                              { cc = this.options.fc }

      return cc;
   },

   fade: function( d ) {
      var cc = new Array(), tc = new Array();

      if (d == 1) tc = this.options.fc.hexToRgb( true );
      else tc = this.colour ? this.colour.hexToRgb( true ) : [ 0, 0, 0 ];

      cc = this.currentColour( this.linkNo ).hexToRgb( true );

      if (tc[ 0 ] == cc[ 0 ] && tc[ 1 ] == cc[ 1 ] && tc[ 2 ] == cc[ 2 ]) {
         clearInterval( this.timer ); this.timer = null;
         return;
      }

      this.links[ this.linkNo ].style.color = this.nextColour( tc, cc, d );
   },

   nextColour: function( tc, cc, d ) {
      var change, colour, diff, i, nc;

      for (i = 0; i < 3; i++) {
         if (d == 1) { change = this.options.inBy }
         else { change = this.options.outBy }

         if (!colour) colour = 'rgb(';
         else colour += ',';

         nc = cc[ i ];

         if (tc[ i ]-cc[ i ] > 0) { diff   = tc[ i ] - cc[ i ] }
         else                     { diff   = cc[ i ] - tc[ i ] }
         if (diff  < change)      { change = diff }
         if (cc[ i ] > tc[ i ])   { nc     = cc[ i ] - change }
         if (cc[ i ] < tc[ i ])   { nc     = cc[ i ] + change }
         if (nc    < 0)           { nc     = 0 }
         if (nc    > 255)         { nc     = 255 }

         colour += nc;
      }

      colour += ')';
      return colour;
   },

   startFade: function( id ) {
      if (this.timer) {
         clearInterval( this.timer ); this.timer = null;

         if (this.colour) {
            this.links[ this.linkNo ].style.color = this.colour.hexToRgb();
         }
      }

      for (var i = 0; i < this.links.length; i++) {
         if (id == this.links[ i ].id) {
            this.linkNo = i;
            this.colour = this.currentColour( i );
            this.timer  = setInterval( this.fade.bind( this ),
                                       this.options.speed, 1);
            return;
         }
      }
   }
});

LinkFader.implement( new Options );

var LiveGridMetaData = new Class({
   initialize: function( options ) {
      this.bufferSize   = options.bufferSize   || 7;
      this.onscroll     = options.onscroll     || null;
      this.onscrollidle = options.onscrollidle || null;
      this.pageSize     = options.pageSize     || 10;
      this.totalRows    = options.totalRows    || 0;
   },

   getBufferSize: function()    { return this.bufferSize },

   getPageSize:   function()    { return this.pageSize },

   getTotalRows:  function()    { return this.totalRows },

   setTotalRows:  function( n ) { this.totalRows = n }
});

var LiveGridScroller = new Class({
   initialize: function( liveGrid ) {
      this.isIE = navigator.userAgent.toLowerCase().indexOf('msie') >= 0;
      this.liveGrid = liveGrid;
      this.metaData = liveGrid.metaData;
      this.scrollTimeout = null;
      this.lastScrollPos = 0;
      this.createScrollBar();
   },

   isUnPlugged: function() { return this.scrollerDiv.onscroll == null },

   plugin: function() {
      this.scrollerDiv.onscroll = this.handleScroll.bindAsEventListener(this);
   },

   unplug: function() { this.scrollerDiv.onscroll = null },

   createScrollBar: function() {
      var table              = this.liveGrid.table;
      var visibleHeight      = table.offsetHeight;
      this.lineHeight        = visibleHeight / this.metaData.getPageSize();
      this.scrollerDiv       = document.createElement( 'div' );
      var scrollerStyle      = this.scrollerDiv.style;
      scrollerStyle.position = 'relative';
      scrollerStyle.left     = this.isIE ? '-6px' : '-4px';
      scrollerStyle.width    = '19px';
      scrollerStyle.height   = visibleHeight + 'px';
      scrollerStyle.overflow = 'auto';

      if (this.isIE) {
         table.onmousewheel =
            function( evt ) {
               if (event.wheelDelta>=0) {//wheel-up
                  this.scrollerDiv.scrollTop -= this.lineHeight;
               }
               else { this.scrollerDiv.scrollTop += this.lineHeight }

               this.handleScroll( true );
            }.bind( this );
      } else {
        table.addEventListener( 'DOMMouseScroll',
            function( evt ) {
                if (evt.detail < 0) { //wheel-up
                   this.scrollerDiv.scrollTop -= this.lineHeight;
                }
                else { this.scrollerDiv.scrollTop += this.lineHeight }

                this.handleScroll( true );
            }.bind( this ), true );
      }

      // create the inner div...
      this.heightDiv = document.createElement( 'div' );
      this.heightDiv.style.width  = '1px';
      this.heightDiv.style.height = parseInt(visibleHeight *
            this.metaData.getTotalRows()/this.metaData.getPageSize()) + 'px' ;

      this.scrollerDiv.appendChild(this.heightDiv);
      this.scrollerDiv.onscroll = this.handleScroll.bindAsEventListener(this);
      table.parentNode.parentNode.insertBefore( this.scrollerDiv,
                                                table.parentNode.nextSibling );
   },

   updateSize: function() {
      var table = this.liveGrid.table;
      var visibleHeight = table.offsetHeight;
      this.heightDiv.style.height = parseInt(visibleHeight *
            this.metaData.getTotalRows()/this.metaData.getPageSize()) + 'px';
   },

   adjustScrollTop: function() {
      this.unplug();
      var rem = this.scrollerDiv.scrollTop % this.lineHeight;

      if (rem != 0) {
         if (this.lastScrollPos < this.scrollerDiv.scrollTop) {
            this.scrollerDiv.scrollTop = this.scrollerDiv.scrollTop
               + this.lineHeight - rem;
         }
         else {
            this.scrollerDiv.scrollTop = this.scrollerDiv.scrollTop - rem;
         }
      }

      this.lastScrollPos = this.scrollerDiv.scrollTop;
      this.plugin();
   },

   moveScroll: function( rowOffset ) {
      var pixelOffset = (rowOffset / this.metaData.getTotalRows())
                           * this.heightDiv.offsetHeight;
      this.scrollerDiv.scrollTop = pixelOffset;
   },

   handleScroll: function( skiptimeout ) {
      if ( this.scrollTimeout ) clearTimeout( this.scrollTimeout );

      var contentOffset = parseInt( this.scrollerDiv.scrollTop *
                 this.metaData.getTotalRows() / this.heightDiv.offsetHeight );

      if ( this.metaData.onscroll )
         this.metaData.onscroll( contentOffset, this.metaData );

      if (skiptimeout == true) { this.scrollIdle() }
      else {
        this.scrollTimeout = setTimeout( this.scrollIdle.bind( this ), 100 );
      }
   },

   scrollIdle: function() {
      if ( this.scrollTimeout ) clearTimeout( this.scrollTimeout );

      // this.adjustScrollTop();
      var contentOffset = parseInt( this.scrollerDiv.scrollTop *
                 this.metaData.getTotalRows() / this.heightDiv.offsetHeight );
      this.liveGrid.requestContentRefresh( contentOffset );

      if ( this.metaData.onscrollidle ) this.metaData.onscrollidle();
   }
});

var LiveGridBuffer = new Class({
   initialize: function( metaData ) {
      this.start    = 0;
      this.size     = 0;
      this.metaData = metaData;
      this.rows     = new Array();
   },

   update: function(text, xml) {
      this.start = parseInt( xml.documentElement.getAttribute( 'offset' ) );
      this.size  = parseInt( xml.documentElement.getAttribute( 'count' ) );
      var rows   = xml.documentElement.getElementsByTagName( 'items' );

      for (var i = 0; i < this.size; i++) {
         this.rows[this.start + i]
            = rows[ i ].childNodes[ 0 ].nodeValue.unescapeHTML();
      }
   },

   isClose: function( start ) {
      return this.rows[start]
             || this.rows[start + this.metaData.getPageSize()];
   },

   isFullyInRange: function( start ) {
      return this.rows[start]
             && this.rows[start + this.metaData.getPageSize()];
   },

   needsPrevPage: function( start ) {
      return !this.rows[start - this.metaData.getPageSize()];
   },

   needsNextPage: function( start ) {
      return !this.rows[start + 2 * this.metaData.getPageSize()];
   },

   needsMorePages: function( start ) {
      return this.needsPrevPage( start ) || this.needsNextPage( start );
   },

   getRows: function( start ) {
      return this.rows.slice( start, start + this.metaData.getPageSize() );
   }
});

var LiveGridRequest = new Class({
   initialize: function( requestOffset, options ) {
      this.requestOffset = requestOffset;
   }
});

var LiveGrid = new Class({
   initialize: function( tableId, url, options ) {
      if ( options == null ) options = {};

      this.url      = url;
      this.options  = options;
      this.tableId  = tableId;
      this.table    = $( tableId );
      this.metaData = new LiveGridMetaData( options );
      this.buffer   = new LiveGridBuffer( this.metaData );

      this.lastDisplayedStartPos = -1;
      this.timeoutHander         = null;
      this.additionalParms       = options.requestParameters || '';
      this.processingRequest     = null;
      this.unprocessedRequest    = null;

      if (options.prefetchBuffer || options.prefetchOffset) {
         var offset = 0;

         if (options.prefetchOffset) {
            this.scroller.moveScroll( options.prefetchOffset );
            offset = options.prefetchOffset;
         }

         this.fetchBuffer( offset, false );
      }
      else { this.scroller = new LiveGridScroller( this ) }
   },

   setRequestParams: function( params ) {
      this.additionalParms = params;
   },

   setTotalRows: function( newTotalRows ) {
      this.metaData.setTotalRows( newTotalRows );
      this.scroller.updateSize();
   },

   handleTimedOut: function() {
      //server did not respond in n secs assume that there could have been
      //an error or something, and allow requests to be processed again...
      this.processingRequest = null;
      this.processQueuedRequest();
   },

   fetchBuffer: function( offset, sequence_buffers ) {
      var page, page_size;

      if (this.processingRequest) {
         this.unprocessedRequest = new LiveGridRequest( offset );
         return;
      }

      this.processingRequest = new LiveGridRequest( offset );

      page_size = this.metaData.getBufferSize() * this.metaData.getPageSize();
      page      = Math.floor( offset / page_size );

      if (sequence_buffers) {
         page  += offset - page * page_size > page_size / 2 ? 1 : -1;
      }

      if (page < 0) page = 0;

      var callParms = 'content-type=text/xml&id=' + this.tableId
                    + '&page=' + page + '&page_size=' + page_size;

      if (this.additionalParms.length) {
         callParms = callParms + '&' + this.additionalParms;
      }

      if (!this.ajaxRequest) {
         var options = { data: callParms, method: 'get' };
         Object.extend( options, this.options );
         options.onComplete = this.ajaxUpdate.bind( this );
         this.ajaxRequest = new Ajax( this.url, options )
         this.ajaxRequest.request();
      }
      else {
         Object.extend( this.ajaxRequest.options, { data: callParms } );
         this.ajaxRequest.request();
      }

      this.timeoutHandler = setTimeout(this.handleTimedOut.bind(this), 10000);
   },

   requestContentRefresh: function( offset ) {
      if ( this.buffer.isFullyInRange( offset ) ) {
         this.updateContent( offset );

         if (this.buffer.needsMorePages( offset )) {
            this.fetchBuffer( offset, true );
         }
      }
      else if (this.buffer.isClose( offset )) {
         this.fetchBuffer( offset, true );
      }
      else { this.fetchBuffer( offset, false ) }
   },

   ajaxUpdate: function( text, xml ) {
      clearTimeout( this.timeoutHandler );

      try {
         var totalrows =  xml.documentElement.getAttribute( 'totalcount' );
         if (totalrows) this.setTotalRows( totalrows );
      }
      catch (err) {}

      this.buffer.update( text, xml );

      if (this.unprocessedRequest == null) {
         this.updateContent( this.processingRequest.requestOffset );
      }

      this.processingRequest = null;

      if (!this.scroller) {
         this.scroller = new LiveGridScroller( this );

         if (this.options.onFirstContent) this.options.onFirstContent( this );
      }

      if (this.options.onComplete) this.options.onComplete( this );

      this.processQueuedRequest();
   },

   processQueuedRequest: function() {
      if (this.unprocessedRequest != null) {
         this.requestContentRefresh( this.unprocessedRequest.requestOffset );
         this.unprocessedRequest = null
      }
   },

   updateContent: function( offset ) {
      this.replaceCellContents( this.buffer, offset );
   },

   replaceCellContents: function( buffer, start ) {
      if (start == this.lastDisplayedStartPos) return;

      this.table.setHTML( buffer.getRows( start ).join( '' ) );
      this.lastDisplayedStartPos = start
   }
});

var LoadMore = new Class({
   initialize: function( options ) {
      this.url = options.url;
   },

   request: function( action, id, val ) {
      new Ajax( this.url + action,
         { method    : 'get',
           data      : 'content-type=text/xml&id=' + id + '&val=' + val,
           onComplete: this.updateContent } ).request();
   },

   updateContent: function( text, xml ) {
      var html = '';
      var id   = xml.documentElement.getAttribute( 'id' );
      var rows = xml.documentElement.getElementsByTagName( 'items' );
      $each( rows, function( row ) { html += row.childNodes[ 0 ].nodeValue } );
      $( id ).setHTML( html.unescapeHTML() );
   }
});

var ServerUtils = new Class({
   initialize: function( options ) {
      this.url = options.url;
   },

   checkField: function( id, val ) {
      new Ajax( this.url + 'check_field',
         { method    : 'get',
           data      : 'content-type=text/xml&id=' + id + '&val=' + val,
           onComplete: this.updateClass } ).request();
   },

   postData: function( url, data ) {
      new Ajax( url, { method: 'post', data: data } ).request();
   },

   updateClass: function( text, xml ) {
      var id = xml.documentElement.getAttribute( 'id' );
      $( id ).className = xml.documentElement.getAttribute( 'result' );
   }
});

ServerUtils.implement( new Options() );

var SubmitUtils = new Class({
   initialize: function( options ) {
      this.form    = options.form;
      this.cookies = new Cookies( { path:   options.path,
                                    prefix: options.prefix } );
   },

   chooser: function( field, button, url, winPrefs ) {
      var form  = document.forms[ this.form ];
      var value = form.elements[ field ].value;

      if (value && value.indexOf( '%' ) < 0) {
         if (button) {
            form.elements[ '_method' ].value = button; form.submit();
         }

         return false;
      }

      top.chooser = window.open( url + '?form=' + this.form + '&value=' +value,
                                 'chooser', winPrefs );
      top.chooser.opener = top;
      return false;
   },

   confirmSubmit: function( key, text ) {
      if (text.length < 1 || window.confirm( text )) {
         this.submitForm( key );
         return true;
      }

      return false;
   },

   refresh: function( name, value ) {
      this.cookies.set( name, value ); document.forms[ this.form ].submit();
   },

   returnValue: function( form, name, value ) {
      var field = opener.document.forms[ form ].elements[ name ];

      if (field) {
         field.value = value;

         if (field.focus) field.focus();
      }

      window.close();
      return false;
   },

   setField: function( name, value ) {
      var form = document.forms[ this.form ];
      form.elements[ name ].value = value;
   },

   submitForm: function( key ) {
      var form = document.forms[ this.form ];
      form.elements[ '_method' ].value = key;
      form.submit();
   },

   submitOnReturn: function( evt, key ) {
      var code = evt.which;

      if (code == 13) {
         if (document.forms) this.submitForm( key );
         else window.alert( 'Document contains no forms' );
      }

      return false;
   }
});

var TableUtils = new Class({
   initialize: function( options ) {
      this.form = options.form;
      this.url  = options.url;
   },

   addTableRow: function( name, edit ) {
      var aelem, cell, cNo = 0, elem, fld, nelem, nrows, row;
      var form = document.forms[ this.form ];

      if (nelem = form.elements[ name + '_nrows' ]) {
         nrows = nelem.value ? parseInt( nelem.value, 10 ) : 0;

         if (elem = $( name + '_add' )) {
            row = document.createElement( 'tr' );
            row.setAttribute( 'id', name + '_row' + nrows );

            while (aelem = $( name + '_add' + cNo )) {
               if (edit) {
                  fld = document.createElement( 'input' );
                  fld.setAttribute( 'value', aelem.value );
                  fld.setAttribute( 'type', 'input' );
                  fld.setAttribute( 'name', aelem.name + nrows );
                  if (aelem.size) { fld.setAttribute( 'size', aelem.size ) }
                  if (aelem.maxlength) {
                     fld.setAttribute( 'maxlength', aelem.maxlength );
                  }
               }
               else {
                  fld = document.createTextNode( aelem.value );
               }

               cell = document.createElement( 'td' );
               cell.appendChild( fld );
               row.appendChild( cell );
               aelem.value = ''; cNo++;
            }

            if (edit) {
               fld = document.createElement( 'input' );
               fld.setAttribute( 'name', name + '_select' + nrows );
               fld.setAttribute( 'type', 'checkbox' );
               cell = document.createElement( 'td' );
               cell.setAttribute( 'align', 'center' );
               cell.setAttribute( 'class', (cNo%2 == 0 ? 'even' : 'odd') );
               cell.appendChild( fld );
               row.appendChild( cell );
            }

            elem.parentNode.insertBefore( row, elem );
            nelem.value = nrows + 1;
         }
      }

      return false;
   },

   createGrid: function( text, xml ) {
      var keyid  = this.gridKey + this.gridId;
      var count  = parseInt( xml.documentElement.getAttribute( 'totalcount' ));
      var html   = '';
      var opts   = {
         bufferSize    : 7,
         pageSize      : 10,
         prefetchBuffer: true,
         onscroll      : this.updateHeader.bind( this ),
         onFirstContent: this.updateHeader.bind( this, 0 ),
         totalRows     : count
      };
      var rows   = xml.documentElement.getElementsByTagName( 'items' );
      var urlkey = this.url + this.gridKey + '_grid_rows';

      $each( rows, function( row ) { html += row.childNodes[ 0 ].nodeValue } );
      $( keyid + 'Disp' ).setHTML( html.unescapeHTML() );
      this.gridObj = new LiveGrid( keyid + '_grid', urlkey, opts );
   },

   removeTableRow: function( name ) {
      var count, elem, hidden, i, nelem, nrows;
      var form = document.forms[ this.form ];

      if (nelem = form.elements[ name + '_nrows' ]) {
         nrows = parseInt( nelem.value, 10 ); count = 0;

         for (i = 0; i < nrows; i++) {
            if (elem = form.elements[ name + '_select' + i ]) {
               if (elem.checked) {
                  if (elem = $( name + '_row' + i )) {
                     elem.parentNode.removeChild( elem );
                     count++;
                  }
               }
            }
         }

         nelem.value = nrows - count;
      }

      return false;
   },

   liveGrid: function( key, id, imgs, pageSz, toggle ) {
      if (key && id && imgs) {
         var elem = $( key + id + 'Disp' );

         if (elem) {
            var img = imgs.split( '~' );

            if (toggle && elem.style.display != 'none') {
               elem.style.display = 'none';
               elem = $( key + id + 'Img' );

               if (elem) elem.src = img[0];

               this.gridKey  = null;
               this.gridId   = null;
               this.gridObj = null;
               this.pageSz   = 10;
            }
            else {
               if (this.gridKey && this.gridId) {
                  var keyid = this.gridKey + this.gridId;
                  var prev  = $( keyid + 'Disp' );

                  if (prev) prev.style.display = 'none';

                  prev = $( keyid + 'Img' );

                  if (prev) prev.src = img[0];

                  this.gridKey  = null;
                  this.gridId   = null;
                  this.gridObj = null;
                  this.pageSz   = 10;
               }

               elem.style.display = '';
               elem = $( key + id + 'Img' );

               if (elem) elem.src = img[1];

               this.gridKey = key;
               this.gridId  = id;
               this.pageSz  = (pageSz ? pageSz : 10);
               new Ajax( this.url + key +  '_grid_table',
                  { method    : 'get',
                    data      : 'content-type=text/xml&id='
                                + id + '&val=' + pageSz,
                    onComplete: this.createGrid.bind( this ) } ).request();
            }
         }
      }
   },

   updateHeader: function( offset ) {
      var id, sortInfo, text, urlkey, metaData = this.gridObj.metaData;

      id    = this.gridKey + this.gridId + '_header';
      text  = 'Listing ' + (offset + 1) + ' - ';
      text += (offset + metaData.getPageSize());
      text += ' of ' + metaData.getTotalRows();
      $( id ).setHTML( text );

      if (this.gridObj.sortCol) {
         sortInfo  = '&data_grid_sort_col=' + this.gridObj.sortCol;
         sortInfo += '&data_grid_sort_dir=' + this.gridObj.sortDir;
      }
      else sortInfo = '';

      urlkey = this.url + this.gridKey + '_gridPage';
      text   = urlkey + '?data_grid_index=' + offset + sortInfo;
      $( id ).href = text;
   }
});

TableUtils.implement( new Options );

/* Script: Tips.js
      Tooltips, BubbleTips, whatever they are, they will appear on mouseover

   License:
      MIT-style license.

   Credits:
      The idea behind Tips.js is based on Bubble Tooltips
      (<http://web-graphics.com/mtarchive/001717.php>) by Alessandro
      Fulcitiniti <http://web-graphics.com>
   Class: Tips
      Display a tip on any element with a title and/or href.

   Note:
      Tips requires an XHTML doctype.

   Arguments:
      elements - collection of elements to apply the tooltips to on mouseover.
      options - an object. See options Below.

   Options:
      maxTitleChars - the maximum number of characters to display in the
                      title of the tip. defaults to 30.
      showDelay - the delay the onShow method is called. (defaults to 100 ms)
      hideDelay - the delay the onHide method is called. (defaults to 100 ms)
      className - the prefix for your tooltip classNames. defaults to 'tool'.
         the whole tooltip will have as classname: tool-tip
         the title will have as classname: tool-title
         the text will have as classname: tool-text
      offsets - the distance of your tooltip from the mouse. an Object
                with x/y properties.
      fixed - if set to true, the toolTip will not follow the mouse.

   Events:
      onShow - optionally you can alter the default onShow behaviour with
               this option (like displaying a fade in effect);
      onHide - optionally you can alter the default onHide behaviour with
               this option (like displaying a fade out effect);

   Example:
      (start code)
      <img src="/images/i.png" title="The body of the tooltip is stored
                                      in the title" class="toolTipImg"/>
      <script>
         var myTips = new Tips($$('.toolTipImg'), {
            maxTitleChars: 50 //I like my captions a little long
         });
      </script>
      (end)

   Note:
      The title of the element will always be used as the tooltip
      body. If you put ~ in your title, the text before the ~ will become
      the tooltip title.
*/

var Tips = new Class({
   options: {
      className: 'tool',
      fixed    : false,
      hellip   : '\u2026',
      hideDelay: 100,
      maxTitleChars: 40,
      offsets  : { 'x': 20, 'y': 20 },
      onHide   : function( tip ) { tip.setStyle( 'visibility', 'hidden'  ) },
      onShow   : function( tip ) { tip.setStyle( 'visibility', 'visible' ) },
      separator: '~',
      showDelay: 100,
      spacer   : '\u00a0\u00a0\u00a0',
      timeout  : 30000
   },

   initialize: function( elements, options ) {
      var cell, row, table;

      this.setOptions( options );
      this.toolTip = new Element( 'div', {
         'class' : this.options.className + '-tip',
         'styles': { 'position'  : 'absolute',
                     'top'       : '0',
                     'left'      : '0',
                     'visibility': 'hidden' } } ).inject( document.body );
      table = new Element( 'table',
         { 'cellpadding': '0', 'cellspacing': '0' } ).inject( this.toolTip );
      row   = new Element( 'tr' ).inject( table );
      this.titleCell = new Element( 'td',
         { 'class': this.options.className + '-tip-topLeft'} ).inject( row );
      this.title = new Element( 'span' ).inject( this.titleCell );

      cell  = new Element( 'td',
         { 'class': this.options.className + '-tip-topRight'} ).inject( row );
      new Element( 'span' ).appendText( this.options.spacer ).inject( cell );

      row   = new Element( 'tr' ).inject( table );
      this.textCell  = new Element( 'td', { 'class': this.options.className
                                   + '-tip-bottomLeft'} ).inject( row );
      this.text = new Element( 'span' ).inject( this.textCell );

      cell  = new Element( 'td', { 'class': this.options.className
                                   + '-tip-bottomRight' } ).inject( row );
      new Element( 'span' ).appendText( this.options.spacer ).inject( cell );

      $$( elements ).each( this.build, this );

      if (this.options.initialize) this.options.initialize.call( this );
   },

   build: function( el ) {
      if (el.$tmp.myTitle || el.$tmp.myText) return;

      el.$tmp.myTitle = (el.href && el.getTag() == 'a')
                      ? el.href.replace( 'http://', '' )
                      : (el.rel || false);

      if (el.title){
         var dual = el.title.split( this.options.separator );

         if (dual.length > 1){
            el.$tmp.myTitle = dual[ 0 ].trim();
            el.$tmp.myText  = dual[ 1 ].trim();
         }
         else {
            if (!el.$tmp.myTitle) el.$tmp.myTitle = this.options.hellip;

            el.$tmp.myText = el.title;
         }

         el.removeAttribute( 'title' );
      }
      else { el.$tmp.myText = false }

      if (el.$tmp.myTitle && el.$tmp.myTitle.length >
          this.options.maxTitleChars) {
         el.$tmp.myTitle
            = el.$tmp.myTitle.substr( 0, this.options.maxTitleChars - 1 )
            + this.options.hellip;
      }

      el.addEvent( 'mouseenter', function( event ) {
         this.start( el );

         if (!this.options.fixed) this.locate( event );
         else this.position( el );
      }.bind( this ) );

      if (!this.options.fixed)
         el.addEvent( 'mousemove', this.locate.bindWithEvent( this ) );

      el.addEvent( 'mouseleave', this.end.bind( this ) );
      el.addEvent( 'trash', this.hide.bind( this ) );
   },

   end: function( event ) {
      $clear( this.timer );
      this.timer = this.hide.delay( this.options.hideDelay, this );
   },

   hide: function() {
      this.fireEvent( 'onHide', [ this.toolTip ] );
   },

   locate: function( event ) {
      var win = { 'x': window.getWidth(), 'y': window.getHeight() };
      var scroll
         = { 'x': window.getScrollLeft(), 'y': window.getScrollTop() };
      var tip
         = { 'x': this.toolTip.offsetWidth, 'y': this.toolTip.offsetHeight };
      var prop = { 'x': 'left', 'y': 'top' };

      for (var z in prop) {
         var pos = event.page[z] + this.options.offsets[z];
         if ((pos + tip[z] - scroll[z]) > win[z])
            pos = event.page[z] - this.options.offsets[z] - tip[z];
         this.toolTip.setStyle( prop[z], pos );
      };
   },

   position: function( element ) {
      var pos = element.getPosition();
      this.toolTip.setStyles({
         'left': pos.x + this.options.offsets.x,
         'top': pos.y + this.options.offsets.y
      });
   },

   show: function() {
      if ( this.options.timeout )
         this.timer = this.hide.delay( this.options.timeout, this );
      this.fireEvent( 'onShow', [ this.toolTip ] );
   },

   start: function(el) {
      var len, width, w = 100;

      if (el.$tmp.myText) {
         width = window.getWidth();
         len   = el.$tmp.myTitle.length > el.$tmp.myText.length
               ? el.$tmp.myTitle.length : el.$tmp.myText.length;
         w     = 10 * len;

         if (w < 100)       w = 100;
         if (w > width / 4) w = width / 4;
      }

      this.titleCell.setStyle( 'width', parseInt( w ) + 'px' );

      if ($defined( this.title.lastChild ))
         this.title.removeChild( this.title.lastChild );

      this.title.appendText( el.$tmp.myTitle || this.options.spacer );
      this.textCell.setStyle( 'width', parseInt( w ) + 'px' );

      if ($defined( this.text.lastChild ))
         this.text.removeChild( this.text.lastChild );

      this.text.appendText( el.$tmp.myText || this.options.spacer );
      $clear( this.timer );
      this.timer = this.show.delay( this.options.showDelay, this );
   }
});

Tips.implement( new Events, new Options );

var WindowUtils = new Class({
   initialize: function( options ) {
      if (options.prefix) this.cname = options.prefix + '_session';
      else this.cname = 'session';

      this.copts = { path: options.path || '/', domain: options.domain || '' };
   },

   openWindow: function( href, key, prefs ) {
      window.open( href, key, prefs );
      return;
   },

   placeOnTop: function() {
      if (self != top) {
         if (document.images) top.location.replace( window.location.href );
         else top.location.href = window.location.href;
      }
   },

   wayOut: function( href ) {
      Cookie.remove( this.cname, this.copts );

      if (document.images) top.location.replace( href );
      else top.location.href = href;
   }
});
