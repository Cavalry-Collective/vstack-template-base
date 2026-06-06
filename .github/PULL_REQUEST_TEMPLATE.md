## Summary

<!-- What changed and why. -->

Spec: specs/<file>
<!-- The spec this implements (specs/YYYY-MM-DD-<feature>.md) — or "N/A" with a one-line reason. -->

## Test plan

<!-- Commands you ran and the output you observed — not "tests pass", the actual evidence. -->

- [ ] lint / test / build pass locally (or note which check is not yet wired up, and why)
- [ ] every acceptance criterion in the linked spec/issue is demonstrated (evidence above)
- [ ] tests cover the changed behaviour, where the project has a test harness
- [ ] states exercised: happy path + the error/empty paths the change can hit

## Database (delete if no schema change)

- [ ] migration up → down → up round-trips cleanly on a scratch DB, or the irreversible change is justified in the spec

## UI checklist (if UI changed)

- [ ] all four data states verified (loading / error / empty / success) — see `apps/frontend/CLAUDE.md`
- [ ] keyboard-only pass done (reachable, visible focus, modals trap/restore)
- [ ] mockup linked and compared, or noted "no mockup" — see `design/README.md`
- [ ] all user-facing strings via i18n, keys added to every locale — see `apps/frontend/CLAUDE.md`
- [ ] before/after screenshots attached at the primary form factor (add the off-axis breakpoint if layout changed)

## Notes

<!-- Anything reviewers should know: deployment steps, feature flags, follow-ups. Incomplete work must be behind a flag. -->
