<!--
Bug fix: start with "Fixes [<TICKET>](<ticket link>): <what users saw, and where>." Keep "Cause".
Any other change: start with one sentence describing what the PR changes. Delete "Cause".
If there is no ticket, describe what users saw. Delete any section that does not apply.
-->

<One line: what the PR fixes or changes.>

## Cause
<Bug fix only. Why the bug occurred, in plain language.>

## Changes
- <One bullet per user-visible behaviour.>

## Evidence
<The command or call you ran and the output you observed, or a video or screenshot, for each behaviour.>

## Tests
- <Bug fix: how you reproduced the bug, and what happens on `main` compared with this PR.>
- <The flow test extended or added. If you added a new flow, explain why no existing flow fits.>
- <Anything not covered by automated tests, and why.>

## Before release
- <Config values to set, feature flags, and anything that must deploy first. "None" if there are none.>

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

## Additional notes
- <For example, refactoring, self-review findings you did not fix and why, or for each new abstraction, dependency or config key, the simpler option and why it was rejected.>
