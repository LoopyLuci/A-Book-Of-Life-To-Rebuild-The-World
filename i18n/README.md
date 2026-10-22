# Internationalization (i18n)

A Book Of Life To Rebuild The World supports 12 languages at launch, with a
translation framework that scales to more.

> Translations are reference material like everything else in this project.
> A translated entry is still an entry: check the primary sources, and do not
> rely on a translation as a sole source of information. See
> [docs/DISCLAIMER.md](../docs/DISCLAIMER.md).

## Supported Languages

| Code | Language | Coverage target |
|------|----------|-----------------|
| `en` | English | 100% |
| `es` | Spanish | 100% |
| `fr` | French | 100% |
| `de` | German | 100% |
| `pt` | Portuguese | 100% |
| `hi` | Hindi | 80% |
| `ar` | Arabic | 80% |
| `sw` | Swahili | 60% |
| `zh` | Chinese (Simplified) | 80% |
| `it` | Italian | 30% |
| `ru` | Russian | 40% |
| `nl` | Dutch | 30% |
| `ja` | Japanese | 40% |
| `ko` | Korean | 25% |
| `vi` | Vietnamese | 30% |
| `tr` | Turkish | 30% |

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
