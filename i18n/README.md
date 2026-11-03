# Internationalization (i18n)

A Book Of Life To Rebuild The World ships its interface in 17 languages, with
16 translated corpora and a translation framework that scales to more. Every
language has a coverage target, and the pipeline fails the build when a
language drops below it.

> Translations are reference material like everything else in this project.
> A translated entry is still an entry: check the primary sources, and do not
> rely on a translation as a sole source of information. See
> [docs/DISCLAIMER.md](../docs/DISCLAIMER.md).

## Supported Languages

`en` is the canonical corpus; every other language is a translation that falls
back to it key by key. The coverage figure is what the language covers of the
207 entries today, and the target is the floor the pipeline enforces.

| Code | Language | Coverage | Target |
|------|----------|----------|--------|
| `en` | English | 100% | 100% |
| `es` | Spanish | 100% | 100% |
| `fr` | French | 100% | 100% |
| `de` | German | 100% | 100% |
| `pt` | Portuguese | 100% | 100% |
| `hi` | Hindi | 80.2% | 80% |
| `ar` | Arabic | 80.2% | 80% |
| `zh` | Chinese (Simplified) | 80.2% | 80% |
| `sw` | Swahili | 60.4% | 60% |
| `ja` | Japanese | 40.1% | 40% |
| `ru` | Russian | 40.1% | 40% |
| `id` | Indonesian | 30.4% | 30% |
| `it` | Italian | 30.4% | 30% |
| `nl` | Dutch | 30.4% | 30% |
| `tr` | Turkish | 30.4% | 30% |
| `vi` | Vietnamese | 30.4% | 30% |
| `ko` | Korean | 25.1% | 25% |

### Sources, not only translations

A reader whose first language is Swahili or Korean can follow an untranslated
entry, because every entry cites sources in several languages and records the
language of each one:

```yaml
sources:
- title: Water Purification
  author: Wikipedia contributors
  url: https://fr.wikipedia.org/wiki/Purification_de_l%27eau
  license: CC-BY-SA-4.0
  language: fr
```

The URLs are resolved through the MediaWiki language-links API when they are
added, so each one is a real article in that language rather than a guess. See
[`../docs/ENTRIES.md`](../docs/ENTRIES.md) for the rule.


## Structure

```
i18n/
├── strings/
│   ├── en.yaml       # canonical UI strings
│   ├── es.yaml
│   ├── fr.yaml
│   └── ...
└── translations/
    ├── es/
    │   └── survival/
    │       ├── making-fire.md
    │       └── making-fire.pnk.yaml
    └── ...
```

`strings/<lang>.yaml` holds the interface vocabulary: the words the apps show
on screen. `translations/<lang>/<domain>/<slug>.md` holds the translated
entry body, with a matching `.pnk.yaml` sidecar next to it that carries the
translated title, the tags, the language code and a `translation_of` pointer
to the original entry id.

## Translation workflow

1. A translator copies `domains/<domain>/<slug>.md` to
   `i18n/translations/<lang>/<domain>/<slug>.md`.
2. They translate the body.
3. They create a sidecar at
   `i18n/translations/<lang>/<domain>/<slug>.pnk.yaml` with:
   ```yaml
   id: pnk:.../domain/slug
   translation_of: pnk:.../domain/slug
   language: es
   ```
4. They run `python scripts/validate_i18n.py` to check coverage.
5. They run `python scripts/build_i18n.py` to build the per-language indexes.

## Rules for a translation

- **Keep the structure.** The same headings, in the same order, at the same
  levels, with the same numbering. A reader comparing the two versions must be
  able to find the same step in the same place.
- **Never translate a value.** Numbers, units, standard numbers, tolerances,
  dosages, temperatures, part numbers, chemical formulae and safety levels
  stay exactly as they are. Translate the words around them.
- **Keep every step and every hazard.** A shorter translation is fine when the
  language is more compact. A translation that omits a step, a hazard or a
  caveat is not a translation.
- **Keep the placeholders.** The em dashes in the Verification block and any
  `{placeholder}` in the UI strings must survive.
- **Tags are ASCII.** The tag pattern only allows lowercase letters, digits
  and hyphens. For a language that does not write in the Latin alphabet, use a
  romanised form rather than the native script.
- **Safety levels never change.** A red entry stays red in every language.

## Building

`python scripts/build_i18n.py` produces per-language index files and
integrates translations into the offline bundle.

## Adding a language

1. Add the code to `LANGS` and `COVERAGE_TARGETS` in `scripts/validate_i18n.py`.
2. Copy `i18n/strings/en.yaml` to `i18n/strings/<lang>.yaml` and translate it.
3. Add the language to `supported_languages` in `manifest.toml` and to the
   locale list in `android/app/src/main/res/xml/locales_config.xml`.
4. Translate as many entries as the coverage target requires and run
   `python scripts/validate_i18n.py`.

The Android app generates its localized interface strings from
`i18n/strings/*.yaml` with `android/tools/export_content.py`. If you change
those files, re-run the exporter and commit the result, or the Android CI job
fails on a dirty tree.
