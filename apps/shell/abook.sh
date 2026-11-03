#!/bin/sh
#
# abook.sh - an interactive reader for the knowledge base of
# "A Book Of Life To Rebuild The World".
#
# The reader is written in portable POSIX shell.  It uses nothing but a
# standard POSIX toolset: awk, sed, grep, cut, tr, dd and stty.  The corpus
# is read straight from the repository checkout, so the reader never needs
# the network.
#
# Usage:
#   abook.sh                 open the reader
#   abook.sh --selftest      run the built in checks and exit
#   abook.sh --version       print the version and exit
#   abook.sh --help          print this help and exit
#
# Options:
#   --root <path>    the repository root (found automatically by default)
#   --lang <code>    the interface language, e.g. fr
#   --theme <name>   the colour theme, light or dark

# The libraries are checked on their own, so shellcheck is told to look past
# the names that they share and past the files that are sourced.
# shellcheck disable=SC1091
# shellcheck disable=SC2153

set -eu

# --------------------------------------------------------------------------
# Set up
# --------------------------------------------------------------------------

ABOOK_APP_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ABOOK_LIB_DIR="$ABOOK_APP_DIR/lib"
ABOOK_SELF="$ABOOK_APP_DIR/$(basename -- "$0")"

# The control characters the key reader uses.
ABOOK_ESC=$(printf '\033')
ABOOK_K_TAB=$(printf '\t')
ABOOK_CTRL_C=$(printf '\003')
ABOOK_CTRL_F=$(printf '\006')
ABOOK_CTRL_K=$(printf '\013')
ABOOK_CTRL_L=$(printf '\014')
ABOOK_CTRL_Q=$(printf '\021')
ABOOK_CTRL_T=$(printf '\024')
ABOOK_CTRL_U=$(printf '\025')
ABOOK_ENTER=$(printf '\015')
#: A newline.  It cannot be made with a command substitution, because that
#: would swallow the newline.
ABOOK_NEWLINE='
'
ABOOK_BACKSPACE=$(printf '\177')

# The libraries.
# shellcheck source=lib/config.sh
. "$ABOOK_LIB_DIR/config.sh"
# shellcheck source=lib/theme.sh
. "$ABOOK_LIB_DIR/theme.sh"
# shellcheck source=lib/corpus.sh
. "$ABOOK_LIB_DIR/corpus.sh"
# shellcheck source=lib/search.sh
. "$ABOOK_LIB_DIR/search.sh"
# shellcheck source=lib/i18n.sh
. "$ABOOK_LIB_DIR/i18n.sh"
# shellcheck source=lib/render.sh
. "$ABOOK_LIB_DIR/render.sh"

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

#: The text of the live search box.
QUERY=""

#: The text of the quick jump palette.
JUMP_QUERY=""

#: The text of the command line.
CMD=""

#: The mode of the input: "", "search", "jump" or "command".
INPUT_MODE=""

#: Which pane has the focus: "left" or "right".
FOCUS="left"

#: The item of the left pane that is selected.
CURSOR=1

#: How many items the left pane holds.
ITEM_COUNT=0

#: The first row of the left pane that is drawn.
LEFT_SCROLL=0

#: The first line of the right pane that is drawn.
RIGHT_SCROLL=0

#: The overlay that is drawn over the frame: "", "about" or "help".
OVERLAY=""

#: Where the results come from: "search" or "recent".
RESULTS_MODE="search"

#: The domains of the corpus, one "name<TAB>count<TAB>description" per line.
DOMAIN_ROWS=""

#: How many domains the corpus holds.
DOMAIN_COUNT=0

#: The rows of the left pane, one "kind|text" line per row.
LEFT_ROWS=""

#: The items of the left pane, one "kind:argument" per line.
LEFT_ITEMS=""

#: The row of every item of the left pane.
LEFT_ITEM_ROWS=""

#: The row the next item is added at.
LEFT_ROW=0

#: Set to 1 when the left pane has to be built again.
LEFT_DIRTY=1

#: The index of the entry that is drawn in the right pane.
VIEW_INDEX=0

#: The header of the entry that is drawn in the right pane.
VIEW_HEADER=""

#: The path of the entry that is drawn in the right pane.
VIEW_PATH=""

#: The body of the entry that is drawn in the right pane.
VIEW_BODY=""

#: The index the cached body belongs to.
VIEW_BODY_INDEX=0

#: The titles of the entries of the domain that is drawn in the right pane.
VIEW_DOMAIN_TITLES=""

#: The domain the cached titles belong to.
VIEW_DOMAIN=""

#: The lines of the right pane.
RIGHT_CONTENT=""

#: The lines of the left pane.
LEFT_CONTENT=""

#: The row of the left pane that is selected.
SELECTED_ROW=0

#: The text of the status bar.
STATUS_TEXT=""

#: The text of the search line.
SEARCH_TEXT=""

#: The text of the command line.
COMMAND_TEXT=""

#: The path of the repository root that was asked for.
ROOT_OPTION=""

#: The language that was asked for.
LANG_OPTION=""

#: The theme that was asked for.
THEME_OPTION=""

#: Set to 1 when the reader should leave.
_QUIT=0

#: How many checks of the self test passed.
_CHECKS_PASSED=0

#: How many checks of the self test failed.
_CHECKS_FAILED=0

# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------

# _usage
#
# Print the usage of the program.
_usage() {
    sed -n '3,20p' "$ABOOK_SELF" | sed 's/^# \{0,1\}//'
    return 0
}

# _die <message>
#
# Print a message on the error stream and leave with a non zero code.
_die() {
    printf 'abook: %s\n' "$1" >&2
    exit 2
}

# _need_tty
#
# Refuse to open the interface when there is no terminal to draw on.
_need_tty() {
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        printf 'abook: %s\n' "$(t not_interactive)" >&2
        printf 'abook: %s\n' "Try: sh $ABOOK_SELF --selftest" >&2
        exit 2
    fi
    return 0
}

