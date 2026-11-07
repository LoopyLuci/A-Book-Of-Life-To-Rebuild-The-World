# Writing an Entry

Every entry in this book is two files that describe one thing: a Markdown
file that a person reads, and a YAML sidecar that a machine reads. This page
is the reference for writing them.

In short:

- One entry covers one procedure or one concept. Not a chapter.
- Every entry uses the same seven sections, in the same order.
- Grade the safety honestly, and say what training the work needs.
- Every claim traces to a source you have actually read.
- When you are not sure, say so, and leave the entry at `draft`.

## The two halves of an entry

| Half | Path | Holds |
|------|------|-------|
| Markdown | `domains/<domain>/<slug>.md` | The prose |
| Sidecar | `sidecars/<domain>/<slug>.pnk.yaml` | The metadata |

The slug is the filename without its extension, and it is the same in both
places: `domains/survival/making-fire.md` and
`sidecars/survival/making-fire.pnk.yaml` are one entry. The script
`scripts/new_entry.py` creates both halves and refuses to overwrite an
existing pair.

### The Markdown half

This is the half a reader reads, and it is the half a skilled contributor
writes. It starts with the title, the metadata line and the reference
notice, and then it runs through the seven sections in a fixed order. The
search index chunks the book by heading, so these headings are also what a
reader sees when a search result is expanded.

### The sidecar half

This is the half the machines read. The index, the search API, the SDKs,
the MCP server and the apps all take their metadata from it, and
`scripts/validate.py` checks every sidecar against
`schemas/sidecar.schema.json`. The validator also fails when a sidecar has
no Markdown file at the matching path, so the pair cannot drift apart by
accident.

### When the two halves disagree

The reader sees one version and the app shows another. That is a bug, and
it is the most common review comment in this project.

- The sidecar is authoritative for metadata: title, domain, difficulty,
  safety, verification state, sources, tags.
- The Markdown is authoritative for the substance: the procedure, the
  quantities, the safety notes, the limits.
- The Android app renders the title, the verification block and the source
  list from the sidecar, and strips those blocks out of the Markdown body.
  A disagreement between the halves is therefore visible on the device,
  not just in a diff.
- Change a title, a difficulty or a safety level in both files in the same
  commit. Never let the sidecar claim a safety level that the body does
  not justify.

## The shape of an entry

### Section order

The order is fixed. Do not add, remove or rename sections.

| Section | What belongs in it |
|---------|--------------------|
| Overview | What the reader can do afterwards. |
| Prerequisites | What must already be true. |
| Materials & Tools | The consumables and the instruments. |
| Procedure | The numbered steps. |
| Safety Notes | The real hazard and the protection. |
| Verification | The review and test state. |
| Sources | Where the claims came from. |

### A worked skeleton

This is a complete entry, taken from `domains/survival/making-fire.md`. The
title line, the metadata line and the italic notice are copied exactly as
they appear in every real file.

```markdown
# Making Fire

> **Domain:** survival | **Difficulty:** novice | **Safety:** yellow

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Fire provides warmth, light, cooking, water purification, and protection.
Mastering multiple ignition methods ensures resilience across environments.

## Prerequisites

- None

## Materials & Tools

- Tinder (dry grass, birch bark, char cloth)
- Kindling (small dry twigs)
- Fuel (larger dry wood)
- Ignition source (one of the methods below)

## Procedure

### Method 1: Ferro Rod

1. Scrape magnesium from the rod onto a small pile of tinder.
2. Hold the striker at a 45° angle to the rod.
3. Draw the striker down the rod firmly to create sparks.
4. Direct sparks into the magnesium pile.
5. Once the tinder catches, add kindling gradually.

### Method 2: Bow Drill

1. Carve a fireboard with a shallow depression and a notch.
2. Cut a spindle about 20 cm long, pointed at both ends.
3. Make a bow with a flexible branch and cordage.
4. Use a socket (stone or hardwood) to press the spindle.
5. Saw the bow back and forth with steady pressure.
6. When the notch glows, transfer the ember to tinder.

## Safety Notes

- Never build a fire under overhanging branches.
- Keep a water source or sand nearby.
- Avoid flammable clothing when tending fire.
- Do not leave fires unattended.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- US Army Field Manual FM 21-76 (public domain)
- Boy Scouts of America Handbook (public domain, historical)
```

The metadata line is a single blockquote with three fields, separated by
pipes: the domain slug, the difficulty level and the safety level. The
notice that follows it is fixed text. Both are part of the contract with
the apps, so copy them rather than paraphrasing them.

