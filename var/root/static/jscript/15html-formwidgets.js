/* @(#)$Id: 15html-formwidgets.js 1278 2012-03-11 23:23:04Z pjf $
 * Portions of this code are taken from MooTools 1.3 which is:
 * Copyright (c) 2006-2010 [Valerio Proietti](http://mad4milk.net/). */

Options.implement( {
   build: function() {
      var selector = this.options.selector;

      if (selector) $$( selector ).each( function( el ) {
         if (! this.collection.contains( el )) {
            this.collection.include( el ); this.attach( el );
         }
      }, this );
   },

   setBuildOptions: function( options ) {
      options         = options || {};
      this.collection = [];
      this.callbacks  = {};
      this.debug      = false;
      this.log        = function() {};

      [ 'callbacks', 'debug', 'log' ].each( function( attr ) {
         if (options[ attr ] != undefined) {
            this[ attr ] = options[ attr ]; delete options[ attr ];
         }
      }.bind( this ) );

      this.setOptions( options );

      if (this.callbacks.collect) this.callbacks.collect( this );

      return this;
   },

   setConfigOptions: function( el ) {
      var opt = this.options, cfg = opt.config[ el.id || 'none' ] || {};

      for (var key in cfg) { opt[ key ] = cfg[ key ] }
   }
} );

String.implement( {
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
} );

var AutoSize = new Class( {
   Implements: [ Events, Options ],

   options           : {
      container_class: 'expanding_area',
      preformat_class: 'expanding_spacer',
      selector       : '.autosize' // element class to search for
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var opt  = this.options;
      var div  = new Element( 'div', { 'class': opt.container_class } );
      var pre  = new Element( 'pre', { 'class': opt.preformat_class } );
      var span = new Element( 'span' );

      div.inject( el, 'before' ); pre.inject( div ); div.grab( el );

      span.inject( pre ); new Element( 'br' ).inject( pre );

      el.addEvent( 'keyup', function() { span.set( 'text', el.value ) } );

      span.set( 'text', el.value );
   }
} );

var Calendars = new Class( {
   Implements: [ Options ],

   options: { config: {}, selector: '.calendars' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var button, cfg, opt = this.options, submit = this.callbacks.submit;

      if (! (cfg = opt.config[ el.id ])) return;

      if (submit && (button = $( el.id + '_clear' )))
         button.addEvent( 'click', function( ev ) {
            new Event( ev ).stop(); submit.clearField( el.id ) } );

      Calendar.setup( Object.append( cfg, {
         inputField: el.id, button: el.id + '_trigger' } ) );
   }
} );

var CheckboxReplace = new Class( {
   Implements: [ Options ],

   options               : {
      checkboxSelector   : 'input[type=checkbox]',
      radiobuttonSelector: 'input[type=radio]',
      suffix             : '_replacement'
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   build: function() {
      var opt = this.options;

      [ opt.checkboxSelector, opt.radiobuttonSelector ]
         .each( function( selector ) {
            if (selector) $$( selector ).each( function( el ) {
               this.collection.include( el ); this.attach( el );
            }, this );
         }, this );
   },

   attach: function( el ) {
      var handler, replacement = this.getReplacement( el );

      if (! (handler = replacement.retrieve( 'click' )))
         replacement.store( 'click', handler = this.toggle.bind( this, el ) );

      replacement.addEvent( 'click', handler );
   },

   getReplacement: function( el ) {
      var new_id = el.name
                 + (el.type == 'checkbox' ? '' : el.value)
                 + this.options.suffix;

      var replacement; if (replacement = $( new_id )) return replacement;

      el.setStyles( { position: 'absolute', left: '-9999px' } );

      return new Element( 'span', {
         'class': 'checkbox' + (el.checked ? ' checked' : ''),
         id     : new_id,
         name   : el.name
      } ).inject( el, 'after' );
   },

   toggle: function( el ) {
      if (el.getProperty( 'disabled' )) return;

      var replacement = this.getReplacement( el );

      replacement.toggleClass( 'checked' );

      if (replacement.hasClass( 'checked' )) {
         el.setProperty( 'checked', 'checked' );

         if (el.type == 'radio') {
            this.collection.each( function( box ) {
               replacement = this.getReplacement( box );

               if (box != el && box.name == el.name
                   && replacement.hasClass( 'checked' )) {
                  replacement.removeClass ( 'checked' );
                  box.removeProperty( 'checked' );
               }
            }.bind( this ) );
         }
      }
      else el.removeProperty( 'checked' );
   }
} );

/* Originally created by: Adam Wulf adam.wulf@gmail.com Version 1.4.0
 * http://welcome.totheinter.net/columnizer-jquery-plugin/ */

var Columnizer = new Class( {
   Implements: [ Events, Options ],

   options         : {
      accuracy     : false,
      // true to build columns once regardless of window resize
      // false to rebuild when content box changes bounds
      buildOnce    : false,
      // Percentage left + right padding in CSS for column class
      columnPadding: 1.5,
      // optional # of columns instead of width
      columns      : false,
      // this function is called after content is columnized
      // should columns float left or right
      float        : 'left',
      height       : false,
      // re-columnizing when images reload might make things
      // run slow. so flip this to true if it's causing delays
      ignoreImageLoading: true,
      // ensure the last column is never the tallest column
      lastNeverTallest  : false,
      // an object with options if the text should overflow
      // it's container if it can't fit within a specified height
      lineHeight   : 18,
      maxLoops     : 3,
      overflow     : false,
      // if the content should be columnized into a
      // container node other than it's own node
      target       : false,
      // default width of columnx
      width        : 400
   },

   initialize: function( el, options ) {
      el = $( el );

      if (options.columns && typeOf( options.columns ) != 'number')
         options.columns = null;

      this.setOptions( options ); var opt = this.options;
      // this is where we'll put the real content
      this.cache = new Element( 'div' );
      this.node  = $( opt.target || el );

      if (! this.node.data) this.node.data = {
          lastWidth: 0, size: this.node.getSize() };

      this.cache.adopt( this.node.getChildren().clone() );

      // images loading after dom load can screw up the column heights,
      // so recolumnize after images load
      if (! opt.ignoreImageLoading && ! opt.target) {
         if (! this.node.data.imageLoaded) {
            this.node.data.imageLoaded = true;

            var images = el.getElements( 'img' );

            if (images.length > 0) {
               // only bother if there are actually images...
               var func = function( obj, el, images ) {
                  return function() {
                     if (! this.node.data.firstImageLoaded) {
                        this.node.data.firstImageLoaded = true;
                        new Columnizer( el, this.options ); // Recurse
                        images.removeEvent( 'abort', func );
                        images.removeEvent( 'load',  func );
                     }
                  }.bind( obj );
               }(this, el, images);

               images.addEvents( { abort: func, load: func } );
               return;
            }
         }
      }

      this.build();

      if (! opt.buildOnce)
         window.addEvent( 'resize', function() { this.build() }.bind( this ) );
   },

   build: function() {
      var opt        = this.options;
      var data       = this.node.data;
      var num_cols   = opt.columns ? opt.columns
                                   : Math.round( data.size.x / opt.width );
      var padding    = opt.columnPadding;
      var width      = (100 - (2 * padding * num_cols)) / num_cols;

      if (data.columnizing || data.lastWidth == width) return;

      data.columnizing = true; data.lastWidth = width;

      if (num_cols <= 1) return this.singleColumnize();

      var style      = { float  : opt.float,
                         padding: '0px ' + padding + '%',
                         width  : Math.floor( width ) + '%' };

      this.node.setStyles( style );
      this.cache.getChildren().each( function( el ) {
         this.node.grab( el.clone() ) }.bind( this ) );

      var tgt_height = Math.floor( this.node.getHeight() / num_cols );

      this.node.removeProperty( 'style' );

      var horizontal = false, max_loops = opt.maxLoops;

      if (opt.overflow) {
         max_loops = 1; tgt_height = opt.overflow.height;
      }
      else if (opt.height && opt.width) {
         max_loops = 1; tgt_height = opt.height; horizontal = true;
      }

      this.state = [ 0, max_loops, tgt_height ];

      while (this.state[ 0 ] < this.state[ 1 ]) {
         var destroyable
              = this._buildDestroyable( style, num_cols, horizontal );

         this._buildColumns( destroyable, num_cols, horizontal );

         this.state[ 0 ]++;
      }

      data.columnizing = false;

      if (opt.overflow) opt.overflow.fireEvent( 'complete' );

      this.fireEvent( 'complete' );
   },

   _buildColumns: function( destroyable, num_cols, horizontal ) {
      var columns = this.node.getChildren(), opt = this.options;

      if (opt.overflow && ! horizontal) {
         var overflow = $( opt.overflow.id );
         var kids     = destroyable.getChildren();

         overflow.empty().adopt( kids.clone() );
      }
      else if (! horizontal) {
         // the last column in the series
         var col = columns.getLast();

         while (destroyable.childNodes.length ) {
            col.appendChild( destroyable.childNodes[ 0 ] );
         }

         this._buildNewState( columns, num_cols );
      }
      else {
         // it's scrolling horizontally, fix width/classes of the columns
         columns.each( function( col, i ) {
            col.width( this.options.width + 'px' );

            if (i == 0) {
               col.addClass( 'first' );
            }
            else if (i == this.node.childNodes.length - 1) {
               col.addClass( 'last' );
            }
            else {
               col.removeClass( 'first' ); col.removeClass( 'last' );
            }
         }.bind( this ) );

         this.node.width( (columns.length * opt.width) + 'px' );
      }
   },

   _buildDestroyable: function( style, num_cols, horizontal ) {
      var destroyable = this.cache.clone(), opt = this.options;

      this.node.empty(); destroyable.setOpacity( 0 ); // Hide

      // create the columns
      for (var i = 0; i < num_cols; i++) {
         var className = (i == 0) ? 'column first' : 'column';
         var className = (i == num_cols - 1)
                       ? (className + ' last') : className;
         var el = new Element( 'div', { class: className, styles: style } );

         el.inject( this.node, 'inside' );
      }

      // fill all but the last column (unless overflowing)
      var i = 0;

      while (i < num_cols - (opt.overflow ? 0 : 1)
             || horizontal && destroyable.childNodes.length) {
         if (this.node.childNodes.length <= i) {
            // we ran out of columns, make another
            var el = new Element( 'div', { class: className, styles: style } );

            el.inject( this.node, 'inside' );
         }

         var col = $( this.node.childNodes[ i ] );

         this.columnize( col, destroyable, col, this.state[ 2 ] );

         // make sure that the last item in the column isn't a 'dontend'
         if (destroyable.firstChild
             && ! $( destroyable.firstChild ).hasClass( 'dontend' ))
            this.split( col, destroyable, col, this.state[ 2 ] );

         while (this._checkDontEndColumn( col.lastChild )) {
            var para = $( col.lastChild );

            para.dispose(); para.inject( destroyable, 'top' );
         }

         i++;
      }

      return destroyable;
   },

   _buildNewState: function( columns, num_cols ) {
      var opt       = this.options;
      var lastIsMax = false;
      var max       = 0;
      var min       = 10000000;
      var totalH    = 0;

      columns.each( function( col ) {
         var h = col.getHeight(); lastIsMax = false; totalH += h;

         if (h > max) { max = h; lastIsMax = true; }
         if (h < min) { min = h; }
      } );

      var avgH = Math.floor( totalH / num_cols );

      if (opt.lastNeverTallest && lastIsMax) {
         // the last column is the tallest so allow columns
         // to be taller and retry
         this.state[ 2 ] += opt.lineHeight;

         if (this.state[ 0 ] == this.state[ 1 ] - 1) this.state[ 1 ]++;
      }
      else if (max - min > 2 * opt.lineHeight) {
         // too much variation, try again
          this.state[ 2 ] = avgH + opt.lineHeight;
      }
      else if (Math.abs( avgH - this.state[ 2 ] ) > opt.lineHeight) {
         this.state[ 2 ] = avgH; // too much variation, try again
      }
      else {
         this.state[ 0 ] = this.state[ 1 ]; // solid, we're done
      }
   },

   _checkDontEndColumn: function( el ) {
      el = $( el );

      if (el == undefined)           return false;
      if (typeOf( el ) != 'element') return false;
      if (el.hasClass( 'dontend' ))  return true;
      if (el.childNodes.length == 0) return false;

      return this._checkDontEndColumn( el.lastChild );
   },

   columnize: function( putInHere, pullOutHere, parentColumn, height ) {
      while (parentColumn.getHeight() < height
             && pullOutHere.childNodes.length ) {
         putInHere.appendChild( pullOutHere.childNodes[ 0 ] );
      }

      if (putInHere.childNodes.length == 0) return;

      // now we're too tall, undo the last one
      var kids = putInHere.childNodes, kid = kids[ kids.length - 1 ];

      putInHere.removeChild( kid );

      var is_textnode = typeOf( kid ) == 'textnode'
                     || typeOf( kid ) == 'whitespace';

      if (is_textnode) {
         // it's a text node, split it up
         var oText    = kid.nodeValue;
         var counter2 = this.options.accuracy
                      ? this.options.accuracy : this.options.width / 18;
         var columnText, latestTextNode = null;

         while (parentColumn.getHeight() < height && oText.length) {
            if (oText.indexOf( ' ', counter2 ) != '-1')
               columnText = oText.substring( 0, oText.indexOf( ' ', counter2));
            else columnText = oText;

            latestTextNode = document.createTextNode( columnText );
            putInHere.appendChild( latestTextNode );

            if (oText.length > counter2)
               oText = oText.substring( oText.indexOf( ' ', counter2 ) );
            else oText = '';
         }

         if (parentColumn.getHeight() >= height
             && latestTextNode != null) {
            // too tall :(
            putInHere.removeChild( latestTextNode );
            oText = latestTextNode.nodeValue + oText;
         }

         if (oText.length) kid.nodeValue = oText;
         else return false; // we ate the whole text node, move on
      }


      if (pullOutHere.childNodes.length)
         pullOutHere.insertBefore( kid, pullOutHere.firstChild );
      else pullOutHere.appendChild( kid );

      return is_textnode;
   },

   singleColumnize: function() {
      var options = this.options;
      var style   = { float: options.float, padding: '0px 1.5%', width: '97%' };
      var col     = new Element( 'div', { class : 'column first last',
                                          styles: style } );

      this.node.empty(); col.inject( this.node, 'inside' );

      if (options.overflow) {
         var destroyable  = this.cache.clone();
         var tgt_height = options.overflow.height;

         this.columnize( col, destroyable, col, tgt_height );

         // make sure that the last item in the column isn't a 'dontend'
         if (! $( destroyable.firstChild ).hasClass( 'dontend' ))
            this.split( col, destroyable, col, tgt_height );

         while (this._checkDontEndColumn( col.lastChild )) {
            var para = $( col.lastChild );

            para.dispose(); para.inject( destroyable, 'top' );
         }

         var overflow = $( options.overflow.id ).empty();

         while (destroyable.firstChild != undefined) {
            var para = $( destroyable.firstChild );

            para.dispose(); para.inject( overflow, 'inside' );
         }
      }
      else this.cache.inject( col, 'inside' );

      this.node.data.columnizing = false;

      if (options.overflow) options.overflow.fireEvent( 'complete' );

      this.fireEvent( 'complete' );
   },

   split: function( putInHere, pullOutHere, parentColumn, height ) {
      if (! pullOutHere.childNodes.length) return;

      var opt     = this.options;
      var cloneMe = pullOutHere.firstChild, clone = cloneMe.clone();

      if (! typeOf( clone ) == 'element' || clone.hasClass( 'dontend' )) return;

      clone.inject( putInHere, 'inside' );

      if (clone.tag == 'img'
          && parentColumn.getHeight() < height + opt.lineHeight) {
         cloneMe.dispose();
      }
      else if (! cloneMe.hasClass( 'dontsplit' )
               && parentColumn.getHeight() < height + opt.lineHeight) {
         cloneMe.dispose();
      }
      else if (clone.tag == 'img' || cloneMe.hasClass( 'dontsplit' )) {
         clone.dispose();
      }
      else {
         clone.empty();

         if (! this.columnize( clone,  cloneMe,  parentColumn, height )
             && cloneMe.childNodes.length) {
            this.split( clone, cloneMe, parentColumn, height ); // Recurse
         }

         if (clone.childNodes.length == 0) {
            // it was split, but nothing is in it :(
            clone.dispose();
         }
      }
   }
} );

var Columnizers = new Class( {
   Implements   : [ Options ],

   options      : {
      classNames: [ 'zero', 'one', 'two', 'three', 'four', 'five', 'six',
                    'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve',
                    'thirteen', 'fourteen', 'fifteen' ],
      config    : {},
      selector  : '.multiColumn'
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var opt   = this.options,
          klass = el.getProperty( 'class' ).split( ' ' )[ 0 ],
          cols  = opt.classNames.indexOf( klass ),
          cfg   = Object.merge( opt.config, { columns: cols } );

      el.columnizer = new Columnizer( el, cfg );
   }
} );

var Cookies = new Class( {
   Implements: [ Options ],

   options  : {
      domain: '',
      expire: 90,
      name  : 'state',
      path  : '/',
      prefix: '',
      secure: false
   },

   initialize: function( options ) {
      this.setOptions( options ); var opt = this.options;

      var cName = (opt.prefix ? opt.prefix + '_' : '') + opt.name;
      var cOpts = { domain: opt.domain, duration: opt.expire,
                    path  : opt.path,   secure  : opt.secure };

      this.cookie = new Cookie( cName, cOpts );
   },

   get: function( name ) {
      var val = this.cookie.read();

      if (name && val) {
         var cookies = val.split( '+' );

         for (var i = 0, cl = cookies.length; i < cl; i++) {
            var pair = cookies[ i ].split( '~' );

            if (unescape( pair[ 0 ] ) == name)
               return pair[ 1 ] != 'null' ? unescape( pair[ 1 ] ) : null;
         }

         return '';
      }

      return val;
   },

   remove: function( name ) {
      var i, val = this.cookie.read();

      if (val && name) name = escape( name );
      else return false;

      if ((i = val.indexOf( name + '~' )) < 0) return false;

      var j = val.substring( i ).indexOf( '+' );

      if (i == 0) val = (j < 0) ? '' : val.substring( j + 1 );

      if (i > 0) {
         val = (j < 0) ? val.substring( 0, i - 1 )
                       : val.substring( 0, i - 1 ) + val.substring( i + j );
      }

      return this.cookie.write( val );
   },

   set: function( name, cookie ) {
      var i, val = this.cookie.read();

      if (name) name = escape( name );
      else return;

      if (cookie) cookie = escape( cookie );

      if (val) {
         if ((i = val.indexOf( name + '~' )) >= 0) {
            var j = val.substring( i ).indexOf( '+' );

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

      return this.cookie.write( val );
   }
} );

var FreeList = new Class( {
   Implements: [ Options ],

   options: { selector: 'input.freelist' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      $( el.id + '_add' ).addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); this.addItem( el.id );
      }.bind( this ) );

      $( el.id + '_remove' ).addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); this.removeItem( el.id );
      }.bind( this ) );
   },

   addItem: function( id ) {
      var el = $( id ), list = $( id + '_list' ), options = list.options;

      new Element( 'input', {
         name: id, type: 'hidden', value: el.value
      } ).inject( list, 'after' );

      options[ options.length ] = new Option( el.value );
      el.value = null;
      el.focus();
   },

   removeItem: function( id ) {
      var el = $( id ), list = $( id + '_list' ), options = list.options;

      for (var i = options.length - 1; i >= 0; i--) {
         if (options[ i ].selected != true) continue;

         var value = options[ i ].value;

         $$( 'input[name=' + id + ']' ).some( function( el ) {
            if (el.type == 'hidden' && el.value == value) {
               el.destroy(); return true;
            }

            return false;
         } );

         options[ i ].destroy();
      }

      el.focus();
   }
} );

