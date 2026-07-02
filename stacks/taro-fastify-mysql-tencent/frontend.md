# Taro 4 H5 — frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/frontend/CLAUDE.md` to **Taro 4 (H5 target, React 18, plain JavaScript)**, built to static assets and **served by the backend** (`@fastify/static`) — one origin, REST against `./backend.md`. Taro H5 *is* the base's client-rendered SPA, so most of it binds unchanged.

## Binding at a glance

- **Taro 4, H5 target only** — no Mini Program targets. React 18 function components, plain JS/JSX (no TypeScript; `typecheck` is a no-op).
- **State: Zustand** — one store slice per domain under `src/store/` (the base store rule; Zustand is the mechanism); slices may call services, never import a page or render.
- **Data flow: REST-only through `src/services/`** — each module mirrors a backend route group over one `services/api.js` fetch wrapper injecting `x-tenant` + session credentials and mapping the error envelope to a typed error for the base *error* state. Built **same-origin** (`TARO_APP_API_BASE=/api`) — cookies first-party, CORS never enters.

## Structure

The base atomic folders — `components/{atoms,molecules,organisms,templates}/`, `pages/<name>/index.jsx` as the pages tier — apply unchanged. The DRY gate and "never hand-roll a primitive" hold as-is (the shared `<PageHeader>` for every nav bar).

## Routing — two Taro surfaces

The base single route registry binds to **two** Taro files that change together — no `routes.<ext>`:

- **`src/app.config.js`** registers every page path (`pages/<name>/index`); an unlisted page **does not exist**.
- **`config/index.js` → `h5.router.customRoutes`** maps each internal path to its clean URL (`/pages/login/index` → `/login`) — the base "URLs never expose internal build paths" rule.

Add both entries the moment a page is created (register below).

## Navigation chrome & the Taro H5 router

Each bullet binds a base *Navigation chrome, overlays & scroll* rule.

- **Compare routes against the customRoute *alias* (`/home`), never `/pages/home/index`** — Taro stores H5 router state under the clean URL; an internal-path check silently never matches.
- **Portal anything that must survive navigation to `document.body`** — keep-alive tab views, the global bottom nav, overlays/sheets. Taro's router stylesheet hides any `.taro_page` not `:last-child` of `.taro_router` — a persistent sibling shell blanks deep pages; the base "portal fixed chrome" rule is *mandatory* here.
- **`Taro.redirectTo` collapses the stack and *skips* the enter transition** (stamping `taro_page_show` + `taro_page_stationed` synchronously). Tab switches use `redirectTo` for a 1-deep stack; a custom switch animation means your own keyframes, with all `position: fixed` chrome portalled **outside** the transformed subtree (base rule).
- **Taro H5 `pushState` fires no navigation event** — patch `history.pushState`/`replaceState` once to emit one; drive all chrome (nav visibility, active tab, keep-alive pane) off one reactive `usePathname` on that event + `popstate`.
- **Capital `Px` opts a pixel value out of `postcss-pxtransform`** (e.g. matching Taro's prebuilt-component sizes); lowercase `px` is rem-rescaled and drifts against the built-ins.
- **Re-implement a Taro built-in (e.g. pull-to-refresh) when the real scroll container is a body-portalled shell** Taro can't detect — it silently won't attach.

## Tokens & styling

- **`src/styles/tokens.css` mirrors the confirmed design guide** (base *Design guide*) — confirm the guide first, then carry its values over, converting oklch→hex (below).
- **One token source: `src/styles/tokens.css`** (CSS variables), three tiers per the base; consume semantic tokens only.
- **Author colours as hex, not oklch.** In-app WebViews and older Android Chromium this build targets don't render `oklch()` — an oklch token silently drops the colour; a real H5 constraint, not a preference.

## Responsive layout

Base *Responsive layout* rules, bound to H5 idioms:

- **Mobile-first is the native posture** — author base styles at the narrowest width, scale up with `min-width` queries. The viewport meta and `env(safe-area-inset-*)` insets are the shared layout's job (base rule).
- **Taro rewrites `px`→`rem` via `postcss-pxtransform`** — author in `px` and let it convert (opt-outs: *Navigation chrome*).
- **Full-height surfaces: `100dvh` with a `100vh` fallback; scrollable input pages: `min-height`** (see the register).
- **Wide content scrolls in its own `overflow-x:auto` box** — the page never scrolls sideways; atomic values (phone numbers, codes) get `white-space: nowrap`.

## Video — VOD + HLS

An addition (no base rule): upload with **`vod-js-sdk-v6`** using a short-lived signature from the backend `/vod/*` route (the permanent signer key stays backend-side — `./infra.md`); play HLS via **`hls.js`**. Transcode is VOD's job; clients upload direct to VOD, never through the backend.

## Versioning / build identity

The base version.json approach **stays** — nothing else handles bundle skew for this cached, statically served bundle: emit a build-stamped `version.json`, poll it cache-busted on launch/foreground, show a dismissible "Refresh" banner on a differing build, plus the visible `v<version>` tag from `apps/frontend/package.json`. The app is a PWA (install banner); `version.json` is served `no-store`.

## i18n & test-mode sign-in

- **i18n** (base rule): en/zh dictionaries under `src/i18n/`; CI **`i18n:check`** enforces key parity both directions; name keys by meaning.
- **Test-user picker** (**test-mode**, if adopted — `add-ons/test-mode/`): a one-tap picker on the login screen, fed by a `test`-tenant-gated unauthenticated endpoint that returns empty in `production`; gate it on the backend's own `x-tenant: test` signal.

## Security bindings

- **H5 security headers come from the backend** — the Fastify process serving the bundle sends the hardening set + CSP via `@fastify/helmet` (`./backend.md` *Security bindings*); the Taro build carries no header config, EdgeOne adds none. A new asset origin (COS media, VOD/HLS) extends the backend CSP allow-list, never `*`.
- **No secrets in the bundle, bound:** every `TARO_APP_*` value compiles into public client code; the VOD signer key and COS credentials stay server-side behind the signing routes.

## Testing

Run the `e2e/` Playwright workspace mobile-first with `x-tenant: test`; a phone-device project makes the four-state specs exercise narrow width (base narrow-viewport check). Store slices, services, organisms: base rules unchanged.

## Conflict register

- **Base says:** every route lives in one central registry `routes.<ext>`; URLs are built through it. **In this stack:** split across **two** files — `app.config.js` (page registration) and `config/index.js` `customRoutes` (internal path → clean URL) — no single `routes.<ext>`. **Because:** Taro owns page registration in its config and maps H5 URLs separately; one registry means fighting the framework. **Concretely:** DO add both entries when creating a page and audit routing by reading the pair; DON'T maintain a third route→URL table; DON'T hand-concatenate `/pages/...` paths into a browser URL.
- **Base says:** size full-bleed sections to content, never `100vh`; prefer `svh` when something must fill the viewport, `dvh` only to deliberately track browser chrome. **In this stack:** full-height surfaces use **`100dvh` with a `100vh` fallback**. **Because:** app-shell surfaces should fill whatever viewport is visible — tracking the chrome is wanted — and older in-app WebViews need the `100vh` fallback where dynamic units are unsupported. **Concretely:** DO declare `height: 100vh` then override with `height: 100dvh`; DON'T ship a bare `100vh`/`inset: 0` sheet (it clips or overflows as the iOS toolbar toggles); DON'T use `100dvh` on ordinary scrollable pages — those use `min-height`.
