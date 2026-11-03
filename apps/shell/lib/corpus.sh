#!/bin/sh
#
# Reading the repository corpus: the YAML sidecars and the Markdown bodies.
#
# Sourced by abook.sh.  The corpus of *A Book Of Life To Rebuild The World*
# lives in two places inside the repository:
#
#   sidecars/<domain>/<slug>.pnk.yaml   the metadata of an entry
#   domains/<domain>/<slug>.md          the Markdown body of an entry
#
# The metadata is read with the small awk YAML parser below, which handles
# the subset of YAML the repository uses: mappings, sequences, scalars,
# quoted strings, comments and inline [a, b] lists.  The parsed corpus is
# cached under the state directory so that a second run starts instantly.
#
# Usage:  . "$ABOOK_LIB_DIR/corpus.sh"

# The constants of this file are read by the other files of the application.
# shellcheck disable=SC2034

if [ -z "${ABOOK_LIB_DIR:-}" ]; then
    printf 'abook: lib/corpus.sh must be sourced, not executed\n' >&2
    return 1
fi

# --------------------------------------------------------------------------
# The YAML parser
# --------------------------------------------------------------------------

# The parser reads a list of files (one path per line) and prints one
# "path<TAB>key<TAB>value" line for every scalar it finds.  The key is the
# dotted path of the scalar inside the document, so "verification.status" is
# the status of the verification mapping and "tags.0" is the first tag.
# shellcheck disable=SC2016
ABOOK_YAML_AWK='
function trim(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}

function is_seq_item(t) {
    return (t == "-" || substr(t, 1, 2) == "- ")
}

# Remove a trailing comment that is not inside a quoted scalar.
function strip_comment(s,   i, c, q, n, out, prev) {
    n = length(s); q = ""; out = ""
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        prev = (i > 1 ? substr(s, i - 1, 1) : "")
        if (q != "") {
            out = out c
            if (q == "\"" && c == "\\" && i < n) {
                out = out substr(s, i + 1, 1)
                i++
                continue
            }
            if (c == q) q = ""
            continue
        }
        if ((c == "\"" || c == "\047") && (i == 1 || prev == " " || prev == "\t")) {
            q = c
            out = out c
            continue
        }
        if (c == "#" && (i == 1 || prev == " " || prev == "\t")) break
        out = out c
    }
    return out
}

# Split "key: value".  A colon only separates a key from a value when it is
# followed by a space or ends the line, so that identifiers such as
# "pnk:01HZX0K8J9Q7R3VY6T2M4B8N1P" stay intact.
function split_key(t,   i, c, n) {
    if (t == "") return 0
    if (substr(t, 1, 1) == "\"" || substr(t, 1, 1) == "\047") return 0
    n = length(t)
    for (i = 1; i <= n; i++) {
        c = substr(t, i, 1)
        if (c != ":") continue
        if (i == n) { KEY = trim(substr(t, 1, i - 1)); REST = ""; return 1 }
        if (substr(t, i + 1, 1) == " " || substr(t, i + 1, 1) == "\t") {
            KEY = trim(substr(t, 1, i - 1))
            REST = trim(substr(t, i + 2))
            return 1
        }
    }
    return 0
}

# Remove the quotes of a scalar and expand the escape sequences.
function unquote(v,   s, i, c, n, out, nx) {
    v = trim(v)
    n = length(v)
    if (n >= 2 && substr(v, 1, 1) == "\"" && substr(v, n, 1) == "\"") {
        s = substr(v, 2, n - 2)
        out = ""
        n = length(s)
        for (i = 1; i <= n; i++) {
            c = substr(s, i, 1)
            if (c == "\\" && i < n) {
                i++
                nx = substr(s, i, 1)
                if (nx == "n") out = out "\n"
                else if (nx == "t") out = out "\t"
                else if (nx == "r") out = out "\r"
                else if (nx == "\"") out = out "\""
                else if (nx == "\\") out = out "\\"
                else if (nx == "/") out = out "/"
                else out = out nx
                continue
            }
            out = out c
        }
        return out
    }
    if (n >= 2 && substr(v, 1, 1) == "\047" && substr(v, n, 1) == "\047") {
        s = substr(v, 2, n - 2)
        gsub(/\047\047/, "\047", s)
        return s
    }
    return v
}

