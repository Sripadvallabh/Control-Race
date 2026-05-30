#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv-rulebook"
REQUIREMENTS_FILE="${ROOT_DIR}/requirements-rulebook.txt"
VERSION_FILE="${ROOT_DIR}/VERSION"
SOURCE_DIR="${ROOT_DIR}/docs/rulebook"
ENTRY_FILE="${SOURCE_DIR}/index.rst"
VERSION_RST="${SOURCE_DIR}/_version.rst"
THEME_STYLE="${SOURCE_DIR}/theme.yaml"
PDF_DIR="${ROOT_DIR}/dist/rulebooks"
CURRENT_PDF="${PDF_DIR}/control-race-rulebook.pdf"
BUILD_DIR="${ROOT_DIR}/build/rulebook"
BACKGROUND_PNG="${BUILD_DIR}/page-background.png"
GENERATED_STYLE="${BUILD_DIR}/rulebook-style.yaml"

usage() {
  printf '%s\n' \
    "Usage: tools/rulebook.sh <command> [argument]" \
    "" \
    "Commands:" \
    "  build                 Generate the versioned PDF." \
    "  bump <patch|minor|major|x.y.z>" \
    "                        Update VERSION and rulebook substitution." \
    "  release [patch|minor|major|x.y.z]" \
    "                        Optionally bump, build, git add, and commit." \
    "  clean                 Remove build outputs and the local tool venv." \
    "" \
    "Examples:" \
    "  tools/rulebook.sh build" \
    "  tools/rulebook.sh release patch" \
    "  tools/rulebook.sh release 0.2.0"
}

rulebook_version() {
  tr -d '[:space:]' < "${VERSION_FILE}"
}

validate_version() {
  local value="$1"
  if [[ ! "${value}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'Invalid version: %s\nExpected semantic version format: x.y.z\n' "${value}" >&2
    exit 1
  fi
}

sync_version_rst() {
  local version="$1"
  mkdir -p "${SOURCE_DIR}"

  local tmp_file
  tmp_file="$(mktemp)"
  {
    printf '%s\n' '.. This file is maintained by tools/rulebook.sh.'
    printf '.. |rulebook_version| replace:: %s\n' "${version}"
  } > "${tmp_file}"

  if [[ ! -f "${VERSION_RST}" ]] || ! cmp -s "${tmp_file}" "${VERSION_RST}"; then
    cp "${tmp_file}" "${VERSION_RST}"
  fi

  rm -f "${tmp_file}"
}

bump_version() {
  local bump="$1"
  local current
  current="$(rulebook_version)"
  validate_version "${current}"

  local next
  if [[ "${bump}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    next="${bump}"
  else
    local major minor patch
    IFS='.' read -r major minor patch <<< "${current}"

    case "${bump}" in
      major)
        next="$((major + 1)).0.0"
        ;;
      minor)
        next="${major}.$((minor + 1)).0"
        ;;
      patch)
        next="${major}.${minor}.$((patch + 1))"
        ;;
      *)
        printf 'Unknown bump: %s\n' "${bump}" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  validate_version "${next}"
  printf '%s\n' "${next}" > "${VERSION_FILE}"
  sync_version_rst "${next}"
  printf 'Rulebook version set to %s\n' "${next}"
}

ensure_tools() {
  if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    python3 -m venv "${VENV_DIR}"
  fi

  "${VENV_DIR}/bin/python" -m pip install --upgrade pip
  "${VENV_DIR}/bin/python" -m pip install -r "${REQUIREMENTS_FILE}"
}

