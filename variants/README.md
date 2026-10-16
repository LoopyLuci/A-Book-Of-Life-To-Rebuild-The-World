# Regional Variants

Some entries must be adapted to climate, culture, and available materials.
Variants live alongside the canonical entry and override specific sections.

## Structure

```
variants/
├── arid/
│   └── survival/
│       └── water-purification.md
├── tropical/
│   └── agriculture/
│       └── food-preservation.md
├── arctic/
│   └── survival/
│       └── emergency-shelter.md
└── temperate/
    └── construction/
        └── simple-housing.md
```

## Override semantics

A variant file contains only the sections that differ. The build system
merges the variant into the canonical entry, replacing matching `##`
sections.

## Variant sidecars

Every variant carries a sidecar that specifies:

```yaml
variant_of: pnk:...
region: arid
overrides: [Procedure, Safety Notes]
```

## Building

`python scripts/build_variants.py` merges variants into `build/variants/`.
