#!/usr/bin/env bash
# PreToolUse hook: blocks Edit/Write to already-committed files under db/migrations/.
# Enforces db/CLAUDE.md "Never edit an applied migration" — once a migration is
# merged or applied anywhere it is immutable; fix forward with a new migration.
# Tracked-by-git is the proxy for "applied anywhere". Fails open (exit 0) whenever
# it can't decide, so it never blocks unrelated work.
set -u
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat) || exit 0
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -n "$file_path" ] || exit 0

case "$file_path" in
  *.md) exit 0 ;;                  # docs (e.g. db/migrations/README.md) stay editable
  */db/migrations/*) ;;
  *) exit 0 ;;
esac

repo_root=$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null) || exit 0
rel=${file_path#"$repo_root"/}
if git -C "$repo_root" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
  echo "BLOCKED: $rel is a committed migration, and migrations are immutable once merged/applied (db/CLAUDE.md). Create a new migration that fixes forward instead." >&2
  exit 2
fi
exit 0
