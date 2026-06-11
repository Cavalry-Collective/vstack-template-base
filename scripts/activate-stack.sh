#!/usr/bin/env bash
# Builds the path-scoped stack rule files (.claude/rules/stack-*.md) from a pack's
# appendices — the single activation mechanism described in stacks/README.md.
# Each rule is the appendix body with `paths:` frontmatter prepended (rule files
# don't resolve @-imports, so each must be self-contained).
#
# Usage:
#   scripts/activate-stack.sh [<pack-name>]            (re)generate the rule files
#   scripts/activate-stack.sh [<pack-name>] --check    exit non-zero if any rule file is stale
#
# <pack-name> may be omitted when exactly one pack remains under stacks/ (the normal
# state after instantiation). The appendices stay the source of truth — rerun this
# script after editing one; CI runs --check as the drift gate (a no-op until a pack
# is activated).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

rules_dir=.claude/rules
check=false
pack=""
for arg in "$@"; do
  case "$arg" in
    --check) check=true ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *) pack="$arg" ;;
  esac
done

if [ -z "$pack" ]; then
  packs=""
  for dir in stacks/*/; do
    [ -d "$dir" ] && packs="$packs $(basename "$dir")"
  done
  pack_count=$(echo "$packs" | wc -w | tr -d ' ')
  if [ "$pack_count" -eq 1 ]; then
    pack=$(echo "$packs" | tr -d ' ')
  elif $check && ! ls "$rules_dir"/stack-*.md >/dev/null 2>&1; then
    echo "No stack rules under $rules_dir to check (no pack activated) — nothing to do."
    exit 0
  else
    echo "usage: $0 <pack-name> [--check] — found $pack_count packs under stacks/, name one." >&2
    exit 1
  fi
fi

pack_dir="stacks/$pack"
[ -d "$pack_dir" ] || { echo "no such pack: $pack_dir" >&2; exit 1; }

# appendix → paths: scope (db also loads for the backend repo ring; infra.md is the
# optional fifth appendix per stacks/README.md)
paths_for() {
  case "$1" in
    backend)  echo '["apps/backend/**"]' ;;
    frontend) echo '["apps/frontend/**"]' ;;
    db)       echo '["db/**", "apps/backend/**/repo/**"]' ;;
    infra)    echo '["infra/**"]' ;;
  esac
}

status=0
for name in backend frontend db infra; do
  src="$pack_dir/$name.md"
  [ -f "$src" ] || continue
  rule="$rules_dir/stack-$name.md"
  expected=$(printf -- '---\npaths: %s\n---\n' "$(paths_for "$name")"; cat "$src")
  if $check; then
    if [ ! -f "$rule" ]; then
      echo "STALE: $rule missing (source: $src) — run scripts/activate-stack.sh $pack" >&2
      status=1
    elif ! printf '%s\n' "$expected" | cmp -s - "$rule"; then
      echo "STALE: $rule does not match $src — run scripts/activate-stack.sh $pack" >&2
      status=1
    fi
  else
    mkdir -p "$rules_dir"
    printf '%s\n' "$expected" > "$rule"
    echo "wrote $rule (from $src)"
  fi
done
exit $status
