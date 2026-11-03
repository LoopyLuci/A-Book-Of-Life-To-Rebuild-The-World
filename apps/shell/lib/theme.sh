#!/bin/sh
#
# The light and dark colour palettes and the box drawing characters.
#
# Sourced by abook.sh.  Every widget of the interface is styled from the
# variables defined here, so switching the theme is a matter of calling
# _theme_set again and redrawing.
#
# Usage:  . "$ABOOK_LIB_DIR/theme.sh"

# The constants of this file are read by the other files of the application.
# shellcheck disable=SC2034

if [ -z "${ABOOK_LIB_DIR:-}" ]; then
    printf 'abook: lib/theme.sh must be sourced, not executed\n' >&2
    return 1
fi

# --------------------------------------------------------------------------
# Palette
# --------------------------------------------------------------------------

#: The name of the active theme.
THEME_NAME="dark"

#: The style of ordinary text.
C_FG="39"

#: The style of dimmed text such as hints and counts.
C_MUTED="90"

#: The style of headings and of the accent of the interface.
C_ACCENT="96"

#: The style of the border of a panel.
C_BORDER="90"

#: The style of a selected row.
C_SELECT="7"

#: The style of a selected row that is also the active one.
C_SELECT_ACCENT="1;7"

#: The style of a warning.
C_WARN="93"

#: The style of a danger.
C_DANGER="91"

#: The style of a success.
C_OK="92"

#: The style of the title bar.
C_TITLE="1;97"

#: The style of the status bar.
C_STATUS="1;36"

#: The style of the prompt.
C_PROMPT="1;33"

#: The style of an error.
C_ERROR="1;91"

# --------------------------------------------------------------------------
# Box drawing characters
# --------------------------------------------------------------------------

#: The top left corner of a box.
BOX_TL="+"

#: The top right corner of a box.
BOX_TR="+"

#: The bottom left corner of a box.
BOX_BL="+"

#: The bottom right corner of a box.
BOX_BR="+"

#: A horizontal line.
BOX_H="-"

#: A vertical line.
BOX_V="|"

#: The left tee of a box.
BOX_LT="+"

#: The right tee of a box.
BOX_RT="+"

#: The left bottom tee of a box.
BOX_LB="+"

#: The right bottom tee of a box.
BOX_RB="+"

#: The top tee of a box.
BOX_T="+"

#: The bottom tee of a box.
BOX_B="+"

#: The cross of a box.
BOX_X="+"

#: A full block, used by the progress bar.
BAR_FULL="#"

#: An empty block, used by the progress bar.
BAR_EMPTY="."

#: The bullet of a list item.
BULLET="-"

#: The marker of the cursor.
MARK_CURSOR=">"

#: An ellipsis.
ELLIPSIS="..."

#: The character used for a scrollbar.
SCROLLBAR="|"

# --------------------------------------------------------------------------
# Theme switching
# --------------------------------------------------------------------------

# _theme_set <light|dark>
#
# Load one of the two palettes.  An unknown name loads the dark theme.
_theme_set() {
    case "$1" in
        light)
            THEME_NAME="light"
            C_FG="30"
            C_MUTED="90"
            C_ACCENT="34"
            C_BORDER="90"
            C_SELECT="7"
            C_SELECT_ACCENT="1;7"
            C_WARN="33"
            C_DANGER="31"
            C_OK="32"
            C_TITLE="1;34"
            C_STATUS="1;36"
            C_PROMPT="1;33"
            C_ERROR="1;91"
            ;;
        *)
            THEME_NAME="dark"
            C_FG="39"
            C_MUTED="90"
            C_ACCENT="96"
            C_BORDER="90"
            C_SELECT="7"
            C_SELECT_ACCENT="1;7"
            C_WARN="93"
            C_DANGER="91"
            C_OK="92"
            C_TITLE="1;97"
            C_STATUS="1;36"
            C_PROMPT="1;33"
            C_ERROR="1;91"
            ;;
    esac
    _theme_set_characters
    return 0
}

# _theme_set_characters
#
# Pick the box drawing characters.  UTF-8 characters are used when the
# terminal can show them and plain ASCII is used otherwise.
_theme_set_characters() {
    if [ "$ABOOK_UTF8" -eq 1 ]; then
        BOX_TL="┌"; BOX_TR="┐"; BOX_BL="└"; BOX_BR="┘"
        BOX_H="─"; BOX_V="│"
        BOX_LT="├"; BOX_RT="┤"; BOX_LB="┴"; BOX_RB="┘"
        BOX_T="┬"; BOX_B="┴"; BOX_X="┼"
        BAR_FULL="█"; BAR_EMPTY="░"
        BULLET="•"; MARK_CURSOR="▸"; ELLIPSIS="…"; SCROLLBAR="│"
    else
        BOX_TL="+"; BOX_TR="+"; BOX_BL="+"; BOX_BR="+"
        BOX_H="-"; BOX_V="|"
        BOX_LT="+"; BOX_RT="+"; BOX_LB="+"; BOX_RB="+"
        BOX_T="+"; BOX_B="+"; BOX_X="+"
        BAR_FULL="#"; BAR_EMPTY="."
        BULLET="-"; MARK_CURSOR=">"; ELLIPSIS="..."; SCROLLBAR="|"
    fi
    return 0
}

# --------------------------------------------------------------------------
# Styling helpers
# --------------------------------------------------------------------------

# _c <style> <text>
#
# Print the text in the given style.  When the terminal cannot show colour
# the text is printed unchanged.
_c() {
    if [ "$ABOOK_COLOR" -eq 0 ]; then
        printf '%s' "$2"
        return 0
    fi
    printf '\033[%sm%s\033[0m' "$1" "$2"
    return 0
}

# _c_plain <style> <text>
#
# Like _c but the text is printed with a trailing newline.
_c_plain() {
    if [ "$ABOOK_COLOR" -eq 0 ]; then
        printf '%s\n' "$2"
        return 0
    fi
    printf '\033[%sm%s\033[0m\n' "$1" "$2"
    return 0
}

# _trim <text>
#
# Print the text without its leading and trailing blanks.
_trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
    return 0
}

# _pad <text> <width>
#
# Print the text padded with blanks to the given width.  A text that is
# longer than the width is cut and marked with an ellipsis.
_pad() {
    _pad_text=$1
    _pad_width=$2
    _pad_len=${#_pad_text}
    if [ "$_pad_len" -gt "$_pad_width" ]; then
        _pad_cut=$((_pad_width - 1))
        [ "$_pad_cut" -lt 0 ] && _pad_cut=0
        printf '%s%s' "$(printf '%s' "$_pad_text" | cut -c1-"$_pad_cut")" "$ELLIPSIS"
        return 0
    fi
    printf '%s' "$_pad_text"
    _pad_fill=$((_pad_width - _pad_len))
    while [ "$_pad_fill" -gt 0 ]; do
        printf ' '
        _pad_fill=$((_pad_fill - 1))
    done
    return 0
}

# _repeat <text> <count>
#
# Print the text the given number of times.
_repeat() {
    _rp_count=$2
    while [ "$_rp_count" -gt 0 ]; do
        printf '%s' "$1"
        _rp_count=$((_rp_count - 1))
    done
    return 0
}
