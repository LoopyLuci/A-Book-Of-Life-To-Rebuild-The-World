# Internationalization (i18n)

A Book Of Life To Rebuild The World supports 8 languages at launch, with a
translation framework that scales to more.

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
    │       └── making-fire.md
    └── ...
```

## Translation workflow

1. A translator copies `domains/<domain>/<slug>.md` to
   `i18n/translations/<lang>/<domain>/<slug>.md`.
2. They translate the body.
3. They create a sidecar at
   `i18n/translations/<lang>/<domain>/<slug>.pnk.yaml` with:
   ```yaml
   translation_of: pnk:...      # original id
   language: es
   ```
4. They run `python scripts/validate_i18n.py` to check coverage.

## Building

`python scripts/build_i18n.py` produces per-language index files and
integrates translations into the offline bundle.
