# Next.js (App Router) on Vercel — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **Next.js (App Router, TypeScript)**, deployed as a Vercel project, consuming the Fastify backend (`./backend.md`) over REST. Read the base file first; this only adds the bindings and the marked overrides.

## Stack binding at a glance

- **App Router under `src/app/`**, TypeScript. A file is a Server Component unless it opens `'use client'`; place the directive at the smallest interaction leaf — never on a page/layout "to be safe".
- **REST-only data flow — no Server Actions, no direct DB.** Every read and mutation goes through `services/` to the backend's `/internal/v1` API. Pack decision — rejected alternative: Server Actions / route-handler data access (the Fastify backend owns the domain; a second server-side mutation path would fork the contract and bypass its aspects).
- **Plain `fetch` through the services layer — no react-query/SWR by default.** Pack decision — rejected alternative: react-query (add it only when client-side cache invalidation genuinely appears; don't pre-install).
- **State: React Context providers under `src/store/`** — one provider per domain, seeded with server-fetched data passed down from Server Components (a deliberate divergence from the sibling `nextjs-nestjs-postgres` pack — see the conflict register). Pack decision — rejected alternative: an external store library (Redux/Zustand); context + props cover this architecture's client-state needs.

## The `/api` proxy (load-bearing)

- `next.config` `rewrites()` maps **`/api/:path*` → `${BACKEND_URL}/internal/v1/:path*`**. The browser only ever talks to the frontend origin — session cookies stay first-party and CORS never enters the picture.
- **Browser path:** one fetch wrapper `services/http.ts` calling relative `/api/...` paths; it maps the backend's error envelope to a typed `ApiError { code, status, message }` so failures feed the base error state and carry the correlation id.
- **Server path (RSC):** `services/server-api.ts` calls `BACKEND_URL` directly (relative URLs don't resolve server-side) and **forwards the incoming request's cookies**.
- Both paths live in `services/` — the base "all network access lives here" rule, bound. A `fetch` inlined in a component is the greppable smell.
- `BACKEND_URL` is read at build time (the rewrite destination) *and* at runtime (RSC fetches) — it must be present in both contexts.

## Folder mapping (base `src/` shape → App Router)

| Base layer | Here |
|---|---|
| `pages/` | `src/app/` route segments (`page`, `layout`, `loading`, `error`, `not-found`); "pages hold no business logic" applies to `page.tsx` |
| `store/` | `src/store/` — React Context providers + hooks |
| `services/` | `src/services/` — `http.ts` (browser), `server-api.ts` (RSC), one module per backend route group |
| `components/atoms/`, `components/molecules/`, `components/organisms/<feature>/`, `components/templates/` | unchanged (atomic tiers per the base *Component structure*) |
| `lib/`, `i18n/` | unchanged |
| `routes.<ext>` | the `app/` tree + a `routes` link-helper module (see *Routing*) |
| `tokens.<ext>` | CSS variables declared via Tailwind 4 `@theme` in the global stylesheet (see *Styling*) |

## Routing

The `app/` tree replaces the central `routes.<ext>` registry; the surviving base intent is rename-safe links. Build every parameterized href through a `routes` link-helper module (`src/lib/routes.ts`) — never a hand-concatenated URL string; static routes may use literal hrefs. `<Link href>` is the default navigation primitive; `useRouter().push`/`redirect()` for programmatic cases.

## Four data states → App Router files

Binding only — the base owns the why. **Loading** → `loading.tsx` / `<Suspense>` with shared skeletons. **Error** → `error.tsx` (must be a Client Component), wiring `reset()` into the shared `<ErrorState>` and surfacing the correlation id from the failed call; root-layout failures need `global-error.tsx`. **Empty** → the shared `<EmptyState>` primitive. **Missing resource** → `not-found.tsx` + `notFound()`. Segment files stay thin and delegate to the shared `atoms/`/`molecules/` primitives.

## Styling & primitives

- **Tailwind CSS 4** (CSS-first config): design tokens are CSS variables declared in `@theme` in the global stylesheet — that declaration **is** the base's single token source; components consume semantic tokens through Tailwind utilities.
- **Foundation: Radix UI primitives**, wrapped as **atoms** in `components/atoms/` (base *Component structure* unchanged). Atom/molecule variants via `class-variance-authority`; class composition via `clsx` + `tailwind-merge` (one `cn()` helper in `lib/`). Icons: `lucide-react`. Fonts via `next/font`.
- Don't import a prebuilt styled component kit on top — compose Radix + tokens in `components/atoms/`/`molecules/`. Swapping the headless library is allowed only by recording the choice in `apps/frontend/CLAUDE.md`; don't mix two.

## Responsive layout (Tailwind v4)

Binds the base *Responsive layout* rules to Tailwind v4 — the base owns the *why*, here is the idiom for each.

- **Mobile-first, stepped utilities.** Base classes target the narrowest width; scale up with `sm:`/`md:`/`lg:`. The default breakpoints are usually enough — don't add custom `@theme` breakpoints without a real reason.
- **Prefer intrinsic sizing over breakpoints.** Reach for fluid type/space (`clamp()`, or a fluid step in the `@theme` scale) and self-wrapping layout (`grid-cols-[repeat(auto-fit,minmax(…,1fr))]`, `flex-wrap`) before adding a breakpoint — they adapt continuously, so fewer breakpoints and less per-screen tuning.
- **Component responsiveness uses container queries.** A primitive that must adapt to the space it occupies uses Tailwind v4's built-in `@container` + `@sm:`/`@md:` variants (not viewport `sm:`/`md:`), so the same component works in a wide main *and* a narrow sidebar. Keep viewport breakpoints for page-level layout.
- **CSS-first, no `tailwind.config`.** Breakpoints and tokens are the `@theme` declaration in the global stylesheet — the single token source the base names. Header clearance and screen gutter are semantic tokens (`--header-clearance`, `--gutter-screen`), not magic numbers per page.
- **One layout primitive owns the gutter.** Wrap the recurring `container mx-auto px-4 lg:px-8` idiom once as a `<Container>` / `<Section>` atom (driven by `--gutter-screen`), with inner `max-w-*` reading columns. Hand-composing that string per page is the greppable smell — it drifts.
- **Full-bleed hero: content-driven height.** `min-h-[Xrem]` + responsive `py-*`. **Never** `h-screen` / `100vh` (ignores mobile browser UI) and **never** `aspect-[…]` on a flex child (sizes inconsistently across engines). Where an element must truly fill the viewport (a mobile sheet), use `min-h-[100svh]` (the *small* unit, stable) — not `vh`, and `dvh` only to deliberately track the URL bar. Clearance comes from the shared layout token (`pt-[…]` bound to `--header-clearance`); top-anchor the copy so its position doesn't depend on (admin-editable) headline height.
- **Atomic values don't wrap.** The shared inline-value / link atom applies `whitespace-nowrap` to `tel:`/`mailto:` values and `font-mono` codes; a long unbreakable string (a raw URL) uses `overflow-wrap`. Free-text table cells use `truncate max-w-*` inside a `min-w-0` parent; wrap wide tables/code in an `overflow-x-auto` box so the page never scrolls sideways.
- **`text-balance` is the heading default** — set it in the shared heading atom, don't retrofit per screen.
- **`<DataTable>` primitive.** `overflow-x-auto` wrapper + `whitespace-nowrap` columns (opt-in `truncate max-w-*` for free text) + **windowed pagination (≤ ~7 slots: first, last, current ± 1, ellipsis)** so a large page count can't widen the layout.
- **Modal sizing is fixed once.** Keep the Radix/shadcn dialog baseline `w-full max-w-[calc(100%-2rem)] sm:max-w-lg` — full-width-minus-gutter on phones, capped above `sm`; don't re-solve dialog sizing per feature.
- **Images: `next/image` `fill` + explicit `sizes` + an `aspect-[…]` wrapper.** Art-direct across breakpoints with `object-position` / `object-cover` rather than shipping crops — unless a crop genuinely must differ, which is what `<picture>` / `media` is for. Use `unoptimized` only for `data:` URLs and the logo.

## Versioning / build identity

Inline the version at build time — `next.config` sets `env.NEXT_PUBLIC_APP_VERSION` from `npm_package_version` — and render the unobtrusive `v<version>` tag from it. Vercel + App Router handle deployment skew (deployment ids, asset versioning, RSC re-fetch on navigation) — see the conflict register; no `version.json` poll.

## Analytics & Speed Insights

Wire Vercel's product analytics in from day 1 — both are drop-in for the App Router and stream to the project dashboard:

- **Web Analytics** — add `@vercel/analytics` and render `<Analytics />` in the root layout (`app/layout.tsx`).
- **Speed Insights** — add `@vercel/speed-insights` and render `<SpeedInsights />` in the root layout, for real-user Core Web Vitals.

Enable Web Analytics + Speed Insights on the **frontend** project in the Vercel dashboard (the API serves only JSON — the browser scripts are a no-op there). This is the frontend half of the observability story whose backend/log-drain half lives in `infra.md`.

## Security headers (binding)

The base *Security baseline* (`apps/frontend/CLAUDE.md`) is bound here to **`next.config` `async headers()`**: emit `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, and a **`Content-Security-Policy-Report-Only`** to start. Allow-list the origins this app actually loads — the Vercel Analytics / Speed Insights endpoints and any payment drop-in or embed — then promote the report-only header to the enforcing `Content-Security-Policy` once violation reports are clean.

## Testing — typecheck + build + Playwright e2e

- The frontend suite is `tsc --noEmit`, `next build`, and **Playwright** specs under `apps/frontend/e2e/` exercising the real app — every screen's four states and primary flows. `E2E_BASE_URL` selects the target: the local dev stack or a deployed preview.
- **Run the specs at a narrow viewport as well as desktop** (base *Testing* rule). Define a second Playwright project on a mobile device — `{ name: 'mobile', use: { ...devices['Pixel 7'] } }` beside the desktop project — so the four-state specs also run at phone width; a suite pinned to one desktop viewport ships mobile-layout regressions. Add mobile-only assertions (nav collapses, no horizontal scroll) where a screen's layout genuinely diverges.
- See the conflict register for what this replaces. The moment a store slice or service accrues branching logic worth isolating, add a unit runner for that code — don't scaffold one speculatively.

## Add-on bindings (if adopted)

- **seo** (`add-ons/seo/`) — bound, per seam item:
  - **S1** rendering: indexable routes stay Server Components rendered complete on the server (this pack's default); static-generate where the data allows.
  - **S2** metadata: the App Router Metadata API — `metadataBase` once in the root layout, `generateMetadata()` per indexable segment (title/description/canonical/Open Graph incl. the share image); no hand-written `<head>` tags.
  - **S3** canonical origin + redirects: a validated env key (e.g. `NEXT_PUBLIC_CANONICAL_ORIGIN`, documented in `.env.example`) feeds `metadataBase`; permanent moves via `next.config` `redirects()` with `permanent: true`.
  - **S4** sitemap/robots: `app/sitemap.*` + `app/robots.*`, enumerating indexable routes through the `routes` link-helper (this pack's registry binding); Vercel preview deployments already answer `X-Robots-Tag: noindex` — keep it, production is the only indexable origin.
  - **S5** missing entity: `notFound()` + `not-found.tsx` → a real 404 response.
  - **S6** structured data: one shared JSON-LD component fed by the page's own data.
  - **S7** locale alternates: n/a until the project pins a locale mechanism; if it goes multilingual, derive alternates from the base i18n locale set.
- **premium-design** (`add-ons/premium-design/`): motion primitives are atoms/molecules driven by `@theme` duration/easing tokens — CSS transitions/keyframes by default; reach for the **`motion`** library only at a `'use client'` interaction leaf when a sequence outgrows CSS, recording the choice per the base dependency rule. Scroll reveals go through one shared IntersectionObserver hook in `lib/` (client leaf). Fonts stay on `next/font`, imagery on `next/image` (see *Responsive layout*). Honour `prefers-reduced-motion` by collapsing the duration tokens under the media query, and watch Speed Insights for motion-caused Web Vitals regressions.

## Conflict register

- **Base says:** `apps/frontend` is "the single-page app" (also root `CLAUDE.md` and `README.md`). **In this stack:** it is server-first Next.js App Router on Vercel, not a client-rendered SPA. **Because:** the chosen stack. **Concretely:** default every component to server; add `'use client'` only at interaction leaves. (Soften the root-file SPA framing on day 1 per the root README; the repo name stays stale.)
- **Base says:** every route lives in one central registry `routes.<ext>`, and URLs are built through it. **In this stack:** the `app/` tree *is* the registry; a `routes` link-helper replaces hand-built URLs, so `routes.<ext>` is dropped. **Because:** App Router is filesystem-routed. **Concretely:** resolve parameterized links through the helper — never concatenate path strings; don't recreate a route→URL table (the base already forbids a second one).
- **Base says:** the client `store/` "owns application state" and may front service data (and the sibling `nextjs-nestjs-postgres` pack forbids copying server data into client state). **In this stack:** a `store/` context provider may be seeded with server-fetched data passed down from a Server Component, and owns it on the client from then on — refreshed after a mutation via `router.refresh()` or a service refetch through the same provider. **Because:** with REST-only data flow (no Server Actions, no client cache library), an interactive subtree that shares and mutates server data needs exactly one client-side carrier, and the seeded provider is it; the per-request server render alone can't hold state the subtree mutates. **Concretely:** seed a provider only for data an interactive subtree actually shares or mutates — purely-display data stays props; DON'T reflexively mirror every fetch into a provider.
- **Base says:** a deployed SPA is cached, so detect a stale bundle (poll a build-stamped `version.json` / react to a new service worker) and prompt to refresh. **In this stack:** Vercel's deployment skew protection plus App Router asset versioning and RSC re-fetch handle stale clients. **Because:** the platform solves what the base rule hand-rolls. **Concretely:** ship only the visible `v<version>` tag (from `NEXT_PUBLIC_APP_VERSION`); DON'T build a `version.json` poll.
- **Base says:** test store slices and `lib/` helpers as plain units, and services with the network mocked at the edge. **In this stack:** the default frontend suite is typecheck + build + Playwright e2e covering the four-state contract; per-unit suites are added on demand, not scaffolded. **Because:** this architecture keeps business logic behind the REST API, so frontend units would mostly re-test glue — e2e against the real contract catches what matters, and this was validated in production use of the stack. **Concretely:** DO cover every new screen's states in an e2e spec in the same change; DON'T add a unit runner until a slice/service holds real branching logic — then test that unit per the base rules.
- **Base says:** product analytics stay vendor-agnostic — emitted through one shared service/hook, with no pinned analytics SDK. **In this stack:** `@vercel/analytics` and `@vercel/speed-insights` are pinned and rendered in the root layout (see *Analytics & Speed Insights*). **Because:** they are platform page/performance telemetry that ships with the Vercel deployment — not the product-event taxonomy; if the project adds product events, those still flow through a shared service with by-meaning names per the base rule. **Concretely:** DO keep `<Analytics />`/`<SpeedInsights />` in `app/layout.tsx`; DON'T scatter product-event calls through components — those still need the shared hook.
