# Control Race

Rulebook and related artifacts for the game of Control Race.

## Rulebook

The rulebook source lives in `docs/rulebook/` as reStructuredText files.

Changes are tracked in `CHANGELOG.rst` and included near the front of the
generated PDF.

The PDF theme lives in `docs/rulebook/theme.yaml`; generated page art is created
by the build script and left out of Git.

The committed PDF output lives in `dist/rulebooks/`:

- `control-race-rulebook.pdf` is the current generated rulebook.
- `control-race-rulebook-v0.1.2.pdf` is the latest themed release.
- `control-race-rulebook-v0.1.1.pdf` adds the first themed release.
- `control-race-rulebook-v0.1.0.pdf` is the initial draft release.

## Build

Generate the PDF locally:

```sh
tools/rulebook.sh build
```

The script creates a local `.venv-rulebook/`, installs the pinned renderer from
`requirements-rulebook.txt`, and writes the PDF to `dist/rulebooks/`.

## Release

Create a versioned rulebook release and commit the source plus PDF:

```sh
tools/rulebook.sh release patch
```

You can also set an exact version:

```sh
tools/rulebook.sh release 0.2.0
```

The release command updates `VERSION`, regenerates `docs/rulebook/_version.rst`,
builds the PDF, stages the rulebook files and generated PDFs, then creates a
Git commit. Update `CHANGELOG.rst` before running a release so readers can
review only what changed.
