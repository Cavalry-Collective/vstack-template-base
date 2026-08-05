# Next.js App Router: frontend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the frontend to server-first Next.js App Router. Use JavaScript or TypeScript consistently within the app.

## Rendering and structure

- Default every component to a Server Component.
- Add `'use client'` only at the smallest interactive leaf.
- Map base pages to `src/app/` route segments.
- Keep stores, services, components, `lib/`, and `i18n/` under `src/`.
- Split services into `services/server/` and `services/client/`.
- Keep Server Actions in dedicated action files that export only async functions.
- Use `jsconfig.json` for aliases in a JavaScript app.

## Routing

- Treat the `app/` tree as the route registry.
- Build parameterised paths through `src/lib/routes.*`.
- Allow literal static paths.
- Use `<Link>`, `redirect()`, or `useRouter()` for navigation.
- Do not maintain a second route table.

## Data and state

- Keep network access in services.
- Fetch normal screen data through `services/server/`.
- Call Nest's `/internal/v1` API rather than importing Prisma or reaching the database.
- Forward authentication and correlation headers across the Next-to-Nest hop.
- Validate responses with the shared Zod schema.
- Put shareable state in the URL.
- Keep normal server data in the Server Component render.
- Keep only ephemeral, optimistic, or genuinely client-owned state in `store/`.
- Mutate through Server Actions by default and revalidate affected paths or tags.
- Use `services/client/` only when an action cannot support the interaction.

## App Router states

- Use `loading.*` and `<Suspense>` for loading.
- Use client `error.*` boundaries with the shared error component and correlation ID.
- Add `global-error.*` for root-layout failures.
- Use the shared empty state.
- Use `not-found.*` and `notFound()` for missing resources.

## UI bindings

- Wrap the UI foundation chosen in the base's *UI component approach* as atoms; default that choice to Radix UI primitives.
- Keep interactive primitives as client leaves.
- Use CSS variables, Tailwind, or a static token module that Server Components can consume.
- Do not use runtime styling that forces the token boundary into a Client Component. This rules out a styled kit built on runtime CSS-in-JS; a kit that compiles to static CSS is fine.
- Pass only React-serialisable values into client leaves.
- Format dates on one side of the boundary with an explicit locale and timezone.
- Move focus to the main landmark and announce route changes.

## Forms, i18n, and version

- Use Zod for forms and API responses.
- Share schemas with the Nest controller edge where the shape is genuinely identical.
- Load the active dictionary on the server by locale route segment.
- Keep the base dictionary parity gate.
- Render the package version.
- Rely on Next deployment skew handling; add a refresh prompt only for a real long-lived or PWA requirement.

## Testing

- Test server services and actions with the Nest API mocked at the network boundary.
- Assert authentication and correlation forwarding.
- Assert mutation revalidation.
- Test loading, error, empty, missing, and global-error boundaries.
- Test parameterised path helpers.
- Run Playwright at the primary and minimum supported widths.

## Conflict register

- **Base says:** the frontend is a client-rendered SPA. **In this stack:** it is a server-first Next.js application. **Because:** App Router is the selected rendering model. **Concretely:** default to Server Components and place `'use client'` only on interactive leaves.
- **Base says:** routes live in one central registry. **In this stack:** the `app/` tree is the registry and a helper builds parameterised paths. **Because:** App Router uses filesystem routing. **Concretely:** build parameterised links through the helper; DON'T create a route table.
- **Base says:** the client store owns application and service state. **In this stack:** normal server data stays in Server Components; the store holds only client state. **Because:** server-first rendering already owns the request data. **Concretely:** DON'T copy server-fetched data into a store slice.
- **Base says:** a cached SPA should poll build identity. **In this stack:** Next handles asset and RSC deployment skew. **Because:** this is not a static SPA bundle. **Concretely:** render the version only; DON'T add default `version.json` polling.
