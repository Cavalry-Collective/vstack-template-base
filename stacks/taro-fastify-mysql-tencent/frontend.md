# Taro 4 H5 — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **Taro 4 (H5 target, React 18, plain JavaScript)**, built to static assets and **served by the backend** (`@fastify/static`) so the browser talks to one origin. Consumes the Fastify backend (`./backend.md`) over REST. Read the base file first; Taro H5 *is* the client-rendered SPA the base assumes, so most of the base binds unchanged — this adds only the Taro-specific bindings and the marked overrides.

## Stack binding at a glance

- **Taro 4, H5 target only** — no Mini Program targets active. React 18 function components, plain JS/JSX (no TypeScript; `typecheck` is a no-op).
- **State: Zustand** — one store slice per domain under `src/store/` (the base *Layering* store rule; Zustand is the mechanism). Slices may call services; never import a page or render.
- **Data flow: REST-only through `src/services/`** — each module mirrors a backend route group over a shared `services/api.js` fetch wrapper that injects the `x-tenant` header + session credentials and maps the backend error envelope to a typed error feeding the base *error* state. **Same-origin:** built with `TARO_APP_API_BASE=/api`, so cookies stay first-party and CORS never enters.
- **Components follow the base atomic tiers** under `src/components/` (see *Component tiers* below).

## Routing — two Taro surfaces, kept in sync (base one-registry rule)

The base's single route registry binds to **two** Taro files that must change together; there is no `routes.<ext>`:

- **`src/app.config.js`** registers every page path (`pages/<name>/index`); a page not listed **does not exist**.
- **`config/index.js` → `h5.router.customRoutes`** maps each internal path to its clean browser URL (`/pages/login/index` → `/login`) — the base "URLs never expose internal build paths" rule.

Add both entries the moment a page is created (the base "never ship a page without its route entry"). Reading these two files together is how you audit routing — keep no third route→URL list. See the conflict register.

## Navigation chrome & the Taro H5 router

Taro's H5 router has sharp edges; each item binds a base *Navigation chrome, overlays & scroll* rule to Taro concretely:

- **Compare a route against its customRoute *alias* (`/home`), never the internal `/pages/home/index`.** Taro's H5 runtime stores router state under the clean URL, so active-tab highlighting and nav-visibility checks must match on the alias — otherwise the check silently never matches.
- **Portal anything that must survive navigation to `document.body`** — keep-alive tab views, the global bottom nav, overlays/sheets. Taro's H5 router stylesheet hides any `.taro_page` that isn't `:last-child` of `.taro_router`, so a persistent sibling shell otherwise blanks the deep pages. (This makes the base "portal fixed chrome out of transform/stacking contexts" rule *mandatory* here, not just prudent.)
- **`Taro.redirectTo` collapses the stack and *skips* the enter transition** (it stamps `taro_page_show` + `taro_page_stationed` synchronously). Tab switches use `redirectTo` to keep a 1-deep stack; if you want a switch animation you drive your own keyframes — and then all `position: fixed` chrome must live **outside** the transformed subtree (portalled), per the base rule.
- **Taro H5 `pushState` fires no navigation event.** Patch `history.pushState` / `replaceState` once to emit a custom event, and drive all chrome (nav visibility, active tab, keep-alive pane selection) off a single reactive `usePathname` subscribing to that event + `popstate`.
- **Use capital `Px` for pixel values `postcss-pxtransform` must leave alone** (e.g. matching Taro's own prebuilt-component sizes); lowercase `px` is rem-rescaled and drifts against Taro's built-ins.
- **Re-implement a Taro built-in behaviour (e.g. pull-to-refresh) when the real scroll container is a body-portalled shell.** Taro attaches such behaviours to its own page scroller and can't detect a portalled container — the built-in silently does nothing there.

## Tokens & styling (base *Page layout & design tokens*)

- **`src/styles/tokens.css` mirrors the confirmed design guide.** The base ships `design/design-guide.html` + `design/tokens.css` (base *Design guide*); confirm the guide first, then carry its token values into `src/styles/tokens.css` — converting oklch→hex on the way (next bullet).
- **One token source: `src/styles/tokens.css`** (CSS variables), three tiers per the base (primitive → semantic → component). Pages/components consume semantic tokens only.
- **Author colours as hex, not oklch.** Source design tokens may be authored in oklch, but **convert to hex** in `tokens.css`: some in-app WebViews / older Android Chromium the H5 build must run on don't render `oklch()`, so an oklch token silently drops the colour. This is a real H5-target constraint, not a preference.

## Responsive layout (Taro H5)

Binds the base *Responsive layout* rules to Taro's H5 target — the H5 idioms and anti-patterns.

- **Mobile-first is the native posture** — H5 ships to phones first; author base styles at the narrowest width and scale up with `min-width` media queries. The viewport meta and `env(safe-area-inset-*)` insets are the shared layout's job (base *One shared layout*), not a per-page concern.
- **Taro rewrites `px`→`rem` via `postcss-pxtransform` for scaling** — author in `px` and let it convert; use capital **`Px`** to opt a value out (matching Taro's prebuilt-component sizes). See *Navigation chrome & the Taro H5 router*.
- **Full-height surfaces use `100dvh` with a `100vh` fallback; scrollable input pages use `min-height`.** iOS Safari's `100vh` measures the chrome-hidden viewport, so `100vh` / `inset:0` sheets clip when the toolbar shows and overflow when it hides.
- **Wide content scrolls in its own `overflow-x:auto` box** so the page never scrolls sideways; atomic values (phone numbers, codes) are `white-space: nowrap`.
- **Test at a phone viewport.** Run the `e2e/` Playwright workspace mobile-first with `x-tenant: test`; keep a phone-device project so the four-state specs also exercise narrow width (base *Testing*).

## Component tiers (base *Component structure — atomic design*)

Use the base atomic folders — `components/{atoms,molecules,organisms,templates}/` with `pages/<name>/index.jsx` as the pages tier — unchanged; Taro imposes nothing here. The DRY gate and "never hand-roll a primitive" apply as-is (e.g. use the shared `<PageHeader>` for every nav bar).

## Video — VOD upload + HLS playback

Video is an addition (no base rule): upload with **`vod-js-sdk-v6`**, fetching a short-lived upload signature from the backend `/vod/*` route (the backend holds the permanent signer key — `./infra.md`); play HLS with **`hls.js`**. Compress/transcode is VOD's job server-side; the client uploads directly to VOD, not through the backend.

## Versioning / build identity (base rule — kept)

This stack **keeps** the base's version.json approach (contrast the `vercel` pack, where the platform handles skew): emit a build-stamped `version.json`, poll it cache-busted on launch/foreground, and show a dismissible "Refresh" banner when the running build differs — plus the visible `v<version>` tag from `apps/frontend/package.json`. The app is also a PWA (install banner); `version.json` is served `no-store`.

## Internationalisation & test-mode sign-in

- **i18n** (base *Internationalisation*): en/zh dictionaries under `src/i18n/`; the CI **`i18n:check`** enforces key parity both directions. Name keys by meaning.
- **Test-user picker** (if you adopt the **test-mode** add-on, `add-ons/test-mode/`): the login screen offers a one-tap account picker fed by a `test`-tenant-gated unauthenticated endpoint that returns empty in `production`. Keep it on the login screen, gated on the same `x-tenant: test` signal the backend uses.

## Add-on bindings (if adopted)

- **premium-design** (`add-ons/premium-design/`): motion is CSS transitions/keyframes driven by duration/easing tokens in `src/styles/tokens.css` — no animation library by default (H5 bundle weight; the base dependency rule). Scroll reveals go through one shared IntersectionObserver hook in `lib/`. Fonts are self-hosted static assets loaded with `font-display: swap`; images ship pre-sized and compressed — this stack has no runtime image optimiser. Honour `prefers-reduced-motion` by collapsing the duration tokens under the media query; keep animated values that must match Taro built-ins in capital `Px` (see *Responsive layout*).
- **multi-tenancy** (`add-ons/multi-tenancy/`): Taro's page registry can't carry the organisation as a path segment, so the active organisation lives in one persisted store slice (id + name + role), set only from the memberships endpoint; every `services/` call builds the organisation-scoped API path from that slice, and the backend re-validates membership on each request. Switching goes through an organisation-picker page whose switch action **resets every organisation-scoped store slice before writing the new id** — no cached list, draft, or detail survives a switch. Show the current organisation name in the app shell so the tenant context is always visible. (The `x-tenant` header here is the test-mode signal, not this add-on's tenant — see `backend.md`.)

## Conflict register

- **Base says:** every route lives in one central registry `routes.<ext>`, and URLs are built through it. **In this stack:** Taro splits it across **two** files — `app.config.js` (page registration) and `config/index.js` `customRoutes` (internal-path → clean-URL) — with no single `routes.<ext>`. **Because:** Taro owns page registration in its own config and maps H5 URLs separately; there is no place to collapse them into one registry without fighting the framework. **Concretely:** DO add both entries when creating a page and treat the pair as the routing surface to audit; DON'T maintain a third route→URL table (the base already forbids a second one), and DON'T hand-concatenate `/pages/...` paths into a browser URL.
- **Base says:** size full-bleed sections to content, never `100vh`; where something must truly fill the viewport prefer `svh` over `vh`, and `dvh` only to deliberately track the browser chrome (base *Responsive layout*). **In this stack:** full-height surfaces use **`100dvh` with a `100vh` fallback** (see *Responsive layout* above). **Because:** these are app-shell surfaces meant to fill whatever viewport is actually visible — tracking the browser chrome is the wanted behaviour here, not an accident — and the older in-app WebViews this H5 build targets need the `100vh` fallback where dynamic units are unsupported. **Concretely:** DO declare `height: 100vh` then override with `height: 100dvh`; DON'T ship a bare `100vh`/`inset: 0` sheet (it clips or overflows as the iOS toolbar toggles), and DON'T use `100dvh` on ordinary scrollable pages — those use `min-height`.
