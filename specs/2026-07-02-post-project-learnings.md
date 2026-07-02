# Post-project learnings

Reusable lessons from two shipped projects, folded back into the template so the next project doesn't re-derive them.

The delta beyond what the base already covers (onion, error envelope, security baseline, observability, expand-first migrations, atomic design, worktrees, i18n parity). Landed as base-contract additions, an optional add-ons mechanism, a design-guide keystone, and a new stack pack.

## What landed

- **Base additions.** `apps/backend/CLAUDE.md`: an audit-trail rule (distinct from logging) and a default-off-flag + no-op-sink integration-gating rule. `apps/frontend/CLAUDE.md`: a **Navigation chrome, overlays & scroll** section, a **Design guide** keystone section, the *One shared layout* rule extended (layout owns all clearance/insets; tab-vs-navigated as a prop), and a token-value-matches-scale guard. `db/CLAUDE.md`: seed toward realistic, named accounts.
- **`add-ons/` mechanism.** Optional capability modules, sibling to `stacks/`, opted into at Day-1 and activated via `scripts/activate-addons.sh` into always-on `.claude/rules/addon-*.md` (with a CI drift gate). Two add-ons: **test-mode** and **otp-auth**.
- **Design-guide keystone.** `design/design-guide.html` + `design/tokens.css` — the confirm-before-building-UI gate. Ship as placeholders the Fable 5 model generates per project.
- **Stack pack `taro-fastify-mysql-tencent`.** Taro 4 H5 + Fastify 4 + Knex/MySQL 8 on Tencent Cloud. Five appendices (`README` + backend/frontend/db/infra), each with the precedence line + conflict register, additions-only. Deploy seam is a real `.github/workflows/deploy.yml` pipeline.

## Decisions

- **Multi-tenancy — not extracted.** The reference implementation shipped but wasn't confidently nailed; recorded as deferred rather than promoted. Revisit if a future project nails it.
- **Test mode and OTP are add-ons, not base rules** — not every project needs them.
- **The design guide is a placeholder, generated per project by the Fable 5 model** — neutral defaults or the project's brand, structured on the Uber Base design system.

## Out of scope

Domain specifics (check-in/streak model, announcements, calendar, data imports; WeChat login + Mini Program, never built) are product features, not template patterns. A Storybook of the real framework components is left as an optional per-stack upgrade.
