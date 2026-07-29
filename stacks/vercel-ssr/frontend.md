# Next.js (App Router, full-stack) — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **Next.js (App Router, TypeScript)** — the UI half of the single full-stack app. Read the base file first; this only adds the bindings and the marked overrides.

## Scope

This file owns the App Router UI: folder mapping, routing, the four data states, auth UX, styling and responsive idioms, versioning, analytics, headers, and frontend testing. The server half is `./backend.md`; provisioning and deploys are `./infra.md`.

## Stack binding at a glance

- **App Router under `src/app/`**, TypeScript. A file is a Server Component unless it opens `'use client'`; place the directive at the smallest interaction leaf — never on a page/layout "to be safe".
- **Data flow is function calls, not HTTP.** Server Components read by importing a module's `controller/queries.ts`; client components mutate by invoking its `controller/actions.ts` Server Actions. No internal REST API, no fetch wrapper, and no react-query/SWR (add a client cache library only when client-side invalidation needs genuinely appear). See the conflict register.
- **State: React Context providers under `src/store/`** — one provider per domain, seeded with server-fetched data passed down from Server Components (pack decision — see the README). After a successful mutation the action calls `revalidatePath`/`revalidateTag` (or the client calls `router.refresh()`), so the seeded provider re-hydrates from fresh server data.
- **Authenticated screens are dynamically rendered by construction** (they read the session cookie); don't fight that with route-level cache tuning. Static/ISR rendering is for the public indexable surface.

## Folder mapping (base `src/` shape → App Router)

| Base layer | Here |
|---|---|
| `pages/` | `src/app/` route segments (`page`, `layout`, `loading`, `error`, `not-found`); "pages hold no business logic" applies to `page.tsx` |
| `store/` | `src/store/` — React Context providers + hooks |
| `services/` | **replaced** by the server modules' controller edges (`queries.ts` / `actions.ts` — `./backend.md`); no `src/services/` (see the conflict register) |
| `components/atoms/`, `components/molecules/`, `components/organisms/<feature>/`, `components/templates/` | unchanged (atomic tiers per the base *Component structure*) |
| `lib/`, `i18n/` | unchanged |
| `routes.<ext>` | the `app/` tree + a `routes` link-helper module (see *Routing*) |
| `tokens.<ext>` | CSS variables declared via Tailwind 4 `@theme` in the global stylesheet (see *Styling*) |

## Routing

The `app/` tree replaces the central `routes.<ext>` registry; the surviving base intent is rename-safe links. Build every parameterized href through a `routes` link-helper module (`src/lib/routes.ts`) — never a hand-concatenated URL string; static routes may use literal hrefs. `<Link href>` is the default navigation primitive; `useRouter().push`/`redirect()` for programmatic cases.

## Four data states → App Router files

Binding only — the base owns the why. **Loading** → `loading.tsx` / `<Suspense>` with shared skeletons. **Error** → `error.tsx` (must be a Client Component), wiring `reset()` into the shared `<ErrorState>` and surfacing the error reference — the envelope's `correlationId`, or the RSC error `digest`; root-layout failures need `global-error.tsx`. **Empty** → the shared `<EmptyState>` primitive. **Missing resource** → `not-found.tsx` + `notFound()`. **Mutation in flight** → `useActionState`'s pending flag on the triggering control (the base "feedback stays on the control" rule); a failed action feeds the shared error and field-error primitives from its returned envelope. Segment files stay thin and delegate to the shared `atoms/`/`molecules/` primitives.

## Auth UX (cross-app conventions, bound)

There is no HTTP interceptor because there is no internal HTTP: an unauthenticated query/action triggers a server-side `redirect('/login?next=…')` from the shared guard (`./backend.md` → *Aspects*, auth), preserving the requested URL; an authorization failure renders the shared forbidden state — never a bounce to login. Sign-out clears the seeded providers so no stale authenticated data lingers. The correlation id arrives in the result envelope (not a response header); the shared error path surfaces it unchanged ("Error reference: `<id>`").

## Styling & primitives

- **Tailwind CSS 4** (CSS-first config): design tokens are CSS variables declared in `@theme` in the global stylesheet — that declaration **is** the base's single token source; components consume semantic tokens through Tailwind utilities.
- **Foundation: Radix UI primitives**, wrapped as **atoms** in `components/atoms/` (base *Component structure* unchanged). Atom/molecule variants via `class-variance-authority`; class composition via `clsx` + `tailwind-merge` (one `cn()` helper in `lib/`). Icons: `lucide-react`. Fonts via `next/font`.
- Don't import a prebuilt styled component kit on top — compose Radix + tokens in `components/atoms/`/`molecules/`. Swapping the headless library is allowed only by recording the choice in `apps/frontend/CLAUDE.md`; don't mix two.

