# Frontend

The frontend contract. Read this before touching anything under `apps/frontend/`; repo-wide rules (principles, worktree workflow, cross-app standards) live in the root `CLAUDE.md`. Stack pack adopted? Read its `frontend.md` appendix first — precedence rules in `stacks/README.md`.

Two axes never blur: horizontal **layers** (what code *is* — store, service, page, component) and vertical **feature slices** (what business capability it serves). Components follow **atomic design** — see *Component structure*.

## Project structure

Mirror this shape under `apps/frontend/src/`. The toolchain is not yet chosen (root `CLAUDE.md`), so file extensions and framework specifics are illustrative, not mandates.

```
src/
  store/               # one slice per domain
  services/            # API clients — mirror backend route groups
  pages/               # screens — compose organisms, no business logic
  components/
    atoms/             # smallest primitives, by type (on the headless lib)
    molecules/         # generic compositions, by type
    organisms/
      <feature>/       # feature sections, by feature
    templates/         # page-level layout scaffolds
  i18n/                # one dictionary per language
  lib/                 # shared, side-effect-light helpers
  routes.<ext>         # the single route registry
  tokens.<ext>         # the single design-token source
```

A feature's vertical slice spans `store/<feature>` + `services/<feature>` + `components/organisms/<feature>`, so it can be understood, changed, and removed as a unit (grouping rules: *Component structure*). Promote code into `atoms/`/`molecules/` or `lib/` only once genuinely shared — never in anticipation of reuse; co-locate a one-off helper with its only caller until reuse appears (`src/lib/` holds only genuinely shared, side-effect-light code).

## Layering

Each layer has one job, may depend only on the layers beneath it, and never reaches upward. Tier definitions: *Component structure*.

- **Store** — application state, one slice per domain. May depend on services; never imports a page or renders anything.
- **Services** — all data fetching and mutation; each domain mirrors a backend route group; **all network access lives here**. May depend on `lib/`; never hold view state.
  - The backend endpoint contract (*Endpoint contract*, `apps/backend/CLAUDE.md`) is the single source of truth for shapes and status codes; the service mirrors it, never invents its own.
  - Prefer a generated or shared contract artifact (e.g. an OpenAPI/JSON-schema document the backend emits); without one, every contract change is one PR touching the backend endpoint *and* its mirroring frontend service.
  - Validate responses against the declared shape so a contract break surfaces as a typed error feeding the `error` state, not an undefined-field render.
- **Pages** — compose organisms into a screen and wire data from store/services into components. No business logic; never fetch directly or embed reusable UI inline.
- **Templates** — arrange organisms with no real data; no business logic. See *Page layout & design tokens*.
- **Organisms** — may use `atoms/`, `molecules/`, and `lib/`; never imported by a primitive.
- **Shared primitives (`atoms/`, `molecules/`)** — depend only on the UI library and the design tokens; never know a specific feature or page.

**Loading/error/empty/success are handled consistently on every data-backed screen** — presented the same way. An empty state is designed, not blank: state *why* there's nothing and offer the primary next action where one exists. First-run ("create your first X"), no-results/filtered-to-nothing (offer to clear filters), and access-restricted (explain the missing permission) are distinct cases — they differ in copy and CTA. A data-load **failure** is an error state with a retry, never an empty state.

## URL routing

Browser URLs stay clean and human-meaningful and **never expose internal build/source paths** (no `/src/` or `/pages/` prefix in the address bar).

- **One central registry.** Every route lives in `routes.<ext>`, registered the moment its page is created. Audit routing by reading the registry; maintain no second route→URL list anywhere else (including this file).
- **Build URLs from named routes in the registry,** never by concatenating path strings — internal structure can't leak into a URL, and renaming a route updates every link at once.

## Design guide (confirm before building UI)

