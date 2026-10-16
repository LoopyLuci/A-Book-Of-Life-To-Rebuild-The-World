# Media Library

Offline-storable video and audio for procedures that are easier to show
than to describe.

## Structure

```
media/
├── video/
│   └── <domain>/
│       └── <entry-slug>/
│           ├── tutorial.mp4
│           ├── tutorial.vtt       # WebVTT transcript
│           └── metadata.yaml
└── audio/
    └── <domain>/
        └── <entry-slug>/
            ├── guide.mp3
            ├── guide.txt          # plain text transcript
            └── metadata.yaml
```

## Metadata schema

See `schemas/media.schema.json`.

## Encoding standards

- Video: H.264, 720p, 30 fps, AAC audio, ≤100 MB per file.
- Audio: MP3, 96 kbps mono, ≤20 MB per file.
- Transcripts: WebVTT for video, plain text for audio.

## Generation

```bash
python scripts/build_media.py
```

This transcribes, indexes, and links media into the offline bundle.
