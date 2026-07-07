# seo — stack bindings

The shipped packs' answers to seam items S1–S10 (`README.md`, *Binds to a stack*), kept in this directory so the add-on's whole footprint lives here — keeping or deleting `add-ons/seo/` at Day-1 carries everything, and no stack appendix changes either way. At Day-1, keep the section for the adopted pack and delete the rest along with their packs. A pack with no section here is **silent** — a defect: add its bound section (one line per seam item, keyed by id) or record it unbound like the Taro section below.

## vercel — bound

Per seam item:

- **S1** rendering: indexable routes stay Server Components rendered complete on the server (this pack's default); static-generate where the data allows.
- **S2** metadata: the App Router Metadata API — `metadataBase` once in the root layout, `generateMetadata()` per indexable segment (title/description/canonical/Open Graph incl. the share image); no hand-written `<head>` tags.
- **S3** canonical origin + redirects: a validated env key (e.g. `NEXT_PUBLIC_CANONICAL_ORIGIN`, documented in `.env.example`) feeds `metadataBase`; permanent moves via `next.config` `redirects()` with `permanent: true`.
- **S4** sitemap/robots: `app/sitemap.*` + `app/robots.*`, enumerating indexable routes through the `routes` link-helper (this pack's registry binding); Vercel preview deployments already answer `X-Robots-Tag: noindex` — keep it, production is the only indexable origin, and a test still asserts the non-production noindex response (gate G3 — platform behaviour is not the gate).
- **S5** missing entity: `notFound()` + `not-found.tsx` → a real 404 response.
- **S6** structured data: one shared JSON-LD component fed by the page's own data.
- **S7** locale alternates: n/a until the project pins a locale mechanism; if it goes multilingual, derive alternates from the base i18n locale set.
- **S8** intent record + inventory: each indexable `routes` link-helper entry carries its target-intent phrase (per locale); a small route handler (e.g. `app/page-intents.json/route.ts`) serves the derived page↔intent pairs off the same registry as `app/sitemap.*` — generated, never hand-kept.
- **S9** ownership verification: a validated env key (e.g. `SEARCH_CONSOLE_VERIFICATION_TOKEN`, documented in `.env.example`) feeds the Metadata API `verification` field — absent key, absent tag.
- **S10** budget + measurement: a checked-in per-route payload budget asserted in CI against `next build` output (gate G6); the three loading-experience axes are the Core Web Vitals (LCP, INP, CLS) — Lighthouse for lab runs, Vercel Speed Insights for field data.

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

## nextjs-nestjs-postgres — bound

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

## taro-fastify-mysql-tencent — unbound

Unmeetable seam item: **S1** — the form factor is a phone-first, app-like H5/PWA client, and Taro H5's client-only rendering cannot serve indexable routes complete without client JS. Workable alternative: a project on this stack that grows a public crawlable surface serves it outside the Taro bundle (its own prerendered or server-rendered pages) and binds the add-on there. Residual posture: R10 survives unbinding — a publicly reachable H5 origin that shouldn't appear in search results still serves a refuse-indexing response (deny-all robots / noindex header) regardless.