# Split the body of a flow collection on the commas that separate its items.
function split_flow(inner, arr,   i, c, q, n, depth, cur, cnt, last, prev) {
    cnt = 0; cur = ""; q = ""; depth = 0; n = length(inner)
    for (i = 1; i <= n; i++) {
        c = substr(inner, i, 1)
        prev = (i > 1 ? substr(inner, i - 1, 1) : "")
        if (q != "") {
            cur = cur c
            if (q == "\"" && c == "\\" && i < n) {
                cur = cur substr(inner, i + 1, 1)
                i++
                continue
            }
            if (c == q) q = ""
            continue
        }
        if ((c == "\"" || c == "\047") && (i == 1 || prev == " " || prev == "\t")) {
            q = c
            cur = cur c
            continue
        }
        if (c == "[" || c == "{") depth++
        else if (c == "]" || c == "}") depth--
        if (c == "," && depth == 0) {
            cnt++
            arr[cnt] = trim(cur)
            cur = ""
            continue
        }
        cur = cur c
    }
    last = trim(cur)
    if (last != "") {
        cnt++
        arr[cnt] = last
    }
    return cnt
}

function push(comp) { SP++; STACK[SP] = comp }
function pop() { if (SP > 0) { delete STACK[SP]; SP-- } }

function cur_path(   i, p) {
    p = ""
    for (i = 1; i <= SP; i++) p = (p == "" ? STACK[i] : p "." STACK[i])
    return p
}

# Print one scalar.  A flow collection is expanded into its members.
function emit_value(path, raw,   inner, arr, n, j, item, p, key, val, first, value) {
    raw = trim(raw)
    if (raw != "" && substr(raw, 1, 1) == "[" && substr(raw, length(raw), 1) == "]") {
        inner = substr(raw, 2, length(raw) - 2)
        n = split_flow(inner, arr)
        for (j = 1; j <= n; j++) emit_value(path "." (j - 1), arr[j])
        return
    }
    if (raw != "" && substr(raw, 1, 1) == "{" && substr(raw, length(raw), 1) == "}") {
        inner = substr(raw, 2, length(raw) - 2)
        n = split_flow(inner, arr)
        for (j = 1; j <= n; j++) {
            item = arr[j]
            p = index(item, ":")
            if (p == 0) continue
            key = trim(substr(item, 1, p - 1))
            val = trim(substr(item, p + 1))
            emit_value(path "." key, val)
        }
        return
    }
    first = substr(raw, 1, 1)
    value = unquote(raw)
    if (first != "\"" && first != "\047" && (value == "null" || value == "~")) value = ""
    printf("%s\t%s\t%s\n", CURFILE, path, value)
}

# Parse the block that starts at the given line and indentation.
function parse_block(i, indent,   t, key, rest) {
    while (i <= N) {
        if (LI[i] < indent) break
        if (LI[i] > indent) { i++; continue }
        t = LT[i]
        if (is_seq_item(t)) break
        if (!split_key(t)) { i++; continue }
        key = KEY
        rest = REST
        i++
        push(key)
        if (rest == "") {
            if (i <= N && LI[i] > indent) {
                if (is_seq_item(LT[i])) i = parse_seq(i, LI[i])
                else i = parse_block(i, LI[i])
            } else if (i <= N && LI[i] == indent && is_seq_item(LT[i])) {
                i = parse_seq(i, indent)
            } else {
                emit_value(cur_path(), "")
            }
        } else {
            emit_value(cur_path(), rest)
        }
        pop()
    }
    return i
}

# Parse the block sequence that starts at the given line and indentation.
function parse_seq(i, indent,   t, rest, idx, cind, key) {
    idx = 0
    while (i <= N && LI[i] == indent && is_seq_item(LT[i])) {
        t = LT[i]
        rest = ""
        if (t != "-") rest = trim(substr(t, 3))
        cind = LC[i]
        i++
        push(idx)
        if (rest == "") {
            if (i <= N && LI[i] > indent) {
                if (is_seq_item(LT[i])) i = parse_seq(i, LI[i])
                else i = parse_block(i, LI[i])
            } else {
                emit_value(cur_path(), "")
            }
        } else if (split_key(rest)) {
            key = KEY
            push(key)
            if (REST == "") {
                if (i <= N && LI[i] > indent) {
                    if (is_seq_item(LT[i])) i = parse_seq(i, LI[i])
                    else i = parse_block(i, LI[i])
                } else {
                    emit_value(cur_path(), "")
                }
            } else {
                emit_value(cur_path(), REST)
            }
            pop()
            if (i <= N && LI[i] == cind && !is_seq_item(LT[i])) i = parse_block(i, cind)
        } else {
            emit_value(cur_path(), rest)
        }
        pop()
        idx++
    }
    return i
}

