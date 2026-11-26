<One line: what the PR adds.>
- <One bullet per user-visible behaviour.>
- <Who can see it, and the feature flag that hides it.>

## Demo
### 1. <Flow name>
<video>

### 2. <Flow name>
<video>

## Tests
- <Each flow test extended or added, and why a new flow was needed.>

## Before release
- <Config values to set, and anything that must deploy first.>

## Spec
<The spec this implements, per `specs/README.md`, or "N/A".>

## Database (delete if no schema change)

- [ ] migration verified per `db/CLAUDE.md`'s merge gate — up → down → up on a scratch DB by default; if the active stack pack binds a different gate, that one (see its conflict register) — or the irreversible change is justified in the spec

## UI checklist (if UI changed)

- [ ] all four data states verified (loading / error / empty / success) — see `apps/frontend/CLAUDE.md`
- [ ] keyboard-only pass done (reachable, visible focus, modals trap/restore)
- [ ] new screen compared to its `design/` mockup (mockups are the **initial-build** reference only); existing-screen change built to convention — see `design/README.md`
- [ ] all user-facing strings via i18n (keys added to every locale) or the project's single strings/copy module — see `apps/frontend/CLAUDE.md`
- [ ] verified at the minimum supported width — no overflow / clipping / horizontal scroll, fixed chrome clears content — see `apps/frontend/CLAUDE.md` *Responsive layout*
- [ ] before/after screenshots attached at the primary form factor and the narrow width
