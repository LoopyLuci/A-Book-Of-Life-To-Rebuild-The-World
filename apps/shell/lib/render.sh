#!/bin/sh
#
# Drawing the interface: the panes, the boxes, the colours and the cursor.
#
# Sourced by abook.sh.  Every line that is drawn carries a one letter kind
# that says how it should be styled:
#
#   N  ordinary text      H  heading        H2 sub heading
#   S  selected row       M  muted text     A  accent text
#   B  bullet             N2 numbered item  Q  quote
#   C  code               R  rule           E  empty line
#   W  warning            D  danger         O  ok
#
# The renderer measures and pads the text itself, so the caller only has to
# build the lines.
#
# Usage:  . "$ABOOK_LIB_DIR/render.sh"

# The constants of this file are read by the other files of the application.
# shellcheck disable=SC2034

if [ -z "${ABOOK_LIB_DIR:-}" ]; then
    printf 'abook: lib/render.sh must be sourced, not executed\n' >&2
    return 1
fi

# --------------------------------------------------------------------------
# Layout
# --------------------------------------------------------------------------

#: The total width of the left pane, borders included.
LAYOUT_LEFT_OUTER=26

#: The width of the text of the left pane.
LAYOUT_LEFT_INNER=24

#: The width of the text of the right pane.
LAYOUT_RIGHT_INNER=52

#: The first row of the panes.
LAYOUT_PANE_TOP=4

#: How many rows the panes have.
LAYOUT_PANE_HEIGHT=16

#: The row of the status bar.
LAYOUT_STATUS_ROW=21

#: The row of the search line.
LAYOUT_SEARCH_ROW=22

#: The row of the command line.
LAYOUT_COMMAND_ROW=23

# _layout_compute
#
# Work out the geometry of the interface from the size of the terminal.
_layout_compute() {
    _lc_left=$((ABOOK_COLS / 3))
    [ "$_lc_left" -lt 24 ] && _lc_left=24
    [ "$_lc_left" -gt 40 ] && _lc_left=40
    [ "$_lc_left" -ge "$ABOOK_COLS" ] && _lc_left=$((ABOOK_COLS - 10))
    [ "$_lc_left" -lt 12 ] && _lc_left=12
    LAYOUT_LEFT_OUTER=$_lc_left
    LAYOUT_LEFT_INNER=$((_lc_left - 2))
    LAYOUT_RIGHT_INNER=$((ABOOK_COLS - _lc_left - 1))
    [ "$LAYOUT_RIGHT_INNER" -lt 10 ] && LAYOUT_RIGHT_INNER=10
    LAYOUT_PANE_TOP=4
    LAYOUT_PANE_HEIGHT=$((ABOOK_LINES - 8))
    [ "$LAYOUT_PANE_HEIGHT" -lt 3 ] && LAYOUT_PANE_HEIGHT=3
    LAYOUT_STATUS_ROW=$((ABOOK_LINES - 3))
    LAYOUT_SEARCH_ROW=$((ABOOK_LINES - 2))
    LAYOUT_COMMAND_ROW=$((ABOOK_LINES - 1))
    return 0
}

# --------------------------------------------------------------------------
# Terminal control
# --------------------------------------------------------------------------

# _ui_clear
#
# Clear the screen and move the cursor to the top left corner.
_ui_clear() {
    printf '\033[2J\033[H'
    return 0
}

# _ui_home
#
# Move the cursor to the top left corner.
_ui_home() {
    printf '\033[H'
    return 0
}

# _ui_hide_cursor
#
# Hide the cursor.
_ui_hide_cursor() {
    printf '\033[?25l'
    return 0
}

# _ui_show_cursor
#
# Show the cursor.
_ui_show_cursor() {
    printf '\033[?25h'
    return 0
}

# _ui_move <row> <column>
#
# Move the cursor.
_ui_move() {
    printf '\033[%d;%dH' "$1" "$2"
    return 0
}

# _ui_line <row> <text>
#
# Draw one line of the screen from the first column and erase the rest of it.
_ui_line() {
    printf '\033[%d;1H\033[K%s' "$1" "$2"
    return 0
}