# Read one file into the line arrays.
function load_file(path,   raw, ind, t, k) {
    N = 0
    while ((getline raw < path) > 0) {
        sub(/\r$/, "", raw)
        raw = strip_comment(raw)
        if (trim(raw) == "") continue
        ind = 0
        while (substr(raw, ind + 1, 1) == " ") ind++
        t = substr(raw, ind + 1)
        N++
        LI[N] = ind
        LT[N] = t
        if (is_seq_item(t)) {
            k = 2
            while (k <= length(t) && substr(t, k, 1) == " ") k++
            LC[N] = ind + (k - 1)
        } else {
            LC[N] = ind
        }
    }
    close(path)
}

BEGIN {
    CURFILE = ""
    SP = 0
    while ((getline path < LISTFILE) > 0) {
        if (path == "") continue
        CURFILE = path
        load_file(path)
        SP = 0
        if (N > 0) {
            if (is_seq_item(LT[1])) parse_seq(1, LI[1])
            else parse_block(1, LI[1])
        }
    }
    close(LISTFILE)
}
'

# --------------------------------------------------------------------------
# The index builder
# --------------------------------------------------------------------------

# The builder turns the flat "path<TAB>key<TAB>value" stream into one line
# per entry.  The columns of the index are:
#
#   1 id      2 domain     3 slug       4 title      5 difficulty
#   6 safety  7 time       8 status     9 tags       10 entry id
#  11 body    12 materials 13 tools     14 sources
#  15 title (lower case)  16 tags (lower case)  17 body (lower case)
# shellcheck disable=SC2016
ABOOK_INDEX_AWK='
function reset(   i) {
    title = ""; domain = ""; difficulty = ""; safety = ""
    ttc = ""; status = ""; entryid = ""
    ntags = 0; nmaterials = 0; ntools = 0; nsources = 0
    for (i = 1; i <= 512; i++) {
        delete tags[i]
        delete materials[i]
        delete tools[i]
        delete sources[i]
    }
}

function read_body(path,   line, out) {
    out = ""
    while ((getline line < path) > 0) {
        sub(/\r$/, "", line)
        if (out != "") out = out " "
        out = out line
    }
    close(path)
    return out
}

function list_of(arr, n,   i, out) {
    out = ""
    for (i = 0; i < n; i++) {
        if (arr[i] == "") continue
        out = out (out == "" ? "" : ", ") arr[i]
    }
    return out
}

function flush(   parts, n, dom, slug, bodypath, body, low, taglist) {
    if (CUR == "") return
    n = split(CUR, parts, "/")
    dom = parts[n - 1]
    slug = parts[n]
    sub(SUFFIX, "", slug)
    if (domain == "") domain = dom
    bodypath = DOMDIR "/" dom "/" slug ".md"
    body = read_body(ROOT "/" bodypath)
    low = tolower(body)
    gsub(/[\t\r\n]+/, " ", low)
    gsub(/  +/, " ", low)
    taglist = list_of(tags, ntags)
    printf("%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        IDX, domain, slug, title, difficulty, safety, ttc, status, taglist,
        entryid, bodypath, list_of(materials, nmaterials), list_of(tools, ntools),
        list_of(sources, nsources), tolower(title), tolower(taglist), low) > IDXFILE
    IDX++
}

BEGIN {
    FS = "\t"
    IDX = 1
    CUR = ""
    reset()
}

{
    file = $1
    key = $2
    val = $3
    if (file != CUR) {
        flush()
        CUR = file
        reset()
    }
    if (key == "title") { title = val; next }
    if (key == "domain") { domain = val; next }
    if (key == "difficulty") { difficulty = val; next }
    if (key == "safety") { safety = val; next }
    if (key == "time_to_complete") { ttc = val; next }
    if (key == "verification.status") { status = val; next }
    if (key == "id") { entryid = val; next }
    if (key ~ /^tags\.[0-9]+$/) {
        sub(/^tags\./, "", key)
        n = key + 0
        tags[n] = val
        if (n + 1 > ntags) ntags = n + 1
        next
    }
    if (key ~ /^materials_required\.[0-9]+$/) {
        sub(/^materials_required\./, "", key)
        n = key + 0
        materials[n] = val
        if (n + 1 > nmaterials) nmaterials = n + 1
        next
    }
    if (key ~ /^tools_required\.[0-9]+$/) {
        sub(/^tools_required\./, "", key)
        n = key + 0
        tools[n] = val
        if (n + 1 > ntools) ntools = n + 1
        next
    }
    if (key ~ /^sources\.[0-9]+\.title$/) {
        sub(/^sources\./, "", key)
        sub(/\.title$/, "", key)
        n = key + 0
        sources[n] = val
        if (n + 1 > nsources) nsources = n + 1
        next
    }
}

