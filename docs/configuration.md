# Configuration and environment

How runtime config works in every project built from this template. Binding rules: root `CLAUDE.md` → *Configuration* (plus each backend/frontend contract's security notes). This guide is the how-to.

## The model

1. **Environment variables are the only input.** No config files read at runtime, no per-machine special cases. Local development uses `.env` files (gitignored); deployed environments inject real env vars through the platform.
2. **One reading site per app.** Each app has exactly one config module that reads the environment, validates it against a declared schema, and exports typed values. Nothing else touches `process.env` (or the platform equivalent) — inner layers receive config as passed-in values.
3. **Fail fast, by name.** A missing or malformed variable stops startup with an error naming the variable — never a mid-request `undefined`.
4. **`.env.example` is the canon.** Every variable the app reads appears there with a comment saying what it does and an example or placeholder value. It updates **in the same change** that adds or removes a key — that's part of the Definition of Done.

## Adding a config key

1. Add it to the app's config schema (with type, and default only if a default is genuinely safe).
2. Thread it inward as a value from the composition root / config module.
3. Document it in `.env.example` with a comment.
4. Set it in your local `.env` and in each deployed environment before the code needing it ships.
5. Justify it in the PR (one line: the simpler option and why it was rejected) — config keys are abstraction surface too.

## Feature flags

A flag is a **boolean key in the validated config schema, default off**. That's the whole mechanism — no flag service or SDK unless a project explicitly adopts one and records it in Learnings. Flags are how incomplete work lands on an always-releasable trunk, and how risky integrations stay dark until enabled per environment.

**Integrations that spend money or reach real users** (SMS, email, payments, push, LLM calls) always ship behind a default-off flag routing to a no-op/stdout sink when off — flipping the flag back off is the instant rollback (backend contract → *Integrations*).

## Secrets

- Never committed, never hardcoded, never echoed in errors or logs. Local secrets live in gitignored `.env`; deployed secrets live in the platform's secret store / CI variables.
- The frontend bundle is public: anything secret stays server-side behind a backend endpoint. A `VITE_`/`NEXT_PUBLIC_`-style prefix is a declaration that a value is *not* secret.
- Secrets stored through the API are write-only on read (a "configured" indicator, never the value), and blank-on-update means "keep existing" (backend contract → *Security baseline*).
- Terraform: sensitive inputs are `sensitive = true`, injected at run time, never in committed `.tfvars` (`infra/CLAUDE.md`).

## Per-environment shape

| Environment | Source of values | Notes |
|---|---|---|
| local | `.env` (+ `apps/*/.env*`), copied into every new worktree | root contract → *Working in a git worktree* |
| CI | workflow env / repository secrets | scratch resources only; never production credentials |
| staging / production | platform env + secret store | set keys **before** deploying code that reads them — the app fails fast otherwise, by design |

The adopted stack pack binds the mechanics (schema library, config module location, platform env handling) in its appendices.