# _find_root
#
# Work out which repository to read and load its manifest.
_find_root() {
    if [ -n "$ROOT_OPTION" ]; then
        ABOOK_ROOT=$(CDPATH='' cd -- "$ROOT_OPTION" 2>/dev/null && pwd) || _die "no such directory: $ROOT_OPTION"
    else
        ABOOK_ROOT=$(_abook_find_root "$ABOOK_APP_DIR") || _die "could not find $ABOOK_MANIFEST_NAME; run the reader from inside the repository"
    fi
    [ -f "$ABOOK_ROOT/$ABOOK_MANIFEST_NAME" ] || _die "no $ABOOK_MANIFEST_NAME in $ABOOK_ROOT"
    _abook_load_manifest "$ABOOK_ROOT" || true
    return 0
}

# --------------------------------------------------------------------------
# The left pane
# --------------------------------------------------------------------------

# _left_reset
#
# Empty the left pane.
_left_reset() {
    LEFT_ROWS=""
    LEFT_ITEMS=""
    LEFT_ITEM_ROWS=""
    LEFT_ROW=0
    return 0
}

# _left_add <kind> <text> <item>
#
# Add one row to the left pane.  The item is empty for the rows that cannot
# be selected.
_left_add() {
    _la_kind=$1
    _la_text=$2
    _la_item=$3
    LEFT_ROWS="$LEFT_ROWS$_la_kind|$_la_text
"
    if [ -n "$_la_item" ]; then
        LEFT_ITEMS="$LEFT_ITEMS$_la_item
"
        LEFT_ITEM_ROWS="$LEFT_ITEM_ROWS$LEFT_ROW
"
    fi
    LEFT_ROW=$((LEFT_ROW + 1))
    return 0
}

# _left_item <number>
#
# Print the item of the left pane at the given position.
_left_item() {
    printf '%s\n' "$LEFT_ITEMS" | sed -n "${1}p"
    return 0
}

# _left_row <number>
#
# Print the row of the left pane item at the given position.
_left_row() {
    printf '%s\n' "$LEFT_ITEM_ROWS" | sed -n "${1}p"
    return 0
}

# _left_count
#
# Print how many items the left pane holds.
_left_count() {
    printf '%s\n' "$LEFT_ITEMS" | grep -c . || true
    return 0
}

# _build_left
#
# Build the rows of the left pane: the domains first, then the results.
_build_left() {
    _bl_left=$((LAYOUT_LEFT_INNER - 5))
    [ "$_bl_left" -lt 6 ] && _bl_left=6
    _left_reset
    _left_add "H" "$(t domains) ($DOMAIN_COUNT)" ""
    while IFS="$ABOOK_TAB" read -r _bl_name _bl_count _bl_desc; do
        [ -n "$_bl_name" ] || continue
        _left_add "N" "$(printf '  %-*s%3s' "$_bl_left" "$_bl_name" "$_bl_count")" "D:$_bl_name"
    done <<ABOOK_DOMAINS_EOF
$DOMAIN_ROWS
ABOOK_DOMAINS_EOF
    if [ "$RESULTS_MODE" = "recent" ]; then
        _left_add "H" "$(t recently_read) ($SEARCH_COUNT)" ""
    else
        _left_add "H" "$(t results) ($SEARCH_COUNT)" ""
    fi
    if [ "$SEARCH_COUNT" -eq 0 ]; then
        _left_add "M" "  $(t no_results)" ""
    else
        while IFS="$ABOOK_TAB" read -r _bl_tier _bl_score _bl_domain _bl_title _bl_index; do
            [ -n "$_bl_index" ] || continue
            _left_add "N" "  $_bl_title" "E:$_bl_index"
        done <<ABOOK_RESULTS_EOF
$SEARCH_RESULTS
ABOOK_RESULTS_EOF
    fi
    LEFT_CONTENT=$LEFT_ROWS
    ITEM_COUNT=$(_left_count)
    LEFT_DIRTY=0
    return 0
}

# _build_right
#
# Build the lines of the right pane: the selected entry or the overview of
# the selected domain.
_build_right() {
    _br_item=$(_left_item "$CURSOR")
    case "$_br_item" in
        E:*)
            _build_entry_view "${_br_item#E:}"
            ;;
        D:*)
            _build_domain_view "${_br_item#D:}"
            ;;
        *)
            RIGHT_CONTENT="M|$(t select_entry)"
            ;;
    esac
    return 0
}

# _build_entry_view <index>
#
# Build the right pane for one entry.
_build_entry_view() {
    _bev_index=$1
    if [ "$VIEW_INDEX" != "$_bev_index" ]; then
        VIEW_INDEX=$_bev_index
        _bev_line=$(_corpus_entry "$_bev_index")
        _bev_title=$(printf '%s\n' "$_bev_line" | cut -f4)
        _bev_domain=$(printf '%s\n' "$_bev_line" | cut -f2)
        _bev_diff=$(printf '%s\n' "$_bev_line" | cut -f5)
        _bev_safety=$(printf '%s\n' "$_bev_line" | cut -f6)
        _bev_time=$(printf '%s\n' "$_bev_line" | cut -f7)
        _bev_status=$(printf '%s\n' "$_bev_line" | cut -f8)
        _bev_tags=$(printf '%s\n' "$_bev_line" | cut -f9)
        VIEW_PATH=$(printf '%s\n' "$_bev_line" | cut -f11)
        _bev_meta="$_bev_domain  -  $(t difficulty): ${_bev_diff:-?}  -  $(t safety): ${_bev_safety:-?}"
        _bev_meta2="$(t verification): ${_bev_status:-?}"
        if [ -n "$_bev_time" ]; then
            _bev_meta2="$_bev_meta2  -  $(t time_to_complete): $_bev_time"
        fi
        # A narrow pane gets the short form of the line.
        if [ "$(_display_width "$_bev_meta")" -gt "$LAYOUT_RIGHT_INNER" ]; then
            _bev_meta="$_bev_domain  -  ${_bev_diff:-?}  -  ${_bev_safety:-?}"
        fi
        if [ "$(_display_width "$_bev_meta2")" -gt "$LAYOUT_RIGHT_INNER" ]; then
            _bev_meta2="${_bev_status:-?}"
            if [ -n "$_bev_time" ]; then
                _bev_meta2="$_bev_meta2  -  $_bev_time"
            fi
        fi
        VIEW_HEADER="H|$_bev_title
M|$_bev_meta
M|$_bev_meta2"
        if [ -n "$_bev_tags" ]; then
            VIEW_HEADER="$VIEW_HEADER
M|$(t tags): $_bev_tags"
        fi
        VIEW_HEADER="$VIEW_HEADER
R|"
    fi
    if [ "$VIEW_BODY_INDEX" != "$_bev_index" ]; then
        VIEW_BODY=$(_render_markdown "$ABOOK_ROOT/$VIEW_PATH" "$LAYOUT_RIGHT_INNER" 2>/dev/null || printf '')
        VIEW_BODY_INDEX=$_bev_index
    fi
    RIGHT_CONTENT="$VIEW_HEADER
$VIEW_BODY
M|$VIEW_PATH"
    return 0
}