ensure_page_assets() {
  mkdir -p "${BUILD_DIR}"

  BACKGROUND_PNG="${BACKGROUND_PNG}" "${VENV_DIR}/bin/python" - <<'PY'
import os
from PIL import Image, ImageDraw

path = os.environ["BACKGROUND_PNG"]

width, height = 1240, 1754
image = Image.new("RGB", (width, height), "#fbfaf6")
draw = ImageDraw.Draw(image)

felt = "#123d2b"
gold = "#c8a64b"
ink = "#1d2320"
red = "#b63232"
yellow = "#e3bd35"
green = "#2f8f46"
brown = "#855525"
blue = "#2d5fa8"
pink = "#cf6b96"
black = "#171717"

draw.rectangle((0, 0, width, 116), fill=felt)
draw.rectangle((0, 116, width, 132), fill=gold)
draw.rectangle((0, height - 74, width, height), fill="#f1eee6")
draw.line((0, height - 74, width, height - 74), fill="#d6caa9", width=2)

ball_y = 58
ball_radius = 18
ball_colors = [yellow, green, brown, blue, pink, black, red]
start_x = width - 360
for index, color in enumerate(ball_colors):
  x = start_x + index * 46
  draw.ellipse(
      (x, ball_y - ball_radius, x + ball_radius * 2, ball_y + ball_radius),
      fill=color,
      outline="#f7f4ea" if color == black else ink,
      width=2,
  )

draw.rectangle((0, 132, 12, height - 74), fill="#d8c26b")
draw.rectangle((12, 132, 18, height - 74), fill="#123d2b")

image.save(path)
PY

  local version
  version="$(rulebook_version)"

  {
    printf '%s\n' 'pageTemplates:'
    printf '%s\n' '  mainPage:'
    printf '    background: "%s"\n' "${BACKGROUND_PNG}"
    printf '%s\n' '    background_fit_mode: scale'
    printf '    defaultFooter: "Control Race Rulebook v%s | Page ###Page###"\n' "${version}"
    printf '%s\n' '    showFooter: true'
    printf '%s\n' '    showHeader: false'
    printf '%s\n' '  decoratedPage:'
    printf '    background: "%s"\n' "${BACKGROUND_PNG}"
    printf '%s\n' '    background_fit_mode: scale'
    printf '    defaultFooter: "Control Race Rulebook v%s | Page ###Page###"\n' "${version}"
    printf '%s\n' '    showFooter: true'
    printf '%s\n' '    showHeader: false'
  } > "${GENERATED_STYLE}"
}

versioned_pdf_path() {
  printf '%s/control-race-rulebook-v%s.pdf\n' "${PDF_DIR}" "$(rulebook_version)"
}

build_pdf() {
  local version
  version="$(rulebook_version)"
  validate_version "${version}"
  sync_version_rst "${version}"
  ensure_tools
  ensure_page_assets

  mkdir -p "${PDF_DIR}"

  local output_pdf
  output_pdf="$(versioned_pdf_path)"

  "${VENV_DIR}/bin/rst2pdf" \
    --date-invariant \
    --stylesheets="${THEME_STYLE},${GENERATED_STYLE}" \
    "${ENTRY_FILE}" \
    -o "${output_pdf}"
  cp "${output_pdf}" "${CURRENT_PDF}"

  printf 'Generated %s\n' "${output_pdf}"
  printf 'Updated %s\n' "${CURRENT_PDF}"
}

release_rulebook() {
  if [[ $# -gt 0 ]]; then
    bump_version "$1"
  else
    sync_version_rst "$(rulebook_version)"
  fi

  build_pdf

  git -C "${ROOT_DIR}" add \
    ".gitignore" \
    "CHANGELOG.rst" \
    "README.md" \
    "VERSION" \
    "requirements-rulebook.txt" \
    "docs/rulebook" \
    "tools/rulebook.sh" \
    "dist/rulebooks"

  if git -C "${ROOT_DIR}" diff --cached --quiet; then
    printf 'Nothing to commit.\n'
    return
  fi

  git -C "${ROOT_DIR}" commit -m "Release Control Race rulebook v$(rulebook_version)"
}

clean_outputs() {
  rm -rf "${ROOT_DIR}/build" "${VENV_DIR}"
  printf 'Removed build outputs and local rulebook virtualenv.\n'
}

main() {
  local command="${1:-}"
  if [[ $# -gt 0 ]]; then
    shift
  fi

  case "${command}" in
    build)
      build_pdf
      ;;
    bump)
      if [[ $# -ne 1 ]]; then
        usage >&2
        exit 1
      fi
      bump_version "$1"
      ;;
    release)
      if [[ $# -gt 1 ]]; then
        usage >&2
        exit 1
      fi
      release_rulebook "$@"
      ;;
    clean)
      clean_outputs
      ;;
    -h|--help|help|'')
      usage
      ;;
    *)
      printf 'Unknown command: %s\n' "${command}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
