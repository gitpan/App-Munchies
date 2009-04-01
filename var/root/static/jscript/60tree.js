/* @(#)$Id: 60tree.js 633 2009-03-31 12:16:38Z pjf $ */

/* Originally Cross Browser Tree Widget 1.17
 * Created by Emil A Eklund (http://webfx.eae.net/contact.html#emil)
 * Copyright (c) 1999 - 2002 Emil A Eklund */

var Tree = {};

Tree.Config = new Abstract({
	rootIcon        : behaviour.baseURL + 'static/images/foldericon.png',
	openRootIcon    : behaviour.baseURL + 'static/images/openfoldericon.png',
	folderIcon      : behaviour.baseURL + 'static/images/foldericon.png',
	openFolderIcon  : behaviour.baseURL + 'static/images/openfoldericon.png',
	fileIcon        : behaviour.baseURL + 'static/images/file.png',
	iIcon           : behaviour.baseURL + 'static/images/I.png',
	lIcon           : behaviour.baseURL + 'static/images/L.png',
	lMinusIcon      : behaviour.baseURL + 'static/images/Lminus.png',
	lPlusIcon       : behaviour.baseURL + 'static/images/Lplus.png',
	tIcon           : behaviour.baseURL + 'static/images/T.png',
	tMinusIcon      : behaviour.baseURL + 'static/images/Tminus.png',
	tPlusIcon       : behaviour.baseURL + 'static/images/Tplus.png',
	blankIcon       : behaviour.baseURL + 'static/images/blank.png',
   selectedIcon    : behaviour.baseURL + 'static/images/current.png',
	defaultText     : 'Tree Leaf',
	defaultAction   : 'javascript:void(0);',
	defaultBehavior : 'classic',
	usePersistence	 : true
});

Tree.Handler = new Abstract({
	idCounter : 0,
	idPrefix  : 'tree_node_',
	all       : {},
	behavior  : null,
	selected  : null,
	onSelect  : null, /* should be part of tree, not handler */

	getId     : function() { return this.idPrefix + this.idCounter++; },

	toggle    : function( el ) {
      this.all[ el.id.replace( '-plus', '' ) ].toggle();
   },

	select    : function( el ) {
      this.all[ el.id.replace( '-icon', '' ) ].select();
   },

	focus     : function( el ) {
      this.all[ el.id.replace( '-anchor', '' ) ].focus();
   },

	blur      : function( el ) {
      this.all[ el.id.replace( '-anchor', '' ) ].blur();
   },

	keydown   : function( el, event ) {
      return this.all[ el.id ].keydown( event.keyCode );
   },

	insertHTMLBeforeEnd: function( el, html ) {
		if (el.insertAdjacentHTML != null) {
			el.insertAdjacentHTML( "BeforeEnd", html )
			return;
		}

		var r = el.ownerDocument.createRange();
		r.selectNodeContents( el );
		r.collapse( false );
		var df = r.createContextualFragment( html );
		el.appendChild( df );
	},
});

