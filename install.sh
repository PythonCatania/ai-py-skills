#!/usr/bin/env bash
#
# Symlink every skill from this repo into agent config directories, in two
# layers:
#
#   1. the agent-neutral dir (default: ~/.agents/skills) gets one link per
#      skill directory, pointing into this repo;
#   2. the agent's own skills dir (default: ~/.claude/skills) gets links
#      pointing at the corresponding agent-neutral entries.
#
# Re-running converges: correct links are left alone, links owned by this
# repo that point elsewhere are re-pointed, and broken ones are pruned. To
# wire up another agent, run again with its --skills-dir.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
AGENTS_DIR="${HOME}/.agents"
SKILLS_DIR="${HOME}/.claude/skills"
FORCE=0

usage() {
  cat <<'EOF'
Symlink every skill in skills/ into <agents-dir>/skills, then link those
entries into the agent's own skills dir. Safe to re-run.

Usage:
  ./install.sh [options]

Options:
  --agents-dir DIR   Agent-neutral directory   (default: ~/.agents)
  --skills-dir DIR   Agent's skills directory  (default: ~/.claude/skills)
  --force            Overwrite real files/dirs and foreign symlinks
  -h, --help         Show this help
EOF
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agents-dir|--skills-dir)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "$1 needs a directory." >&2; exit 1; }
      if [ "$1" = --agents-dir ]; then AGENTS_DIR="$2"; else SKILLS_DIR="$2"; fi
      shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

mkdir -p "${AGENTS_DIR}/skills" "$SKILLS_DIR"
AGENTS_DIR="$(cd "$AGENTS_DIR" && pwd -P)"
SKILLS_DIR="$(cd "$SKILLS_DIR" && pwd -P)"

# Ours: a link into this repo, or an agent-dir link to an agent-neutral entry.
is_ours() {
  local target
  target="$(readlink "$1")" || return 1
  [[ "$target" == "${REPO_DIR}"/* || "$target" == "${AGENTS_DIR}/skills"/* ]]
}

prune_dir() {
  local entry
  for entry in "$1"/*; do
    { [ -L "$entry" ] && [ ! -e "$entry" ] && is_ours "$entry"; } || continue
    rm -- "$entry"
    echo "  prune  $(basename "$entry")"
  done
}

link_one() {
  local src="$1" name dest
  name="$(basename "$src")"
  dest="$2/${name}"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ok     ${name}"
    return
  fi
  if [ -L "$dest" ] && is_ours "$dest"; then
    rm -- "$dest"
    ln -s -- "$src" "$dest"
    echo "  relink ${name}"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$FORCE" -eq 0 ]; then
      echo "  skip   ${name} (already exists; use --force to overwrite)"
      return
    fi
    rm -rf -- "$dest"
  fi
  ln -s -- "$src" "$dest"
  echo "  link   ${name}"
}

# Phase 1: agent-neutral dir -> this repo. Pruning first breaks the agent-dir
# links of removed skills, so phase 2 prunes them in the same run.
echo "Agents dir -> ${AGENTS_DIR}/skills"
prune_dir "${AGENTS_DIR}/skills"
for skill in "${REPO_DIR}"/skills/*/; do
  [ -d "$skill" ] || continue
  link_one "${skill%/}" "${AGENTS_DIR}/skills"
done

# Phase 2: agent dir -> agent-neutral entries. Skipped when both are the same
# dir, where every link would point at itself.
echo "Skills -> ${SKILLS_DIR}"
if [ "$SKILLS_DIR" = "${AGENTS_DIR}/skills" ]; then
  echo "  ok     (this is the agents dir itself; already populated)"
else
  prune_dir "$SKILLS_DIR"
  for skill in "${REPO_DIR}"/skills/*/; do
    [ -d "$skill" ] || continue
    src="${AGENTS_DIR}/skills/$(basename "$skill")"
    # Link only entries phase 1 owns, never a foreign one sharing the name.
    if [ "$(readlink "$src" 2>/dev/null)" != "${skill%/}" ]; then
      echo "  skip   $(basename "$skill") (agents dir entry is not from this repo)"
      continue
    fi
    link_one "$src" "$SKILLS_DIR"
  done
fi

echo "Done."
