# `stacks/` — stack packs

The base CLAUDE.md files are framework-agnostic on purpose. A **stack pack** binds those agnostic contracts to one concrete stack (frameworks, ORM, package manager) through appendix docs that **ride on top of** the base — they add bindings and resolve conflicts, never restate the base. One pack is chosen at instantiation; the rest are deleted. This file is the system doc (read once, not loaded during normal work); each pack carries its own manifest `README.md`.

## What a pack is

A pack is a directory `stacks/<pack-name>/` of **guidance-as-text** — concrete config and command snippets to copy, never installed dependencies, lockfiles, or generated scaffolding in the buildable tree. `<pack-name>` is `<frontend>-<backend>-<database>`, lowercase and hyphenated; **append the client/ORM when it is the distinguishing choice** (e.g. `nextjs-nestjs-postgres-prisma`) so a future TypeORM-on-Postgres pack doesn't collide. **Platform exception:** a pack whose identity is the deployment platform rather than the framework triple (e.g. `vercel`) may be named for the platform — its README records the would-be triple, and it is renamed to the convention form if a second pack on that platform ever appears.

## Required file set

Every pack carries all five files. **Absence is a statement**: an area that genuinely doesn't apply to the stack still ships its file, reduced to a stub that opens with the precedence line, states *what doesn't apply and why*, points at wherever the area's obligations actually live, and ends with the no-conflicts line. A missing file is a conformance failure.

| File | Binds onto base file | Holds |
|---|---|---|
| `README.md` | — (manifest) | identity, appendix→base mapping, dev + CI `<pm>` blocks, Day-1 wiring, deploy-seam pointer |
| `backend.md` | `apps/backend/CLAUDE.md` | HTTP-framework bindings, DI/composition root, language-path deltas |
| `frontend.md` | `apps/frontend/CLAUDE.md` | UI-framework bindings, rendering model, four-states/mutation mapping |
| `db.md` | `db/CLAUDE.md` (+ repo ring) | ORM/migration bindings, schema/migration mechanics |
| `infra.md` | `infra/CLAUDE.md` | provider bindings, workload shape, deploy pipeline — or the n/a stub |

## One shape, parallel reading

Every area appendix follows the same skeleton, so any two packs compare side by side and a future pack starts from a known outline:

1. **Precedence line** (verbatim, below).
2. **Binding at a glance** — the stack picks for this area, each rejected alternative named once, here and nowhere else.
3. **Structure** — how the base shape (rings, layers, folders) maps onto this stack.
4. **Bindings** — the area's concrete sections. Packs add sections only where the stack genuinely differs, and the difference is stated, never implied.
5. **Security bindings** (`backend.md` and `frontend.md`, always present) — the concrete header/CSP mechanism, the SSRF check, and secret write-only masking the base delegates to the pack.
6. **Testing** — runner and per-ring/per-layer approach.
7. **Conflict register** (last, format below).

The manifest `README.md` follows its own fixed shape: identity (and would-be triple for platform packs) → appendix→base mapping → dev block → CI block → Day-1 wiring **including the root-CLAUDE.md Learnings entry** → deploy seam.

## Pack invariants (a pack is valid iff it satisfies all of these)

- **Additions-only.** No restating base content — only (a) stack bindings and (b) explicit conflict resolutions. If a line is true without naming the stack, it does not belong.
- **Register or obey.** A pack may override any base rule — even a structural one, like swapping the onion's feature-first axis for layer-first — but only through a conflict-register entry; a silent contradiction makes the pack invalid. What no pack may drop is the discipline itself: layers stay separated and dependencies point one way, whatever the axis.
- **Registers hold replacements only.** A binding that doesn't contradict the base belongs in the body, never the register — the register is the audit surface for overrides, and diluting it hides them.
- **Standalone.** A pack never references a sibling pack — siblings are deleted at instantiation, so every comparison or contrast is rewritten as a self-contained statement.
- **Precedence line atop every appendix** (verbatim): `> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.`
- **Conflict register ending every appendix.** Bulleted entries, each ending in a checkable imperative:
  > **Base says:** … **In this stack:** … **Because:** … **Concretely:** … *(one DO/DON'T an agent can check or grep for)*

  A zero-conflict appendix states so: `_No conflicts — this appendix only adds bindings; the base contract is unchanged._`
- **No project-specific values.** No DB URLs, secrets, env, per-project form-factor declarations, or per-project route tables — those go into project-local files at instantiation.
- **Size discipline.** Each appendix is well under 200 lines, terse and checkable.

## Activation (by instruction)

Packs activate by **instruction, not machinery**. Each area's `CLAUDE.md` (`apps/backend`, `apps/frontend`, `db`, `infra`) tells the agent to read the adopted pack's matching appendix before working in that area — so a backend task pulls in `backend.md`, and only that. Adoption is structural: keep exactly **one** pack directory under `stacks/` and delete the rest, so "the adopted pack" is unambiguous. The appendix is read directly from `stacks/` — the single source of truth, no generated copy to drift. The pack's `README.md` is read once, at adoption, from the Day-1 checklist.

## How to add a pack

1. Create `stacks/<pack-name>/` with all five files, each on the skeleton above (`infra.md` may be the n/a stub).
2. Put the precedence line atop each appendix and a conflict register at the end; keep every line additions-only.
3. Write the manifest `README.md` on the manifest shape, including the Day-1 Learnings entry.
4. Add a bindings section for each add-on the template ships (see `add-ons/README.md`).
5. Nothing else to wire — the per-area `CLAUDE.md` pointers pick the pack up as soon as it is the only directory under `stacks/` (see *Activation*).
