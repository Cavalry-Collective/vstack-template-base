# Next.js (App Router) frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **Next.js (App Router, server-first)**. Read the base file first; this only adds App-Router mechanics and the marked overrides. Backend hop → `./backend.md`; data layer → `./db.md`.

## Server-first cheat-sheet

- **A file is a Server Component unless it opens `'use client'`.** Reach for a Client Component **only at an interaction leaf** — a component using `useState`/`useEffect`/`onClick`/browser APIs. Everything else stays on the server.
- **Place the directive leaf-ward**, at the smallest interactive component — never on a page/layout "to be safe": lifting it forces the whole subtree to the client. Pages stay Server Components and pass data into small client leaves.
- Next `layout` files **are** the base's single shared layout (the frame); `page` files supply content. The `app/` tree **is** the route registry (see *Routing*).
- **JS or TS, project's choice** — honour base types as TS `interface`/`type` or JS JSDoc `@typedef` (same ports approach as `apps/backend/CLAUDE.md`). One language per app. JS path: use `jsconfig.json` (not `tsconfig.json`) for path aliases; `.js`/`.jsx`, Server Actions, and `'use client'` need no extra transform. (The Nest Babel/decorator setup is a backend concern — `./backend.md` — and does not apply here.)
- **App location is pinned to `src/app/`**, keeping `app/` under the same `src/` root the base structure assumes. Colocated non-route code lives elsewhere under `src/`.

## Folder mapping (base `src/` shape → App Router)

Each base layer keeps its meaning; only its home moves. Feature-slice grouping is unchanged.

| Base layer | Here |
|---|---|
| `pages/` | `src/app/` route segments — `page`, `layout`, `loading`, `error`, `not-found`, `global-error`. The base "pages hold no business logic, compose organisms" rule applies to `page.*`. |
| `store/` | `src/store/` — **client state only** (see *Data access*). |
| `services/` | `src/services/{server,client}/` — split by execution context. Server Actions live in dedicated `_actions`/`action.*` files, separate from `server/` data-access. |
| `components/atoms/`, `components/molecules/`, `components/organisms/<feature>/`, `components/templates/` | unchanged (atomic tiers per base *Component structure*). An interactive atom/molecule is a client leaf; a presentational one may stay a Server Component. |
| `i18n/`, `lib/`, `tokens.<ext>` | unchanged source; tokens consumed via a server-safe mechanism (see *Layout & tokens*). |
| `routes.<ext>` | replaced by the `app/` tree + a `routes` link-helper module (see *Routing*). |

## Data access

- **Network access still lives in `services/`** (base rule, bound verbatim) — the fetch *sites* move server-side. Server Components call `services/server/`; Client Components mutate via a Server Action (default) or `services/client/`. **Forbidden:** ad-hoc `fetch()`/`axios`/SDK calls inlined in a component (grep client files for those as a smell).
- **State home — URL → Server → Client.** URL (route segment / search params) for anything navigable or shareable; **server** data is the per-request Server Component render (Next 15+ is uncached-by-default — opt into caching explicitly per call via `cache`/`next.revalidate`); **client `store/`** holds only genuinely client UI/ephemeral/optimistic state. **Do not copy server data into a `store/` slice** to "have it on the client."
- **Mutations** go Client Component → Server Action (default) → `revalidatePath()`/`revalidateTag()` for the affected data. A write that changes user-visible data and doesn't revalidate is a bug. A Server Action file opens with `'use server'` and exports **only async functions** — keep actions out of `services/server/` data-access files. Use `services/client/` direct calls only when an action can't (e.g. optimistic UI needing the response inline); justify in the PR.

### Next-server → NestJS boundary

The real backend is NestJS (`apps/backend`). `services/server/` wraps fetch to its `/internal/v1` API: one base-URL config, **forwards auth** (cookies/headers from the request), and **propagates the correlation id** across the hop so the base's cross-app correlation rule holds. A Server Component never reaches the DB directly — it goes through the NestJS API. **Validate responses with the shared Zod schema** (see *Forms & schemas*) so a contract break surfaces as a typed error feeding the base `error` state.

## Routing

