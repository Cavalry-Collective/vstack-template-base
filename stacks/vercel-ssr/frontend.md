# Next.js full-stack UI: frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the frontend to TypeScript, Next.js App Router, Server Components, and Server Actions.

## Bindings

| Concern | Binding |
|---|---|
| Routes | `src/app/` tree plus `src/lib/routes.ts` link helpers |
| Reads | server module `controller/queries.ts` |
| Mutations | server module `controller/actions.ts` |
| Client state | React Context only for shared interactive state |
| Styling | Tailwind CSS 4, `next/font`; UI foundation per the base's *UI component approach* (this pack defaults to Radix UI) |
| Tests | TypeScript, Next build, Vitest as needed, Playwright |

Default every file to a Server Component. Add `'use client'` only at the smallest interactive leaf.

## Structure and data flow

- Map base `pages/` to App Router segments.
- Keep atoms, molecules, organisms, templates, `lib/`, and `i18n/` in their base homes.
- Replace `services/` with the server modules' controller edges.
- Build parameterised paths through `src/lib/routes.ts`; static links may remain literals.
- Read by importing server queries into Server Components.
- Mutate through Server Actions, then call `revalidatePath`, `revalidateTag`, or `router.refresh()`.
- Seed a Context provider only when an interactive subtree shares or mutates the data.
- Keep purely presentational server data in props.

Authenticated routes are dynamic because they read the session cookie. Use static or incremental rendering only for public pages.

## App Router states

- Use `loading.tsx` and `<Suspense>` for loading.
- Use `error.tsx` with the shared error component and `reset()`.
- Add `global-error.tsx` for root-layout failures.
- Use the shared empty component.
- Use `not-found.tsx` and `notFound()` for missing resources.
- Use `useActionState` pending state on the control that triggered a mutation.
- Surface the result envelope's correlation ID in error UI.

Unauthenticated queries and actions redirect to login while preserving the intended route. Authorisation failures render the forbidden state. Sign-out clears client providers.

## UI bindings

- Declare tokens through Tailwind 4 `@theme`.
- Wrap the UI foundation chosen in the base's *UI component approach* as atoms, keeping client directives at the interactive leaf.
- Default that choice to Radix primitives with `class-variance-authority`, one `cn()` helper, `lucide-react`, and `next/font`.
- Reject a styled kit that requires runtime CSS-in-JS: it pulls the token boundary into a Client Component. A kit that compiles to static CSS is fine.
- Use mobile-first utilities, container queries for reusable components, and intrinsic layout before new breakpoints.
- Keep page gutters in one shared layout primitive.
- Use `next/image` with explicit `sizes` and an aspect-ratio wrapper.

## Version, analytics, and headers

- Expose the package version as `NEXT_PUBLIC_APP_VERSION` and render it.
- Rely on Vercel and App Router deployment skew handling; do not add `version.json` polling.
- Render `@vercel/analytics` and `@vercel/speed-insights` in the root layout.
- Configure security headers through `next.config`.
- Start CSP in report-only mode and enforce it after reviewing violations.

## Testing

- Run TypeScript and `next build`.
- Cover every screen's states and primary flow with Playwright.
- Run desktop and mobile Playwright projects.
- Add Vitest only for isolated store or helper logic.

## Conflict register

- **Base says:** frontend network access lives in `services/`. **In this stack:** the application's own reads and writes use the server modules' query and action edges. **Because:** there is no internal network boundary. **Concretely:** DON'T create `src/services` or fetch the application's own origin; use controller queries and actions.
- **Base says:** routes live in one central registry. **In this stack:** the `app/` tree is the registry and `src/lib/routes.ts` provides parameterised link builders. **Because:** App Router uses filesystem routing. **Concretely:** build parameterised links with the helper; DON'T recreate a route table.
- **Base says:** the client store may own service data. **In this stack:** providers carry only data shared or mutated by an interactive subtree. **Because:** Server Components own normal server data. **Concretely:** pass display-only data as props; DON'T mirror every query into Context.
- **Base says:** a cached SPA should poll build identity. **In this stack:** Vercel and App Router handle asset and RSC skew. **Because:** this is not a static SPA bundle. **Concretely:** render the version only; DON'T add a default `version.json` poll.
- **Base says:** frontend helpers and services receive standing unit coverage. **In this stack:** Playwright is the default UI coverage and Vitest is added for real isolated logic. **Because:** business logic sits in the server onion. **Concretely:** cover screen states in Playwright; DON'T add frontend unit files only to test glue.
- **Base says:** product analytics stay vendor-independent. **In this stack:** Vercel Analytics and Speed Insights are installed for platform telemetry. **Because:** they do not replace the product event taxonomy. **Concretely:** keep both in the root layout; DON'T scatter product-event calls outside the shared product-analytics path.
