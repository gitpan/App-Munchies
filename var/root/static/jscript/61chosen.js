/* @(#)$Id: 61chosen.js 1272 2012-02-06 16:11:54Z pjf $
 * Chosen, a Select Box Enhancer for Mootools
 * by Patrick Filler for Harvest, http://getharvest.com
 * Available under the MIT License, http://en.wikipedia.org/wiki/MIT_License
 * Copyright (c) 2011 by Harvest
 */

Element.implement( {
    get_side_border_padding: function() {
        var styles  = this.getStyles(
            'padding-left', 'padding-right',
            'border-left-width', 'border-right-width' );
        var strings = Object.filter( styles, function( value ) {
            return (typeof( value ) == 'string') } );
        var ints    = Object.map( strings, function( s ) { return s.toInt() } );
        var array   = Object.values( ints );
        var result  = 0, l = array.length;

        if (l) { while (l--) result += array[ l ]; }

        return result;
    },

    select_to_array: function() {
        var parser = new SelectParser();

        this.getChildren().each( function( child ) {
            parser.add_node( child );
        } );

        return parser.parsed;
    }
} );

var SelectParser = new Class( {
    options_index: 0,
    parsed       : [],

    add_node: function( child ) {
        if (child.nodeName === 'OPTGROUP') this.add_group( child );
        else this.add_option( child );
    },

    add_group: function( group ) {
        var group_position = this.parsed.length;

        this.parsed.push( {
            array_index: group_position,
            group      : true,
            label      : group.label,
            children   : 0,
            disabled   : group.disabled
        } );

        group.getChildren().each( function( option ) {
            this.add_option( option, group_position, group.disabled );
        }, this );
    },

    add_option: function( option, group_position, group_disabled ) {
        if (option.nodeName !== 'OPTION') return;

        if (option.text === '') {
            this.parsed.push( {
                array_index  : this.parsed.length,
                options_index: this.options_index,
                empty        : true
            } );
        }
        else {
            if (group_position != null)
                this.parsed[ group_position ].children += 1;

            this.parsed.push( {
                array_index      : this.parsed.length,
                options_index    : this.options_index,
                value            : option.value,
                text             : option.text,
                selected         : option.selected,
                disabled         : group_disabled === true
                                 ? group_disabled : option.disabled,
                group_array_index: group_position
            } );
        }

        this.options_index += 1;
    }
} );