# _ui_line_at <row> <column> <text>
#
# Draw one line of the screen from the given column.  The rest of the line is
# left alone, so the two panes can be drawn one after the other.
_ui_line_at() {
    printf '\033[%d;%dH%s' "$1" "$2" "$3"
    return 0
}

# _ui_raw_on
#
# Put the terminal into the mode the key reader needs: no echo, no line
# editing and a short read timeout, so that an escape sequence can be read
# without blocking.
_ui_raw_on() {
    stty -echo -icanon min 0 time 1 2>/dev/null || true
    return 0
}

# _ui_raw_off
#
# Put the terminal back the way it was found.
_ui_raw_off() {
    stty echo icanon 2>/dev/null || true
    return 0
}

# _ui_blocking_on
#
# Put the terminal into the mode the text editor needs: no echo, no line
# editing, but a read that waits for a character.
_ui_blocking_on() {
    stty -echo -icanon min 1 time 0 2>/dev/null || true
    return 0
}

# _ui_read_byte
#
# Read one byte from the terminal and put it in UI_BYTE.  A newline is kept:
# a command substitution would swallow it, so a marker is added to the output
# and removed again.
_ui_read_byte() {
    UI_BYTE=$(dd bs=1 count=1 2>/dev/null; printf 'X')
    UI_BYTE=${UI_BYTE%X}
    [ -n "$UI_BYTE" ] || return 1
    return 0
}

# _ui_read_key <blocking>
#
# Read one key and put it in UI_KEY.  The escape sequences of the arrow keys,
# of PageUp, of PageDown and of F1 are translated into readable names.  When
# blocking is 1 the terminal is expected to be in the blocking mode, and the
# terminal is switched to the short timeout mode while the rest of an escape
# sequence is read, so that a lone Escape never hangs.
_ui_read_key() {
    UI_KEY=""
    _urk_blocking=${1:-0}
    _ui_read_byte || return 1
    _urk=$UI_BYTE
    if [ "$_urk" != "$ABOOK_ESC" ]; then
        UI_KEY="$_urk"
        return 0
    fi
    if [ "$_urk_blocking" -eq 1 ]; then
        stty min 0 time 1 2>/dev/null || true
        _urk_short=1
    else
        _urk_short=0
    fi
    _ui_read_byte || true
    _urk2=$UI_BYTE
    if [ -z "$_urk2" ]; then
        if [ "$_urk_short" -eq 1 ]; then
            stty min 1 time 0 2>/dev/null || true
        fi
        UI_KEY="ESC"
        return 0
    fi
    if [ "$_urk2" != "[" ] && [ "$_urk2" != "O" ]; then
        if [ "$_urk_short" -eq 1 ]; then
            stty min 1 time 0 2>/dev/null || true
        fi
        UI_KEY="ESC"
        return 0
    fi
    _ui_read_byte || true
    _urk3=$UI_BYTE
    case "$_urk3" in
        A) UI_KEY="UP" ;;
        B) UI_KEY="DOWN" ;;
        C) UI_KEY="RIGHT" ;;
        D) UI_KEY="LEFT" ;;
        H) UI_KEY="HOME" ;;
        F) UI_KEY="END" ;;
        P) UI_KEY="F1" ;;
        1)
            _ui_read_byte || true
            if [ "$UI_BYTE" = "~" ]; then
                UI_KEY="HOME"
            else
                _ui_read_byte || true
                if [ "$UI_BYTE" = "~" ]; then
                    UI_KEY="F1"
                else
                    UI_KEY="ESC"
                fi
            fi
            ;;
        4)
            _ui_read_byte || true
            case "$UI_BYTE" in
                "~") UI_KEY="END" ;;
                *) UI_KEY="ESC" ;;
            esac
            ;;
        5)
            _ui_read_byte || true
            case "$UI_BYTE" in
                "~") UI_KEY="PGUP" ;;
                *) UI_KEY="ESC" ;;
            esac
            ;;
        6)
            _ui_read_byte || true
            case "$UI_BYTE" in
                "~") UI_KEY="PGDN" ;;
                *) UI_KEY="ESC" ;;
            esac
            ;;
        7)
            _ui_read_byte || true
            case "$UI_BYTE" in
                "~") UI_KEY="HOME" ;;
                *) UI_KEY="ESC" ;;
            esac
            ;;
        *) UI_KEY="ESC" ;;
    esac
    if [ "$_urk_short" -eq 1 ]; then
        stty min 1 time 0 2>/dev/null || true
    fi
    return 0
}