/* Description: An Fx.Elements extension which allows you to easily
 *              create accordion type controls.
 * License: MIT-style license
 * Authors: Valerio Proietti, Peter Flanigan */

Fx.Accordion = new Class( {
   Extends: Fx.Elements,

   options               : {
      alwaysHide        : false,
      display           : 0,
      fixedHeight       : false,
      fixedWidth        : false,
      height            : true,
      initialDisplayFx  : true,
/*    onActive          : function( togglers, index, section ) {}, */
/*    onBackground      : function( togglers, index, section ) {}, */
      opacity           : true,
      returnHeightToAuto: true,
      show              : false,
      trigger           : 'click',
      wait              : false,
      width             : false
   },

   initialize: function() {
      var defined = function( obj ) { return obj != null };
      var params  = Array.link( arguments, {
         'options'  : Type.isObject,
         'togglers' : defined,
         'elements' : defined
      } );

      this.parent( params.elements, params.options );
      this.togglers      = $$( params.togglers );
      this.internalChain = new Chain();
      this.previous      = -1;
      this.effects       = {};

      var opt = this.options;

      if (opt.alwaysHide) opt.wait = true;

      if (opt.show || opt.show === 0) {
         opt.display = false; this.previous = opt.show;
      }

      if (opt.opacity) this.effects.opacity = 'fullOpacity';

      if (opt.width) this.effects.width = opt.fixedWidth ? 'fullWidth'
                                                         : 'offsetWidth';

      if (opt.height) this.effects.height = opt.fixedHeight ? 'fullHeight'
                                                            : 'scrollHeight';

      for (var i = 0, l = this.togglers.length; i < l; i++) {
         var toggler = this.togglers[ i ];

         if (i == 0) toggler.addClass( 'accordion_header_first' );

         this.addSection( toggler, this.elements[ i ] );
      }

      this.elements.each( function( el, i ) {
         if (opt.show === i) {
            this.fireEvent( 'active', [ this.togglers, i, el ] );
         }
         else {
            for (var fx in this.effects) el.setStyle( fx, 0 );
         }
      }, this );

      if (opt.display || opt.display === 0)
         this.display( opt.display, opt.initialDisplayFx );

      this.addEvent( 'complete',
                     this.internalChain.callChain.bind( this.internalChain ) );
   },

   addSection: function( toggler, el ) {
      toggler = document.id( toggler ); el = document.id( el );

      var test = this.togglers.contains( toggler );

      this.togglers.include( toggler ); this.elements.include( el );

      var opt       = this.options;
      var index     = this.togglers.indexOf( toggler );
      var displayer = this.display.pass( [ index, true ], this );

      toggler.addEvent( opt.trigger, displayer );
      toggler.store( 'accordion:display', displayer );
      el.setStyle( 'overflow-y', opt.fixedHeight ? 'auto' : 'hidden' );
      el.setStyle( 'overflow-x', opt.fixedWidth  ? 'auto' : 'hidden' );
      el.fullOpacity = 1;

      if (! test) { for (var fx in this.effects) el.setStyle( fx, 0 ); }

      this.internalChain.chain( function() {
         if (! opt.fixedHeight && opt.returnHeightToAuto
             && ! this.selfHidden) {
            if (this.now == index) el.setStyle( 'height', 'auto' );
         };
      }.bind( this ) );

      return this;
   },

   detach: function( toggler ) {
      var remove = function( toggler ) {
         toggler.removeEvent( this.options.trigger,
                              toggler.retrieve( 'accordion:display' ) );
      }.bind( this );

      if (! toggler) this.togglers.each( remove );
      else remove( toggler );

      return this;
   },

   display: function( index, useFx ) {
      if (! this.check( index, useFx )) return this;

      var els = this.elements, opt = this.options;

      index = (typeOf( index ) == 'element') ? els.indexOf( index )
                                             : index;
      index = index >= els.length ? els.length - 1 : index;
      useFx = useFx != null ? useFx : true;

      if (! opt.fixedHeight && opt.returnHeightToAuto) {
         var prev = this.previous > -1 ? els[ this.previous ] : false;

         if (prev && ! this.selfHidden) {
            for (var fx in this.effects) {
               prev.setStyle( fx, prev[ this.effects[ fx ] ] );
            }
         }
      }

      if (this.timer && opt.wait) return this;

      this.previous = this.now != undefined ? this.now : -1;
      this.now      = index;

      var obj = this._element_iterator( function( el, i, hide ) {
         this.fireEvent( hide ? 'background' : 'active',
                         [ this.togglers, i, el ] );
      }.bind( this ) );

      return useFx ? this.start( obj ) : this.set( obj );
   },

   _element_iterator: function( f ) {
      var obj = {}, opt = this.options;

      this.elements.each( function( el, i ) {
         var hide = false; obj[ i ] = {};

         if (i != this.now) { hide = true }
         else if (opt.alwaysHide && ((el.offsetHeight > 0 && opt.height)
                                     || el.offsetWidth  > 0 && opt.width)) {
            hide = this.selfHidden = true;
         }

         f( el, i, hide );

         for (var fx in this.effects)
            obj[ i ][ fx ] = hide ? 0 : el[ this.effects[ fx ] ];
      }, this );

      return obj;
   },

   removeSection: function( toggler, displayIndex ) {
      var index   = this.togglers.indexOf( toggler );
      var el      = this.elements[ index ];
      var remover = function() {
         this.togglers.erase( toggler );
         this.elements.erase( el );
         this.detach( toggler );
      }.bind( this );

      if (this.now == index || displayIndex != null){
         this.display( displayIndex != null ? displayIndex
                       : (index - 1 >= 0 ? index - 1 : 0) ).chain( remover );
      }
      else { remover() }

      return this;
   },

   resize: function() {
      var opt    = this.options;
      var height = typeOf( opt.fixedHeight ) == 'function'
                 ? opt.fixedHeight.call() : opt.fixedHeight;
      var width  = typeOf( opt.fixedWidth  ) == 'function'
                 ? opt.fixedWidth.call()  : opt.fixedWidth;
      var obj    = this._element_iterator( function( el, i, hide ) {
         if (height) el.fullHeight = height;
         if (width)  el.fullWidth  = width;
      }.bind( this ) );

      this.set( obj );
   }
} );

var GroupMember = new Class( {
   Implements: [ Options ],

   options: { selector: 'select.groupmembers' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      $( el.id + '_add' ).addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); this.addItem( el.id );
      }.bind( this ) );

      $( el.id + '_remove' ).addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); this.removeItem( el.id );
      }.bind( this ) );
   },

   addItem: function( id ) {
      var all = $( id ), members = $( id + '_current' );

      for (var i = all.length - 1; i >= 0; i--) {
         if (all.options[ i ].selected != true) continue;

         var value = all.options[ i ].value;

         if (! this.deleteHidden( id + '_deleted', value )) {
            var name = all.name.replace( /^_/g, '' ) + '_added';

            new Element( 'input', {
               name: name, type: 'hidden', value: value
            } ).inject( members, 'after' );
         }

         members.options[ members.length ] = all.options[ i ];
         // This suddenly started happening, weird but works after v0.1.657
         // all.options[ i ] = null;
      }
   },

   deleteHidden: function( id, value ) {
      return $$( 'input[name=' + id + ']' ).some( function( el ) {
         if (el.type == 'hidden' && el.value == value) {
            el.destroy(); return true;
         }

         return false;
      } );
   },

   removeItem: function( id ) {
      var all = $( id ), members = $( id + '_current' );

      for (var i = members.length - 1; i >= 0; i--) {
         if (members.options[ i ].selected != true) continue;

         var value = members.options[ i ].value;

         if (! this.deleteHidden( id + '_added', value )) {
            var name = all.name.replace( /^_/g, '' )+ '_deleted' ;

            new Element( 'input', {
               name: name, type: 'hidden', value: value
            } ).inject( members, 'after' );
         }

         all.options[ all.length ] = members.options[ i ];
         // This suddenly started happening, weird but works after v0.1.657
         // members.options[ i ] = null;
      }
   }
} );

