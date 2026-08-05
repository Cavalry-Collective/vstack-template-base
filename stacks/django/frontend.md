# React SPA over Django: frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the frontend to React, TypeScript, Vite, React Router, and the Django API.

## Bindings

| Concern | Binding |
|---|---|
| Rendering | client-only SPA; no SSR or prerendering |
| Routing | React Router library mode in `src/routes.tsx` |
| Data | relative `/api` calls through `services/http.ts` |
| Contract | drf-spectacular OpenAPI to openapi-typescript |
| State | React Context by domain |
| Styling | Tailwind CSS 4; UI foundation per the base's *UI component approach* (this pack defaults to Radix UI) |
| Tests | Vitest, React Testing Library, Playwright |

Everything exposed through `VITE_*` is public. Parse frontend configuration once with Zod.

## Rendering and routing

- Emit one `dist/index.html` shell with hashed assets.
- Mount with `createRoot(...).render(...)`.
- Keep React Router in library mode. If adopting framework mode, set `ssr: false`.
- Keep route objects and parameterised link helpers in `src/routes.tsx`.
- Load screens through route-level `lazy`.
- Do not add Next.js, Server Component directives, server render APIs, hydration, prerender plugins, or frontend server files.
- Change packs or use a separate public origin when a requirement needs server-rendered HTML.

## Data and deployment edge

- Generate types from the backend OpenAPI document.
- Call relative `/api` paths through one fetch wrapper.
- Read Django's `csrftoken` cookie and send `X-CSRFToken` on mutations.
- Parse responses and map failures to `ApiError { code, status, message, correlationId }`.
- Proxy `/api` to Django's `/internal/v1` in Vite development and the deployed serving layer.
- Configure a catch-all to `index.html` in the deployed serving layer.
- Configure security headers there, with CSP report-only before enforcement.

## UI, version, and testing

- Declare tokens through Tailwind 4 `@theme`.
- Wrap the UI foundation chosen in the base's *UI component approach* as atoms; default that choice to Radix primitives.
- Self-host fonts and keep one `cn()` helper.
- Inject and render `VITE_APP_VERSION`.
- Serve `version.json` with `no-store` and show a dismissible refresh prompt when it changes.
- Offer an explicit reload when an old lazy chunk no longer exists.
- Test stores, services, helpers, and component states with Vitest and React Testing Library.
- Run Playwright at desktop and mobile widths.
- Request a deep link directly to verify the deployed SPA fallback.

## Conflict register

_No conflicts — this appendix only adds bindings; the base contract is unchanged._