The base's central `routes.<ext>` registry is replaced by the `app/` tree; the base's `internal path → browser URL` mapping is the filesystem, so the pack keeps **no** duplicate table. What survives is the base intent — rename-safe links, no hand-built URLs.

- **Build parameterized hrefs through a `routes` link-helper module** (`src/lib/routes.*`): one named builder per parameterized segment (`routes.order(id)` → `/orders/${id}`), keyed off the `app/` tree. Links/redirects resolve through it — **never a raw URL string literal**. Static routes may use literal hrefs.
- `<Link href>` is the default navigation primitive; `useRouter().push` / `redirect()` for programmatic cases. Route groups `(group)/` keep org-only folders out of the URL; `_folders` colocate non-route code. (`next typedRoutes` is TS-only and optional — not the default, since the pack must not mandate TS.)

## Four data states → App Router files

The base owns *why* each of loading/error/empty/success matters; this only adds the file binding. Segment files stay thin and delegate to the shared `atoms/`/`molecules/` primitives.

- **Loading** → `loading.*` + `<Suspense>` streaming, falling back to a shared `<Skeleton>`/`<Spinner>`. Don't hand-roll spinner state where a `loading.*` boundary belongs.
- **Error** → `error.*` boundary — **must be a Client Component**; catches errors from its own segment + children (put a boundary at the parent segment to catch a sibling `layout.*`), and wires `reset()` into the shared `<ErrorState>` retry. Throw on a failed fetch/action so the boundary catches it; never catch-and-render an error string inline. Surface the correlation id from the failed call in the error UI (base cross-app rule).
- **Root-layout errors** → `error.*` does not catch them; add `global-error.*` at app root (renders its own `<html>`/`<body>`, still showing the shared `<ErrorState>`).
- **Empty** → shared `<EmptyState>` primitive (base: designed, not blank). **Not-found** → `not-found.*` + `notFound()` for missing resources.

## Primitives, layout & tokens

- **Headless lib: Radix UI is blessed** as the base's headless foundation; wrap it as **atoms** in `components/atoms/` (base *Component structure* unchanged). A project may swap to another headless lib (Headless UI, Ark, React Aria) only by recording the choice in `apps/frontend/CLAUDE.md` — don't mix two.
- **Interactive atoms/molecules are client leaves, and that is correct** — Radix and most headless libs are client-only, so `<Button>`-with-handler, `<Modal>`, `<Menu>`, `<Combobox>` carry `'use client'`. **Do NOT hand-roll a server-only control to dodge `'use client'`** — that re-drops the accessibility the base requires (the canonical base mistake). Purely-presentational atoms/molecules (`<Badge>`, `<Card>`, layout chrome) may stay Server Components.
- **Tokens must be consumable by Server Components without a client runtime** — use CSS variables / a Tailwind theme / a static token module. A runtime CSS-in-JS lib that forces `'use client'` at the token boundary is disallowed. Map the base shared layout onto Next root/segment `layout` files; declare global tokens once on `:root` in the root layout. The primary-form-factor declaration (project-local, `apps/frontend/CLAUDE.md`) selects which base layout tokens the root layout applies (e.g. `--bottom-nav-clearance` for mobile-first); responsive stays the baseline.
- **Boundary hygiene:** only RSC-serializable props cross into a client leaf (primitives, plain objects, `Date`/`Map`/`Set`/`BigInt`, Server Action refs) — not functions or class instances. Format a date on **one** side via the shared date helper with timezone/locale pinned; an unpinned date format is the canonical App-Router hydration bug. On navigation, move focus to the main landmark / page `<h1>` and announce via a shared live-region primitive — App-Router route changes don't move focus by default (the base a11y rule, bound to server-first).

## Forms & schemas

**Zod** is the schema library for form and API-response shapes; a shape shared with the NestJS edge is defined once and reused on both sides (see *Controller ring* in `./backend.md` and the validation note in the pack README). Client form validation and `services/server/` response validation both run against the shared schema.

## Internationalisation