var LinkFader = new Class( {
   Implements: [ Options ],

   options    : {
      fc      : 'ff0000', // Fade to colour
      inBy    : 6,        // Fade in colour inc/dec by
      outBy   : 6,        // Fade out colour inc/dec by
      selector: '.fade',  // Class name matching links to fade
      speed   : 20        // Millisecs between colour changes
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      el.addEvent( 'mouseover', this.startFade.bind( this, el ) );
      el.addEvent( 'mouseout',  this.clearFade.bind( this, el ) );
   },

   clearFade: function( el ) {
      if (el.timer) clearInterval( el.timer );

      el.timer = this.fade.periodical( this.options.speed, this, [ el, 0 ] );
   },

   currentColour: function( el ) {
      var cc = el.getStyle( 'color' ), temp = '';

      if (cc.length == 4 && cc.substring( 0, 1 ) == '#') {
         for (var i = 0; i < 3; i++) {
            temp += cc.substring( i + 1, i + 2 ) + cc.substring( i + 1, i + 2);
         }

         cc = temp;
      }
      else if (cc.indexOf('rgb') != -1) { cc = cc.rgbToHex().substring(1, 7) }
      else if (cc.length == 7)          { cc = cc.substring( 1, 7 ) }
      else                              { cc = this.options.fc }

      return cc;
   },

   fade: function( el, d ) {
      var cc = this.currentColour( el ).hexToRgb( true );
      var tc = (d == 1)  ? this.options.fc.hexToRgb( true )
             : el.colour ? el.colour.hexToRgb( true )
                         : [ 0, 0, 0 ];

      if (tc[ 0 ] == cc[ 0 ] && tc[ 1 ] == cc[ 1 ] && tc[ 2 ] == cc[ 2 ]) {
         clearInterval( el.timer ); return el.timer = null;
      }

      el.setStyle( 'color', this.nextColour( tc, cc, d ) );
   },

   nextColour: function( tc, cc, d ) {
      var change = (d == 1) ? this.options.inBy : this.options.outBy;
      var colour;

      for (var i = 0; i < 3; i++) {
         var diff, nc = cc[ i ];

         if (! colour) colour = 'rgb(';
         else colour += ',';

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

   startFade: function( el ) {
      if (el.timer) {
         clearInterval( el.timer ); el.timer = null;

         if (el.colour) el.setStyle( 'color', el.colour.hexToRgb() );
      }

      el.colour = this.currentColour( el );
      el.timer  = this.fade.periodical( this.options.speed, this, [ el, 1 ] );
   }
} );

var LiveGrid = new Class( {
   initialize: function( tableId, url, options ) {
      this.url      = url;
      this.tableId  = tableId;
      this.options  = options = options || {};
      this.table    = $( tableId );
      this.metaData = new LiveGridMetaData( options );
      this.buffer   = new LiveGridBuffer( this.metaData );

      this.lastDisplayedStartPos = -1;
      this.timeoutHander         = null;
      this.additionalParms       = options.requestParameters || {};
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

   ajaxUpdate: function( text, xml ) {
      clearTimeout( this.timeoutHandler ); this.timeoutHandler = null;

      try {
         var totalrows =  xml.documentElement.getAttribute( 'totalcount' );

         if (totalrows) this.setTotalRows( totalrows );
      }
      catch (err) {}

      this.buffer.update( text, xml );

      if (this.unprocessedRequest == null)
         this.updateContent( this.processingRequest.requestOffset );

      this.processingRequest = null;

      if (! this.scroller) {
         this.scroller = new LiveGridScroller( this );

         if (this.options.onFirstContent) this.options.onFirstContent( this );
      }

      if (this.options.onComplete) this.options.onComplete( this );

      this.processQueuedRequest();
      return;
   },

   fetchBuffer: function( offset, sequence_buffers ) {
      var page, page_size;

      if (this.processingRequest) {
         this.unprocessedRequest = new LiveGridRequest( offset );
         return;
      }

      this.processingRequest = new LiveGridRequest( offset );

      if (! this.ajaxRequest) {
         var options = {}; Object.extend( options, this.options );

         options.onSuccess = this.ajaxUpdate.bind( this );
         options.url       = this.url;
         this.ajaxRequest  = new Request( options );
      }

      page_size = this.metaData.getBufferSize() * this.metaData.getPageSize();
      page      = Math.floor( offset / page_size );

      if (sequence_buffers)
         page  += offset - page * page_size > page_size / 2 ? 1 : -1;

      if (page < 0) page = 0;

      var callParms = { 'content-type': 'text/xml', 'id'       : this.tableId,
                        'page'        : page,       'page_size': page_size };

      Object.extend( callParms, this.additionalParms );
      this.ajaxRequest.get( callParms );
      this.timeoutHandler = setTimeout( this.handleTimedOut.bind(this), 10000);
      return;
   },

   handleTimedOut: function() {
      //server did not respond in n secs assume that there could have been
      //an error or something, and allow requests to be processed again...
      this.processingRequest = null;
      this.processQueuedRequest();
      return;
   },

   processQueuedRequest: function() {
      if (this.unprocessedRequest != null) {
         this.requestContentRefresh( this.unprocessedRequest.requestOffset );
         this.unprocessedRequest = null
      }

      return;
   },

   replaceCellContents: function( buffer, start ) {
      if (start == this.lastDisplayedStartPos) return;

      this.table.set( 'html', buffer.getRows( start ).join( '' ) );
      this.lastDisplayedStartPos = start
      return;
   },

   requestContentRefresh: function( offset ) {
      if ( this.buffer.isFullyInRange( offset ) ) {
         this.updateContent( offset );

         if (this.buffer.needsMorePages( offset ))
            this.fetchBuffer( offset, true );
      }
      else if (this.buffer.isClose( offset )) {
         this.fetchBuffer( offset, true );
      }
      else { this.fetchBuffer( offset, false ) }

      return;
   },

   setRequestParams: function( params ) {
      this.additionalParms = params;
      return;
   },

   setTotalRows: function( newTotalRows ) {
      this.metaData.setTotalRows( newTotalRows );
      this.scroller.updateSize();
      return;
   },

   updateContent: function( offset ) {
      return this.replaceCellContents( this.buffer, offset );
   }
} );

var LiveGridBuffer = new Class( {
   initialize: function( metaData ) {
      this.start    = 0;
      this.size     = 0;
      this.metaData = metaData;
      this.rows     = [];
   },

   getRows: function( start ) {
      return this.rows.slice( start, start + this.metaData.getPageSize() );
   },

   isClose: function( start ) {
      return this.rows[start] || this.rows[start + this.metaData.getPageSize()];
   },

   isFullyInRange: function( start ) {
      return this.rows[start] && this.rows[start + this.metaData.getPageSize()];
   },

   needsMorePages: function( start ) {
      return this.needsPrevPage( start ) || this.needsNextPage( start );
   },

   needsNextPage: function( start ) {
      return ! this.rows[ start + 2 * this.metaData.getPageSize() ];
   },

   needsPrevPage: function( start ) {
      return ! this.rows[ start - this.metaData.getPageSize() ];
   },

   update: function( text, xml ) {
      var doc    = xml.documentElement;
      var rows   = doc.getElementsByTagName( 'items' );

      this.start = parseInt( doc.getAttribute( 'offset' ) );
      this.size  = parseInt( doc.getAttribute( 'count'  ) );

      for (var i = 0, size = this.size; i < size; i++) {
         this.rows[ this.start + i ]
            = rows[ i ].childNodes[ 0 ].nodeValue.unescapeHTML();
      }

      return;
   }
} );

var LiveGridMetaData = new Class( {
   initialize: function( options ) {
      this.bufferSize   = options.bufferSize   || 7;
      this.onscroll     = options.onScroll     || null;
      this.onscrollidle = options.onScrollidle || null;
      this.pageSize     = options.pageSize     || 10;
      this.totalRows    = options.totalRows    || 0;
   },

   getBufferSize: function()    { return this.bufferSize },

   getPageSize:   function()    { return this.pageSize },

   getTotalRows:  function()    { return this.totalRows },

   setTotalRows:  function( n ) { this.totalRows = n }
} );

var LiveGridRequest = new Class( {
   initialize: function( requestOffset, options ) {
      this.requestOffset = requestOffset;
   }
} );

var LiveGridScroller = new Class( {
   initialize: function( liveGrid ) {
      this.liveGrid      = liveGrid;
      this.metaData      = liveGrid.metaData;
      this.scrollTimeout = null;
      this.lastScrollPos = 0;
      this.createScrollBar();
   },

   adjustScrollTop: function() {
      var sd = this.scrollerDiv, rem = sd.scrollTop % this.lineHeight;

      this.unplug();

      if (rem != 0)
         sd.scrollTop +=
            (this.lastScrollPos < sd.scrollTop ? this.lineHeight : 0) - rem;

      this.lastScrollPos = sd.scrollTop;
      this.plugin();
      return;
   },

   createScrollBar: function() {
      var table         = this.liveGrid.table;
      var visibleHeight = table.offsetHeight;
      var pageSize      = this.metaData.getPageSize();
      var lineHeight    = visibleHeight / pageSize;
      var height        = this.metaData.getTotalRows() * lineHeight;

      this.lineHeight   = lineHeight;
      this.heightDiv    = new Element( 'div', {
         styles: { height: parseInt( height ) + 'px', width: '1px' }
      } );
      this.scrollerDiv  = new Element( 'div', {
         styles     : {
            height  : visibleHeight + 'px',
            overflow: 'auto',
            position: 'relative',
            width   : '19px' }
      } );
      this.scrollerDiv.setStyle( 'left', Browser.ie ? '-6px' : '-4px' );
      this.scrollerDiv.appendChild( this.heightDiv );
      this.scrollerDiv.inject( table.parentNode, 'after' );
      this.plugin();

      if (Browser.ie) {
         table.onmousewheel = function( ev ) {
            this.scrollerDiv.scrollTop
               += (ev.wheelDelta >= 0 < 0 ? -1 : 1) * this.lineHeight;
            this.handleScroll( true );
         }.bind( this );
      }
      else {
         table.addEventListener( 'DOMMouseScroll', function( ev ) {
            this.scrollerDiv.scrollTop
               += (ev.detail < 0 ? -1 : 1) * this.lineHeight;
            this.handleScroll( true );
         }.bind( this ), true );
      }

      return;
   },

   handleScroll: function( skiptimeout ) {
      if (this.scrollTimeout) {
         clearTimeout( this.scrollTimeout ); this.scrollTimeout = null;
      }

      var contentOffset = parseInt( this.scrollerDiv.scrollTop
                * this.metaData.getTotalRows() / this.heightDiv.offsetHeight );

      if (this.metaData.onscroll)
         this.metaData.onscroll( contentOffset, this.metaData );

      if (skiptimeout == true) this.scrollIdle();
      else this.scrollTimeout = setTimeout( this.scrollIdle.bind( this ), 100 );

      return;
   },

   isUnPlugged: function() { return this.scrollerDiv.onscroll == null },

   moveScroll: function( rowOffset ) {
      this.scrollerDiv.scrollTop = this.heightDiv.offsetHeight
                                     * rowOffset / this.metaData.getTotalRows();
      return;
   },

   plugin: function() {
      this.scrollerDiv.onscroll = this.handleScroll.bind( this ); return;
   },

   scrollIdle: function() {
      if (this.scrollTimeout) {
         clearTimeout( this.scrollTimeout ); this.scrollTimeout = null;
      }

      // this.adjustScrollTop();
      var contentOffset = parseInt( this.scrollerDiv.scrollTop *
                 this.metaData.getTotalRows() / this.heightDiv.offsetHeight );

      this.liveGrid.requestContentRefresh( contentOffset );

      if ( this.metaData.onscrollidle ) this.metaData.onscrollidle();

      return;
   },

   unplug: function() { this.scrollerDiv.onscroll = null; return },

   updateSize: function() {
      var table = this.liveGrid.table, visibleHeight = table.offsetHeight;

      this.heightDiv.style.height = parseInt( visibleHeight *
         this.metaData.getTotalRows() / this.metaData.getPageSize() ) + 'px';
      return;
   }
} );

var LiveGrids = new Class( {
   Implements: [ Options ],

   options      : {
      config    : { iconClasses: [ 'a', 'b' ] },
      gridSize  : 10,
      gridToggle: true,
      selector  : '.live_grid',
      url       : null
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      el.addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); return this.requestGrid( el );
      }.bind( this ) );
   },

   _createGrid: function( text, xml ) {
      var keyid  = this.gridKey + '_' + this.gridId,
          count  = parseInt( xml.documentElement.getAttribute( 'totalcount' ) ),
          rows   = $$( xml.documentElement.getElementsByTagName( 'items' ) ),
          urlkey = this.options.url + this.gridKey + '_grid_rows',
          html   = '',
          opts   = {
             bufferSize    : 7,
             gridSize      : this.options.gridSize,
             prefetchBuffer: true,
             onScroll      : this._updateHeader.bind( this ),
             onFirstContent: this._updateHeader.bind( this, 0 ),
             totalRows     : count };

      rows.each( function( row ) { html += row.childNodes[ 0 ].nodeValue } );

      $( keyid + 'Disp' ).set( 'html', html.unescapeHTML() );

      this.gridObj = new LiveGrid( keyid + '_grid', urlkey, opts );
   },

   requestGrid: function( anchor ) {
      var el, a = anchor.id.split( '_' ), key = a[ 0 ], id = a[ 1 ];

      if (! key || ! id || ! (el = $( anchor.id + 'Disp' ))) return;

      var opt = this.options, cfg = opt.config;

      if (opt.gridToggle && el.isDisplayed()) {
         el.hide();

         if (el = $( anchor.id + 'Icon' )) el.className = cfg.iconClasses[ 0 ];

         this.gridKey = null; this.gridId = null; this.gridObj = null;
         return;
      }

      if (this.gridKey && this.gridId) {
         var keyid = this.gridKey + '_' + this.gridId, prev;

         if (prev = $( keyid + 'Disp' )) prev.hide();
         if (prev = $( keyid + 'Icon' )) prev.className = cfg.iconClasses[ 0 ];

         this.gridKey = null; this.gridId = null; this.gridObj = null;
      }

      el.show(); this.gridKey = key; this.gridId = id;

      if (el = $( anchor.id + 'Icon' )) el.className = cfg.iconClasses[ 1 ];

      new Request( {
         onSuccess: this._createGrid.bind( this ),
         url      : opt.url + key +  '_grid_table' } ).get( {
            'content-type': 'text/xml', 'id': id, 'val': opt.gridSize } );
      return;
   },

   _updateHeader: function( offset ) {
      var id, sortInfo, text, urlkey, metaData = this.gridObj.metaData;

      id    = this.gridKey + '_' + this.gridId + '_header';
      text  = 'Listing ' + (offset + 1) + ' - ';
      text += (offset + metaData.getPageSize());
      text += ' of ' + metaData.getTotalRows();
      $( id ).set( 'html', text );

      if (this.gridObj.sortCol) {
         sortInfo  = '&data_grid_sort_col=' + this.gridObj.sortCol;
         sortInfo += '&data_grid_sort_dir=' + this.gridObj.sortDir;
      }
      else sortInfo = '';

      urlkey = this.options.url + this.gridKey + '_gridPage';
      text   = urlkey + '?data_grid_index=' + offset + sortInfo;
      $( id ).href = text;
      return;
   }
} );

var PersistantStyleSheet = new Class( {
   initialize: function( options ) {
      var opt = options || {}; this.cookies = opt.cookies || function() {};

      this.setActive( this.cookies.get( 'stylesheet' ) || this.getPreferred() );

      window.addEvent( 'unload', function() {
         this.cookies.set( 'stylesheet', this.getActive() );
      }.bind( this ) );
   },

   getActive: function() {
      var active;

      $$( 'link' ).some( function( el ) {
         return (el.rel.indexOf( 'style' ) != -1
                 && ! el.disabled && (active = el.title)) ? true : false;
      } );

      return active;
   },

   getPreferred: function() {
      var preferred;

      $$( 'link' ).some( function( el ) {
         return (el.rel.indexOf( 'style' ) != -1
                 && el.rel.indexOf( 'alt' ) == -1 && (preferred = el.title))
              ? true : false;
      } );

      return preferred;
   },

   setActive: function( active ) {
      $$( 'link' ).each( function( el ) {
         if (el.rel.indexOf( 'style' ) != -1 && el.title)
            el.disabled = el.title != active ? true : false;
      } );
   }
} );

var RotateList = new Class( {
   Implements: [ Options ],

   options      : {
      config    : {},        // Per list config keyed by list id
      direction : 'up',      // Direction in which to scroll
      duration  : 1000,      // Millisecs for each transition
      nitems    : 3,         // Number of items to display
      selector  : '.rotate', // Class name matching lists to rotate
      speed     : 5000,      // Millisecs between rotations
      transition: 'linear',  // Transition style
      zero_style: { height : 0, marginBottom : 0, marginTop : 0,
                    opacity: 0, paddingBottom: 0, paddingTop: 0 }
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var opt = this.options; this.setConfigOptions( el );

      var first; if (! (first = el.getElement( 'li' ))) return;

      el.setStyle( 'height', (opt.nitems * first.getHeight()) + 'px' );
      el.timer = opt.direction == 'up'
               ? this.rotateListUp.periodical  ( opt.speed, this, [ el ] )
               : this.rotateListDown.periodical( opt.speed, this, [ el ] );
   },

   rotateListDown: function( el ) {
      var opt      = this.options;
      var first    = el.getElement ( 'li' );
      var last     = el.getElements( 'li' ).getLast();
      var styles   = last.getStyles( 'height',        'marginBottom',
                                     'marginTop',     'opacity',
                                     'paddingBottom', 'paddingTop' );
      var disposed = last.dispose();

      disposed.setStyles( opt.zero_style );

      var inserted = el.insertBefore( disposed, first );

      inserted.set  ( 'morph', { duration  : opt.duration,
                                 transition: opt.transition } );
      inserted.morph( styles );
   },

   rotateListUp: function( el ) {
      var opt    = this.options;
      var first  = el.getElement( 'li' );
      var clone  = first.clone();
      var rotate = function() {
          this.destroy(); el.appendChild( clone ) }.bind( first );

      first.set  ( 'morph', { onComplete: rotate,
                              duration  : opt.duration,
                              transition: opt.transition } );
      first.morph( opt.zero_style );
   }
} );

/* Adds markers to the page scrollbar to indicate the location of key
   elements on the page. Inspired by a simmilar mechanism used on MSNBC.com
   Was rewritten from from a Scriptaculous extension which was
   Copyright (c) 2010, Jarvis Badgley - chiper[at]chipersoft[dot]com
   Usage:

   var sp = new ScrollPins( { config: { Pintray: { pins: {
      // anchor elements are referenced via css selectors
      'hr'          : { image: 'pins/pin_gray.png' },
      // document order doesn't matter, only the order in the object
      'div'         : { image: 'pins/pin_empty.png' },
      // this line overwrites the pin created by 'div'
      'div.red'     : { image:'pins/pin_red.png' },
      // use a css selector to identify the pin contents
      'div.orange'  : { selector:'button' },
      // use an element id to get the pin contents
      'div.blue'    : { element:'bluepin' },
      // or add the element directly by variable
      //If the element was already in use as a pin, it gets cloned
      'div.lavender': { element:document.body.getChildren()[0] },
      //remove pins created by higher up in the array
      'div.eggplant': null
   } } } } ); */

