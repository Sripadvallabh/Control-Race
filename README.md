# Control Race

Rulebook and related artifacts for the game of Control Race.

## Latest PDFs

- `control-race-rulebook.pdf` - current polished rulebook.
- `control-race-rulebook-plain.pdf` - current plain rulebook.

## Source

- Rulebook RST files: `docs/rulebook/`
- Changelog: `CHANGELOG.rst`
- Version: `VERSION`
- PDF themes: `docs/rulebook/theme.yaml` and `docs/rulebook/theme-plain.yaml`
- Versioned PDF archive: `dist/rulebooks/`

## Build

```sh
tools/rulebook.sh build
```

Builds both current root PDFs and versioned PDFs under `dist/rulebooks/`.

## Release

```sh
tools/rulebook.sh release patch
```

Use `minor`, `major`, or an exact version such as `0.2.0` instead of `patch`
when needed. Update `CHANGELOG.rst` before releasing.