# _ui_read_char
#
# Read one character and put it in UI_KEY.  A multi byte character is read
# as a whole, so that a search can be typed in any language.
_ui_read_char() {
    UI_KEY=""
    _ui_read_byte || return 1
    _uic=$UI_BYTE
    _uic_val=$(printf '%d' "'$_uic" 2>/dev/null || printf 0)
    case "$_uic_val" in
        ''|*[!0-9]*) _uic_val=0 ;;
    esac
    if [ "$_uic_val" -lt 128 ]; then
        UI_KEY="$_uic"
        return 0
    fi
    UI_KEY="$_uic"
    while :; do
        _ui_read_byte || break
        UI_KEY="$UI_KEY$UI_BYTE"
        _uic_val=$(printf '%d' "'$UI_BYTE" 2>/dev/null || printf 0)
        case "$_uic_val" in
            ''|*[!0-9]*) _uic_val=0 ;;
        esac
        if [ "$_uic_val" -lt 128 ] || [ "$_uic_val" -gt 191 ]; then
            break
        fi
    done
    return 0
}

# --------------------------------------------------------------------------
# Styles
# --------------------------------------------------------------------------

# _style_of <kind>
#
# Print the style of a line kind.
_style_of() {
    case "$1" in
        H)  printf '%s' "$C_ACCENT" ;;
        H2) printf '%s' "$C_MUTED" ;;
        S)  printf '%s' "$C_SELECT_ACCENT" ;;
        M)  printf '%s' "$C_MUTED" ;;
        A)  printf '%s' "$C_ACCENT" ;;
        B)  printf '%s' "$C_ACCENT" ;;
        N2) printf '%s' "$C_ACCENT" ;;
        Q)  printf '%s' "$C_MUTED" ;;
        C)  printf '%s' "$C_OK" ;;
        R)  printf '%s' "$C_BORDER" ;;
        E)  printf '%s' "" ;;
        W)  printf '%s' "$C_WARN" ;;
        D)  printf '%s' "$C_DANGER" ;;
        O)  printf '%s' "$C_OK" ;;
        *)  printf '%s' "$C_FG" ;;
    esac
    return 0
}

# _display_width <text>
#
# Print the width of a text in characters.  This counts characters and not
# bytes, so a translated string lines up with the border of a pane.
_display_width() {
    printf '%s' "$1" | wc -m | tr -d ' \t\n'
    return 0
}

# _spaces <count>
#
# Print a number of blanks.
_spaces() {
    _sp_i=0
    while [ "$_sp_i" -lt "$1" ]; do
        printf ' '
        _sp_i=$((_sp_i + 1))
    done
    return 0
}

# _measure_lines <content>
#
# Measure every line of a block of content and print the width of the text
# of each line in front of it, separated by a tab.  The width is counted in
# characters, so that a line with an accent or an em dash lines up with the
# border of its pane.
_measure_lines() {
    printf '%s\n' "$1" | awk '{
        kind = substr($0, 1, 1)
        text = substr($0, 3)
        printf("%d\t%s|%s\n", length(text), kind, text)
    }'
    return 0
}

# _draw_pane_line <kind> <text> <width> <text-width>
#
# Draw one line of a pane: the text is padded to the width and styled.  The
# width of the text is given by the caller, because it is measured in
# characters by the renderer and not in bytes by the shell.
_draw_pane_line() {
    _dpl_kind=$1
    _dpl_text=$2
    _dpl_width=$3
    _dpl_len=$4
    if [ "$_dpl_len" -le 0 ]; then
        _dpl_len=$(_display_width "$_dpl_text")
    fi
    if [ "$_dpl_len" -gt "$_dpl_width" ]; then
        _dpl_text=$(printf '%s' "$_dpl_text" | cut -c1-"$((_dpl_width - 1))")
        _dpl_text="$_dpl_text$ELLIPSIS"
        _dpl_len=$(_display_width "$_dpl_text")
    fi
    _dpl_style=$(_style_of "$_dpl_kind")
    _dpl_fill=$((_dpl_width - _dpl_len))
    if [ "$ABOOK_COLOR" -eq 0 ]; then
        printf '%s' "$_dpl_text"
        _spaces "$_dpl_fill"
    else
        printf '\033[%sm%s' "$_dpl_style" "$_dpl_text"
        _spaces "$_dpl_fill"
        printf '\033[0m'
    fi
    return 0
}

