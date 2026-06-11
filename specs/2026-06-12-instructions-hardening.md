# Agent-instructions hardening

## Goal

Close the gaps a 2026-06-12 deep review of the agent instructions confirmed, so instantiated projects stop inventing contracts per-project (error/list shapes), the highest-risk prose rules become mechanism (hooks, drift gates), and duplicated surfaces stop drifting (stack activation existed as three diverging bash copies).

## Decisions (binding, user-confirmed)

| Decision | Choice |
|---|---|
| Error contract | One envelope — `{ "error": { "code", "message", "correlationId" } }` — pinned in `apps/backend/CLAUDE.md`; correlation id also travels as the `x-correlation-id` response header on every response |
| List contract | `{ "data": [...], "page", "recordsPerPage", "totalRecords" }`; empty result is `200` + `[]`, never `404` |
| Methods / status codes | `204` for DELETE (no body); no `PATCH` by default (`PUT` is full-resource replace); `429` named |
| Feature flags | A boolean key in the validated config schema, default off; no flag service/SDK unless a project adopts one explicitly |
| Enforcement | `.claude/settings.json` with **ask** rules (not deny — an approved run must stay possible) for `terraform apply`, `prisma migrate reset`, `git push`; a PreToolUse hook blocks Edit/Write to committed files under `db/migrations/` (`*.md` exempt; fails open without `jq`) |
| Stack activation | `scripts/activate-stack.sh [<pack>] [--check]` is the single rule-build mechanism; the three hand-copied bash blocks (root README + both pack READMEs) are replaced by calls to it; CI runs `--check` as a real, non-TODO step |
| Route table | `design/README.md` inventory drops its Route column — the route registry stays the only route→URL surface (`apps/frontend/CLAUDE.md` already forbids a second) |
| Terraform lock file | `.terraform.lock.hcl` is committed (removed from `.gitignore`), per Terraform's own recommendation; recorded in `infra/CLAUDE.md` |
| Vercel pack: worktrees | Adopts per-worktree databases on the shared server (mirrors the Prisma pack); recorded in its db conflict register |
| Vercel pack: store | Context-providers-seeded-with-server-data stance **kept** (it differs from the nextjs pack deliberately — REST-only flow has no other client carrier) and recorded in its frontend conflict register |
| Typecheck | A `<pm> typecheck` verb exists everywhere the suite is named (commands block, Definition of Done, pack dev/CI blocks); explicit no-op in plain-JS apps |

## User stories

### S1 (P1) — contract holes closed

`apps/backend/CLAUDE.md` pins the error envelope (+ header transport), the list envelope, DELETE/PATCH/429 stances; `apps/frontend/CLAUDE.md` points its correlation-id rule at the pinned contract; root `CLAUDE.md` defines what a feature flag is.

- **AC:** the frontend can implement its correlation-id and error-state rules from the named fields alone, with no invented shape. *Verify: read the two files together; no open referent.*

### S2 (P1) — enforcement over prose

`.claude/settings.json` (ask-rules + hook registration) and `.claude/hooks/block-applied-migration-edits.sh` exist and work.

- **AC:** the hook exits 2 for a committed migration file, 0 for an untracked one and for `*.md`. *Verify: run it with simulated stdin against a scratch repo; state observed exits.*

### S3 (P1) — one activation mechanism

`scripts/activate-stack.sh` builds rule files for any pack (auto-detects the pack when one remains; handles optional `infra.md`); `--check` is wired into `ci.yml` uncommented; root README, `stacks/README.md`, and both pack READMEs point at the script instead of carrying bash copies.

- **AC1:** generate + `--check` round-trip cleanly for the `vercel` pack (4 rules) in a scratch copy; an edited appendix fails `--check`. *Verify: run it; state observed output.*
- **AC2:** on this template repo (no rules built), `--check` exits 0. *Verify: run it here.*

### S4 (P1) — pack gaps closed

Vercel pack: store conflict registered; per-worktree DBs adopted (db register entry replaces "no conflicts"); production-project name dropped from the README; typecheck verb added. Prisma pack: PR-template surface added to its round-trip register entry; misplaced `[JS]` Babel bullet removed from `db.md`; typecheck verb added. PR template's migration checkbox defers to the active pack's register.

- **AC:** every register entry still names a real, current base surface. *Verify: re-read each register against the edited base files.*

### S5 (P2) — consistency sweep

Typecheck named consistently; `.terraform.lock.hcl` committed; `infra/CLAUDE.md` deduped (apply-approval ×3 → ×1, `ignore_changes` ×3 → ×2 with pointer) + sentence-case headings + lock-file rule; design inventory route column dropped; worktree env-copy snippet reports instead of silently skipping; deploy trigger wording matches `deploy.yml`; PR-template i18n line admits the single-language strings module; `stacks/README.md` "exactly four files" → "at least", platform-naming exception folded in; Day-1 checklist gains a protect-`main` step.

- **AC:** the Day-1 step-9/10 greps still behave (spec + stacks excluded; no new `TODO: replace`-matching text outside stubs). *Verify: run the greps.*

## Out of scope

- `AGENTS.md` symlink for non-Claude agents (YAGNI until another agent touches the repo).
- The remaining deferred lows from `specs/2026-06-06-claude-md-overhaul.md` (spec TEMPLATE.md, `.env.example`, size/complexity rule, ADR convention, memory-worthiness definition, trunk-name mismatch) — two of that backlog's items (feature-flag mechanics, `.claude/` settings artifacts) are promoted and closed here.
- Restating pack CI blocks as runnable workflow files (packs stay guidance-as-text).

## Open questions

None — all decisions resolved above.
