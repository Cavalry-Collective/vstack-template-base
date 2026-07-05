# Testing strategy

What we test, where, and with what kind of test. Binding rules: root `CLAUDE.md` → *Testing* and each area contract's *Testing* section. This is the assembled picture.

## Principles

- **Tests ship with the behaviour** — same change, same PR. A slice with no tests is not shippable.
- **Bug fixes start red.** Reproduce with a failing test, then fix.
- **Cheapest kind that proves it.** Unit (a rule in isolation) → integration (a use case across layers) → contract (an API or port boundary). Reach for the next tier only when the cheaper one can't prove the behaviour.
- **Assert behaviour, not implementation.** No mirroring internals, no mocking private methods, no broad markup snapshots. A good test survives a refactor; a bad one fails on it.

## Where coverage lives — backend

The onion makes testing cheap; exploit it. Most coverage sits in the fast inner rings, thinning outward:

| Ring | Kind | How |
|---|---|---|
| Domain | pure unit | no mocks, no I/O — the ring forbids both; assert invariants directly |
| Service | use-case | in-memory fakes of the ports; assert orchestration + transaction boundary |
| Repo | integration | real database / sandbox; assert mappers round-trip and queries behave |
| Controller | contract | status codes, validation rejection, auth guards, request/response schema |

A domain rule that can only be tested by standing up a database is in the wrong ring — fix the shape, not the test.

## Where coverage lives — frontend

| Layer | Kind | How |
|---|---|---|
| store slices, `lib/` | unit | plain functions in, assertions out |
| services | contract | network mocked **at the edge**; assert request shape + response/error mapping |
| organisms | behaviour | the four states (loading/error/empty/success) are the checklist for every data-backed section |
| screens | e2e (representative) | at the primary form factor **and** the minimum supported width — a suite pinned to one desktop width is how mobile regressions ship |

Snapshot the data a component receives if you must snapshot anything — never its rendered markup.

## Database and infra

- Every migration is proven before merge — up → down → up round-trip on a **scratch** database (or the adopted pack's bound equivalent, e.g. Prisma's apply-from-zero + drift gate). Evidence stated, not implied.
- Seeds are idempotent: running twice succeeds. CI asserts it.
- Infra has no test suite; its gate is the reviewed plan + risk checklist before apply, and observed outcomes after (`infra/CLAUDE.md`).

## CI is the enforcement point

`.github/workflows/ci.yml` runs the same verbs the Definition of Done names — lint, typecheck, test, build — plus the cross-cutting gates: i18n key parity, migration verification, accessibility scan. A failing check fails the build; `|| true` and warn-only checks are forbidden. Until the toolchain placeholders are filled, the gate is not delegated: the agent/human runs the checks and says so.

## What we deliberately don't do

- **No coverage-percentage targets.** Coverage follows from "tests ship with behaviour"; a number invites gaming.
- **No E2E-everything.** E2E is a thin representative layer over screens; logic coverage lives in the cheap inner tiers.
- **No test-mode branching in business logic.** If the app has a test mode (see `add-ons/test-mode/`), it stubs side effects at the boundary — the flow under test is the real flow.
