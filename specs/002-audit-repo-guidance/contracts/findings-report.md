# Contract: Findings Report Format

The P1 audit produces `specs/002-audit-repo-guidance/audit-report.md`. It is the gate artifact for every later slice, so its format is a contract: the maintainer must be able to approve, reject, and track every change from this one document.

## Required sections, in order

1. **Header** — audit date, commit audited, corpus word-count baseline, scanner tool + version used for the history scan.
2. **Executive summary** — one paragraph: overall health, count of findings by severity, whether the repo is currently release-ready.
3. **Release gate** — the four gate items (secrets, internal references, license, front door) each marked pass/fail with evidence.
4. **Findings** — every finding, ordered `release-blocking → high → medium → low`, using the Finding schema from [data-model.md](../data-model.md): id, location, issue, violated convention/principle, severity, remedy, destructive flag, disposition. Destructive findings carry an explicit **approval requested** marker.
5. **Instruction-discovery map** — every corpus file with its `audience` and `loading` classification (the written answer to the maintainer's README question, SC-002); files at risk of being missed are called out.
6. **File-by-file verdicts** — appendix listing 100% of in-scope files with `clean` or their finding ids (SC-001).
7. **Decisions requested** — the consolidated list the maintainer must rule on: disposition of historical spec directories and every destructive finding. (The license is already decided — MIT — and appears in the release gate, not here.)

## Rules

- A finding that names no violated convention or principle is invalid (FR-002).
- No file in scope may be absent from section 6 — coverage is checkable by diffing the file list against the corpus inventory.
- Dispositions are edited in place as the maintainer decides; the report stays the single source of truth through P2–P5.
