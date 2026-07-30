# React SPA: frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the frontend to React, TypeScript, Vite, React Router, and a platform-neutral static host.

## Bindings

| Concern | Binding |
|---|---|
| Rendering | client-only SPA; no SSR or prerendering |
| Routing | React Router library mode in `src/routes.tsx` |
| Data | relative `/api` calls through `services/http.ts` |
| State | one React Context provider per domain |
| Styling | Tailwind CSS 4, Radix UI, CSS-variable tokens |
| Configuration | Zod-parsed `VITE_*` values |
| Tests | Vitest, React Testing Library, Playwright |

Everything exposed through `VITE_*` is public.

## Rendering and routing

- Emit one `dist/index.html` shell with hashed JavaScript and CSS.
- Mount with `createRoot(...).render(...)`.
- Keep React Router in library mode. If adopting framework mode, set `ssr: false`.
- Keep route objects and parameterised link helpers in `src/routes.tsx`.
- Load screens through route-level `lazy`.
- Do not add Next.js, Server Component directives, server render APIs, hydration, prerender plugins, or frontend server files.
- Change packs when a requirement needs server-rendered HTML.

## Serving contract

The deployment platform must provide:

1. a catch-all to `index.html`;
2. a same-origin `/api` proxy to the Express `/internal/v1` API;
3. the base security headers, with CSP report-only before enforcement;
4. `version.json` with `no-store`.

- Mirror the `/api` proxy in Vite development.
- Parse responses with Zod and map failures to `ApiError { code, status, message, correlationId }`.
- Keep all network access in `services/`.

## UI, version, and testing

- Map router pending, error, empty, and missing-resource states to the shared primitives.
- Declare tokens through Tailwind 4 `@theme` and wrap Radix primitives as atoms.
- Use mobile-first utilities, container queries for components, and one shared gutter primitive.
- Inject `VITE_APP_VERSION`, render it, and poll `version.json` for a dismissible refresh prompt.
- Offer an explicit reload when an old lazy chunk no longer exists.
- Run Vitest and React Testing Library for stores, services, helpers, and organisms.
- Run Playwright at desktop and mobile widths.
- Request a deep link directly to verify the deployed fallback.

## Gotcha

Tailwind truncation requires a `min-w-0` ancestor.

## Conflict register

_No conflicts — this appendix only adds bindings; the base contract is unchanged._