END {
    flush()
    close(IDXFILE)
}
'

# --------------------------------------------------------------------------
# Corpus state
# --------------------------------------------------------------------------

#: The file that holds the parsed corpus.
CORPUS_INDEX_FILE=""

#: The file that holds the number of sidecars the cache was built from.
CORPUS_STAMP_FILE=""

#: The number of entries in the corpus.
CORPUS_COUNT=0

#: The number of sidecars that were read.
CORPUS_SIDECAR_COUNT=0

#: The domains of the corpus, one per line.
CORPUS_DOMAINS=""

#: The directory the sidecars live in.
ABOOK_SIDECARS_DIR=""

#: The directory the Markdown bodies live in.
ABOOK_DOMAINS_DIR=""

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

# _corpus_cache_key <path>
#
# Print a short key that identifies a cache file for the given path.
_corpus_cache_key() {
    printf '%s' "$1" | cksum | awk '{print $1 "-" $2}'
    return 0
}

# _corpus_yaml_get <file> <key>
#
# Print the value of one key of a YAML file, using the awk parser.  The key
# is the dotted path of the scalar, so "verification.status" works.
_corpus_yaml_get() {
    _cyg_file=$1
    _cyg_key=$2
    [ -r "$_cyg_file" ] || return 1
    _cyg_list="${TMPDIR:-/tmp}/abook-yaml.$$"
    printf '%s\n' "$_cyg_file" > "$_cyg_list"
    _cyg_out=$(awk -v LISTFILE="$_cyg_list" "$ABOOK_YAML_AWK" 2>/dev/null | awk -F'\t' -v want="$_cyg_key" '$2 == want { print $3; exit }')
    rm -f "$_cyg_list" 2>/dev/null
    [ -n "$_cyg_out" ] || return 1
    printf '%s\n' "$_cyg_out"
    return 0
}

# _corpus_yaml_dump <file>
#
# Print every scalar of a YAML file as "key<TAB>value" lines.
_corpus_yaml_dump() {
    _cyd_file=$1
    [ -r "$_cyd_file" ] || return 1
    _cyd_list="${TMPDIR:-/tmp}/abook-yaml.$$"
    printf '%s\n' "$_cyd_file" > "$_cyd_list"
    awk -v LISTFILE="$_cyd_list" "$ABOOK_YAML_AWK" 2>/dev/null | cut -f2,3
    rm -f "$_cyd_list" 2>/dev/null
    return 0
}

# --------------------------------------------------------------------------
# Loading
# --------------------------------------------------------------------------

# _corpus_sidecar_list
#
# Write the list of sidecars to the cache directory and print how many there
# are.
_corpus_sidecar_list() {
    _csl_file="$ABOOK_CACHE_DIR/sidecars.lst"
    mkdir -p "$ABOOK_CACHE_DIR" 2>/dev/null || return 1
    if [ -d "$ABOOK_SIDECARS_DIR" ]; then
        find "$ABOOK_SIDECARS_DIR" -type f -name "*$ABOOK_SIDECAR_SUFFIX" 2>/dev/null \
            | LC_ALL=C sort > "$_csl_file"
    else
        : > "$_csl_file"
    fi
    _csl_count=$(wc -l < "$_csl_file" 2>/dev/null | tr -d ' \t' || printf 0)
    case "$_csl_count" in
        ''|*[!0-9]*) _csl_count=0 ;;
    esac
    printf '%s\n' "$_csl_count"
    return 0
}

