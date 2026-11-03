# Proposing a Topic

A topic is a subject area that deserves its own domain: a field with its
own vocabulary, its own sources and its own safety profile. This page
explains what a topic is, what it has to satisfy before it is accepted,
and how it becomes a published domain with entries in it.

`chemistry`, `silicon`, `ship` and `quantum` were all added this way.

## Topic or entry

| | Entry | Topic |
|---|---|---|
| Scope | One procedure or one concept | A whole subject area |
| Vocabulary | Borrowed from its domain | Defines its own |
| Sources | A few, cited in the entry | A body of primary literature |
| Safety profile | One level for the work | A profile across the field |
| Created by | `scripts/new_entry.py` | `scripts/new_topic.py` |
| Lives in | One domain directory | A new domain directory |

Three rules of thumb settle most cases:

- If a reader would search for it as a question with one answer, "how do
  I make fire", it is an entry.
- If a reader would search for it as a field, "chemistry", "shipbuilding",
  it is a topic.
- If you cannot name the first five entries, it is not a topic yet. It is
  an entry with a long title.

## The criteria a topic must meet

### 1. A real and durable need

The need exists, the existing domains do not cover it, and it will still
exist in ten years.

- Name the reader and the situation: a person rebuilding a workshop needs
  to do X.
- Show the gap. The domain table in `domains/README.md` lists every
  domain in the book; show that none of them covers this.
- Durable means independent of a brand, a vendor, a patent, a war or a
  current event. A subject that depends on one manufacturer's process
  note is an entry, not a domain.

### 2. A distinct body of primary sources

The literature exists, it is primary, and it is public domain or openly
licensed.

- Name at least three sources you have read, and record the licence of
  each.
- Primary sources beat summaries: standards, manuals, treatises, field
  manuals, official guidance, open textbooks, and the original papers.
- If the field's literature is paywalled, or cannot be read offline, the
  topic cannot be written to this book's standard. That is a reason to
  decline, not to lower the bar.

### 3. A reader who would act on it

Someone must be able to do something after reading, not merely understand
something.

- The test: after reading an entry in this domain, can the reader make,
  fix, measure, build, identify or protect something?
- If the only outcome is awareness or opinion, the subject belongs in
  `society` or `knowledge`.

### 4. A safety profile that can be stated

The field's dominant hazards can be named, and a safety level can be
assigned honestly to the work it describes.

- Name the hazards, the controls and the competence the work needs.
- Every entry in this book carries a level, and a field whose risk
  cannot be characterised cannot be graded. That is a safety problem, not
  a formatting one.

### 5. A scope one or two people can write

The working minimum is five to eight entries. More than that and the
proposal needs a team, a maintainer and a plan before the domain opens.

- If the honest scope is a hundred entries, propose the first eight and
  say in the issue that the rest is planned.
- If eight entries is all there is, say so. A small honest domain is
  better than a large one nobody finishes.

### 6. It is not a near-duplicate of an existing domain

- Read the domain table in `domains/README.md` and then the entry list in
  each domain's own README.
- If the subject is a special case of an existing domain, it is an entry
  in that domain. If it shares a vocabulary and a safety profile with an
  existing domain, it is that domain.
- A new domain also needs a name, a description, an icon and an accent
  colour that it can own without being confused with a neighbour.

## From proposal to published domain

### Step 1: Search the book first

Read `domains/README.md`, then the entry list in every domain's README,
then search the whole corpus. A proposal that duplicates an existing entry
will be closed with a pointer to it.

### Step 2: Open the issue

Use the New Topic issue template, `.github/ISSUE_TEMPLATE/new-topic.md`,
which `README.md` and `CONTRIBUTING.md` point to. If it is not offered in
the issue picker, open a normal issue and use the headings below.

Fill in:

- The subject, in one paragraph.
- Who needs it, and in what situation.
- What a reader should be able to do afterwards.
- The sources, with their licences.
- The safety profile, and the level you think the work deserves.
- The first five entry titles.
- The slug you want, and the title and one-line description for the apps.

### Step 3: Maintainer discussion

A core maintainer and one domain maintainer respond. The discussion
settles four things:

- New domain, or an existing one.
- The slug, the title and the one-line description.
- The first five entries, and who writes them.
- The domain maintainer who will own it.

Decisions are taken by rough consensus of the relevant maintainers, with a
seven day comment period, and are recorded in `governance/DECISION-LOG.md`.

### Step 4: Scaffold the domain

```bash
python scripts/new_topic.py ceramics --title "Ceramics & Glass" \
    --description "Clay bodies, glazes, kiln design and testing"
```

The slug must be lower case letters, digits and hyphens. The script
refuses to run if the domain directory already exists, and it never
overwrites an existing registration.