# _build_domain_view <domain>
#
# Build the right pane for one domain.
_build_domain_view() {
    _bdv_domain=$1
    if [ "$VIEW_DOMAIN" != "$_bdv_domain" ]; then
        VIEW_DOMAIN=$_bdv_domain
        VIEW_DOMAIN_TITLES=$(awk -F'\t' -v d="$_bdv_domain" '$2 == d { print $4 }' "$CORPUS_INDEX_FILE")
    fi
    _bdv_count=0
    _bdv_body=""
    while IFS= read -r _bdv_line; do
        [ -n "$_bdv_line" ] || continue
        _bdv_count=$((_bdv_count + 1))
        _bdv_body="$_bdv_body
N|$_bdv_line"
    done <<ABOOK_TITLES_EOF
$VIEW_DOMAIN_TITLES
ABOOK_TITLES_EOF
    _bdv_desc=$(printf '%s\n' "$DOMAIN_ROWS" | awk -F'\t' -v d="$_bdv_domain" '$1 == d { print $3; exit }')
    RIGHT_CONTENT="H|$_bdv_domain
M|$_bdv_desc
M|$(t domain_entry_count count="$_bdv_count")
R|
$_bdv_body"
    return 0
}

# --------------------------------------------------------------------------
# Scrolling
# --------------------------------------------------------------------------

# _scroll_to_cursor
#
# Make sure the selected item is visible in the left pane.
_scroll_to_cursor() {
    _stc_row=$(_left_row "$CURSOR")
    [ -n "$_stc_row" ] || _stc_row=0
    if [ "$_stc_row" -lt "$LEFT_SCROLL" ]; then
        LEFT_SCROLL=$_stc_row
    fi
    if [ "$_stc_row" -ge $((LEFT_SCROLL + LAYOUT_PANE_HEIGHT)) ]; then
        LEFT_SCROLL=$((_stc_row - LAYOUT_PANE_HEIGHT + 1))
    fi
    [ "$LEFT_SCROLL" -lt 0 ] && LEFT_SCROLL=0
    SELECTED_ROW=$((_stc_row - LEFT_SCROLL + 1))
    return 0
}

# _move_cursor <delta>
#
# Move the selection of the left pane.
_move_cursor() {
    _mc_target=$((CURSOR + $1))
    [ "$ITEM_COUNT" -lt 1 ] && _mc_target=1
    [ "$_mc_target" -lt 1 ] && _mc_target=1
    [ "$_mc_target" -gt "$ITEM_COUNT" ] && _mc_target=$ITEM_COUNT
    CURSOR=$_mc_target
    RIGHT_SCROLL=0
    _scroll_to_cursor
    return 0
}

# _scroll_body <delta>
#
# Scroll the entry in the right pane.
_scroll_body() {
    _sb_lines=$(printf '%s\n' "$RIGHT_CONTENT" | grep -c . || true)
    _sb_max=$((_sb_lines - LAYOUT_PANE_HEIGHT))
    [ "$_sb_max" -lt 0 ] && _sb_max=0
    RIGHT_SCROLL=$((RIGHT_SCROLL + $1))
    [ "$RIGHT_SCROLL" -lt 0 ] && RIGHT_SCROLL=0
    [ "$RIGHT_SCROLL" -gt "$_sb_max" ] && RIGHT_SCROLL=$_sb_max
    return 0
}

# _scroll_body_to <position>
#
# Scroll the entry in the right pane to the top or to the bottom.
_scroll_body_to() {
    _sbt_lines=$(printf '%s\n' "$RIGHT_CONTENT" | grep -c . || true)
    _sbt_max=$((_sbt_lines - LAYOUT_PANE_HEIGHT))
    [ "$_sbt_max" -lt 0 ] && _sbt_max=0
    RIGHT_SCROLL=$1
    [ "$RIGHT_SCROLL" -lt 0 ] && RIGHT_SCROLL=0
    [ "$RIGHT_SCROLL" -gt "$_sbt_max" ] && RIGHT_SCROLL=$_sbt_max
    return 0
}

# --------------------------------------------------------------------------
# The status bar
# --------------------------------------------------------------------------

