#!/bin/sh
#
# The test suite of the shell reader.
#
# The suite exercises the parts of the reader that can be checked without a
# terminal: the YAML parser, the corpus loader, the search ranking, the
# language fallback, the version comparison and the renderer.  It leaves with
# a non zero code when a check fails.
#
# Usage:  sh tests/run-tests.sh

# The libraries are checked on their own, so shellcheck is told to look past
# the names that they share and past the files that are sourced.
# shellcheck disable=SC1091
# shellcheck disable=SC2034

set -eu

ABOOK_TESTS_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ABOOK_APP_DIR=$(CDPATH='' cd -- "$ABOOK_TESTS_DIR/.." && pwd)
ABOOK_LIB_DIR="$ABOOK_APP_DIR/lib"

# A scratch directory that is removed when the suite ends.  The state of the
# reader is kept inside it, so the suite never touches the state of the
# user.
WORK=$(mktemp -d "${TMPDIR:-/tmp}/abook-tests.XXXXXX" 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/abook-tests.$$")
mkdir -p "$WORK"
export ABOOK_HOME="$WORK/home"
mkdir -p "$ABOOK_HOME"

# The libraries under test.
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
# The test harness
# --------------------------------------------------------------------------

#: How many checks passed.
PASSED=0

#: How many checks failed.
FAILED=0

#: The names of the checks that failed.
FAILURES=""

# _cleanup
#
# Remove the scratch directory.  The exit status of the suite is kept, so a
# trap cannot turn a failure into a success.  The function is only called
# through a trap.
# shellcheck disable=SC2317
_cleanup() {
    _cleanup_status=$?
    rm -rf "$WORK" 2>/dev/null || true
    exit "$_cleanup_status"
}
trap _cleanup EXIT INT TERM
# _pass <name>
#
# Record a check that passed.
_pass() {
    PASSED=$((PASSED + 1))
    printf '  [ ok ] %s\n' "$1"
    return 0
}

# _fail <name> <detail>
#
# Record a check that failed.
_fail() {
    FAILED=$((FAILED + 1))
    FAILURES="$FAILURES$1
"
    printf '  [FAIL] %s\n' "$1"
    if [ -n "${2:-}" ]; then
        printf '         %s\n' "$2"
    fi
    return 0
}

# _assert_eq <name> <expected> <actual>
#
# Check that two values are the same.
_assert_eq() {
    if [ "$2" = "$3" ]; then
        _pass "$1"
    else
        _fail "$1" "expected [$2], got [$3]"
    fi
    return 0
}

# _assert_ne <name> <unexpected> <actual>
#
# Check that two values are different.
_assert_ne() {
    if [ "$2" != "$3" ]; then
        _pass "$1"
    else
        _fail "$1" "did not expect [$2]"
    fi
    return 0
}

# _assert_ok <name> <status>
#
# Check that a status is 0.
_assert_ok() {
    if [ "$2" -eq 0 ]; then
        _pass "$1"
    else
        _fail "$1" "status $2"
    fi
    return 0
}

# _assert_contains <name> <needle> <haystack>
#
# Check that a text contains another text.
_assert_contains() {
    case "$3" in
        *"$2"*) _pass "$1" ;;
        *) _fail "$1" "[$3] does not contain [$2]" ;;
    esac
    return 0
}

# _assert_not_contains <name> <needle> <haystack>
#
# Check that a text does not contain another text.
_assert_not_contains() {
    case "$3" in
        *"$2"*) _fail "$1" "[$3] contains [$2]" ;;
        *) _pass "$1" ;;
    esac
    return 0
}

# _section <name>
#
# Print the name of a group of checks.
_section() {
    printf '\n%s\n' "$1"
    return 0
}

# --------------------------------------------------------------------------
# The YAML parser
# --------------------------------------------------------------------------

_section "the YAML parser"

cat > "$WORK/mapping.yaml" <<'YAML'
# A comment that has to be ignored.
id: pnk:01HZX0K8J9Q7R3VY6T2M4B8N1P/survival/making-fire
title: Making Fire
domain: survival
difficulty: novice
safety: yellow
YAML

_assert_eq "mapping, plain scalar" "Making Fire" "$(_corpus_yaml_get "$WORK/mapping.yaml" title)"
_assert_eq "mapping, scalar with a colon" \
    "pnk:01HZX0K8J9Q7R3VY6T2M4B8N1P/survival/making-fire" \
    "$(_corpus_yaml_get "$WORK/mapping.yaml" id)"