It creates:

- `domains/<slug>/README.md`, the domain index, with the title, the
  description and an empty entry table.
- `sidecars/<slug>/`, the sidecar directory for the domain.

It registers the domain in:

- `schemas/sidecar.schema.json`, so sidecars in the new domain validate.
- `manifest.toml`, the domain list of the knowledge base.
- `api/openapi.yaml`, the domain filter of the search API.
- `scripts/mcp_server.py`, the domain filter of the MCP server.
- `android/tools/export_content.py`, the title, description, icon and
  accent colour the app shows.
- `domains/README.md`, the row in the domain table.

The script prints every path it created or changed. Review that diff
before you commit it, because the replacements are anchored to fixed
strings in those files.

### Step 5: Finish the registration

The scaffold is mechanical and leaves three things for a human:

- Replace the placeholder icon and colour in `android/tools/export_content.py`.
  The script inserts the `menu_book` icon and the colour `#546E7A` for
  every new domain.
- Fill in the maintainer column of the domain table in `domains/README.md`.
  The scaffold leaves a placeholder there.
- Name the domain maintainer in the domain maintainer table in
  `MAINTAINERS.md`.

### Step 6: Write the first entries

```bash
python scripts/new_entry.py ceramics clay-body-formulation \
    "Clay Body Formulation"
```

Five to eight entries, written to `docs/ENTRIES.md`, with a sidecar each.

### Step 7: Review, translate and merge

- The domain maintainer reviews the entries. Two reviewers are needed
  before an entry can claim `peer-reviewed`.
- The entries need their translations, for the reason given under
  "Maintaining a topic" below.
- Every check in `docs/ENTRIES.md` has to pass, and the Markdown lint and
  the link check run in CI on every push.
- Merge, and the domain appears in the apps at the next release.

## How many entries a topic needs

Five to eight entries, as a working minimum, before a domain is accepted.

- Fewer than five and the domain is a stub: the app shows a category with
  one or two entries, and a search inside it returns a list too short to
  be useful.
- More than eight and the proposal is a book rather than a topic. Scope it
  down, and propose a second topic later.
- The set should span the domain's safety profile: at least one `green`
  entry, one `yellow`, and one `red` where the field has red work.
- The set should also span the difficulty levels, so that a reader can
  find something they can act on today.

### What a good first entry looks like

- It is the entry a reader needs first in the field: the concept the rest
  of the domain hangs on, or the first operation.
- It stands alone. A reader with no other entry in the domain can carry
  it out from the page.
- It has the strongest source base of anything in the domain.
- It sets the vocabulary, so that the later entries can refer to it
  without repeating it.
- It is not the entry that needs the most equipment.

The first entry of `chemistry` is a good model:
`domains/chemistry/stoichiometry-calculation.md` is a calculation rather
than a reaction, so it needs no laboratory and no hazardous reagent, and
it gives the whole domain its unit conventions, its molar masses and its
habit of carrying significant figures.

## How a topic appears in the apps

### The domain metadata

`android/tools/export_content.py` holds a `DOMAIN_META` table. Each domain
is one tuple of four fields:

```python
"chemistry": ("Chemistry & Laboratory",
              "Reactions, analysis, separation, safety",
              "science", "#00838F"),
```

1. The domain title, shown as the heading of the domain screen.
2. The one-line description, shown under the title and in the domain list.
3. The icon, a Material Symbols name such as `science`, `sailing` or
   `bolt`.
4. The accent colour, a six digit hex value such as `#00838F`.

Rules for choosing them:

- The title is the name of the field, not the slug: "Chemistry &
  Laboratory", not "chemistry".
- The description is short enough to survive a narrow phone screen: four
  to six words, no full stop.
- The icon must be a real Material Symbols name, and it should not be
  one the reader already associates with another domain. `memory` is
  currently used by both `silicon` and `computers`.
- The colour must read clearly on the app background, and it must not be
  so close to a neighbouring domain's colour that the two look the same.

### The domain table

`domains/README.md` holds a table with three columns: the domain, a
one-line description, and the maintainer. The domain name is linked to the
domain's own index, relative to that file. The scaffold writes the row
with a placeholder in the maintainer column.

### The domain index

`domains/<slug>/README.md` is the index a reader lands on when they open
the domain. It is a table with one row per entry:

```text
| Entry | Difficulty | Safety | Time |
|-------|------------|--------|------|
| Stoichiometry and Limiting Reagents | novice | green | hours |
```

The entry title is linked to the entry's Markdown file, relative to the
domain directory. The domain maintainer keeps this table current, and a
new entry is not complete until its row exists.

## Maintaining a topic

### The domain maintainer