var ScrollPins = new Class( {
   Implements: [ Events, Options ],

   options             : {
      config           : {},
      scrollBarWidth   : 19,
      scrollDuration   : 500,
      scrollMargin     : 0,
      selector         : '.pintray',
      tag              : 'li',
      target           : window,
      trayPadding      : 10,
      trayPaddingBottom: undefined,
      trayPaddingTop   : undefined
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();

      this.fireEvent( 'initialize' );
   },

   build: function() {
      var opt = this.options;

      if (opt.selector) $$( opt.selector ).each( function( pintray ) {
         var cfg = Object.merge( opt, opt.config,
                                 (opt.config[ pintray.id ] || {}) );

         if (typeOf( cfg.target ) != 'window') cfg.target = $( cfg.target );

         pintray.cfg = cfg; pintray.pins = pintray.pins || [];

         Object.each( cfg.pins || {}, function( value, key ) {
            this.createMarkup( pintray, key, value );
         }, this );

         this.resize( pintray );

         pintray.pins.each( function( el ) { this.attach( el ) }, this );

         if (! this.collection.contains( pintray )) {
            cfg.target.addEvent( 'resize', this.resize.bind( this, pintray ) );
            this.collection.include( pintray );
         }
      }, this );

      this.fireEvent( 'build' );
   },

   attach: function( el ) {
      if (el.attached) return; el.attached = true;

      var cfg      = el.pin.pintray.cfg,
          margin   = el.getStyle( 'margin-top' ).toInt(),
          position = el.getPosition( cfg.target ),
          padding  = typeOf( cfg.target ) != 'window'
                   ? cfg.target.getStyle( 'padding-top' ).toInt() : 0;

      if (this.debug)
         this.log( 'ScrollPins attach: ' + position.y + ' ' + margin
                   + ' ' + padding );

      el.pin.addEvent( 'click', function( ev ) {
         new Event( ev ).stop();
         new Fx.Scroll( cfg.target, { duration: cfg.scrollDuration } )
                .start( position.x, position.y - margin - padding );
      } );

      this.fireEvent( 'attach', [ el ] );
   },

   createMarkup: function( pintray, key, value ) {
      // key   contains a selector for the node we want the pin to point at
      // value contains an object indicating what the pin should be made of
      var template = value ? this._getTemplate( value ) : false;

      if (template) template.pin_used = template.pin_used || 0;

      $$( key ).each( function( el ) {
         if (el.pin) el.pin.destroy(); if (! template) return;

         var cfg    = pintray.cfg,
             markup = template.pin_used++ ? template.clone( true )
                                          : template.show();

         if (cfg.title) markup.title = cfg.title.call( this, el );

         el.pin = new Element( cfg.tag ).inject( pintray );

         el.pin.grab( el.pin.markup = markup ); el.pin.pintray = pintray;

         pintray.pins.include( el );
      }, this );
   },

   _getTemplate: function( obj ) {
      return obj.icon     ? new Element( 'span', { class: obj.icon  } )
           : obj.image    ? new Element( 'img',  { src  : obj.image } )
           : obj.selector ? $$( obj.selector )[ 0 ]
           : obj.element  ?  $( obj.element  )
                          : false;
   },

   resize: function( pintray ) {
      this._resizePintray( pintray );

      pintray.pins.each( function( el ) {
         var cfg         = el.pin.pintray.cfg,
             padding_bot = [ cfg.trayPaddingBottom, cfg.trayPadding ].pick(),
             padding_top = [ cfg.trayPaddingTop,    cfg.trayPadding ].pick(),
             real_height = cfg.target.getScrollHeight(),
             view_height = cfg.target.getHeight(),
             pin_height  = el.pin.getHeight(),
             offset      = el.getPosition( cfg.target ).y,
             maximum     = view_height - padding_top - pin_height - padding_bot,
             pin_top     = padding_top + (offset * maximum / real_height);

         if (this.debug)
            this.log( 'ScrollPins resize: ' + padding_bot + ' '
                    + padding_top + ' ' + real_height + ' ' + view_height + ' '
                    + pin_height  + ' ' + offset      + ' ' + maximum     + ' '
                    + pin_top );

         el.isVisible() && el.parentNode ? el.pin.show() : el.pin.hide();
         pin_top = Math.max( Math.min( pin_top, maximum ), padding_top );
         el.pin.setStyle( 'top', pin_top.round() + 'px' );
      }, this );
   },

   _resizePintray: function( pintray ) {
      var cfg = pintray.cfg, target = cfg.target;

      if (typeOf( target ) == 'window') return;

      var margin_right = target.getStyle( 'margin-right' ).toInt(),
          right        = target.getStyle( 'right' ).toInt() + margin_right,
          margin_top   = target.getStyle( 'margin-top' ).toInt(),
          top          = target.getStyle( 'top' ).toInt() + margin_top;

      pintray.setStyles( { right: (cfg.scrollBarWidth + right) + 'px',
                           top  : top + 'px' } );
   }
} );

var ServerUtils = new Class( {
   Implements: [ Options ],

   options    : {
      config  : {},
      selector: '.server',
      url     : null
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var cfg; if (! (cfg = this.options.config[ el.id ])) return;
      var event = cfg.event || 'click';

      if (event == 'load') {
         this[ cfg.method ].apply( this, cfg.args ); return;
      }

      el.addEvent( event, function( ev ) {
         new Event( ev ).stop(); this[ cfg.method ].apply( this, cfg.args );
      }.bind( this ) );
   },

   checkField: function( id ) {
      this.request( 'check_field', id, $( id ).value, function( doc, html ) {
         $( doc.getAttribute( 'id' ) ).className
            = html ? doc.getAttribute( 'class_name' ) : 'hidden';
      }.bind( this ) );
   },

   request: function( action, id, val, onComplete ) {
      if (onComplete) this.onComplete = onComplete;

      new Request( { onSuccess: this._response.bind( this ),
                     url      : this.options.url + action
      } ).get( { 'content-type': 'text/xml', 'id': id, 'val': val } );
   },

   requestIfVisible: function( action, id, val, onComplete ) {
      if ($( id ).isVisible()) this.request( action, id, val, onComplete );
   },

   _response: function( text, xml ) {
      var doc = xml.documentElement, html = '';

      $$( doc.getElementsByTagName( 'items' ) ).each( function( item ) {
         for (var i = 0, il = item.childNodes.length; i < il; i++) {
            html += item.childNodes[ i ].nodeValue;
         }
      } );

      $( doc.getAttribute( 'id' ) ).set( 'html', html.unescapeHTML() );

      if (this.onComplete) this.onComplete.call( this.callbacks, doc, html );
   }
} );

var Sidebar = new Class( {
   Implements: [ Options ],

   options                : {
      accordion           : 'accordionDiv',
      config              : {},
      panel               : 0,
      panelClass          : '.accordion_panel',
      prefix              : 'sidebar',
      togglerClass        : '.accordion_header',
      togglerHeight       : 30,
      togglersMarginHeight: 12,
      togglersMinMargin   : 5,
      width               : 38
   },

   initialize: function( options ) {
      this.callbacks = options.callbacks || {}; delete options[ 'callbacks' ];

      this.setOptions( options ); var opt = this.options, prefix = opt.prefix;

      var sb; if (! (sb = this.el = $( prefix + 'Disp' ))) return;

      var cookies  = this.callbacks.cookies || {};
      var sb_state = cookies.get( prefix ) ? true : false;
      var sb_panel = cookies.get( prefix + 'Panel' ) || opt.panel;
      var sb_width = cookies.get( prefix + 'Width' )
                  || parseInt( opt.width * window.getWidth() / 100 );

      cookies.set( prefix + 'Width', sb_width );

      /* Setup the slide in/out effect */
      this.slider = new Fx.Slide( prefix + 'Container', {
         mode      : 'horizontal',
         onComplete: function() {
            var sb_icon = $( prefix + 'Icon' );

            /* When the effect is complete toggle the state */
            if (this.callbacks.cookies.get( prefix )) {
               if (sb_icon) sb_icon.className = 'pushedpin_icon';
            }
            else {
               this.callbacks.resize();

               if (sb_icon) sb_icon.className = 'pushpin_icon';
            }
         }.bind( this ),
         transition: Fx.Transitions.Circ.easeInOut
      } );

      /* Setup the event handler to turn the side bar on/off */
      $( prefix ).addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); var cookies = this.callbacks.cookies;

         if (cookies.get( prefix )) {
            cookies.remove( prefix ); this.slider.slideOut();
         }
         else {
            var panel = cookies.get( prefix + 'Panel' );

            cookies.set( prefix, 'pushedpin_icon' ); this.callbacks.resize();
            this.accordion.display( panel, false ); this.slider.slideIn();
         }

         return false;
      }.bind( this ) );

      /* Setup the horizontal resize grippy for the side bar */
      sb.makeResizable( {
         handle   : $( prefix + 'Grippy' ),
         limit    : { x: [ 150, 450 ] },
         modifiers: { x: 'width', y: false },
         onDrag   : function() {
             var sb_width = sb.getStyle( 'width' ).toInt();

             this.callbacks.cookies.set( prefix + 'Width',  sb_width );
             this.slider.wrapper.setStyle( 'width', sb_width + 'px' );
             this.callbacks.resize() }.bind( this )
      } );

      var togglers  = $$( opt.togglerClass ), panels = $$( opt.panelClass );
      var getHeight = this.getHeight.pass( [ togglers ], this );

      /* Create an Accordion widget in the side bar */
      this.accordion = new Fx.Accordion( togglers, panels, {
         display         : sb_state ? sb_panel : -1,
         fixedHeight     : getHeight,
         initialDisplayFx: false,
         opacity         : false,
         onActive        : function( togglers, index, el ) {
            var toggler = togglers[ index ];

            toggler.swapClass( 'inactive', 'active' );
            this.callbacks.cookies.set( prefix + 'Panel', index );

            var cfg; if (! (cfg = opt.config[ toggler.id ])) return;

            if (cfg.action && cfg.name) {
               this.callbacks.server.request( cfg.action, cfg.name,
                                              cfg.value,  cfg.onComplete );
            }
         }.bind( this ),
         onBackground    : function( togglers, index, el ) {
            togglers[ index ].swapClass( 'active', 'inactive' );
         }
      } );

      return;
   },

   getHeight: function( togglers ) {
      var opt    = this.options;
      var styles = { styles: [ 'padding', 'border', 'margin' ] };
      var size   = this.el.getComputedSize( styles );
      var height = (opt.togglerHeight * togglers.length)
                 + opt.togglersMarginHeight;
      var margin = Math.max( opt.togglersMinMargin,
                             this.el.getStyle( 'marginBottom' ).toInt() );

      return Math.max( 1, size.totalHeight - (height + margin) );
   },

   getWidth: function() {
      return this.el.getStyle( 'width' ).toInt();
   },

   resize: function() {
      var sb; if (! (sb = this.el)) return;

      var prefix        = this.options.prefix;
      var cookies       = this.callbacks.cookies;
      var state         = cookies.get( prefix ) ? true : false;
      var margin_bottom = this.callbacks.getContentMarginBottom();

      if (state) { sb.show() } else { sb.hide() }

      sb.setStyle( 'marginBottom', margin_bottom + 'px' );

      // Calculate and set vertical offset for side bar grippy
      var sb_height     = sb.getHeight();
      var grippy_height = $( prefix + 'Grippy' ).getHeight();
      var offset        = Math.max( 1, Math.round( sb_height / 2 )
                                     - Math.round( grippy_height / 2 ) );

      $( prefix + 'Grippy' ).setStyle( 'marginTop', offset + 'px' );

      var sb_width = state ? cookies.get( prefix + 'Width' ) : 0;

      sb.setStyle( 'width', sb_width + 'px' );
      this.accordion.resize();
      return;
   }
} );

var Sliders = new Class( {
   Implements: [ Options ],

   options: { config: {}, selector: '.slider' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var cfg, opt = this.options, slider, submit = this.callbacks.submit;

      if (! (cfg = opt.config[ el.id ])) return;

      var name       = cfg.name;       delete cfg[ 'name'       ];
      var default_v  = cfg.default_v;  delete cfg[ 'default_v'  ];
      var knob_class = cfg.knob_class; delete cfg[ 'knob_class' ];
      var knob       = el.getElement( knob_class );

      cfg = Object.append( cfg, {
         onChange: function( value ) {
            submit.setField.call( submit, name, value ) }
      } );

      el.slider = new Slider( el, knob, cfg ).set( default_v );
   }
} );

/* Originally Copyright (c) 2011 Felix Gnass [fgnass at neteye dot de]
 * https://fgnass.github.com/spin.js
 * Licensed under the MIT license */

