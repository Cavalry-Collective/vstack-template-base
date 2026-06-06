# `stacks/` — stack packs

The base CLAUDE.md files are framework-agnostic on purpose. A **stack pack** binds those agnostic contracts to one concrete stack (frameworks, ORM, package manager) through appendix docs that **ride on top of** the base — they add bindings and resolve conflicts, never restate the base. One pack is chosen at instantiation; the rest are deleted. This file is the **system doc** (read once, not loaded during normal work); each pack carries its own manifest `README.md`.

## What a pack is

A pack is a directory `stacks/<pack-name>/` of **guidance-as-text** — concrete config and command snippets to copy, never installed dependencies, lockfiles, or generated scaffolding in the buildable tree. `<pack-name>` is `<frontend>-<backend>-<database>`, lowercase and hyphenated; **append the client/ORM when it is the distinguishing choice** (e.g. `nextjs-nestjs-postgres-prisma`) so a future TypeORM-on-Postgres pack doesn't collide.

## Required file set

Every pack carries exactly these four files (one may be thin, but all four exist):

| File | Binds onto base file | Holds |
|---|---|---|
| `README.md` | — (manifest) | identity, appendix→base mapping, suggested `<pm>` blocks, day-1 wiring, deploy-seam pointer |
| `backend.md` | `apps/backend/CLAUDE.md` | HTTP-framework bindings, DI/composition root, language-path deltas |
| `frontend.md` | `apps/frontend/CLAUDE.md` | UI-framework bindings, rendering model, four-states/mutation mapping |
| `db.md` | `db/CLAUDE.md` (+ repo ring) | ORM/migration bindings, schema/migration mechanics |

## Pack invariants (a pack is valid iff it satisfies all of these)

- **Additions-only.** No restating base content — only (a) stack bindings and (b) explicit conflict resolutions. If a line is true without naming the stack, it does not belong.
- **Precedence line atop every appendix** (verbatim): `> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.`
- **Conflict register ending every appendix.** The four registers are the single audit surface — where the appendix replaces a base statement, it is listed here, not left as a live contradiction. Each entry, ending in a checkable imperative:
  > **Base says:** … **In this stack:** … **Because:** … **Concretely:** … *(one DO/DON'T an agent can check or grep for)*

  A zero-conflict appendix states so: `_No conflicts — this appendix only adds bindings; the base contract is unchanged._`
- **No project-specific values.** No DB URLs, secrets, env, per-project form-factor declarations, or per-project route tables — those go into project-local files at instantiation.
- **Size discipline.** Each appendix is well under 200 lines, terse and checkable.

## Activation (path-scoped rules)

Packs activate through **`.claude/rules/` with `paths:` frontmatter** — the documented "load only for matching files" mechanism. Day 1 adds one rule per appendix: the appendix **body copied** with `paths:` frontmatter prepended (rule files do not resolve `@`-imports — only `CLAUDE.md` files do — so each rule must be self-contained). An appendix loads at full size **only** when an agent touches files matching its rule — a backend-only task never loads the frontend appendix. The appendix under `stacks/` stays the source of truth: edit it, then regenerate its rule file. The per-pack `README.md` carries the exact build commands.

> **Decision record (2026-06-06):** chose `.claude/rules/` prepend-copies over (a) `@import` in a nested app CLAUDE.md — the composed lazy-load behavior is undocumented and subdir loading is reported unreliable; (b) a prose "read this first" pointer — an agent can skip a request, a loaded rule cannot; (c) copying appendices into app dirs — that duplicates into the buildable tree and breaks "unused packs get deleted"; (d) `@`-importing the appendix from the rule file — rule files don't resolve `@`-imports per the docs, so the import would silently never load. A symlink under `.claude/rules/` also works but loses path-scoping (the appendix carries no frontmatter), so it would load unconditionally.

## How to add a pack

1. Create `stacks/<pack-name>/` with the four required files.
2. Put the precedence line atop each appendix and a conflict register at the end; keep every line additions-only.
3. Write the manifest `README.md` — identity, appendix→base mapping, the `.claude/rules/` files, suggested dev + CI `<pm>` blocks, deploy-seam pointer.
4. Activate per the manifest's day-1 wiring (see the root README `## Day-1 checklist`).

A pack MAY add an optional `infra.md` later under the same invariants (infra is cloud-shaped, not app-stack-shaped — not required in v1).