Every domain has a domain maintainer, elected per domain under
`governance/ROLES.md`, serving a twelve month renewable term. The
maintainer:

- Reviews pull requests for the domain and merges them.
- Keeps the domain README index current.
- Nominates contributors for the verifier role.
- Keeps the domain's safety grading consistent.

Recusal applies as everywhere else: a reviewer must recuse from an entry
they authored, and a verifier must not field-test their own entry. A
domain with no maintainer is reviewed by a core maintainer, and the
maintainer column in `domains/README.md` keeps its placeholder until
someone takes it.

### The review queue

The review queue for a domain is its open pull requests. A new domain
starts empty, and the first five entries are usually reviewed by the
person who wrote them plus one other contributor. Recruit a second
reader early: two reviewers are needed for `peer-reviewed`, and it is the
cheapest status to reach.

### The translation obligation

A new domain needs its entries, and their sidecars, in every supported
language, or the i18n coverage check fails.

- `scripts/validate_i18n.py` measures coverage as the share of canonical
  entries that have a translation sidecar, and compares it with a target
  per language: Spanish, French, German and Portuguese at 100 percent,
  Hindi, Arabic and Chinese at 80 percent, Swahili at 60 percent.
- Every new English entry lowers coverage for every language, so the
  translations of a domain's first entries are part of accepting the
  domain, not a task for later.
- A translated entry lives at
  `i18n/translations/<lang>/<domain>/<slug>.md`, with a matching
  `.pnk.yaml` sidecar carrying `translation_of` and `language`.
- The interface strings live in `i18n/strings/<lang>.yaml`. If a domain
  introduces new interface wording, the same key has to appear in every
  language file.
- Translate the words, never the values. Numbers, units, standard numbers,
  safety levels and difficulty levels stay exactly as the English original
  has them.

## Worked examples

### chemistry: a proper laboratory

The book had water, fire, soil and materials, and no way to make a
reagent, measure a quantity or control a reaction. Agriculture and
materials covered the outputs of chemistry without covering the
discipline. The need was real and durable, the textbooks and national
laboratory safety guidance were openly licensed, and the safety profile
was statable: gloves and goggles for routine work, and `red` for
distillation and for flammable solvents. The domain opened with eighteen
entries, from stoichiometry to solvent extraction, and gave the rest of
the book a shared vocabulary for quantities, purity and reagents.

### silicon: the tools that make electronics

`computers` covered circuits, firmware and systems, and `materials`
covered glass and metals, but nothing covered the material the whole
industry rests on. The need was to build the tools, not only to use them.
The sources were semiconductor processing texts and public process
documentation, and the safety profile was acids and heated quartz at
first, rising to high voltage and cryogenics in the later entries. The
domain took purification, crystal growth, wafers, fabrication and devices,
and it gave `computers` the vocabulary of the substrate everything sits on.

### ship: from using vessels to building them

`transport` covered carts, pack animals, ferries and bicycles: the use of
vehicles. Rebuilding a civilisation needed the other half, the ability to
build the vessel: hull forms, lofting, shipyard layout, welding,
propulsion. The classical naval architecture treatises are public domain,
classification society rules supply the regulated detail, and the safety
profile is `red` for much of the field: hot work, welding, confined
spaces, heavy lifting and stability. The domain begins where `transport`
stops.

### quantum: the hardest field that still qualified

A reader rebuilding a civilisation is not going to build a quantum
computer. That is not the test. The test is whether there is a durable
need, a body of primary sources that can be read, a reader who will act on
it, and a safety profile that can be stated. For quantum the answer was
yes: the laboratory instruments are the hard part, and they are built
from the machinery of the domains that came before. The sources are the
primary literature, much of it openly available, and the safety profile
is dominated by cryogenics, stored magnetic energy and microwave and
laser hazards. The domain shows that the criteria accept a hard field,
because the criteria are about need, sources, use, safety and scope, not
about how difficult the science is.

## Checklist for a topic proposal

- [ ] The subject is not covered by one of the sixteen domains.
- [ ] The need is real, durable, and not served by an existing domain.
- [ ] The reader is named, and the reader will act on the content.
- [ ] At least three primary sources are named, with their licences, and
  they are openly licensed.
- [ ] The dominant hazards are named, and a safety profile can be stated.
- [ ] The scope fits one or two people: five to eight entries.
- [ ] The slug is lower case, short and stable.
- [ ] The domain title and the one-line description are drafted.
- [ ] The icon and the accent colour are chosen, and are not already in
  use next door.
- [ ] The first five entry titles are listed.
- [ ] A domain maintainer is willing to take it, or the issue says who to
  ask.
- [ ] The translation plan is stated for the first entries.
- [ ] The issue was opened with the New Topic template, and the reasoning
  is recorded in the decision log.
