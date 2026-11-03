#!/bin/sh
#
# Paths, terminal capabilities and persisted preferences.
#
# This file is sourced by abook.sh before anything else.  It works out where
# the repository lives, where the state of the application is kept, how the
# terminal is measured and how the user preferences are stored.
#
# Usage:  . "$ABOOK_LIB_DIR/config.sh"

# The constants of this file are read by the other files of the application.
# shellcheck disable=SC2034

if [ -z "${ABOOK_LIB_DIR:-}" ]; then
    printf 'abook: lib/config.sh must be sourced, not executed\n' >&2
    return 1
fi

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------

#: The file that marks the root of the repository.
ABOOK_MANIFEST_NAME="manifest.toml"

#: The directory that holds the entry metadata sidecars.
ABOOK_SIDECARS_DIRNAME="sidecars"

#: The directory that holds the Markdown bodies.
ABOOK_DOMAINS_DIRNAME="domains"

#: The suffix of an entry metadata sidecar.
ABOOK_SIDECAR_SUFFIX=".pnk.yaml"

#: The optional pre-built search index, relative to the repository root.
ABOOK_INDEX_RELPATH="build/index.db"

#: The disclaimer document that the about box quotes.
ABOOK_DISCLAIMER_RELPATH="docs/DISCLAIMER.md"

#: The directory that holds the interface translations, relative to the root.
ABOOK_STRINGS_RELDIR="i18n/strings"

#: How many entries the "recently read" list keeps.
ABOOK_RECENT_MAX=25

#: The terminal width used when the terminal cannot be measured.
ABOOK_DEFAULT_COLS=80

#: The terminal height used when the terminal cannot be measured.
ABOOK_DEFAULT_LINES=24

#: A tab, used as the column separator of the corpus index.
ABOOK_TAB=$(printf '\t')

#: The name of the state directory under the home directory.
ABOOK_STATE_DIRNAME=".abook"

# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

#: The directory the application keeps its state in.
ABOOK_STATE_DIR="${ABOOK_HOME:-${HOME:-/tmp}/$ABOOK_STATE_DIRNAME}"

#: The directory the corpus cache is written to.
ABOOK_CACHE_DIR="$ABOOK_STATE_DIR/cache"

#: The file the preferences are written to.
ABOOK_SETTINGS_FILE="$ABOOK_STATE_DIR/settings.json"

#: The repository root, filled in by _abook_find_root.
ABOOK_ROOT=""

#: The version from manifest.toml.
ABOOK_VERSION="unknown"

#: Where the corpus was read from: "index-db" or "scan".
ABOOK_INDEX_SOURCE="scan"

# --------------------------------------------------------------------------
# The POSIX toolchain
# --------------------------------------------------------------------------

# On Windows the reader runs under a POSIX shell (MSYS2, Git Bash, Cygwin), and
# the inherited PATH there usually puts C:\Windows\System32 *before* /usr/bin.
# `sort` and `find` then resolve to the Windows programs of the same name,
# which take different options and print different output; the corpus cache
# comes out empty and every query silently returns nothing. Put the directory
# that holds the POSIX awk in front of PATH once, because it is where the rest
# of the coreutils live.
if command -v awk >/dev/null 2>&1; then
    _cpx_dir=$(CDPATH='' cd -- "$(dirname -- "$(command -v awk)")" 2>/dev/null && pwd)
    if [ -n "$_cpx_dir" ] && [ -x "$_cpx_dir/sort" ] && [ -x "$_cpx_dir/find" ]; then
        # Move the directory to the front, dropping any later copy of it, so
        # sourcing this file twice does not lengthen PATH.
        _cpx_rest=""
        _cpx_ifs=$IFS
        IFS=:
        for _cpx_entry in $PATH; do
            [ "$_cpx_entry" = "$_cpx_dir" ] && continue
            if [ -n "$_cpx_rest" ]; then
                _cpx_rest="$_cpx_rest:$_cpx_entry"
            else
                _cpx_rest=$_cpx_entry
            fi
        done
        IFS=$_cpx_ifs
        PATH="$_cpx_dir:$_cpx_rest"
        export PATH
        unset _cpx_rest _cpx_ifs _cpx_entry
    fi
    unset _cpx_dir
fi

# --------------------------------------------------------------------------
# Repository discovery
# --------------------------------------------------------------------------

