# Next.js (App Router) on Vercel — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **Next.js (App Router, TypeScript)** on Vercel, consuming the Fastify backend (`./backend.md`) over REST.

## Binding at a glance

- **App Router under `src/app/`**, TypeScript. A file is a Server Component unless it opens `'use client'`; place the directive at the smallest interaction leaf — never on a page/layout "to be safe".
- **REST-only data flow — no Server Actions, no direct DB.** Every read and mutation goes through `services/` to the backend's `/internal/v1` API. Rejected: Server Actions / route-handler data access — the Fastify backend owns the domain; a second mutation path forks the contract and bypasses its aspects.
- **Plain `fetch` through the services layer.** Rejected: react-query/SWR — add a cache library only when client-side invalidation genuinely appears; don't pre-install.
- **State: React Context providers under `src/store/`** — one per domain, seeded with server-fetched data from Server Components (registered). Rejected: Redux/Zustand — context + props cover this architecture's client-state needs.
- **Analytics: `@vercel/analytics` + `@vercel/speed-insights`** (registered — the base is vendor-agnostic).

## Structure (base `src/` → App Router)

| Base layer | Here |
|---|---|
| `pages/` | `src/app/` route segments (`page`, `layout`, `loading`, `error`, `not-found`); "pages hold no business logic" applies to `page.tsx` |
| `store/` | `src/store/` — React Context providers + hooks |
| `services/` | `src/services/` — `http.ts` (browser), `server-api.ts` (RSC), one module per backend route group |
| `components/*`, `lib/`, `i18n/` | unchanged (atomic tiers per the base *Component structure*) |
| `routes.<ext>` | the `app/` tree + a `routes` link-helper module (*Routing*) |
| `tokens.<ext>` | Tailwind 4 `@theme` CSS variables in the global stylesheet (*Styling*) |

## The `/api` proxy