Base parity rule + CI key-parity check stand unchanged. App-Router binding: load the active locale's dictionary **server-side per request** and pass it down — keep other languages out of the client bundle. Pin locale to a route segment (`app/[locale]/`) so the parity CI has one shape to assert. No i18n library mandated; whatever is chosen must preserve the parity check.

## Versioning / build identity

Next handles deployment skew for assets/RSC (deployment IDs, asset versioning, RSC re-fetch on navigation), so the base "cached SPA bundle" model largely doesn't apply (→ register). Still render the visible `v<version>` banner from `apps/frontend/package.json` at build. Add a dismissible "Refresh to update" prompt **only for the residual long-lived-session / installed-PWA case** — don't hand-roll a `version.json` poll by default, and don't disable Next's built-in chunk-recovery to honour "never force a reload" (an unrecoverable `ChunkLoadError` may take a one-time reload).

## Testing (stack-additive)

The base already requires asserting behaviour over implementation — not repeated. Additions: test **data-access / Server Actions** with the NestJS API mocked at the network edge (assert request shape, auth + correlation-id forwarding, and revalidate behaviour); test the four-state + `not-found` + `global-error` segment files; assert parameterized hrefs resolve through the `routes` helper.

## Add-on bindings (if adopted)

- **premium-design** (`add-ons/premium-design/`): motion primitives are atoms/molecules driven by duration/easing tokens — CSS transitions/keyframes by default, so purely-presentational motion keeps Server Components server; an animation library (e.g. `motion`) enters only at a `'use client'` interaction leaf when a sequence outgrows CSS, recorded per the base dependency rule. Scroll reveals go through one shared IntersectionObserver hook (client leaf). Fonts via `next/font`; imagery via `next/image`. Honour `prefers-reduced-motion` by collapsing the duration tokens under the media query.
- **multi-tenancy** (`add-ons/multi-tenancy/`): the active organisation is a route segment — an `app/(org)/[organisationId]/` layout owns every organisation-scoped page; Server Components read the id from `params` and fetch through organisation-scoped service calls (the backend re-validates membership on every request). The switcher is a nav control in that layout fed by the memberships endpoint; switching navigates to the other organisation's URL, and the segment remount is the state reset — never keep organisation-scoped data in a client store that survives the segment, and never key client caches without the organisation id.

## Conflict register

- **Base says:** `apps/frontend` is "the single-page app" (also root `CLAUDE.md` and `README.md`). **In this stack:** it is server-first Next.js App Router, not a client-rendered SPA — the State, boundary, primitives, and versioning bindings all inherit from this one resolution. **Because:** the chosen stack is App Router. **Concretely:** default every component to server; add `'use client'` only at an interaction leaf. (Root files are softened on day 1 per the README; the repo name stays stale.)
- **Base says:** "all network access lives in `services/`," implying client-side fetch. **In this stack:** Server Components / Server Actions fetch server-side through `services/`, which calls the NestJS API. **Because:** server-first moves fetching to the server. **Concretely:** no `fetch`/`axios`/SDK call in a Client Component — props or a service call only.
- **Base says:** every route lives in "one central registry `routes.<ext>`," and you build URLs through it. **In this stack:** routing is file-system based (`app/`), which *is* the registry; a `routes` link-helper replaces hand-built URLs, so `routes.<ext>` is dropped. **Because:** App Router is file-system routed. **Concretely:** resolve every link through the `routes` helper — never a raw URL string literal; don't recreate a route→URL table (the base already forbids a second one).
- **Base says:** the client `store/` "owns application state" and may front service data. **In this stack:** server data is server state (the per-request render, passed as props); the client `store/` holds only client/UI/optimistic state, and mutations flow Client Component → Server Action, not through a store slice. **Because:** server-first. **Concretely:** do not copy server-fetched data into a `store/` slice, and don't wire a store in front of a mutation out of base habit.
- **Base says:** "a deployed SPA is cached, so a user can sit on a stale bundle" (poll `version.json` / new service worker). **In this stack:** Next handles deployment skew for assets/RSC. **Because:** App Router re-fetches RSC on navigation and versions assets per deployment. **Concretely:** ship only the visible `v<version>` banner; add a refresh prompt only for long-lived/PWA sessions, never a default `version.json` poll.
