#!/usr/bin/env bash
# Builds always-on add-on rule files (.claude/rules/addon-*.md) from the add-on
# docs under add-ons/ — the opt-in optional-capability modules described in
# add-ons/README.md. Each rule is the add-on's README body copied verbatim with
# NO `paths:` frontmatter, so it loads unconditionally: add-ons are cross-cutting
# (backend + frontend + db), not path-scoped like stack packs.
#
# Usage:
#   scripts/activate-addons.sh            (re)generate a rule for every add-on kept under add-ons/
#   scripts/activate-addons.sh --check    exit non-zero if any activated add-on rule is stale/orphaned
#
# The opt-in model mirrors stacks: keep the add-on directories you want, delete
# the rest, then run this. The READMEs stay the source of truth — rerun after
# editing one; CI runs --check as the drift gate (a no-op until an add-on is
# activated, i.e. until an addon-*.md rule exists).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

rules_dir=.claude/rules
addons_dir=add-ons
check=false
for arg in "$@"; do
  case "$arg" in
    --check) check=true ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *) echo "unexpected argument: $arg — this script activates every add-on kept under $addons_dir/" >&2; exit 1 ;;
  esac
done

status=0

if $check; then
  # Only verify rules that exist (i.e. add-ons that were activated). No rules
  # yet — a fresh template, or no add-on adopted — is a clean no-op.
  if ! ls "$rules_dir"/addon-*.md >/dev/null 2>&1; then
    echo "No add-on rules under $rules_dir to check (no add-on activated) — nothing to do."
    exit 0
  fi
  for rule in "$rules_dir"/addon-*.md; do
    name=$(basename "$rule" .md); name=${name#addon-}
    src="$addons_dir/$name/README.md"
    if [ ! -f "$src" ]; then
      echo "STALE: $rule has no source ($src) — the add-on was deleted; remove the rule too, or restore the add-on" >&2
      status=1
    elif ! printf '%s\n' "$(cat "$src")" | cmp -s - "$rule"; then
      echo "STALE: $rule does not match $src — run scripts/activate-addons.sh" >&2
      status=1
    fi
  done
  exit $status
fi

# Generate mode: write a rule for every add-on directory kept under add-ons/.
found_any=false
for dir in "$addons_dir"/*/; do
  [ -d "$dir" ] || continue
  src="${dir}README.md"
  [ -f "$src" ] || continue
  found_any=true
  name=$(basename "$dir")
  rule="$rules_dir/addon-$name.md"
  mkdir -p "$rules_dir"
  printf '%s\n' "$(cat "$src")" > "$rule"
  echo "wrote $rule (from $src)"
done
$found_any || echo "No add-ons under $addons_dir/ — nothing to activate."