## Writing each section

### Overview

Write what the entry enables, not what the subject is. Two or three
sentences: the key principle, and what the reader will be able to do
afterwards.

- Good: "Stoichiometry turns a balanced equation into quantities you can
  weigh out."
- Bad: "Stoichiometry is the branch of chemistry concerned with the
  quantitative relationships of chemical reactions."

A definition that restates the title wastes the reader's first minute. An
overview that promises a capability earns it.

### Prerequisites

List what must already be true before the reader starts: skills they need,
entries they should read first, equipment already in hand, a site
condition that has to be met.

- Use `- None` when nothing is required. `domains/survival/making-fire.md`
  does exactly this.
- Every prerequisite that is another entry in this book must also appear
  in the sidecar `prerequisites` array, as a `pnk:` identifier.
- If the work needs a qualification, a permit, a supervisor or a second
  person, it belongs here as well as in Safety Notes.
- "Basic chemistry" is not a prerequisite. "A balance that reads to 0.01 g"
  is.

### Materials & Tools

Be concrete. Sizes, quantities, grades, capacities and tolerances, every
time.

- "Round-bottom or flat-bottom flask, 100 to 500 mL", not "a flask".
- "Tinder (dry grass, birch bark, char cloth)", not "dry material".
- Separate consumables from instruments if the reader has to buy them
  separately.
- Name a substitute when the ideal tool is scarce, and say what accuracy
  the substitute costs.
- Say what precision the procedure needs, and what happens if the reader
  cannot reach it.
- Mirror the list in the sidecar `materials_required` and
  `tools_required` arrays.

### Procedure

Numbered steps, verb first. "Heat the mantle to 120 °C", not "the mantle
should be heated".

- One action per step. If a step contains three actions, split it.
- Put the quantity in the step, with its unit, because readers jump to
  step six and work from there.
- Use `###` sub-sections when there is more than one method or one stage:
  "Method 1: Ferro Rod", "Stage 2: Convert Masses to Moles".
- Give the numbers so the result is reproducible, and say what "finished"
  looks like.
- Include the failure case: what the step looks like when it has gone
  wrong, and what to do about it.
- End with clean-up, disposal and stowage.
- Do not write steps the reader is not equipped to take. If a step belongs
  to a licensed technician, say so and keep it out of the numbered list.

### Safety Notes

Every safety note states three things: the real hazard, the protection,
and the training the work requires.

- Name the hazard: "Fire is the dominant hazard: vapour-air mixtures
  ignite readily", not "be careful".
- Give the control: protective equipment, ventilation, exclusion zone,
  emergency action, what to do when something goes wrong.
- Give the competence: who may do the work, under what supervision, with
  what training and authorisation.
- Cite the standard or the regulation that applies, by number and title.
- Say what the reader must not do. Prohibitions are as useful as
  procedures.
- Keep the same list in the sidecar `hazards` array. The two must match.
- Safety Notes are not a risk assessment, and they do not replace one.

### Verification

The block records the review and test state, and nothing else.

- Use the em dash character "—" for a value you do not have, exactly as
  the skeleton shows.
- Keep the three labels in order: Status, Tested by, Date.
- Never claim a status you have not earned. Most entries are `draft`, and
  that is an honest state, not a defect.
- Mirror the block in the sidecar `verification` object, including
  `reviewers`, `location` and `notes` when they exist.

### Sources

One bullet per source, naming the title, the author, the year and the
licence.

- The address goes in the sidecar source record, in its `url` field. The
  body text carries no URLs, because the apps turn the sidecar value into
  a clickable source row.
- Record the licence of the source, not the licence of this book. The
  permitted values are `public-domain`, `CC0-1.0`, `MIT`, `CC-BY-4.0`,
  `CC-BY-SA-4.0`, `CC-BY-NC-4.0`, `CC-BY-SA-3.0-IGO`,
  `CC-BY-NC-SA-3.0-IGO`, `original`, `field-tested` and
  `permission-granted`. Use `permission-granted` only for a source that is
  read and cited but is not openly licensed, and `original` only for
  material written for this book.
- Every entry carries at least four sources, and at least one of them is
  in a language other than English. Record that language in the `language`
  field of the source record, as an ISO 639-1 code. A reader whose first
  language is Spanish, Arabic, Korean or Swahili should be able to follow
  the trail without translating first.
- Name each source once, in this section, and make sure this section
  covers every claim in the entry that needs support.