Spinner.JS = new Class( {
   Extends: Spinner,

   options       : {
      fill_args  : '0 0 1px rgba(0,0,0,.1)',
      length     : 7,
      line_width : 5,
      lines      : 12,
      opacity    : 0.25,
      prefixes   : [ 'webkit', 'Moz', 'ms', 'O' ],
      radius     : 10,
      shadow     : false,
      shadow_args: '0 0 4px black',
      speed      : 1,
      tag        : [ 'group', 'roundrect', 'fill', 'stroke' ],
      trail      : 100,
      url_vml    : 'url(#default#VML)'
   },

   hide: function( no_fx ) {
      window.clearTimeout( this.timeout );

      if (this.js_spinner && this.js_spinner.parentNode)
         this.js_spinner.parentNode.removeChild( this.js_spinner );

      this.js_spinner = undefined;
      return this.parent( no_fx );
   },

   render: function() {
      this.parent();
      this.animations = {};
      this.styleSheet = this._styleSheet();
      this.use_vml    = false;

      var opt = this.options, group = new Element( opt.tag[ 0 ] );

      this._setStyles( group, 'behavior', opt.url_vml );

      if (!this._vendor( group, 'transform' ) && group.adj) {
         this.use_vml = true;

         for (var i = 0, limit = opt.tag.length; i < limit; i++) {
            this.styleSheet.addRule( opt.tag[ i ], 'behavior:' + opt.url_vml );
         }
      }
      else this.use_css_animations = this._vendor( group, 'animation' );
   },

   show: function( no_fx ) {
      this.js_spinner = this.use_vml ? this._init_vml()
                                     : this._init_css_animations();

      this._insert( this.content, this.js_spinner, this.content.firstChild );

      if (! this.use_css_animations) this._use_js_animations();

      return this.parent( no_fx );
   },


   toggle: function() {
      return this.js_spinner == undefined ? this.show() : this.hide();
   },

   /* Private methods */

   _addAnimation: function( to, end ) {
      var name  = [ 'opacity', end, ~~(to * 100) ].join( '-' );

      if (this.animations[ name ]) return name;

      var opt = this.options, dest = '{ opacity:' + to + '}';

      for (var i = 0, limit = opt.prefixes.length; i < limit; i++) {
         try {
            var rule = '@' +
               (opt.prefixes[ i ] && '-' + opt.prefixes[ i ].toLowerCase()
                + '-' || '') + 'keyframes ' + name + '{0%{opacity:1}' +
               end + '%' + dest + 'to' + dest + '}';

            this.styleSheet.insertRule( rule, this.styleSheet.cssRules.length );
         }
         catch (err) {}
      }

      this.animations[ name ] = 1;
      return name;
   },

   _eachPair: function( args, it ) {
      for (var i = 1, limit = ~~((args.length - 1) / 2); i <= limit; i++) {
         it( args[ i * 2 - 1 ], args[ i * 2 ] );
      }
   },

   _init_css_animations: function() {
      var opt     = this.options;
      var aname   = this._addAnimation( opt.opacity, opt.trail );
      var offset  = 4 + opt.length + opt.radius + opt.line_width;
      var size    = (2 * offset) + 'px';
      var el      = new Element( 'div', { 'class': 'spinner-group' } )
         .setStyles( { 'position': 'relative',
                       'height'  : size, 'width': size } );
      var content = function( i, type ) {
         var klass  = type == 'shadow' ? 'spinner-shadow' : 'spinner-fill';
         var shadow = type == 'shadow' ? opt.shadow_args  : opt.fill_args;

         return this._setStyles
         ( new Element( 'div', { 'class': klass } ),
           'position',        'absolute',
           'width',           (opt.length + opt.line_width) + 'px',
           'height',          opt.line_width + 'px',
           'boxShadow',       shadow,
           'transformOrigin', 'left',
           'transform',       'rotate( '
              + ~~(360 / opt.lines * i) + 'deg) translate('
              + opt.radius + 'px, 0px )',
           'borderRadius',    '100em'
         );
      }.bind( this );

      for (var i = 0, limit = opt.lines; i < limit; i++) {
         var segment = this._setStyles
         ( new Element( 'div' ),
           'position',  'absolute',
           'left',      offset + 'px',
           'top',       (1 + offset + ~(opt.line_width / 2)) + 'px',
           'animation', aname + ' ' + (1 / opt.speed)
              + 's linear ' + (-1 + 1 / opt.lines * i / opt.speed)
              + 's infinite'
         );

         if (opt.shadow)
            this._insert( segment, this._setStyles( content( i, 'shadow' ),
                                                    'top', '2px' ) );

         this._insert( el, this._insert( segment, content( i, 'fill' ) ) );
      }

      return el;
   },

   _init_vml: function() {
      // VML support detected. Insert CSS rules
      var opt    = this.options;
      var r      = opt.length + opt.line_width, s = 2 * r;
      var grp    = function() {
         return this._setStyles( new Element( opt.tag[ 0 ], {
            'coordSize'  :  s + ' ' +  s,
            'coordOrigin': -r + ' ' + -r } ), 'width', s, 'height', s );
      }.bind( this );
      var g      = grp();
      var seg    = function( i, dx, filter ) {
         this._insert
         ( g,
           this._insert
           ( this._setStyles( grp(),
                              'rotation', (360 / opt.lines * i) + 'deg',
                              'left', ~~dx ),
             this._insert
             ( this._setStyles( new Element( opt.tag[ 1 ], { 'arcsize': 1 } ),
                                'width', r, 'height', opt.line_width,
                                'left', opt.radius, 'top', -opt.line_width / 2,
                                'filter', filter ),
               new Element( opt.tag[ 2 ], { 'opacity': opt.opacity } ),
               new Element( opt.tag[ 3 ], { 'opacity': 0 } )
             )
           )
         );
      }.bind( this );

      if (opt.shadow) {
         for (var i = 1, limit = opt.lines; i <= limit; i++) {
            seg( i, -2, 'progid:DXImagetransform.Microsoft.Blur(pixelradius=2,makeshadow=1,shadowopacity=.3)' );
         }
      }

      for (var i = 1, limit = opt.lines; i <= limit; i++) { seg( i ) }

      var margin = ~(opt.length + opt.radius + opt.line_width) + 'px';
      var el     = new Element( 'div', { 'class': 'spinner-group' } )
         .setStyles( { 'position': 'relative',
                       'margin'  : margin + ' 0 0 ' + margin } );

      return this._insert( el, g );
   },

   _insert: function( parent, child1, child2 ) {
      if (child2 && !child2.parentNode) this._insert( parent, child2 );

      parent.insertBefore( child1, child2 || null );
      return parent;
   },

   _opacity: function( el, i, val ) {
      if (this.use_vml) {
         var opt = this.options, l = opt.shadow && opt.lines || 0;

         el.firstChild.childNodes[ i + l ].firstChild.firstChild.opacity = val;
      }
      else el.childNodes[ i ].style.opacity = val;
   },

   _setStyles: function( el ) {
      this._eachPair( arguments, function( k, v ) {
         el.style[ this._vendor( el, k ) || k ] = v;
      }.bind( this ) );

      return el;
   },

   _styleSheet: function() {
      var sheets = document.styleSheets, style = new Element( 'style' );

      this._insert( document.getElementsByTagName( 'head' )[ 0 ], style );

      return sheets[ sheets.length - 1 ];
   },

   _use_js_animations: function() {
      // No CSS animation support, use setTimeout() instead
      var i     = 0, opt = this.options, self = this;
      var f     = 20 / opt.speed;
      var ostep = (1 - opt.opacity) / (f * opt.trail / 100);
      var astep = f / opt.lines;

      (function anim() {
         i++;

         for (var s = opt.lines; s > 0; s--) {
            var alpha = Math.max( 1 - (i + s * astep) % f * ostep,
                                  opt.opacity );

            self._opacity( self.js_spinner, opt.lines - s, alpha );
         }

         self.timeout = self.js_spinner && window.setTimeout( anim, 50 );
      } )();
   },

   _vendor: function( el, prop ) {
      // Tries various vendor prefixes and returns the first supported property
      var opt = this.options, s = el.style;

      if (s[ prop ] !== undefined) return prop;

      prop = prop.charAt( 0 ).toUpperCase() + prop.slice( 1 );

      for (var i = 0, limit = opt.prefixes.length; i < limit; i++) {
         var pp = opt.prefixes[ i ] + prop;

         if (s[ pp ] !== undefined) return pp;
      }

      return;
   }
} );

var Spinners = new Class( {
   Implements: [ Options ],

   options: { config: {}, selector: '.spinner' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var cfg     = this.options.config;
      var options = cfg[ el.id ] || cfg[ 'defaults' ] || {};

      options.class = 'spinner-js'; options.img = false;

      new Spinner.JS( el, options );
   }
} );

var Storage = new Class( {
    Implements: [ Options ],

    options              : {
        document         : window.document,
        driver           : JSON,
        globalStorageName: 'globalStorage',
        localStorageName : 'localStorage',
        namespace        : '__storejs__',
        window           : window
    },

    initialize: function( options ) {
        this.setOptions( options );

        var opt = this.options, win = opt.window, doc = opt.document, storage;

        if (this._isLocalStorageSupported()) {
            storage      = win[ opt.localStorageName ];
            this.clear   = function() { storage.clear() };
            this.get     = function( key ) {
                return this.deserialize( storage.getItem( key ) );
            }.bind( this );
            this.remove  = function( key ) { storage.removeItem( key ) };
            this.set     = function( key, val ) {
                storage.setItem( key, this.serialize( val ) ) }.bind( this );
        }
        else if (this._isGlobalStorageSupported()) {
            storage      = win[ opt.globalStorageName ][ win.location.hostname];
            this.clear   = function() {
                for (var key in storage) delete storage[ key ]; };
            this.get     = function( key ) {
                return this.deserialize( storage[ key ] && storage[ key ].value)
            }.bind( this );
            this.remove  = function( key ) { delete storage[ key ] };
            this.set     = function( key, val ) {
                storage[ key ] = this.serialize( val ) }.bind( this );
        }
        else if (doc.documentElement.addBehavior) {
            storage      = doc.createElement( 'div' );
            this.clear   = this._ieStorage( storage, function( storage ) {
                var attrs = storage.XMLDocument.documentElement.attributes;

                storage.load( opt.localStorageName );

                for (var i = 0, attr; attr = attrs[ i ]; i++)
                    storage.removeAttribute( attr.name );

                storage.save( opt.localStorageName );
            } );
            this.get     = this._ieStorage( storage, function( storage, key ) {
                return this.deserialize( storage.getAttribute( key ) );
            }.bind( this ) );
            this.remove  = this._ieStorage( storage, function( storage, key ) {
                storage.removeAttribute( key );
                storage.save( opt.localStorageName );
            } );
            this.set = this._ieStorage( storage, function( storage, key, val ) {
                storage.setAttribute( key, this.serialize( val ) );
                storage.save( opt.localStorageName );
            }.bind( this ) );
        }
        else {
            this.clear   = function() {};
            this.get     = function( key ) {};
            this.remove  = function( key ) {};
            this.set     = function( key, value ) {};
        }

        this.deserialize = function( value ) {
            return this.decode( value ) }.bind( opt.driver );
        this.serialize   = function( value ) {
            return this.encode( value ) }.bind( opt.driver );
        this.transact    = function( key, callback ) {
            var val = this.get( key ); if (typeof val == 'undefined') val = {};

            callback( val ); this.set( key, val );
        }.bind( this );
        this.disabled    = false;

        try {
            this.set( opt.namespace, opt.namespace );

            if (this.get( opt.namespace ) != opt.namespace)
                this.disabled = true;

            this.remove( opt.namespace );
        }
        catch (e) { this.disabled = true }
    },

    _ieStorage: function( storage, storeFn ) {
        var opt = this.options, doc = opt.document;

        return function() {
            var args = Array.prototype.slice.call( arguments, 0 );

            args.unshift( storage );
            doc.body.appendChild( storage );
            storage.addBehavior( '#default#userData' );
            storage.load( opt.localStorageName );

            var result = storeFn.apply( this, args );

            doc.body.removeChild( storage );
            return result;
        }.bind( this );
    },

    _isLocalStorageSupported: function() {
        var opt = this.options, win = opt.window;

        try {
            return (opt.localStorageName in win && win[ opt.localStorageName ] )
        }
        catch (e) { return false }
    },

    _isGlobalStorageSupported: function() {
        var opt = this.options, win = opt.window;

        try {
            return (opt.globalStorageName in win && win[ opt.globalStorageName ]
                    && win[ opt.globalStorageName ][ win.location.hostname ] ) }
        catch (e) { return false }
    }
} );

var SubmitUtils = new Class( {
   Implements: [ Options ],

   options          : {
      chooseSelector: '.chooser_button',
      config        : {},
      formName      : null,
      submitSelector: '.submit'
   },

   initialize: function( options ) {
      this.setBuildOptions( options );
      this.form = document.forms ? document.forms[ this.options.formName ]
                                 : function() {};
      this.build();
   },

   build: function() {
      var opt = this.options;

      if (opt.chooseSelector) $$( opt.chooseSelector ).each( function( el ) {
         if (! this.collection.contains( el )) {
            this.collection.include( el ); this.attachChooser( el );
         }
      }.bind( this ) );

      if (opt.submitSelector) $$( opt.submitSelector ).each( function( el ) {
         if (! this.collection.contains( el )) {
            this.collection.include( el ); this.attachSubmit( el );
         }
      }.bind( this ) );
   },

   attachChooser: function( el ) {
      var cfg; if (! (cfg = this.options.config[ el.id ])) return;

      var win_prefs  = 'width=' + cfg.width + ', screenX=' + cfg.screen_x;
          win_prefs += ', height=' + cfg.height + ', screenY=';
          win_prefs += cfg.screen_y + ', dependent=yes, titlebar=no, ';
          win_prefs += 'scrollbars=yes';

      el.addEvent( 'click', function( ev ) {
         new Event( ev ).stop();
         this.chooser( el.value, cfg.field, cfg.href, win_prefs );
      }.bind( this ) );
   },

   attachSubmit: function( el ) {
      var cfg; if (! (cfg = this.options.config[ el.id ])) return;

      el.addEvent( cfg.event || 'click', function() {
         return this[ cfg.method ].apply( this, cfg.args );
      }.bind( this ) );
   },

   chooser: function( button, name, base, win_prefs ) {
      var value = this.form.elements[ name ].value || '';

      if (value.indexOf( '%' ) < 0) this.submitForm( button );
      else {
         var uri  = base + '?form=' + this.options.formName;
             uri += '&field=' + name + '&value=' + value;

         top.chooser = window.open( uri, 'chooser', win_prefs );
         top.chooser.opener = top;
      }
   },

   clearField: function( name ) {
      return this.setField( name, '' );
   },

   confirmSubmit: function( button, text ) {
      if (text.length < 1 || window.confirm( text )) {
         $$( '*[name=_method]' ).some( function( el ) {
            return (el.value == button) ? true : false;
         } ) ? this.form.submit() : this.submitForm( button );

         return true;
      }

      return false;
   },

   historyBack: function() {
      window.history.back(); return false;
   },

   postData: function( url, data ) {
      new Request( { url: url } ).post( data );
   },

   refresh: function( name, value ) {
      if (name) this.callbacks.cookies.set( name, value );

      this.form.submit();
      return false;
   },

   returnValue: function( form_name, name, value ) {
      if (form_name && name && opener) {
         var el, form = opener.document.forms[ form_name ];

         if (form && (el = form.elements[ name ])) {
            el.value = value; if (el.focus) el.focus();
         }
      }

      window.close();
      return false;
   },

   setField: function( name, value ) {
      var el; if (name && (el = this.form.elements[ name ])) el.value = value;

      return el ? el.value : null;
   },

   submitForm: function( button ) {
      new Element( 'input', {
          name: '_method', type: 'hidden', value: button
      } ).inject( $( 'top' ), 'after' );

      this.form.submit();
      return true;
   },

   submitOnReturn: function( button ) {
      ev = new Event();

      if (ev.key == 'enter') {
         if (document.forms) return this.submitForm( button );
         else window.alert( 'Document contains no forms' );
      }

      return false;
   }
} );

var TableSort = new Class( {
   Implements: [ Events, Options ],

   options          : {
/*    onSortComplete: function() {}, */
      selector      : 'th.sort',
      sortRowClass  : 'sortable_row' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.sortables = {}; this.build();
   },

   attach: function( el ) {
      el.addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); return this.sortRows( el );
      }.bind( this ) );
   },

   _get_sort_field: function( cell, type ) {
      var el = cell ? cell.firstChild : '', field = '';

      if      (el && el.nodeName == '#text') field = el.nodeValue;
      else if (el && el.nodeName == 'INPUT') field = el.value;

      if (type && type == 'date') {
         field = Date.parse( field ) || Date.parse( '01 Jan 1970' );
      }
      else if (type && type == 'money') {
         field = field.substring( 1 );
         field.replace( /[^0-9.]/g, '' );
         field = parseFloat( field ) || 0;
      }
      else if (type && type == 'numeric') {
         field.replace( /[^+\-0-9.]/g, '' );
         field = parseFloat( field ) || 0;
      }
      else field = field + '';

      return field;
   },

   _get_sort_order: function( table_id, default_column, column_id ) {
      var sortable = this.sortables[ table_id ]
                  || { sort_column: default_column, reverse: false };
      var reverse  = (column_id == sortable.sort_column)
                   ? ! sortable.reverse : false;

      sortable.reverse = reverse; sortable.sort_column = column_id;
      this.sortables[ table_id ] = sortable;
      return reverse ? [ 1, -1 ] : [ -1, 1 ];
   },

   sortRows: function( table_header ) {
      var id       = table_header.id,
          id_a     = id.split( '.' ),
          table_id = id_a[ 0 ], column_type = id_a[ 2 ],
          table    = $( table_id ),
          columns  = table.getElements( 'th' ),
          col_ids  = columns.map( function( column ) { return column.id } );

      if (! col_ids.contains( id )) return;

      var col_id   = col_ids.indexOf( id ),
          order    = this._get_sort_order( table_id, col_ids[ 0 ], id ),
          selector = 'tr.' + this.options.sortRowClass,
          rows     = [];

      table.getElements( selector ).map( function( row, index ) {
         var field = this._get_sort_field( row.cells[ col_id ], column_type );

         rows[ index ] = row;

         return [ field, row.clone( true, true ) ];
      }.bind( this ) ).sort( function( a, b ) {
         return a[ 0 ] < b[ 0 ] ? order[ 0 ]
             : (a[ 0 ] > b[ 0 ] ? order[ 1 ] : 0);
      } ).map( function( sorted_rows, index ) {
         var old_row    = rows[ index ],
             new_row    = sorted_rows[ 1 ],
             new_row_id = new_row.id;

         new_row.removeAttribute( 'id' ); new_row.replaces( old_row );

         return [ new_row, new_row_id ];
      } ).map( function( sorted_rows, index ) {
         var id, row = sorted_rows[ 0 ];

         if (id = sorted_rows[ 1 ]) row.id = id;

         return row;
      } );

      this.fireEvent( 'sortComplete' );
   }
} );