_assert_eq "mapping, the comment is not a key" "" \
    "$(_corpus_yaml_get "$WORK/mapping.yaml" "# A comment that has to be ignored." || printf '')"

cat > "$WORK/nested.yaml" <<'YAML'
verification:
  status: peer-reviewed
  date: "2026-03-12"
  reviewers:
    - one
    - two
YAML

_assert_eq "nested mapping" "peer-reviewed" "$(_corpus_yaml_get "$WORK/nested.yaml" verification.status)"
_assert_eq "nested mapping, quoted scalar" "2026-03-12" "$(_corpus_yaml_get "$WORK/nested.yaml" verification.date)"
_assert_eq "nested sequence" "one" "$(_corpus_yaml_get "$WORK/nested.yaml" verification.reviewers.0)"
_assert_eq "nested sequence, second item" "two" "$(_corpus_yaml_get "$WORK/nested.yaml" verification.reviewers.1)"

cat > "$WORK/flow.yaml" <<'YAML'
tags: [fire, ignition, warmth]
empty: []
sources:
  - title: US Army Field Manual FM 21-76
    license: public domain
  - title: Boy Scouts of America Handbook
YAML

_assert_eq "inline list, first item" "fire" "$(_corpus_yaml_get "$WORK/flow.yaml" tags.0)"
_assert_eq "inline list, second item" "ignition" "$(_corpus_yaml_get "$WORK/flow.yaml" tags.1)"
_assert_eq "inline list, third item" "warmth" "$(_corpus_yaml_get "$WORK/flow.yaml" tags.2)"
_assert_eq "inline list, empty" "" "$(_corpus_yaml_get "$WORK/flow.yaml" empty.0 || printf '')"
_assert_eq "sequence of mappings" "US Army Field Manual FM 21-76" "$(_corpus_yaml_get "$WORK/flow.yaml" sources.0.title)"
_assert_eq "sequence of mappings, second key" "public domain" "$(_corpus_yaml_get "$WORK/flow.yaml" sources.0.license)"
_assert_eq "sequence of mappings, second item" "Boy Scouts of America Handbook" "$(_corpus_yaml_get "$WORK/flow.yaml" sources.1.title)"

printf 'title: Carriage Return\r\ndomain: survival\r\n' > "$WORK/crlf.yaml"
_assert_eq "carriage return endings" "Carriage Return" "$(_corpus_yaml_get "$WORK/crlf.yaml" title)"

cat > "$WORK/quoted.yaml" <<'YAML'
title: 'It is quoted'
other: "A \"quote\" inside"
number: 42
yes_no: true
nothing: null
YAML

_assert_eq "single quoted scalar" "It is quoted" "$(_corpus_yaml_get "$WORK/quoted.yaml" title)"
_assert_eq "double quoted scalar" 'A "quote" inside' "$(_corpus_yaml_get "$WORK/quoted.yaml" other)"
_assert_eq "integer scalar" "42" "$(_corpus_yaml_get "$WORK/quoted.yaml" number)"
_assert_eq "boolean scalar" "true" "$(_corpus_yaml_get "$WORK/quoted.yaml" yes_no)"
_assert_eq "null scalar" "" "$(_corpus_yaml_get "$WORK/quoted.yaml" nothing || printf '')"

cat > "$WORK/sequence.yaml" <<'YAML'
prerequisites:
- pnk:one/survival/a
- pnk:two/survival/b
YAML

_assert_eq "sequence at the same indentation" "pnk:one/survival/a" "$(_corpus_yaml_get "$WORK/sequence.yaml" prerequisites.0)"
_assert_eq "sequence at the same indentation, second item" "pnk:two/survival/b" "$(_corpus_yaml_get "$WORK/sequence.yaml" prerequisites.1)"

if _corpus_yaml_get "$WORK/does-not-exist.yaml" title >/dev/null 2>&1; then
    _fail "a missing file is not an error" "the parser returned a value"
else
    _pass "a missing file is not an error"
fi

# --------------------------------------------------------------------------
# The corpus loader
# --------------------------------------------------------------------------

_section "the corpus loader"

ABOOK_ROOT=$(_abook_find_root "$ABOOK_APP_DIR")
_assert_ne "the repository is found" "" "$ABOOK_ROOT"

_abook_load_manifest "$ABOOK_ROOT"
_assert_eq "the version comes from the manifest" "0.1.0-alpha" "$ABOOK_VERSION"

