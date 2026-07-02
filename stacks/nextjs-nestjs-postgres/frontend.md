# Next.js (App Router) frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to Next.js (App Router, server-first). Read the base first. Backend hop → `./backend.md`; data layer → `./db.md`.

## Binding at a glance

- **Rendering model:** App Router, **server-first** — not a client-rendered SPA (register). A file is a Server Component unless it opens `'use client'`; reach for a Client Component only at an **interaction leaf** (`useState`/`useEffect`/`onClick`/browser APIs), directive placed leaf-ward — never on a page/layout "to be safe" (lifting it forces the whole subtree to the client).
- **Headless foundation:** **Radix UI**, wrapped as atoms. Swap to another headless lib (Headless UI, Ark, React Aria) only by recording it in `apps/frontend/CLAUDE.md`; never mix two.
- **Schemas:** **Zod** for form and API-response shapes, shared with the NestJS edge and defined once (pack README); form validation and `services/server/` response validation both run against it.
- **Language:** JS or TS, project's choice — one language per app. `JS:` use `jsconfig.json` for path aliases; Server Actions and `'use client'` need no extra transform (the Nest Babel setup is backend-only).

## Structure (base `src/` shape → App Router)

App location is pinned to `src/app/`; colocated non-route code lives elsewhere under `src/`. Each base layer keeps its meaning; only its home moves — feature-slice grouping unchanged.

| Base layer | Here |
|---|---|
| `pages/` | `src/app/` route segments — `page`, `layout`, `loading`, `error`, `not-found`, `global-error`. "Pages hold no business logic, compose organisms" applies to `page.*`. |
| `store/` | `src/store/` — client state only (register). |
| `services/` | `src/services/{server,client}/` — split by execution context; Server Actions in dedicated `_actions`/`action.*` files, separate from `server/` data-access. |
| `components/*` tiers | unchanged (atomic tiers per base); interactive vs presentational split: see *Primitives, layout & tokens*. |
| `i18n/`, `lib/`, `tokens.<ext>` | unchanged; tokens consumed server-safe (see *Primitives, layout & tokens*). |
| `routes.<ext>` | replaced by the `app/` tree + a `routes` link-helper (register). |

Next `layout` files are the base's single shared layout (the frame); `page` files supply content.

## Data access

- **Network access still lives in `services/`** — the fetch *sites* move server-side. Server Components call `services/server/`; Client Components mutate via a Server Action (default) or `services/client/`. Forbidden: ad-hoc `fetch()`/`axios`/SDK calls inlined in a component (grep smell).
- **State home — URL → Server → Client.** URL (route segment / search params) for anything navigable or shareable; server data is the per-request Server Component render — Next 15+ is uncached-by-default, so opt into caching explicitly per call (`cache`/`next.revalidate`); client `store/` holds only genuinely client UI/ephemeral/optimistic state. Never copy server data into a `store/` slice.
- **Mutations:** Client Component → Server Action → `revalidatePath()`/`revalidateTag()` for the affected data — a write that changes user-visible data without revalidation is a bug. A `'use server'` file exports only async functions; keep actions out of `services/server/` data-access files. `services/client/` direct calls only when an action can't serve (e.g. optimistic UI needing the response inline); justify in the PR.

### Next-server → NestJS boundary

`services/server/` wraps fetch to the NestJS `/internal/v1` API: one base-URL config, forwards auth (cookies/headers from the request), and propagates the correlation id across the hop. A Server Component never reaches the DB — it goes through the API (hard rule: `./db.md`). Validate responses with the shared Zod schema so a contract break surfaces as a typed error feeding the base `error` state.

## Routing

The `app/` tree is the route registry, and the internal-path → URL mapping is the filesystem — keep no duplicate table (register).

- **Build parameterized hrefs through a `routes` link-helper** (`src/lib/routes.*`): one named builder per parameterized segment (`routes.order(id)` → `/orders/${id}`), keyed off the `app/` tree. Links and redirects resolve through it — never a raw URL string literal; static routes may use literal hrefs.
- `<Link href>` is the default navigation primitive; `useRouter().push`/`redirect()` for programmatic cases. Route groups `(group)/` keep org-only folders out of the URL; `_folders` colocate non-route code. `typedRoutes` is TS-only and optional.

## Four data states → App Router files

Segment files stay thin and delegate to shared `atoms/`/`molecules/` primitives.

