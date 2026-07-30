# `stacks/` — stack packs

The base CLAUDE.md files are framework-agnostic on purpose. A **stack pack** binds those agnostic contracts to one concrete stack (frameworks, ORM, package manager) through appendix docs that **ride on top of** the base: they add bindings and resolve conflicts, never restate the base. One pack is chosen at instantiation; the rest are deleted. This file is the system doc — read once, not loaded during normal work. Each pack carries its own manifest `README.md`.

## What a pack is

A pack is a directory `stacks/<pack-name>/` of **guidance-as-text**: concrete config and command snippets to copy. A pack never ships installed dependencies, lockfiles, or generated scaffolding in the buildable tree.

`<pack-name>` is a short identity name, lowercase and hyphenated — the name an adopter recognizes the stack by. It comes from the deployment platform or product surface when that choice defines the stack (`vercel-csr`, `vercel-ssr`, `wechat`), from a well-known stack acronym (`mern`), from the stack's defining framework (`django`), or from its architectural character (`enterprise`). The name stays auditable because every pack README records the underlying `<frontend>-<backend>-<database>` triple in its naming note. Packs sharing one platform coexist by suffixing the shape that distinguishes them — for `vercel-csr` / `vercel-ssr` the suffix *is* the rendering model. Each README names its sibling(s) and the contrast, so an adopter picks deliberately.

## Required file set

Every pack carries at least these four files (one may be thin, but all four exist). A pack MAY also add `infra.md` as an optional fifth appendix, under the same invariants — infra is cloud-shaped, not app-stack-shaped, so no pack is required to ship it.

| File | Binds onto base file | Holds |
|---|---|---|
| `README.md` | — (manifest) | identity, appendix→base mapping, suggested `<pm>` blocks, day-1 wiring, deploy-seam pointer |
| `backend.md` | `apps/backend/CLAUDE.md` | HTTP-framework bindings, DI/composition root, language-path deltas |
| `frontend.md` | `apps/frontend/CLAUDE.md` | UI-framework bindings, rendering model, four-states/mutation mapping |
| `db.md` | `db/CLAUDE.md` (+ repo ring) | ORM/migration bindings, schema/migration mechanics |

## Pack invariants (a pack is valid iff it satisfies all of these)

- **Additions-only.** No restating base content — only (a) stack bindings and (b) explicit conflict resolutions. If a line is true without naming the stack, it does not belong.
- **Register or obey.** A pack may override any base rule — even a structural one, like swapping the onion's feature-first axis for layer-first — but only through a conflict-register entry; a silent contradiction makes the pack invalid. What no pack may drop is the discipline itself: layers stay separated and dependencies point one way, whatever the axis.
- **Precedence line atop every appendix** (verbatim): `> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.`
- **Conflict register ending every appendix.** The four registers are the single audit surface — where the appendix replaces a base statement, it is listed here, not left as a live contradiction. An entry that contradicts nothing is not a conflict — plain bindings stay in the body; padding the register weakens the audit. Each entry (bullet or blockquote — the fields matter, not the markup), ending in a checkable imperative:
  > **Base says:** … **In this stack:** … **Because:** … **Concretely:** … *(one DO/DON'T an agent can check or grep for)*

  A zero-conflict appendix states so: `_No conflicts — this appendix only adds bindings; the base contract is unchanged._`
- **No project-specific values.** No DB URLs, secrets, env, per-project form-factor declarations, or per-project route tables — those go into project-local files at instantiation.
- **Size discipline.** Each appendix is well under 200 lines, terse and checkable.

## Activation (by instruction)

Packs activate by **instruction, not machinery**. Each area's `CLAUDE.md` (`apps/backend`, `apps/frontend`, `db`, `infra`) tells the agent to read the adopted pack's matching appendix before working in that area — a backend task pulls in `backend.md`, and only that. Adoption is structural: keep exactly **one** pack directory under `stacks/` and delete the rest, so "the adopted pack" is unambiguous. The appendix is read directly from `stacks/` — it is the single source of truth, with no generated copy to drift.

## How to add a pack

1. Create `stacks/<pack-name>/` with the four required files.
2. Put the precedence line atop each appendix and a conflict register at the end; keep every line additions-only.
3. Write the manifest `README.md` — identity, appendix→base mapping, suggested dev + CI `<pm>` blocks, deploy-seam pointer.
4. Do no add-on work. Add-on wiring is derived at adoption from each add-on's *Binds to a stack* seam list plus this pack's appendices. Note in the manifest only a genuine incompatibility: an add-on whose requirements the stack cannot meet.
5. Nothing else to wire — the per-area `CLAUDE.md` pointers pick the pack up as soon as it is the only directory under `stacks/` (see *Activation*).