# _abook_find_root <start-directory>
#
# Walk up from the given directory until manifest.toml is found and print the
# directory that holds it.  Prints nothing and fails when there is none, so
# the application can be started from any working directory.
_abook_find_root() {
    _afr_dir=$1
    [ -n "$_afr_dir" ] || _afr_dir=$PWD
    _afr_dir=$(CDPATH='' cd -- "$_afr_dir" 2>/dev/null && pwd) || return 1
    while [ -n "$_afr_dir" ]; do
        if [ -f "$_afr_dir/$ABOOK_MANIFEST_NAME" ]; then
            printf '%s\n' "$_afr_dir"
            return 0
        fi
        _afr_parent=$(dirname -- "$_afr_dir")
        [ "$_afr_parent" = "$_afr_dir" ] && break
        _afr_dir=$(CDPATH='' cd -- "$_afr_parent" 2>/dev/null && pwd) || break
    done
    return 1
}

# _abook_load_manifest <root>
#
# Read the version and the list of domains from the manifest.  The manifest is
# TOML, but only two values are needed and both are simple enough to read
# with a small awk program.
_abook_load_manifest() {
    _alm_file="$1/$ABOOK_MANIFEST_NAME"
    [ -r "$_alm_file" ] || return 1
    _alm_data=$(awk '
        { sub(/\r$/, "") }
        /^\[/ { section = $0; gsub(/[][[:space:]]/, "", section); next }
        section == "project" && /^version[ \t]*=/ {
            v = $0; sub(/^version[ \t]*=[ \t]*/, "", v)
            gsub(/^"|"$/, "", v); print "version=" v; next
        }
        section == "domains" && /^list[ \t]*=[ \t]*\[/ {
            collect = 1; buf = $0
            sub(/^list[ \t]*=[ \t]*\[/, "", buf)
            if (buf ~ /\]/) { sub(/\].*/, "", buf); collect = 0 }
            gsub(/[",]/, " ", buf)
            n = split(buf, parts, /[ \t]+/)
            for (i = 1; i <= n; i++) if (parts[i] != "") domains = domains parts[i] " "
            if (!collect) { printf "domains=%s\n", domains; exit }
            next
        }
        collect {
            buf = $0
            if (buf ~ /\]/) { sub(/\].*/, "", buf); collect = 0 }
            gsub(/[",]/, " ", buf)
            n = split(buf, parts, /[ \t]+/)
            for (i = 1; i <= n; i++) if (parts[i] != "") domains = domains parts[i] " "
            if (!collect) { printf "domains=%s\n", domains; exit }
        }
    ' "$_alm_file")
    [ -n "$_alm_data" ] || return 1
    _alm_version=$(printf '%s\n' "$_alm_data" | sed -n 's/^version=//p')
    _alm_domains=$(printf '%s\n' "$_alm_data" | sed -n 's/^domains=//p')
    [ -n "$_alm_version" ] && ABOOK_VERSION=$_alm_version
    MANIFEST_DOMAINS=$(printf '%s' "$_alm_domains" | tr -s ' ' | sed 's/^ //; s/ $//')
    return 0
}

# --------------------------------------------------------------------------
# Terminal capabilities
# --------------------------------------------------------------------------

#: The width of the terminal in columns.
ABOOK_COLS=$ABOOK_DEFAULT_COLS

#: The height of the terminal in lines.
ABOOK_LINES=$ABOOK_DEFAULT_LINES

#: 1 when the terminal can show colour, 0 when it cannot.
ABOOK_COLOR=0

#: 1 when the terminal can show box drawing characters, 0 when it cannot.
ABOOK_UTF8=0

# _abook_detect_utf8
#
# Work out whether the terminal can show UTF-8 box drawing characters.  The
# ABOOK_ASCII and ABOOK_UTF8 environment variables override the guess.
_abook_detect_utf8() {
    if [ -n "${ABOOK_ASCII:-}" ]; then
        ABOOK_UTF8=0
        return 0
    fi
    if [ -n "${ABOOK_UTF8:-}" ]; then
        ABOOK_UTF8=1
        return 0
    fi
    _adu_locale="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    case "$_adu_locale" in
        *[Uu][Tt][Ff]8*|*[Uu][Tt][Ff]-[Uu][Tt][Ff]8*) ABOOK_UTF8=1 ;;
        *) ABOOK_UTF8=0 ;;
    esac
    return 0
}

# _abook_detect_color
#
# Work out whether the terminal can show colour.  NO_COLOR and the dumb
# terminal disable it, ABOOK_COLOR=always|never overrides the guess.
_abook_detect_color() {
    case "${ABOOK_COLOR:-auto}" in
        always) ABOOK_COLOR=1; return 0 ;;
        never)  ABOOK_COLOR=0; return 0 ;;
    esac
    if [ -n "${NO_COLOR:-}" ]; then
        ABOOK_COLOR=0
        return 0
    fi
    case "${TERM:-dumb}" in
        ''|dumb) ABOOK_COLOR=0 ;;
        *)       ABOOK_COLOR=1 ;;
    esac
    return 0
}

