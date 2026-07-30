# `add-ons/` — optional capability add-ons

An **add-on** is an optional, cross-cutting capability the base leaves out because not every project needs it — an agnostic pattern for a recurring feature (a **test mode**, **OTP login**, **LLM calls**). Opt into the ones you want at Day-1; delete the rest. This file is the system doc; each add-on carries its own `README.md`.

Sibling to `stacks/`, on a different axis: a **stack pack** binds the base to one technology stack, and exactly one is chosen; an **add-on** adds an optional capability, stated agnostically, and zero or more are chosen. An add-on is read into context like a crash course when its capability is planned or built; the concrete stack wiring is **derived at adoption** from the add-on's *Binds to a stack* seam list plus the active pack's appendices — nothing is pre-written per pack.

## What an add-on is

A directory `add-ons/<name>/` with a `README.md` of agnostic guidance — the capability's durable SOP. `<name>` is lowercase, hyphenated, capability-named (`test-mode`, `otp-auth`). Docs only — no dependencies, lockfiles, or scaffolding, consistent with `stacks/`. A larger add-on distills its capability into an **Implementation areas** section — per area, what must be covered and the opinionated way to do it — and states any **Prerequisites** (a stack capability or another add-on it cannot work without). Everything an add-on ships lives inside its directory, so keeping or deleting the directory carries the add-on's whole footprint. Add-ons carry no requirement specs and no per-pack bindings: the top-level `specs/` holds the project's actual requirement specs, written per area at implementation time against the add-on's coverage checklist, with the stack wiring derived from the seam list and the active pack's appendices.

## Opt in — adoption is keeping the directory

Keep the add-ons you want under `add-ons/`, delete the directories you don't. Opting out *is* deleting the directory; every directory still present is adopted. The Day-1 checklist (root `README.md`) is where a fresh project chooses.

Activation is by instruction: the root `CLAUDE.md` tells agents to read every kept add-on's `README.md` and follow it when touching the capability it covers. Add-ons are cross-cutting (backend + frontend + db at once), so the pointer lives in the always-loaded root file rather than a per-area one. The README under `add-ons/` is the single source of truth — edit it in place; there is no generated copy.

## Add-on invariants (valid iff all hold)

- **Agnostic.** States the approach without naming a framework, table, SDK, or cloud — those are the active pack's job. If a line only makes sense for one stack, it belongs in the pack.
- **States the approach concisely.** Direction and SOP for a capability that's easy to get wrong — how to do it, not the history of getting it wrong.
- **Names its stack seam.** A short "Binds to a stack" section says what the active pack must supply; the concrete answers are derived at adoption from that list and the active pack's appendices, and recorded in the implementing requirement spec.
- **Names its interactions.** How it composes with base rules and other add-ons.
- **Size discipline.** Terse and checkable; well under ~150 lines.

## Current add-ons

| Add-on | Capability | Pack supplies |
|---|---|---|
| [`test-mode/`](test-mode/README.md) | Stub external side effects so the app runs end-to-end without real providers, plus a test-user picker | the mode signal, the sinks, the picker's gated read |
| [`otp-auth/`](otp-auth/README.md) | One-time-code login / contact verification over phone or email | the challenge store or provider, the SMS/email SDK, canonicalisation |
| [`llm-calls/`](llm-calls/README.md) | Guardrails for product features that call an LLM/AI API | the provider SDK and adapter home, the canned-response sink, the cost/usage monitoring home |
| [`premium-design/`](premium-design/README.md) | Art direction, a motion system, and a craft review gate that raise chosen screens from consistent to premium | the motion mechanism and primitives home, the font pipeline, the image/asset path |
| [`enterprise-compliance/`](enterprise-compliance/README.md) | Enterprise controls for SOC 2 / ISO 27001 / GDPR / PDPA readiness: access control, audit, retention/deletion, recovery, governance | the IdP/SSO + MFA libraries, session store, KMS, append-only audit store, job runner, object storage, backup tooling, rate-limit store |
| [`multi-tenancy/`](multi-tenancy/README.md) | First-class tenancy: organisations sharing one deployment with strictly isolated data, members, files, and jobs | the tenant guard + request-context mechanism, the scoped query helper, database-level enforcement, the tenant-scoped storage layout |
| [`saas-billing/`](saas-billing/README.md) | Subscription billing as an architecture layer: data-defined plans, checkout, renewal, invoices, trials, entitlements, seat & usage enforcement, webhook sync | the payment provider + SDK/adapter home, the webhook raw-body/signature seam, the stub gateway, the job runner |
| [`seo/`](seo/README.md) | Structural search discoverability: canonical URLs, metadata, sitemaps, structured data, keyword targeting, page-speed budgets | rendering, metadata/canonical/sitemap mechanisms, structured-data home, budgets |

## Add one

1. Create `add-ons/<name>/README.md` — the agnostic approach plus its "binds to a stack" and "interactions" sections, per the invariants. A capability with several implementation areas adds an **Implementation areas** section: per area, the coverage checklist and the opinionated approach, stated as directives.
2. If it cannot work without a stack capability or another add-on, state that in a **Prerequisites** section — including which shipped packs qualify, when not all do.
3. Add a row to the **Current add-ons** table above — it is the registry an adopter chooses from at Day-1 (the root `README.md` step 6 points here; a kept directory is picked up by the root `CLAUDE.md` pointer automatically).
