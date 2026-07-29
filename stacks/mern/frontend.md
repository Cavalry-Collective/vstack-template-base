# React SPA (Vite) — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **React + TypeScript, built by Vite into static assets**, served by whatever the base `infra/` contract stands up (see *Serving `dist/`*) and consuming the Express backend (`./backend.md`) over REST. Read the base file first; this only adds the bindings and the marked overrides.

## Rendering model: client-only. No SSR. (load-bearing)

**This pack is a single-page app. There is no server-side rendering, and adding any is a defect, not an improvement.** The base contract's SPA framing (`apps/frontend/CLAUDE.md`, root `CLAUDE.md`, root `README.md`) applies **verbatim** — skip the root `README.md` "soften the SPA framing" step; it targets the server-first packs.

- **`vite build` emits `dist/`: one static `index.html` shell plus hashed JS/CSS.** Every route returns that same shell; React renders the page in the browser. **No render-to-HTML step anywhere** — not per request (SSR), not at build (SSG/prerender). HTML is authored once, by hand, in `index.html`.
- **Entry is `createRoot(...).render(...)` in `src/main.tsx`** — never `hydrateRoot`, which exists only to attach to server-rendered markup.
- **Routing is React Router in library mode** — `createBrowserRouter` + `<RouterProvider>` fed by the central registry (see *Routing*). If the project ever moves to React Router **framework mode**, `react-router.config.ts` **must** set `ssr: false`; framework mode defaults to SSR on.

**Forbidden — each one is greppable, and any hit is a violation:**

| Grep for | Why it's a violation |
|---|---|
| `next`, `next/*` in `apps/frontend/package.json` | Next.js belongs to the server-rendered packs (`vercel-ssr`, `enterprise`), not this one |
| `'use client'` / `'use server'` | React Server Component directives — there is no server component tree here |
| `renderToString`, `renderToPipeableStream`, `renderToReadableStream`, `hydrateRoot` | server rendering / hydration |
| `vike`, `vite-plugin-ssr`, any prerender/SSG plugin | build-time HTML generation |
| `*.server.ts(x)`, an `api/` directory under `apps/frontend/` | a server tier on the web project |

**If a requirement genuinely needs server-rendered HTML — public search indexability above all — that is a pack change, not a patch.** Switch deliberately to a server-rendered pack (or serve the crawlable surface outside this app); do not bolt a render step onto this one. See `add-ons/seo/bindings.md`, where this pack is recorded **unbound** for exactly that reason.

## Stack binding at a glance