var TableUtils = new Class( {
   Implements: [ Events, Options ],

   options           : {
      config         : {},
      editRowClass   : 'editable_row',
      formName       : null,
      inputCellClass : 'data_field',
/*    onRowAdded     : function(){}, */
/*    onRowsRemoved  : function(){}, */
      selector       : 'table.editable',
      sortableOptions: {
         clone       : function( ev, el, list ) {
             return new Element( 'div' ).inject( document.body ); },
         constrain   : true,
         handle      : 'td.row_drag',
         revert      : { duration: 500, transition: 'elastic:out' } },
      sortRowClass   : 'sortable_row',
      textCellClass  : 'data_value',
   },

   initialize: function( options ) {
      this.setBuildOptions( options );
      this.form = document.forms ? document.forms[ this.options.formName ]
                                 : function() {};
      this.build();
   },

   attach: function( el ) {
      var opt = this.options;

      el.getElements( 'tr.' + opt.editRowClass ).each( function( row ) {
         $uid( row );
      } );

      el.sortables = new Sortables( el.getElement( 'tbody' ),
                                    opt.sortableOptions );

      var button = $( el.id + '_add' );

      if (button) button.addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); return this.addRow( el );
      }.bind( this ) );

      button = $( el.id + '_remove' );

      if (button) button.addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); return this.removeRows( el );
      }.bind( this ) );
   },

   addRow: function( table ) {
      var cNo     = 0, el,
          offset  = 0,
          opt     = this.options,
          cfg     = opt.config[ table.id ] || {},
          edit    = cfg.editSide   || 'left',
          select  = cfg.selectSide || 'left',
          klass   = opt.inputCellClass,
          rows    = table.getElements( 'tr.' + opt.editRowClass ),
          nrows   = rows ? rows.length : 0,
          row_id  = nrows,
          row     = new Element( 'tr', {
             id   : table.id + '_row' + row_id,
             class: opt.editRowClass + ' ' + opt.sortRowClass } ),
          id_a    = table.id.split( '.' ),
          name    = id_a[ 1 ] || id_a[ 0 ];

      if (edit == 'left') {
         row.appendChild( this._add_drag( cNo++ ) ); offset++;
      }

      if (select == 'left') {
         row.appendChild( this._add_select( name, row_id, cNo++ ) );
         offset++;
      }

      while (el = $( table.id + '_add' + (cNo - offset) )) {
         var cell  = new Element( 'td' ),
             type  = el.type == 'textarea' ? 'textarea' : 'input',
             input = new Element( type, {
                class: 'ifield',
                name : name + '_' + row_id + '_' + (cNo - offset),
                value: el.value
             } );

         if (el.cols)      input.set( 'cols',      el.cols );
         if (el.rows)      input.set( 'rows',      el.rows );
         if (el.size)      input.set( 'size',      el.size );
         if (el.maxlength) input.set( 'maxlength', el.maxlength );

         cell.appendChild( input );
         cell.set( 'class', klass + this._col_class( cNo++ ) );
         row.appendChild( cell );
         el.value = '';
      }

      if (select == 'right')
         row.appendChild( this._add_select( name, row_id, cNo++ ) );

      if (edit == 'right') row.appendChild( this._add_drag( cNo++ ) );

      this.form.elements[ '_' + name + '_nrows' ].value = nrows + 1;
      row.inject( $( table.id ).getElement( 'tbody' ) );
      table.sortables.attach();
      this.fireEvent( 'rowAdded' );
      return false;
   },

   _add_drag: function( cNo ) {
      var span = new Element( 'span', { class: 'drag_icon' } );
      var cell = new Element( 'td', {
         class: 'row_drag' + this._col_class( cNo )
      } );

      cell.appendChild( span );
      return cell;
   },

   _add_select: function( name, new_id, cNo ) {
      var input = new Element( 'input', {
         name: name + '.select' + new_id, type: 'checkbox'
      } );
      var cell  = new Element( 'td', {
         class: 'row_select' + this._col_class( cNo )
      } );

      cell.appendChild( input );
      return cell;
   },

   _col_class: function( cNo ) {
      return (cNo + 1) % 2 == 0 ? ' even_col' : ' odd_col';
   },

   removeRows: function( table ) {
      var rows      = table.getElements( 'tr.' + this.options.editRowClass ),
          nrows     = rows ? rows.length : 0,
          id_a      = table.id.split( '.' ),
          name      = id_a[ 1 ] || id_a[ 0 ],
          destroyed = 0;

      rows.map( function( row ) {
         row.getElements( 'td.row_select' ).map( function( cell ) {
            cell.getElements( 'input[type=checkbox]' ).map( function( cb ) {
               if (cb.checked) { row.destroy(); destroyed++ }
            } );
         } );
      } );

      this.form.elements[ '_' + name + '_nrows' ].value = nrows - destroyed;

      if (destroyed > 0) this.fireEvent( 'rowsRemoved' );

      return false;
   }
} );

/* Clientcide Copyright (c) 2006-2009
   Description: Handles the scripting for a common UI layout; the tabbed box.
   License: http://www.clientcide.com/wiki/cnet-libraries#license */

var TabSwapper = new Class( {
   Implements: [ Options, Events ],

   options           : {
      clickers       : 'a',
      cookieName     : 'tabswapper_',
      deselectedClass: 'off',
      effectOptions  : { duration: 500 },
      initPanel      : 0,
      maxSize        : null,
      mouseoverClass : 'tab_over',
//    onActive       : function(){},
//    onActiveAfterFx: function(){},
//    onBackground   : function(){},
      rearrangeDOM   : true,
      sections       : 'dd.panel',
      selectedClass  : 'tab_selected',
      smooth         : false,
      smoothSize     : false,
      tabs           : 'dt',
      usePersistance : true
   },

   tabs: [],

   initialize: function( el, options ) {
      this.cookies = options.cookies || function() {};

      this.setOptions( options ); var opt = this.options;

      this.cookieName = opt.cookieName + el.id;

      var sections = el.getElements( opt.sections );

      tabs = el.getElements( opt.tabs );

      tabs.each( function( tab, index ) {
         this.addTab( $( tab ), $( sections[ index ] ), index );
         this.hideSection( index );
      }, this );

      this.show( this.recall() ); el.store( 'tabSwapper', this );
   },

   addTab: function( tab, section, index ) {
      var opt = this.options, clicker = tab.getElement( opt.clickers ) || tab;

      // If the index isn't specified, put the tab at the end
      if (index == undefined) index = this.tabs.length;

      // If the tab is already in the interface, just move it
      if (this.tabs.indexOf( tab ) >= 0 && tab.retrieve( 'tabbered' )
          && this.tabs.indexOf( tab ) != index && opt.rearrangeDOM) {
         this.moveTab( this.tabs.indexOf( tab ), index );
         return this;
      }

      // If this isn't the first item, and there's a tab
      // already in the interface at the index 1 less than this
      // insert this after that one
      if (index > 0 && this.tabs[ index - 1 ] && opt.rearrangeDOM) {
         tab.inject( this.tabs[ index - 1 ], 'after' );
         section.inject( this.tabs[ index - 1 ].retrieve( 'section' ), 'after');
      }

      this.tabs.splice( index, 0, tab );

      tab.addEvents( {
         mouseout : function() {
            this.removeClass( opt.mouseoverClass ); }.bind( tab ),
         mouseover: function() {
            this.addClass( opt.mouseoverClass ); }.bind( tab )
      } );

      clicker.addEvent( 'click', function( ev ) {
         new Event( ev ).stop(); this.show( index );
      }.bind( this ) );

      tab.store( 'tabbered', true    );
      tab.store( 'section',  section );
      tab.store( 'clicker',  clicker );
      return this;
   },

   hideSection: function( idx ) {
      var tab; if (! (tab = this.tabs[ idx ])) return this;

      var section; if (! (section = tab.retrieve( 'section' ))) return this;

      if (section.isDisplayed()) {
         this.lastHeight = section.getHeight(); section.hide();
         tab.swapClass( this.options.selectedClass,
                        this.options.deselectedClass );
         this.fireEvent( 'onBackground', [ tab, section, idx ] );
      }

      return this;
   },

   moveTab: function( from, to ) {
      var tab       = this.tabs[ from ];
      var clicker   = tab.retrieve( 'clicker' );
      var section   = tab.retrieve( 'section' );
      var toTab     = this.tabs[ to ];
      var toClicker = toTab.retrieve( 'clicker' );
      var toSection = toTab.retrieve( 'section' );

      this.tabs.erase( tab ).splice( to, 0, tab );
      tab.inject( toTab, 'before' );
      clicker.inject( toClicker, 'before' );
      section.inject( toSection, 'before' );
      return this;
   },

   recall: function() {
      var opt = this.options, panel;

      if (opt.usePersistance) panel = this.cookies.get( this.cookieName );

      return panel ? panel.toInt() : opt.initPanel;
   },

   removeTab: function( index ) {
      var now = this.tabs[ this.now ];

      if (this.now == index) {
         if (index > 0) this.show( index - 1 );
         else if (index < this.tabs.length) this.show( index + 1 );
      }

      this.now = this.tabs.indexOf( now );
      return this;
   },

   save: function( index ) {
      var opt = this.options;

      if (opt.usePersistance) this.cookies.set( this.cookieName, index );

      return this;
   },

   show: function( i ) {
      if (! (this.now || this.now === 0)) {
         this.tabs.each( function( tab, idx ) {
            if (i != idx) this.hideSection( idx );
         }, this );
      }

      this.showSection( i ).save( i );
      return this;
   },

   showSection: function( idx ) {
      var opt = this.options, smoothOk = opt.smooth && !Browser.ie;

      var tab; if (! (tab = this.tabs[ idx ])) return this;

      var section; if (! (section = tab.retrieve( 'section' ))) return this;

      if (this.now != idx) {
         if (! tab.retrieve( 'tabFx' ))
            tab.store( 'tabFx', new Fx.Morph( section, opt.effectOptions ) );

         var effect   = false;
         var overflow = section.getStyle( 'overflow' );
         var start    = { display: 'block', overflow: 'hidden' };

         if (smoothOk) {
            start.opacity = 0; effect = { opacity: 1 };
         } else if (section.getStyle( 'opacity' ).toInt() < 1) {
            section.setStyle( 'opacity', 1 );

            if (! opt.smoothSize)
               this.fireEvent( 'onActiveAfterFx', [ tab, section, idx ] );
         }

         if (opt.smoothSize) {
            var size = section.getDimensions().height;

            if ((opt.maxSize || opt.maxSize === 0) && opt.maxSize < size)
                size = opt.maxSize;

            if (! effect) effect = {};

            effect.height = size;
         }

         if (this.now || this.now === 0) this.hideSection( this.now );

         if (opt.smoothSize && this.lastHeight) start.height = this.lastHeight;

         section.setStyles( start );

         if (effect) {
            tab.retrieve( 'tabFx' ).start( effect ).chain( function() {
               this.fireEvent( 'onActiveAfterFx', [ tab, section, idx ] );

               section.setStyles( {
                  height  : this.options.maxSize == effect.height
                          ? this.options.maxSize : 'auto',
                  overflow: overflow
               } );

               var inputs = section.getElements( 'input, textarea' );

               inputs.setStyle( 'opacity', 1 );
            }.bind( this ) );
         }

         this.now = idx; this.fireEvent( 'onActive', [ tab, section, idx ] );
      }

      tab.swapClass( opt.deselectedClass, opt.selectedClass );
      return this;
   }
} );

var TabSwappers = new Class( {
   Implements: [ Options ],

   options: { config: {}, selector: '.tabswapper' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var cfg     = this.options.config;
      var options = cfg[ el.id ] || cfg[ 'defaults' ] || {};

      options.cookies = this.callbacks.cookies;

      new TabSwapper( el, options );
   }
} );

/* Description: Class for creating nice tips that follow the mouse cursor
                when hovering an element.
   License: MIT-style license
   Authors: Valerio Proietti, Christoph Pojer, Luis Merino, Peter Flanigan */

