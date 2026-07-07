# Add-on: seo

> Optional add-on. Opt in at Day-1 by keeping this directory (see `add-ons/README.md`). Agnostic approach; the active stack pack binds seam items S1–S7 below — or declares itself unbound in its manifest.

Search discoverability for the app's public pages — being crawled, indexed, and previewed correctly when shared. Structural work only: keyword strategy, paid search, rank tracking, and page-speed ranking factors are out of scope.

## Adoption fit

| Your surface | Do this |
|---|---|
| Public content is the product (marketing, listings, articles, profiles) | Adopt; classify routes from day 1 |
| Mostly private app with a small public shell | Adopt; classify every private route non-indexable |
| Fully login-walled — no indexable surface | Delete this add-on; a publicly reachable origin still serves a refuse-indexing response (R10's posture) |

## Approach

Every rule states behaviour observable from outside the running app; *Verify by observing* mirrors them one-to-one.

- **R1 — Classify every route.** Each route/URL space carries an indexable-or-not classification, recorded at the route registry (or the pack's registry equivalent). An unclassified route is a defect (gate G1).
- **R2 — No crawl traps.** Parameter, filter, and pagination variants of a page are non-indexable and canonical to their base page unless deliberately classified — a URL space never multiplies open-endedly.
- **R3 — Complete without scripts.** An indexable page's full content is present in the raw response, before any client-side script runs; the pack names the rendering mechanism (S1).
- **R4 — One canonical URL per page.** Variants (trailing slash, casing, host aliases, tracking params) permanently redirect to it; each indexable page declares its canonical absolutely; the canonical origin comes from validated config, never from the incoming request.
- **R5 — URLs are commitments.** Indexable slugs are stable; a rename keeps a permanent redirect from every previously published URL, so inbound links never die silently.
- **R6 — Honest status codes.** A missing entity answers not-found (or gone), never a success status wrapping an error screen; moved pages answer permanent redirects from the server, not a client-side bounce.
- **R7 — One metadata helper.** Unique title, description, share-preview tags **and share image** per indexable page, set through one shared helper only; the copy lives in the central copy home (base *Microcopy & content*).
- **R8 — Structured data mirrors the page.** Machine-readable entity markup only for entity types the product actually has, generated from the data the page shows; markup describing unshown content is cloaking.
- **R9 — Sitemap and robots are derived.** Generated from the route registry (plus entity data for parameterized routes), never hand-maintained; the sitemap lists exactly the indexable routes; robots disallows the non-indexable surface (gate G2).
- **R10 — Non-production never indexes.** Staging and preview origins answer a noindex directive, failing closed: only the configured production origin is ever indexable (gate G3).
- **R11 — No cloaking.** Crawlers see what users see; never branch content on the requester's user agent — the fix for an unindexable page is rendering.

## CI gates

In the spirit of the base i18n key-parity check, the adopting project's suite asserts from day 1:

- **G1** — no route/URL space is unclassified (R1).
- **G2** — the sitemap derives from the registry: regeneration produces no diff (R9).
- **G3** — every non-production environment configuration answers noindex (R10).

## Verify by observing

Correctness is observed, not inferred (base *Goal-driven execution*). Per rule, fetch and see:

- **R3/R4/R7** — fetch an indexable page raw → full content, unique title and description, one absolute canonical, share tags + image.
- **R2/R4** — fetch a variant URL → permanent redirect to, or canonical pointing at, the base page.
- **R5** — fetch a pre-rename URL → permanent redirect to the new slug.
- **R6** — fetch a nonexistent entity → not-found status.
- **R8** — entity markup content is a subset of the visible page content.
- **R9** — fetch the sitemap and robots → exactly the indexable set, nothing more.
- **R10** — fetch any non-production page → noindex present (and G3 asserts it in the suite).
- **R11** — fetch as a bot and as a browser → same content.

Once live, register the production origin with the search engines' index-coverage tooling and watch it — deindexing shows up there first.

## Binds to a stack

The active pack answers each seam item, keyed by id, one line each. A pack that cannot meet S1 declares itself **unbound** in its manifest instead — stating why, the workable alternative, and that R10's refuse-indexing posture still applies to any publicly reachable origin.

- **S1** — the rendering mechanism that makes indexable routes complete without client-side scripts (R3).
- **S2** — the metadata helper and its home: title/description/canonical/share tags + share image (R7).
- **S3** — the canonical-origin validated-config key home, and the server/edge permanent-redirect mechanism (R4/R5).
- **S4** — how sitemap and robots are generated from the route registry and served (R9).
- **S5** — how a missing entity becomes a real not-found status (R6).
- **S6** — the structured-data helper home (R8).
- **S7** — the locale-alternates home (multilingual projects only; an explicit "n/a" otherwise, never silence).

## Interactions

- **Base *URL routing*** — the route registry gains the classification (R1) and feeds sitemap/robots (R9); registry-built URLs keep canonicals consistent (R4).
- **Base *Configuration*** — the canonical origin (S3) is a validated config value.
- **Base *Internationalisation*** — locale alternates (S7) derive from the same locale set the dictionaries define.
- **Base *Microcopy & content*** — titles and descriptions (R7) live with the rest of the copy.
- **test-mode** — same fail-closed posture, different axis: test-mode stubs side effects per request; this add-on denies indexing per environment (R10).
