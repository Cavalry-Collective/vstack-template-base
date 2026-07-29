# React SPA (Vite) over a Django API — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **React + TypeScript, built by Vite into static assets**, consuming the Django/DRF backend (`./backend.md`) over REST. Read the base file first; this only adds the bindings.

## Scope

This file owns the SPA build, routing, data flow, config, styling, and frontend testing. The API and CSRF contract it consumes → `./backend.md`; who serves `dist/` → the base `infra/` contract (this pack ships no `infra.md`). Rejected alternatives for the tool picks are in the pack README → *Pack decisions*.

## Stack binding at a glance

- **Vite + React + TypeScript**, sources under `src/` in the base's shape.
- **REST-only data flow** through `services/` to the backend's `/internal/v1` API, reached as `/api` on the same origin (*Data flow* below).
- **Plain `fetch`, no react-query/SWR by default. State: React Context providers under `src/store/`.**
- **Contract types are generated**, not hand-copied: the backend's drf-spectacular OpenAPI schema → `openapi-typescript` — the base "prefer a generated contract artifact" rule, bound.
- **Config: only `VITE_`-prefixed vars reach the bundle**, read once through a Zod-parsed `src/lib/env.ts` at module load — the base fail-fast rule. Everything in the bundle is public; a secret in a `VITE_` var is the base *No secrets in the bundle* violation.

## Rendering model

**This pack is a single-page app. There is no server-side rendering, and adding any is a defect.** The base contract's SPA framing applies **verbatim** — Day-1 step 4 in the pack README keeps it as shipped.

- **`vite build` emits `dist/`: one `index.html` shell plus hashed JS/CSS.** Every route serves that same shell; React renders the page in the browser. No render-to-HTML step anywhere — not per request (SSR), not at build (SSG/prerender). HTML is authored once, by hand, in `index.html`.
- **Entry is `createRoot(...).render(...)` in `src/main.tsx`** — never `hydrateRoot`, which exists only to attach to server-rendered markup.
- **Routing is React Router in library mode** — `createBrowserRouter` + `<RouterProvider>` fed by `src/routes.tsx`, the base's single central registry: the route array plus a typed link-helper per parameterized route. Code-split at the route and nowhere else, via each route object's `lazy`. If the project ever moves to framework mode, `react-router.config.ts` **must** set `ssr: false` — framework mode defaults to SSR on.

**Forbidden — each one is greppable, and any hit is a violation:**

| Grep for | Why it's a violation |
|---|---|
| `next` in `apps/frontend/package.json` | Next.js belongs to the server-rendered packs, not this one |
| `'use client'` / `'use server'` | React Server Component directives — there is no server component tree here |
| `renderToString`, `renderToPipeableStream`, `renderToReadableStream`, `hydrateRoot` | server rendering / hydration |
| `vike`, any prerender/SSG plugin | build-time HTML generation |
| `*.server.ts(x)` files | a server tier on the web project |

A requirement that genuinely needs server-rendered HTML — public search indexability above all — is a **pack change**, not a patch. See `add-ons/seo/bindings.md`, where this pack is recorded **unbound** for exactly that reason.

## Data flow — one origin, `/api`

- **One fetch wrapper** (`services/http.ts`) calls relative `/api/...` paths, parses responses with Zod, and maps the backend's error envelope to a typed `ApiError { code, status, message, correlationId }` feeding the base error state.
- **CSRF:** session-cookie auth keeps Django's CSRF protection on (`./backend.md`) — the wrapper reads the `csrftoken` cookie and sends `X-CSRFToken` on every mutation. This lives in the one wrapper, never per call site.
- **Dev:** Vite `server.proxy` sends `/api` → `http://localhost:8000/internal/v1`, so relative paths and first-party cookies behave identically in dev and deployed.
- **Deployed:** the same shape — `dist/` and the API served from **one origin** by whatever the infra contract stands up (a reverse proxy fronting Django and the static files), with two routing rules: `/api` → the Django `internal/v1` prefix, and a catch-all serving `index.html` (the SPA fallback — without it a deep link or refresh 404s). Keep the dev proxy and the deployed rewrite pointing at the same destination; drift between them is the "works locally, 404s deployed" bug.

## Styling & primitives

- **Tailwind CSS 4** (CSS-first config): design tokens are CSS variables declared in `@theme` in the global stylesheet — that declaration *is* the base's single token source.
- **Radix UI** primitives wrapped as atoms; variants via `class-variance-authority`, composition via one `cn()` helper (`clsx` + `tailwind-merge`); fonts self-hosted (`@fontsource-variable/*`). Don't import a prebuilt styled component kit on top.

## Security headers

Headers come from the serving layer — Django's `SecurityMiddleware` where Django serves the files, otherwise the reverse proxy the infra contract stands up (`./backend.md`); static `dist/` carries none of its own. Same base rules: report-only CSP first, then enforce.

## Versioning / build identity

The base rule applies in full — this is a cached static bundle, exactly the case it was written for. `VITE_APP_VERSION` from `npm_package_version` renders the `v<version>` tag; a build-stamped `public/version.json` is served `no-store` by the serving layer and polled for the dismissible "Refresh to update" banner. One exception to "never force a reload": a failed lazy-route `import()` after a redeploy is unrecoverable — catch it in the route `errorElement` and offer an explicit reload as the retry action.

## Testing

- **Vitest + React Testing Library** for store slices, `lib/` helpers, services (network mocked at the edge — msw), and organisms' four states — the base testing rules bound, unchanged.
- **Playwright** e2e under `apps/frontend/e2e/`, run at desktop **and** a mobile device project (base narrow-viewport rule). One spec requests a deep route path directly (not by in-app navigation) and asserts the screen renders — the regression test for the SPA fallback.
- `tsc --noEmit` and `vite build` complete the suite (the root `typecheck`/`build` verbs).

## Conflict register

_No conflicts — this appendix only adds bindings; the base contract is unchanged._