# _abook_measure_terminal
#
# Measure the terminal.  tput is used when it is available, stty is the
# fallback and the built in defaults are used when neither works.
_abook_measure_terminal() {
    _amt_cols=0
    _amt_lines=0
    if command -v tput >/dev/null 2>&1; then
        _amt_cols=$(tput cols 2>/dev/null || printf 0)
        _amt_lines=$(tput lines 2>/dev/null || printf 0)
    fi
    case "$_amt_cols" in
        ''|*[!0-9]*) _amt_cols=0 ;;
    esac
    case "$_amt_lines" in
        ''|*[!0-9]*) _amt_lines=0 ;;
    esac
    if { [ "$_amt_cols" -lt 20 ] || [ "$_amt_lines" -lt 6 ]; } && command -v stty >/dev/null 2>&1; then
        _amt_size=$(stty size 2>/dev/null || printf '')
        _amt_rows=${_amt_size%% *}
        _amt_cols2=${_amt_size##* }
        case "$_amt_rows" in ''|*[!0-9]*) _amt_rows=0 ;; esac
        case "$_amt_cols2" in ''|*[!0-9]*) _amt_cols2=0 ;; esac
        [ "$_amt_rows" -gt 0 ] && [ "$_amt_lines" -lt 6 ] && _amt_lines=$_amt_rows
        [ "$_amt_cols2" -gt 0 ] && [ "$_amt_cols" -lt 20 ] && _amt_cols=$_amt_cols2
    fi
    [ "$_amt_cols" -ge 20 ] || _amt_cols=$ABOOK_DEFAULT_COLS
    [ "$_amt_lines" -ge 8 ] || _amt_lines=$ABOOK_DEFAULT_LINES
    ABOOK_COLS=$_amt_cols
    ABOOK_LINES=$_amt_lines
    return 0
}

# --------------------------------------------------------------------------
# Preferences
# --------------------------------------------------------------------------

#: The interface language of the last run.
SETTINGS_LANGUAGE="en"

#: The colour theme of the last run.
SETTINGS_THEME="dark"

#: The domain filter, empty when every domain is shown.
FILTER_DOMAIN=""

#: The safety filter, empty when every safety level is shown.
FILTER_SAFETY=""

#: The difficulty filter, empty when every difficulty is shown.
FILTER_DIFFICULTY=""

#: The recently read entry ids, one per line.
RECENT_IDS=""

