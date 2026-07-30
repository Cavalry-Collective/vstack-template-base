<img src="docs/brand/vstack-lockup-tile-1120.png" alt="Visual Stack" width="420">

# Visual Stack project template

**An opinionated starting point for full-stack projects built by people and AI agents.**

Project conventions and architecture contracts by [Cavalry Collective](https://cavalry.sg).

Most templates give you generated code. This one gives you the decisions that should outlast it:
where code belongs, how changes move from idea to production, what quality means, and what must be
verified before work is done.

There is no application to install and no generator to run. Start from the template, choose a stack,
keep the capabilities the project needs, and build inside the resulting contract.

This is the base project behind [Visual Stack](https://github.com/Cavalry-Collective/visual-stack).
Use it directly from GitHub or run `/vstack:start` for guided setup.

---

## Start a project

Click **Use this template** on GitHub, create a repository, and complete the
[Day-1 setup](#day-1-setup).

The setup chooses the project’s concrete stack and removes the guidance it does not need. After that,
the files left in the repository are the source of truth.

---

## What you get

| Path | Purpose |
| --- | --- |
| [`CLAUDE.md`](CLAUDE.md) | Project-wide architecture, workflow, quality gates, and Definition of Done |
| [`apps/backend/`](apps/backend/) | Backend contract: domain, services, repositories, and controllers |
| [`apps/frontend/`](apps/frontend/) | Frontend contract: state, services, pages, components, and design tokens |
| [`db/`](db/) | Database and migration contract |
| [`infra/`](infra/) | Terraform structure, safety rules, and verification |
| [`design/`](design/) | The token-driven design guide confirmed before screen work begins |
| [`specs/`](specs/) | Short feature specifications written before implementation |
| [`stacks/`](stacks/) | Concrete stack packs that bind the base contracts to frameworks and platforms |
| [`add-ons/`](add-ons/) | Optional guidance for capabilities such as billing, OTP, multi-tenancy, and LLM calls |
| [`.github/workflows/`](.github/workflows/) | Integrity checks for this template and workflow examples for generated projects |

The `CLAUDE.md` files sit beside the work they govern. A person can read them as engineering
documentation; Claude Code loads the relevant contract when it works in that area.

---

## Choose a stack

The base contracts define the shape of the system without choosing its libraries. A stack pack makes
those choices and records where they differ from the base.

| Pack | Application |
| --- | --- |
| [`django`](stacks/django/README.md) | React SPA, Django REST API, and Postgres |
| [`enterprise`](stacks/enterprise/README.md) | Server-first Next.js, separate NestJS API, Prisma, and Postgres |
| [`mern`](stacks/mern/README.md) | React SPA, Express API, and MongoDB |
| [`vercel-csr`](stacks/vercel-csr/README.md) | React SPA, Fastify API, Postgres, and Vercel |
| [`vercel-ssr`](stacks/vercel-ssr/README.md) | One full-stack Next.js application on Vercel with Postgres |
| [`wechat`](stacks/wechat/README.md) | Taro H5, Fastify, MySQL, and Tencent Cloud |

A project keeps one pack. Its README contains the exact Day-1 changes, development commands, CI
requirements, and deployment model for that stack.

See [Stack packs](stacks/README.md) for how packs bind to the base contracts.

---

## Add capabilities

Add-ons cover concerns that do not belong in every project: test mode, OTP authentication, LLM
calls, premium design, enterprise compliance, multi-tenancy, SaaS billing, and SEO.

A project may keep any number of add-ons. Each retained directory is adopted; delete the rest.
The add-on defines what the capability must do, while the active stack pack supplies its concrete
implementation.

See [Optional add-ons](add-ons/README.md) for the available capabilities and their prerequisites.

---

## Day-1 setup

Complete this once when creating a project.

1. **Create and clone the repository.** Use this template on GitHub, then open
   `project.code-workspace`.
2. **Read the contracts.** Start with the root [`CLAUDE.md`](CLAUDE.md), then the contracts under
   `apps/backend/`, `apps/frontend/`, `db/`, and `infra/`.
3. **Adopt one stack pack.** Follow its Day-1 instructions and delete the other pack directories.
   Copy its development commands into the root `CLAUDE.md`, record the adopted pack under
   **Learnings**, and use its CI section when wiring the workflow in step 5.
4. **Choose the add-ons.** Keep the capabilities the project needs, check their prerequisites, and
   delete the others.
5. **Wire the toolchain.**
   - Replace the command placeholders in the root `CLAUDE.md`.
   - Copy `.github/workflows/examples/ci.yml.example` to `.github/workflows/ci.yml` and implement
     every active gate.
   - Delete `.github/workflows/template-integrity.yml`; it protects this source template, not the
     generated project.
   - Add `.github/workflows/deploy.yml` only when the chosen pack requires it and the deployment
     target is configured.
   - Add a real `.env.example`.
6. **Set the frontend baseline.** Declare the primary form factor in
   `apps/frontend/CLAUDE.md`. Rebrand `design/tokens.css`, open `design/design-guide.html`, and
   confirm the visual system before building screens.
7. **Add runtime configuration.** Restore the project’s local environment and secrets. Stand up
   staging when the chosen pack defines one.
8. **Run the complete suite.** Push the configured project and confirm its first CI run is green.
9. **Protect `main`.** Require the project’s CI check, block force pushes and deletion, and keep
   history linear. Configure this after the first successful run so the required check exists.

Finally, confirm that no setup marker remains:

```bash
grep -rn 'FILL IN ON SETUP\|TODO:' . \
  --exclude-dir=stacks --exclude-dir=specs --exclude-dir=.git \
  | grep -v '^\./README\.md:'
grep -n '^<pm> ' CLAUDE.md
grep -rn '^ *# *- name:' .github/workflows/
```

All three commands should return nothing.

Replace this README with the project’s own once setup is complete.

---

## Build from the contracts

For each non-trivial change:

1. Write a short specification under `specs/`.
2. Build the smallest independently shippable slice.
3. Run the relevant lint, typecheck, tests, build, migration, accessibility, and visual checks.
4. Verify the result by observing it, not by inferring that it should work.
5. Rebase and merge only when the integrated change is green.

The contracts remain framework-independent unless the retained stack pack says otherwise. Add-ons
become requirements only when the project adopts them.

---

## Why it is documentation-shaped

Generated scaffolding dates quickly. Architecture boundaries, delivery rules, and verification
standards last much longer.

Keeping those decisions in plain files makes them visible, reviewable, and available to the people
and agents doing the work. The template provides the house style; the project supplies the product.

---

## Support

- Found a wrong or contradictory rule? [Open an issue](https://github.com/Cavalry-Collective/vstack-template-base/issues).
- Want to contribute? Read [`CONTRIBUTING.md`](CONTRIBUTING.md).
- Found a security problem? Follow [`SECURITY.md`](SECURITY.md).

Projects created from this template are maintained by their owners.

## License

[MIT](LICENSE). A project created from the template may replace this license with its own.
