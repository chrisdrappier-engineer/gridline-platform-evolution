# Decision Note: Request Evidence File Boundaries

## Date

2026-07-15

## Related Work

- [Issue 19: Add file uploads for request evidence](https://github.com/chrisdrappier-engineer/gridline-platform-evolution/issues/19)
- [Roadmap](../roadmap/README.md)

## Summary

Issue 19 adds evidence files to the service request note stream.

The implementation intentionally keeps the first file-upload slice narrow:
evidence belongs to notes, note visibility controls file visibility, and local
Active Storage is used as the baseline storage mechanism.

## Decisions

Evidence files attach to `ServiceRequestNote`, not directly to
`ServiceRequest`.

This keeps file context close to the operational note that explains why the
file exists. A request can still have many files through its notes.

Allowed file types are:

- JPEG, PNG, and WebP images
- PDF
- plain text
- CSV

Deferred file types include:

- video
- audio
- Office documents
- ZIP/archive files
- executables or scripts
- HEIC/HEIF

Images render as thumbnails in the note stream. PDF, text, and CSV files render
as compact open/download links. Inline PDF/text/CSV previews are deferred.

Active Storage variants generate image thumbnails on demand. The application
does not store custom thumbnail records.

## Validation Boundary

File validation happens in both places:

- frontend validation catches file count, file size, total upload size, and
  obvious type mismatches before upload when possible
- backend validation remains authoritative

The selected limits are:

- images: 5 MB each
- PDFs: 10 MB each
- text/CSV: 1 MB each
- files per note: 5
- total upload size per note: 15 MB

Validation messages should give users a recovery path. For example, oversized
images can be compressed, oversized PDFs can be split or compressed, and
oversized text/CSV files can be split.

The application does not automatically compress, split, or modify uploads in
this issue. That work is deferred because it raises questions about file
integrity, original retention, background processing, and user approval of the
modified result.

## Demo Data

Committed demo source files live under `monolith/db/demo_files`.

The repository stores only tiny deterministic source files. Active Storage
runtime blobs are generated during seeding and remain outside git.

This keeps demo rebuilds reliable without bloating the repository.

## Scaling Narrative

Local Active Storage is appropriate for the single-instance simulated PaaS
baseline.

It is also intentionally a future pressure point. Once the application moves
toward multiple app containers, local file storage becomes a natural reason to
introduce object storage, background processing for file work, and more careful
delivery/caching behavior.

## AI Involvement

Codex proposed local Active Storage, note-inherited visibility, on-demand image
variants, and deferring video, previews, and automated compression. The user
pressed on repository bloat, demo rebuild reliability, frontend/backend
validation, user-facing recovery instructions, and whether image thumbnails
should render inline. Those prompts shaped the final implementation boundary.