## Responsive layout (Tailwind v4)

Binds the base *Responsive layout* rules to Tailwind v4 — the base owns the *why*, here is the idiom for each.

- **Mobile-first, stepped utilities.** Base classes target the narrowest width; scale up with `sm:`/`md:`/`lg:`. The default breakpoints are usually enough — don't add custom `@theme` breakpoints without a real reason.
- **Prefer intrinsic sizing over breakpoints.** Reach for fluid type/space (`clamp()`, or a fluid step in the `@theme` scale) and self-wrapping layout (`grid-cols-[repeat(auto-fit,minmax(…,1fr))]`, `flex-wrap`) before adding a breakpoint.
- **Component responsiveness uses container queries.** A primitive that must adapt to the space it occupies uses Tailwind v4's built-in `@container` + `@sm:`/`@md:` variants (not viewport `sm:`/`md:`); keep viewport breakpoints for page-level layout.
- **CSS-first, no `tailwind.config`.** Breakpoints and tokens are the `@theme` declaration in the global stylesheet — the single token source the base names. Header clearance and screen gutter are semantic tokens (`--header-clearance`, `--gutter-screen`), not magic numbers per page.
- **One layout primitive owns the gutter.** Wrap the recurring `container mx-auto px-4 lg:px-8` idiom once as a `<Container>` / `<Section>` atom (driven by `--gutter-screen`); hand-composing that string per page is the greppable smell.
- **Full-bleed hero: content-driven height.** `min-h-[Xrem]` + responsive `py-*`. **Never** `h-screen` / `100vh` (ignores mobile browser UI) and **never** `aspect-[…]` on a flex child. Where an element must truly fill the viewport, use `min-h-[100svh]` — not `vh`, and `dvh` only to deliberately track the URL bar. Clearance comes from the shared layout token; top-anchor the copy so its position doesn't depend on (admin-editable) headline height.
- **Atomic values don't wrap.** The shared inline-value / link atom applies `whitespace-nowrap` to `tel:`/`mailto:` values and `font-mono` codes; a long unbreakable string uses `overflow-wrap`. Free-text table cells use `truncate max-w-*` inside a `min-w-0` parent; wrap wide tables/code in an `overflow-x-auto` box so the page never scrolls sideways.
- **`text-balance` is the heading default** — set it in the shared heading atom, don't retrofit per screen.
- **`<DataTable>` primitive.** `overflow-x-auto` wrapper + `whitespace-nowrap` columns (opt-in `truncate max-w-*` for free text) + **windowed pagination (≤ ~7 slots: first, last, current ± 1, ellipsis)** so a large page count can't widen the layout.
- **Modal sizing is fixed once.** Keep the Radix dialog baseline `w-full max-w-[calc(100%-2rem)] sm:max-w-lg`; don't re-solve dialog sizing per feature.
- **Images: `next/image` `fill` + explicit `sizes` + an `aspect-[…]` wrapper.** Art-direct across breakpoints with `object-position` / `object-cover` rather than shipping crops — unless a crop genuinely must differ, which is what `<picture>` / `media` is for. Use `unoptimized` only for `data:` URLs and the logo.

## Versioning / build identity

Inline the version at build time — `next.config` sets `env.NEXT_PUBLIC_APP_VERSION` from `npm_package_version` — and render the unobtrusive `v<version>` tag from it. Vercel + App Router handle deployment skew (deployment ids, asset versioning, RSC re-fetch on navigation) — see the conflict register; no `version.json` poll.

## Analytics & Speed Insights

Wire Vercel's product analytics in from day 1 — both are drop-in for the App Router:

- **Web Analytics** — add `@vercel/analytics` and render `<Analytics />` in the root layout (`app/layout.tsx`).
- **Speed Insights** — add `@vercel/speed-insights` and render `<SpeedInsights />` in the root layout, for real-user Core Web Vitals.

Enable both on the Vercel project in the dashboard. This is the frontend half of the observability story whose log-drain half lives in `./infra.md`.

## Security headers (binding)

