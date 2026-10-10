#!/usr/bin/env bash
# Link the skills under the given tags into ~/.claude/skills.
# Usage: claude/install.sh <tag>...   e.g. claude/install.sh valkai personal
set -euo pipefail

SKILLS_SRC="$(cd "$(dirname "$0")/skills" && pwd)"
SKILLS_DEST="$HOME/.claude/skills"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <tag>...  (tags: $(ls "$SKILLS_SRC" | tr '\n' ' '))" >&2
  exit 1
fi

mkdir -p "$SKILLS_DEST"

for tag in "$@"; do
  [[ -d "$SKILLS_SRC/$tag" ]] || { echo "Unknown tag: $tag" >&2; exit 1; }
  for skill in "$SKILLS_SRC/$tag"/*/; do
    [[ -d "$skill" ]] || continue
    name="$(basename "$skill")"
    dest="$SKILLS_DEST/$name"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      echo "Skip $name: $dest exists and is not a link" >&2
      continue
    fi
    ln -sfn "${skill%/}" "$dest"
    echo "Linked $name ($tag)"
  done
done
