# seo — stack bindings

The shipped packs' answers to seam items S1–S10 (`README.md`, *Binds to a stack*), kept in this directory so the add-on's whole footprint lives here — keeping or deleting `add-ons/seo/` at Day-1 carries everything, and no stack appendix changes either way. At Day-1, keep the section for the adopted pack and delete the rest along with their packs. A pack with no section here is **silent** — a defect: add its bound section (one line per seam item, keyed by id) or record it unbound like the Taro section below.

## vercel-csr — unbound

Unmeetable seam item: **S1** — that pack is a **client-rendered SPA with no SSR by deliberate design** (`stacks/vercel-csr/frontend.md` → *Rendering model*). Every route is served as the same static `index.html` and painted by JavaScript, so there is no mechanism that makes an indexable route complete without client-side scripts, and nothing to hang S2–S9 off either: no server render to emit per-route `<head>` tags, no server response to carry a 301 or a real 404 status. Adding one is a pack change, not a patch — do not reach for a prerender/SSG plugin to close this gap; that is precisely what the pack's forbidden list rules out.

Workable alternative: adopt the sibling **`vercel-ssr`** pack, whose bound section is directly below — it is the same platform and the same database, and it exists for this requirement. A project that must keep the SPA serves its crawlable surface **outside** the app bundle (its own server-rendered origin — a marketing site, a docs site) and binds the add-on there.

Residual posture: **R10 survives unbinding** — the SPA origin is publicly reachable, so it still serves a refuse-indexing response. Bind that much: a static `public/robots.txt` disallowing all, plus `X-Robots-Tag: noindex` from the `vercel.json` `headers` block on every non-production deployment, and a Playwright assertion on the non-production response (gate G3). Vercel previews already answer `noindex` — assert it anyway; platform behaviour is not the gate.

## vercel-ssr — bound

Full-stack Next.js is this add-on's best case: an indexable route is complete without client JS **by construction** — Server Components render the full HTML — provided its content never moves into a `'use client'` leaf. Per seam item:

- **S1** rendering: Server Components render indexable routes complete on the server (by construction, above); static-generate where the data allows.
- **S2** metadata: one shared helper (`src/lib/seo.ts`) called from each indexable page's `generateMetadata()` — unique title/description, share-preview (Open Graph) tags incl. the share image, and the canonical as an absolute URL built from `metadataBase`; copy lives in the i18n dictionaries / strings module per the base rule.
- **S3** canonical origin + redirects: `metadataBase` comes from the validated canonical-origin config key, never the incoming request; host aliases, trailing slash, and moved pages are `next.config` `redirects()` entries with `permanent: true` — server-issued, never a client-side bounce.
- **S4** sitemap/robots: `app/sitemap.ts` + `app/robots.ts`, generated from the routes module's indexable entries (plus entity data for parameterized routes) — never a hand-kept URL list; the classification lives on each `routes` link-helper entry as an indexable flag, keeping the registry the single audit surface. Non-production is never indexable, fail closed: `app/robots.ts` answers disallow-all unless the deployed environment is production (`VERCEL_ENV === 'production'` — environment config, not request inference), and a test asserts the non-production branch (gate G3).
- **S5** missing entity: `notFound()` → a real 404 status via `not-found.tsx`, not a 200 error UI.
- **S6** structured data: one shared JSON-LD component fed by the page's own data.
- **S7** locale alternates: a multilingual page declares `alternates.languages` (hreflang) from the same locale set the dictionaries define.
- **S8** intent record + inventory: each indexable entry in the routes module carries its target-intent phrase (per locale); a route handler (e.g. `app/page-intents.json/route.ts`) serves the derived page↔intent pairs the same way `app/sitemap.ts` derives the sitemap — generated, never hand-kept.
- **S9** ownership verification: a validated env key (e.g. `SEARCH_CONSOLE_VERIFICATION_TOKEN`) feeds the root layout's Metadata API `verification` field — absent key, absent tag.
- **S10** budget + measurement: a checked-in per-route payload budget asserted in CI against `next build` output (gate G6); the three loading-experience axes are the Core Web Vitals (LCP, INP, CLS) — Lighthouse for lab runs, Vercel Speed Insights for field data (already allow-listed in that pack's Content-Security-Policy baseline).

## enterprise — bound

Per seam item:

- **S1** rendering: indexable routes are Server Components rendering complete HTML (this pack's default), fetching through `services/server/`; static-generate where the data allows.
- **S2** metadata: the App Router Metadata API — `metadataBase` once in the root layout, `generateMetadata()` per indexable segment (title/description/canonical/Open Graph incl. the share image); copy from the locale dictionaries; no hand-written `<head>` tags.
- **S3** canonical origin + redirects: a validated env key (e.g. `NEXT_PUBLIC_CANONICAL_ORIGIN`, documented in `.env.example`) feeds `metadataBase`; permanent moves via `next.config` `redirects()` with `permanent: true`.
- **S4** sitemap/robots: `app/sitemap.*` + `app/robots.*` off the `routes` link-helper; non-production answers noindex keyed on validated config (`robots.*` disallow-all unless production) — fail closed, asserted by a test (gate G3).
- **S5** missing entity: `notFound()` → a real 404 response.
- **S6** structured data: one shared JSON-LD component fed by the page's own data.
- **S7** locale alternates: `app/[locale]/` segments declare hreflang `alternates` from the same locale set the i18n parity check asserts.
- **S8** intent record + inventory: each indexable `routes` link-helper entry carries its target-intent phrase (per locale); a route handler (e.g. `app/page-intents.json/route.ts`) serves the derived page↔intent pairs off the same registry as `app/sitemap.*` — generated, never hand-kept.
- **S9** ownership verification: a validated env key (e.g. `SEARCH_CONSOLE_VERIFICATION_TOKEN`, documented in `.env.example`) feeds the Metadata API `verification` field — absent key, absent tag.
- **S10** budget + measurement: a checked-in per-route payload budget asserted in CI against `next build` output (gate G6); the three loading-experience axes are the Core Web Vitals (LCP, INP, CLS), measured with Lighthouse against the running app (R19's observation check).

## wechat — unbound

Unmeetable seam item: **S1** — the form factor is a phone-first, app-like H5/PWA client, and Taro H5's client-only rendering cannot serve indexable routes complete without client JS. Workable alternative: a project on this stack that grows a public crawlable surface serves it outside the Taro bundle (its own prerendered or server-rendered pages) and binds the add-on there. Residual posture: R10 survives unbinding — a publicly reachable H5 origin that shouldn't appear in search results still serves a refuse-indexing response (deny-all robots / noindex header) regardless.

## mern — unbound

Unmeetable seam item: **S1** — that pack is a **client-rendered SPA with no SSR by deliberate design** (`stacks/mern/frontend.md` → *Rendering model*). Every route is served as the same static `index.html` and painted by JavaScript, so there is no mechanism that makes an indexable route complete without client-side scripts, and nothing to hang S2–S9 off either: no server render to emit per-route `<head>` tags, no server response to carry a 301 or a real 404 status. Adding one is a pack change, not a patch — do not reach for a prerender/SSG plugin to close this gap; that is precisely what the pack's forbidden list rules out.

Workable alternative: this pack has no same-stack SSR sibling — adopt a server-rendered pack instead (**`vercel-ssr`** or **`enterprise`**, both bound above), or keep the SPA and serve the crawlable surface **outside** the app bundle (its own server-rendered origin — a marketing site, a docs site) and bind the add-on there.

Residual posture: **R10 survives unbinding** — the SPA origin is publicly reachable, so it still serves a refuse-indexing response. Bind that much: a static `public/robots.txt` disallowing all, plus `X-Robots-Tag: noindex` from the serving layer's headers on every non-production environment (the pack's deploy seam — `stacks/mern/frontend.md` → *Serving `dist/`*, requirement 3's header home), and a Playwright assertion on the non-production response (gate G3). No platform answers noindex for this pack by default — the serving layer must, and the suite assertion, not platform behaviour, is the gate.

## django — unbound

Unmeetable seam item: **S1** — that pack's frontend is a **client-rendered SPA with no SSR by deliberate design** (`stacks/django/frontend.md` → *Rendering model*). Every route is served as the same static `index.html` and painted by JavaScript — Django serves only the JSON API — so there is no mechanism that makes an indexable route complete without client-side scripts, and nothing to hang S2–S9 off either: no server render to emit per-route `<head>` tags, no server response on app routes to carry a 301 or a real 404 status. Adding one is a pack change, not a patch — do not reach for a prerender/SSG plugin to close this gap; that is precisely what the pack's forbidden list rules out.

Workable alternative: adopt a server-rendered pack (**`vercel-ssr`** or **`enterprise`**, both bound above) — or serve the crawlable surface **outside** the SPA bundle. On this stack that second path is unusually cheap: Django itself can host server-rendered template pages (a marketing/docs surface) on their own public URLs beside the API, and the add-on binds to *those* pages — but that is a separate, deliberate adoption with its own seam answers, not a default this pack supplies.

Residual posture: **R10 survives unbinding** — the SPA origin is publicly reachable, so it still serves a refuse-indexing response. Bind that much: a `robots.txt` disallowing all, plus `X-Robots-Tag: noindex` on every non-production response, emitted from the serving layer (Django middleware where Django serves the files, otherwise the reverse proxy the infra contract stands up), keyed on validated environment config — never request inference — with a test asserting the non-production response (gate G3).