_corpus_load "$ABOOK_ROOT"
_assert_ok "the corpus loads" "$([ "$CORPUS_COUNT" -gt 0 ] && echo 0 || echo 1)"
_expected_sidecars=$(find "$ABOOK_ROOT/$ABOOK_SIDECARS_DIRNAME" -type f -name "*$ABOOK_SIDECAR_SUFFIX" | wc -l | tr -d ' \t')
_assert_eq "every sidecar is read" "$_expected_sidecars" "$CORPUS_SIDECAR_COUNT"
_assert_eq "the corpus is indexed" "$CORPUS_SIDECAR_COUNT" "$CORPUS_COUNT"

DOMAIN_ROWS=$(_corpus_domain_rows)
DOMAIN_COUNT=$(printf '%s\n' "$DOMAIN_ROWS" | grep -c . || true)
_assert_eq "sixteen domains" "16" "$DOMAIN_COUNT"
_assert_contains "the domain of the first entry" "agriculture" "$(_corpus_field 1 2)"
_assert_contains "the title of the first entry" "Beekeeping" "$(_corpus_field 1 4)"
_assert_ne "the first entry has tags" "" "$(_corpus_field 1 9)"
_assert_contains "the body path of the first entry" "domains/agriculture/beekeeping.md" "$(_corpus_field 1 11)"

_cache_before=$(find "$ABOOK_CACHE_DIR" -type f | wc -l | tr -d ' \t')
_corpus_load "$ABOOK_ROOT"
_cache_after=$(find "$ABOOK_CACHE_DIR" -type f | wc -l | tr -d ' \t')
_assert_eq "the cache is reused" "$_cache_before" "$_cache_after"

# A repository without a search index must still load.
mkdir -p "$WORK/bare/sidecars" "$WORK/bare/domains"
printf '[project]\nname = "bare"\nversion = "0.0.1"\n' > "$WORK/bare/manifest.toml"
_corpus_load "$WORK/bare"
_assert_eq "a missing index is not an error" "scan" "$ABOOK_INDEX_SOURCE"
_assert_eq "a missing corpus is empty, not broken" "0" "$CORPUS_COUNT"

# The repository of the tests has to be found again.
_corpus_load "$ABOOK_ROOT"

# --------------------------------------------------------------------------
# The search ranking
# --------------------------------------------------------------------------

_section "the search ranking"

_search_run "water purification"
_assert_ok "the search finds entries" "$([ "$SEARCH_COUNT" -gt 0 ] && echo 0 || echo 1)"
_assert_eq "a title match comes first" "Water Purification" "$(printf '%s\n' "$SEARCH_RESULTS" | head -n 1 | cut -f4)"
_assert_eq "a title match is in the title tier" "3" "$(printf '%s\n' "$SEARCH_RESULTS" | head -n 1 | cut -f1)"

_search_run "water pur"
_assert_contains "a prefix of a title matches" "Water Purification" "$SEARCH_RESULTS"

_search_run ""
_assert_eq "an empty query returns everything" "$CORPUS_COUNT" "$SEARCH_COUNT"

_search_run "zzzznotanentry"
_assert_eq "a query that matches nothing returns nothing" "0" "$SEARCH_COUNT"

_search_run "Making Fire"
_assert_eq "the best match is a title match" "3" "$(printf '%s\n' "$SEARCH_RESULTS" | head -n 1 | cut -f1)"
_assert_eq "the best match is the right entry" "Making Fire" "$(printf '%s\n' "$SEARCH_RESULTS" | head -n 1 | cut -f4)"

_search_run "Ferro Rod"
_assert_eq "a match that is only in the body is in the body tier" "1" \
    "$(printf '%s\n' "$SEARCH_RESULTS" | head -n 1 | cut -f1)"

FILTER_DOMAIN="survival"
_search_run "aid"
_assert_eq "the domain filter keeps only that domain" "survival" \
    "$(printf '%s\n' "$SEARCH_RESULTS" | cut -f3 | sort -u | tr '\n' ' ' | sed 's/ $//')"
FILTER_DOMAIN=""

FILTER_SAFETY="red"
_search_run ""
_expected_red=$(awk -F'\t' '$6 == "red"' "$CORPUS_INDEX_FILE" | wc -l | tr -d ' \t')
_assert_eq "the safety filter keeps only that level" "$_expected_red" "$SEARCH_COUNT"
FILTER_SAFETY=""

