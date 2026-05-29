# LibPolyCall v2 Repository Structure

This repository is organized so production source, daemon code, bindings,
documentation, generated outputs, and container packaging remain easy to audit
independently.

## Top-Level Boundaries

```
libpolycall-v2/
|-- src/                 Core C implementation for libpolycall
|-- include/             Public C headers
|-- daemon/              POSIX polycalld daemon plus Windows compatibility shim
|-- bindings/            Language binding source packages
|-- examples/            Runnable examples and sample integrations
|-- projects/            Larger reference applications
|-- config/              Runtime, CMake, package, service, and proxy config
|-- schema/              Polycallfile and protocol schemas
|-- scripts/             Release, extraction, and maintenance helpers
|-- test/                Core C tests
|-- docs/                Human-facing documentation and documentation assets
|-- reports/             Build and migration reports
|-- snapshots/           Historical terminal/session captures
|-- Dockerfile           Container build definitions
|-- docker-compose*.yml  Local runtime and example orchestration
|-- Makefile             Native C build entry point
|-- CMakeLists.txt       CMake build entry point
`-- build-windows.ps1    Windows host build helper
```

## Source Code

Core production code lives in `src/` and `include/`. The daemon is intentionally
kept in `daemon/` because it has its own process model and platform constraints.
Language adapters live under `bindings/`, and larger composed applications live
under `projects/`.

Generated build output must stay out of source folders. Use `build/`,
`_docker_build/`, language-specific `target/`, or tool-managed cache folders.
These paths are ignored by `.gitignore` and `.dockerignore`.

## Documentation And Media

Markdown, manuals, PDFs, diagrams, transcripts, and image assets belong under
`docs/`:

```
docs/
|-- assets/          Curated static assets used by docs
|-- images/          Screenshots and image-only documentation material
|-- diagrams/        PlantUML, SVG, and architecture diagrams
|-- man/             Manual pages
|-- pdf/             Rendered document exports
|-- references/      External or long-form reference PDFs
|-- specifications/  Protocol, architecture, and implementation specs
`-- transcripts/     Session transcripts and historical notes
```

Repository-root documentation should stay limited to onboarding files such as
`README.md`, `QUICKSTART.md`, `USAGE_GUIDE.md`, and release/publishing notes.

## Container Packaging

The Docker image keeps three responsibilities separate:

- `builder`: compiler and CMake toolchain used only to produce artifacts.
- `runtime`: production library, headers, binary, and runtime configuration.
- `development`: optional language runtimes, build tools, bindings, and examples.

Documentation, screenshots, PDFs, reports, snapshots, and generated outputs are
excluded from the Docker context so they do not inflate image layers or appear
in runtime vulnerability scans.

## Cleanup Rules

- Do not commit compiled Java `target/` output, C object files, DLLs, EXEs, or
  package caches.
- Keep image assets inside `docs/assets/` or `docs/images/`.
- Keep generated reports in `reports/` and historical captures in `snapshots/`.
- Add new production C APIs under `include/` and their implementations under
  `src/`.
- Add new daemon-only behavior under `daemon/`; do not mix it into the core
  library unless it is reusable runtime functionality.
