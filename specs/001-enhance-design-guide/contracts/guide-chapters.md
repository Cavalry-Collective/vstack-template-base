# Contract — Guide Chapters

The interface this feature exposes is the guide itself: what a reader (agent or human)
can rely on finding, where. Implementation must satisfy this contract exactly; the
chapter *content* rules live in [`../data-model.md`](../data-model.md).

## Navigation contract (research R2)

Sidebar groups and chapter order after the change:

| Group | Chapters (order) | Change |
|---|---|---|
| Start | Introduction · Principles · Tokens | unchanged |
| Foundations | Colour · Typography · Spacing · Layout · Shape & border · **Surfaces & elevation** · Motion · Icons · States & focus · Accessibility · Content · Data formatting | Elevation extended + retitled; Spacing/Layout/Content/Shape receive small in-place edits |
| **Composition** (new) | **Screen archetypes** · **Forms** · **View states & feedback** | three new chapters |
| Beyond | **Components & reuse** | existing chapter rewritten in role (keeps id and no-inventory stance) |

Constraints:
- Hash-router behaviour preserved: each chapter is a `section` page; no-JS fallback
  (one long page) still works; pager prev/next follows the new order.
- Existing chapter ids stay stable (`#elevation`, `#components` keep their anchors —
  retitles do not break inbound links from `apps/frontend/CLAUDE.md` or specs).

## Per-chapter block contract

Every **new** chapter (and the two extended ones, for their new content) MUST contain, in
the guide's existing idiom:

1. `kicker` (group label) + `h1` + one-sentence `lede`.
2. At least one **live specimen figure** (FR-021) using existing figure classes
   (`.figure`, `.app-frame`-style miniatures, `.dodont`, token-annotated tables with
   `.resolved`), styled by semantic tokens only.
3. **When to use / when not to use** blocks wherever a choice exists (archetypes,
   surface levels, separator, feedback routing) — the "when not" side names the
   alternative (FR-004, FR-018).
4. A closing `ul.rules` list of checkable rules — a violation is citable as
   chapter + rule (SC-005).
5. Cross-references instead of restatement wherever another chapter owns a rule
   (FR-020): rounding → Shape & border; app frame → Layout; copy → Content.

## Edits-in-place contract (existing chapters)

| Chapter | Edit | Bound |
|---|---|---|
| Spacing | pointer from the spacing-band rules to the archetype chapter's page-rhythm tokens | ≤ 2 lines; no rule moves |
| Layout | cross-reference: "what fills the body region → Screen archetypes" | ≤ 2 lines |
| Shape & border | note that the concentric formula also governs nested-surface rounding (R4) | ≤ 2 lines |
| Content | add common-actions vocabulary table (FR-016): one canonical verb per recurring action (create, edit, delete, save, cancel, search, filter, export at minimum) | one table + ≤ 2 rules |
| Surfaces & elevation | existing shadow/z content kept verbatim where possible; ladder, nesting, separator content added around it | existing rules keep their meaning |
| Components & reuse | keeps: no-inventory stance, twice/thrice promotion rule, specimen-promotion path; adds: reuse-first check order + new-construct bar (FR-010/011) | promotion rule text preserved |

## Intro-page contract

The Introduction's reader instructions ("New project? / Building? / Reviewing?") gain one
line for builders: pick the screen archetype before building any screen. (Keeps the intro
the guide's entry contract; consistent with digest entry #2.)
