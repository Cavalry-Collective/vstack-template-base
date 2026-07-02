# Frontend

The frontend contract. Read this before touching anything under `apps/frontend/`. Repo-wide rules (principles, worktree workflow, cross-app standards) live in the root `CLAUDE.md`; this file governs how the single-page app itself is structured. **If a stack pack is adopted (a single directory kept under `stacks/`), also read its `frontend.md` appendix before working here** — it adds the concrete bindings, and its conflict register resolves any disagreement with this file, for that stack only.

The frontend is organised along **two axes that never blur**: horizontal **layers** (what a piece of code *is* — store, service, page, component) and vertical **feature slices** (what business capability it serves). Components themselves follow **atomic design** — see *Component structure* below.

## Project structure

Mirror this shape under `apps/frontend/src/`. It is **illustrative**: the toolchain is not yet chosen (see the root `CLAUDE.md`), so treat file extensions and framework specifics as examples, not mandates.

```
src/
  store/               # state layer — one slice per domain
  services/            # API clients — each domain mirrors a backend route group
  pages/               # screens (atomic "pages" tier) — compose organisms, no business logic
  components/
    atoms/             # smallest primitives, by type — Button, Input, Icon (on the headless lib)
    molecules/         # small compositions of atoms, by type — FormField, SearchBar, Card
    organisms/
      <feature>/       # feature-meaningful sections, grouped by feature — BidTable, SiteHeader
    templates/         # page-level layout scaffolds — the shared layout, page chrome
  i18n/                # one dictionary per language
  lib/                 # genuinely shared, side-effect-light helpers
  routes.<ext>         # the single central route registry
  tokens.<ext>         # the single design-token source
```

**Grouping is set by the tier, not by preference** (full rule in *Component structure*): `atoms/` and `molecules/` are grouped **by type** and shared globally — they carry no business vocabulary; `organisms/` are grouped **by feature** — they do. A feature's vertical slice therefore spans `store/<feature>` + `services/<feature>` + `components/organisms/<feature>`, so it can still be understood, changed, and removed as a unit. Promote code into `atoms/`/`molecules/` or `lib/` only once it is genuinely shared — not in anticipation of reuse.

## Layering

Each layer has one job, may depend only on the layers beneath it, and must never reach upward.

- **Store (`src/store/`)** — owns application state, one slice per domain. May depend on services. Must never import a page or render anything.
- **Services (`src/services/`)** — own all data fetching and mutation; each domain mirrors a backend route group. **All network access lives here**, never scattered across presentational components. May depend on `lib/`. Must never hold view state.
  - **API contract.** The backend endpoint contract (see *Endpoint contract* in `apps/backend/CLAUDE.md`) is the single source of truth for request/response shapes and status codes; the service mirrors it and never invents its own shape.
  - **Prefer a generated or shared contract artifact** over hand-copying when the toolchain supports it (e.g. an OpenAPI/JSON-schema document the backend emits and the frontend types against). When it doesn't, every contract change is one PR touching the backend endpoint *and* its mirroring frontend service together.
  - **Validate responses against the declared shape** rather than trusting them, so a contract break surfaces as a typed error (feeding the `error` state) instead of an undefined-field render.
- **Pages (`src/pages/`)** — compose organisms into a screen (the atomic *pages* tier). **Hold no business logic;** they wire data from store/services into components. Must never fetch directly or embed reusable UI inline.
- **Templates (`src/components/templates/`)** — page-level layout scaffolds (the one shared layout, page chrome) that arrange organisms with no real data. May use organisms and primitives; hold no business logic. See *Page layout & design tokens*.
- **Organisms / feature components (`src/components/organisms/<feature>/`)** — compose atoms and molecules into a feature-meaningful section. May use `atoms/`, `molecules/`, and `lib/`. Must never be imported by a primitive.
- **Shared primitives (`src/components/atoms/`, `src/components/molecules/`)** — the reusable base. May depend only on the UI library and the design tokens. Must never know about a specific feature or page.