(function() {

var getText = function( el ) {
   return (el.get( 'rel' ) || el.get( 'href' ) || '').replace( 'http://', '' );
};

var read = function( opt, el ) {
   return opt ? (typeOf( opt ) == 'function' ? opt( el ) : el.get( opt )) : '';
};

var storeTitleAndText = function( opt, el ) {
   if (el.retrieve( 'tip:title' )) return;

   var title = read( opt.title, el ), text = read( opt.text, el );

   if (title) {
      el.store( 'tip:native', title ); var pair = title.split( opt.separator );

      if (pair.length > 1) {
         title = pair[ 0 ].trim(); text = (pair[ 1 ] + ' ' + text).trim();
      }
   }
   else title = opt.hellip;

   if (title.length > opt.maxTitleChars)
      title = title.substr( 0, opt.maxTitleChars - 1 ) + opt.hellip;

   el.store( 'tip:title', title ).erase( 'title' );
   el.store( 'tip:text',  text  );
};

this.Tips = new Class( {
   Implements: [ Events, Options ],

   options         : {
      className    : 'tips',
      fixed        : false,
      fsWidthRatio : 1.35,
      hellip       : '\u2026',
      hideDelay    : 100,
      id           : 'tips',
      maxTitleChars: 40,
      maxWidthRatio: 4,
      minWidth     : 120,
      offsets      : { x: 4, y: 36 },
/*    onAttach     : function( el ) {}, */
/*    onBound      : function( coords ) {}, */
/*    onDetach     : function( el) {}, */
      onHide       : function( tip, el ) {
         tip.setStyle( 'visibility', 'hidden'  ) },
      onShow       : function( tip, el ) {
         tip.setStyle( 'visibility', 'visible' ) },
      selector     : '.tips',
      separator    : '~',
      showDelay    : 100,
      showMark     : true,
      spacer       : '\u00a0\u00a0\u00a0',
      text         : getText,
      timeout      : 30000,
      title        : 'title',
      windowPadding: { x: 0, y: 0 }
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.createMarkup();

      this.build(); this.fireEvent( 'initialize' );
   },

   attach: function( el ) {
      var events = [ 'enter', 'leave' ], opt = this.options;

      storeTitleAndText( opt, el );

      if (! opt.fixed) events.push( 'move' );

      events.each( function( value ) {
         var key = 'tip:' + value, method = 'element' + value.capitalize();

         var handler; if (! (handler = el.retrieve( key ))) {
            handler = function( ev ) {
               return this[ method ].apply( this, [ ev, el ] ) }.bind( this );
            el.store( key, handler );
         }

         el.addEvent( 'mouse' + value, handler );
      }, this );

      this.fireEvent( 'attach', [ el ] );
   },

   createMarkup: function() {
      var opt    = this.options;
      var klass  = opt.className;
      var dlist  = this.tip = new Element( 'dl', {
         'id'    : opt.id,
         'class' : klass + '-container',
         'styles': { 'left'      : 0,
                     'position'  : 'absolute',
                     'top'       : 0,
                     'visibility': 'hidden' } } ).inject( document.body );

      if (opt.showMark) {
         this.mark = []; [ 0, 1 ].each( function( idx ) {
            var el = this.mark[ idx ] = new Element( 'span', {
               'class': klass + '-mark' + idx } ).inject( dlist );

            [ 'left', 'top' ].each( function( prop ) {
               el.store( 'tip:orig-' + prop, el.getStyle( prop ) ) } );
         }, this );
      }

      this.term = new Element( 'dt', {
         'class' : klass + '-term' } ).inject( dlist );
      this.defn = new Element( 'dd', {
         'class' : klass + '-defn' } ).inject( dlist );
   },

   detach: function() {
      this.collection.each( function( el ) {
         [ 'enter', 'leave', 'move' ].each( function( value ) {
            var ev = 'mouse' + value, key = 'tip:' + value;

            el.removeEvent( ev, el.retrieve( key ) ).eliminate( key );
         } );

         this.fireEvent( 'detach', [ el ] );

         if (this.options.title == 'title') {
            var original = el.retrieve( 'tip:native' );

            if (original) el.set( 'title', original );
         }
      }, this );

      return this;
   },

   elementEnter: function( ev, el ) {
      clearTimeout( this.timer );
      this.timer = this.show.delay( this.options.showDelay, this, el );
      this.setup( el ); this.position( ev, el );
   },

   elementLeave: function( ev, el ) {
      clearTimeout( this.timer );

      var opt = this.options, delay = Math.max( opt.showDelay, opt.hideDelay );

      this.timer = this.hide.delay( delay, this, el );
      this.fireForParent( ev, el );
   },

   elementMove: function( ev, el ) {
      this.position( ev, el );
   },

   fireForParent: function( ev, el ) {
      el = el.getParent(); if (! el || el == document.body) return;

      if (el.retrieve( 'tip:enter' )) el.fireEvent( 'mouseenter', ev );
      else this.fireForParent( ev, el );
   },

   hide: function( el ) {
      this.fireEvent( 'hide', [ this.tip, el ] );
   },

   position: function( ev, el ) {
      var opt    = this.options;
      var bounds = opt.fixed ? this._positionFixed( ev, el )
                             : this._positionVariable( ev, el );

      if (opt.showMark) this._positionMarks( bounds );
   },

   _positionFixed: function( ev, el ) {
      var offsets = this.options.offsets, pos = el.getPosition();

      this.tip.setStyles( { left: pos.x + offsets.x, top: pos.y + offsets.y } );

      return { x: false, x2: false, y: false, y2: false };
   },

   _positionMark: function( state, quads, coord, dimn ) {
      for (var idx = 0; idx < 2; idx++) {
         var el     = this.mark[ idx ];
         var colour = el.getStyle( 'border-' + quads[ 0 ] + '-color' );

         if (colour != 'transparent') {
            el.setStyle( 'border-' + quads[ 0 ] + '-color', 'transparent' );
            el.setStyle( 'border-' + quads[ 1 ] + '-color', colour );
         }

         var orig  = el.retrieve( 'tip:orig-' + coord ).toInt();
         var value = this.tip.getStyle( dimn ).toInt();

         if (coord == 'left') {
            var blsize = this.tip.getStyle( 'border-left' ).toInt();
            var left   = this.mark[ 0 ].retrieve( 'tip:orig-left' ).toInt();

            value -= 2 * left - blsize * idx;
         }

         el.setStyle( coord, (state ? value : orig) + 'px' );
      }
   },

   _positionMarks: function( coords ) {
      var quads = coords[ 'x2' ] ? [ 'left', 'right' ] : [ 'right', 'left' ];

      this._positionMark( coords[ 'x2' ], quads, 'left', 'width' );

      quads = coords[ 'y2' ] ? [ 'bottom', 'top' ] : [ 'top', 'bottom' ];

      this._positionMark( coords[ 'y2' ], quads, 'top', 'height' );
   },

   _positionVariable: function( ev, el ) {
      var opt     = this.options, offsets = opt.offsets, pos = {};
      var prop    = { x: 'left',                 y: 'top'                 };
      var scroll  = { x: window.getScrollLeft(), y: window.getScrollTop() };
      var tip     = { x: this.tip.offsetWidth,   y: this.tip.offsetHeight };
      var win     = { x: window.getWidth(),      y: window.getHeight()    };
      var bounds  = { x: false, x2: false,       y: false, y2: false      };
      var padding = opt.windowPadding;

      for (var z in prop) {
         var coord = ev.page[ z ] + offsets[ z ];

         if (coord < 0) bounds[ z ] = true;

         if (coord + tip[ z ] > scroll[ z ] + win[ z ] - padding[ z ]) {
            coord = ev.page[ z ] - offsets[ z ] - tip[ z ];
            bounds[ z + '2' ] = true;
         }

         pos[ prop[ z ] ] = coord;
      }

      this.fireEvent( 'bound', bounds ); this.tip.setStyles( pos );

      return bounds;
   },

   setup: function( el ) {
      var opt    = this.options;
      var term   = el.retrieve( 'tip:title' ) || '';
      var defn   = el.retrieve( 'tip:text'  ) || '';
      var tfsize = this.term.getStyle( 'font-size' ).toInt();
      var dfsize = this.defn.getStyle( 'font-size' ).toInt();
      var max    = Math.floor( window.getWidth() / opt.maxWidthRatio );
      var w      = Math.max( term.length * tfsize / opt.fsWidthRatio,
                             defn.length * dfsize / opt.fsWidthRatio );

      w = parseInt( w < opt.minWidth ? opt.minWidth : w > max ? max : w );

      this.tip.setStyle( 'width', w + 'px' );
      this.term.empty().appendText( term || opt.spacer );
      this.defn.empty().appendText( defn || opt.spacer );
   },

   show: function( el ) {
      var opt = this.options;

      if (opt.timeout) this.timer = this.hide.delay( opt.timeout, this );

      this.fireEvent( 'show', [ this.tip, el ] );
   }
} );
} )();

var Togglers = new Class( {
   Implements: [ Options ],

   options: { config: {}, selector: '.togglers' },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();

      this.resize = this.callbacks.resize.bind( this.callbacks );
   },

   attach: function( el ) {
      var cfg; if (! (cfg = this.options.config[ el.id ])) return;

      el.addEvent( cfg.event || 'click', function( ev ) {
         new Event( ev ).stop(); this[ cfg.method ].apply( this, cfg.args );
      }.bind( this ) );
   },

   toggle: function( id, name ) {
      var el = $( id ); if (! el) return;

      var toggler = el.retrieve( name ); if (! toggler) return;

      toggler.toggle( this.callbacks.cookies ); this.resize();
   },

   toggleSwapText: function( id, name, s1, s2 ) {
      var el = $( id ); if (! el) return; var cookies = this.callbacks.cookies;

      if (cookies.get( name ) == 'true') {
         cookies.set( name, 'false' );

         if (el) el.set( 'html', s2 );

         if (el = $( name + 'Disp' )) el.hide();
      }
      else {
         cookies.set( name, 'true' );

         if (el) el.set( 'html', s1 );

         if (el = $( name + 'Disp' )) el.show();
      }

      this.resize();
   }
} );

var Trees = new Class( {
   Implements: [ Options ],

   options          : {
      classPrefix   : 'tree',
      cookieDomain  : '',
      cookiePath    : '/',
      cookiePrefix  : 'html_formwidgets',
      cookieSuffix  : 'tree',
      selector      : '.tree',
      usePersistance: true
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); var opt = this.options;

      if (opt.usePersistance) {
         var prefix = opt.cookiePrefix + '_' + opt.cookieSuffix;

         this.cookies = new Cookies( { domain: opt.cookieDomain,
                                       path  : opt.cookiePath,
                                       prefix: prefix } );
      }

      this.build();
   },

   attach: function( el, branch ) {
      if (! el || ! el.childNodes || el.childNodes.length == 0) return;

      if (! branch) this.attachControls( el.id );

      var dt, node;

      for (var i = 0, ecl = el.childNodes.length; i < ecl; i++) {
         if (! (node = $( el.childNodes[ i ] ))) continue;

         if (node.nodeName == 'DT') { dt = node; continue; }

         if (node.nodeName != 'DD') continue; var dd = node;

         this.setState( dt, dd, ! branch ); this.attachTogglers( dt, dd );

         for (var j = 0, ddcl = dd.childNodes.length; j < ddcl; j++) {
            if ((node = $( dd.childNodes[ j ] )) && node.nodeName == 'DL')
               this.attach( node, true );
         }
      }
   },

   attachControls: function( id ) {
      $( id + '_collapse_button' ).addEvent
         ( 'click', this.collapseTree.bind( this, id ) );
      $( id + '_expand_button' ).addEvent
         ( 'click', this.expandTree.bind( this, id ) );
   },

   attachToggler: function( dt, dd, klass, event ) {
      $$( '#' + dt.id + ' span.' + klass ).each( function( el ) {
         el.addEvent( event, function( ev ) {
            new Event( ev ).stop(); return this.toggle( dt, dd );
         }.bind( this ) );
      }, this );
   },

   attachTogglers: function( dt, dd ) {
      var prefix = this.options.classPrefix;

      this.attachToggler( dt, dd, prefix + '_node_ctrl', 'click'    );
      this.attachToggler( dt, dd, prefix + '_node_icon', 'dblclick' );
   },

   close: function( dt, dd ) {
      var prefix = this.options.classPrefix;

      if (dt.hasClass( prefix + '_node_open' )) {
         dt.swapClass( prefix + '_node_open', prefix + '_node_closed' );
         dd.swapClass( prefix + '_node_open', prefix + '_node_closed' );
      }
      else if (dt.hasClass( prefix + '_node_last_open' )) {
         dt.swapClass( prefix + '_node_last_open',
                       prefix + '_node_last_closed' );
         dd.swapClass( prefix + '_node_last_open',
                       prefix + '_node_last_closed' );
      }

      if (this.options.usePersistance) this.cookies.set( dt.id, '0' );
   },

   collapseTree: function( treeId ) {
      var list = $( treeId );

      return list == null ? false : this.expandCollapseList( list, 'close' );
   },

   expandCollapseList: function( el, dirn, itemId ) {
      if (! el || ! el.childNodes || el.childNodes.length == 0) return false;

      var dt, node;

      for (var i = 0, ecl = el.childNodes.length; i < ecl; i++) {
         if (! (node = $( el.childNodes[ i ] ))) continue;

         if (itemId != null && itemId == node.id) return true;

         if (node.nodeName == 'DT') { dt = node; continue; }

         if (node.nodeName != 'DD') continue; var dd = node;

         for (var j = 0, ddcl = dd.childNodes.length; j < ddcl; j++) {
            if ((node = $( dd.childNodes[ j ] )) && node.nodeName == 'DL') {
               var ret = this.expandCollapseList( node, dirn, itemId );

               if (itemId != null && ret) {
                  if (dirn == 'close') this.close( dt, dd );
                  else this.open( dt, dd );

                  return true;
               }
            }
         }

         if (itemId == null) {
            if (dirn == 'close') this.close( dt, dd );
            else this.open( dt, dd );
         }
      }

      return false;
   },

   expandToItem: function( treeId, itemId ) {
      var list = $( treeId ), o, ret;

      if (list == null) return false;

      if (ret = this.expandCollapseList( list, 'open', itemId )) {
         if (o = $( itemId ) && o.scrollIntoView) o.scrollIntoView( false );
      }

      return ret;
   },

   expandTree: function( treeId ) {
      var list = $( treeId );

      return list == null ? false : this.expandCollapseList( list, 'open' );
   },

   open: function( dt, dd ) {
      var prefix = this.options.classPrefix;

      if (dt.hasClass( prefix + '_node_closed' )) {
         dt.swapClass( prefix + '_node_closed', prefix + '_node_open' );
         dd.swapClass( prefix + '_node_closed', prefix + '_node_open' );
      }
      else if (dt.hasClass( prefix + '_node_last_closed' )) {
         dt.swapClass( prefix + '_node_last_closed',
                       prefix + '_node_last_open' );
         dd.swapClass( prefix + '_node_last_closed',
                       prefix + '_node_last_open' );
      }

      if (this.options.usePersistance) this.cookies.set( dt.id, '1' );
   },

   setState: function( dt, dd, state ) {
      if (this.options.usePersistance) {
         this.cookies.get( dt.id ) == '1'
            ? this.open( dt, dd ) : this.close( dt, dd );
      }
      else {
         if (state) this.open( dt, dd );
         else this.close( dt, dd );
      }
   },

   toggle: function( dt, dd ) {
      var prefix = this.options.classPrefix;

      if (dt.hasClass( prefix + '_node_last_open' )
          || dt.hasClass( prefix + '_node_last_closed' )) {
         dt.toggleClass( prefix + '_node_last_open'   );
         dt.toggleClass( prefix + '_node_last_closed' );
         dd.toggleClass( prefix + '_node_last_open'   );
         dd.toggleClass( prefix + '_node_last_closed' );
      }
      else {
         dt.toggleClass( prefix + '_node_open'   );
         dt.toggleClass( prefix + '_node_closed' );
         dd.toggleClass( prefix + '_node_open'   );
         dd.toggleClass( prefix + '_node_closed' );
      }

      if (this.options.usePersistance) {
         if (dt.hasClass( prefix + '_node_open' )
             || dt.hasClass( prefix + '_node_last_open' ))
            this.cookies.set( dt.id, '1' );
         else this.cookies.set( dt.id, '0' );
      }

      return false;
   }
} );

var WindowUtils = new Class( {
   Implements: [ Options ],

   options        : {
      config      : {},
      cookieDomain: null,
      cookieName  : 'session',
      cookiePath  : '/',
      cookiePrefix: null,
      customLogFn : false,
      quiet       : false,
      selector    : '.windows',
      target      : null,
      windowHeight: 600,
      windowWidth : 800
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); var opt = this.options;

      if (opt.customLogFn) {
         if (typeOf( opt.customLogFn ) != 'function')
            throw 'customLogFn is not a function';
         else this.customLogFn = opt.customLogFn;
      }

      if (opt.target == 'top') this.placeOnTop();

      this.build();
   },

   attach: function( el ) {
      var cfg; if (! (cfg = this.options.config[ el.id ])) return;

      el.addEvent( cfg.event || 'click', function( ev ) {
         new Event( ev ).stop();
         return this[ cfg.method ].apply( this, cfg.args );
      }.bind( this ) );
   },

   log: function( message ) {
      if (this.options.quiet) return;

      message = 'html-formwidgets.js: ' + message;

      if (this.customLogFn) { this.customLogFn( message ) }
      else if (window.console && window.console.log) {
         window.console.log( message );
      }
   },

   openWindow: function( href, options ) {
      var opt = this.options;

      options.height = options.height || opt.windowHeight;
      options.width  = options.width  || opt.windowWidth;

      new Browser.Popup( href, options );
   },

   placeOnTop: function() {
      if (self != top) {
         if (document.images) top.location.replace( window.location.href );
         else top.location.href = window.location.href;
      }
   },

   wayOut: function( href ) {
      var copt, name, opt = this.options;

      name = (opt.cookiePrefix ? opt.cookiePrefix + '_' : '') + opt.cookieName;

      new Cookie( name, { path: opt.cookiePath } ).dispose();

      if (document.images) top.location.replace( href );
      else top.location.href = href;
   }
} );

/* Author  : luistar15, <leo020588 [at] gmail.com>
 * Class   : wysiwyg (rev.06-07-08)
 * License : MIT License */

