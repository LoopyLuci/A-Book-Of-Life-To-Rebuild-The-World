#!/bin/sh
#
# Ranking the corpus against a free-text query.
#
# Sourced by abook.sh.  The ranking is deliberately simple and predictable:
# a title match always outranks a tag match and a tag match always outranks
# a body match.  On top of that a whole-phrase match is rewarded, so that
# "water pur" finds *Water Purification*.
#
# The search runs over the corpus index, which holds the title, the tags and
# the body of every entry in lower case, so one awk pass over the index is
# enough to rank the whole corpus.
#
# Usage:  . "$ABOOK_LIB_DIR/search.sh"

# The constants of this file are read by the other files of the application.
# shellcheck disable=SC2034

if [ -z "${ABOOK_LIB_DIR:-}" ]; then
    printf 'abook: lib/search.sh must be sourced, not executed\n' >&2
    return 1
fi

# --------------------------------------------------------------------------
# The ranker
# --------------------------------------------------------------------------

# The ranker prints "tier<TAB>score<TAB>domain<TAB>title<TAB>index" for every
# entry that matches.  The tier is 3 for a title match, 2 for a tag match and
# 1 for a body match.
# shellcheck disable=SC2016
ABOOK_SEARCH_AWK='
BEGIN {
    FS = "\t"
    q = tolower(query)
    gsub(/[ \t]+/, " ", q)
    nq = split(q, terms, " ")
}

{
    idx = $1; dom = $2; title = $4; diff = $5; saf = $6
    tl = $15; tgl = $16; bl = $17

    if (fdomain != "" && dom != fdomain) next
    if (fsafety != "" && saf != fsafety) next
    if (fdifficulty != "" && diff != fdifficulty) next

    tier = 1
    score = 0
    if (nq > 0) {
        tier = 0
        ok = 1
        for (t = 1; t <= nq; t++) {
            term = terms[t]
            if (term == "") continue
            if (index(tl, term) > 0) { c = 3; w = 100 }
            else if (index(tgl, term) > 0) { c = 2; w = 30 }
            else if (index(bl, term) > 0) { c = 1; w = 5 }
            else { ok = 0; break }
            if (c > tier) tier = c
            score += w
            if (c == 3 && index(tl, term) == 1) score += 50
        }
        if (!ok) next
        if (length(q) >= 3) {
            if (index(tl, q) > 0) { score += 400; tier = 3 }
            else if (index(tgl, q) > 0) { score += 120; if (tier < 2) tier = 2 }
            else if (index(bl, q) > 0) { score += 30; if (tier < 1) tier = 1 }
        }
    }
    printf("%d\t%d\t%s\t%s\t%s\n", tier, score, dom, title, idx)
}
'

# The quick jump ranks entries by their title, their slug and their tags.
# shellcheck disable=SC2016
ABOOK_JUMP_AWK='
BEGIN {
    FS = "\t"
    q = tolower(query)
    gsub(/[ \t]+/, " ", q)
}

{
    title = tolower($4)
    slug = tolower($3)
    tgl = $16
    if (index(title, q) == 1) tier = 3
    else if (index(title, q) > 0) tier = 2
    else if (index(slug, q) > 0 || index(tgl, q) > 0) tier = 1
    else next
    printf("%d\t%d\t%s\t%s\t%s\n", tier, 100 - tier, $2, $4, $1)
}
'

# --------------------------------------------------------------------------
# Results
# --------------------------------------------------------------------------

#: The entries that match the current query, best match first.  Every line
#: holds the tier, the score, the domain, the title and the index.
SEARCH_RESULTS=""

#: The indexes of the entries that match the current query.
SEARCH_INDEXES=""

#: How many entries match the current query.
SEARCH_COUNT=0