Tree.AbstractNode = new Class({
   initialize: function( text, action, tip ) {
      this._last      = false;
      this.childNodes = [];
      this.config     = Tree.Config;
      this.handler    = Tree.Handler;
      this.cookies    = new Cookies( { path  : behaviour.sessionPath,
                                       prefix: behaviour.sessionPrefix } );
      this.selected   = false;

      this.action     = action || this.config.defaultAction;
      this.text       = text   || this.config.defaultText;
      this.tip        = tip    || '';
      this.id         = this.handler.getId();

      this.handler.all[ this.id ] = this;
   },

   add: function( node, bNoIdent ) {
      node.parentNode = this;
      this.childNodes[ this.childNodes.length ] = node;
      var prev = this.childNodes[ this.childNodes.length - 2 ];

      if (this.childNodes.length >= 2) prev._last = false;

      var root = this; while (root.parentNode) { root = root.parentNode; }

      if (root.rendered) {
         if (this.childNodes.length >= 2) {
            $( prev.id + '-plus' ).src
               = (prev.folder ? (prev.open ? this.config.tMinusIcon
                                           : this.config.tPlusIcon)
                                           : this.config.tIcon);
            prev.plusIcon  = this.config.tPlusIcon;
            prev.minusIcon = this.config.tMinusIcon;
            prev._last     = false;
         }

         this._last = true; var foo = this;

         while (foo.parentNode) {
            for (var i = 0; i < foo.parentNode.childNodes.length; i++) {
               if (foo.id == foo.parentNode.childNodes[ i ].id) { break; }
            }

            if (i == foo.parentNode.childNodes.length - 1) {
               foo.parentNode._last = true;
            }
            else { foo.parentNode._last = false; }

            foo = foo.parentNode;
         }

         this.handler.insertHTMLBeforeEnd
            ( $( this.id + '-cont' ), node.toString() );

         if (!this.folder && !this.openIcon) {
            this.icon     = this.config.folderIcon;
            this.openIcon = this.config.openFolderIcon;
         }

         if (!this.folder) { this.folder = true; this.collapse( true ); }
         if (!bNoIdent)    { this.indent(); }
      }

      return node;
   },

   toggle: function() {
      if (this.folder) {
         if (this.open) this.collapse();
         else this.expand();
      }
	},

   select: function() { $( this.id + '-anchor' ).focus(); },

   deSelect: function() {
      $( this.id + '-anchor' ).className = 'treeFade';
      this.handler.selected = null;
   },

   focus: function() {
      if (this.handler.selected && (this.handler.selected != this)) {
         this.handler.selected.deSelect();
      }

      this.handler.selected = this;

      if (this.openIcon && (this.handler.behavior != 'classic')) {
         $( this.id + '-icon' ).src = this.selected
                                    ? this.config.selectedIcon : this.openIcon;
      }

      $( this.id + '-anchor' ).className = 'treeFade selected';
      $( this.id + '-anchor' ).focus();

      if (this.handler.onSelect) this.handler.onSelect( this );
   },

   blur: function() {
      if (this.openIcon && (this.handler.behavior != 'classic')) {
         $( this.id + '-icon' ).src = this.selected
                                    ? this.config.selectedIcon : this.icon;
      }

      $( this.id + '-anchor' ).className = 'treeFade selected-inactive';
   },

   doExpand: function() {
      if (this.handler.behavior == 'classic') {
         $( this.id + '-icon' ).src = this.selected
                                    ? this.config.selectedIcon : this.openIcon;
      }

      if (this.childNodes.length) {
         $( this.id + '-cont' ).style.display = 'block';
      }

      this.open = true;

      if (this.config.usePersistence) this.cookies.set( this.id, '1' );
   },

   doCollapse: function() {
      if (this.handler.behavior == 'classic') {
         $( this.id + '-icon' ).src = this.selected
                                    ? this.config.selectedIcon : this.icon;
      }

      if (this.childNodes.length) {
         $( this.id + '-cont' ).style.display = 'none';
      }

      this.open = false;

      if (this.config.usePersistence) this.cookies.set( this.id, '0' );
	},

   expandAll: function() {
      this.expandChildren();

      if (this.folder && !this.open) this.expand();
   },

   expandChildren: function() {
      for (var i = 0; i < this.childNodes.length; i++) {
         this.childNodes[ i ].expandAll();
      }
   },

   collapseAll: function() {
      this.collapseChildren();

      if (this.folder && this.open) this.collapse( true );
   },

   collapseChildren: function() {
      for (var i = 0; i < this.childNodes.length; i++) {
         this.childNodes[ i ].collapseAll();
      }
   },

   indent: function( lvl, del, last, level, nodesLeft ) {
      /*
       * Since we only want to modify items one level below ourself,
       * and since the rightmost indentation position is occupied by
       * the plus icon we set this to -2
       */
      var state = 0;

      if (lvl == null) lvl = -2;

      for (var i = this.childNodes.length - 1; i >= 0 ; i--) {
         state = this.childNodes[ i ].indent( lvl + 1, del, last, level );

         if (state) return;
      }

      if (del) {
         if ((level >= this._level) && $(this.id + '-plus' )) {
            if (this.folder) {
               $( this.id + '-plus' ).src
                  = this.open ? this.config.lMinusIcon : this.config.lPlusIcon;
               this.plusIcon  = this.config.lPlusIcon;
               this.minusIcon = this.config.lMinusIcon;
            }
            else {
               if (nodesLeft) $( this.id + '-plus' ).src = this.config.lIcon;
            }

            return 1;
         }
      }

      var foo = $( this.id + '-indent-' + lvl );

      if (foo) {
         if (foo._last || (del && last)) { foo.src = this.config.blankIcon; }
         else { foo.src = this.config.iIcon; }
      }

      return 0;
   },
});

