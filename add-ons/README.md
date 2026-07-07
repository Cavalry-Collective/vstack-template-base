# `add-ons/` — optional capability add-ons

An **add-on** is an optional, cross-cutting capability the base leaves out because not every project needs it — an agnostic pattern for a recurring feature (a **test mode**, **OTP login**, **LLM calls**). Opt into the ones you want at Day-1; delete the rest.

Sibling to `stacks/`, on a different axis:

- A **stack pack** binds the base to one technology stack. Exactly one is chosen.
- An **add-on** adds an optional capability, stated agnostically. Zero or more are chosen; the active stack pack then supplies the concrete bindings for each one you adopt.

This file is the system doc; each add-on carries its own `README.md`.

## What an add-on is

A directory `add-ons/<name>/` with a `README.md` of agnostic guidance. `<name>` is lowercase, hyphenated, capability-named (`test-mode`, `otp-auth`). Docs only — no dependencies, lockfiles, or scaffolding, consistent with `stacks/`.

## Opt in — adoption is keeping the directory

Keep the add-ons you want under `add-ons/`, delete the directories you don't. Opting out *is* deleting the directory; every directory still present is adopted. The Day-1 checklist (root `README.md`) is where a fresh project chooses.

Activation is by instruction: the root `CLAUDE.md` tells agents to read every kept add-on's `README.md` and follow it when touching the capability it covers. Add-ons are cross-cutting (backend + frontend + db at once), so the pointer lives in the always-loaded root file rather than a per-area one. The README under `add-ons/` is the single source of truth — edit it in place; there is no generated copy.

## Add-on invariants (valid iff all hold)

- **Agnostic.** States the approach without naming a framework, table, SDK, or cloud — those are the active pack's job. If a line only makes sense for one stack, it belongs in the pack.
- **States the approach concisely.** Direction and SOP for a capability that's easy to get wrong — how to do it, not the history of getting it wrong.
- **Names its stack seam.** A short "Binds to a stack" section says what the active pack must supply.
- **Names its interactions.** How it composes with base rules and other add-ons.
- **Size discipline.** Terse and checkable; well under ~150 lines.

## Current add-ons

| Add-on | Capability | Pack supplies |
|---|---|---|
| [`test-mode/`](test-mode/README.md) | Stub external side effects so the app runs end-to-end without real providers, plus a test-user picker | the mode signal, the sinks, the picker's gated read |
| [`otp-auth/`](otp-auth/README.md) | One-time-code login / contact verification over phone or email | the challenge store or provider, the SMS/email SDK, canonicalisation |
| [`llm-calls/`](llm-calls/README.md) | Guardrails for product features that call an LLM/AI API | the provider SDK and adapter home, the canned-response sink, the cost/usage monitoring home |
| [`premium-design/`](premium-design/README.md) | Art direction, a motion system, and a craft review gate that raise chosen screens from consistent to premium | the motion mechanism and primitives home, the font pipeline, the image/asset path |

## Add one

1. Create `add-ons/<name>/README.md` — the agnostic approach + its "binds to a stack" and "interactions" sections, per the invariants.
2. If it needs concrete bindings, add a short section to each active stack pack's appendices.
3. Wire it into the root `README.md` Day-1 "choose your add-ons" step — a kept directory is picked up by the root `CLAUDE.md` pointer automatically.