# _draw_full_line <kind> <text>
#
# Draw one line that spans the whole width of the frame.  The width is
# measured in characters, so translated strings line up.
_draw_full_line() {
    _dfl_kind=$1
    _dfl_text=$2
    _dfl_width=$((ABOOK_COLS - 2))
    _dfl_len=$(_display_width "$_dfl_text")
    if [ "$_dfl_len" -gt "$_dfl_width" ]; then
        _dfl_text=$(printf '%s' "$_dfl_text" | cut -c1-"$((_dfl_width - 1))")
        _dfl_text="$_dfl_text$ELLIPSIS"
        _dfl_len=$(_display_width "$_dfl_text")
    fi
    _dfl_style=$(_style_of "$_dfl_kind")
    _dfl_fill=$((_dfl_width - _dfl_len))
    if [ "$ABOOK_COLOR" -eq 0 ]; then
        printf '%s' "$_dfl_text"
        _spaces "$_dfl_fill"
    else
        printf '\033[%sm%s' "$_dfl_style" "$_dfl_text"
        _spaces "$_dfl_fill"
        printf '\033[0m'
    fi
    return 0
}

# --------------------------------------------------------------------------
# The frame
# --------------------------------------------------------------------------

# _render_frame <left> <right> <left-scroll> <right-scroll> <selected-row> <status> <search> <command>
#
# Draw the whole interface.  The panes of content are newline separated
# strings whose lines start with a kind letter.  The row of the left pane
# that is selected is drawn in the selection style.
_render_frame() {
    _rf_left=$1
    _rf_right=$2
    _rf_lscroll=$3
    _rf_rscroll=$4
    _rf_selected=$5
    _rf_status=$6
    _rf_search=$7
    _rf_command=$8

    _ui_home

    # The top border of the frame.
    _rf_border=""
    _rf_count=$((ABOOK_COLS - 2))
    while [ "$_rf_count" -gt 0 ]; do
        _rf_border="$_rf_border$BOX_H"
        _rf_count=$((_rf_count - 1))
    done
    _ui_line 1 "$BOX_TL$_rf_border$BOX_TR"

    # The title bar.
    _rf_title=" $(t site_name) "
    _rf_meta="v$ABOOK_VERSION  $(_i18n_name "$I18N_LANG")  [$THEME_NAME] "
    _rf_fill=$((ABOOK_COLS - 2 - $(_display_width "$_rf_title") - $(_display_width "$_rf_meta")))
    [ "$_rf_fill" -lt 1 ] && _rf_fill=1
    _ui_line 2 "$BOX_V$(_c "$C_TITLE" "$_rf_title")$(_c "$C_MUTED" "$(_spaces "$_rf_fill")$_rf_meta")$BOX_V"

    # The separator above the panes.
    _rf_sep=""
    _rf_count=0
    while [ "$_rf_count" -lt "$LAYOUT_LEFT_INNER" ]; do
        _rf_sep="$_rf_sep$BOX_H"
        _rf_count=$((_rf_count + 1))
    done
    _rf_sep2=""
    _rf_count=0
    while [ "$_rf_count" -lt "$LAYOUT_RIGHT_INNER" ]; do
        _rf_sep2="$_rf_sep2$BOX_H"
        _rf_count=$((_rf_count + 1))
    done
    _ui_line 3 "$BOX_LT$_rf_sep$BOX_T$_rf_sep2$BOX_RT"

    # The right pane, drawn first because it clears the rest of the line.
    _rf_rtop=$((_rf_rscroll + 1))
    _rf_rbot=$((_rf_rscroll + LAYOUT_PANE_HEIGHT))
    _rf_slice=$(printf '%s\n' "$_rf_right" | sed -n "${_rf_rtop},${_rf_rbot}p")
    _rf_slice=$(_measure_lines "$_rf_slice")
    _rf_row=$LAYOUT_PANE_TOP
    while IFS="$ABOOK_TAB" read -r _rf_width _rf_item; do
        _rf_kind=${_rf_item%%|*}
        _rf_text=${_rf_item#*|}
        _ui_line_at "$_rf_row" "$((LAYOUT_LEFT_OUTER + 1))" "$(_draw_pane_line "$_rf_kind" "$_rf_text" "$LAYOUT_RIGHT_INNER" "$_rf_width")$BOX_V"
        _rf_row=$((_rf_row + 1))
    done <<ABOOK_RIGHT_EOF
$_rf_slice
ABOOK_RIGHT_EOF
    while [ "$_rf_row" -lt $((LAYOUT_PANE_TOP + LAYOUT_PANE_HEIGHT)) ]; do
        _ui_line_at "$_rf_row" "$((LAYOUT_LEFT_OUTER + 1))" "$(_draw_pane_line N "" "$LAYOUT_RIGHT_INNER" 0)$BOX_V"
        _rf_row=$((_rf_row + 1))
    done

    # The left pane.
    _rf_ltop=$((_rf_lscroll + 1))
    _rf_lbot=$((_rf_lscroll + LAYOUT_PANE_HEIGHT))
    _rf_slice=$(printf '%s\n' "$_rf_left" | sed -n "${_rf_ltop},${_rf_lbot}p")
    _rf_slice=$(_measure_lines "$_rf_slice")
    _rf_row=$LAYOUT_PANE_TOP
    _rf_index=0
    while IFS="$ABOOK_TAB" read -r _rf_width _rf_item; do
        _rf_index=$((_rf_index + 1))
        _rf_kind=${_rf_item%%|*}
        _rf_text=${_rf_item#*|}
        if [ "$_rf_index" -eq "$_rf_selected" ]; then
            _rf_kind="S"
            _rf_text="$MARK_CURSOR${_rf_text#?}"
        fi
        _ui_line_at "$_rf_row" 1 "$BOX_V$(_draw_pane_line "$_rf_kind" "$_rf_text" "$LAYOUT_LEFT_INNER" "$_rf_width")$BOX_V"
        _rf_row=$((_rf_row + 1))
    done <<ABOOK_LEFT_EOF
$_rf_slice
ABOOK_LEFT_EOF
    while [ "$_rf_row" -lt $((LAYOUT_PANE_TOP + LAYOUT_PANE_HEIGHT)) ]; do
        _ui_line_at "$_rf_row" 1 "$BOX_V$(_draw_pane_line N "" "$LAYOUT_LEFT_INNER" 0)$BOX_V"
        _rf_row=$((_rf_row + 1))
    done

    # The separator below the panes.
    _ui_line "$((LAYOUT_PANE_TOP + LAYOUT_PANE_HEIGHT))" "$BOX_LB$_rf_sep$BOX_B$_rf_sep2$BOX_RB"

    # The status bar, the search line and the command line.
    _ui_line "$LAYOUT_STATUS_ROW" "$BOX_V$(_draw_full_line N "$_rf_status")$BOX_V"
    _ui_line "$LAYOUT_SEARCH_ROW" "$BOX_V$(_draw_full_line N "$_rf_search")$BOX_V"
    _ui_line "$LAYOUT_COMMAND_ROW" "$BOX_V$(_draw_full_line N "$_rf_command")$BOX_V"

    # The bottom border of the frame.
    _ui_line "$ABOOK_LINES" "$BOX_BL$_rf_border$BOX_BR"

    return 0
}

# _render_overlay <title> <body>
#
# Draw a box in the middle of the screen, over the frame.
_render_overlay() {
    _ro_title=$1
    _ro_body=$2
    _ro_width=$((ABOOK_COLS - 6))
    [ "$_ro_width" -gt 96 ] && _ro_width=96
    [ "$_ro_width" -lt 24 ] && _ro_width=24
    _ro_inner=$((_ro_width - 4))
    _ro_lines=$(printf '%s\n' "$_ro_body" | wc -l | tr -d ' \t\n')
    _ro_height=$((_ro_lines + 4))
    [ "$_ro_height" -gt $((ABOOK_LINES - 2)) ] && _ro_height=$((ABOOK_LINES - 2))
    _ro_top=$(((ABOOK_LINES - _ro_height) / 2 + 1))
    _ro_left=$(((ABOOK_COLS - _ro_width) / 2 + 1))

    _ro_border=""
    _ro_count=0
    while [ "$_ro_count" -lt "$_ro_inner" ]; do
        _ro_border="$_ro_border$BOX_H"
        _ro_count=$((_ro_count + 1))
    done
    _ui_move "$_ro_top" "$_ro_left"
    printf '%s' "$BOX_TL$_ro_border$BOX_TR"
    _ui_move "$((_ro_top + 1))" "$_ro_left"
    printf '%s' "$BOX_V $(_c "$C_ACCENT" "$_ro_title")"
    _spaces "$_ro_inner"
    printf '%s' " $BOX_V"

    _ro_row=$((_ro_top + 2))
    _ro_index=0
    while IFS= read -r _ro_item; do
        _ro_index=$((_ro_index + 1))
        if [ "$_ro_index" -gt "$_ro_lines" ]; then
            break
        fi
        _ui_move "$_ro_row" "$_ro_left"
        printf '%s' "$BOX_V "
        _ro_text=$_ro_item
        _ro_style=$C_FG
        case "$_ro_text" in
            "!|"*) _ro_style=$C_ERROR; _ro_text=${_ro_text#*|} ;;
            "M|"*) _ro_style=$C_MUTED; _ro_text=${_ro_text#*|} ;;
            ">|"*) _ro_style=$C_ACCENT; _ro_text=${_ro_text#*>|} ;;
        esac
        _ro_len=$(_display_width "$_ro_text")
        if [ "$_ro_len" -gt "$_ro_inner" ]; then
            _ro_text=$(printf '%s' "$_ro_text" | cut -c1-"$((_ro_inner - 1))")
            _ro_len=$(_display_width "$_ro_text")
        fi
        printf '%s' "$(_c "$_ro_style" "$_ro_text")"
        _spaces "$((_ro_inner - _ro_len))"
        printf '%s' " $BOX_V"
        _ro_row=$((_ro_row + 1))
    done <<ABOOK_OVERLAY_EOF
$_ro_body
ABOOK_OVERLAY_EOF

    _ui_move "$_ro_row" "$_ro_left"
    printf '%s' "$BOX_BL$_ro_border$BOX_BR"
    return 0
}

# --------------------------------------------------------------------------
# The spinner
# --------------------------------------------------------------------------

#: The process id of the spinner.
_SPINNER_PID=""

# _spinner_start <message>
#
# Show a spinner until _spinner_stop is called.  Nothing happens when the
# output is not a terminal.
_spinner_start() {
    _sps_message=$1
    [ -t 1 ] || return 0
    if [ -z "${ABOOK_SLEEP:-}" ]; then
        if sleep 0.05 2>/dev/null; then
            ABOOK_SLEEP="sleep 0.08"
        else
            ABOOK_SLEEP="sleep 1"
        fi
    fi
    (
        _sps_i=0
        while :; do
            case $((_sps_i % 4)) in
                0) _sps_frame="|" ;;
                1) _sps_frame="/" ;;
                2) _sps_frame="-" ;;
                *) _sps_frame="\\" ;;
            esac
            printf '\r\033[K%s %s' "$_sps_message" "$_sps_frame"
            _sps_i=$((_sps_i + 1))
            $ABOOK_SLEEP
        done
    ) &
    _SPINNER_PID=$!
    return 0
}

