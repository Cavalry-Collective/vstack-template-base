# Frontend

The frontend contract. Read this before touching anything under `apps/frontend/`. Repo-wide rules (principles, worktree workflow, cross-app standards) live in the root `CLAUDE.md`; this file governs how the single-page app itself is structured.

The frontend is organised along **two axes that never blur**: horizontal **layers** (what a piece of code *is* — store, service, page, component) and vertical **feature slices** (what business capability it serves).

## Project structure

Mirror this shape under `apps/frontend/src/`. It is **illustrative**: the toolchain is not yet chosen (see the root `CLAUDE.md`), so treat file extensions and framework specifics as examples, not mandates.

```
src/
  store/               # state layer — one slice per domain
  services/            # API clients — each domain mirrors a backend route group
  pages/               # screens — compose feature components, hold no business logic
  components/
    ui/                # shared base primitives (built ON TOP of the UI library)
    <feature>/         # feature components, grouped by business capability
  i18n/                # one dictionary per language
  lib/                 # genuinely shared, side-effect-light helpers
  routes.<ext>         # the single central route registry
  tokens.<ext>         # the single design-token source
```

Group by **business capability first** inside `components/` and `store/`: a feature's components, state, and styles live together so a slice can be understood, changed, and removed as a unit. Promote code into `ui/` or `lib/` only once it is genuinely shared across features — not in anticipation of reuse.

## Layering

Each layer has one job, may depend only on the layers beneath it, and must never reach upward.

- **Store (`src/store/`)** — owns application state, one slice per domain. May depend on services. Must never import a page or render anything.
- **Services (`src/services/`)** — own all data fetching and mutation; each domain mirrors a backend route group. **All network access lives here**, never scattered across presentational components. May depend on `lib/`. Must never hold view state.
- **Pages (`src/pages/`)** — compose feature components into a screen. **Hold no business logic;** they wire data from store/services into components. Must never fetch directly or embed reusable UI inline.
- **Feature components (`src/components/<feature>/`)** — compose smaller primitives into a capability. May use `ui/` and `lib/`. Must never be imported by a primitive.
- **Shared primitives (`src/components/ui/`)** — the reusable base. May depend only on the UI library and the design tokens. Must never know about a specific feature or page.

Cross-cutting rules for every layer:

- **Loading / error / empty / success states are handled consistently** — the same four states, presented the same way, on every data-backed screen.
- **Don't accumulate one-off helpers in `src/lib/`** — co-locate a helper with its only caller until reuse actually appears.

## URL routing

A route is part of the app's public contract; an internal file path is an implementation detail. **Keep the two separate.** Browser URLs stay clean and human-meaningful and **never expose internal build/source paths** (no `/src/` or `/pages/` prefix in the address bar).

- **One central registry.** Every route lives in a single routing config (`routes.<ext>`), registered the moment its page is created — never ship a page without its route entry. One place to read the whole routing surface, one place to change it.
- **Build URLs through the registry, never by hand.** Resolve links and redirects from named routes, not by concatenating path strings — so internal structure can never leak into a URL, and renaming a route updates every link at once.
- **Keep the mapping reviewable.** Maintain an up-to-date `internal path → browser URL` table in this file so the routing surface is auditable at a glance.

```
| Internal path   | Browser URL |
|-----------------|-------------|
| pages/index     | /           |
| pages/login     | /login      |
| …               | …           |
```

## Page layout & design tokens

Consistency is a system, not a per-page effort. Two things make every screen feel like one product: a **single shared layout** and a **single token source**. A page author composes the layout and reaches for tokens — and never re-decides spacing, colour, or navigation.

**One shared layout.** Every page builds on common layout components that supply the standing furniture — header / navigation, page chrome, safe-area and bottom-nav clearance, consistent gutters and background. The page provides its content; the layout owns the frame. Don't hand-roll a page shell.