Cross-cutting rules for every layer:

- **Loading / error / empty / success states are handled consistently** — the same four states, presented the same way, on every data-backed screen.
  - **An empty state is designed, not blank.** Every empty state states *why* there's nothing and offers the primary next action where one exists. Handle the cases distinctly — they differ in copy and CTA: first-run / never-created ("create your first X"), no-results / filtered-to-nothing (offer to clear filters or adjust the query), and access-restricted (explain the missing permission). A data-load **failure** is an error state, never an empty state — show a retry, not "nothing here".
- **Don't accumulate one-off helpers in `src/lib/`** — co-locate a helper with its only caller until reuse actually appears.

## URL routing

A route is part of the app's public contract; an internal file path is an implementation detail. **Keep the two separate.** Browser URLs stay clean and human-meaningful and **never expose internal build/source paths** (no `/src/` or `/pages/` prefix in the address bar).

- **One central registry.** Every route lives in a single routing config (`routes.<ext>`), registered the moment its page is created — never ship a page without its route entry. Reading `routes.<ext>` is the way to audit routing; do not maintain a second route→URL list anywhere else (including this file). A CI check in the spirit of the i18n key-parity check can enforce completeness.
- **Build URLs through the registry, never by hand.** Resolve links and redirects from named routes, not by concatenating path strings — so internal structure can never leak into a URL, and renaming a route updates every link at once.

## Design guide — the visual keystone (confirm before building UI)

**Lock the visual system before building any screen.** The project's visual system lives in the **design guide** (`design/design-guide.html` — "Keystone"): the design principles plus every foundation — colour, type, spacing, layout, shape, elevation, motion, iconography, states/focus, accessibility, content, data formatting — rendered live from the single design-token source (`design/tokens.css`, the seed for the app's `tokens.<ext>`). A live mirror of the tokens, not a stale screenshot. **Foundations only, by design** — components stay flexible per app and are built *from* these foundations.

- ***Confirm* the design guide before building screens.** It is a gate: for a new project (or a rebrand) no screen or component work starts until the guide reflects the project's brand, has been reviewed in a browser, and signed off. Once the system is established small additions don't re-gate — but a new foundational token lands in the guide first.
- **Customise by editing tokens, not screens.** A rebrand edits the **primitive** token tier — or has your AI assistant regenerate it from the brand — and the semantic tier and the whole guide re-derive. This is the "one token source, three tiers" rule below — the guide is its human-reviewable face.
- **The guide binds components without prescribing them.** Every component consumes semantic tokens, answers with the guide's state ladder and focus spec, and meets its accessibility floor; a component that violates a foundation is the defect (the DRY-gate audit under *Component structure* catches duplicates). A pattern that recurs across projects earns a specimen in the guide; a stack pack may add a Storybook against the same tokens (optional upgrade).

**Never-violate gates** — the build-time digest; the named guide chapter is canonical:

1. Every colour, size, space, and duration resolves to a semantic token — a hex or px literal in a screen is the defect (guide → *Tokens*).
2. Pick the screen archetype before building any screen — its zones, page rhythm, and width are fixed, never re-derived per page (guide → *Screen archetypes*).
3. Surfaces follow the ladder: no card-like container inside another; separate in order whitespace → background shift → border → divider (tables/dense rows only) (guide → *Surfaces & elevation*).
4. Reuse first: archetype → documented pattern → existing screens/primitives → extend a primitive → only then new, with the PR recording why nothing fit (guide → *Components & reuse*).
5. One density app-wide, set at the token layer — never mixed within a page hierarchy (guide → *Screen archetypes*).

## Page layout & design tokens

Consistency is a system, not a per-page effort. Two things make every screen feel like one product: a **single shared layout** and a **single token source**. A page author composes the layout and reaches for tokens — and never re-decides spacing, colour, or navigation.

**Primary form factor (FILL IN ON SETUP):** `<mobile-first | desktop-first | responsive-equal>` plus the supported viewport range. This choice drives the default navigation pattern and which furniture the shared layout carries.

