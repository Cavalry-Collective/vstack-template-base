# Stack packs

The base instruction files are framework-independent. A stack pack binds them to one concrete application stack, database toolchain, package manager, and deployment platform.

A project adopts exactly one pack during Day-1 setup. Keep that pack under `stacks/` and delete the others.

## How packs work

- Each area instruction tells the agent to read the adopted pack's matching appendix.
- Appendices add stack bindings and resolve explicit conflicts.
- The base remains authoritative wherever the appendix is silent.
- The retained files are the source of truth. There is no generated copy.
- Add-on bindings are derived from the add-on's **Binds to a stack** section and the adopted appendices.

## Required files

Every pack contains:

| File | Binds to | Contains |
|---|---|---|
| `README.md` | pack manifest | stack identity, Day-1 changes, commands, CI, deployment |
| `backend.md` | `apps/backend/CLAUDE.md` | framework, language, dependency injection, edge, testing |
| `frontend.md` | `apps/frontend/CLAUDE.md` | rendering, routing, data flow, UI toolchain, testing |
| `db.md` | `db/CLAUDE.md` and the repo ring | schema, migrations, transactions, local and CI databases |

A pack may add `infra.md` when its deployment platform is part of the stack.

## Appendix rules

- Add only stack-specific bindings and conflict resolutions.
- Do not repeat rules that are already complete in the base.
- Keep project-specific values, routes, secrets, and environment choices out of the pack.
- Keep each appendix easy to scan and under 200 lines.
- Record the underlying `<frontend>-<backend>-<database>` identity in the manifest.

Every appendix must open with this line verbatim:

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Every appendix must end with **Conflict register**. Record only real contradictions using all four fields:

> **Base says:** ... **In this stack:** ... **Because:** ... **Concretely:** ...

End **Concretely** with an instruction that can be checked in review. When there is no conflict, write:

`_No conflicts — this appendix only adds bindings; the base contract is unchanged._`

## Add a pack

1. Create `stacks/<pack-name>/` with the four required files.
2. Add `infra.md` only when the pack owns the deployment platform.
3. Name the pack after its defining platform, framework, product surface, or established stack acronym.
4. Put the precedence line and conflict register in every appendix.
5. Add the Day-1 commands and CI checks to the manifest.
6. State genuine add-on incompatibilities in the manifest.

Use a short lowercase, hyphenated name. If two packs share a platform, include the distinguishing application shape, as in `vercel-csr` and `vercel-ssr`.