# _build_status
#
# Build the text of the status bar and of the two input lines.  The filters
# that are not set are not shown, and the hints of the keyboard are only
# shown when there is room for them.
_build_status() {
    _bs_filters=""
    if [ -n "$FILTER_DOMAIN" ]; then
        _bs_filters="$(t filter_domain): $FILTER_DOMAIN | "
    fi
    if [ -n "$FILTER_SAFETY" ]; then
        _bs_filters="$_bs_filters$(t filter_safety): $FILTER_SAFETY | "
    fi
    if [ -n "$FILTER_DIFFICULTY" ]; then
        _bs_filters="$_bs_filters$(t difficulty): $FILTER_DIFFICULTY | "
    fi
    _bs_left="$_bs_filters$(t result_count count="$SEARCH_COUNT") | $(_i18n_name "$I18N_LANG") | $THEME_NAME"
    _bs_right="$(t shortcut_search)  $(t shortcut_jump)  $(t shortcut_about)  $(t shortcut_quit)"
    _bs_short="F1 help  Ctrl+Q quit"
    _bs_width=$((ABOOK_COLS - 2))
    _bs_left_len=$(_display_width "$_bs_left")
    if [ $((_bs_left_len + $(_display_width "$_bs_right") + 1)) -gt "$_bs_width" ]; then
        _bs_right=$_bs_short
    fi
    _bs_fill=$((_bs_width - _bs_left_len - $(_display_width "$_bs_right") - 1))
    [ "$_bs_fill" -lt 1 ] && _bs_fill=1
    STATUS_TEXT="$_bs_left$(_spaces "$_bs_fill")$_bs_right"
    SEARCH_TEXT="$(t search): $QUERY"
    COMMAND_TEXT=": $CMD"
    return 0
}

# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------

# _run_command <command>
#
# Run one command of the command line.
_run_command() {
    _rc_cmd=$1
    _rc_word=${_rc_cmd%% *}
    _rc_rest=${_rc_cmd#* }
    if [ "$_rc_rest" = "$_rc_cmd" ]; then
        _rc_rest=""
    fi
    case "$_rc_word" in
        help)
            OVERLAY="help"
            ;;
        about)
            OVERLAY="about"
            ;;
        search)
            QUERY=$_rc_rest
            RESULTS_MODE="search"
            _refresh_results
            ;;
        domain)
            FILTER_DOMAIN=$_rc_rest
            RESULTS_MODE="search"
            _refresh_results
            ;;
        safety)
            case "$_rc_rest" in
                green|yellow|red) FILTER_SAFETY=$_rc_rest ;;
                *) FILTER_SAFETY="" ;;
            esac
            RESULTS_MODE="search"
            _refresh_results
            ;;
        difficulty)
            case "$_rc_rest" in
                novice|apprentice|journeyman|master) FILTER_DIFFICULTY=$_rc_rest ;;
                *) FILTER_DIFFICULTY="" ;;
            esac
            RESULTS_MODE="search"
            _refresh_results
            ;;
        lang)
            if [ -n "$_rc_rest" ]; then
                _i18n_load "$_rc_rest" || true
                SETTINGS_LANGUAGE=$I18N_LANG
            fi
            ;;
        theme)
            case "$_rc_rest" in
                light|dark) _theme_set "$_rc_rest" ;;
                *) _theme_set "$THEME_NAME" ;;
            esac
            SETTINGS_THEME=$THEME_NAME
            ;;
        recent)
            RESULTS_MODE="recent"
            _refresh_results
            ;;
        open)
            _rc_index=$(_corpus_find_by_slug "$_rc_rest")
            if [ -n "$_rc_index" ]; then
                RESULTS_MODE="search"
                _refresh_results
                _select_index "$_rc_index"
            fi
            ;;
        clear)
            QUERY=""
            FILTER_DOMAIN=""
            FILTER_SAFETY=""
            FILTER_DIFFICULTY=""
            RESULTS_MODE="search"
            _refresh_results
            ;;
        quit|q|exit)
            _QUIT=1
            ;;
        "")
            ;;
        *)
            STATUS_TEXT="$(t no_command command="$_rc_cmd")"
            ;;
    esac
    return 0
}

# _select_index <index>
#
# Put the selection on an entry.
_select_index() {
    _si_index=$1
    _si_row=0
    _si_found=0
    while IFS= read -r _si_item; do
        [ -n "$_si_item" ] || continue
        _si_row=$((_si_row + 1))
        case "$_si_item" in
            "E:$_si_index")
                CURSOR=$_si_row
                _si_found=1
                break
                ;;
        esac
    done <<ABOOK_ITEMS_EOF
$LEFT_ITEMS
ABOOK_ITEMS_EOF
    [ "$_si_found" -eq 1 ] || return 0
    RIGHT_SCROLL=0
    _scroll_to_cursor
    return 0
}

# --------------------------------------------------------------------------
# Results
# --------------------------------------------------------------------------

# _refresh_results
#
# Run the search again and put the selection on the first result.
_refresh_results() {
    if [ "$RESULTS_MODE" = "recent" ]; then
        _search_recent
    else
        _search_run "$QUERY"
    fi
    LEFT_DIRTY=1
    if [ "$SEARCH_COUNT" -gt 0 ]; then
        CURSOR=$((DOMAIN_COUNT + 1))
    fi
    return 0
}

# --------------------------------------------------------------------------
# The overlays
# --------------------------------------------------------------------------

# _about_body
#
# Build the body of the about screen: the version, the index and the
# disclaimer of the repository, quoted verbatim.  A line of the disclaimer
# that is too wide for the screen is folded, so that no word is lost.
_about_body() {
    _ab_width=$((ABOOK_COLS - 10))
    [ "$_ab_width" -gt 90 ] && _ab_width=90
    [ "$_ab_width" -lt 40 ] && _ab_width=40
    _ab_body=">$(t site_name)
>$(t version): $ABOOK_VERSION
>$(t entries): $CORPUS_COUNT
>$(t index_source source="$ABOOK_INDEX_SOURCE")
M|$(t disclaimer)
>"
    _ab_disclaimer=$(_corpus_disclaimer 2>/dev/null || printf '')
    while IFS= read -r _ab_line; do
        [ -n "$_ab_line" ] || continue
        if [ "${#_ab_line}" -gt "$_ab_width" ]; then
            _ab_line=$(printf '%s\n' "$_ab_line" | fold -s -w "$_ab_width")
        fi
        while IFS= read -r _ab_part; do
            _ab_body="$_ab_body
$_ab_part"
        done <<ABOOK_FOLD_EOF
$_ab_line
ABOOK_FOLD_EOF
    done <<ABOOK_DISCLAIMER_EOF
$_ab_disclaimer
ABOOK_DISCLAIMER_EOF
    _ab_body="$_ab_body
M|$(t shortcuts)
>$(t shortcut_search)
>$(t shortcut_jump)
>$(t shortcut_about)
>$(t shortcut_quit)
M|$(t disclaimer_full)
M|$(t press_any_key)"
    printf '%s\n' "$_ab_body"
    return 0
}

