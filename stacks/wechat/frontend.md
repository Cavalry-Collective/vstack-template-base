# Taro H5: frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the frontend to Taro 4's H5 target, React 18, and plain JavaScript.

## Bindings

| Concern | Binding |
|---|---|
| Rendering | client-only H5 SPA |
| State | Zustand slices under `src/store/` |
| Data | `src/services/api.js` and relative `/api` |
| Components | base atomic tiers with Taro pages |
| Styling | CSS-variable tokens and Taro pixel transform |
| Tests | Playwright mobile-first with `x-tenant: test` |

- Keep Mini Program targets disabled.
- Inject session credentials and the `x-tenant` mode signal through the shared API wrapper.
- Map backend failures to the base error state.

## Routing

Every page needs two entries:

1. `src/app.config.js` registers the internal Taro page path;
2. `config/index.js` `h5.router.customRoutes` maps it to the browser URL.

Treat those files as one routing surface. Do not maintain a third route table or expose `/pages/...` paths in browser links.

## Tokens and layout

- Keep the confirmed design tokens in `src/styles/tokens.css`.
- Convert unsupported `oklch()` colours to hex.
- Let components consume semantic tokens rather than primitive values.
- Author mobile-first CSS.
- Let `postcss-pxtransform` convert lowercase `px`; use capital `Px` only to opt out.
- Apply safe-area insets in the shared layout.
- Use `100dvh` with a `100vh` fallback for true app-shell surfaces.
- Use `min-height` for normal scrollable pages.
- Keep wide content in its own horizontal scroller.

## Video, version, and i18n

- Upload video directly through `vod-js-sdk-v6` using a short-lived signature from the backend.
- Play adaptive HLS through `hls.js`.
- Emit `version.json` with `no-store`, poll it on launch or foreground, and show a dismissible refresh prompt.
- Render the package version.
- Keep English and Chinese dictionaries under `src/i18n/` and enforce bidirectional key parity.

## Taro H5 gotchas

- Compare routes against their clean custom-route aliases.
- Portal persistent navigation, overlays, and fixed chrome to `document.body`.
- Use `redirectTo` for tab switches and provide any switch animation yourself.
- Keep fixed chrome outside transformed animation subtrees.
- Patch `history.pushState` and `replaceState` once to emit a navigation event.
- Drive chrome from one reactive pathname hook.
- Reimplement page behaviour when Taro attached it to a hidden page scroller rather than the portalled shell.

## Conflict register

- **Base says:** routes live in one central registry. **In this stack:** Taro requires page registration and H5 URL mapping in two files. **Because:** Taro owns the two routing concerns separately. **Concretely:** add both entries for every page and audit them together; DON'T create a third route list.
- **Base says:** prefer `svh` over `vh` for a true viewport-filling surface. **In this stack:** app-shell surfaces use `100dvh` with a preceding `100vh` fallback. **Because:** the shell must track browser chrome while older embedded WebViews need the fallback. **Concretely:** declare fallback then dynamic height for shells; DON'T use bare `100vh` or dynamic height on ordinary pages.