# _corpus_cache_valid
#
# Return 0 when the cached corpus can be used as it is.
_corpus_cache_valid() {
    [ -f "$CORPUS_INDEX_FILE" ] || return 1
    [ -f "$CORPUS_STAMP_FILE" ] || return 1
    _ccv_stamp=$(cat "$CORPUS_STAMP_FILE" 2>/dev/null || printf 0)
    [ "$_ccv_stamp" = "$CORPUS_SIDECAR_COUNT" ] || return 1
    if [ "$CORPUS_SIDECAR_COUNT" -gt 0 ] && [ -d "$ABOOK_SIDECARS_DIR" ]; then
        _ccv_newer=$(find "$ABOOK_SIDECARS_DIR" -type f -name "*$ABOOK_SIDECAR_SUFFIX" \
            -newer "$CORPUS_INDEX_FILE" -print 2>/dev/null | head -n 1)
        [ -z "$_ccv_newer" ] || return 1
    fi
    return 0
}

# _corpus_build
#
# Parse every sidecar and write the corpus index.
_corpus_build() {
    _cb_list="$ABOOK_CACHE_DIR/sidecars.lst"
    _cb_flat="${TMPDIR:-/tmp}/abook-flat.$$"
    _cb_tmp="${TMPDIR:-/tmp}/abook-index.$$"
    [ -f "$_cb_list" ] || return 1
    awk -v LISTFILE="$_cb_list" "$ABOOK_YAML_AWK" > "$_cb_flat" 2>/dev/null || {
        rm -f "$_cb_flat" 2>/dev/null
        return 1
    }
    : > "$_cb_tmp"
    awk -v ROOT="$ABOOK_ROOT" \
        -v IDXFILE="$_cb_tmp" \
        -v DOMDIR="$ABOOK_DOMAINS_DIRNAME" \
        -v SUFFIX="\\.pnk\\.yaml\$" \
        "$ABOOK_INDEX_AWK" "$_cb_flat" >/dev/null 2>&1
    _cb_rc=$?
    rm -f "$_cb_flat" 2>/dev/null
    if [ "$_cb_rc" -ne 0 ] || [ ! -s "$_cb_tmp" ]; then
        rm -f "$_cb_tmp" 2>/dev/null
        return 1
    fi
    mv -f "$_cb_tmp" "$CORPUS_INDEX_FILE" 2>/dev/null || {
        rm -f "$_cb_tmp" 2>/dev/null
        return 1
    }
    printf '%s\n' "$CORPUS_SIDECAR_COUNT" > "$CORPUS_STAMP_FILE" 2>/dev/null || true
    return 0
}

# _corpus_load <root>
#
# Load the corpus of the repository at the given root.  The parsed corpus is
# cached, so a second run is instantaneous.  The root of the application is
# not changed: the caller decides which repository the reader works on.
_corpus_load() {
    _cl_root=$1
    ABOOK_SIDECARS_DIR="$_cl_root/$ABOOK_SIDECARS_DIRNAME"
    ABOOK_DOMAINS_DIR="$_cl_root/$ABOOK_DOMAINS_DIRNAME"
    CORPUS_INDEX_FILE="$ABOOK_CACHE_DIR/corpus-$(_corpus_cache_key "$_cl_root").tsv"
    CORPUS_STAMP_FILE="$ABOOK_CACHE_DIR/corpus-$(_corpus_cache_key "$_cl_root").stamp"
    mkdir -p "$ABOOK_CACHE_DIR" 2>/dev/null || true
    CORPUS_SIDECAR_COUNT=$(_corpus_sidecar_list)
    if ! _corpus_cache_valid; then
        _corpus_build || true
    fi
    if [ -f "$CORPUS_INDEX_FILE" ]; then
        CORPUS_COUNT=$(wc -l < "$CORPUS_INDEX_FILE" 2>/dev/null | tr -d ' \t' || printf 0)
        case "$CORPUS_COUNT" in
            ''|*[!0-9]*) CORPUS_COUNT=0 ;;
        esac
    else
        CORPUS_COUNT=0
    fi
    if [ -f "$_cl_root/$ABOOK_INDEX_RELPATH" ]; then
        ABOOK_INDEX_SOURCE="$ABOOK_INDEX_RELPATH"
    else
        ABOOK_INDEX_SOURCE="scan"
    fi
    return 0
}

# _corpus_entry <index>
#
# Print the index line of one entry.
_corpus_entry() {
    [ -f "$CORPUS_INDEX_FILE" ] || return 1
    awk -v n="$1" 'NR == n { print; exit }' "$CORPUS_INDEX_FILE"
    return 0
}

