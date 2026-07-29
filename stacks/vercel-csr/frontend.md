# React SPA (Vite) on Vercel — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **React 19 + TypeScript, built by Vite into static assets**, served from Vercel's CDN and consuming the Fastify backend (`./backend.md`) over REST. Read the base file first; this only adds the bindings and the marked overrides.

## Scope

This file owns the client-only rendering model, routing, data flow, styling and responsive idioms, versioning, analytics, headers, and frontend testing. The API is `./backend.md`; provisioning and deploys are `./infra.md`.

## Stack binding at a glance

- **Vite 7 + React 19 + TypeScript**, sources under `src/` in the base's shape (see *Folder mapping*). `@vitejs/plugin-react`.
- **REST-only data flow.** Every read and mutation goes through `services/` to the backend's `/internal/v1` API (rejected: any client-side direct-DB or BFF layer — the Fastify backend owns the domain and its aspects).
- **Plain `fetch` through the services layer** (rejected: react-query/SWR — add a client cache library only when client-side cache invalidation genuinely appears; don't pre-install).
- **State: React Context providers under `src/store/`** — one provider per domain, holding client state and service results (rejected: an external store library, Redux/Zustand — context + props cover this architecture's needs).
- **Config: only `VITE_`-prefixed vars reach the bundle**, read once through one typed `src/lib/env.ts` parsed by Zod at module load — binds the base *Configuration* fail-fast rule. Everything in the bundle is **public**; a secret in a `VITE_` var is the base *No secrets in the bundle* violation.

## Rendering model — client-only, no SSR

This pack is a single-page app: there is no server-side rendering, and adding any is a defect, not an improvement. The base contract's SPA framing (`apps/frontend/CLAUDE.md`, root `CLAUDE.md`, root `README.md`) applies **verbatim** — do **not** soften it on Day 1 (`../README.md` → *Day-1 wiring*).

- **`vite build` emits `dist/`: one `index.html` shell plus hashed JS/CSS.** Every route returns that same shell; React renders the page in the browser. Vercel serves it as static files — the web project runs **no** function, at request time or at build time.
- **No render-to-HTML step anywhere** — not per request (SSR), not at build (SSG/prerender). HTML is authored once, by hand, in `index.html`.
- **Entry is `createRoot(...).render(...)` in `src/main.tsx`** — never `hydrateRoot`, which exists only to attach to server-rendered markup.
- **Routing is React Router in library mode** — `createBrowserRouter` + `<RouterProvider>` fed by the central registry (see *Routing*). If the project ever moves to React Router **framework mode**, `react-router.config.ts` **must** set `ssr: false`; framework mode defaults to SSR on.

**Forbidden — each one is greppable, and any hit is a violation:**

| Grep for | Why it's a violation |
|---|---|
| `next`, `next/*` in `apps/frontend/package.json` | Next.js brings a server runtime this pack must not have |
| `'use client'` / `'use server'` | React Server Component directives — there is no server component tree here |
| `renderToString`, `renderToPipeableStream`, `renderToReadableStream`, `hydrateRoot` | server rendering / hydration |
| `vike`, `vite-plugin-ssr`, any prerender/SSG plugin | build-time HTML generation |
| `*.server.ts(x)`, an `api/` directory under `apps/frontend/` | a server tier on the web project |

A requirement that genuinely needs server-rendered HTML (public search indexability above all) is a pack change, not a patch — see `../README.md` → *Defining constraint* and `add-ons/seo/bindings.md`, where this pack is recorded **unbound** for exactly that reason.

## Folder mapping (base `src/` shape)

The base shape holds **as written** — `store/`, `services/`, `pages/`, `components/{atoms,molecules,organisms/<feature>,templates}`, `i18n/`, `lib/`. Two file bindings only:

| Base file | Here |
|---|---|
| `routes.<ext>` | `src/routes.tsx` — the React Router route objects **and** the link helpers, one module (see *Routing*) |
| `tokens.<ext>` | CSS variables declared via Tailwind 4 `@theme` in the global stylesheet (see *Styling*) |

## Routing

`src/routes.tsx` is the base's single central registry, bound: the `createBrowserRouter` route array plus a typed link-helper per parameterized route. `<Link to>` is the default navigation primitive; `useNavigate()` for programmatic cases. Never hand-concatenate a path string — resolve it through the helper. **Code-split at the route and nowhere else**: each entry loads its page through the route object's own `lazy` field, so one chunk maps to one screen. Don't scatter `React.lazy` below the route — it fragments the bundle without shortening the critical path.

## `vercel.json` — the SPA fallback and the `/api` proxy

`apps/frontend/vercel.json` carries two rewrites, and **order matters** — the `/api` rule must precede the catch-all or the proxy is swallowed by it:

1. **`/api/:path*` → `<api-origin>/internal/v1/:path*`.** The browser only ever talks to the web origin, so session cookies stay first-party and CORS never enters the picture.
2. **Catch-all → `/index.html`.** Without it, a deep link or a refresh on any route but `/` returns the CDN's 404 — the canonical SPA-on-a-CDN bug.

- The API origin is a literal hostname per environment, selected by a **host condition** (`has: [{ "type": "host", "value": "…" }]`): the production domain routes to the production API's domain, the `develop` alias to the staging API's. Why it cannot be an env var: see *Gotchas*.
- Per-PR preview hosts are random, so they fall through to the **staging** API — a recorded tradeoff. A PR whose change spans both apps is verified against its own preview pair by pointing `E2E_BASE_URL` at the API preview directly.
- **Browser path:** one fetch wrapper `services/http.ts` calling relative `/api/...` paths. It parses responses with Zod, and maps the backend's error envelope to a typed `ApiError { code, status, message, correlationId }` so failures feed the base error state and carry the correlation id.
- **Locally, `vercel.json` is inert** — the Vite dev server does the same job through `server.proxy` (`/api` → `http://localhost:4000/internal/v1`), so relative `/api/...` paths and first-party cookies behave identically in dev and deployed. Keep the two destinations in step; a drift between them is the "works locally, 404s on preview" bug.
- Both the wrapper and every domain module live in `services/` — the base "all network access lives here" rule, bound. A `fetch` inlined in a component is the greppable smell.

## Four data states → React Router

Binding only — the base owns the why. **Loading** → the shared skeletons, driven by the router's pending navigation state while a route chunk is in flight and by the store's per-domain `status` for in-page fetches. **Error** → a route `errorElement` wired into the shared `<ErrorState>`, surfacing `ApiError.correlationId`; one top-level `errorElement` on the root route catches what a leaf doesn't. **Empty** → the shared `<EmptyState>` primitive. **Missing resource** → a 404 route element (the SPA answers HTTP 200 with a not-found *screen*; a real 404 status is impossible without a server — see the SEO note under *Rendering model*). Page components stay thin and delegate to the shared `atoms/`/`molecules/` primitives.

## Styling & primitives

- **Tailwind CSS 4** (CSS-first config, `@tailwindcss/vite`): design tokens are CSS variables declared in `@theme` in the global stylesheet — that declaration **is** the base's single token source; components consume semantic tokens through Tailwind utilities.
- **Foundation: Radix UI primitives**, wrapped as **atoms** in `components/atoms/` (base *Component structure* unchanged). Atom/molecule variants via `class-variance-authority`; class composition via `clsx` + `tailwind-merge` (one `cn()` helper in `lib/`). Icons: `lucide-react`.
- Fonts are **self-hosted** (`@fontsource-variable/*` imported in the entry stylesheet) with `font-display: swap` — no render-blocking third-party font request, and one less CSP origin.
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
- **Images: a plain `<img>` with explicit `width`/`height`** (reserving the box, so nothing shifts) inside an `aspect-[…]` wrapper, `object-cover` + `object-position` to art-direct across breakpoints, `loading="lazy"` + `decoding="async"` below the fold. There is no image-optimization server here — ship pre-sized assets and offer them through `srcset`/`sizes`; reach for `<picture>`/`media` only when a crop genuinely must differ.

## Versioning / build identity

The base *Versioning / build identity* rule applies in full — this is a cached static bundle, exactly the case it was written for.

- `vite.config` injects `VITE_APP_VERSION` from `npm_package_version`; render the unobtrusive `v<version>` tag from `import.meta.env.VITE_APP_VERSION`.
- Emit a build-stamped `public/version.json`, served **`no-store`** via a `vercel.json` `headers` entry, and poll it on launch/foreground — a mismatch shows the dismissible "Refresh to update" banner. Never force the reload.
- **One exception to "never force a reload":** a failed lazy-route `import()` after a redeploy (the old hashed chunk is gone from the CDN) is unrecoverable — catch it in the route `errorElement` and offer an explicit reload as the retry action.

## Analytics & Speed Insights

Wire Vercel's product analytics in from day 1 — both ship React entrypoints that work in a plain SPA:

- **Web Analytics** — add `@vercel/analytics` and render `<Analytics />` once in the root layout component.
- **Speed Insights** — add `@vercel/speed-insights` and render `<SpeedInsights />` there too, for real-user Core Web Vitals.

Enable Web Analytics + Speed Insights on the **frontend** project in the Vercel dashboard (the API serves only JSON — the browser scripts are a no-op there). This is the frontend half of the observability story whose backend/log-drain half lives in `infra.md`.

## Security headers (binding)

The base *Security baseline* header rule binds to **`vercel.json` `headers`** — there is no framework header layer in a static build, so the platform is it. Emit `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, and a **`Content-Security-Policy-Report-Only`** to start. Allow-list the origins this app actually loads — the Vercel Analytics / Speed Insights endpoints and any payment drop-in or embed — then promote the report-only header to the enforcing `Content-Security-Policy` once violation reports are clean. `connect-src` needs only `'self'`, because the API is reached through the same-origin `/api` rewrite.

## Testing — typecheck + build + Playwright e2e

- The frontend suite is `tsc --noEmit`, `vite build`, and **Playwright** specs under `apps/frontend/e2e/` exercising the real app — every screen's four states and primary flows. `E2E_BASE_URL` selects the target: the local dev stack or a deployed preview.
- **Run the specs at a narrow viewport as well as desktop** (base *Testing* rule). Define a second Playwright project on a mobile device — `{ name: 'mobile', use: { ...devices['Pixel 7'] } }` beside the desktop project — so the four-state specs also run at phone width; a suite pinned to one desktop viewport ships mobile-layout regressions. Add mobile-only assertions (nav collapses, no horizontal scroll) where a screen's layout genuinely diverges.
- **One spec asserts the SPA fallback**: request a deep route path directly (not by in-app navigation) and assert the screen renders — that is the regression test for the `vercel.json` catch-all.
- See the conflict register for what this replaces. The moment a store slice or service accrues branching logic worth isolating, add a unit runner for that code — don't scaffold one speculatively.

## Gotchas

- **`vercel.json` is static — Vercel reads it *before* the build, so it cannot interpolate an env var.** The API origin in the `/api` rewrite is therefore a literal hostname per environment (the host-conditioned rules above), never `BACKEND_URL`.

## Conflict register

- **Base says:** test store slices and `lib/` helpers as plain units, and services with the network mocked at the edge. **In this stack:** the default frontend suite is typecheck + build + Playwright e2e covering the four-state contract; per-unit suites are added on demand, not scaffolded. **Because:** this architecture keeps business logic behind the REST API, so frontend units would mostly re-test glue — e2e against the real contract catches what matters, and it is the only kind that exercises the two rewrites this pack's routing depends on. **Concretely:** DO cover every new screen's states in an e2e spec in the same change; DON'T add a unit runner until a slice/service holds real branching logic — then test that unit per the base rules.
- **Base says:** product analytics stay vendor-agnostic — emitted through one shared service/hook, with no pinned analytics SDK. **In this stack:** `@vercel/analytics` and `@vercel/speed-insights` are pinned and rendered in the root layout component (see *Analytics & Speed Insights*). **Because:** they are platform page/performance telemetry that ships with the Vercel deployment — not the product-event taxonomy; if the project adds product events, those still flow through a shared service with by-meaning names per the base rule. **Concretely:** DO keep `<Analytics />`/`<SpeedInsights />` in the root layout component; DON'T scatter product-event calls through components — those still need the shared hook.