**One token source, three tiers.** All spacing, colour, typography, radius, and elevation come from a single design-token source, never hardcoded per page. Structure tokens in three layers so they stay coherent and themeable:

1. **Primitive tokens** — raw, context-free values (`--color-blue-600`, `--space-4`).
2. **Semantic tokens** — decisions that map primitives to meaning (`--color-bg`, `--gutter-screen`, `--bottom-nav-clearance`). Components reference *these*.
3. **Component tokens** — per-component overrides, where a component genuinely needs them.

Pages and components consume **semantic** tokens; they never reach past them to a raw primitive value.

## Shared primitives — never build one-offs

Visual and behavioural consistency comes from **reuse**, not from discipline repeated per screen. Build the UI in three tiers and never skip one:

1. **Foundation** — unstyled, behavioural primitives from a headless UI library (focus management, accessibility, and keyboard handling solved once).
2. **Wrapper** — a thin layer mapping the project's tokens and conventions onto that foundation: `<Button>`, `<Input>`, `<Modal>`, `<PageHeader>`. This is `components/ui/`.
3. **Composition** — feature components assembled from the wrappers above.

- **Use the shared primitive for every page that needs it.** A page that needs a nav bar uses `<PageHeader>`. **Never build a one-off header** — or button, input, modal, table, or icon button; reach for `components/ui/`.
- **A shared primitive must be genuinely reusable** (decoupled from any one page); a page-specific component must not be prematurely generalised.
- **Wrap from the start; don't defer.** Route every screen through the wrapper layer even before a component is widely reused, so a later change to behaviour or tokens lands everywhere at once.

## Internationalisation (if multilingual)

Treat one language as the **reference** and keep every other language in exact parity with it.

- Dictionaries live under `src/i18n/`, one per language.
- **Add every new key to every language file in the same change** — never let dictionaries drift.
- **Run a key-parity check in CI** that fails on any key missing from a locale *or* present in a locale but absent from the reference. Both directions are drift.
- **Name keys by meaning, not location** (`order.confirm_button`, not `page3.btn`), so a key survives a screen being moved or redesigned.

## Coding standards

- **Never reimplement what the UI library already gives you.** Typography, buttons, inputs, and the like are **built on top of the chosen UI library** — wrapped through `components/ui/`, never hand-rolled from scratch. A bespoke `<Button>` that duplicates the library's is the canonical mistake: it fragments styling, drops the accessibility the library solved, and drifts over time. Build on the foundation; don't rebuild it.
- **Cross-cutting concerns belong in shared hooks / services**, not duplicated per screen. Wrap repeated API / auth / error-reporting plumbing once and reuse it; don't copy-paste it into every page.
- **Don't accumulate one-off helpers in `src/lib/`.** Co-locate a helper with its only caller until reuse actually appears; `src/lib/` is for genuinely shared, side-effect-light code.
- **Use libraries instead of hand-rolling — especially for dates.** Date math is the canonical AI failure mode (timezones, DST, month-end, locale). Don't write `new Date(...).toISOString().slice(0,10)` or hand-rolled offset arithmetic; reach for a real date library and a single shared helper. Likewise use established libraries for phone canonicalisation, CSV, UUIDs, and schema validation. If the right library isn't a dependency yet, propose adding it before rolling your own — don't reinvent `dayjs`, `zod`, `uuid`, and friends.

## Versioning / build identity

The running build must be **identifiable** and **updatable** — a deployed SPA is cached, so a user can sit on a stale bundle indefinitely after a release.

- **Make the version visible.** Render an inconspicuous `v<version>` tag somewhere unobtrusive (e.g. the login footer), sourced from `apps/frontend/package.json` at build time. Bump the version on every release (semver) so the deployed build is identifiable at a glance.
- **Give users a way off a stale bundle.** Detect when the running build differs from the deployed one (e.g. poll a build-stamped `version.json`, or react to a new service worker), then **prompt** — show a dismissible "Refresh to update" banner. Let the user choose when to reload; never force a reload that could interrupt work in progress.