- A source you have not read is not a source. Reading the summary of a
  source is not the same as reading it.
- A link you have not opened is not verified. When you add a source with a
  `url`, open it once and confirm it is the document you think it is.

## The sidecar

The field list is fixed by `schemas/sidecar.schema.json`, and the schema
rejects any field that is not in it. Required fields are `id`, `title`,
`domain`, `tags`, `difficulty`, `safety`, `sources` and `verification`.

| Field | Required | Meaning | A good value |
|---|---|---|---|
| `id` | Yes | Stable identifier, ULID based | Written by `new_entry.py` |
| `title` | Yes | The entry title | `Stoichiometry and Limiting Reagents` |
| `domain` | Yes | Which domain it belongs to | `chemistry` |
| `tags` | Yes | Lower case search terms | `stoichiometry`, `molar-mass` |
| `difficulty` | Yes | Skill the work demands | `novice` |
| `safety` | Yes | Summary of the risk | `green` |
| `time_to_complete` | No | How long one run takes | `hours` |
| `yield` | No | Output or capacity, with units | `2 L of 0.1 mol/L solution` |
| `season` | No | When it works best | `late winter` |
| `storage` | No | Shelf life of inputs or outputs | `Sealed, dark, 6 months` |
| `cost` | No | Money to do it once | `low` |
| `hazards` | No | What can hurt the reader | `Fire; vapour inhalation` |
| `resource_budget` | No | Inputs for a stated batch | `labor_hours: 1.5` |
| `lifespan` | No | Service life of the result | `500 hours of lamp life` |
| `maintenance` | No | Routine servicing | `Clean the wick weekly` |
| `limits` | No | Where it stops working | `Assumes laboratory-grade purity` |
| `prerequisites` | No | Entry ids needed first | See the example below |
| `materials_required` | No | Consumables and amounts | `Sodium chloride` |
| `tools_required` | No | Instruments and precision | `Balance to 0.01 g` |
| `sources` | Yes | Where the claims come from | See the example below |
| `verification` | Yes | Review and test state | `status: draft` |
| `links` | No | Related entry ids | See the example below |
| `geographic_applicability` | No | Where it applies | `universal` |
| `language` | No | Language of this file | `en` |
| `translation_of` | No | The original entry id | See the example below |
| `media` | No | Images, audio, models, diagrams | `type: image` |

The `id` follows the pattern `pnk:` then 26 upper case characters from the
Crockford alphabet, then the domain, then the slug. Tags are lower case
letters, digits and hyphens, and they must be unique. `time_to_complete`
is one of `minutes`, `hours`, `days`, `weeks` and `months`. `cost` is one
of `low`, `medium` and `high`. `geographic_applicability` is a list drawn
from `temperate`, `arid`, `tropical`, `arctic` and `universal`.

### A filled sidecar

The shape below follows the file that
`scripts/new_entry.py` writes, with the fields filled in the way a
finished entry should have them.

```yaml
id: pnk:01KDVDNA00DPPSPVSYXKQMR8CV/chemistry/stoichiometry-calculation
title: Stoichiometry and Limiting Reagents
domain: chemistry
tags:
- chemistry
- stoichiometry
- molar-mass
- limiting-reagent
difficulty: novice
safety: green
time_to_complete: hours
yield: 0.15 mol of hydrogen
season: ''
storage: ''
cost: low
hazards:
- Chemical burns and splashes; wear splash goggles and gloves.
resource_budget:
  batch: 10 g of zinc with 50 mL of 3 mol/L hydrochloric acid
  labor_hours: 1.5
  energy_kwh: 0
  water_liters: 2
lifespan: ''
maintenance: ''
limits:
- Values assume laboratory-grade purity and calibrated glassware.
prerequisites: []
materials_required:
- Sodium chloride, 500 g
- Zinc granules, 250 g
tools_required:
- Balance that reads to 0.01 g
- Graduated cylinders, 10 mL and 100 mL
sources:
- title: Introduction to Chemistry
  license: public-domain
  language: en
- title: Introducción a la química
  author: Wikipedia contributors
  url: https://es.wikipedia.org/wiki/Qu%C3%ADmica
  license: CC-BY-SA-4.0
  language: es
verification:
  status: draft
links:
- pnk:01KDVDNA003C3R12TEZPFVS263/chemistry/distillation-fractionation
geographic_applicability:
- universal
language: en
media: []
```

Leave a field empty with `''` or `[]` when it genuinely does not apply.
Do not write a placeholder word such as "n/a" or "none": the schema
accepts empty strings and empty lists, and an empty value is easier for
the index and the apps to handle than a word.