var WYSIWYG = new Class( {
   Implements: [ Events, Options ],

   options             : {
      barNum           : 4,
      buttonWidth      : 24,
      buttons          : {
         anchor        : [  20, 'Anchor', 'anchor', 'Enter anchor id', '#' ],
         bigger        : [  72, 'Increase Font Size', 'increasefontsize',
                                null ],
         blockquote    : [  19, 'Blockquote', 'formatblock', '<BLOCKQUOTE>' ],
         bold          : [  30, 'Bold', 'bold', null ],
         clear         : [   0, 'Clear', 'selectall+delete', null ],
         copy          : [   3, 'Copy to Clipboard', 'copy', null ],
         cut           : [   4, 'Cut to Clipboard', 'cut', null ],
         div           : [  56, 'Div Element', 'formatblock', '<DIV>' ],
         elfinder      : [ 129, 'Find Element', 'elfinder',
                                'Enter element selector', '' ],
         flash         : [   9, 'Shockwave Flash', 'flash' ],
         forecolor     : [  50, 'Text Colour', 'forecolor',
                                'Enter text colour', '#' ],
         fullscreen    : [  21, 'Full Screen', 'fullscreen' ],
         h1            : [  67, 'Header Level 1', 'formatblock', '<H1>' ],
         h2            : [  68, 'Header Level 2', 'formatblock', '<H2>' ],
         h3            : [  69, 'Header Level 3', 'formatblock', '<H3>' ],
         hilitecolor   : [  51, 'Highlight Colour', 'hilitecolor',
                                'Enter highlight colour', '#' ],
         horizontalrule: [  18, 'Horizontal Rule', 'inserthorizontalrule',
                                null ],
         image         : [   8, 'Image', 'insertimage',
                                'Enter the image URL:', 'http://' ],
         indent        : [  11, 'Indent', 'indent', null ],
         italic        : [  33, 'Italic', 'italic', null ],
         justifycenter : [  36, 'Justify Centre', 'justifycenter', null ],
         justifyfull   : [  17, 'Justify Full', 'justifyfull', null ],
         justifyleft   : [  35, 'Justify Left', 'justifyleft', null ],
         justifyright  : [  37, 'Justify Right', 'justifyright', null ],
         link          : [  31, 'Link', 'createlink', 'Enter the URL:',
                                'http://' ],
         nbsp          : [  53, 'Non Breaking Space', 'nbsp', null ],
         nexttoolbar   : [  74, 'Next Toolbar', 'nexttoolbar' ],
         orderedlist   : [  15, 'Ordered List', 'insertorderedlist', null ],
         outdent       : [  10, 'Outdent', 'outdent', null ],
         paragraph     : [  70, 'Paragraph', 'formatblock', '<P>' ],
         paste         : [   5, 'Paste from Clipboard', 'paste', null ],
         preformatted  : [  17, 'Preformatted Text', 'formatblock', '<PRE>' ],
         redo          : [  39, 'Redo Previous Action', 'redo', null ],
         removeformat  : [   7, 'Remove Format', 'removeformat', null ],
         smaller       : [  71, 'Decrease Font Size', 'decreasefontsize',
                                null ],
         strikethrough : [  16, 'Strikethrough', 'strikethrough', null ],
         subscript     : [  12, 'Subscript', 'subscript', null ],
         superscript   : [  13, 'Superscript', 'superscript', null ],
         table         : [  23, 'Insert Table', 'table' ],
         tableprops    : [  44, 'Table Properties', 'tableprops' ],
         tablerm       : [  28, 'Remove Table', 'tablerm' ],
         tbrowbefore   : [  48, 'Insert Row Before', 'tbrowbefore' ],
         tbrowafter    : [  47, 'Insert Row After', 'tbrowafter' ],
         tbrowrm       : [  26, 'Remove Row', 'tbrowrm' ],
         tbcolbefore   : [  59, 'Insert Column Before', 'tbcolbefore' ],
         tbcolafter    : [  63, 'Insert Column After', 'tbcolafter' ],
         tbcolrm       : [  29, 'Remove Column', 'tbcolrm' ],
         tbcellprops   : [  64, 'Cell Properties', 'tbcellprops' ],
         tbcellsmerge  : [  40, 'Merge Cells', 'tbcellsmerge' ],
         tbcellsplit   : [  55, 'Split Cell', 'tbcellsplit' ],
         toggle        : [  66, 'Toggle View', 'toggleview' ],
         underline     : [  34, 'Underline', 'underline', null ],
         undo          : [  38, 'Undo Last Action', 'undo', null ],
         unlink        : [  32, 'Unlink', 'unlink', null ],
         unorderedlist : [  14, 'Unordered List', 'insertunorderedlist', null ]
      },
      container     : 'content',
      defaultBody   : '\u00a0',
      defaultClass  : 'wysiwyg_container',
      defaultState  : true,
      iconGridSize  : 30,
      iconsPerRow   : 10,
      iframeMargin  : 80,
      iframePadding : 14,
      minWidth      : 600,
      panels        : {
         alignment  : [ 'justifyleft', 'justifycenter',
                        'justifyright', 'justifyfull' ],
         control    : [ 'toggle', 'clear', 'nexttoolbar' ],
         edit1      : [ 'undo', 'redo' ],
         edit2      : [ 'undo', 'redo', 'copy', 'cut', 'paste', 'pastetext',
                        'pasteformattext', 'removeformat' ],
         edit3      : [ 'undo', 'redo', 'copy', 'cut', 'paste', 'pastetext',
                        'pasteformattext', 'removeformat', 'elfinder' ],
         elements   : [ 'horizontalrule', 'nbsp' ],
         fonts      : [ 'bigger', 'smaller', 'forecolor' ],
         format     : [ 'h1', 'h2', 'h3', 'paragraph',
                        'preformatted', 'div', 'blockquote' ],
         images     : [ 'image' ],
         indent     : [ 'outdent', 'indent' ],
         links      : [ 'link', 'unlink', 'anchor' ],
         lists      : [ 'orderedlist', 'unorderedlist' ],
         media      : [ 'image', 'flash' ],
         style      : [ 'bold', 'italic', 'underline', 'strikethrough',
                        'subscript', 'superscript' ],
         tables     : [ 'table', 'tableprops', 'tablerm',  'tbrowbefore',
                        'tbrowafter', 'tbrowrm', 'tbcolbefore', 'tbcolafter',
                        'tbcolrm', 'tbcellprops', 'tbcellsmerge',
                        'tbcellsplit' ],
         view       : [ 'hilitecolor', 'fullscreen' ]
      },
      selector      : '.wysiwyg',
      spacerWidth   : 10,
      toolbars      : [
         [ 'control', 'style' ],
         [ 'control', 'style', 'alignment', 'lists', 'links' ],
         [ 'control', 'style', 'format', 'fonts', 'alignment',
           'indent', 'lists', 'links', 'elements', 'images' ],
         [ 'control', 'edit1',
           'style', 'format', null, 'fonts', 'alignment',
          'indent', 'lists', 'links', 'elements', 'images' ],
         [ 'control', 'edit2', 'view',
           'style', 'format', null, 'fonts', 'alignment',
           'indent', 'lists', 'links', 'elements', 'images' ],
         [ 'control', 'edit3', 'view',
           'style', 'format', null, 'fonts', 'alignment',
           'indent', 'lists', 'links', 'elements', 'media', null, 'tables' ]
      ]
   },

   initialize: function( options ) {
      this.setBuildOptions( options ); this.build();
   },

   attach: function( el ) {
      var opt   = this.options,
         editor = {
         element: el,
         height : -1,
         barNum : opt.barNum,
         open   : ! opt.defaultState,
         toolbar: new Element( 'span',   { class: 'toolbar' } ),
         iframe : new Element( 'iframe', { frameborder: 0, src: 'about:blank' })
      };

      this.loader = function( self, editor ) {
         return function() {
            editor.iframe.removeEvent( 'load', this.loader );
            editor.doc = editor.iframe.contentWindow.document;
            this.initialiseBody( editor, editor.element.value );
            editor.doc.designMode = 'on';
            return this.toggleView( editor );
         }.bind( self );
      }( this, editor );

      editor.iframe.addEvent( 'load', this.loader );

      new Element( 'div', {
         class: opt.defaultClass
      } ).inject( el, 'before' ).adopt( editor.toolbar, editor.iframe, el );

      this.initialiseToolbar( editor );

      window.addEvent( 'submit', function() {
         if (editor.open) this.toTextarea( editor );
      }.bind( this ) );

      el.editor = editor;
   },

   addButton: function( editor, b ) {
      var but = this.options.buttons[ b ]; if (! but) return false;
      var el  = Browser.ie
              ? new Element( 'a', { class: b, href: '//' + b, title: but[ 1 ] })
              : new Element( 'span', { class: b, title: but[ 1 ] } );

      if (b != 'toggle') this.setIcon( el, but[ 0 ] );

      var handler = function( self, editor, b ) {
         return function( ev ) {
            new Event( ev ).stop();

            return b == 'toggle' ? this.toggleView( editor, true )
                                 : this.exec( editor, b );
         }.bind( self );
      }( this, editor, b );

      el.addEvent( 'click', handler ).inject( editor.toolbar );
      return true;
   },

   clean: function( html ) {
      return html
         .replace( /<[^> ]*/g, function( s ) { return s.toLowerCase() } )
         .replace( /<[^>]*>/g, function( s ) {
               s = s.replace( / [^=]+=/g, function( a ) {
                     return a.toLowerCase() } ); return s } )
         .replace( /<[^>]*>/g, function( s ) {
               s = s.replace( /( [^=]+=)([^\"][^ >]*)/g, '$1\"$2\"' );
               return s } )
         .replace( /(<[^>]+) array="[^\"]*"([^>]*>)/g, '$1$2' )
         .replace( /<span style="font-weight: normal;">(.+?)<\/span>/gm, '$1' )
         .replace( /<span style="font-weight: bold;">(.+?)<\/span>/gm,
                   '<strong>$1</strong>' )
         .replace( /<span style="font-style: italic;">(.+?)<\/span>/gm,
                   '<em>$1</em>' )
         .replace( /<span style="(font-weight: bold; ?|font-style: italic; ?){2}">(.+?)<\/span>/gm,
                   '<strong><em>$2</em></strong>' )
         .replace( /<b(\s+|>)/g, '<strong$1' )
         .replace( /<\/b(\s+|>)/g, '</strong$1' )
         .replace( /<i(\s+|>)/g, '<em$1' )
         .replace( /<\/i(\s+|>)/g, '</em$1' )
         .replace( /<u>(.+?)<\/u>/gm,
                   '<span style="text-decoration: underline;">$1</span>' )
         .replace( /<img src="([^\">]*)">/g, '<img alt="Image" src="$1" />' )
         .replace( /(<img [^>]+[^\/])>/g, '$1 />' )
         .replace( /(<[^>]+)\s+>/g, '$1>' )
         .replace( /<br>\s*<\//g, '</' )
         .replace( /^&nbsp\;/g, ' ' )
         .replace( /&nbsp\;$/g, ' ' )
         .replace( /^\s+|\s+$/g, '' );
      /*
         .replace( /<(br|hr)>/g, '<$1 />' )
         .replace(/\s{2,}/g,' ')
         .replace(/<[^>]*>/g,function(s){s=s.replace(/ ([^=]+)="[^\"]*"/g,function(a,b){if(b=='alt'||b=='class'||b=='href'||b=='id'||b=='name'||b=='src'||b=='style'||b=='title'){return a}return''});return s})
         .replace(/<font[^>]*?>(.+?)<\/font>/gm,'$1')
         .replace(/<font>|<\/font>/gm,'')
         .replace(/<(table|tbody|tr|td|th)[^>]*>/g,'<$1>')
         .replace(/<\?xml[^>]*>/g,'')
         .replace(/<[^ >]+:[^>]*>/g,'')
         .replace(/<\/[^ >]+:[^>]*>/g,'')
         .replace(/(<br(\s+\/)?>)([^\n]|[^\r])/g,"$1\r\n$3")
         .replace(/<br(\s+\/)?>$/g, '')
         .replace(/(<[^\/]>|<[^\/][^>]*[^\/]>)\s*<\/[^>]*>/g,'')
      */
   },

   exec: function( editor, b, v ) {
      if (! editor.open) return;

      editor.iframe.contentWindow.focus();

      var but = this.options.buttons[ b ],
          doc = editor.doc,
          val = v || but[ 3 ];

      if (! v && ( but[ 4 ] != undefined)
          && ! (val = prompt( but[ 3 ], but[ 4 ] ))) return;

      switch (b) {
      case 'anchor':
         var html = '<a id="' + val + '" title="Bookmark: ' + val + '"> </a>';

         return doc.execCommand( 'inserthtml', false, html );
      case 'fullscreen':
         return this.fullscreen( editor );
      case 'nbsp':
         return doc.execCommand( 'inserthtml', false, '\u00a0' );
      case 'nexttoolbar':
         return this.nextToolBar( editor );
      default:
         var cmds = but[ 2 ].split( '+' );

         for (var i = 0, l = cmds.length; i < l; i++) {
            doc.execCommand( cmds[ i ], false, val );
         }
      }

      if (b == 'clear') this.initialiseBody( editor );

      return false;
   },

   fullscreen: function( editor ) {
      var height, width, iframe = editor.iframe,
          toolbar = editor.toolbar, opt = this.options;

      if (editor.height == -1) {
         var container = $( opt.container );

         editor.width  = iframe.getWidth();
         editor.height = iframe.getHeight();
         width         = container.getWidth()  - opt.iframeMargin;
         height        = container.getHeight() - opt.iframeMargin
                         - toolbar.getHeight();
      }
      else { width = editor.width; height = editor.height; editor.height = -1; }

      toolbar.setStyle( 'width', (width  + opt.iframePadding) + 'px' );
      iframe.setStyle(  'width',  width  + 'px' );
      iframe.setStyle(  'height', height + 'px' );
   },

   initialiseBody: function( editor, html ) {
      html = html && html.length > 0
           ? html.replace( /&nbsp;/g, '\u00a0' ) : this.options.defaultBody;
//      $( editor.doc.body ).set( 'html', html );
       editor.doc.body.innerHTML = html;
   },

   initialiseToolbar: function( editor ) {
      var opt      = this.options,
          panels   = opt.toolbars[ editor.barNum ],
          barWidth = 0,
          rowWidth = 0;

      editor.toolbar.empty();

      panels.each( function( p, index ) {
         if (! p) {
            new Element( 'br' ).inject( editor.toolbar ); rowWidth = 0; return;
         }

         var found = false;

         opt.panels[ p ].each( function( b ) {
            var added = this.addButton( editor, b );

            if (added) rowWidth += opt.buttonWidth;

            found = found || added;
         }, this );

         if (found && ( panels[ index + 1 ] != undefined)) {
            new Element( 'span', { class: 'spacer' } ).inject( editor.toolbar );

            rowWidth += opt.spacerWidth;
         }

         barWidth = Math.max( barWidth, rowWidth );
      }, this );

      barWidth = Math.max( opt.minWidth, barWidth );
      editor.toolbar.setStyle( 'width', barWidth + 'px' );
      editor.iframe.setStyle( 'width', (barWidth - opt.iframePadding) + 'px' );
   },

   nextToolBar: function( editor ) {
      editor.barNum += 1;

      if (editor.barNum > this.options.toolbars.length - 1) editor.barNum = 0;

      this.initialiseToolbar( editor );
   },

   setIcon: function( el, butNum ) {
      var opt = this.options,
          x   = 0 - opt.iconGridSize * (butNum % opt.iconsPerRow),
          y   = 0 - opt.iconGridSize * Math.floor( butNum / opt.iconsPerRow );

      el.setStyle( 'background-position', x + 'px ' + y + 'px' );
   },

   toEditor: function( editor, view ) {
      var html = editor.element.value.trim() || '';

      this.initialiseBody( editor, html );

      if (view) {
         editor.element.addClass( 'hidden' );
         editor.iframe.removeClass( 'hidden' );
         editor.toolbar.removeClass( 'disabled' );
      }
   },

   toggleView: function( editor, focus ) {
      if (editor.doc.body) {
         editor.open = ! editor.open;

         if (editor.open) this.toEditor( editor, true );
         else this.toTextarea( editor, true );

              if (focus &&   editor.open) editor.iframe.contentWindow.focus();
         else if (focus && ! editor.open) editor.element.focus();
      }

      return false;
   },

   toTextarea: function( editor, view ) {
      var doc; if (! (doc = editor.doc)) return;

      editor.element.value = this.clean( doc.body.innerHTML.unescapeHTML() );

      if (view) {
         editor.element.removeClass( 'hidden' );
         editor.iframe.addClass( 'hidden' );
         editor.toolbar.addClass( 'disabled' );
      }
   }
} );

function Expand_Collapse() {}

/* Local Variables:
 * mode: javascript
 * tab-width: 3
 * End:
 */