Tree.Trunk = Tree.AbstractNode.extend({
   initialize: function( text, action, tip, behavior, icon, openIcon ) {
      this.parent( text, action, tip );

      this.icon     = icon     || this.config.rootIcon;
      this.openIcon = openIcon || this.config.openRootIcon;

      if (this.config.usePersistence) {
         this.open = (this.cookies.get( this.id ) == '0') ? false : true;
      }
      else { this.open = true; }

      this.folder   = true;
      this.rendered = false;
      this.onSelect = null;

      if (!this.handler.behavior) {
         this.handler.behavior = behavior || this.config.defaultBehavior;
      }
   },

   setBehavior: function( behavior ) { this.handler.behavior = behavior; },

   getBehavior: function( behavior ) { return this.handler.behavior; },

   getSelected: function() {
      if (this.handler.selected) return this.handler.selected;
      else return null;
   },

   remove: function() {},

   expand: function() { this.doExpand(); },

   collapse: function( b ) {
      if (!b) this.focus();

      this.doCollapse();
   },

   getFirst: function() { return null; },

   getLast: function() { return null; },

   getNextSibling: function() { return null; },

   getPreviousSibling: function() { return null; },

   keydown: function( key ) {
      if (key == 39) {
         if (!this.open) this.expand();
         else if (this.childNodes.length) this.childNodes[ 0 ].select();

         return false;
      }

      if (key == 37) { this.collapse(); return false; }

      if ((key == 40) && this.open && this.childNodes.length) {
         this.childNodes[ 0 ].select(); return false;
      }

      return true;
   },

   toString: function() {
      var i, sb = [], str;

      str  = '<div id="' + this.id + '" ';
      str += 'ondblclick="Tree.Handler.toggle(this);" ';
      str += 'class="treeBranch" ';
      str += 'onkeydown="return Tree.Handler.keydown(this, event)">';
      str += '<img id="' + this.id + '-icon" class="treeIcon" src="';
      str += this.selected
             ? this.config.selectedIcon
             : this.handler.behavior == 'classic' && this.open
               ? this.openIcon : this.icon;
      str += '" onclick="Tree.Handler.select(this);">';

      if (this.tip) {
         str += '<span class="help tips" title="' + this.tip + '">';
      }

      str += '<a class="treeFade" href="' + this.action + '" id="' + this.id;
      str += '-anchor" onfocus="Tree.Handler.focus(this);" ';
      str += 'onblur="Tree.Handler.blur(this);"';
      str += this.target ? ' target="' + this.target + '"' : '';
      str += '>' + this.text + '</a>';

      if (this.tip) str += '</span>';

      str += '</div>' + '<div id="' + this.id + '-cont" ';
      str += 'class="treeContainer" style="display: ';
      str += (this.open ? 'block' : 'none') + ';">';

      for (i = 0; i < this.childNodes.length; i++) {
         sb[ i ] = this.childNodes[ i ].toString( i, this.childNodes.length );
      }

      this.rendered = true;
      return str + sb.join( '' ) + '</div>';
   },
});