# _search_run <query>
#
# Rank the corpus against the query and store the result in SEARCH_RESULTS.
_search_run() {
    _sr_query=$1
    SEARCH_RESULTS=""
    SEARCH_INDEXES=""
    SEARCH_COUNT=0
    [ -f "$CORPUS_INDEX_FILE" ] || return 0
    _sr_raw=$(awk -v query="$_sr_query" \
        -v fdomain="$FILTER_DOMAIN" \
        -v fsafety="$FILTER_SAFETY" \
        -v fdifficulty="$FILTER_DIFFICULTY" \
        "$ABOOK_SEARCH_AWK" "$CORPUS_INDEX_FILE" 2>/dev/null \
        | LC_ALL=C sort -t "$ABOOK_TAB" -k1,1nr -k2,2nr -k3,3 -k4,4)
    [ -n "$_sr_raw" ] || return 0
    SEARCH_RESULTS=$_sr_raw
    SEARCH_INDEXES=$(printf '%s\n' "$_sr_raw" | cut -f5)
    SEARCH_COUNT=$(printf '%s\n' "$SEARCH_INDEXES" | grep -c . || true)
    return 0
}

# _search_quick_jump <query>
#
# Rank the corpus for the quick jump palette.  Titles that start with the
# query come first, then titles that contain it, then slugs and tags.
_search_quick_jump() {
    _sq_query=$1
    _sq_raw=$(awk -v query="$_sq_query" "$ABOOK_JUMP_AWK" "$CORPUS_INDEX_FILE" 2>/dev/null \
        | LC_ALL=C sort -t "$ABOOK_TAB" -k1,1nr -k2,2nr -k3,3 -k4,4)
    [ -n "$_sq_raw" ] || return 0
    SEARCH_RESULTS=$_sq_raw
    SEARCH_INDEXES=$(printf '%s\n' "$_sq_raw" | cut -f5)
    SEARCH_COUNT=$(printf '%s\n' "$SEARCH_INDEXES" | grep -c . || true)
    return 0
}

# _search_recent
#
# Use the recently read list as the result set, most recent first.
_search_recent() {
    _sr_recent=""
    SEARCH_RESULTS=""
    SEARCH_INDEXES=""
    SEARCH_COUNT=0
    [ -f "$CORPUS_INDEX_FILE" ] || return 0
    [ -n "$RECENT_IDS" ] || return 0
    _sr_list="${TMPDIR:-/tmp}/abook-recent.$$"
    printf '%s\n' "$RECENT_IDS" > "$_sr_list"
    _sr_raw=$(awk -F'\t' -v listfile="$_sr_list" '
        BEGIN {
            while ((getline id < listfile) > 0) {
                if (id == "") continue
                n++
                ord[id] = n
            }
        }
        { if ($10 in ord) printf("%d\t%d\t%s\t%s\t%s\n", 0, n - ord[$10] + 1, $2, $4, $1) }
    ' "$CORPUS_INDEX_FILE" 2>/dev/null | LC_ALL=C sort -t "$ABOOK_TAB" -k2,2nr)
    rm -f "$_sr_list" 2>/dev/null
    [ -n "$_sr_raw" ] || return 0
    SEARCH_RESULTS=$_sr_raw
    SEARCH_INDEXES=$(printf '%s\n' "$_sr_raw" | cut -f5)
    SEARCH_COUNT=$(printf '%s\n' "$SEARCH_INDEXES" | grep -c . || true)
    return 0
}

# _search_snippet <index> <query>
#
# Print a short excerpt of the body of an entry, around the first word of the
# query that occurs in it.
_search_snippet() {
    _ss_index=$1
    _ss_query=$2
    _ss_rel=$(_corpus_field "$_ss_index" 11)
    [ -n "$_ss_rel" ] || return 1
    [ -r "$ABOOK_ROOT/$_ss_rel" ] || return 1
    awk -v q="$_ss_query" '
        BEGIN {
            gsub(/[ \t]+/, " ", q)
            nq = split(q, terms, " ")
        }
        {
            line = $0
            sub(/\r$/, "", line)
            text = text " " line
        }
        END {
            if (text == "") exit
            low = tolower(text)
            at = -1
            for (t = 1; t <= nq; t++) {
                if (terms[t] == "") continue
                p = index(low, terms[t])
                if (p > 0 && (at < 0 || p < at)) at = p
            }
            if (at < 0) at = 1
            start = at - 70
            if (start < 1) start = 1
            out = substr(text, start, 200)
            gsub(/[ \t]+/, " ", out)
            if (start > 1) out = "..." out
            print out
        }
    ' "$ABOOK_ROOT/$_ss_rel"
    return 0
}
