# Data Model — Design Guide Enhancement

This is a documentation feature; the "data model" is the **documentation schema** — the
required shape of each concept the guide will define. Implementation (chapter authoring)
must populate every field below; a missing field is a defect against FR-001/FR-006/
FR-010/FR-013–FR-015. Guide-representation details (nav, figures, blocks) live in
[`contracts/guide-chapters.md`](./contracts/guide-chapters.md).

## Screen Archetype (7 records — FR-001)

| Field | Type | Constraint |
|---|---|---|
| `name` | text | unique; business-meaningful (e.g. "Collection", "Record detail") |
| `purpose` | text | one sentence — the user job the page type serves |
| `when_to_use` | text | checkable conditions |
| `when_not_to_use` | text | MUST name the alternative archetype (FR-004) |
| `zones` | ordered list of Zone | ≥ 1; first zone is always the shared Page header (FR-002) |
| `zone_gaps` | token refs | one named spacing token per adjacent-zone pair (FR-003) |
| `content_width` | token ref | one of the two existing container tokens (research R3) |
| `reflow` | text | behaviour at both ends of the supported viewport range (US1/AS4) |
| `specimen` | figure ref | live wireframe figure in the chapter (FR-021) |

**Fixed record set** (clarified): Collection/list · Record detail · Form (create/edit) ·
Dashboard/overview · Settings · Multi-step flow · Full-page utility.

**Relationships**: every archetype embeds the shared **Page skeleton** (below); a zone MAY
host another archetype's *content pattern*, but exactly one archetype owns the page frame
(spec edge case "hybrid screens").

**State/lifecycle**: archetype set is append-only via the guide's evidence rule + reuse
bar (FR-011); no archetype is removed while any derived project uses it.

## Page Skeleton (1 record — FR-002)

| Field | Type | Constraint |
|---|---|---|
| `header_anatomy` | structure | title (exactly one per page) + optional description, navigation context, page-level actions |
| `title_gap` | token ref | `--page-title-gap` (research R3) |
| `section_gap` | token ref | `--page-section-gap` |
| `frame_source` | cross-ref | app frame owned by the Layout chapter (research R7) — referenced, never restated |

## Zone (embedded in archetypes)

| Field | Type | Constraint |
|---|---|---|
| `name` | text | unique within its archetype (e.g. "filter bar", "primary table") |
| `box_size` | token ref | one of the three container-padding sizes; one density app-wide (FR-005) |
| `allowed_surfaces` | Surface-level refs | which ladder levels may appear in this zone |
| `state_placement` | rule ref | where loading/empty/error render for this zone (FR-014) — authored in US4's View states chapter; archetype entries gain this cross-reference when US4 lands (legitimately absent in a US1-only build) |

## Surface Level (4 records — FR-006)

| Field | Type | Constraint |
|---|---|---|
| `name` | text | recessed · page · card/panel · floating |
| `background` | token ref | existing semantic background/surface tokens only |
| `shadow` | token ref or none | pairing rule: surface + shadow + stacking travel together |
| `stacking` | token ref or none | existing z-band tokens (floating only) |
| `may_contain` | Surface-level refs | e.g. card may NOT contain card (FR-007) |
| `may_stack_above` | Surface-level refs | closed list — any combination checkably valid/invalid (FR-009) |
| `alternatives_when_prohibited` | rule ref | spacing → background-shift inset → divider-where-allowed |

**Validation**: the separator decision rule (FR-008) is a single ordered list —
whitespace (default) → background shift → border → divider (dense data rows/tables only).

## Pattern (3 records — FR-013–FR-015)

| Field | Type | Constraint |
|---|---|---|
| `name` | text | Forms · View states · Feedback routing |
| `rules` | checkable list | each rule conditional, with do/don't + "use instead" (FR-018) |
| `library_agnostic` | invariant | expressible in any component library (FR-017); on conflict the pattern wins (spec edge case) |
| `copy_source` | cross-ref | state/feedback copy cross-references the Content chapter (FR-020) |
| `specimen` | figure ref | live do/don't figure (FR-021) |

**Forms pattern minimum rule set**: label placement · field-width ↔ expected content ·
group spacing · required/optional marking · button order + placement per container
(page, dialog, inline) · validation placement + recovery.

**View-states minimum rule set**: per archetype zone: loading, empty, error, partial
placement · skeleton-vs-indicator rule.

**Feedback-routing minimum rule set**: inline vs floating vs blocking decision · anchored
to the causing control or zone.

## Reuse Gate (1 record — FR-010/FR-011)

| Field | Type | Constraint |
|---|---|---|
| `check_order` | ordered list | archetype → documented pattern → existing screens/primitives → extend a primitive → create new |
| `new_construct_bar` | rule | demonstrated need + no existing equivalent; aligned with the existing twice/thrice promotion rule (extends, does not replace) |
| `justification_path` | rule | any exception is recorded with written justification (feeds SC-004) |

## Rule Digest (1 record — FR-012, clarified)

| Field | Type | Constraint |
|---|---|---|
| `location` | file section | `apps/frontend/CLAUDE.md` → existing "Design guide" section (research R5) |
| `entries` | ≤ ~8 lines | hard gates only: token-only · archetype-first · surface ladder/no card-in-card · separator order · reuse-first · one density |
| `entry_shape` | rule + pointer | each line names the owning guide chapter as canonical |
| `drift_control` | invariant | guide is canonical; digest never carries detail absent from the guide |

## Rhythm Token (new tier-2 entries — FR-003/FR-019)

| Field | Type | Constraint |
|---|---|---|
| `name` | `--page-*` | semantic tier only; aliases existing primitives (research R3) |
| `value` | primitive ref | no new raw values |
| `guide_visibility` | invariant | visible in the guide in the same change (live mirror, FR-019) |