### Cross-references

`prerequisites` and `links` hold entry identifiers, not titles. A
prerequisite is an entry the reader should have read first. A link is an
entry that this one works with, depends on, or replaces. Both are lists of
`pnk:` identifiers of the form `pnk:<26 characters>/<domain>/<slug>`.

Name the other entry in words in the body text. The sidecar carries the
machine-readable half of the reference, and the apps use it to build the
navigation.

## Safety levels

There are three, and they are a summary of risk, never a risk assessment.

| Level | Means |
|---|---|
| `green` | Ordinary care and normal protective equipment. |
| `yellow` | Real hazards; protection and supervision needed. |
| `red` | Serious risk of injury, death, fire or toxic exposure. |

Typical work at each level:

- `green`: measuring, calculating, reading, assembling.
- `yellow`: fire, power tools, solvents, mains electricity, height.
- `red`: distillation, cryogenics, surgery, pressure vessels, high
  voltage.

A `red` entry describes work that is performed only with appropriate
training, supervision, protective equipment, facilities and authorisation.
It also carries a real risk of injury, death, fire, toxic exposure,
contamination or legal liability.

### Choosing the level

1. Grade the worst credible outcome of the procedure as written, not the
   average case and not the reader's competence.
2. Grade the entry, not the reader. A procedure that a trained technician
   performs in a fume hood may still be `yellow`, but the entry must say
   who is allowed to do it.
3. Combine hazards. Fire plus a reactive chemical is `red` even when each
   one alone is `yellow`. The domain index in `domains/README.md` records
   the same rule: safety levels escalate when hazards are combined.
4. Grade for scale. 5 mL in a fume hood is not 5 L on a bench, and a
   campfire is not a bonfire.
5. Name the standard when one applies. If a procedure is regulated, give
   the regulation and the qualification it requires.
6. Never lower a level to make an entry publishable. If the work needs a
   qualification, the entry says so and the level stays where it is.
7. When two entries in the same domain disagree, take the higher level,
   and open an issue.

### What a safety level is not

A safety level is a summary of the risk as the author understood it. It is
not a risk assessment and it does not replace one. A `green` entry is not
a guarantee of safety, and a `red` entry is not a description of how to do
the work without the training it says the work needs.

## Difficulty levels

There are four, and they grade the procedure rather than the subject.

| Level | Who it is for | Assumes |
|---|---|---|
| `novice` | A reader with no training | Ordinary tools and a sober mind |
| `apprentice` | Some experience of the field | Can diagnose a common failure |
| `journeyman` | An experienced practitioner | Judgement about tolerances |
| `master` | A specialist | Formal training, equipment, authority |

- Grade the hardest step, not the average step.
- Difficulty and safety are separate axes. A calculation can be `green` and
  `novice`; a solvent can be `red` and `apprentice`.
- If the procedure needs a certificate, a licence or a supervisor, it is
  `master` and it is `red`.
- Raise the level when the entry assumes equipment the reader is unlikely
  to own, and say what a poorer substitute would cost.

## The verification lifecycle

The lifecycle is `draft` to `peer-reviewed` to `field-tested` to
`deprecated`, and `manifest.toml` declares it together with the number of
reviewers it takes to advance an entry.

| Status | Means | Does not mean |
|---|---|---|
| `draft` | Unchecked. | That it is wrong or unsafe. |
| `peer-reviewed` | Read by two contributors. | That it was tested. |
| `field-tested` | Carried out and reported. | That it is safe for you. |
| `deprecated` | Superseded, kept. | That the old method is forbidden. |

How each status is earned:

- `draft`: by writing the entry honestly. This is where most entries
  stay, and it is not a defect.
- `peer-reviewed`: two contributors read the entry against its sources and
  are named in `verification.reviewers`. `manifest.toml` sets the number
  of reviewers at two.
- `field-tested`: a verifier carried out the procedure and filed a
  report in `field-tests/`, validated against
  `schemas/field-test.schema.json`.
- `deprecated`: a better entry exists. The old entry stays in the book
  with a pointer to its replacement, and the body says why.

The status is a statement about the review, never a warranty. A field test
is a report from one place at one time. It is evidence, not proof.

`scripts/verify.py` is the state machine that records the moves:

```bash
python scripts/verify.py show <entry_id>
python scripts/verify.py advance <entry_id> --to <status> --actor <you>
```

