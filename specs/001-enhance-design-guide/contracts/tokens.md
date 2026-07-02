# Contract — Token Additions

All additions are **tier 2 (semantic)** entries in `design/tokens.css`, aliasing existing
primitives — no new primitive values, no removed or renamed existing tokens (FR-003,
FR-019, research R3). Exact primitive choices are an implementation decision confirmed in
the browser gate; the *names and roles* below are the contract.

| Token | Tier | Role | Aliases |
|---|---|---|---|
| `--page-title-gap` | semantic | page-header block → first content | an existing `--space-*` step |
| `--page-section-gap` | semantic | between content sections within a page | formalizes the existing "between sections" spacing step |

Reused as-is (no change, listed for completeness of the archetype chapter's vocabulary):
`--gutter-screen`, `--container-content`, `--container-narrow`, `--header-clearance`,
`--bottom-nav-clearance`, `--box-padding-sm/-/-lg`, `--space-1..6`.

Constraints:

- **Live mirror (FR-019)**: both new tokens appear in the guide with `.resolved`
  annotations in the same change that adds them.
- **Comment discipline**: each new token carries the same style of role comment the file
  already uses (what relationship it governs, not where it came from).
- **No screen-side re-derivation**: archetype documentation references these names;
  no chapter or derived project restates their raw values.
- **Density**: no new density tokens — the existing three-step box scale is the density
  mechanism; the app-wide density rule (FR-005) is documentation, not a token.