# _help_body
#
# Build the body of the help screen: the commands and the shortcuts.
_help_body() {
    _hb_body=">$(t shortcuts)
>$(t shortcut_search)
>$(t shortcut_jump)
>$(t shortcut_about)
>$(t shortcut_quit)
>Tab - switch pane
>Up, Down - move the selection
>PageUp, PageDown - scroll the entry
>Ctrl+T - switch the theme
>Ctrl+L - switch the language
M|$(t command)
>:help             - this help
>:about            - the about screen
>:search <text>    - search for text
>:domain <name>    - filter by domain
>:safety <level>   - filter by safety level
>:difficulty <lvl> - filter by difficulty
>:lang <code>      - switch the interface language
>:theme <name>     - light or dark
>:recent           - the recently read entries
>:open <slug>      - open an entry by slug
>:clear            - clear the filters
>:quit             - leave
M|$(t press_any_key)"
    printf '%s\n' "$_hb_body"
    return 0
}

# --------------------------------------------------------------------------
# The key reader
# --------------------------------------------------------------------------

# _handle_navigation_key
#
# Handle a key that was pressed while the panes had the focus.
_handle_navigation_key() {
    if [ "$FOCUS" = "right" ]; then
        case "$UI_KEY" in
            UP) _scroll_body -1; return 0 ;;
            DOWN) _scroll_body 1; return 0 ;;
            PGUP) _scroll_body "-$LAYOUT_PANE_HEIGHT"; return 0 ;;
            PGDN) _scroll_body "$LAYOUT_PANE_HEIGHT"; return 0 ;;
            HOME) _scroll_body_to 0; return 0 ;;
            END) _scroll_body_to 1000000; return 0 ;;
        esac
    fi
    case "$UI_KEY" in
        UP)
            _move_cursor -1
            ;;
        DOWN)
            _move_cursor 1
            ;;
        PGUP)
            _move_cursor "-$LAYOUT_PANE_HEIGHT"
            ;;
        PGDN)
            _move_cursor "$LAYOUT_PANE_HEIGHT"
            ;;
        LEFT|RIGHT|"$ABOOK_K_TAB")
            if [ "$FOCUS" = "left" ]; then
                FOCUS="right"
            else
                FOCUS="left"
            fi
            ;;
        "$ABOOK_CTRL_F")
            INPUT_MODE="search"
            _ui_blocking_on
            ;;
        "$ABOOK_CTRL_K")
            INPUT_MODE="jump"
            JUMP_QUERY=""
            _search_quick_jump ""
            LEFT_DIRTY=1
            _ui_blocking_on
            ;;
        ":")
            INPUT_MODE="command"
            CMD=""
            _ui_blocking_on
            ;;
        "$ABOOK_CTRL_T")
            if [ "$THEME_NAME" = "dark" ]; then
                _theme_set light
            else
                _theme_set dark
            fi
            SETTINGS_THEME=$THEME_NAME
            ;;
        "$ABOOK_CTRL_L")
            _cycle_language
            ;;
        "$ABOOK_CTRL_U")
            QUERY=""
            RESULTS_MODE="search"
            _refresh_results
            ;;
        "$ABOOK_ESC")
            QUERY=""
            FILTER_DOMAIN=""
            FILTER_SAFETY=""
            FILTER_DIFFICULTY=""
            RESULTS_MODE="search"
            _refresh_results
            ;;
        "$ABOOK_ENTER"|"$ABOOK_NEWLINE")
            _activate_item
            ;;
        F1)
            OVERLAY="about"
            ;;
        *)
            ;;
    esac
    return 0
}

# _activate_item
#
# React to the selected item: a domain becomes the filter, an entry is
# remembered as recently read.
_activate_item() {
    _ai_item=$(_left_item "$CURSOR")
    case "$_ai_item" in
        D:*)
            _ai_domain=${_ai_item#D:}
            if [ "$FILTER_DOMAIN" = "$_ai_domain" ]; then
                FILTER_DOMAIN=""
            else
                FILTER_DOMAIN=$_ai_domain
            fi
            RESULTS_MODE="search"
            _refresh_results
            ;;
        E:*)
            _ai_index=${_ai_item#E:}
            _ai_id=$(_corpus_field "$_ai_index" 10)
            _abook_recent_add "$_ai_id"
            _abook_settings_save || true
            ;;
    esac
    return 0
}

# _cycle_language
#
# Switch to the next language that has a catalogue.
_cycle_language() {
    _cl_first=""
    _cl_next=""
    _cl_found=0
    for _cl_code in $(_i18n_available); do
        if [ "$_cl_found" -eq 0 ]; then
            _cl_first=$_cl_code
        fi
        if [ "$_cl_found" -eq 1 ]; then
            _cl_next=$_cl_code
            break
        fi
        if [ "$_cl_code" = "$I18N_LANG" ]; then
            _cl_found=1
        fi
    done
    [ -n "$_cl_next" ] || _cl_next=$_cl_first
    [ -n "$_cl_next" ] || return 0
    _i18n_load "$_cl_next" || true
    SETTINGS_LANGUAGE=$I18N_LANG
    return 0
}

