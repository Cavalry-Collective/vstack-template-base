# Quickstart: Validating the SEO Add-on (redo)

**Feature**: `003-seo-addon` · Everything in Part A runs in this repo today; Part B documents the checks that only exist once a project is instantiated (see spec *Assumptions* for this split).

## Prerequisites

- This repo checked out; no toolchain needed (docs-only feature — `grep`, `wc`, `curl` only).
- The redo applied to the working tree (post-`/speckit-implement`).

## Part A — template-level validation (runnable here)

### A1. The add-on exists, is sized, and carries the enumerated structures

```bash
test -f add-ons/seo/README.md && echo OK
wc -l add-ons/seo/README.md                      # expect ≤ ~70 (hard ceiling ~150)
grep -c '^- \*\*R[0-9]' add-ons/seo/README.md    # expect 11 approach rules (R1–R11)
grep -o 'S[1-7]' add-ons/seo/README.md | sort -u # expect S1..S7
grep -c 'G[1-3]' add-ons/seo/README.md           # G1–G3 gates present
```

**Expected**: file present; within budget; R1–R11, S1–S7, G1–G3 all present. (Exact grep patterns may need adjusting to the final markup — the assertion is the IDs exist, not the regex.)

### A2. Agnosticism (no stack names in the add-on)

```bash
grep -inE 'next\.?js|react|vue|radix|tailwind|vercel|tencent|taro|fastify|nest|prisma|zod|node' add-ons/seo/README.md
```

**Expected**: no matches.

### A3. Every shipped pack takes exactly one stance (contract: stack-seam)

```bash
for p in stacks/*/; do echo "== $p"; grep -rl 'add-ons/seo' "$p" || echo "SILENT — FR-012 violation"; done
grep -o 'S[1-7]' stacks/vercel/frontend.md | sort -u                 # bound: S1..S7 (or S7 n/a stated)
grep -o 'S[1-7]' stacks/nextjs-nestjs-postgres/frontend.md | sort -u # bound: S1..S7
grep -i 'unbound' stacks/taro-fastify-mysql-tencent/README.md        # unbound-declared, with reason
```

**Expected**: no pack silent; both Next packs answer every seam id; Taro manifest declares unbound with reason + alternative + residual refuse-indexing posture.

### A4. All four adoption choice points enumerate the add-on

```bash
grep -n 'seo' add-ons/README.md | head -5        # registry table row
grep -n 'SEO\|`seo`' README.md                    # folder table + Day-1 step 6
grep -n 'SEO' CLAUDE.md                           # root repo map
```

**Expected**: a hit at each of the four locations (two are in root `README.md`).

### A5. Document-contract review (human, ~5 minutes)

Read `add-ons/seo/README.md` top to bottom against [contracts/add-on-document.md](contracts/add-on-document.md): section order, triage table present, every rule stated as an observable behaviour, interactions reference only base sections that exist (spot-check each named base heading against `apps/frontend/CLAUDE.md` / root `CLAUDE.md`).

### A6. Scope boundary stated and respected (FR-014 / SC-006)

```bash
head -6 add-ons/seo/README.md | grep -iE 'keyword strategy'   # boundary in the opening capability statement
head -6 add-ons/seo/README.md | grep -ioE 'keyword strategy|paid search|rank tracking|page-speed' | sort -u  # all four named
grep -inE 'keyword|paid search|rank track|page-speed|core web vitals' add-ons/seo/README.md
```

**Expected**: the opening capability statement names all four exclusions; the third grep's only hits are in that statement itself — no rule (R), gate (G), or seam item (S) addresses an excluded topic.

## Part B — instantiated-project validation (documented; runs in adopting apps)

These are the [observable-behaviour](contracts/observable-behaviour.md) clauses as commands. `$APP` = the app origin, `$STAGE` = a non-production origin.

```bash
# O1  Indexable page complete without JS, one canonical, share tags + image
curl -s "$APP/some-indexable-page" | grep -E '<title>|rel="canonical"|og:image'

# O2/O4  Variants and renamed slugs redirect permanently
curl -sI "$APP/Some-Indexable-Page/" | head -3          # expect 301/308 → canonical
curl -sI "$APP/old-slug" | head -3                       # expect 301/308 → new slug

# O5  Missing entity is a real 404
curl -s -o /dev/null -w '%{http_code}\n' "$APP/things/does-not-exist"   # expect 404

# O7/O8  Sitemap lists exactly the indexable set; robots covers the rest
curl -s "$APP/sitemap.xml"; curl -s "$APP/robots.txt"

# O9  Staging refuses indexing (fail-closed)
curl -sI "$STAGE/" | grep -i 'x-robots-tag'              # expect noindex
# ...and G3 asserts this in the project's suite, not just by hand.

# O10  No cloaking
diff <(curl -s "$APP/page") <(curl -s -A Googlebot "$APP/page")          # expect no content diff
```

**Expected**: every command matches its stated expectation; G1–G3 run red/green in the adopting project's CI.

## Success criteria traceability

| Spec criterion | Proven by |
|---|---|
| SC-001 (Day-1 decision from checklist) | A4 + A5 (triage table readable < 5 min) |
| SC-002 (100% invariants) | A1 + A2 + A5 |
| SC-003 (3/3 packs determinable) | A3 |
| SC-004 (all rules outside-observable) | A5 + Part B mapping (every R has an O/G) |
| SC-005 (app-level observables) | Part B |
| SC-006 (exclusions named up front; zero rules address them) | A6 |