An entry can be sent back to `draft` after a major rewrite, and a
`deprecated` entry can be revived. Every move is appended to
`governance/verification-ledger.jsonl`. A field test report is validated by
`scripts/validate_field_tests.py` against
`schemas/field-test.schema.json`, and must be reviewed (`verified: true`,
with reviewer and date recorded)
before it can support a `field-tested` transition. A reset to `draft` clears
review and test metadata so it cannot be mistaken for evidence about the
current version. See [Field testing](FIELD-TESTS.md) for safety and privacy
requirements.

## Style rules

### Formatting

- Hard wrap at 80 columns. No line may be longer, including tables.
- One blank line before and after every heading and every list.
- Two spaces to continue a bullet, three spaces to continue a numbered
  item.
- No tabs, and no trailing whitespace on any line.
- Use the em dash character "—" for an empty value, and plain ASCII
  apostrophes everywhere else.
- No emoji, in the entry, in the title, or in the sidecar.

### Links and sources

- No URLs in the body text. The address belongs in the sidecar source
  record, where the app renders it as a clickable row.
- No Markdown links in the body. Name the other entry in words, and let
  the sidecar carry the identifier.
- A standard or a regulation is named in the text by its number and
  title, and is listed in Sources like any other source.

### Voice

- Short sentences. Concrete nouns. The present tense for a procedure, the
  past tense for a reported field test.
- No marketing tone, no enthusiasm, no filler.
- Cut these openers: "it is important to note", "it should be noted
  that", "as any expert knows", "simply", "just", "very easy",
  "obviously".
- Write the number, not the adjective: "3 mm", not "a few millimetres".
- Do not call the reader "the user". Write "the reader".

### Uncertainty

- Say what you do not know, in the entry, in plain words.
- Give the range, the count and the conditions: "3 to 5 attempts, in dry
  weather below 20 °C", not "it usually works".
- Separate what is established from what is not: "The stoichiometry is
  exact; the yield depends on how well the glassware is dried."
- Never write a specific number you cannot source. If a number is your
  own estimate, say so: "estimated, not measured".
- If the entry cannot be supported, leave it at `draft`. An honest draft
  is worth more than a confident invention, and both the disclaimer and
  the contribution guide say so.

### Units

- SI is the primary system: metres, kilograms, seconds, kelvin, pascals,
  litres.
- Add the imperial in brackets when the reader is likely to hold an
  imperial tool: "a 5 mm (3/16 in) hole".
- Say which system a table is in, in the table's own heading or caption.
- Never convert silently. Show the conversion once, with the arithmetic,
  so the reader can check it.
- Give the tolerance where the tolerance matters: "20 mL ± 2 mL".
- Keep significant figures consistent through a worked example, and carry
  them through every step of a calculation.

### Readers with few tools

- Assume the reader has a workshop, not a laboratory.
- Name a substitute for every scarce instrument, and say what the
  substitute costs in accuracy.
- Give absolute quantities in grams and millilitres as well as ratios.
- Say what can be improvised with local materials, and what cannot be
  improvised at all.
- If the procedure genuinely needs a scarce tool, say so in
  Prerequisites and set the difficulty honestly.

## Legal and safety rules

- Never give medical, legal, financial, engineering, architectural or
  surveying advice. Describe the procedure and the hazard, and point to
  the qualified person who decides.
- Never be a single source of truth. An entry is a summary. A primary
  source and a qualified professional win.
- Never invent citations, URLs, measurements or standards. If you do not
  know, say so in the entry and keep it at `draft`.
- Never describe work the reader is not equipped to do. A `red` entry
  states the training, supervision, equipment and authorisation the work
  needs.
- Cite the standard or the regulation where one applies, by number and
  title, and record it as a source.
- Copy only from sources whose licence allows it, and record the licence
  of each source.
- Publish no secrets, no personal data, and no name of a person who has
  not consented to be named.
- Publish no instructions for work that is illegal in most places.
- Honour the disclaimer. `docs/DISCLAIMER.md` is the single source of the
  warnings that apply to the book, and it applies to your entry.

## Checks your change must pass

```bash
python scripts/validate.py             # sidecars against the schema
python scripts/validate_field_tests.py # field test reports
python scripts/build_index.py          # the search index builds
python scripts/validate_i18n.py        # translation coverage
python -m pytest -q                    # the test suite
python -m ruff check .                 # lint
npx markdownlint-cli2 "domains/**/*.md"
```

`make validate` runs the first two. The Markdown lint and the link check
run in CI on every push. A change that leaves any of these red is not
finished.