Tree.Branch = Tree.AbstractNode.extend({
   initialize: function( text, action, tip, parent, icon, openIcon ) {
      this.parent( text, action, tip );

      if (this.config.usePersistence) {
         this.open = (this.cookies.get( this.id ) == '1') ? true : false;
      }
      else { this.open = false; }

      this.icon     = icon     || this.config.rootIcon;
      this.openIcon = openIcon || this.config.openRootIcon;

      if (parent) parent.add( this );
   },

   remove: function() {
      var iconSrc = $( this.id + '-plus' ).src;
      var parentNode = this.parentNode;
      var prevSibling = this.getPreviousSibling( true );
      var nextSibling = this.getNextSibling( true );
      var folder = this.parentNode.folder;
      var last = (nextSibling && nextSibling.parentNode
                  && (nextSibling.parentNode.id == parentNode.id))
               ? false : true;
      this.getPreviousSibling().focus();
      this._remove();

      if (parentNode.childNodes.length == 0) {
         $( parentNode.id + '-cont' ).style.display = 'none';
         parentNode.doCollapse();
         parentNode.folder = false;
         parentNode.open = false;
      }

      if (!nextSibling || last) {
         parentNode.indent( null, true, last, this._level,
                            parentNode.childNodes.length);
      }

      if ((prevSibling == parentNode) && !parentNode.childNodes.length) {
         prevSibling.folder = false;
         prevSibling.open = false;
         iconSrc = $( prevSibling.id + '-plus' ).src;
         iconSrc = iconSrc.replace( 'minus', '' ).replace( 'plus', '' );
         $( prevSibling.id + '-plus' ).src = iconSrc;
         $( prevSibling.id + '-icon' ).src = this.config.fileIcon;
      }

      if ($( prevSibling.id + '-plus' )) {
         if (parentNode == prevSibling.parentNode) {
            iconSrc = iconSrc.replace( 'minus', '' ).replace( 'plus', '' );
            $( prevSibling.id + '-plus' ).src = iconSrc;
         }
      }
	},

   _remove: function() {
      for (var i = this.childNodes.length - 1; i >= 0; i--) {
         this.childNodes[ i ]._remove();
      }

      for (var i = 0; i < this.parentNode.childNodes.length; i++) {
         if (this == this.parentNode.childNodes[ i ]) {
            for (var j = i; j < this.parentNode.childNodes.length; j++) {
               this.parentNode.childNodes[j] = this.parentNode.childNodes[j+1];
            }

            this.parentNode.childNodes.length -= 1;

            if (i + 1 == this.parentNode.childNodes.length) {
               this.parentNode._last = true;
            }

            break;
         }
      }

      this.handler.all[ this.id ] = null;
      var tmp = $( this.id );

      if (tmp) tmp.parentNode.removeChild( tmp );

      tmp = $( this.id + '-cont' );

      if (tmp) tmp.parentNode.removeChild( tmp );
   },

   expand: function() {
      this.doExpand();
      $( this.id + '-plus' ).src = this.minusIcon;
   },

   collapse: function( b ) {
      if (!b) this.focus();

      this.doCollapse();
      $( this.id + '-plus' ).src = this.plusIcon;
   },

   getFirst: function() { return this.childNodes[ 0 ]; },

   getLast: function() {
      if (this.childNodes[ this.childNodes.length - 1 ].open) {
         return this.childNodes[ this.childNodes.length - 1 ].getLast();
      }
      else { return this.childNodes[ this.childNodes.length - 1 ]; }
   },

   getNextSibling: function() {
      for (var i = 0; i < this.parentNode.childNodes.length; i++) {
         if (this == this.parentNode.childNodes[ i ]) break;
      }

      if (++i == this.parentNode.childNodes.length) {
         return this.parentNode.getNextSibling();
      }
      else { return this.parentNode.childNodes[ i ]; }
   },

   getPreviousSibling: function( b ) {
      for (var i = 0; i < this.parentNode.childNodes.length; i++) {
         if (this == this.parentNode.childNodes[ i ]) break;
      }

      if (i == 0) { return this.parentNode; }
      else {
         if (this.parentNode.childNodes[ --i ].open
             || (b && this.parentNode.childNodes[ i ].folder)) {
            return this.parentNode.childNodes[ i ].getLast();
         }
         else { return this.parentNode.childNodes[ i ]; }
      }
   },

   keydown: function( key ) {
      if ((key == 39) && this.folder) {
         if (!this.open) this.expand();
         else this.getFirst().select();

         return false;
      }
      else if (key == 37) {
         if (this.open) this.collapse();
         else this.parentNode.select();

         return false;
      }
      else if (key == 40) {
         if (this.open) { this.getFirst().select(); }
         else {
            var sib = this.getNextSibling();

            if (sib) sib.select();
         }

         return false;
      }
      else if (key == 38) {
         this.getPreviousSibling().select();
         return false;
      }

      return true;
   },

   toString: function( nItem, nItemCount ) {
      var i = 0, img, indent = '', label, sb = [], str, foo = this.parentNode;

      if (nItem + 1 == nItemCount) this.parentNode._last = true;

      while (foo.parentNode) {
         foo    = foo.parentNode;
         img    = '<img id=\"' + this.id + '-img-' + i;
         img   += '" class="treeIcon" src="';
         img   += foo._last ? this.config.blankIcon : this.config.iIcon;
         img   += '">';
         indent = img + indent;
         i++;
      }

      this._level = i;

      if (this.childNodes.length) this.folder = 1;
      else this.open = false;

      if (this.folder || (this.handler.behavior != 'classic')) {
         this.icon     = this.icon     || this.config.folderIcon;
         this.openIcon = this.openIcon || this.config.openFolderIcon;
      }
      else { this.icon = this.icon || this.config.fileIcon; }

      label = this.text.replace( /</g, '&lt;' ).replace( />/g, '&gt;' );
      str  = '<div id="' + this.id;
      str += '" ondblclick="Tree.Handler.toggle(this);" class="treeBranch" ';
      str += 'onkeydown="return Tree.Handler.keydown(this, event)">' + indent;
      str += '<img class="treeIcon" id="' + this.id + '-plus" src="';
      str += this.folder ? (this.open
                            ? (this.parentNode._last
                               ? this.config.lMinusIcon
                               : this.config.tMinusIcon)
                            : (this.parentNode._last
                               ? this.config.lPlusIcon
                               : this.config.tPlusIcon))
                         : (this.parentNode._last
                            ? this.config.lIcon
                            : this.config.tIcon);
      str += '" onclick="Tree.Handler.toggle(this);">';
      str += '<img id="' + this.id + '-icon" class="treeIcon" src="';
      str += this.selected
             ? this.config.selectedIcon
             : this.open && this.handler.behavior == 'classic'
               ? this.openIcon : this.icon;
      str += '" onclick="Tree.Handler.select(this);">';

      if (this.tip) {
         str += '<span class="help tips" title="' + this.tip + '">';
      }

      str += '<a class="treeFade" href="' + this.action + '" id="' + this.id;
      str += '-anchor" onfocus="Tree.Handler.focus(this);" ';
      str += 'onblur="Tree.Handler.blur(this);"';
      str += (this.target ? ' target="' + this.target + '"' : '');
      str += '>' + label + '</a>';

      if (this.tip) str += '</span>';

      str += '</div>' + '<div id="' + this.id + '-cont" ';
      str += 'class="treeContainer" style="display: ';
      str += (this.open ? 'block' :'none') + ';">';

      for (i = 0; i < this.childNodes.length; i++) {
         sb[ i ] = this.childNodes[ i ].toString( i, this.childNodes.length );
      }

      this.plusIcon  = (this.parentNode._last
                        ? this.config.lPlusIcon  : this.config.tPlusIcon);
      this.minusIcon = (this.parentNode._last
                        ? this.config.lMinusIcon : this.config.tMinusIcon);
      return str + sb.join( '' ) + '</div>';
   },
});
