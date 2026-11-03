#!/bin/sh
#
# The interface strings and the runtime language switcher.
#
# Sourced by abook.sh.  The user interface strings live in the repository, in
# i18n/strings/<lang>.yaml; en.yaml is the canonical catalogue.  The reader
# loads the catalogue of the selected language and falls back to English when
# a language file is missing, unreadable or incomplete, so the application
# always starts even when a translation has been removed.
#
# The languages the application offers are listed in ABOOK_LANGUAGES.  A
# language is only offered when its catalogue file exists on disk.
#
# Usage:  . "$ABOOK_LIB_DIR/i18n.sh"

# The constants of this file are read by the other files of the application.
# shellcheck disable=SC2034
# shellcheck disable=SC1091

if [ -z "${ABOOK_LIB_DIR:-}" ]; then
    printf 'abook: lib/i18n.sh must be sourced, not executed\n' >&2
    return 1
fi

if ! command -v _corpus_yaml_dump >/dev/null 2>&1; then
    # shellcheck source=lib/corpus.sh
    . "$ABOOK_LIB_DIR/corpus.sh"
fi

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------

#: The languages the application offers, in the order they are listed.
ABOOK_LANGUAGES="en es fr de pt hi ar sw zh id it ja ko nl ru tr vi"

#: The name of every language, written in that language.
ABOOK_LANGUAGE_NAMES="en:English es:Español fr:Français de:Deutsch pt:Português hi:हिन्दी ar:العربية sw:Kiswahili zh:中文 id:Bahasa Indonesia it:Italiano ja:日本語 ko:한국어 nl:Nederlands ru:Русский tr:Türkçe vi:Tiếng Việt"

#: The fallback language.
ABOOK_FALLBACK_LANGUAGE="en"

#: A newline, used to join the catalogue lines.
ABOOK_NL='
'

#: The catalogue of the active language, one "key<TAB>value" line per entry.
I18N_DATA=""

#: The English catalogue, used when a key is missing from the active one.
I18N_FALLBACK=""

#: The built in English strings, used when no catalogue can be read at all.
I18N_DEFAULTS=""

#: The language that is currently active.
I18N_LANG="en"

# --------------------------------------------------------------------------
# The built in strings
# --------------------------------------------------------------------------

# The keys of the interface that the shell reader adds to the catalogue of
# the repository, and the English strings used when a catalogue does not
# carry them.  The catalogues of the repository are shared with the other
# applications, so they are left untouched.
I18N_DEFAULTS='app_title	A Book Of Life - Shell Reader
shell_title	A Book Of Life - Shell Reader
tagline	An offline-first knowledge base for rebuilding civilization.
search	Search
search_placeholder	Search {count} entries...
domains	Domains
entries	Entries
results	Results
no_results	No matching entries
result_count	{count} results
entry_count	{count} entries
domain_entry_count	{count} entries in this domain
domain_overview	Domain overview
select_entry	Select an entry to read it.
recently_read	Recently read
no_recent_entries	Nothing read yet.
tags	Tags
path	Path
sources	Sources
materials	Materials & Tools
difficulty	Difficulty
all_difficulties	All difficulties
safety	Safety
all_safety_levels	All safety levels
filter_domain	Domain
all_domains	All domains
verification	Verification
time_to_complete	Time to complete
status_draft	Draft
status_peer_reviewed	Peer-Reviewed
status_field_tested	Field-Tested
status_deprecated	Deprecated
safety_green	Safe
safety_yellow	Caution
safety_red	Danger
difficulty_novice	Novice
difficulty_apprentice	Apprentice
difficulty_journeyman	Journeyman
difficulty_master	Master
language	Language
theme	Theme
theme_light	Light
theme_dark	Dark
about	About
version	Version
close	Close
ok	OK
loading	Loading the corpus...
loading_progress	Loading {done} of {total} entries...
ready	Ready
index_source	Index: {source}
index_source_db	build/index.db
index_source_scan	corpus scan
quick_jump	Quick jump
quick_jump_hint	Type a title, slug or tag...
clear	Clear
command	Command
quit	Quit
help	Help
shortcuts	Shortcuts
shortcut_search	Ctrl+F - focus search
shortcut_jump	Ctrl+K - quick jump
shortcut_about	F1 - about
shortcut_quit	Ctrl+Q - quit
disclaimer	Disclaimer
disclaimer_full	The full disclaimer is in docs/DISCLAIMER.md.
press_any_key	Press any key to continue.
entry_position	{current} of {total}
filters	Filters
no_command	Unknown command: {command}. Type :help for the list.
not_interactive	This program needs an interactive terminal. Run it from a terminal, or use --selftest for the headless checks.
corpus_empty	No entries were found in the corpus.
'

# --------------------------------------------------------------------------
# Loading
# --------------------------------------------------------------------------

# _i18n_parse <file>
#
# Print every scalar of a catalogue file as a "key<TAB>value" line.
_i18n_parse() {
    _ip_file=$1
    [ -r "$_ip_file" ] || return 1
    _ip_list="${TMPDIR:-/tmp}/abook-i18n.$$"
    printf '%s\n' "$_ip_file" > "$_ip_list"
    _ip_data=$(awk -v LISTFILE="$_ip_list" "$ABOOK_YAML_AWK" 2>/dev/null | cut -f2,3)
    rm -f "$_ip_list" 2>/dev/null
    [ -n "$_ip_data" ] || return 1
    printf '%s\n' "$_ip_data"
    return 0
}

