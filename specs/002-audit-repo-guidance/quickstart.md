# Quickstart: Validating the Guidance Audit & Public Showcase

How to prove each success criterion, mapped SC-by-SC. Run scripted checks from the repo root; manual protocols reference the [contracts](./contracts/).

## Prerequisites

- `gitleaks` installed locally (`brew install gitleaks`) — used for the scan only, not added to the template.
- A scratch directory outside the repo for the dry-run instantiation (SC-006).

## Corpus definition (used by several checks)

```bash
CORPUS=$(find . -name "*.md" -not -path "./.git/*" -not -path "./.claude/*" \
  -not -path "./.specify/*" -not -path "./specs/*")
```

Baseline re-captured 2026-07-03: **36,978 words** ⇒ SC-003 target ≤ **27,733**.

## Checks

| SC | What proves it | How |
|---|---|---|
| SC-001 | Every in-scope file has a verdict | Diff `$CORPUS` (plus structural artifacts) against the report's file-by-file appendix; zero missing entries |
| SC-002 | Discovery question answered | The report's instruction-discovery map classifies every file's `loading`; the answer cites the loading model in [research.md R1](./research.md) |
| SC-003 | ≥25% smaller, zero rules lost | `wc -w $CORPUS` ≤ 27,597; rule inventory shows every `removed` rule linked to an approved finding |
| SC-004 | No unlabelled tier contradictions | Read each pack file beside its generic counterpart; every deviation carries the exception label per [stack-pack-structure.md](./contracts/stack-pack-structure.md) |
| SC-005 | No orphaned agent-binding file | For each `audience: agent/both` file, trace: auto-loaded, lazy subtree CLAUDE.md, or referenced with a "read when" pointer from one — one hop max |
| SC-006 | Instantiation still works | In the scratch clone, follow the front-door Day-1 checklist end to end; no broken references, missing files, or stale placeholders |
| SC-007 | Two-doc orientation | Pick any area; read only root `CLAUDE.md` + that area's `CLAUDE.md`; state the area's binding rules; nothing load-bearing missing |
| SC-008 | 10-minute front door | Fresh-reader protocol ([research.md R8](./research.md)): README only, 10 minutes, then answer *what is it / what philosophy / how to start*; all three correct |
| SC-009 | Release gate clean | `gitleaks git .` clean over full history; grep pass for internal URLs/hosts, personal emails, internal project names clean; `LICENSE` (MIT) exists at root |
| SC-010 | One consistent voice | Sample any three guidance files; hold each against [guidance-style.md](./contracts/guidance-style.md); zero prohibited content |
| SC-011 | Uniform stack packs | Per pack: five files `present` or `n/a-declared`; side-by-side shape matches; canonical structure documented in `stacks/README.md` |
| SC-012 | Cavalry attribution | README renders the Cavalry lockup (light/dark) and names Cavalry; design guide carries the mark + attribution; all brand assets resolve to files under `design/brand/` in this repo — no external or internal URLs |

## Useful commands

```bash
# SC-003: corpus size vs target
wc -w $CORPUS | tail -1

# SC-009: secrets across working tree and full history
gitleaks git . --verbose

# SC-009: internal references / personal data (extend patterns as found)
grep -rInE "(internal\.|corp\.|@(?!users\.noreply)[a-z-]+\.(sg|com))" \
  --include="*.md" . | grep -v ".git/"

# SC-005 / FR-008: relative links that don't resolve
grep -rhoE "\]\((\./|\.\./)?[A-Za-z0-9_./-]+\.md" --include="*.md" . \
  | sed 's/](//' | sort -u | while read -r f; do [ -f "$f" ] || echo "broken: $f"; done
```

## Order of operations

1. Run the P1 audit → `audit-report.md` per [findings-report.md](./contracts/findings-report.md); SC-001, SC-002 checkable immediately.
2. Maintainer rules on the **Decisions requested** section (historical specs, destructive changes — the license is already decided: MIT).
3. Execute P2–P5 slices, each closing its findings; re-run the affected checks after each slice.
4. Before declaring release-ready: the full table above passes, and every release-blocking finding is `verified` or `rejected`.