FILTER_DIFFICULTY="master"
_search_run ""
_expected_master=$(awk -F'\t' '$5 == "master"' "$CORPUS_INDEX_FILE" | wc -l | tr -d ' \t')
_assert_eq "the difficulty filter keeps only that level" "$_expected_master" "$SEARCH_COUNT"
FILTER_DIFFICULTY=""

_search_quick_jump "making"
_assert_ok "the quick jump finds entries" "$([ "$SEARCH_COUNT" -gt 0 ] && echo 0 || echo 1)"
_assert_contains "the quick jump finds the entry" "Making Fire" "$SEARCH_RESULTS"

# --------------------------------------------------------------------------
# The language fallback
# --------------------------------------------------------------------------

_section "the language fallback"

_i18n_load_fallback
_i18n_load "en"
_english=$(_i18n_get site_name)
_assert_ne "the English catalogue loads" "" "$_english"

if _i18n_load "zz"; then
    _fail "an unknown language falls back" "the catalogue was loaded"
else
    _pass "an unknown language falls back"
fi
_assert_eq "the fallback language is English" "en" "$I18N_LANG"
_assert_eq "the fallback string is the English one" "$_english" "$(_i18n_get site_name)"

_i18n_load "fr"
_assert_ne "another language is used" "$_english" "$(_i18n_get site_name)"
_assert_eq "the language is the one that was asked for" "fr" "$I18N_LANG"

_i18n_load "en"
_lang_count=$(_i18n_available | grep -c . || true)
# The expected count is read from the repository, so adding a language does not
# mean editing this suite.
_catalogue_count=$(find "$ABOOK_APP_DIR/../../i18n/strings" -type f -name '*.yaml' 2>/dev/null | grep -c . || true)
_assert_eq "every language of the repository is offered" "$_catalogue_count" "$_lang_count"
_assert_contains "the languages are the ones of the repository" "zh" "$(_i18n_available | tr '\n' ' ')"
_assert_contains "the newest languages are offered too" "vi" "$(_i18n_available | tr '\n' ' ')"

_assert_eq "a string is interpolated" "5 results" "$(t result_count count=5)"
_assert_eq "an unknown key falls back to the key" "no_such_key" "$(t no_such_key)"

# --------------------------------------------------------------------------
# The version comparison
# --------------------------------------------------------------------------

_section "the version comparison"

_assert_eq "the same version" "0" "$(_abook_version_cmp "0.1.0-alpha" "0.1.0-alpha")"
_assert_eq "a pre-release is older" "-1" "$(_abook_version_cmp "0.1.0-alpha" "0.1.0")"
_assert_eq "a release is newer" "1" "$(_abook_version_cmp "0.1.0" "0.1.0-alpha")"
_assert_eq "a bigger number is newer" "1" "$(_abook_version_cmp "0.2.0" "0.1.9")"
_assert_eq "a smaller number is older" "-1" "$(_abook_version_cmp "0.1.9" "0.2.0")"
_assert_eq "the parts are compared as numbers" "1" "$(_abook_version_cmp "0.10.0" "0.9.0")"
_assert_eq "a missing part is zero" "0" "$(_abook_version_cmp "1.0" "1.0.0")"
_assert_eq "a pre-release is older than a pre-release" "-1" "$(_abook_version_cmp "1.0.0-alpha" "1.0.0-beta")"
_assert_eq "the version of the manifest" "0" \
    "$(_abook_version_cmp "$ABOOK_VERSION" "$(_corpus_built_version 2>/dev/null || printf '%s' "$ABOOK_VERSION")")"

# --------------------------------------------------------------------------
# The keys
# --------------------------------------------------------------------------

_section "the keys"

ABOOK_ESC=$(printf '\033')
_seq="$WORK/keys.bin"

# _key_of <bytes>
#
# Feed bytes to the key reader and print the name of the key it returns.
_key_of() {
    printf '%b' "$1" > "$_seq"
    _ui_read_key 0 < "$_seq"
    printf '%s' "$UI_KEY"
}

_assert_eq "the up arrow" "UP" "$(_key_of '\033[A')"
_assert_eq "the down arrow" "DOWN" "$(_key_of '\033[B')"
_assert_eq "the right arrow" "RIGHT" "$(_key_of '\033[C')"
_assert_eq "the left arrow" "LEFT" "$(_key_of '\033[D')"
_assert_eq "page down" "PGDN" "$(_key_of '\033[6~')"
_assert_eq "page up" "PGUP" "$(_key_of '\033[5~')"
_assert_eq "F1" "F1" "$(_key_of '\033OP')"
_assert_eq "F1, the other form" "F1" "$(_key_of '\033[11~')"
_assert_eq "the tab key" "$(printf '\t')" "$(_key_of '\t')"
_assert_eq "escape" "ESC" "$(_key_of '\033')"
_assert_eq "a letter" "x" "$(_key_of 'x')"

