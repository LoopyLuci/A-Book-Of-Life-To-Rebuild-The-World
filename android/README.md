# A Book Of Life — Android App

An offline-first, native Android reader for the *A Book Of Life To Rebuild The World*
knowledge base. Written in Kotlin with Jetpack Compose and Material 3, it packages the
entire knowledge base into the APK so it works with **zero connectivity**.

## Features

- **Offline knowledge base** — all entries, sidecar metadata and Markdown bodies are
  bundled as assets and imported into a local Room database on first launch.
- **Hybrid search** — SQLite FTS4 candidate retrieval fused with an in-memory BM25 +
  TF-IDF (cosine) ranker via Reciprocal Rank Fusion, with matched terms highlighted in
  results. Filter by domain and difficulty.
- **Rich reader** — a Compose Markdown renderer (headings, lists, blockquotes, code,
  tables, links, emphasis) with adjustable text size, optional serif body text, reading
  time, safety/difficulty/verification badges and prerequisite links.
- **Bookmarks & progress** — save entries and resume reading where you left off.
- **Themes** — Material 3 light/dark, dynamic color on Android 12+, and a parchment
  "field manual" accent palette.
- **Localization** — 8 UI translations (ar, de, es, fr, hi, pt, sw, zh) generated from
  `i18n/strings/*.yaml`.

## Architecture

A clean, multi-module Gradle project:

```
android/
├── app/                    # Application, navigation, DI wiring
├── core/
│   ├── model/              # Domain models (pure Kotlin)
│   ├── common/             # Dispatchers, text utilities
│   ├── designsystem/       # Theme, components, shared UI strings
│   └── data/               # Room, DataStore, content importer, search engine
└── feature/
    ├── home/               # Library, domains, continue-reading
    ├── search/             # Search + filters
    ├── reader/             # Markdown reader, bookmarks, share
    ├── bookmarks/          # Saved entries
    └── settings/           # Appearance, reading, content controls
```

- **UI**: Jetpack Compose + Material 3, Navigation Compose, Hilt view models.
- **Data**: Room 2.6, DataStore Preferences, kotlinx.serialization.
- **Concurrency**: Kotlin coroutines + Flow.
- **Markdown**: `org.jetbrains:markdown` (GFM) parsed into Compose.
- **Toolchain**: Kotlin 2.0, AGP 8.7, `minSdk 26`, `targetSdk 35`, Java 17.

## Content pipeline

Content is generated from the repository's source of truth by
`tools/export_content.py`:

```
domains/**/*.md + sidecars/**/*.pnk.yaml + i18n/strings/*.yaml + manifest.toml
        │
        ▼  python android/tools/export_content.py
android/app/src/main/assets/content/{entries,domains,meta}.json
android/app/src/main/res/values-<lang>/strings.xml
```

The generated files are committed, and CI regenerates them and fails if the working
tree differs — so change the source entries, re-run the exporter, and commit the result.

## Build

Requirements: JDK 17 and the Android SDK (platform 35, build-tools 35.0.0). The Gradle
wrapper pins Gradle 8.9.

```bash
cd android

# Regenerate bundled content first (from the repo root)
python tools/export_content.py

# Build a debug APK
./gradlew assembleDebug

# Install on a connected device
./gradlew installDebug
```

The debug APK is written to `app/build/outputs/apk/debug/app-debug.apk`.

Create `local.properties` (gitignored) if the SDK is not auto-detected:

```properties
sdk.dir=/path/to/Android/Sdk
```

## Testing

```bash
cd android
./gradlew test
```

## Continuous integration

[`.github/workflows/android.yml`](../.github/workflows/android.yml) regenerates the
content assets, verifies they are committed, runs the unit tests, assembles the debug
APK and uploads it as a build artifact.

## License

Code: [MIT](../LICENSE-CODE). Content: [CC BY-SA 4.0](../LICENSE-CONTENT).