# _corpus_field <index> <column>
#
# Print one column of one entry.  The columns of the index are separated by
# tabs.
_corpus_field() {
    [ -f "$CORPUS_INDEX_FILE" ] || return 1
    awk -F'\t' -v n="$1" -v c="$2" 'NR == n { print $c; exit }' "$CORPUS_INDEX_FILE"
    return 0
}

# _corpus_find_by_id <entry-id>
#
# Print the index of the entry with the given id.
_corpus_find_by_id() {
    [ -f "$CORPUS_INDEX_FILE" ] || return 1
    awk -F'\t' -v id="$1" '$10 == id { print $1; exit }' "$CORPUS_INDEX_FILE"
    return 0
}

# _corpus_find_by_slug <slug>
#
# Print the index of the entry whose slug matches, either exactly or as a
# suffix of its path.
_corpus_find_by_slug() {
    [ -f "$CORPUS_INDEX_FILE" ] || return 1
    awk -F'\t' -v slug="$1" '$3 == slug { print $1; exit }' "$CORPUS_INDEX_FILE"
    return 0
}

# _corpus_built_version
#
# Print the version of the corpus that was last built, as recorded in
# build/manifest.json.  Nothing is printed when the file is missing.
_corpus_built_version() {
    _cbv_file="$ABOOK_ROOT/$ABOOK_INDEX_RELPATH"
    _cbv_manifest="$ABOOK_ROOT/build/manifest.json"
    [ -r "$_cbv_manifest" ] || return 1
    sed -n 's/.*"kb_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_cbv_manifest" | head -n 1
    return 0
}

# _corpus_domain_rows
#
# Print one line per domain: the name, the number of entries and the
# description of the domain.
_corpus_domain_rows() {
    [ -f "$CORPUS_INDEX_FILE" ] || return 0
    _cdr_desc="$ABOOK_ROOT/$ABOOK_DOMAINS_DIRNAME/README.md"
    awk -v list="$MANIFEST_DOMAINS" -v descfile="$_cdr_desc" '
        BEGIN {
            n = split(list, names, " ")
            for (i = 1; i <= n; i++) if (names[i] != "") order[++m] = names[i]
            while ((getline line < descfile) > 0) {
                if (substr(line, 1, 1) != "|") continue
                sub(/^\|/, "", line)
                sub(/\|[ \t]*$/, "", line)
                k = split(line, cells, "|")
                if (k < 2) continue
                first = cells[1]
                second = cells[2]
                gsub(/^[ \t]+/, "", first); gsub(/[ \t]+$/, "", first)
                gsub(/^[ \t]+/, "", second); gsub(/[ \t]+$/, "", second)
                if (first !~ /^\[/) continue
                if (!match(first, /^\[[^]]+\]/)) continue
                nm = substr(first, RSTART + 1, RLENGTH - 2)
                if (nm != "") desc[nm] = second
            }
            close(descfile)
        }
        { count[$2]++ }
        END {
            for (i = 1; i <= m; i++) {
                name = order[i]
                if (!(name in seen)) {
                    seen[name] = 1
                    printf "%s\t%d\t%s\n", name, count[name] + 0, desc[name]
                }
            }
            for (name in count) {
                if (!(name in seen)) {
                    seen[name] = 1
                    printf "%s\t%d\t%s\n", name, count[name] + 0, desc[name]
                }
            }
        }
    ' "$CORPUS_INDEX_FILE"
    return 0
}

# --------------------------------------------------------------------------
# The disclaimer
# --------------------------------------------------------------------------

# _corpus_disclaimer
#
# Print the summary section of docs/DISCLAIMER.md, quoted verbatim.
_corpus_disclaimer() {
    _cd_file="$ABOOK_ROOT/$ABOOK_DISCLAIMER_RELPATH"
    [ -r "$_cd_file" ] || return 1
    awk '
        /^##[ \t]/ {
            if (inside) exit
            heading = $0
            sub(/^##[ \t]*/, "", heading)
            n = split(heading, parts, /[. \t]/)
            inside = (parts[1] == "12")
            next
        }
        inside { print }
    ' "$_cd_file" | sed '/./,$!d'
    return 0
}

# _corpus_disclaimer_full
#
# Print docs/DISCLAIMER.md, quoted verbatim.
_corpus_disclaimer_full() {
    _cdf_file="$ABOOK_ROOT/$ABOOK_DISCLAIMER_RELPATH"
    [ -r "$_cdf_file" ] || return 1
    cat "$_cdf_file"
    return 0
}