var Chosen = new Class( {
    Implements: [ Options ],

    options           : {
        multiple_text : 'Select some options',
        search_f_width: true,
        search_min_w  : 25,
        single_text   : 'Select an option'
    },

    initialize: function( el, options ) {
        this.setBuildOptions( options ); var opt = this.options;

        this.form_field         = el;
        this.is_multiple        = el.multiple;
        this.f_width            = el.getCoordinates().width;
        this.default_text       = el.get( 'title' ) ? el.get( 'title' )
                                : this.is_multiple  ? opt.multiple_text
                                                    : opt.single_text;
        this.active_field       = false;
        this.mouse_on_container = false;
        this.results_showing    = false;
        this.result_highlighted = null;
        this.result_single      = null;
        this.choices            = 0;
        this.createMarkup();
        this.attach();
    },

    activate_field: function() {
        if (!this.is_multiple && !this.active_field) {
            this.search_field.set
                ( 'tabindex', this.selected_item.get( 'tabindex' ) );
            this.selected_item.set( 'tabindex', -1 );
        }

        this.container.addClass( 'chzn-container-active' );
        this.active_field = true;
        this.search_field.set( 'value', this.search_field.get( 'value' ) );
        this.search_field.focus();
    },

    attach: function() {
        this.click_test_action = this.test_active_click.bind( this );
        this.form_field.addEvent
            ( 'liszt:updated', this.results_update_field.bind( this ) );
        this.container.addEvents( {
            click     : this.container_click.bind( this ),
            mouseenter: this.mouse_enter.bind( this ),
            mouseleave: this.mouse_leave.bind( this )
        } );
        this.search_field.addEvents( {
            blur   : this.input_blur.bind( this ),
            keyup  : this.keyup_checker.bind( this ),
            keydown: this.keydown_checker.bind( this )
        } );
        this.search_results.addEvents( {
            click    : this.search_results_click.bind( this ),
            mouseover: this.search_results_mouseover.bind( this ),
            mouseout : this.search_results_mouseout.bind( this )
        } );

        if (this.is_multiple) {
            this.search_choices.addEvent
                ( 'click', this.choices_click.bind( this ) );
            this.search_field.addEvent
                ( 'focus', this.input_focus.bind( this ) );
        }
        else {
            this.selected_item.addEvent
                ( 'focus', this.activate_field.bind( this ) );
        }
    },

    blur_test: function( ev ) {
        if (!this.active_field
            && this.container.hasClass( 'chzn-container-active' )) {
            this.close_field();
        }
    },

    choice_build: function( item ) {
        var choice_id = this.form_field.id + '_chzn_c_' + item.array_index, el;

        this.choices += 1;

        el = new Element( 'li', { 'id': choice_id, 'class': 'search-choice' } );

        new Element( 'a', { 'class': 'search-choice-close', href: '#',
                            rel: item.array_index } ).inject( el );
        new Element( 'span' ).appendText( item.text ).inject( el );

        var prompt = this.search_choices.getElement( 'li.search-prompt' );

        if (prompt) prompt.setStyle( 'display', 'none' );

        el.inject( this.search_choices );
        $( choice_id ).getElement( 'a' )
            .addEvent( 'click', this.choice_destroy_link_click.bind( this ) );
    },

    choice_destroy: function( link ) {
        this.choices -= 1; this.show_search_field_default();

        if (this.is_multiple && this.choices > 0
            && this.search_field.value.length < 1) {
            this.results_hide();
        }

        this.result_deselect( link.get( 'rel' ) );
        link.getParent( 'li' ).destroy();
    },

    choice_destroy_link_click: function( ev ) {
        ev.preventDefault();
        this.pending_destroy_click = true;
        this.choice_destroy( ev.target );
    },

    choices_click: function( ev ) {
        ev.preventDefault();

        if (this.active_field && !(ev.target.hasClass( 'search-choice' )
                                   || ev.target.getParent( '.search-choice' ))
            && !this.results_showing) {
            this.results_show();
        }
    },

    clear_backstroke: function() {
        if (this.pending_backstroke)
            this.pending_backstroke.removeClass( 'search-choice-focus' );

        this.pending_backstroke = null;
    },

    close_field: function() {
        document.removeEvent( 'click', this.click_test_action );

        if (!this.is_multiple) {
            this.selected_item.set
                ( 'tabindex', this.search_field.get( 'tabindex' ) );
            this.search_field.set( 'tabindex', -1 );
        }

        this.active_field = false;
        this.results_hide();
        this.container.removeClass( 'chzn-container-active' );
        this.winnow_results_clear();
        this.clear_backstroke();
        this.show_search_field_default();
        this.search_field_scale();
    },

    container_click: function( ev ) {
        if (ev && ev.type === 'click') ev.stopPropagation();

        if (this.pending_destroy_click) {
            this.pending_destroy_click = false; return;
        }

        if (!this.active_field) {
            if (this.is_multiple) this.search_field.value = '';

            document.addEvent( 'click', this.click_test_action );
            this.results_toggle();
        }
        else if (!this.is_multiple && ev
                 && (ev.target === this.selected_item
                     || ev.target.getParents( 'a.chzn-single' ).length)) {
            ev.preventDefault();
            this.results_show();
        }

        this.activate_field();
    },

    createMarkup: function() {
        var opt   = this.options,    is_multiple = this.is_multiple;
        var field = this.form_field, chzn_id     = field.id + '_chzn';

        var container_div = new Element( 'div', {
            'id': chzn_id, 'class': 'chzn-container'
        } ).setStyle( 'width', this.f_width + 'px' );

        if (is_multiple){
            var list  = new Element( 'ul', { 'class': 'chzn-choices' } )
                .inject( container_div );
            var item  = new Element( 'li', { 'class': 'search-prompt' } )
                .inject( list );
            new Element( 'span' ).appendText( this.default_text )
                .inject( item );
            var filler = new Element( 'div' ).inject( item );
            new Element( 'b' ).inject( filler );
        }
        else {
            var anchor = new Element( 'a', {
                'class': 'chzn-single', href: 'javascript:void(0)' } )
                .inject( container_div );
            new Element( 'span' ).appendText( this.default_text )
                .inject( anchor );
            var filler = new Element( 'div' ).inject( anchor );
            new Element( 'b' ).inject( filler );
        }

        var drop   = new Element( 'div', { 'class': 'chzn-drop' } )
            .setStyle( 'left', '-9000px' ).inject( container_div );
        var search = new Element( 'div', { 'class': 'chzn-search' } )
            .inject( drop );
        new Element( 'input', { type: 'text', 'class': 'ifield' } )
            .inject( search );
        new Element( 'ul', { 'class': 'chzn-results' } ).inject( drop );

        field.setStyle( 'display', 'none' ).grab( container_div, 'after' );

        var container = this.container = $( chzn_id );
        var klass     = 'chzn-container-' + (is_multiple ? 'multi' : 'single');

        container.addClass( klass );
        this.dropdown         = container.getElement( 'div.chzn-drop'   );
        this.search_container = container.getElement( 'div.chzn-search' );
        this.search_field     = container.getElement( 'input'           );
        this.search_results   = container.getElement( 'ul.chzn-results' );

        if (is_multiple)
             this.search_choices = container.getElement( 'ul.chzn-choices' );
        else this.selected_item  = container.getElement( '.chzn-single' );

        this.results_build();
        this.set_tab_index();
    },

    input_blur: function( ev ) {
        if (!this.mouse_on_container) {
            this.active_field = false;
            setTimeout( this.blur_test.bind( this ), 100 );
        }
    },

    input_focus: function( ev ) {
        if (!this.active_field)
            setTimeout( this.container_click.bind( this ), 50 );
    },

    keydown_arrow: function() {
        var first_active, next_sib;

        if (!this.result_highlight) {
            first_active = this.search_results.getElement( 'li.active-result' );

            if (first_active) this.result_do_highlight( first_active );
        }
        else if (this.results_showing) {
            next_sib = this.result_highlight.getNext( 'li.active-result' );

            if (next_sib) this.result_do_highlight( next_sib );
        }

        if (!this.results_showing) this.results_show();
    },

    keydown_backstroke: function() {
        if (this.pending_backstroke){
            this.choice_destroy( this.pending_backstroke.getElement( 'a' ) );
            this.clear_backstroke();
        }
        else {
            this.pending_backstroke
                = this.search_choices.getLast( 'li.search-choice' );
            this.pending_backstroke.addClass( 'search-choice-focus' );
        }
    },

    keydown_checker: function( ev ) {
        this.search_field_scale();

        if (ev.key !== 'backspace' && this.pending_backstroke)
            this.clear_backstroke();

        switch (ev.key) {
        case 'backspace':
            this.backstroke_length = this.search_field.value.length;
            break;
        case 'tab':
            this.mouse_on_container = false;
            break;
        case 'enter':
            ev.preventDefault();
            break;
        case 'up':
            ev.preventDefault();
            this.keyup_arrow();
            break;
        case 'down':
            this.keydown_arrow();
            break;
        }
    },

    keyup_arrow: function() {
        if (!this.results_showing && !this.is_multiple) {
            this.results_show();
        }
        else if (this.result_highlight) {
            var prev_sibs = this.result_highlight
                .getAllPrevious( 'li.active-result' );

            if (prev_sibs.length){
                this.result_do_highlight( prev_sibs[ 0 ] );
            }
            else {
                if (this.choices > 0) this.results_hide();

                this.result_clear_highlight();
            }
        }
    },

    keyup_checker: function( ev ) {
        this.search_field_scale();

        switch (ev.key) {
        case 'backspace':
            if (this.is_multiple && this.backstroke_length < 1
                && this.choices > 0) {
                this.keydown_backstroke();
            }
            else if (!this.pending_backstroke) {
                this.result_clear_highlight(); this.results_search();
            }

            break;
        case 'enter':
            ev.preventDefault();

            if (this.results_showing) this.result_select();

            break;
        case 'esc':
            if (this.results_showing) this.results_hide();

            break;
        case 'tab':
        case 'up':
        case 'down':
        case 'shift':
            break;
        default:
            this.results_search();
        }
    },

    mouse_enter: function() {
        this.mouse_on_container = true;
    },

    mouse_leave: function() {
        this.mouse_on_container = false;
    },

    no_results: function( terms ) {
        var no_results_html = new Element( 'li', { 'class': 'no-results' } )
            .set( 'html', 'No results match "<span></span>"' );

        no_results_html.getElement( 'span' ).appendText( terms );
        this.search_results.grab( no_results_html );
    },

    no_results_clear: function() {
        this.search_results.getElements( '.no-results' ).destroy();
    },

    result_activate: function( el ) {
        el.addClass( 'active-result' ).setStyle( 'display', 'block' );
    },

    result_add_group: function( group ) {
        if (group.disabled) return '';

        group.dom_id = this.form_field.id + 'chzn_g_' + group.array_index;

        var item = new Element( 'li', {
            'id': group.dom_id, 'class': 'group-result' } );

        new Element( 'div' ).appendText( group.label ).inject( item );
        return item;
    },

    result_add_option: function( option ) {
        if (option.disabled) return '';

        option.dom_id = this.form_field.id + 'chzn_o_' + option.array_index;

        var classes = option.selected && this.is_multiple
                    ? [] : [ 'active-result' ];

        if (option.selected) classes.push( 'result-selected' );

        if (option.group_array_index != null) classes.push( 'group-option' );

        var item = new Element( 'li', {
            'id': option.dom_id, 'class': classes.join( ' ' ) } );

        new Element( 'div' ).appendText( option.text ).inject( item );
        return item;
    },

    result_clear_highlight: function() {
        if (this.result_highlight)
            this.result_highlight.removeClass( 'highlighted' );

        this.result_highlight = null;
    },

    result_deactivate: function( el ) {
        el.removeClass( 'active-result' ).setStyle( 'display', 'none' );
    },

    result_deselect: function( pos ) {
        var result_data = this.results_data[ pos ];
        var result      = $( this.form_field.id + 'chzn_o_' + pos );

        result_data.selected = false;
        this.form_field.options[ result_data.options_index ].selected = false;
        result.removeClass( 'result-selected' )
              .addClass   ( 'active-result' ).setStyle( 'display', 'block' );
        this.result_clear_highlight();
        this.winnow_results();
        this.form_field.fireEvent( 'change' );
        this.search_field_scale();
    },

    result_do_highlight: function( el ) {
        if (!el) return;

        this.result_clear_highlight();
        this.result_highlight = el;
        this.result_highlight.addClass( 'highlighted' );

        var results        = this.search_results;
        var maxHeight      = parseInt( results.getStyle( 'maxHeight' ), 10 );
        var visible_top    = results.getScroll().y;
        var visible_bottom = maxHeight + visible_top;
        var high_top       = this.result_highlight.getPosition( results ).y
                           + visible_top;
        var high_bottom    = high_top
                           + this.result_highlight.getCoordinates().height;

        if (high_bottom >= visible_bottom) {
            results.scrollTo( 0, (high_bottom - maxHeight) > 0
                              ? high_bottom - maxHeight : 0 );
        }
        else if (high_top < visible_top) { results.scrollTo( 0, high_top ) }
    },

    result_select: function() {
        if (!this.result_highlight) return;

        var high = this.result_highlight, high_id = high.get( 'id' );

        this.result_clear_highlight(); high.addClass( 'result-selected' );

        if (this.is_multiple) this.result_deactivate( high );
        else this.result_single = high;

        var position = high_id.substr( high_id.lastIndexOf( '_' ) + 1 );
        var item     = this.results_data[ position ];

        item.selected = true;
        this.form_field.options[ item.options_index ].selected = true;

        if (this.is_multiple) this.choice_build( item );
        else this.selected_item.getElement( 'span' ).set( 'text', item.text );

        this.results_hide();
        this.search_field.set( 'value', '' );
        this.form_field.fireEvent( 'change' );
        this.search_field_scale();
    },

    results_build: function() {
        this.results_data = this.form_field.select_to_array();

        if (this.is_multiple && this.choices > 0) {
            this.search_choices.getElements( 'li.search-choice' ).destroy();
            this.choices = 0;
        }
        else if (!this.is_multiple) {
            this.selected_item.getElements( 'span' )
                .set( 'text', this.default_text );
        }

        this.results_data.each( function( data ) {
            var results = this.search_results;

            if (data.group) {
                results.grab( this.result_add_group( data ) ); return;
            }

            if (data.empty) return;

            results.grab( this.result_add_option( data ) );

            if (!data.selected) return;

            if (this.is_multiple) { this.choice_build( data ); return; }

            this.selected_item.getElements( 'span' ).set( 'text', data.text );
        }, this );

        this.show_search_field_default();
        this.search_field_scale();
    },

    results_hide: function() {
        if (!this.is_multiple)
            this.selected_item.removeClass( 'chzn-single-with-drop' );

        this.result_clear_highlight();
        this.dropdown.setStyle( 'left', -9000 );
        this.results_showing = false;
    },

    results_search: function( ev ) {
        if (this.results_showing) this.winnow_results();
        else this.results_show();
    },

    results_show: function() {
        if (!this.is_multiple) {
            this.selected_item.addClass( 'chzn-single-with-drop' );

            if (this.result_single)
                this.result_do_highlight( this.result_single );
        }

        var dd_top = this.is_multiple
                   ? this.container.getCoordinates().height
                   : this.container.getCoordinates().height - 1;

        this.dropdown.setStyles( { 'top': dd_top, 'left': 0 } );
        this.results_showing = true;
        this.search_field.focus();
        this.search_field.set( 'value', this.search_field.get( 'value' ) );
        this.winnow_results();
    },

    results_toggle: function() {
        if (this.results_showing) this.results_hide();
        else this.results_show();
    },

    results_update_field: function() {
        this.result_clear_highlight();
        this.result_single = null;
        this.results_build();
    },

    search_field_scale: function() {
        var opt      = this.options;
        var dropdown = this.dropdown, search_f = this.search_field;
        var dd_top   = this.container.getCoordinates().height;
        var dd_width = this.f_width - dropdown.get_side_border_padding();
        var sf_width = dd_width
                     - this.search_container.get_side_border_padding()
                     - search_f.get_side_border_padding();
        var w        = sf_width;

        dropdown.setStyles( { 'width': dd_width, 'top': dd_top } );

        if (this.is_multiple && !opt.search_f_width) {
            var style_block = { position: 'absolute', visibility: 'hidden' };
            var styles      = search_f.getStyles(
                'font-size', 'font-style', 'font-weight', 'font-family',
                'line-height', 'text-transform', 'letter-spacing' );

            Object.merge( style_block, styles );

            var div = new Element( 'div', { 'styles': style_block } )
                      .appendText( search_f.get( 'value' ) );

            document.body.grab( div );

            w = div.getCoordinates().width + opt.search_min_w;

            div.destroy(); if (w > sf_width) w = sf_width;
        }

        search_f.setStyle( 'width', w );
    },

    search_results_click: function( ev ) {
        var target = ev.target.hasClass( 'active-result' )
                   ? ev.target : ev.target.getParent( '.active-result' );

        if (target) {
            this.result_highlight = target; this.result_select();
        }
    },

    search_results_mouseout: function( ev ) {
        if (ev.target.hasClass( 'active-result' )
            || ev.target.getParent( '.active-result' )) {
            this.result_clear_highlight();
        }
    },

    search_results_mouseover: function( ev ) {
        var target = ev.target.hasClass( 'active-result' )
                   ? ev.target : ev.target.getParent( '.active-result' );

        if (target) this.result_do_highlight( target );
    },

    set_tab_index: function( el ) {
        var field = this.form_field, ti = field.get( 'tabindex' );

        if (!ti) return; field.set( 'tabindex', -1 );

        if (this.is_multiple) { this.search_field.set( 'tabindex', ti ) }
        else {
            this.selected_item.set( 'tabindex', ti );
            this.search_field.set ( 'tabindex', -1 );
        }
    },

    show_search_field_default: function() {
        if (this.is_multiple && this.choices < 1) {
            var prompt = this.search_choices.getElement( 'li.search-prompt' );

            if (prompt) prompt.setStyle( 'display', '' );
        }
        else this.search_field.set( 'value', '' );
    },

    test_active_click: function( ev ) {
        if (ev.target.getParents( '#' + this.container.id ).length)
            this.active_field = true;
        else this.close_field();
    },

    winnow_results: function() {
        this.no_results_clear();

        var searchText = this.search_field.get( 'value' ) === this.default_text
                       ? '' : this.search_field.get( 'value' ).trim();
        var regex      = new RegExp
            ( '^' + searchText.replace( /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&" ),
              'i' );
        var zregex     = new RegExp
            ( searchText.replace( /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&" ), 'i' );
        var results    = 0;

        this.results_data.each( function( option ) {
            var found = false, otext = option.text, result_id = option.dom_id;

            if (option.disabled || option.empty) return;

            if (option.group) {
                $( result_id ).setStyle( 'display', 'none' ); return;
            }

            if (this.is_multiple && option.selected) return;

            if (regex.test( otext )) { found = true; results += 1 }
            else if (otext.indexOf( ' ' ) >= 0 || otext.indexOf( '[' ) === 0) {
                var parts = otext.replace( /\[|\]/g, '' ).split( ' ' );

                if (parts.length) parts.each( function( part ) {
                    if (regex.test( part )) { found = true; results += 1 }
                } );
            }

            if (found) {
                var text;

                if (searchText.length) {
                    var startpos = otext.search( zregex );

                    text = otext.substr( 0, startpos + searchText.length )
                        + '</em>'
                        + otext.substr( startpos + searchText.length );
                    text = text.substr( 0, startpos )
                        + '<em>' + text.substr( startpos );
                }
                else { text = otext }

                if ($(result_id).get( 'html' ) !== text)
                    $(result_id).set( 'html', text );

                this.result_activate( $( result_id ) );

                if (option.group_array_index != null) {
                    $( this.results_data[ option.group_array_index ].dom_id )
                        .setStyle( 'display', 'block' );
                }
            }
            else {
                if (this.result_highlight
                    && result_id === this.result_highlight.get( 'id' )) {
                    this.result_clear_highlight();
                }

                this.result_deactivate( $( result_id ) );
            }
        }, this );

        if (results < 1 && searchText.length) this.no_results( searchText );
        else this.winnow_results_set_highlight();
    },

    winnow_results_clear: function() {
        this.search_field.set( 'value', '' );
        this.search_results.getElements( 'li' ).each( function( el ) {
            el.hasClass( 'group-result' )
                ? el.setStyle( 'display', 'block' )
                : !this.is_multiple || !el.hasClass( 'result-selected' )
                ? this.result_activate( el ) : void 0;
        }, this );
    },

    winnow_results_set_highlight: function() {
        if (!this.result_highlight) {
            var do_high = this.search_results.getElement( '.active-result' );

            if (do_high) this.result_do_highlight( do_high );
        }
    }
} );

var Chosens = new Class( {
    Implements: [ Options ],

    options: { config: { defaults: {} }, selector: '.chzn-select' },

   initialize: function( options ) {
      this.setBuildOptions( options );
      this.config = Object.merge( this.options.config.defaults );
      this.build();
   },

   attach: function( el ) {
       el.chosen = new Chosen
           ( el, Object.merge( this.config, this.options.config[ el.id ] ) );
   }
} );

/* Local Variables:
 * mode: javascript
 * tab-width: 3
 * End:
 */