# _handle_input_key
#
# Handle a key that was pressed while a text was being typed.
_handle_input_key() {
    case "$UI_KEY" in
        "$ABOOK_ENTER"|"$ABOOK_NEWLINE")
            case "$INPUT_MODE" in
                search)
                    RESULTS_MODE="search"
                    _refresh_results
                    INPUT_MODE=""
                    _ui_raw_on
                    ;;
                jump)
                    _jump_commit
                    INPUT_MODE=""
                    _ui_raw_on
                    ;;
                command)
                    _run_command "$CMD"
                    CMD=""
                    INPUT_MODE=""
                    _ui_raw_on
                    ;;
            esac
            return 0
            ;;
        "$ABOOK_BACKSPACE")
            case "$INPUT_MODE" in
                search) QUERY=$(_abook_chop_last "$QUERY") ;;
                jump) JUMP_QUERY=$(_abook_chop_last "$JUMP_QUERY") ;;
                command) CMD=$(_abook_chop_last "$CMD") ;;
            esac
            return 0
            ;;
        "$ABOOK_CTRL_U")
            case "$INPUT_MODE" in
                search) QUERY="" ;;
                jump) JUMP_QUERY="" ;;
                command) CMD="" ;;
            esac
            return 0
            ;;
        "$ABOOK_ESC")
            INPUT_MODE=""
            _ui_raw_on
            return 0
            ;;
        "$ABOOK_CTRL_C"|"$ABOOK_CTRL_Q")
            _QUIT=1
            return 0
            ;;
        *)
            ;;
    esac
    # A character that can be typed.  A control character is not one, but a
    # character that is written in more than one byte is.
    case "$UI_KEY" in
        "") return 0 ;;
        *[[:cntrl:]]*) return 0 ;;
    esac
    case "$INPUT_MODE" in
        search) QUERY="$QUERY$UI_KEY" ;;
        jump) JUMP_QUERY="$JUMP_QUERY$UI_KEY" ;;
        command) CMD="$CMD$UI_KEY" ;;
    esac
    return 0
}

# _jump_commit
#
# Leave the quick jump palette and go to the entry that was picked.
_jump_commit() {
    _jc_item=$(_left_item "$CURSOR")
    case "$_jc_item" in
        E:*)
            _jc_index=${_jc_item#E:}
            RESULTS_MODE="search"
            JUMP_QUERY=""
            _search_run ""
            LEFT_DIRTY=1
            _build_left
            _select_index "$_jc_index"
            ;;
    esac
    return 0
}

# --------------------------------------------------------------------------
# The main loop
# --------------------------------------------------------------------------

# _cleanup
#
# Put the terminal back the way it was found.  The function is only called
# through a trap.
# shellcheck disable=SC2317
_cleanup() {
    _ui_raw_off
    _ui_show_cursor
    printf '\n'
    return 0
}

# _run_interactive
#
# Open the reader.
_run_interactive() {
    _need_tty
    _find_root
    _abook_detect_utf8
    _abook_detect_color
    _abook_measure_terminal
    _theme_set "${SETTINGS_THEME:-dark}"
    _i18n_load_fallback
    _i18n_load "${SETTINGS_LANGUAGE:-en}" || true

    _spinner_start "$(t loading)"
    _corpus_load "$ABOOK_ROOT"
    _spinner_stop

    if [ "$CORPUS_COUNT" -eq 0 ]; then
        _die "$(t corpus_empty)"
    fi

    DOMAIN_ROWS=$(_corpus_domain_rows)
    DOMAIN_COUNT=$(printf '%s\n' "$DOMAIN_ROWS" | grep -c . || true)
    _layout_compute
    _refresh_results
    _build_left
    CURSOR=$((DOMAIN_COUNT + 1))
    [ "$CURSOR" -gt "$ITEM_COUNT" ] && CURSOR=$ITEM_COUNT
    [ "$CURSOR" -lt 1 ] && CURSOR=1
    _scroll_to_cursor

    trap '_cleanup' EXIT
    trap '_cleanup; exit 0' INT
    trap '_cleanup; exit 0' TERM

    _ui_clear
    _ui_hide_cursor
    _ui_raw_on

    _ri_redraw=1
    while [ "$_QUIT" -eq 0 ]; do
        if [ "$_ri_redraw" -eq 1 ]; then
            _layout_compute
            if [ "$LEFT_DIRTY" -eq 1 ]; then
                _build_left
            fi
            if [ "$CURSOR" -gt "$ITEM_COUNT" ]; then
                CURSOR=$ITEM_COUNT
            fi
            [ "$CURSOR" -lt 1 ] && CURSOR=1
            _scroll_to_cursor
            _build_right
            _build_status
            _render_frame "$LEFT_CONTENT" "$RIGHT_CONTENT" "$LEFT_SCROLL" "$RIGHT_SCROLL" \
                "$SELECTED_ROW" "$STATUS_TEXT" "$SEARCH_TEXT" "$COMMAND_TEXT"
            if [ -n "$OVERLAY" ]; then
                case "$OVERLAY" in
                    help) _render_overlay "$(t help)" "$(_help_body)" ;;
                    *) _render_overlay "$(t about)" "$(_about_body)" ;;
                esac
            fi
            if [ "$INPUT_MODE" = "search" ] || [ "$INPUT_MODE" = "jump" ]; then
                _ui_move "$LAYOUT_SEARCH_ROW" "$((4 + $(_display_width "$(t search): ")))"
                _ui_show_cursor
            elif [ "$INPUT_MODE" = "command" ]; then
                _ui_move "$LAYOUT_COMMAND_ROW" 3
                _ui_show_cursor
            else
                _ui_hide_cursor
            fi
            _ri_redraw=0
        fi
        if [ -n "$INPUT_MODE" ]; then
            _ui_read_char || continue
        else
            _ui_read_key 0 || continue
        fi
        if [ -n "$OVERLAY" ]; then
            OVERLAY=""
        elif [ -n "$INPUT_MODE" ]; then
            _handle_input_key
            if [ "$INPUT_MODE" = "search" ]; then
                RESULTS_MODE="search"
                _refresh_results
                CURSOR=$((DOMAIN_COUNT + 1))
                [ "$CURSOR" -gt "$ITEM_COUNT" ] && CURSOR=$ITEM_COUNT
                [ "$CURSOR" -lt 1 ] && CURSOR=1
                RIGHT_SCROLL=0
            elif [ "$INPUT_MODE" = "jump" ]; then
                _search_quick_jump "$JUMP_QUERY"
                LEFT_DIRTY=1
                CURSOR=$((DOMAIN_COUNT + 1))
                [ "$CURSOR" -gt "$ITEM_COUNT" ] && CURSOR=$ITEM_COUNT
                [ "$CURSOR" -lt 1 ] && CURSOR=1
                RIGHT_SCROLL=0
            fi
        else
            _handle_navigation_key
        fi
        _ri_redraw=1
    done

    _abook_settings_save || true
    _ui_raw_off
    _ui_show_cursor
    printf '\n'
    trap - EXIT INT TERM
    return 0
}