# _spinner_stop
#
# Stop the spinner and clear the line it was drawn on.
_spinner_stop() {
    [ -n "${_SPINNER_PID:-}" ] || return 0
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    if [ -t 1 ]; then
        printf '\r\033[K'
    fi
    return 0
}

# --------------------------------------------------------------------------
# The Markdown renderer
# --------------------------------------------------------------------------

# The renderer turns a Markdown body into the "kind<TAB>text" lines the
# interface draws.  It understands the subset of Markdown the entries use:
# headings, bullet and numbered lists, block quotes, horizontal rules, fenced
# code blocks, emphasis and links.
# shellcheck disable=SC2016
ABOOK_MARKDOWN_AWK='
function trim(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}

function strip_inline(s) {
    # The markers of the inline markup are removed instead of being replaced
    # by what they enclose: a backreference in the replacement of gsub is
    # not portable between the versions of awk.
    gsub(/\]\([^)]*\)/, "", s)
    gsub(/\[/, "", s)
    gsub(/\]/, "", s)
    gsub(/\*\*/, "", s)
    gsub(/\*/, "", s)
    gsub(/`/, "", s)
    return s
}

function emit(kind, text, prefix,   words, n, i, cur, first, room) {
    if (kind == "E" || kind == "R") {
        printf("%s|%s\n", kind, text)
        return
    }
    room = width - length(prefix)
    if (room < 8) room = 8
    n = split(text, words, " ")
    cur = ""
    first = 1
    for (i = 1; i <= n; i++) {
        if (words[i] == "") continue
        if (cur == "") {
            cur = words[i]
        } else if (length(cur) + 1 + length(words[i]) <= room) {
            cur = cur " " words[i]
        } else {
            printf("%s|%s%s\n", (first ? kind : "T"), prefix, cur)
            first = 0
            cur = words[i]
        }
    }
    if (cur != "") printf("%s|%s%s\n", (first ? kind : "T"), prefix, cur)
}

# The lines of a paragraph are joined before they are wrapped, so that the
# reader does not see the line breaks of the Markdown source.
function flush_para(   i, text) {
    if (npara == 0) return
    text = ""
    for (i = 1; i <= npara; i++) {
        text = text (text == "" ? "" : " ") para[i]
    }
    npara = 0
    emit("T", strip_inline(trim(text)), "")
}

{
    line = $0
    sub(/\r$/, "", line)
    if (incode) {
        if (line ~ /^```/) {
            incode = 0
        } else {
            flush_para()
            emit("C", line, "  ")
        }
        next
    }
    if (line ~ /^```/) { flush_para(); incode = 1; next }
    if (line ~ /^#[ \t]/) { flush_para(); next }
    if (line ~ /^##[ \t]/) {
        flush_para()
        sub(/^##[ \t]*/, "", line)
        emit("H", strip_inline(trim(line)), "")
        next
    }
    if (line ~ /^###[ \t]/) {
        flush_para()
        sub(/^###[ \t]*/, "", line)
        emit("H2", strip_inline(trim(line)), "")
        next
    }
    if (line ~ /^(---|\*\*\*|___)[ \t]*$/) {
        flush_para()
        emit("R", "", "")
        next
    }
    if (line ~ /^[ \t]*[-*+][ \t]+/) {
        flush_para()
        sub(/^[ \t]*[-*+][ \t]+/, "", line)
        emit("B", strip_inline(trim(line)), bullet " ")
        next
    }
    if (line ~ /^[0-9]+[.)][ \t]+/) {
        flush_para()
        sub(/^[0-9]+[.)][ \t]+/, "", line)
        emit("N2", strip_inline(trim(line)), "  ")
        next
    }
    if (line ~ /^[ \t]*>/) {
        flush_para()
        sub(/^[ \t]*>[ \t]?/, "", line)
        emit("Q", strip_inline(trim(line)), "| ")
        next
    }
    if (line ~ /^[ \t]*\|/) {
        flush_para()
        emit("T", strip_inline(trim(line)), "")
        next
    }
    if (trim(line) == "") {
        flush_para()
        emit("E", "", "")
        next
    }
    npara++
    para[npara] = line
}

END {
    flush_para()
}
'

# _render_markdown <file> <width>
#
# Print the lines of a Markdown body, ready to be drawn.
_render_markdown() {
    _rm_file=$1
    _rm_width=$2
    [ -r "$_rm_file" ] || return 1
    awk -v width="$_rm_width" -v bullet="$BULLET" "$ABOOK_MARKDOWN_AWK" "$_rm_file"
    return 0
}