**One shared layout.** Every page builds on common layout components that supply the standing furniture — header / navigation, page chrome, consistent gutters and background, and the navigation pattern for the declared form factor. The page provides its content; the layout owns the frame — don't hand-roll a page shell. **The layout owns every clearance and inset; pages never re-derive them:** fixed/sticky chrome reserves its space through one clearance token (composed once with its safe-area inset), and top-spacing variants are a **prop the layout offers** — a page picks one, it never re-decides the padding.

**Layouts are responsive by default** — content reflows without horizontal scroll or clipping across the declared viewport range; no fixed pixel widths that break it.

**One token source, three tiers.** All spacing, colour, typography, radius, and elevation come from a single design-token source, never hardcoded per page. Structure tokens in three layers so they stay coherent and themeable:

1. **Primitive tokens** — raw, context-free values (`--red-400`, `--space-3`).
2. **Semantic tokens** — decisions that map primitives to meaning (`--color-bg`, `--gutter-screen`, `--header-clearance`). Components reference *these* (plus form-factor-specific tokens such as `--bottom-nav-clearance` only when mobile is the primary form factor).
3. **Component tokens** — per-component overrides, where a component genuinely needs them.

Pages and components consume **semantic** tokens; they never reach past them to a raw primitive value.

**A token's committed value must match its documented scale — guard it.** Check the token file against its declared scale, in the spirit of the i18n key-parity check.

## Responsive layout

"Responsive by default" (above) is a promise; these rules keep it, whatever primary form factor you declared. Fix each failure with a primitive or token applied **once** — never a per-page tweak. (The concrete idioms per CSS toolchain live in the active stack pack.)

- **Author from the smallest supported width up.** The floor is WCAG **Reflow**: no sideways scroll or lost content at **320 CSS px**, and the layout survives **200% text zoom**.
- **Prefer intrinsic sizing; reach for breakpoints last.** Fluid type/space and self-wrapping grids adapt *between* breakpoints; a reusable component adapts to **its container's** width, not the viewport's. Add a viewport breakpoint only for a genuine page-level layout change.
- **No horizontal overflow at the minimum width.** Atomic values (phone numbers, IDs, amounts) never wrap mid-token — bake no-wrap into the shared inline-value primitive; long free text wraps or truncates, never pushes width (a flex/grid child needs `min-width: 0` to be allowed to shrink); wide tables and code blocks scroll inside their own box, never the page.
- **Reserve space for fixed / sticky chrome with one semantic token** (`--header-clearance`) applied by the shared layout — never re-measured or re-padded per page.
- **Size full-bleed sections to content, not the viewport** — a content-driven min-height plus vertical padding, never `100vh`; where something must truly fill the viewport prefer `svh` over `vh`, and `dvh` only to deliberately track the browser chrome.
- **Treat configurable copy as variable-length.** Any admin/CMS-editable string must survive a one-word *and* a three-line value without clipping or colliding with chrome; balance headings by default.
- **Multi-field rows collapse to full-width below the breakpoint,** each field keeping a min-width that leaves its content legible.
- **Adapt by disclosure, never by hiding meaning** — if navigation doesn't fit, collapse it into a menu; don't drop destinations or actions on small screens.

## Navigation chrome, overlays & scroll

Persistent chrome (a bottom nav, a sticky header), overlays, and client-side route changes recur as rework in an SPA — fix each at the root, not per screen. (Companion to *Responsive layout*, which owns overflow and viewport sizing; and to *One shared layout*, which owns clearance.)