# --------------------------------------------------------------------------
# The self test
# --------------------------------------------------------------------------

# _check <name> <status> <detail>
#
# Record the outcome of one check of the self test.  A status of 0 means
# that the check passed.
_check() {
    _ck_name=$1
    _ck_ok=$2
    _ck_detail=$3
    if [ "$_ck_ok" -eq 0 ]; then
        _CHECKS_PASSED=$((_CHECKS_PASSED + 1))
        printf '  [ ok ] %s\n' "$_ck_name"
    else
        _CHECKS_FAILED=$((_CHECKS_FAILED + 1))
        printf '  [FAIL] %s\n' "$_ck_name"
    fi
    if [ -n "$_ck_detail" ]; then
        printf '         %s\n' "$_ck_detail"
    fi
    return 0
}

# _check_metadata
#
# Check that every entry of the corpus has the metadata the reader needs.
_check_metadata() {
    [ -f "$CORPUS_INDEX_FILE" ] || return 1
    if awk -F'\t' '
        NF < 8 { missing = 1 }
        $2 == "" { missing = 1 }
        $4 == "" { missing = 1 }
        END { exit (missing ? 1 : 0) }
    ' "$CORPUS_INDEX_FILE"; then
        return 0
    fi
    return 1
}

# _run_selftest
#
# Run the built in checks and print a report.  This is how the reader is
# verified on a machine without a terminal.
_run_selftest() {
    _find_root
    printf 'abook shell reader - self test\n'
    printf '  version: %s\n' "$ABOOK_VERSION"
    printf '  repository: %s\n' "$ABOOK_ROOT"

    _abook_detect_utf8
    _abook_detect_color
    _theme_set "${SETTINGS_THEME:-dark}"
    _i18n_load_fallback
    _i18n_load "${SETTINGS_LANGUAGE:-en}" || true

    _corpus_load "$ABOOK_ROOT"
    DOMAIN_ROWS=$(_corpus_domain_rows)
    DOMAIN_COUNT=$(printf '%s\n' "$DOMAIN_ROWS" | grep -c . || true)

    _check "repository found" 0 "$ABOOK_ROOT"
    _check "corpus loaded" "$([ "$CORPUS_COUNT" -gt 0 ] && echo 0 || echo 1)" "$CORPUS_COUNT entries from $ABOOK_INDEX_SOURCE"
    _check "sixteen domains" "$([ "$DOMAIN_COUNT" -eq 16 ] && echo 0 || echo 1)" "$DOMAIN_COUNT domains"
    if _check_metadata; then
        _cm_status=0
    else
        _cm_status=1
    fi
    _check "every entry has metadata" "$_cm_status" "title, domain, safety and difficulty"
    _cm_tags=$(_corpus_field 1 9 2>/dev/null || printf '')
    _check "entries carry their tags" "$([ -n "$_cm_tags" ] && echo 0 || echo 1)" "first entry: $_cm_tags"

    # The YAML parser.
    _self_sidecar="$ABOOK_ROOT/$ABOOK_SIDECARS_DIRNAME/survival/making-fire.pnk.yaml"
    _self_yaml=$(_corpus_yaml_get "$_self_sidecar" "title" 2>/dev/null || printf '')
    _check "yaml parser" "$([ "$_self_yaml" = "Making Fire" ] && echo 0 || echo 1)" "title = $_self_yaml"
    _self_yaml2=$(_corpus_yaml_get "$_self_sidecar" "verification.status" 2>/dev/null || printf '')
    _check "yaml nested mapping" "$([ "$_self_yaml2" = "draft" ] && echo 0 || echo 1)" "verification.status = $_self_yaml2"
    _self_yaml3=$(_corpus_yaml_get "$_self_sidecar" "tags.1" 2>/dev/null || printf '')
    _check "yaml inline list" "$([ -n "$_self_yaml3" ] && echo 0 || echo 1)" "tags.1 = $_self_yaml3"
    _self_yaml4=$(_corpus_yaml_get "$_self_sidecar" "sources.0.title" 2>/dev/null || printf '')
    _check "yaml sequence of mappings" "$([ -n "$_self_yaml4" ] && echo 0 || echo 1)" "sources.0.title = $_self_yaml4"

    # The search.
    _search_run "water purification"
    _check "search finds entries" "$([ "$SEARCH_COUNT" -gt 0 ] && echo 0 || echo 1)" "$SEARCH_COUNT results"
    _self_first=$(printf '%s\n' "$SEARCH_RESULTS" | head -n 1 | cut -f4)
    _self_tier=$(printf '%s\n' "$SEARCH_RESULTS" | head -n 1 | cut -f1)
    _check "title matches rank first" "$(printf '%s' "$_self_first" | grep -qi "water purif" && echo 0 || echo 1)" "best: $_self_first"
    _check "title tier" "$([ "$_self_tier" = "3" ] && echo 0 || echo 1)" "tier $_self_tier"

    FILTER_DOMAIN="survival"
    _search_run "aid"
    _self_domains=$(printf '%s\n' "$SEARCH_RESULTS" | cut -f3 | sort -u | tr '\n' ' ')
    _check "domain filter" "$(printf '%s' "$_self_domains" | grep -q "survival" && echo 0 || echo 1)" "domains: ${_self_domains:-none}"
    FILTER_DOMAIN=""

    FILTER_SAFETY="red"
    _search_run ""
    _self_safety=$(printf '%s\n' "$SEARCH_RESULTS" | cut -f1 | sort -u | tr '\n' ' ')
    _check "safety filter" "$([ "$SEARCH_COUNT" -gt 0 ] && echo 0 || echo 1)" "$SEARCH_COUNT entries, tiers $_self_safety"
    FILTER_SAFETY=""

    FILTER_DIFFICULTY="master"
    _search_run ""
    _check "difficulty filter" "$([ "$SEARCH_COUNT" -gt 0 ] && echo 0 || echo 1)" "$SEARCH_COUNT entries"
    FILTER_DIFFICULTY=""

    _search_run "zzzzznotanentry"
    _check "no match" "$([ "$SEARCH_COUNT" -eq 0 ] && echo 0 || echo 1)" "$SEARCH_COUNT results"
    _search_run ""

    # The translations.
    _self_english=$(_i18n_get site_name)
    _i18n_load "zz" || true
    _check "language fallback" "$([ "$I18N_LANG" = "en" ] && echo 0 || echo 1)" "fell back to $I18N_LANG"
    _check "fallback string" "$([ "$(_i18n_get site_name)" = "$_self_english" ] && echo 0 || echo 1)" "$(_i18n_get site_name)"
    _i18n_load "fr" || true
    _check "translation loaded" "$([ -n "$(_i18n_get site_name)" ] && echo 0 || echo 1)" "$(_i18n_get site_name)"
    _i18n_load "en" || true
    _self_lang_count=$(_i18n_available | grep -c . || true)
    _check "languages offered" "$([ "$_self_lang_count" -ge 9 ] && echo 0 || echo 1)" "$(_i18n_available | tr '\n' ' ')"

    # The disclaimer.
    _self_disclaimer=$(_corpus_disclaimer 2>/dev/null || printf '')
    _check "disclaimer quoted" "$(printf '%s' "$_self_disclaimer" | grep -q "Reference and education only" && echo 0 || echo 1)" "${#_self_disclaimer} characters"

    # The version.
    _self_built=$(_corpus_built_version 2>/dev/null || printf '')
    if [ -n "$_self_built" ]; then
        _check "version matches the build" "$([ "$(_abook_version_cmp "$ABOOK_VERSION" "$_self_built")" = "0" ] && echo 0 || echo 1)" "$ABOOK_VERSION vs $_self_built"
    fi
    _self_cmp=$(_abook_version_cmp "0.1.0-alpha" "0.1.0-alpha")
    _check "version comparison, equal" "$([ "$_self_cmp" = "0" ] && echo 0 || echo 1)" "0.1.0-alpha vs 0.1.0-alpha = $_self_cmp"
    _self_cmp=$(_abook_version_cmp "0.1.0-alpha" "0.1.0")
    _check "version comparison, pre-release" "$([ "$_self_cmp" = "-1" ] && echo 0 || echo 1)" "0.1.0-alpha vs 0.1.0 = $_self_cmp"
    _self_cmp=$(_abook_version_cmp "0.2.0" "0.1.9")
    _check "version comparison, newer" "$([ "$_self_cmp" = "1" ] && echo 0 || echo 1)" "0.2.0 vs 0.1.9 = $_self_cmp"

    printf '\n'
    if [ "$_CHECKS_FAILED" -gt 0 ]; then
        printf '%s check(s) failed, %s passed\n' "$_CHECKS_FAILED" "$_CHECKS_PASSED"
        return 1
    fi
    printf 'all %s checks passed\n' "$_CHECKS_PASSED"
    return 0
}