- **Loading** → `loading.*` + `<Suspense>` streaming, falling back to a shared `<Skeleton>`/`<Spinner>` — no hand-rolled spinner state where a `loading.*` boundary belongs.
- **Error** → `error.*` — **must be a Client Component**; catches errors from its own segment + children (put a boundary at the parent segment to catch a sibling `layout.*`); wires `reset()` into the shared `<ErrorState>` retry and surfaces the correlation id. Throw on a failed fetch/action so the boundary catches it; never catch-and-render an error string inline.
- **Root-layout errors** → `error.*` does not catch them; add `global-error.*` at app root (renders its own `<html>`/`<body>`, still showing the shared `<ErrorState>`).
- **Empty** → shared `<EmptyState>` primitive. **Not-found** → `not-found.*` + `notFound()` for missing resources.

## Primitives, layout & tokens

- Interactive atoms/molecules (`<Button>`-with-handler, `<Modal>`, `<Combobox>`) carry `'use client'`, and that is correct — Radix and most headless libs are client-only. **Never hand-roll a server-only control to dodge `'use client'`** — that re-drops the accessibility the base requires. Purely-presentational atoms/molecules may stay Server Components.
- **Tokens must be consumable by Server Components without a client runtime** — CSS variables / a Tailwind theme / a static token module; a runtime CSS-in-JS lib that forces `'use client'` at the token boundary is disallowed. Map the base shared layout onto Next root/segment `layout` files; declare global tokens once on `:root` in the root layout.
- **Boundary hygiene:** only RSC-serializable props cross into a client leaf (primitives, plain objects, `Date`/`Map`/`Set`/`BigInt`, Server Action refs) — not functions or class instances. Format a date on **one** side via the shared date helper with timezone/locale pinned — an unpinned date format is the canonical App-Router hydration bug. On navigation, move focus to the main landmark / page `<h1>` and announce via a shared live-region primitive — App-Router route changes don't move focus by default.

## Internationalisation

Load the active locale's dictionary **server-side per request** and pass it down — keep other languages out of the client bundle. Pin locale to a route segment (`app/[locale]/`) so the base key-parity CI has one shape to assert. No i18n library mandated; whatever is chosen preserves the parity check.

## Versioning / build identity

Next handles deployment skew for assets/RSC (register). Still render the visible `v<version>` banner from the package manifest at build. Add a dismissible "Refresh to update" prompt **only** for the residual long-lived-session / installed-PWA case — no default `version.json` poll, and don't disable Next's built-in chunk recovery (an unrecoverable `ChunkLoadError` may take a one-time reload).

## Security bindings

The base owns the header rules and CSP rollout (report-only → enforce; allow-list only real origins). Mechanism: `headers()` in `next.config.*` emits `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (or a CSP `frame-ancestors` directive), `Referrer-Policy`, and `Content-Security-Policy-Report-Only` first — promoted to the enforcing `Content-Security-Policy` once violation reports are clean.

## Testing (stack-additive)

Test data-access / Server Actions with the NestJS API mocked at the network edge — assert request shape, auth + correlation-id forwarding, and revalidate behaviour. Test the four-state + `not-found` + `global-error` segment files. Assert parameterized hrefs resolve through the `routes` helper.

## Conflict register

- **Base says:** `apps/frontend` is "the single-page app" (also root `CLAUDE.md`, `README.md`), with client-side fetching implied. **In this stack:** server-first App Router — components default to server, and `services/` fetch sites run server-side (Server Components → `services/server/`, mutations → Server Actions). **Because:** the chosen stack is App Router. **Concretely:** DO default every component to server, adding `'use client'` only at an interaction leaf; DON'T put a `fetch`/`axios`/SDK call in a Client Component.
- **Base says:** every route lives in one central registry `routes.<ext>`, and URLs are built through it. **In this stack:** routing is file-system based — the `app/` tree *is* the registry; a `routes` link-helper replaces hand-built URLs; `routes.<ext>` is dropped. **Because:** App Router is file-system routed. **Concretely:** DO resolve every parameterized link through the `routes` helper — never a raw URL string literal; DON'T recreate a route→URL table.
- **Base says:** the client `store/` owns application state and may front service data. **In this stack:** server data is server state (the per-request render, passed as props); `store/` holds only client/UI/optimistic state, and mutations flow through Server Actions, not store slices. **Because:** server-first makes the per-request render the data's home. **Concretely:** DON'T copy server-fetched data into a `store/` slice or wire a store in front of a mutation out of base habit.
- **Base says:** a deployed SPA is cached, so detect a stale bundle (poll `version.json` / react to a new service worker) and prompt to refresh. **In this stack:** Next handles deployment skew — per-deployment asset versioning, RSC re-fetch on navigation. **Because:** the stale-bundle model largely doesn't apply. **Concretely:** DO ship only the visible `v<version>` banner; DON'T add a default `version.json` poll — a refresh prompt only for long-lived/PWA sessions.
