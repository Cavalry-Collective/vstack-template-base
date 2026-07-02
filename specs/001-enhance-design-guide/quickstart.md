# Quickstart — Validating the Design Guide Enhancement

Ship-time verification runs against the guide itself (clarified: the guide is its own
specimen; SC-001/002/004 are later re-measured on the first derived project). No build
step or toolchain is required — a browser and grep suffice.

## Prerequisites

- Any modern browser.
- Repo checked out; work reviewed from the feature worktree before merge-back.

## 1 · Structure smoke test (contract: guide-chapters.md)

1. Open `design/design-guide.html` in a browser.
2. Sidebar shows four groups — Start / Foundations / **Composition** / Beyond — with
   Composition holding **Screen archetypes · Forms · View states & feedback**, and Beyond
   holding **Components & reuse**.
3. Click through every chapter: hash router works, pager prev/next follows the new order,
   `#elevation` and `#components` anchors still resolve.
4. Disable JavaScript (or block the script) and reload: the guide degrades to one long
   page with all chapters visible.

**Expected**: all four pass; any failure is a contract violation.

## 2 · Token & live-mirror audit (contract: tokens.md; FR-003/FR-019)

1. In the browser, confirm every `.resolved` annotation renders a non-empty value —
   including the two new `--page-*` tokens where the archetype chapter cites them.
2. Mechanical audit from repo root — expect **no matches** (the greppable violation rule
   the guide already declares):

   ```bash
   # hex literals or px sizes in guide markup outside tokens.css
   # (excludes anchor hrefs and the standard off-screen skip-link idiom)
   grep -nE '#[0-9a-fA-F]{3,8}\b|[0-9]+px' design/design-guide.html \
     | grep -v 'var(--' | grep -vE 'href="#|-999px'
   ```

   Known-benign baseline patterns the exclusions cover: `href="#data"` (an all-hex-letter
   *anchor*, not a colour) and `.skip { left: -999px }` (the skip-link idiom, intentionally
   not a token). Review any remaining hits: values must resolve to tokens; other
   pre-change hits, if any, are pre-existing defects to flag, not silently fix — root
   CLAUDE.md surgical rule.
3. Confirm `design/tokens.css` adds only the two semantic `--page-*` entries and no
   primitive changed value.

## 3 · Per-story acceptance walk (spec ↔ built guide)

For each story, walk its acceptance scenarios against the rendered guide:

| Story | Check | Proves |
|---|---|---|
| US1 | Each of the 7 archetypes shows every US1 data-model field (purpose, when/when-not naming the alternative, zone skeleton figure, tokenized zone gaps, content width, reflow) — smoke-probe 3 screen briefs (e.g. "audit log", "invoice editor", "plan upgrade wizard") using only the selection guidance; the full SC-006 probe runs in §5 | FR-001–FR-005 |
| US2 | Surfaces & elevation: ladder table makes every surface-on-surface combination checkably valid/invalid; card-in-card shown as a don't with named alternatives; separator rule is one ordered list | FR-006–FR-009 |
| US3 | Components & reuse states the 5-step check order and the new-construct bar; existing promotion rule still present verbatim in meaning | FR-010, FR-011 |
| US4 | Forms + View states & feedback chapters cover their minimum rule sets (see data-model.md); copy is cross-referenced to Content, not restated | FR-013–FR-015 |
| — | Content chapter's common-actions table has one canonical verb per listed action | FR-016 |

## 4 · Digest audit (contract: frontend-digest.md; FR-012)

1. Open `apps/frontend/CLAUDE.md` → "Design guide" section.
2. Confirm: one block, ≤ ~8 rule lines, exactly the six contracted gates, each naming its
   owning guide chapter; no detail present that the guide lacks; no doubled statement of
   the pre-existing token rule.

## 5 · Specimen & rule-form audit (FR-018/FR-020/FR-021)

- Every new chapter ends in a `ul.rules` checkable list and contains ≥ 1 live figure.
- Spot-check 5 random rules: each is conditional/checkable ("X must / never Y — use Z
  instead"), and no rule appears in two chapters (cross-references only).
- SC-005 probe: for each of the three original failure modes (card-in-card layering,
  from-scratch parallel component, ad-hoc page spacing), name the chapter + rule a
  reviewer would cite. All three must resolve.
- SC-006 probe (full, 10 briefs — ≥ 9 must resolve to the intended archetype using only
  the selection guidance): audit log → collection/list · customer profile → record
  detail · invoice editor → form · revenue overview → dashboard · notification
  preferences → settings · plan upgrade wizard → multi-step flow · sign-in → full-page
  utility · team directory → collection/list · new-project setup → form · not-found
  page → full-page utility.

## 6 · Merge-back gate

Standard workflow from root `CLAUDE.md`: rebase onto trunk → full suite (state explicitly
that lint/typecheck/test/build remain toolchain-TODO if still unfilled) → fast-forward
merge → remove worktree. The browser review above is the feature's operative verification
until the toolchain exists.
