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
| `components/ui/`, `components/<feature>/` | unchanged |
| `lib/`, `i18n/` | unchanged |
| `routes.<ext>` | the `app/` tree + a `routes` link-helper module (see *Routing*) |
| `tokens.<ext>` | CSS variables declared via Tailwind 4 `@theme` in the global stylesheet (see *Styling*) |

## Routing

The `app/` tree replaces the central `routes.<ext>` registry; the surviving base intent is rename-safe links. Build every parameterized href through a `routes` link-helper module (`src/lib/routes.ts`) — never a hand-concatenated URL string; static routes may use literal hrefs. `<Link href>` is the default navigation primitive; `useRouter().push`/`redirect()` for programmatic cases.

## Four data states → App Router files

Binding only — the base owns the why. **Loading** → `loading.tsx` / `<Suspense>` with shared skeletons. **Error** → `error.tsx` (must be a Client Component), wiring `reset()` into the shared `<ErrorState>` and surfacing the correlation id from the failed call; root-layout failures need `global-error.tsx`. **Empty** → the shared `<EmptyState>` primitive. **Missing resource** → `not-found.tsx` + `notFound()`. Segment files stay thin and delegate to `components/ui/`.

## Styling & primitives

- **Tailwind CSS 4** (CSS-first config): design tokens are CSS variables declared in `@theme` in the global stylesheet — that declaration **is** the base's single token source; components consume semantic tokens through Tailwind utilities.
- **Foundation tier: Radix UI primitives**, wrapped in `components/ui/` (base three-tier rule unchanged). Wrapper variants via `class-variance-authority`; class composition via `clsx` + `tailwind-merge` (one `cn()` helper in `lib/`). Icons: `lucide-react`. Fonts via `next/font`.
- Don't import a prebuilt styled component kit on top — compose Radix + tokens in `components/ui/`. Swapping the headless library is allowed only by recording the choice in `apps/frontend/CLAUDE.md`; don't mix two.

## Versioning / build identity

Inline the version at build time — `next.config` sets `env.NEXT_PUBLIC_APP_VERSION` from `npm_package_version` — and render the unobtrusive `v<version>` tag from it. Vercel + App Router handle deployment skew (deployment ids, asset versioning, RSC re-fetch on navigation) — see the conflict register; no `version.json` poll.

## Testing — typecheck + build + Playwright e2e

- The frontend suite is `tsc --noEmit`, `next build`, and **Playwright** specs under `apps/frontend/e2e/` exercising the real app — every screen's four states and primary flows. `E2E_BASE_URL` selects the target: the local dev stack or a deployed preview.
- See the conflict register for what this replaces. The moment a store slice or service accrues branching logic worth isolating, add a unit runner for that code — don't scaffold one speculatively.

## Conflict register

- **Base says:** `apps/frontend` is "the single-page app" (also root `CLAUDE.md` and `README.md`). **In this stack:** it is server-first Next.js App Router on Vercel, not a client-rendered SPA. **Because:** the chosen stack. **Concretely:** default every component to server; add `'use client'` only at interaction leaves. (Soften the root-file SPA framing on day 1 per the root README; the repo name stays stale.)
- **Base says:** every route lives in one central registry `routes.<ext>`, and URLs are built through it. **In this stack:** the `app/` tree *is* the registry; a `routes` link-helper replaces hand-built URLs, so `routes.<ext>` is dropped. **Because:** App Router is filesystem-routed. **Concretely:** resolve parameterized links through the helper — never concatenate path strings; don't recreate a route→URL table (the base already forbids a second one).
- **Base says:** the client `store/` "owns application state" and may front service data (and the sibling `nextjs-nestjs-postgres` pack forbids copying server data into client state). **In this stack:** a `store/` context provider may be seeded with server-fetched data passed down from a Server Component, and owns it on the client from then on — refreshed after a mutation via `router.refresh()` or a service refetch through the same provider. **Because:** with REST-only data flow (no Server Actions, no client cache library), an interactive subtree that shares and mutates server data needs exactly one client-side carrier, and the seeded provider is it; the per-request server render alone can't hold state the subtree mutates. **Concretely:** seed a provider only for data an interactive subtree actually shares or mutates — purely-display data stays props; DON'T reflexively mirror every fetch into a provider.
- **Base says:** a deployed SPA is cached, so detect a stale bundle (poll a build-stamped `version.json` / react to a new service worker) and prompt to refresh. **In this stack:** Vercel's deployment skew protection plus App Router asset versioning and RSC re-fetch handle stale clients. **Because:** the platform solves what the base rule hand-rolls. **Concretely:** ship only the visible `v<version>` tag (from `NEXT_PUBLIC_APP_VERSION`); DON'T build a `version.json` poll.
- **Base says:** test store slices and `lib/` helpers as plain units, and services with the network mocked at the edge. **In this stack:** the default frontend suite is typecheck + build + Playwright e2e covering the four-state contract; per-unit suites are added on demand, not scaffolded. **Because:** this architecture keeps business logic behind the REST API, so frontend units would mostly re-test glue — e2e against the real contract catches what matters, and this was validated in production use of the stack. **Concretely:** DO cover every new screen's states in an e2e spec in the same change; DON'T add a unit runner until a slice/service holds real branching logic — then test that unit per the base rules.
