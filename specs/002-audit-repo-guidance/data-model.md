# Data Model: Template Guidance Audit & Public Showcase

**Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

This feature manipulates documents, not database rows. The "data" is the audit's working records, kept as markdown tables inside the findings report and rule inventory. The entities below define those records' fields, allowed values, and state transitions.

## GuidanceFile

One record per file in the audit scope (SC-001 requires 100% coverage).

| Field | Values | Notes |
|---|---|---|
| `path` | repo-relative path | identity |
| `audience` | `agent` \| `human` \| `both` | drives FR-007 (agent-binding) and the dual-audience edge case |
| `tier` | `root` \| `generic-area` \| `stack-pack` \| `add-on` \| `meta` \| `vendored` | `vendored` = Spec Kit tooling, flag-only (never streamlined) |
| `loading` | `auto` \| `lazy-subtree` \| `one-hop` \| `orphaned` | per the R1 loading model; the discovery map (SC-002) is this column for all files |
| `verdict` | `clean` \| list of Finding ids | every file gets exactly one (SC-001) |
| `words_before` / `words_after` | integer | feeds SC-003; blank for `vendored` |

**Validation rules**
- Every file with `audience` ∈ {`agent`, `both`} must end with `loading` ∈ {`auto`, `lazy-subtree`, `one-hop`} — `orphaned` is a Finding (FR-007, SC-005).
- A `human`-audience file must not be the sole carrier of any Rule (US5 scenario 2).

## Finding

One record per issue discovered by the audit.

| Field | Values | Notes |
|---|---|---|
| `id` | `F-###` | stable across report revisions |
| `location` | `path[:section]` | where the issue lives |
| `issue` | prose | what is wrong |
| `violates` | principle/convention reference | which stated rule or convention (FR-002) |
| `severity` | `release-blocking` \| `high` \| `medium` \| `low` | `release-blocking` = public-readiness (FR-011, FR-013) |
| `remedy` | prose | recommended fix |
| `destructive` | yes/no | delete/rename/move/history rewrite ⇒ yes |
| `disposition` | see states below | maintainer-owned |

**States**: `proposed → approved | rejected`; `approved → applied → verified`.

**Transition rules**
- `destructive: yes` findings may not leave `proposed` without explicit maintainer approval (FR-010).
- The release gate (below) counts only `release-blocking` findings; all must reach `verified` or `rejected` before release (SC-009).

## Rule

One record per actionable rule in the pre-streamlining corpus — the zero-loss ledger (FR-004, SC-003).

| Field | Values | Notes |
|---|---|---|
| `id` | `R-###` | assigned during inventory, before any edit |
| `source` | file path | where the rule lived at baseline |
| `statement` | condensed rule text | what it obliges |
| `disposition` | `kept` \| `merged(R-###)` \| `moved(path)` \| `removed` | `removed` requires a linked approved Finding |

**Validation rule**: after streamlining, zero rules with `disposition: removed` lack an approving Finding reference.

## StackPack

One record per pack (FR-015, SC-011).

| Field | Values | Notes |
|---|---|---|
| `name` | pack directory name | |
| `docs` | presence map for `README, backend, frontend, db, infra` | `present` \| `n/a-declared` \| `missing` |
| `exceptions` | list of labelled deviations | each must carry the exception label (FR-006) |
| `conforms` | yes/no | yes ⇔ no `missing` docs and all deviations labelled |

**Validation rule**: `missing` is never acceptable at completion — an area is `present` or `n/a-declared` with a stated reason.

## ReleaseGate

Singleton checklist derived from `release-blocking` findings (SC-009).

| Item | Check |
|---|---|
| Secrets | scanner clean over working tree **and** full history |
| Internal references | grep pass clean: no internal URLs/hosts, personal data, internal project names |
| License | `LICENSE` (MIT) present at root (FR-013) |
| Front door | positioning statement present and passes the fresh-reader test (FR-012, SC-008) |
| Branding | Cavalry mark + attribution on front door and design guide, assets local to this repo (FR-016, SC-012) |

**Rule**: all items pass ⇒ repository is release-ready; the actual flip to public is the maintainer's action, outside this feature.

## Relationships

- `Finding.location` → `GuidanceFile.path`; a file's `verdict` lists its findings.
- `Rule.source` → `GuidanceFile.path`; `Rule.disposition: removed` → an approved `Finding.id`.
- `StackPack.docs` → five `GuidanceFile` records; conformance failures surface as Findings.
- `ReleaseGate` items ← all `release-blocking` Findings.
