# React SPA on Vercel: frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the frontend to React 19, TypeScript, Vite 7, React Router, and Vercel's static CDN.

## Bindings

| Concern | Binding |
|---|---|
| Rendering | client-only SPA; no SSR or prerendering |
| Routing | React Router library mode in `src/routes.tsx` |
| Data | relative `/api` calls through `services/http.ts` |
| State | one React Context provider per domain |
| Styling | Tailwind CSS 4, Radix UI, CSS-variable tokens |
| Configuration | Zod-parsed `VITE_*` values in `src/lib/env.ts` |
| Tests | TypeScript, Vite build, Playwright |

Everything exposed through `VITE_*` is public. Never put a secret in the frontend environment.

## Rendering

- Emit one `dist/index.html` shell with hashed JavaScript and CSS.
- Mount with `createRoot(...).render(...)`.
- Keep React Router in library mode. If adopting framework mode, set `ssr: false`.
- Do not add Next.js, React Server Component directives, server render APIs, hydration, prerender plugins, `*.server.tsx`, or a frontend `api/` directory.
- Change packs when a requirement needs server-rendered HTML.

## Routing and data

- Keep route objects and parameterised link helpers together in `src/routes.tsx`.
- Load each screen through its route object's `lazy` property.
- Use `<Link>` for navigation and the helpers for parameterised paths.
- Do not concatenate URL paths or scatter `React.lazy` below the route.

`apps/frontend/vercel.json` must apply rewrites in this order:

1. `/api/:path*` to the API project's `/internal/v1/:path*`;
2. every other path to `/index.html`.

- Select production and staging API origins with host-conditioned literal rules.
- Let random PR hosts use the staging API unless a cross-app PR is explicitly tested against its own preview pair.
- Mirror the `/api` mapping in Vite's local proxy.
- Parse API responses with Zod and map failures to `ApiError { code, status, message, correlationId }`.
- Keep all network access in `services/`.

## UI bindings

- Map loading to router pending state and shared skeletons.
- Map route failures to `errorElement` and surface the correlation ID.
- Use the shared empty and not-found components.
- Declare semantic tokens through Tailwind 4 `@theme`.
- Wrap Radix primitives as atoms. Use `class-variance-authority`, one `cn()` helper, and `lucide-react`.
- Self-host fonts with `font-display: swap`.
- Use mobile-first utilities, container queries for reusable components, and intrinsic layout before new breakpoints.
- Keep page gutters in one `<Container>` or `<Section>` primitive.
- Reserve image dimensions and ship pre-sized responsive assets.

## Version, analytics, and headers

- Inject `VITE_APP_VERSION` from the package version and render it.
- Serve a build-stamped `version.json` with `no-store` and show a dismissible refresh prompt when it changes.
- On a failed lazy import after deployment, offer an explicit reload.
- Render `@vercel/analytics` and `@vercel/speed-insights` once in the root layout.
- Configure security headers in `vercel.json`. Start CSP in report-only mode, then enforce after reviewing violations.

## Testing

- Run TypeScript and Vite build.
- Cover every screen's states and primary flow with Playwright.
- Run desktop and mobile Playwright projects.
- Request a deep link directly to prove the SPA fallback.
- Add unit tests only when a store slice, service, or helper has branching logic worth isolating.

## Gotcha

Vercel reads `vercel.json` before the build and cannot interpolate environment variables into rewrites. Use explicit host-conditioned API origins.

## Conflict register

- **Base says:** test stores, helpers, and services as units by default. **In this stack:** the default frontend suite is typecheck, build, and Playwright; unit tests are added when isolated branching logic appears. **Because:** Playwright is the only default test that exercises the deployed proxy and SPA fallback. **Concretely:** DO cover every screen's states in Playwright; DON'T add a unit runner only to test glue.
- **Base says:** product analytics stay vendor-independent. **In this stack:** Vercel Analytics and Speed Insights are installed for platform page and performance telemetry. **Because:** these are deployment-platform signals, not the product event taxonomy. **Concretely:** keep both components in the root layout; DON'T emit product events outside the shared product-analytics service.