# _i18n_load_fallback
#
# Load the English catalogue.  The built in strings are a constant and do not
# need to be loaded.
_i18n_load_fallback() {
    I18N_FALLBACK=$(_i18n_parse "$ABOOK_ROOT/$ABOOK_STRINGS_RELDIR/$ABOOK_FALLBACK_LANGUAGE.yaml" 2>/dev/null || printf '')
    return 0
}

# _i18n_load <language>
#
# Load the catalogue of a language.  Returns 0 when the catalogue was loaded
# and 1 when the fallback language was used instead.
_i18n_load() {
    _il_lang=$1
    _il_file="$ABOOK_ROOT/$ABOOK_STRINGS_RELDIR/$_il_lang.yaml"
    _il_data=$(_i18n_parse "$_il_file" 2>/dev/null || printf '')
    if [ -z "$_il_data" ]; then
        I18N_LANG=$ABOOK_FALLBACK_LANGUAGE
        I18N_DATA=$I18N_FALLBACK
        return 1
    fi
    I18N_LANG=$_il_lang
    I18N_DATA=$_il_data
    return 0
}

# _i18n_available
#
# Print the languages that can be selected, one per line.
_i18n_available() {
    _ia_dir="$ABOOK_ROOT/$ABOOK_STRINGS_RELDIR"
    _ia_codes=""
    for _ia_code in $ABOOK_LANGUAGES; do
        if [ -f "$_ia_dir/$_ia_code.yaml" ]; then
            _ia_codes="$_ia_codes $_ia_code"
        fi
    done
    for _ia_file in "$_ia_dir"/*.yaml; do
        [ -f "$_ia_file" ] || continue
        _ia_code=${_ia_file##*/}
        _ia_code=${_ia_code%.yaml}
        case " $_ia_codes " in
            *" $_ia_code "*) continue ;;
        esac
        _ia_codes="$_ia_codes $_ia_code"
    done
    for _ia_code in $_ia_codes; do
        printf '%s\n' "$_ia_code"
    done
    return 0
}

# _i18n_name <language>
#
# Print the display name of a language.
_i18n_name() {
    for _in_pair in $ABOOK_LANGUAGE_NAMES; do
        case "$_in_pair" in
            "$1":*) printf '%s' "${_in_pair#*:}"; return 0 ;;
        esac
    done
    printf '%s' "$1"
    return 0
}

# --------------------------------------------------------------------------
# Access
# --------------------------------------------------------------------------

# _i18n_lookup <key> <catalogue>
#
# Print the value of a key in a catalogue.  Fails when the key is not there.
_i18n_lookup() {
    _il_key=$1
    _il_data=$2
    _il_pre="$_il_key$ABOOK_TAB"
    case "$_il_data" in
        *"$_il_pre"*) ;;
        *) return 1 ;;
    esac
    _il_rest=${_il_data#*"$_il_pre"}
    _il_value=${_il_rest%%"$ABOOK_NL"*}
    printf '%s' "$_il_value"
    return 0
}

# _i18n_get <key>
#
# Print the string of a key.  The active catalogue wins, then the English
# catalogue, then the built in strings, and finally the key itself so that a
# missing string is visible but never fatal.
_i18n_get() {
    _ig_key=$1
    _ig_value=$(_i18n_lookup "$_ig_key" "$I18N_DATA" 2>/dev/null) && {
        printf '%s' "$_ig_value"
        return 0
    }
    _ig_value=$(_i18n_lookup "$_ig_key" "$I18N_FALLBACK" 2>/dev/null) && {
        printf '%s' "$_ig_value"
        return 0
    }
    _ig_value=$(_i18n_lookup "$_ig_key" "$I18N_DEFAULTS" 2>/dev/null) && {
        printf '%s' "$_ig_value"
        return 0
    }
    return 1
}

# _t_interpolate <text> <name> <value>
#
# Replace a {placeholder} of a string with a value.
_t_interpolate() {
    _ti_text=$1
    _ti_name=$2
    _ti_value=$3
    case "$_ti_text" in
        *"{$_ti_name}"*) ;;
        *) printf '%s' "$_ti_text"; return 0 ;;
    esac
    _ti_escaped=$(printf '%s' "$_ti_value" | sed 's/[\\&|]/\\&/g')
    printf '%s' "$_ti_text" | sed "s|[{]${_ti_name}[}]|${_ti_escaped}|g"
    return 0
}

# t <key> [name=value ...]
#
# Print the translated string of a key.  The name=value pairs fill the
# {placeholder} fields of the string.
t() {
    _t_key=$1
    if [ $# -gt 0 ]; then
        shift
    fi
    _t_value=$(_i18n_get "$_t_key") || _t_value=$_t_key
    for _t_pair in "$@"; do
        _t_name=${_t_pair%%=*}
        _t_repl=${_t_pair#*=}
        _t_value=$(_t_interpolate "$_t_value" "$_t_name" "$_t_repl")
    done
    printf '%s' "$_t_value"
    return 0
}
