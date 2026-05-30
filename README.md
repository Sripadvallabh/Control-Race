# Control Race

Rulebook and related artifacts for the game of Control Race.

## Latest PDFs

- `control-race-rulebook.pdf` - current polished rulebook.
- `control-race-rulebook-plain.pdf` - current plain rulebook.

Older versioned rulebooks are available in `dist/rulebooks/`.

## Source

- Rulebook RST files: `docs/rulebook/`
- Changelog: `CHANGELOG.rst` tracks rulebook changes only.
- Version: `VERSION` tracks rulebook content, not tooling or PDF theme changes.
- PDF themes: `docs/rulebook/theme.yaml` and `docs/rulebook/theme-plain.yaml`
- Versioned PDF archive: `dist/rulebooks/`

## Build

```sh
tools/rulebook.sh build
```

Builds both current root PDFs and matching versioned PDFs under
`dist/rulebooks/`.

## Release

```sh
tools/rulebook.sh release patch
```

Use `minor`, `major`, or an exact version such as `0.2.0` instead of `patch`
when the rulebook content changes. Update `CHANGELOG.rst` before releasing a
rulebook change.