# A character is read as a whole, so that a search can be typed in any
# language.
printf '\303\251' > "$_seq"
_ui_read_char < "$_seq"
_assert_eq "a multi byte character" "é" "$UI_KEY"

# --------------------------------------------------------------------------
# The text
# --------------------------------------------------------------------------

_section "the text"

_assert_eq "the last character is removed" "ab" "$(_abook_chop_last "abc")"
_assert_eq "an empty text stays empty" "" "$(_abook_chop_last "")"
_assert_eq "a multi byte character is removed as a whole" "ab" \
    "$(_abook_chop_last "$(printf 'ab\303\251')")"
_assert_eq "a multi byte character in the middle is kept" "x$(printf '\344\270\255')" \
    "$(_abook_chop_last "$(printf 'x\344\270\255y')")"

# --------------------------------------------------------------------------
# The renderer
# --------------------------------------------------------------------------

_section "the renderer"

_theme_set dark
_assert_eq "the dark theme is selected" "dark" "$THEME_NAME"
_theme_set light
_light_accent=$C_ACCENT
_theme_set dark
_assert_ne "the two themes differ" "$_light_accent" "$C_ACCENT"

ABOOK_UTF8=0
_theme_set_characters
_assert_eq "the ASCII fallback uses a plus" "+" "$BOX_TL"
ABOOK_UTF8=1
_theme_set_characters
_assert_eq "the UTF-8 box drawing is used when it is available" "┌" "$BOX_TL"
ABOOK_UTF8=0
_theme_set_characters

printf '# The title\n\n## A heading\n\n- a bullet\n\n1. a number\n\n> a quote\n' > "$WORK/entry.md"
_md=$(_render_markdown "$WORK/entry.md" 40)
_assert_contains "the heading is marked" "H|A heading" "$_md"
_assert_contains "the bullet is marked" "B|- a bullet" "$_md"
_assert_contains "the number is marked" "N2|  a number" "$_md"
_assert_contains "the quote is marked" "Q|| a quote" "$_md"
_assert_not_contains "the title is left out" "H|The title" "$_md"

printf 'A very long line that has to be wrapped by the renderer because it does not fit.\n' > "$WORK/long.md"
_wrapped=$(_render_markdown "$WORK/long.md" 20 | wc -l | tr -d ' \t')
_assert_ne "a long line is wrapped" "1" "$_wrapped"

ABOOK_UTF8=1
_theme_set_characters
_assert_eq "the padding is exact" "ab    " "$(_pad "ab" 6)"
_assert_eq "a long text is cut" "ab…" "$(_pad "abcdef" 3)"
ABOOK_UTF8=0
_theme_set_characters

# --------------------------------------------------------------------------
# The program itself
# --------------------------------------------------------------------------

_section "the program"

if sh "$ABOOK_APP_DIR/abook.sh" > "$WORK/no-tty.txt" 2>&1; then
    _fail "the reader refuses to run without a terminal" "it exited with 0"
else
    _pass "the reader refuses to run without a terminal"
fi
_assert_contains "the refusal explains itself" "interactive" "$(cat "$WORK/no-tty.txt")"

if sh "$ABOOK_APP_DIR/abook.sh" --selftest > "$WORK/selftest.txt" 2>&1; then
    _pass "the self test leaves with 0"
else
    _fail "the self test leaves with 0" "$(tail -n 3 "$WORK/selftest.txt")"
fi
_assert_contains "the self test prints a report" "checks passed" "$(cat "$WORK/selftest.txt")"

# --------------------------------------------------------------------------
# The result
# --------------------------------------------------------------------------

printf '\n'
if [ "$FAILED" -gt 0 ]; then
    printf '%s check(s) failed, %s passed:\n' "$FAILED" "$PASSED"
    while IFS= read -r _failure; do
        [ -n "$_failure" ] || continue
        printf '  - %s\n' "$_failure"
    done <<ABOOK_FAILURES_EOF
$FAILURES
ABOOK_FAILURES_EOF
    exit 1
fi
printf 'all %s checks passed\n' "$PASSED"
exit 0