- **Vite + React + TypeScript**, sources under `src/` in the base's shape (below). `@vitejs/plugin-react`.
- **REST-only data flow.** Every read and mutation goes through `services/` to the backend's `/internal/v1` API. Pack decision — rejected alternative: any client-side direct-DB or BFF layer; the Express backend owns the domain and its aspects.
- **Plain `fetch` through the services layer — no react-query/SWR by default.** Pack decision — rejected alternative: react-query (add it only when client-side cache invalidation genuinely appears; don't pre-install).
- **State: React Context providers under `src/store/`** — one provider per domain. Pack decision — rejected alternative: an external store library (Redux/Zustand); context + props cover this architecture's needs.
- **Config: only `VITE_`-prefixed vars reach the bundle**, read once through one typed `src/lib/env.ts` parsed by Zod at module load — binds the base *Configuration* fail-fast rule. Everything in the bundle is **public**; a secret in a `VITE_` var is the base *No secrets in the bundle* violation.

## Serving `dist/` — deploy-seam requirements (load-bearing)

This pack ships no `infra.md`, so the serving layer is whatever the base `infra/` contract stands up — and it **must** provide all four; infra work is measured against them:

1. **Catch-all → `index.html`.** Without it, a deep link or a refresh on any route but `/` returns a 404 — the canonical SPA-on-a-static-host bug.
2. **`/api/:path*` reverse proxy → the API origin's `/internal/v1/:path*`.** The browser only ever talks to the web origin, so session cookies stay first-party and CORS never enters the picture.
3. **Hardening headers** — the base *Security baseline* set (`Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, a CSP shipped report-only first). A static build has no framework header layer; the serving layer is it. `connect-src` needs only `'self'`, because the API is reached through the same-origin `/api` proxy.
4. **`public/version.json` answered `no-store`** (see *Versioning*).

- **Locally, the Vite dev server covers 1–2** through `server.proxy` (`/api` → `http://localhost:4000/internal/v1`), so relative `/api/...` paths and first-party cookies behave identically in dev and deployed. Keep the dev and deployed proxy destinations in step; a drift between them is the "works locally, 404s deployed" bug.
- **Browser path:** one fetch wrapper `services/http.ts` calling relative `/api/...` paths. It parses responses with Zod and maps the backend's error envelope to a typed `ApiError { code, status, message, correlationId }` so failures feed the base error state and carry the correlation id. Both the wrapper and every domain module live in `services/` — the base "all network access lives here" rule, bound; a `fetch` inlined in a component is the greppable smell.

## Folder mapping (base `src/` shape)

The base shape holds **as written** — `store/`, `services/`, `pages/`, `components/{atoms,molecules,organisms/<feature>,templates}`, `i18n/`, `lib/`. Two file bindings only:

| Base file | Here |
|---|---|
| `routes.<ext>` | `src/routes.tsx` — the React Router route objects **and** the link helpers, one module (see *Routing*) |
| `tokens.<ext>` | CSS variables declared via Tailwind 4 `@theme` in the global stylesheet (see *Styling*) |

## Routing

`src/routes.tsx` is the base's single central registry, bound: the `createBrowserRouter` route array plus a typed link-helper per parameterized route. `<Link to>` is the default navigation primitive; `useNavigate()` for programmatic cases. Never hand-concatenate a path string — resolve it through the helper. **Code-split at the route and nowhere else**: each entry loads its page through the route object's own `lazy` field, so one chunk maps to one screen.

## Four data states → React Router

Binding only — the base owns the why. **Loading** → the shared skeletons, driven by the router's pending navigation state while a route chunk is in flight and by the store's per-domain `status` for in-page fetches. **Error** → a route `errorElement` wired into the shared `<ErrorState>`, surfacing `ApiError.correlationId`; one top-level `errorElement` on the root route catches what a leaf doesn't. **Empty** → the shared `<EmptyState>` primitive. **Missing resource** → a 404 route element (the SPA answers HTTP 200 with a not-found *screen*; a real 404 status is impossible without a server — see the SEO note above).

## Styling & primitives

- **Tailwind CSS 4** (CSS-first config, `@tailwindcss/vite`): design tokens are CSS variables declared in `@theme` in the global stylesheet — that declaration **is** the base's single token source; components consume semantic tokens through Tailwind utilities. No `tailwind.config`.
- **Foundation: Radix UI primitives**, wrapped as **atoms** in `components/atoms/`. Variants via `class-variance-authority`; class composition via `clsx` + `tailwind-merge` (one `cn()` helper in `lib/`). Icons: `lucide-react`. Fonts **self-hosted** (`@fontsource-variable/*`) with `font-display: swap`.
- Don't import a prebuilt styled component kit on top — compose Radix + tokens in `atoms/`/`molecules/`. Swapping the headless library is allowed only by recording the choice in `apps/frontend/CLAUDE.md`; don't mix two.

## Responsive idioms (Tailwind 4)

The base *Responsive layout* rules own the why; the Tailwind bindings: mobile-first stepped utilities (`sm:`/`md:`/`lg:`); prefer intrinsic sizing (`clamp()`, `grid-cols-[repeat(auto-fit,minmax(…,1fr))]`, `flex-wrap`) before adding a breakpoint; a component that adapts to its container uses `@container` + `@sm:` variants, keeping viewport breakpoints for page-level layout. Header clearance and screen gutter are semantic `@theme` tokens (`--header-clearance`, `--gutter-screen`); one `<Container>`/`<Section>` atom owns the gutter idiom — hand-composing `container mx-auto px-*` per page is the greppable smell. Never `h-screen`/`100vh` — content-driven `min-h-[Xrem]`, and `min-h-[100svh]` where something must truly fill the viewport. Wide tables/code scroll in their own `overflow-x-auto` box (`truncate max-w-*` needs a `min-w-0` parent); `text-balance` is the heading atom's default.

## Versioning / build identity

**The base *Versioning / build identity* rule applies in full** — this is a cached static bundle, exactly the case it was written for.

- `vite.config` injects `VITE_APP_VERSION` from `npm_package_version`; render the unobtrusive `v<version>` tag from `import.meta.env.VITE_APP_VERSION`.
- Emit a build-stamped `public/version.json` (served `no-store` — deploy-seam requirement 4) and poll it on launch/foreground; a mismatch shows the dismissible "Refresh to update" banner. Never force the reload.
- **One exception to "never force a reload":** a failed lazy-route `import()` after a redeploy (the old hashed chunk is gone) is unrecoverable — catch it in the route `errorElement` and offer an explicit reload as the retry action.

## Testing — typecheck + build + Playwright e2e

- The frontend suite is `tsc --noEmit`, `vite build`, and **Playwright** specs under `apps/frontend/e2e/` exercising the real app — every screen's four states and primary flows. `E2E_BASE_URL` selects the target: the local dev stack or a deployed environment.
- **Run the specs at a narrow viewport as well as desktop** (base *Testing* rule): a second Playwright project on a mobile device — `{ name: 'mobile', use: { ...devices['Pixel 7'] } }` — beside the desktop one.
- **One spec asserts the SPA fallback**: request a deep route path directly (not by in-app navigation) and assert the screen renders. Run it against a *served* target — the Vite dev server always falls back, so only a deployed/preview run proves deploy-seam requirement 1.
- See the conflict register for what this replaces. The moment a store slice or service accrues branching logic worth isolating, add a unit runner for that code — don't scaffold one speculatively.

## Conflict register

- **Base says:** test store slices and `lib/` helpers as plain units, and services with the network mocked at the edge. **In this stack:** the default frontend suite is typecheck + build + Playwright e2e covering the four-state contract; per-unit suites are added on demand, not scaffolded. **Because:** this architecture keeps business logic behind the REST API, so frontend units would mostly re-test glue — e2e against the real contract catches what matters, and it is the only kind that exercises the proxy and fallback this pack's deploy seam depends on. **Concretely:** DO cover every new screen's states in an e2e spec in the same change; DON'T add a unit runner until a slice/service holds real branching logic — then test that unit per the base rules.