# --------------------------------------------------------------------------
# The entry point
# --------------------------------------------------------------------------

# _parse_arguments <arguments>
#
# Read the command line.
_parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --selftest)
                MODE="selftest"
                shift
                ;;
            --version)
                MODE="version"
                shift
                ;;
            --help|-h)
                MODE="help"
                shift
                ;;
            --root)
                shift
                [ $# -gt 0 ] || _die "--root needs a directory"
                ROOT_OPTION=$1
                shift
                ;;
            --root=*)
                ROOT_OPTION=${1#--root=}
                shift
                ;;
            --lang)
                shift
                [ $# -gt 0 ] || _die "--lang needs a language code"
                LANG_OPTION=$1
                shift
                ;;
            --lang=*)
                LANG_OPTION=${1#--lang=}
                shift
                ;;
            --theme)
                shift
                [ $# -gt 0 ] || _die "--theme needs a name"
                THEME_OPTION=$1
                shift
                ;;
            --theme=*)
                THEME_OPTION=${1#--theme=}
                shift
                ;;
            *)
                _die "unknown option: $1"
                ;;
        esac
    done
    return 0
}

#: What the program should do: "ui", "selftest", "version" or "help".
MODE="ui"

_abook_settings_load
if [ -n "$LANG_OPTION" ]; then
    SETTINGS_LANGUAGE=$LANG_OPTION
fi
if [ -n "$THEME_OPTION" ]; then
    SETTINGS_THEME=$THEME_OPTION
fi
_parse_arguments "$@"

case "$MODE" in
    version)
        if ABOOK_ROOT=$(_abook_find_root "$ABOOK_APP_DIR" 2>/dev/null); then
            _abook_load_manifest "$ABOOK_ROOT" || true
        fi
        printf '%s\n' "$ABOOK_VERSION"
        ;;
    help)
        _usage
        ;;
    selftest)
        _run_selftest
        ;;
    *)
        _run_interactive
        ;;
esac