- `next.config` `rewrites()` maps **`/api/:path*` → `${BACKEND_URL}/internal/v1/:path*`**. The browser talks only to the frontend origin — cookies stay first-party; no CORS.
- **Browser path:** one fetch wrapper `services/http.ts` calls relative `/api/...` paths and maps the error envelope to a typed `ApiError { code, status, message }`, feeding the base error state and carrying the correlation id.
- **Server path (RSC):** `services/server-api.ts` calls `BACKEND_URL` directly (relative URLs don't resolve server-side), **forwarding the incoming request's cookies**.
- Both paths live in `services/` — the base "all network access lives here" rule, bound; a component-inlined `fetch` is the greppable smell.
- `BACKEND_URL` is read at build time (the rewrite destination) *and* at runtime (RSC fetches) — required in both.

## Routing

Rename-safe links survive the registry's replacement (registered): build every parameterized href through `src/lib/routes.ts` — never a hand-concatenated URL string; static routes may use literal hrefs. `<Link href>` is the default navigation primitive, `useRouter().push`/`redirect()` for programmatic cases.

## Four data states → App Router files

**Loading** → `loading.tsx` / `<Suspense>` with shared skeletons. **Error** → `error.tsx` (a Client Component) wiring `reset()` into the shared `<ErrorState>` and surfacing the failed call's correlation id; root-layout failures need `global-error.tsx`. **Empty** → the shared `<EmptyState>` primitive. **Missing** → `not-found.tsx` + `notFound()`. Segment files stay thin, delegating to shared `atoms/`/`molecules/` primitives.

## Styling & primitives

- **Tailwind CSS 4** (CSS-first): design tokens are `@theme` CSS variables in the global stylesheet — that declaration **is** the base's single token source; components consume semantic tokens through Tailwind utilities.
- **Foundation: Radix UI primitives**, wrapped as **atoms** in `components/atoms/`. Variants via `class-variance-authority`; composition via `clsx` + `tailwind-merge` in one `cn()` helper (`lib/`). Icons: `lucide-react`; fonts via `next/font`.
- No prebuilt styled kit on top — compose Radix + tokens in `atoms/`/`molecules/`; swap the headless library only by recording the choice in `apps/frontend/CLAUDE.md`, and don't mix two.

## Responsive layout (Tailwind v4)

Tailwind idioms for the base rules.

- **Mobile-first, stepped utilities:** base classes target the narrowest width, scaling up with `sm:`/`md:`/`lg:`; default breakpoints usually suffice — no custom `@theme` breakpoints without a real reason.
- **Intrinsic sizing first:** fluid type/space (`clamp()` or a fluid `@theme` step) and self-wrapping layout (`grid-cols-[repeat(auto-fit,minmax(…,1fr))]`, `flex-wrap`) before adding a breakpoint.
- **Container queries for component responsiveness:** a primitive adapting to its space uses the built-in `@container` + `@sm:`/`@md:` variants — one component works in a wide main and a narrow sidebar; viewport breakpoints stay page-level.
- **No `tailwind.config`:** breakpoints and tokens live in the `@theme` declaration; header clearance and screen gutter are semantic tokens (`--header-clearance`, `--gutter-screen`), not magic numbers.
- **One layout primitive owns the gutter:** wrap `container mx-auto px-4 lg:px-8` once as a `<Container>`/`<Section>` atom (driven by `--gutter-screen`), inner `max-w-*` reading columns; hand-composed gutter strings are the greppable smell.
- **Full-bleed hero:** `min-h-[Xrem]` + responsive `py-*` — never `h-screen`/`100vh`, never `aspect-[…]` on a flex child. True viewport fill (a mobile sheet): `min-h-[100svh]`. Clearance: `pt-[…]` bound to `--header-clearance`; top-anchor copy so position ignores headline height.
- **Atomic values don't wrap:** the shared inline-value/link atom applies `whitespace-nowrap` to `tel:`/`mailto:` values and `font-mono` codes; long unbreakables use `overflow-wrap`; free-text cells `truncate max-w-*` inside a `min-w-0` parent; wide tables/code sit in `overflow-x-auto`.
- **`text-balance` is the heading default** — set in the shared heading atom.
- **`<DataTable>` primitive:** `overflow-x-auto` wrapper + `whitespace-nowrap` columns (opt-in `truncate max-w-*` for free text) + the base's bounded pagination window.
- **Dialog sizing baseline** (solved once per the base): `w-full max-w-[calc(100%-2rem)] sm:max-w-lg` — full-width-minus-gutter on phones, capped above `sm`.
- **Images:** `next/image` `fill` + explicit `sizes` + an `aspect-[…]` wrapper; art-direct with `object-position`/`object-cover` rather than shipping crops (a genuinely different crop is `<picture>`/`media`); `unoptimized` only for `data:` URLs and the logo.

## Build identity

`next.config` sets `env.NEXT_PUBLIC_APP_VERSION` from `npm_package_version`; render the unobtrusive `v<version>` tag from it. Skew is platform-handled (registered — no `version.json` poll).

## Analytics & Speed Insights (registered)

- **Web Analytics:** add `@vercel/analytics`; render `<Analytics />` in the root layout (`app/layout.tsx`).
- **Speed Insights:** add `@vercel/speed-insights`; render `<SpeedInsights />` beside it — real-user Core Web Vitals.

Enable both on the **frontend** Vercel project (the API serves only JSON — the scripts no-op there); the log-drain half of observability lives in `infra.md`.

## Security bindings

The base *Security baseline* binds to **`next.config` `async headers()`**: emit `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, and a **`Content-Security-Policy-Report-Only`** to start. Allow-list only origins the app actually loads — the Analytics/Speed Insights endpoints and any payment drop-in or embed — then promote to the enforcing header once reports are clean.

## Testing

- The suite is `tsc --noEmit`, `next build`, and **Playwright** specs under `apps/frontend/e2e/` exercising the real app — every screen's four states and primary flows. `E2E_BASE_URL` selects the target: local dev stack or deployed preview. Unit runners are on-demand (registered).
- **Run the specs at a narrow viewport too** (base rule): a second Playwright project on a mobile device — `{ name: 'mobile', use: { ...devices['Pixel 7'] } }` — runs the four-state specs at phone width; add mobile-only assertions (nav collapses, no horizontal scroll) where a layout genuinely diverges.

## Conflict register

- **Base says:** `apps/frontend` is "the single-page app". **In this stack:** server-first Next.js App Router on Vercel, not a client-rendered SPA. **Because:** the chosen stack. **Concretely:** default every component to server; add `'use client'` only at interaction leaves; soften the root-file SPA framing on day 1 per the root README (the repo name stays stale).
- **Base says:** every route lives in one central registry `routes.<ext>` and URLs are built through it. **In this stack:** the `app/` tree *is* the registry; the `routes` link-helper replaces hand-built URLs; `routes.<ext>` is dropped. **Because:** App Router is filesystem-routed. **Concretely:** resolve parameterized links through the helper — never concatenate path strings; DON'T recreate a route→URL table.
- **Base says:** the client `store/` "owns application state" and may front service data. **In this stack:** a context provider is seeded with server-fetched data from a Server Component and owns it on the client — refreshed after a mutation via `router.refresh()` or a service refetch through the same provider. **Because:** under REST-only data flow with no client cache library, an interactive subtree that shares and mutates server data needs exactly one client-side carrier — the seeded provider. **Concretely:** seed a provider only for data an interactive subtree shares or mutates — purely-display data stays props; DON'T reflexively mirror every fetch into a provider.
- **Base says:** a deployed SPA is cached — detect a stale bundle (a `version.json` poll / service-worker signal) and prompt to refresh. **In this stack:** Vercel deployment skew protection, App Router asset versioning, and RSC re-fetch handle stale clients. **Because:** the platform solves what the base rule hand-rolls. **Concretely:** ship only the visible `v<version>` tag (from `NEXT_PUBLIC_APP_VERSION`); DON'T build a `version.json` poll.
- **Base says:** analytics stay vendor-agnostic — emit through the shared service; don't pin an analytics SDK (*Cross-app conventions*). **In this stack:** `@vercel/analytics` and `@vercel/speed-insights` are pinned. **Because:** platform identity is what this pack buys; both stream to the project dashboard. **Concretely:** the two root-layout mounts are the ONLY inline vendor code — DO route product events through the shared analytics service; DON'T scatter vendor calls in components.
- **Base says:** test store slices and `lib/` helpers as plain units; services with the network mocked at the edge. **In this stack:** the default suite is typecheck + build + Playwright e2e covering the four-state contract; unit suites arrive on demand. **Because:** business logic lives behind the REST API, so frontend units would mostly re-test glue — e2e against the real contract catches what matters. **Concretely:** DO cover every new screen's states in an e2e spec in the same change; DON'T add a unit runner until a slice/service holds real branching logic — then test it per the base rules.