# _abook_settings_read <key> <file>
#
# Print the value of one key of the JSON-ish settings file.  An empty string
# is printed when the key is missing.
_abook_settings_read() {
    _asr_key=$1
    _asr_file=$2
    [ -r "$_asr_file" ] || return 0
    awk -v want="$_asr_key" '
        index($0, "\"" want "\"") == 1 || index($0, " \"" want "\"") > 0 {
            line = $0
            p = index(line, ":")
            if (p == 0) next
            value = substr(line, p + 1)
            gsub(/^[[:space:]]+/, "", value)
            gsub(/^"/, "", value)
            gsub(/",?[[:space:]]*$/, "", value)
            print value
            exit
        }
    ' "$_asr_file"
}

# _abook_settings_load
#
# Read the preferences.  A missing or damaged file is not an error: the
# defaults are used instead.
_abook_settings_load() {
    SETTINGS_LANGUAGE="en"
    SETTINGS_THEME="dark"
    FILTER_DOMAIN=""
    FILTER_SAFETY=""
    FILTER_DIFFICULTY=""
    RECENT_IDS=""
    [ -r "$ABOOK_SETTINGS_FILE" ] || return 0
    _asl_language=$(_abook_settings_read language "$ABOOK_SETTINGS_FILE")
    _asl_theme=$(_abook_settings_read theme "$ABOOK_SETTINGS_FILE")
    _asl_domain=$(_abook_settings_read filter_domain "$ABOOK_SETTINGS_FILE")
    _asl_safety=$(_abook_settings_read filter_safety "$ABOOK_SETTINGS_FILE")
    _asl_difficulty=$(_abook_settings_read filter_difficulty "$ABOOK_SETTINGS_FILE")
    [ -n "$_asl_language" ] && SETTINGS_LANGUAGE=$_asl_language
    [ -n "$_asl_theme" ] && SETTINGS_THEME=$_asl_theme
    FILTER_DOMAIN=$_asl_domain
    FILTER_SAFETY=$_asl_safety
    FILTER_DIFFICULTY=$_asl_difficulty
    RECENT_IDS=$(awk '
        /"recently_read"/ { inside = 1 }
        inside {
            n = split($0, parts, "\"")
            for (i = 2; i <= n; i += 2) if (parts[i] != "") print parts[i]
            if (index($0, "]") > 0) exit
        }
    ' "$ABOOK_SETTINGS_FILE")
    return 0
}

# _abook_settings_save
#
# Write the preferences.  Failures are reported but never fatal: losing the
# window size is not worth interrupting a reading session for.
_abook_settings_save() {
    if ! mkdir -p "$ABOOK_STATE_DIR" 2>/dev/null; then
        return 1
    fi
    _ass_tmp="$ABOOK_SETTINGS_FILE.$$"
    {
        printf '{\n'
        printf '  "version": 1,\n'
        printf '  "language": "%s",\n' "$SETTINGS_LANGUAGE"
        printf '  "theme": "%s",\n' "$SETTINGS_THEME"
        printf '  "filter_domain": "%s",\n' "$FILTER_DOMAIN"
        printf '  "filter_safety": "%s",\n' "$FILTER_SAFETY"
        printf '  "filter_difficulty": "%s",\n' "$FILTER_DIFFICULTY"
        printf '  "recently_read": [\n'
        _ass_first=1
        printf '%s\n' "$RECENT_IDS" | while IFS= read -r _ass_id; do
            [ -n "$_ass_id" ] || continue
            if [ "$_ass_first" -eq 1 ]; then
                _ass_first=0
            else
                printf ',\n'
            fi
            printf '    "%s"' "$_ass_id"
        done
        printf '\n  ]\n'
        printf '}\n'
    } > "$_ass_tmp" 2>/dev/null || return 1
    if mv -f "$_ass_tmp" "$ABOOK_SETTINGS_FILE" 2>/dev/null; then
        return 0
    fi
    rm -f "$_ass_tmp" 2>/dev/null
    return 1
}

# _abook_recent_add <entry-id>
#
# Put an entry at the top of the recently read list.
_abook_recent_add() {
    _ara_id=$1
    [ -n "$_ara_id" ] || return 0
    RECENT_IDS=$(printf '%s\n%s\n' "$_ara_id" "$RECENT_IDS" | awk 'NF && !seen[$0]++' | head -n "$ABOOK_RECENT_MAX")
    return 0
}

# --------------------------------------------------------------------------
# Versions
# --------------------------------------------------------------------------

# _abook_chop_last <text>
#
# Print the text without its last character.  A character that is written in
# more than one byte is removed as a whole.
_abook_chop_last() {
    _acl_text=$1
    while [ -n "$_acl_text" ]; do
        _acl_last=${_acl_text#"${_acl_text%?}"}
        _acl_value=$(printf '%d' "'$_acl_last" 2>/dev/null || printf 0)
        case "$_acl_value" in
            ''|*[!0-9]*) _acl_value=0 ;;
        esac
        _acl_text=${_acl_text%?}
        if [ "$_acl_value" -ge 128 ] && [ "$_acl_value" -le 191 ]; then
            continue
        fi
        break
    done
    printf '%s' "$_acl_text"
    return 0
}

# _abook_version_cmp <version-a> <version-b>
#
# Compare two dotted versions.  Prints -1 when a is older than b, 0 when they
# are the same and 1 when a is newer than b.  A pre-release suffix such as
# "-alpha" makes a version older than the same version without one.
_abook_version_cmp() {
    awk -v a="$1" -v b="$2" '
        BEGIN {
            ca = a; sub(/-.*$/, "", ca)
            cb = b; sub(/-.*$/, "", cb)
            if (a ~ /-/) sa = substr(a, index(a, "-") + 1); else sa = ""
            if (b ~ /-/) sb = substr(b, index(b, "-") + 1); else sb = ""
            na = split(ca, xa, ".")
            nb = split(cb, xb, ".")
            n = (na > nb ? na : nb)
            r = 0
            for (i = 1; i <= n; i++) {
                x = (i <= na ? xa[i] + 0 : 0)
                y = (i <= nb ? xb[i] + 0 : 0)
                if (x < y) { r = -1; break }
                if (x > y) { r = 1; break }
            }
            if (r == 0) {
                if (sa == "" && sb == "") r = 0
                else if (sa == "") r = 1
                else if (sb == "") r = -1
                else if (sa < sb) r = -1
                else if (sa > sb) r = 1
                else r = 0
            }
            print r
        }
    '
}