The base *Security baseline* (`apps/frontend/CLAUDE.md`) is bound here to **`next.config` `async headers()`**: emit `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, and a **`Content-Security-Policy-Report-Only`** to start. Allow-list the origins this app actually loads — the Vercel Analytics / Speed Insights endpoints and any payment drop-in or embed — then promote to the enforcing `Content-Security-Policy` once violation reports are clean.

## Testing — typecheck + build + Playwright e2e

- The frontend suite is `tsc --noEmit`, `next build`, and **Playwright** specs under `apps/frontend/e2e/` exercising the real app — every screen's four states and primary flows. `E2E_BASE_URL` selects the target: the local dev stack or a deployed preview.
- **Run the specs at a narrow viewport as well as desktop** (base *Testing* rule). Define a second Playwright project on a mobile device — `{ name: 'mobile', use: { ...devices['Pixel 7'] } }` beside the desktop project; add mobile-only assertions (nav collapses, no horizontal scroll) where a screen's layout genuinely diverges.
- See the conflict register for what this replaces. The moment a store slice or `lib/` helper accrues branching logic worth isolating, cover it in the Vitest runner the server side already ships (`./backend.md` → *Testing*) — don't scaffold a second one.

## Conflict register

- **Base says:** `apps/frontend` is "the single-page app" (also root `CLAUDE.md` and `README.md`). **In this stack:** it is the whole product — a server-first full-stack Next.js App Router app, not a client-rendered SPA. **Because:** the chosen stack. **Concretely:** default every component to server; add `'use client'` only at interaction leaves. (Soften the root-file framing on day 1 per the manifest; the repo name stays stale.)
- **Base says:** `services/` own all data fetching and mutation, mirror backend route groups, and validate responses at the network edge; the cross-app conventions expect a shared HTTP interceptor (401 redirect, `x-correlation-id` header). **In this stack:** there is no internal HTTP — reads are module queries imported by Server Components, mutations are Server Actions, and the server modules' `controller/` edge *is* the service layer; auth redirects happen server-side in the shared guard, and the correlation id rides the typed result envelope. **Because:** one app, one module graph — the network boundary the services layer wraps does not exist, and response validation is redundant when the shape is one typed import. **Concretely:** DON'T create `src/services/` or a fetch wrapper for the app's own data — a `fetch` to the app's own origin is the greppable smell; genuinely third-party browser SDKs (analytics) are the only client-side network callers.
- **Base says:** every route lives in one central registry `routes.<ext>`, and URLs are built through it. **In this stack:** the `app/` tree *is* the registry; a `routes` link-helper replaces hand-built URLs, so `routes.<ext>` is dropped. **Because:** App Router is filesystem-routed. **Concretely:** resolve parameterized links through the helper — never concatenate path strings; don't recreate a route→URL table (the base already forbids a second one).
- **Base says:** the client `store/` "owns application state" and may front service data. **In this stack:** a `store/` context provider may be seeded with server-fetched data passed down from a Server Component, and owns it on the client from then on — refreshed after a mutation via `revalidatePath`/`router.refresh()` through the same provider. **Because:** with no client cache library, an interactive subtree that shares and mutates server data needs exactly one client-side carrier, and the seeded provider is it. **Concretely:** seed a provider only for data an interactive subtree actually shares or mutates — purely-display data stays props; DON'T reflexively mirror every query into a provider.
- **Base says:** a deployed SPA is cached, so detect a stale bundle (poll a build-stamped `version.json` / react to a new service worker) and prompt to refresh. **In this stack:** Vercel's deployment skew protection plus App Router asset versioning and RSC re-fetch handle stale clients. **Because:** the platform solves what the base rule hand-rolls. **Concretely:** ship only the visible `v<version>` tag (from `NEXT_PUBLIC_APP_VERSION`); DON'T build a `version.json` poll.
- **Base says:** test store slices and `lib/` helpers as plain units, and services with the network mocked at the edge. **In this stack:** the default frontend suite is typecheck + build + Playwright e2e covering the four-state contract; per-unit coverage is added on demand, not scaffolded, and there is no network edge to mock — a service-layer test is a use-case test on the server side (`./backend.md`). **Because:** business logic lives behind the controller edge, so frontend units would mostly re-test glue; e2e against the real app catches what matters. **Concretely:** DO cover every new screen's states in an e2e spec in the same change; DON'T add frontend unit files until a slice/helper holds real branching logic — then test that unit per the base rules.
- **Base says:** product analytics stay vendor-agnostic — emitted through one shared service/hook, with no pinned analytics SDK. **In this stack:** `@vercel/analytics` and `@vercel/speed-insights` are pinned and rendered in the root layout. **Because:** they are platform page/performance telemetry that ships with the Vercel deployment — not the product-event taxonomy; product events still flow through a shared hook with by-meaning names per the base rule. **Concretely:** DO keep `<Analytics />`/`<SpeedInsights />` in `app/layout.tsx`; DON'T scatter product-event calls through components — those still need the shared hook.