**Lock the visual system before building any screen.** It lives in the design guide (`design/design-guide.html`), rendered live from the single design-token source (`design/tokens.css` — the seed for the app's `tokens.<ext>`). **Foundations only, by design** — components stay flexible per app and are built *from* these foundations.

- **Confirm the guide first.** For a new project or rebrand, no screen or component work starts until the guide reflects the brand, is browser-reviewed, and signed off. An established system doesn't re-gate small additions — but a new foundational token lands in the guide first.
- **Customise by editing the primitive token tier, not screens;** the semantic tier and the whole guide re-derive.
- **The guide binds components without prescribing them.** Every component consumes semantic tokens, follows the guide's state ladder and focus spec, and meets its accessibility floor; a component violating a foundation is the defect. A pattern recurring across projects earns a guide specimen.

**Never-violate gates** — the named guide chapter is canonical:

1. Every colour, size, space, and duration resolves to a semantic token — a hex or px literal in a screen is the defect (*Tokens*).
2. Pick the screen archetype before building any screen — its zones, page rhythm, and width are fixed, never re-derived per page (*Screen archetypes*).
3. Surfaces follow the ladder: no card-like container inside another; separate in order whitespace → background shift → border → divider (tables/dense rows only) (*Surfaces & elevation*).
4. Reuse first: archetype → documented pattern → existing screens/primitives → extend a primitive → only then new, with the PR recording why nothing fit (*Components & reuse*).
5. One density app-wide, set at the token layer — never mixed within a page hierarchy (*Screen archetypes*).
6. Forms and view states follow the composition patterns — the pattern outranks the component library's defaults (*Forms*, *View states & feedback*).

## Page layout & design tokens

**Primary form factor (FILL IN ON SETUP):** `<mobile-first | desktop-first | responsive-equal>` plus the supported viewport range. This drives the default navigation pattern and the furniture the shared layout carries.

**One shared layout** supplies the standing furniture — header/navigation, page chrome, gutters, background, and the navigation pattern for the declared form factor. The page provides content; the layout owns the frame — never hand-roll a page shell. **The layout owns every clearance and inset; pages never re-derive them:** fixed/sticky chrome reserves its space through one clearance token (composed once with its safe-area inset), and top-spacing variants are a **prop the layout offers** — a page picks one, never re-decides the padding.

**Layouts are responsive by default** — content reflows without horizontal scroll or clipping across the declared viewport range; no fixed pixel widths that break it (rules: *Responsive layout*).

**One token source, three tiers:**

1. **Primitive tokens** — raw, context-free values (`--red-400`, `--space-3`).
2. **Semantic tokens** — decisions mapping primitives to meaning (`--color-bg`, `--gutter-screen`, `--header-clearance`; form-factor-specific tokens such as `--bottom-nav-clearance` only when mobile is primary).
3. **Component tokens** — per-component overrides, where a component genuinely needs them.

Pages and components consume **semantic** tokens; they never reach past them to a raw primitive value. A token's committed value must match its documented scale.

## Responsive layout

Fix each failure below with a primitive or token applied **once**, never a per-page tweak; the concrete CSS idioms live in the active stack pack.

- **Author from the smallest supported width up.** The floor is WCAG Reflow: no sideways scroll or lost content at **320 CSS px**, and the layout survives **200% text zoom**.
- **Prefer intrinsic sizing; reach for breakpoints last.** Fluid type/space and self-wrapping grids adapt *between* breakpoints; a reusable component adapts to **its container's** width, not the viewport's. Add a viewport breakpoint only for a genuine page-level layout change.
- **No horizontal overflow at the minimum width.** Atomic values (phone numbers, IDs, amounts) never wrap mid-token — bake no-wrap into the shared inline-value primitive; long free text wraps or truncates, never pushes width (flex/grid children need `min-width: 0` to shrink); wide tables and code blocks scroll inside their own box, never the page.
- **Pagination controls render a bounded window of page slots (~7: first, last, current ± 1, ellipsis), never the full page list** — a large page count must not widen the layout.
- **Reserve space for fixed/sticky chrome with the one semantic clearance token** applied by the shared layout — never re-measured or re-padded per page.
- **Size full-bleed sections to content, not the viewport** — a content-driven min-height plus vertical padding, never `100vh`; where something must truly fill it prefer `svh` over `vh`, `dvh` only to deliberately track browser chrome.
- **Treat configurable copy as variable-length.** Any admin/CMS-editable string must survive a one-word *and* a three-line value without clipping or colliding with chrome; balance headings by default.
- **Multi-field rows collapse to full width below the breakpoint,** each field keeping a min-width that leaves its content legible.
- **Adapt by disclosure, never by hiding meaning** — if navigation doesn't fit, collapse it into a menu; never drop destinations or actions on small screens.

## Navigation chrome, overlays & scroll

Fix each of these at the root, not per screen:

- **Render overlays and fixed chrome in a top-level portal** — an ancestor's `transform` or low `z-index` otherwise drags or buries them.
- **Reset or restore scroll in an effect keyed on the actual route/view change,** not synchronously at the navigation call; a keep-alive surface has **one explicit scroll owner**.
- **Global-nav visibility is a denylist of chrome-less routes, not an allowlist** — a new screen keeps the nav by default; only auth/legal/full-screen-editor routes opt out.
- **Under the soft keyboard, a flex column scrolls — it does not squeeze:** the scroll region is `overflow-y: auto`, non-shrinkable panels are `flex-shrink: 0`.

## Visual quality bar

Checkable, per screen:

- **Type.** One modular type scale in the token source; at most 2 font families; ~4 type sizes and ~2 weights per screen; body copy capped at ~60–75ch measure. A new size is a new scale step in tokens, never a one-off value in a component.
- **Spacing.** Every margin/padding/gap resolves to an existing step on the spacing scale. If the scale can't express it, fix the scale, not the instance.
- **Hierarchy.** Exactly one primary (filled) action per view; everything else is secondary/tertiary. One H1 per page; heading levels nest in order and never skip — the heading outline doubles as document structure for assistive tech.
- **Colour.** Semantic intent tokens for meaning (success/warning/danger/info); never encode meaning in colour alone — pair it with text or an icon. Limit accent surfaces so the single primary CTA stays the most prominent element.
- **Alignment & density.** Content aligns to the shared layout's grid/gutters — no per-screen one-off gutters. Control sizing/density follows the declared primary form factor and stays consistent within a view.

## Interaction feedback & perceived performance

- **Control states come from tokens on the shared primitives.** Pressed/active, focus-visible, and disabled are defined on `atoms/`/`molecules/`, never per page. Hover is a pointer-device affordance; touch-primary paths always show visible press feedback. Surface the headless foundation's focus-visible; don't suppress it.
- **In-flight feedback stays on the triggering control** — inline busy indicator plus disable; never a top-level spinner for a local action. Full-screen/section loading only for a screen's initial data fetch.
- **Prefer optimistic updates for low-risk mutations** (toggles, reorders, favourites) with rollback + an error message on failure; blocking spinners only for genuinely blocking waits.
- **Initial load uses skeletons matching the final layout;** short indeterminate waits use a spinner; no spinner-to-content layout shift.
- **Avoid indicator flicker:** delay busy indicators (~150 ms) with a small minimum visible time; debounce live search/filter input (~250 ms) — defaults a project may tune, not magic numbers.
- **Move focus deliberately after a navigational or destructive action** — to the next logical element, the confirmation, or back to the trigger after a modal closes.

## Forms

- **Validation timing.** Validate a field on blur after first interaction, the whole form on submit; once a field shows an error, re-validate on change so it clears the moment it's fixed. Never error before first interaction or on first keystroke.
- **Error placement & a11y.** Field errors sit inline, adjacent to the field, `aria-describedby`-associated, and conveyed by more than colour; a failed submit moves focus to the first invalid field.
- **Destructive actions.** Require an explicit confirm naming the consequence ("Delete 3 invoices?"); irreversible/high-risk actions require deliberate confirmation (typed value or equivalent), never a bare button.
- **Unsaved-changes guard.** Warn before discarding meaningful unsaved edits — on in-app route changes and browser unload/refresh; not for trivial/transient inputs (a search box).
- **Submit handling.** Disable the submit control in flight and prevent re-submission; surface progress through the shared loading/error/success convention, not a per-form one.

## Microcopy & content

- **Capitalization is uniform** — one convention project-wide; default sentence case except proper nouns. Never mix title case and sentence case across buttons, headings, and labels.
- **Action labels are verb-first and specific** — "Save changes", "Delete invoice", "Send invite" — not "OK", "Submit", or "Yes".
- **Error copy is user-facing and actionable.** State what happened, why if known, and what the user can do next. Blame-free; never exposes stack traces, status codes, internal identifiers, or raw exception text.
- **Empty/loading/success copy is concise and human.**
- **Centralize user-facing copy** — i18n dictionaries in multilingual projects, a single strings module otherwise — so all product copy is auditable in one place; no hardcoded display literals in components.

## Component structure — atomic design

Structure every component into one of five atomic tiers, over a headless foundation you never skip. The foundation is a **dependency, not a folder**: unstyled behavioural primitives from a headless UI library that solves focus management, keyboard handling, and widget-level ARIA for components routed through it (not page-level a11y — *Accessibility baseline*); atoms build on top of it.

1. **Atoms** — the smallest indivisible primitives, each mapping the project's tokens and conventions onto the foundation: `<Button>`, `<Input>`, `<Icon>`, `<Label>`.
2. **Molecules** — small, still-generic compositions of atoms: `<FormField>` (label + input + error), `<SearchBar>`, `<Card>`.
3. **Organisms** — **feature-meaningful** sections assembled from atoms and molecules: `<InvoiceTable>`, `<RegistrationForm>`, `<SiteHeader>`.
4. **Templates** — page-level layout scaffolds arranging organisms without real data: the one shared layout, page chrome.
5. **Pages** — a template filled with real data; no business logic (*Layering*).

**Grouping is decided by the tier, not by taste.** Atoms and molecules are grouped by **type** and shared globally — no business vocabulary, so a "billing button" is a smell. Organisms are grouped by **feature** (`organisms/<feature>/`) and carry domain meaning — the "removable as a unit" property lives here, mirroring the backend's `shared/` + `modules/<feature>/` shape. The crossover test: does the component speak the business's language? No → atom or molecule (shared); yes → organism (feature-owned).

**The DRY gate:**

- **Reuse-first.** Before building any component, search `atoms/` and `molecules/` for one that exists. A second variant of something already there is the canonical failure.
- **Never build a one-off** header, button, input, modal, table, or icon button — use the shared component, wrapping from the start even before it is widely reused, so a later token/behaviour change lands everywhere at once.
- **Modal/dialog sizing is solved once on the shared dialog primitive,** never re-derived per feature.
- **No feature-specific atoms or molecules.** One you're tempted to make is a fork: genuinely generic → global `molecules/`; business meaning → organism.
- **Audit periodically for duplicated components.** Two components that render the same thing are a defect to merge, not a style.

## Accessibility baseline

Non-negotiable. The headless library covers a11y only for widgets routed through it; everything below is the page author's responsibility.

- **Colour contrast.** Semantic colour tokens meet WCAG 2.1 AA against their intended backgrounds — 4.5:1 body text, 3:1 large text and UI/graphical boundaries. A constraint on the token set.
- **Keyboard operability.** Every interactive element is keyboard-reachable and operable, with a visible focus indicator; never remove the outline without a token-based replacement.
- **Focus management.** Logical focus order; modals trap focus and restore it to the trigger on close.
- **Labels & alt text.** All inputs have associated labels; icon-only controls have an accessible name; images carry meaning via alt text or are explicitly marked decorative.
- **Structure.** The heading outline follows *Visual quality bar* (one H1, no skipped levels); correct landmark regions.
- **Motion.** Honour `prefers-reduced-motion`; never convey essential feedback by motion alone.
- **State announcement.** Never convey state by colour alone; announce dynamic updates via a live region or managed focus.
- **Touch targets** ~44×44px minimum on touch-primary form factors only.
- **Reflow & zoom.** The responsive floor in *Responsive layout* is WCAG 1.4.10 Reflow and 1.4.4 Resize Text; content that genuinely needs two-dimensional layout (data tables, maps) scrolls inside its own box, not the page.

An automated a11y check (axe/lighthouse-style) runs in CI alongside lint/test/build; automation is the floor, not the bar.

## Internationalisation (if multilingual)

Treat one language as the **reference** and keep every other language in exact parity with it.

- Dictionaries live under `src/i18n/`, one per language.
- **Add every new key to every language file in the same change.**
- **Drift in either direction fails the key-parity check** — a key missing from a locale, or present in a locale but absent from the reference.
- **Name keys by meaning, not location** (`order.confirm_button`, not `page3.btn`), so a key survives a screen being moved or redesigned.

## Coding standards

- **Never reimplement what the UI library already gives you.** Typography, buttons, inputs, and the like are built on the chosen UI library, wrapped through the shared `atoms/`/`molecules/` tier. A bespoke `<Button>` duplicating the library's fragments styling, drops the library's widget-level accessibility, and drifts.
- **Cross-cutting concerns belong in shared hooks/services,** never duplicated per screen — wrap repeated API/auth/error-reporting plumbing once and reuse it.
- **Libraries over hand-rolling — especially dates:** *Don't reinvent existing solutions*, root `CLAUDE.md`.

Security baseline:

- **No secrets in the bundle.** The SPA bundle ships to the client fully readable; secrets and API keys stay server-side, behind a backend endpoint that holds the credential.
- **Treat rendered data as untrusted.** All server- and user-supplied data is untrusted: rely on the framework's default escaping; never inject raw HTML with unsanitised input.
- **Auth tokens live in one place** — the one agreed store/service (*Layering*), never scattered across components or hand-read from storage in views.
- **Security response headers are part of the app.** Send the standard hardening headers and a **Content-Security-Policy** at the framework's header layer; ship a new or tightened CSP **report-only first**, then enforce. Allow-list only origins the app actually loads; never `unsafe-inline`/`*` to silence a report. Exact headers + config: the active stack pack.

## Versioning/build identity

A deployed SPA is cached — the running build must be identifiable and updatable:

- **Make the version visible.** Render an unobtrusive `v<version>` tag (e.g. the login footer), sourced from the app's package manifest at build time; bump the version (semver) on every release.
- **Give users a way off a stale bundle.** Detect when the running build differs from the deployed one (e.g. poll a build-stamped `version.json`, or react to a new service worker) and show a dismissible "Refresh to update" prompt. Never force a reload.

## Cross-app conventions

All three live in shared hooks/services (*Coding standards*), never per screen.

- **Correlation id is never discarded.** The shared error-handling path reads the correlation id from every failed response (transport shape: `apps/backend/CLAUDE.md`), shows it unobtrusively in the error UI ("Error reference: `<id>`") for support reports, and attaches it to any client-side error/telemetry report.
- **Session & auth UX.** One shared services-layer interceptor handles auth responses — no page implements its own 401 redirect. **401** → login, preserving the requested URL and returning there after sign-in; **403** → the shared "forbidden" state, never a login bounce. Guard redirect loops (never redirect the login route itself; cap repeats). Sign-out clears client/store state. Token/session refresh is one shared concern.
- **Analytics & events (if the project ships product analytics).** Emit through a single shared service/hook, never inline tracking calls in components. Event names follow a documented by-meaning taxonomy (`order.checkout_started`, not `page3.click`) so events survive a redesign; a UI story that emits analytics names its key events in its spec. Stay vendor-agnostic; don't pin an analytics SDK.

## Testing

- **Store slices & `lib/` helpers** — test as plain units.
- **Services** — test with the network mocked at the edge: assert request shape + response/error mapping, never by stubbing internal methods.
- **Organisms** — test for behaviour and the four states (loading/error/empty/success), not markup; the four-state contract in *Layering* is a test checklist for every data-backed screen.
- **No broad DOM snapshots.** Snapshot the data a component receives, not its rendered output.
- **At least one automated check runs at a narrow viewport** — the end-to-end suite (or a representative subset) at the minimum supported width as well as the primary; the concrete mechanism is the active stack pack's.
- **Mechanical invariants get CI checks:** route-registry completeness, token-scale conformance, component duplication, i18n key parity.

## Verifying a change

Run it; don't infer from reading the code.

- **A new screen's initial build is verified against its `design/` mockup** — render it and *look*; no mockup → sketch the screen in the feature's spec and get it approved there first. Later iterations verify against the running app (full lifecycle + mockup inventory: `design/README.md`).
- Start the dev server and load the touched screen.
- Confirm all four states actually render — force the error and empty paths, don't just read the code.
- Do one keyboard-only pass: tab order sane, focus visible, Esc/Enter work on any modal or dialog.
- Exercise the touched screen at the declared primary form factor **and at the responsive floor** (*Responsive layout*): confirm nothing overflows, clips, or forces horizontal scroll, and fixed chrome doesn't overlap content — force it, don't infer safety from the classes.
- **State what you observed** (which states you exercised, what you saw), not just that you ran it.
