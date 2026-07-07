# Quickstart: SEO Add-on — Structural Expansion

**Feature**: `004-seo-structural-expansion` · Validation guide — Part A runs in this repo; Part B documents the checks for instantiated projects. Definitions: [data-model.md](data-model.md); clause details: [contracts/](contracts/).

## Part A — template-level checks (runnable here, from repo root)

**A1 — Scope boundary rewritten** (FR-001, FR-015)

```bash
grep -n "keyword strategy" add-ons/seo/README.md
```

Expect: the capability statement names the four areas' **structural work in scope** and their **ongoing practice out**; the old sentence ending "…are out of scope" for the four areas is gone.

**A2 — Rules, gates, seams present, old IDs intact** (FR-002…FR-011, FR-013)

```bash
for id in R12 R13 R14 R15 R16 R17 R18 R19 R20 G4 G5 G6 S8 S9 S10; do
  grep -q "\*\*${id}\b" add-ons/seo/README.md && echo "ok  ${id}" || echo "MISSING ${id}"
done
for id in R1 R11 S1 S7 G1 G3; do grep -q "\*\*${id}\b" add-ons/seo/README.md || echo "REGRESSION ${id}"; done
```

Expect: 15 × `ok`, no `MISSING`, no `REGRESSION`.

**A3 — Verify-by-observing covers every new rule 1:1** (FR-012, SC-004)

Read the *Verify by observing* section: each of R12–R20 referenced exactly once (merged lines allowed; omissions not).

**A4 — Bound packs answer S8–S10** (FR-014, SC-005)

```bash
for pack in vercel vercel-ssr nextjs-nestjs-postgres; do
  for id in S8 S9 S10; do
    grep -q "\*\*${id}\b" "stacks/${pack}/frontend.md" && echo "ok  ${pack} ${id}" || echo "MISSING ${pack} ${id}"
  done
done
```

Expect: 9 × `ok`.

**A5 — Unbound pack declaration still accurate** (FR-014)

Read the unbound-declaration blockquote in `stacks/taro-fastify-mysql-tencent/README.md` against the expanded add-on: reason (S1 unmeetable), workable alternative, residual refuse-indexing posture — all still true (research D9). Extend only if wording no longer holds.

**A6 — Registry row tracks the expansion** (FR-015)

```bash
grep -n "seo" add-ons/README.md
```

Expect: the `seo/` row's capability wording reflects the new boundary and the pack-supplies cell spans **S1–S10**.

**A7 — No stale exclusion anywhere** (FR-015, SC-002)

```bash
grep -rn "keyword strategy, paid search, rank tracking" --include="*.md" . \
  | grep -v "specs/003-seo-addon" | grep -v "specs/004-seo-structural-expansion"
```

Expect: zero hits claiming the four areas are out of scope (historical spec records exempt).

**A8 — Size discipline** (FR-013, SC-003)

```bash
wc -l add-ons/seo/README.md
```

Expect: ≤ ~110 lines (hard ceiling well under 150 — clarification 3, research D8).

**A9 — Agnostic wording** (FR-013, SC-003)

Read the diff of `add-ons/seo/README.md`: no framework, SDK, vendor, cloud, or vendor-metric names (the three loading-experience axes described generically — research D5). Root `README.md` and `CLAUDE.md` add-on mentions still true (no edit expected).

## Part B — project-level checks (documented for instantiated apps)

Per [contracts/observable-behaviour.md](contracts/observable-behaviour.md): fetch/traverse/measure clauses **O11–O18** against the running app, and the suite carries standing assertions **G4–G6** from day 1 (intent record present; no same-locale duplicate intents; payload within budget). O12 (orphans) and O17 (thresholds) are observation-only by decision — never CI gates.

## Success-criteria traceability

| SC | Proven by |
|---|---|
| SC-001 | A1 + A6 (boundary readable at the choice points) + A8 (< 5-minute doc) |
| SC-002 | A7 |
| SC-003 | A2, A8, A9 (invariants review) |
| SC-004 | A3 + contract O11–O18 (every rule outside-observable) |
| SC-005 | A4 + A5 (4 of 4 packs unambiguous) |
| SC-006 | Part B: O11–O14, O15, O17, O18 |
| SC-007 | Part B: O15 + O16 (verification + derived inventory suffice; no hand-built lists) |