- **Render overlays and fixed chrome in a top-level portal** — an ancestor's `transform` or low `z-index` otherwise drags or buries them (fixed bars sliding with page transitions; sheets rendering under the nav).
- **Reset or restore scroll in an effect keyed on the actual route/view change**, not synchronously at the navigation call; a keep-alive surface has **one explicit scroll owner**. Otherwise a newly-shown view inherits the previous one's scroll offset.
- **Global-nav visibility is a denylist of chrome-less routes, not an allowlist** — a new screen keeps the nav by default; only auth/legal/full-screen-editor routes opt out (an editor with its own sticky action bar hides the global nav so its primary action isn't clipped).
- **Under the soft keyboard, a flex column scrolls — it does not squeeze:** the scroll region is `overflow-y: auto`, non-shrinkable panels are `flex-shrink: 0`. Otherwise panels collapse to a clipped sliver when the keyboard opens.

## Visual quality bar

Tokens say *where* values come from; this says *which* values are good. Checkable, per screen:

- **Type.** One modular type scale in the token source; at most 2 font families, and on any single screen ~4 type sizes and ~2 weights. Body copy capped at ~60–75ch measure. Adding a size means adding a scale step in tokens, not a one-off value in a component.
- **Spacing.** Every margin / padding / gap resolves to an existing step on the spacing scale. Don't introduce ad-hoc values or new steps to make one screen fit; if the scale can't express it, fix the scale, not the instance.
- **Hierarchy.** Exactly one primary (filled) action per view; everything else is secondary / tertiary. One H1 per page; heading levels nest in order and never skip (h1 → h2 → h3), so the heading outline doubles as document structure for assistive tech.
- **Colour.** Use semantic intent tokens for meaning (success / warning / danger / info); never encode meaning in a raw hue or colour alone — pair it with text or an icon. Limit accent surfaces so the single primary CTA stays the most prominent element.
- **Alignment & density.** Content aligns to the shared layout's grid / gutters — no per-screen one-off gutters. Control sizing / density follows the declared primary form factor and stays consistent within a view; don't hardcode a global density.

## Interaction feedback & perceived performance

- **Every actionable control shows its state from tokens.** Pressed / active, focus-visible, and disabled states are defined on the shared `atoms/`/`molecules/` primitives (not per page) and driven by semantic tokens. Hover is a pointer-device affordance; on a touch-primary form factor the pressed / active state carries the feedback — never leave the touch path without visible press feedback. (Keyboard focus-visible is owed by the headless foundation; surface it, don't suppress it.)
- **In-flight feedback stays on the control that triggered the action.** A local action disables its own control and shows an inline busy indicator there — never blank the whole screen with a top-level spinner for a local action. Reserve full-screen / section loading for a screen's initial data fetch (the `loading` state above).
- **Prefer optimistic updates for low-risk mutations** (toggles, reorders, favourites) with rollback + an error message on failure; reserve blocking spinners for genuinely blocking waits.
- **Initial content load uses skeletons that match the final layout;** short indeterminate waits use a spinner. Don't layout-shift from spinner to content.
- **Avoid indicator flicker:** delay showing a busy indicator (~150 ms) and keep it visible a small minimum once shown; debounce live search / filter input (~250 ms). Treat these as defaults a project may tune, not magic numbers.
- **Move focus deliberately after a navigational or destructive action** — to the next logical element, the confirmation, or back to the triggering control after a modal closes — so keyboard and screen-reader users aren't dropped at the top of the document.

## Forms

- **Validation timing.** Don't surface a field error before the user has interacted with that field. Validate a field on blur after first interaction, and the whole form on submit. Once a field shows an error, re-validate it on change so the error clears the moment it's fixed. Never error-shout on first keystroke.
- **Error placement & a11y.** Show each field's error inline, adjacent to the field, programmatically associated with it (`aria-describedby`) and conveyed by more than colour. On a failed submit, move focus to the first invalid field.
- **Destructive actions.** Require an explicit confirm step that names the consequence ("Delete 3 invoices?"). For irreversible / high-risk actions require deliberate confirmation (typed value or equivalent), never a bare button.
- **Unsaved-changes guard.** When a form holds meaningful unsaved edits, warn before discarding them — on both in-app route changes and browser unload / refresh. Don't prompt for trivial / transient inputs (e.g. a search box).
- **Submit handling.** While a submit is in flight, disable the submit control and prevent re-submission; surface progress through the same loading / error / success convention used elsewhere, not a per-form one.

## Microcopy & content

- **Capitalization is uniform.** Pick one convention project-wide and apply it everywhere — default to sentence case for all UI text except proper nouns. Don't mix title case and sentence case across buttons, headings, and labels.
- **Action labels are verb-first and specific.** Buttons and menu items name the action and its object — "Save changes", "Delete invoice", "Send invite" — not "OK", "Submit", or "Yes".
- **Error copy is user-facing and actionable.** State what happened, why if known, and what the user can do next. Blame-free; never exposes stack traces, status codes, internal identifiers, or raw exception text. (Distinct from the backend's error mapping, which shapes the transport response; this governs what the user reads.)
- **Empty / loading / success copy is concise and human** — paired with the four-state rule above; the states already exist, this governs their wording.
- **Keep user-facing copy centralized and reviewable** — out of component bodies, so all product copy can be audited in one place. In multilingual projects this is the i18n dictionaries; in single-language projects, a single strings / copy module serves the same purpose. No hardcoded display literals scattered through components. (Planned-screen copy still comes from the design mockups; these rules govern the microcopy agents would otherwise invent ad hoc — errors, empties, confirmations, labels.)

## Component structure — atomic design

Visual and behavioural consistency comes from **reuse**, not from discipline repeated per screen. Structure every component into one of five atomic tiers, over a headless foundation you never skip — the foundation is a **dependency, not a folder**: unstyled, behavioural primitives from a headless UI library that solves focus management, keyboard handling, and widget-level ARIA for the components routed through it (not page-level a11y; see *Accessibility baseline*), with atoms built *on top of* it.

1. **Atoms** (`components/atoms/`) — the smallest indivisible primitives, each mapping the project's tokens and conventions onto the foundation: `<Button>`, `<Input>`, `<Icon>`, `<Label>`.
2. **Molecules** (`components/molecules/`) — small, still-generic compositions of atoms: `<FormField>` (label + input + error), `<SearchBar>`, `<Card>`.
3. **Organisms** (`components/organisms/<feature>/`) — larger, **feature-meaningful** sections assembled from atoms and molecules: `<BidTable>`, `<RegistrationForm>`, `<SiteHeader>`.
4. **Templates** (`components/templates/`) — page-level layout scaffolds that arrange organisms without real data: the one shared layout, page chrome.
5. **Pages** (`src/pages/`) — a template filled with real data; holds no business logic (see *Layering*).

**Grouping is decided by the tier, not by taste:**

- **Atoms and molecules are grouped by *type* and live globally** — they carry **no business vocabulary**, so a "billing button" is a smell.
- **Organisms are grouped by *feature*** (`organisms/<feature>/`) — they **do** carry domain meaning, so this is where the "a slice can be removed as a unit" property lives. This mirrors the backend's `shared/` (cross-cutting) + `modules/<feature>/` (feature-owned) shape.
- **The crossover is business meaning.** Ask: does the component speak the business's language? No → atom or molecule (shared). Yes → organism (feature-owned). Atomic design just names, and subdivides, the shared-vs-feature line the UI already had.

**The DRY gate — the whole point is that the UI is *actually* DRY:**

- **Reuse-first.** Before building any component, search `atoms/` and `molecules/` for one that exists. A second variant of something already there is the canonical failure this structure prevents.
- **Never build a one-off.** A page that needs a nav bar uses the shared `<SiteHeader>` organism; never hand-roll a header — or button, input, modal, table, or icon button. Wrap from the start, even before a component is widely reused, so a later token/behaviour change lands everywhere at once.
- **No feature-specific atoms or molecules.** If you are tempted to make one, it is a fork: either it is genuinely generic → put it in global `molecules/`, or it carries business meaning → it is an organism. This one rule is what stops the shared tiers re-fragmenting per feature.
- **Audit for duplication periodically** (in the spirit of the i18n key-parity check): two components that render the same thing are a defect to merge, not a style.

## Accessibility baseline

Non-negotiable. The headless library covers a11y only for widgets routed through it; everything below is the page author's responsibility.

- **Colour contrast.** Semantic colour tokens must meet WCAG 2.1 AA against their intended background — 4.5:1 body text, 3:1 large text and UI / graphical boundaries. This is a constraint on the token set, not something a token "enforces".
- **Keyboard operability.** Every interactive element is keyboard-reachable and operable; preserve a visible focus indicator — never remove the outline without a token-based replacement.
- **Focus management.** Logical focus order; modals trap focus and restore it to the trigger on close.
- **Labels & alt text.** All inputs have associated labels; icon-only controls have an accessible name. Images carry meaning via alt text or are explicitly marked decorative.
- **Structure.** One H1 per page, no skipped heading levels, correct landmark regions.
- **Motion.** Honour `prefers-reduced-motion`; never convey essential feedback by motion alone.
- **State announcement.** Don't convey state by colour alone; announce dynamic updates via a live region or managed focus.
- **Touch targets** ~44×44px minimum on touch-primary form factors (tie this to the declared primary form factor; don't mandate it for desktop-primary tools).
- **Reflow & zoom.** Content reflows without horizontal scrolling or loss at **320 CSS px** width (WCAG 1.4.10) and stays usable at **200% text zoom** (1.4.4) — the responsive floor; see *Responsive layout*. Content that genuinely needs two-dimensional layout (data tables, maps) scrolls inside its own box, not the page.

An automated a11y check (axe / lighthouse-style) belongs in CI alongside Lint / Test / Build, but automation is the floor — it catches only a fraction of these rules.

## Internationalisation (if multilingual)

Treat one language as the **reference** and keep every other language in exact parity with it.

- Dictionaries live under `src/i18n/`, one per language.
- **Add every new key to every language file in the same change** — never let dictionaries drift.
- **Run a key-parity check in CI** that fails on any key missing from a locale *or* present in a locale but absent from the reference. Both directions are drift.
- **Name keys by meaning, not location** (`order.confirm_button`, not `page3.btn`), so a key survives a screen being moved or redesigned.

## Coding standards

- **Never reimplement what the UI library already gives you.** Typography, buttons, inputs, and the like are **built on top of the chosen UI library** — wrapped through the shared `atoms/`/`molecules/` tier, never hand-rolled from scratch. A bespoke `<Button>` that duplicates the library's is the canonical mistake: it fragments styling, drops the widget-level accessibility the library solved, and drifts over time. Build on the foundation; don't rebuild it.
- **Cross-cutting concerns belong in shared hooks / services**, not duplicated per screen. Wrap repeated API / auth / error-reporting plumbing once and reuse it; don't copy-paste it into every page.
- **Don't accumulate one-off helpers in `src/lib/`.** Co-locate a helper with its only caller until reuse actually appears; `src/lib/` is for genuinely shared, side-effect-light code.
- **Use libraries instead of hand-rolling — especially for dates.** See *Don't reinvent existing solutions* in the root `CLAUDE.md` Principles (the canonical statement of this rule).

Security baseline:

- **No secrets in the bundle.** Secrets and API keys never live in the SPA bundle — it ships to the client and is fully readable. Anything secret stays server-side; the frontend calls a backend endpoint that holds the credential.
- **Treat rendered data as untrusted.** Treat all rendered server- and user-supplied data as untrusted: rely on the framework's default escaping and never bypass it (no raw-HTML injection with unsanitised input).
- **Auth tokens live in one place.** Keep auth tokens in the one agreed store/service (see *Layering*), never scattered across components or hand-read from storage in views.
- **Security response headers are part of the app.** The app sends the standard hardening headers and a **Content-Security-Policy** at the framework's header layer; ship a new or tightened CSP **report-only first**, then promote to enforcing. Allow-list only the origins the app actually loads; never fall back to `unsafe-inline`/`*` to silence a report. (Exact headers + config: the active stack pack.)

## Versioning / build identity

The running build must be **identifiable** and **updatable** — a deployed SPA is cached, so a user can sit on a stale bundle indefinitely after a release.

- **Make the version visible.** Render an inconspicuous `v<version>` tag somewhere unobtrusive (e.g. the login footer), sourced from `apps/frontend/package.json` at build time. Bump the version on every release (semver) so the deployed build is identifiable at a glance.
- **Give users a way off a stale bundle.** Detect when the running build differs from the deployed one (e.g. poll a build-stamped `version.json`, or react to a new service worker), then **prompt** — show a dismissible "Refresh to update" banner. Let the user choose when to reload; never force a reload that could interrupt work in progress.

## Cross-app conventions

These bind the frontend to the backend's cross-cutting machinery. All three live in shared hooks / services (see *Coding standards*), never per screen.

- **Correlation id is never discarded.** The backend returns a correlation id on every response (`x-correlation-id` header; errors also carry `error.correlationId` — the envelope is pinned in *Error responses*, `apps/backend/CLAUDE.md`). The shared error-handling path reads it from a failed response, shows it unobtrusively in the user-visible error UI ("Error reference: `<id>`") so it can be quoted in a support report, and attaches it to any client-side error / telemetry report.
- **Session & auth UX.** A single shared services-layer interceptor handles auth responses — no page implements its own 401 redirect. On **401**, send the user to login, preserve the originally requested URL, and return them there after sign-in. On **403**, render the shared "forbidden" error state — don't bounce to login. Guard against redirect loops (never redirect the login route itself; cap repeated redirects). On explicit sign-out, clear client / store state so no stale authenticated data lingers. Treat token / session refresh as one shared concern, not duplicated per request. (Tie 401 / 403 back to the backend status-code contract.)
- **Analytics & events (if the project ships product analytics).** Emit client analytics through a single shared service / hook, never via inline tracking calls scattered in components. Event names follow a documented by-meaning taxonomy (`order.checkout_started`, not `page3.click`), mirroring the i18n name-by-meaning rule so events survive a redesign. A UI story that emits analytics names its key events in the spec, the same way it names its loading / error / empty / success states. Stay vendor-agnostic; don't pin an analytics SDK.

## Testing

- **Store slices & `lib/` helpers** — test as plain units.
- **Services** — test with the network mocked at the edge: assert request shape + response / error mapping, never by stubbing internal methods.
- **Organisms (feature components)** — test for behaviour and the four required states (loading / error / empty / success), not markup. The four-state contract in *Layering* is itself a test checklist for every data-backed screen.
- **No broad DOM snapshots.** Snapshot the data a component receives, not its rendered output — markup snapshots lock in structure and produce noise on every refactor.
- **At least one automated check runs at a narrow viewport.** A suite that only ever runs at one desktop width leaves responsive layout untested — the canonical way mobile-layout regressions ship. Run the end-to-end suite (or a representative subset) at the minimum supported width as well as the primary; the concrete mechanism (a second device project, a viewport override) is the active stack pack's.

## Verifying a change

Run it; don't infer from reading the code.

- **A new screen's initial build is verified against its `design/` mockup** — render it and *look* (a screenshot or equivalent); don't declare it done from the code. No mockup? Sketch the screen in the feature's spec and get it approved there first — never invent UI for a non-trivial new screen silently. Later iterations verify against the running app, not the mockup. (Full loop + mockup inventory: `design/README.md`.)
- Start the dev server and load the touched screen.
- Confirm all four states (loading / error / empty / success) actually render — force the error and empty paths, don't just read the code.
- Do one keyboard-only pass: tab order sane, focus visible, Esc / Enter work on any modal or dialog.
- Exercise the touched screen at the declared primary form factor, **and at the minimum supported width and 200% zoom** — resize down to the narrow end (~320 px) and confirm nothing overflows, clips, or forces horizontal scroll, and that fixed chrome doesn't overlap content (force it; don't infer safety from the classes). This is the responsive baseline, not an optional glance.
- **State what you observed** (which states you exercised, what you saw), not just that you ran it.
