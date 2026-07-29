# Add-on: seo

> Optional add-on. Adopt at Day-1 by keeping this directory (see `add-ons/README.md`); the adopted stack pack supplies the seams named under *Binds to a stack*.

Search discoverability for the app's public pages — being crawled, indexed, and previewed correctly when shared — plus the structural work of keyword strategy, paid search, rank tracking, and page-speed ranking factors. The ongoing practice of each stays out of scope: keyword research and selection, campaign purchase and management, running or reading rank reports, hands-on performance tuning, and analytics/conversion measurement.

## Adoption

| Your surface | Do this |
|---|---|
| Public content is the product (marketing, listings, articles, profiles) | Adopt; classify routes from day 1 |
| Mostly private app with a small public shell | Adopt; classify every private route non-indexable |
| Fully login-walled — no indexable surface | Delete this add-on; a publicly reachable origin still serves a refuse-indexing response (R10's posture) |

## Approach

Every rule states behaviour observable from outside the running app; *Verify* mirrors them one-to-one.

### Routes and URLs
- **R1 — Classify every route.** Each route/URL space carries an indexable-or-not classification, recorded at the route registry (or the pack's registry equivalent). An unclassified route is a defect (gate G1).
- **R2 — No crawl traps.** Parameter, filter, and pagination variants of a page are non-indexable and canonical to their base page unless deliberately classified — a URL space never multiplies open-endedly.
- **R4 — One canonical URL per page.** Variants (trailing slash, casing, host aliases, tracking params) permanently redirect to it; each indexable page declares its canonical absolutely; the canonical origin comes from validated config, never from the incoming request.
- **R5 — URLs are commitments.** Indexable slugs are stable; a rename keeps a permanent redirect from every previously published URL, so inbound links never die silently.
- **R6 — Honest status codes.** A missing entity answers not-found (or gone), never a success status wrapping an error screen; moved pages answer permanent redirects from the server, not a client-side bounce.

### Rendering and metadata
- **R3 — Complete without scripts.** An indexable page's full content is present in the raw response, before any client-side script runs; the pack names the rendering mechanism (S1).
- **R7 — One metadata helper.** Unique title, description, share-preview tags **and share image** per indexable page, set through one shared helper only; the copy lives in the central copy home (base *Microcopy & content*).
- **R8 — Structured data mirrors the page.** Machine-readable entity markup only for entity types the product actually has, generated from the data the page shows; markup describing unshown content is cloaking.
- **R9 — Sitemap and robots are derived.** Generated from the route registry (plus entity data for parameterized routes), never hand-maintained; the sitemap lists exactly the indexable routes; robots disallows the non-indexable surface (gate G2).
- **R10 — Non-production never indexes.** Staging and preview origins answer a noindex directive, failing closed: only the configured production origin is ever indexable (gate G3).
- **R11 — No cloaking.** Crawlers see what users see; never branch content on the requester's user agent — the fix for an unindexable page is rendering.
- **R17 — Ownership verification is configuration.** Search-engine console ownership verification is served from validated config and survives redeploys — never a hand-placed artifact; absent config, absent response.

### Search intent and internal links
- **R12 — Every indexable page records its intent.** Each indexable route carries a target search intent — the query the page answers — recorded at the route registry beside its classification, one per locale; copy iteration updates the record in the same change. A missing record fails gate G4; a same-locale duplicate fails G5 — merge or re-target.
- **R13 — Pages are written against their recorded intent.** Title, description, slug, and the single top-level heading reflect the record; exactly one top-level heading per indexable page, heading levels descending without skipping.
- **R14 — No orphan pages.** Every indexable page is reachable through at least one crawlable link with descriptive anchor text from another indexable page — sitemap presence is not linkage.
- **R18 — The tracking inventory is derived.** The page↔intent inventory — each indexable URL paired with its recorded intent — is generated from the route registry, machine-readable, never hand-kept; renames keep tracking continuity through R5's permanent redirects.

### Paid landing pages
- **R15 — Ad parameters never fork the page.** Content is identical with arbitrary advertising click parameters appended; those parameters never appear in canonicals or the sitemap (R2/R4's variant discipline, applied to the ad case); dedicated landing URL spaces are classified like any route (R1).
- **R16 — Landing URLs answer directly.** An ad destination answers success with no redirect chain; a vanity alias is at most one permanent redirect.

### Loading experience
- **R19 — Meet the published loading-experience bar.** Indexable pages meet the search engines' currently published loading-experience thresholds — main-content loading, responsiveness to input, visual stability. The published values are the bar; this document freezes no numbers.
- **R20 — Rule out the structural causes of slowness.** Media and embeds reserve their space before arrival (no layout shift); primary content is never deferred behind client-side scripting or user interaction; each indexable route respects the project's declared payload budget (gate G6).

## Verify

In the spirit of the base i18n key-parity check, the adopting project's suite asserts from day 1:
- **G1** — no route/URL space is unclassified (R1).
- **G2** — the sitemap derives from the registry: regeneration produces no diff (R9).
- **G3** — every non-production environment configuration answers noindex (R10).
- **G4** — every indexable route has an intent record (R12).
- **G5** — no two same-locale indexable routes record the same intent (R12).
- **G6** — no indexable route exceeds the declared payload budget (R20).

Correctness is observed, not inferred (base *Goal-driven execution*). Per rule, fetch and see:
- **R3/R4/R7** — fetch an indexable page raw → full content, unique title and description, one absolute canonical, share tags + image.
- **R2/R4** — fetch a variant URL → permanent redirect to, or canonical pointing at, the base page.
- **R5/R6** — fetch a pre-rename URL → permanent redirect to the new slug; fetch a nonexistent entity → not-found status.
- **R8** — entity markup content is a subset of the visible page content.
- **R9** — fetch the sitemap and robots → exactly the indexable set, nothing more.
- **R10/R11** — fetch any non-production page → noindex present (G3 asserts it in the suite); fetch as a bot and as a browser → same content.
- **R12** — review the route registry → every indexable route carries one intent per locale (G4/G5 assert it in the suite).
- **R13** — fetch an indexable page raw → exactly one top-level heading, no skipped levels; title, slug, and heading match the recorded intent.
- **R14** — follow links from the indexable entry pages → every indexable page is reached; a sitemap-only page is an orphan.
- **R15/R16** — fetch a page with arbitrary ad click parameters → identical content, parameter-free canonical, no such variant in the sitemap; fetch an ad destination → direct success, its alias → one permanent hop.
- **R17/R18** — fetch the ownership-verification response, redeploy, fetch again → present both times; regenerate the inventory → exactly the indexable routes with their intents, no diff.
- **R19/R20** — measure a running indexable page on the three axes → meets the engines' published thresholds; no visible layout shift, and the primary content is already in the raw response (G6 asserts the budget in the suite).

Once live, register the production origin with the search engines' index-coverage tooling and watch it — deindexing shows up there first.

## Binds to a stack

The adopted pack answers each seam item, keyed by id, one line each — in [`bindings.md`](bindings.md) beside this file, read in place and kept. A pack that cannot meet S1 is recorded there as **unbound** instead — stating why, the workable alternative, and that R10's refuse-indexing posture still applies to any publicly reachable origin.

- **S1** — the rendering mechanism that makes indexable routes complete without client-side scripts (R3).
- **S2** — the metadata helper and its home: title/description/canonical/share tags + share image (R7).
- **S3** — the canonical-origin validated-config key home, and the server/edge permanent-redirect mechanism (R4/R5).
- **S4** — how sitemap and robots are generated from the route registry and served (R9).
- **S5** — how a missing entity becomes a real not-found status (R6).
- **S6** — the structured-data helper home (R8).
- **S7** — the locale-alternates home (multilingual projects only; an explicit "n/a" otherwise, never silence).
- **S8** — where the intent record lives on the pack's route-registry binding, and how the page↔intent inventory is derived and served from it (R12, R18).
- **S9** — how the ownership-verification response is served from the validated-config home (R17).
- **S10** — the payload-budget home and its suite assertion (G6), and the mechanism used to measure the three loading-experience axes on the running page (R19/R20).

## Interactions

- **Base *URL routing*** — the route registry gains the classification (R1) and feeds sitemap/robots (R9); registry-built URLs keep canonicals consistent (R4).
- **Base *Configuration*** — the canonical origin (S3) is a validated config value.
- **Base *Internationalisation*** — locale alternates (S7) derive from the same locale set the dictionaries define; per-locale intent uniqueness (R12/G5) rides the same set.
- **Base *Microcopy & content*** — titles and descriptions (R7) live with the rest of the copy.
- **Base *Interaction feedback & perceived performance*** — general performance stays owned by the base; this add-on owns only the indexable-page ranking-factor slice (R19/R20), duplicating nothing.
- **test-mode** — same fail-closed posture, different axis: test-mode stubs side effects per request; this add-on denies indexing per environment (R10).
