## Summary

<!-- What changed and why. -->

Spec: specs/<feature-dir>
<!-- The spec this implements — or "N/A" with a one-line reason. See specs/README.md. -->

## Test plan

<!-- Commands you ran and the output you observed — not "tests pass", the actual evidence. -->

- [ ] lint / typecheck / test / build pass locally (or note which check is not yet wired up, and why)
- [ ] every acceptance criterion in the linked spec/issue is demonstrated (evidence above)
- [ ] tests cover the changed behaviour, where the project has a test harness
- [ ] states exercised: happy path + the error/empty paths the change can hit

## Database (delete if no schema change)

- [ ] migration verified per `db/CLAUDE.md`'s merge gate — up → down → up on a scratch DB by default; if the active stack pack binds a different gate, that one (see its conflict register) — or the irreversible change is justified in the spec

## UI checklist (if UI changed)

- [ ] all four data states verified (loading / error / empty / success) — see `apps/frontend/CLAUDE.md`
- [ ] keyboard-only pass done (reachable, visible focus, modals trap/restore)
- [ ] new screen compared to its `design/` mockup (mockups are the **initial-build** reference only); existing-screen change built to convention — see `design/README.md`
- [ ] all user-facing strings via i18n (keys added to every locale) or the project's single strings/copy module — see `apps/frontend/CLAUDE.md`
- [ ] verified at the minimum supported width — no overflow / clipping / horizontal scroll, fixed chrome clears content — see `apps/frontend/CLAUDE.md` *Responsive layout*
- [ ] before/after screenshots attached at the primary form factor and the narrow width

## Notes

<!-- Anything reviewers should know: deployment steps, feature flags, follow-ups. Incomplete work must be behind a flag. -->
