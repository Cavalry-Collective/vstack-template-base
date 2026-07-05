# Frontend contract

Binding for everything under `apps/frontend/`. Read with it: the root `CLAUDE.md` (cross-cutting rules) and — if a stack pack is adopted (a single directory under `stacks/`) — its `frontend.md` appendix, whose conflict register wins over this file for that stack only. The structure below is **illustrative** until a pack binds it: treat file extensions and framework specifics as examples, not mandates.

The frontend is organised along two axes that never blur: horizontal **layers** (what a piece of code *is* — store, service, page, component) and vertical **feature slices** (what business capability it serves). Components follow **atomic design** (see *Component structure*).

## Never violate

1. **All network access lives in `services/`** — never in components or pages.
2. **Every data-backed screen handles all four states** — loading / error / empty / success — the same shared way.
3. **Every visual value resolves to a semantic token** — a hex or px literal in a screen is a defect.
4. **Reuse before building:** search `atoms/`/`molecules/` first; a second variant of an existing primitive is the canonical failure. No feature-specific atoms or molecules.
5. **No user-facing display literals in components** — copy lives in i18n dictionaries (every key in every locale, same change) or the single strings module.
6. **Every page registers in the central route registry the moment it exists;** URLs are built through the registry, never by hand.
7. **No secrets in the bundle** — it ships to the client fully readable.
8. **The accessibility baseline is non-negotiable** (see *Accessibility baseline*).
9. **The design guide's gates hold for all UI work** (see *Design guide*).

## Project structure

Mirror this shape under `apps/frontend/src/`:

```
src/
  store/               # state layer — one slice per domain
  services/            # API clients — each domain mirrors a backend route group
  pages/               # screens (atomic "pages" tier) — compose organisms, no business logic
  components/
    atoms/             # smallest primitives, by type — Button, Input, Icon (on the headless lib)
    molecules/         # small compositions of atoms, by type — FormField, SearchBar, Card
    organisms/
      <feature>/       # feature-meaningful sections, by feature — InvoiceTable, SiteHeader
    templates/         # page-level layout scaffolds — the shared layout, page chrome
  i18n/                # one dictionary per language
  lib/                 # genuinely shared, side-effect-light helpers
  routes.<ext>         # the single central route registry
  tokens.<ext>         # the single design-token source
```

**Grouping is set by the tier, not by preference:** `atoms/` and `molecules/` group by type and are global — no business vocabulary. `organisms/` group by feature — they carry it. A feature's vertical slice spans `store/<feature>` + `services/<feature>` + `organisms/<feature>`, so it can be understood, changed, and removed as a unit. Promote into the shared tiers or `lib/` only once code is genuinely shared — never in anticipation.

## Layering

Each layer has one job, depends only on layers beneath it, and never reaches upward.

- **Store (`src/store/`)** — owns application state, one slice per domain. May depend on services. Never imports a page or renders anything.
- **Services (`src/services/`)** — own all data fetching and mutation; each domain mirrors a backend route group. May depend on `lib/`. Never hold view state.
  - **The backend endpoint contract is the single source of truth** for shapes and status codes (`apps/backend/CLAUDE.md` → *Endpoint contract*). The service mirrors it, never invents its own shape.
  - **Prefer a generated/shared contract artifact** (OpenAPI/JSON schema) where the toolchain supports it; otherwise every contract change is one PR touching endpoint and mirroring service together.
  - **Validate responses against the declared shape** so a contract break surfaces as a typed error feeding the `error` state — not an undefined-field render.
- **Pages (`src/pages/`)** — compose organisms into a screen. Hold no business logic; wire data from store/services into components. Never fetch directly or embed reusable UI inline.
- **Templates (`components/templates/`)** — page-level layout scaffolds; may use organisms and primitives; no business logic.
- **Organisms (`organisms/<feature>/`)** — compose atoms and molecules into feature-meaningful sections. Never imported by a primitive.
- **Shared primitives (`atoms/`, `molecules/`)** — depend only on the UI library and the design tokens. Never know about a feature or page.

**The four states, concretely:** loading / error / empty / success, handled the same shared way on every data-backed screen. An empty state is designed, not blank — say why there's nothing and offer the next action (first-run: "create your first X"; no-results: offer to clear filters; access-restricted: name the missing permission). A failed load is an **error** state with a retry — never an empty state.

## URL routing

A route is part of the app's public contract; a file path is an implementation detail. Browser URLs stay clean and human-meaningful — never exposing internal build/source paths.

- **One central registry** (`routes.<ext>`): every route lives there, registered the moment its page is created. Reading it is how you audit routing; no second route→URL list anywhere.
- **Build URLs through the registry, never by hand** — renaming a route then updates every link at once.
- **Shareable state lives in the URL:** anything a link, refresh, or back-button should preserve — filters, active tab, page, selected record — goes in path or query, not the store.

## Design guide — the visual keystone

The project's visual system lives in `design/design-guide.html`, rendered from the single token seed `design/tokens.css` (the source for the app's `tokens.<ext>`). Foundations only, by design — components stay flexible per app and are built *from* those foundations.

- **The guide is a gate:** for a new project or rebrand, no screen or component work starts until the guide reflects the brand and is confirmed in a browser (see `docs/getting-started.md`). Established systems don't re-gate small additions — but a new foundational token lands in the guide first.
- **Customise by editing tokens, not screens:** a rebrand edits the primitive tier; everything re-derives.

**Never-violate gates** (the named guide chapter is canonical):

1. Every colour, size, space, and duration resolves to a semantic token (guide → *Tokens*).
2. Pick the screen archetype before building any screen — zones, rhythm, and width are fixed, never re-derived per page (guide → *Screen archetypes*).
3. Surfaces follow the ladder — no card inside a card; separate in order whitespace → background shift → border → divider (guide → *Surfaces & elevation*).
4. Reuse first: archetype → documented pattern → existing screens/primitives → extend a primitive → only then new, with the PR recording why nothing fit (guide → *Components & reuse*).
5. One density app-wide, set at the token layer (guide → *Screen archetypes*).
6. Tables, forms, and view states follow the composition patterns (guide → *Tables & grids*, *Forms*, *View states & feedback*) — the pattern outranks the component library's defaults. A working table ships the standard kit (search, sort, column filters, pagination, column customisation, selection) by default; dropping a capability is a recorded decision.

## Page layout & design tokens

One shared layout and one token source make every screen feel like one product. A page author composes the layout and reaches for tokens — and never re-decides spacing, colour, or navigation.

**Primary form factor (TEMPLATE-TODO — fill on setup):** `<mobile-first | desktop-first | responsive-equal>` plus the supported viewport range. This drives the default navigation pattern and the shared layout's furniture.

- **One shared layout.** Every page builds on the shared layout components: header/navigation, page chrome, gutters, background. The page provides content; the layout owns the frame — including every clearance and inset. Fixed/sticky chrome reserves its space through one clearance token (composed once with its safe-area inset); top-spacing variants are a layout prop a page picks, never padding it re-derives.
- **One token source, three tiers:** **primitive** (raw, context-free: `--red-400`, `--space-3`) → **semantic** (meaning: `--color-bg`, `--gutter-screen`, `--header-clearance`) → **component** (per-component overrides, only where genuinely needed). Pages and components consume **semantic** tokens; never reach past them to a raw primitive.
- **A token's committed value must match its documented scale** — checkable, in the spirit of the i18n parity check.

## Responsive layout

Layouts are responsive by default — content reflows without horizontal scroll or clipping across the declared viewport range. Fix each failure with a primitive or token applied once, never a per-page tweak. (Concrete idioms: the active pack.)

- **Author from the smallest supported width up.** Floor: WCAG Reflow — no sideways scroll or lost content at **320 CSS px**, surviving **200% text zoom**.
- **Prefer intrinsic sizing; breakpoints last.** Fluid type/space and self-wrapping grids adapt between breakpoints; a reusable component adapts to its **container's** width. Add a viewport breakpoint only for a real page-level layout change.
- **No horizontal overflow at minimum width.** Atomic values (phone numbers, IDs, amounts) never wrap mid-token — bake no-wrap into the shared inline-value primitive. Long free text wraps or truncates, never pushes width (flex/grid children need `min-width: 0` to shrink). Wide tables and code blocks scroll in their own box, never the page.
- **Fixed/sticky chrome reserves space via the one clearance token**, applied by the shared layout — never re-measured per page.
- **Full-bleed sections size to content, not viewport** — content-driven min-height plus padding, never `100vh`; prefer `svh` where something must truly fill, `dvh` only to deliberately track browser chrome.
- **Configurable copy is variable-length:** any admin/CMS-editable string survives one word and three lines without clipping or colliding with chrome; balance headings by default.
- **Multi-field rows collapse to full width below the breakpoint,** each field keeping a legible min-width.
- **Adapt by disclosure, never by hiding meaning** — collapse navigation into a menu; don't drop destinations or actions on small screens.

## Navigation chrome, overlays & scroll

Persistent chrome, overlays, and client-side route changes recur as rework — fix each at the root, not per screen.

- **Render overlays and fixed chrome in a top-level portal** — an ancestor's `transform` or low `z-index` otherwise drags or buries them.
- **Reset/restore scroll in an effect keyed on the actual route/view change,** not at the navigation call; a keep-alive surface has one explicit scroll owner.
- **Global-nav visibility is a denylist of chrome-less routes** — a new screen keeps the nav by default; only auth/legal/full-screen-editor routes opt out.
- **Under the soft keyboard a flex column scrolls, it does not squeeze:** the scroll region is `overflow-y: auto`; non-shrinkable panels are `flex-shrink: 0`.

## Visual quality bar

Tokens say where values come from; this says which values are good. Checkable per screen:

- **Type:** one modular scale in tokens; ≤2 font families, ~4 sizes, ~2 weights per screen; body copy ~60–75ch. A new size is a new scale step, not a one-off.
- **Spacing:** every margin/padding/gap is a step on the spacing scale. If the scale can't express it, fix the scale, not the instance.
- **Hierarchy:** exactly one primary (filled) action per view; one H1 per page; heading levels nest without skipping.
- **Colour:** semantic intent tokens (success/warning/danger/info), always paired with text or an icon — never colour alone. Limit accent surfaces so the primary CTA stays most prominent.
- **Alignment & density:** content aligns to the shared layout's grid and gutters; density follows the declared form factor and stays consistent within a view.

## Interaction feedback & perceived performance

- **Every actionable control shows its state from tokens** — pressed/active, focus-visible, disabled — on the shared primitives, not per page. On touch, the pressed state carries the feedback; never leave a tap without visible response. Surface the headless foundation's focus-visible; don't suppress it.
- **In-flight feedback stays on the triggering control** — disable it and show an inline busy indicator there; never blank the screen for a local action. Full-screen/section loading is for a screen's initial fetch only.
- **Prefer optimistic updates for low-risk mutations** (toggles, reorders, favourites) with rollback + error message on failure; reserve blocking spinners for genuinely blocking waits.
- **Initial loads use skeletons matching the final layout;** short indeterminate waits use a spinner; don't layout-shift between them.
- **Avoid indicator flicker:** delay a busy indicator ~150 ms and keep it a small minimum once shown; debounce live search/filter ~250 ms. Tunable defaults, not magic numbers.
- **Move focus deliberately after navigational or destructive actions** — to the next logical element, the confirmation, or back to the trigger after a modal closes.

## Forms

- **Validation timing:** no field error before the user has interacted with that field. Validate on blur after first interaction, whole form on submit; once a field errors, re-validate on change so the error clears when fixed. Never error-shout on first keystroke.
- **Error placement & a11y:** inline, adjacent to the field, associated via `aria-describedby`, conveyed by more than colour. On failed submit, move focus to the first invalid field.
- **Destructive actions:** an explicit confirm naming the consequence ("Delete 3 invoices?"); irreversible/high-risk actions take deliberate confirmation (typed value or equivalent).
- **Unsaved-changes guard:** warn before discarding meaningful edits — in-app route changes and browser unload. Don't prompt for trivial inputs.
- **Submit handling:** disable while in flight, prevent re-submission, surface progress through the shared loading/error/success convention.

## Microcopy & content

- **One capitalization convention project-wide** — default sentence case except proper nouns.
- **Action labels are verb-first and specific:** "Save changes", "Delete invoice" — never "OK", "Submit", "Yes".
- **Error copy is user-facing and actionable:** what happened, why if known, what to do next. Blame-free; never stack traces, status codes, or raw exception text.
- **Empty/loading/success copy is concise and human.**
- **All copy is centralized and reviewable** — i18n dictionaries (multilingual) or one strings module. Planned-screen copy comes from `design/` mockups; these rules govern the microcopy agents would otherwise invent.

## Component structure — atomic design

Consistency comes from reuse, not per-screen discipline. Five tiers, built over a **headless foundation** you never skip — unstyled behavioural primitives from a headless UI library solving focus, keyboard, and widget-level ARIA for everything routed through it:

1. **Atoms** (`components/atoms/`) — smallest primitives mapping tokens onto the foundation: `<Button>`, `<Input>`, `<Icon>`, `<Label>`.
2. **Molecules** (`components/molecules/`) — still-generic compositions: `<FormField>`, `<SearchBar>`, `<Card>`.
3. **Organisms** (`organisms/<feature>/`) — feature-meaningful sections: `<InvoiceTable>`, `<RegistrationForm>`, `<SiteHeader>`.
4. **Templates** (`components/templates/`) — layout scaffolds without real data.
5. **Pages** (`src/pages/`) — a template filled with real data; no business logic.

The tier test is business meaning: speaks the business's language → organism; doesn't → atom or molecule. **The DRY gate:**

- **Reuse-first:** search the shared tiers before building anything.
- **Never build a one-off:** every header, button, input, modal, table, or icon button is the shared primitive/organism — wrapped from the start, even before wide reuse, so a later token/behaviour change lands everywhere at once.
- **No feature-specific atoms/molecules:** genuinely generic → global tiers; carries business meaning → organism. Nothing in between.
- **Audit for duplication periodically:** two components rendering the same thing are a defect to merge.

## Accessibility baseline

Non-negotiable. The headless library covers only widgets routed through it; everything below is the page author's responsibility.

- **Contrast:** semantic colour tokens meet WCAG 2.1 AA against their intended background — 4.5:1 body text, 3:1 large text and UI boundaries. A constraint on the token set.
- **Keyboard:** every interactive element reachable and operable; visible focus indicator — never remove the outline without a token-based replacement.
- **Focus management:** logical order; modals trap focus and restore it to the trigger on close.
- **Labels & alt text:** all inputs labelled; icon-only controls have an accessible name; images carry alt text or are explicitly decorative.
- **Structure:** one H1, no skipped heading levels, correct landmarks.
- **Motion:** honour `prefers-reduced-motion`; never convey essential feedback by motion alone.
- **State announcement:** never by colour alone; dynamic updates via a live region or managed focus.
- **Touch targets** ~44×44 px minimum on touch-primary form factors.
- **Reflow & zoom:** the 320 px / 200% floor from *Responsive layout*; genuinely two-dimensional content (tables, maps) scrolls in its own box.

An automated a11y check (axe/lighthouse-style) belongs in CI — as the floor, not the bar; it catches only a fraction of these rules.

## Internationalisation (if multilingual)

One language is the **reference**; every other stays in exact parity.

- Dictionaries under `src/i18n/`, one per language.
- **Every new key lands in every language file in the same change.**
- **CI runs a key-parity check** failing on keys missing from a locale *or* present in a locale but absent from the reference — both directions are drift.
- **Name keys by meaning, not location** (`order.confirm_button`, not `page3.btn`).

## Coding standards

- **Never reimplement what the UI library gives you.** A bespoke `<Button>` duplicating the library's is the canonical mistake: it fragments styling, drops solved accessibility, and drifts.
- **Cross-cutting plumbing (API/auth/error-reporting) is a shared hook/service** — wrapped once, never copied into pages.
- **Don't accumulate one-off helpers in `lib/`** — co-locate with the only caller until reuse appears.
- **One shared formatting helper for dates, numbers, currency** — locale and timezone pinned; never inline per-component formatting. (Libraries-over-hand-rolling: root contract.)

Security baseline:

- **No secrets in the bundle** — anything secret stays behind a backend endpoint.
- **Treat rendered data as untrusted:** rely on the framework's default escaping; never bypass it with unsanitised raw HTML.
- **Auth tokens live in one agreed store/service** — default transport is an HTTP-only cookie set by the backend; never `localStorage` sessions unless the active pack registers otherwise.
- **Security headers + CSP at the framework's header layer** — report-only first, then enforcing; allow-list only what the app loads; never `unsafe-inline`/`*` to silence a report. (Exact set: the active pack.)

## Versioning / build identity

A deployed SPA is cached; a user can sit on a stale bundle indefinitely.

- **Make the version visible:** an unobtrusive `v<version>` (e.g. login footer) from `package.json` at build time; bump on every release (semver).
- **Give users a way off a stale bundle:** detect a newer deployed build (build-stamped `version.json` poll, or a new service worker) and show a dismissible "Refresh to update" banner. The user chooses when — never force a reload mid-work.

## Cross-app conventions

Bind the frontend to the backend's cross-cutting machinery — all in shared hooks/services, never per screen.

- **Correlation id is never discarded.** The backend returns one on every response (`x-correlation-id`; error bodies carry `error.correlationId`). The shared error path reads it, shows it unobtrusively ("Error reference: `<id>`"), and attaches it to telemetry.
- **Session & auth UX:** one shared interceptor. **401** → login, preserving the requested URL, returning after sign-in. **403** → the shared "forbidden" state, no bounce to login. Guard against redirect loops; on sign-out clear client/store state. Token refresh is one shared concern.
- **Analytics (if shipped):** one shared service/hook, never inline in components; event names follow a by-meaning taxonomy (`order.checkout_started`, not `page3.click`); a story that emits analytics names its key events in the spec. Vendor-agnostic — no pinned SDK.

## Testing

- **Store slices & `lib/`** — plain unit tests.
- **Services** — network mocked at the edge: assert request shape and response/error mapping; never stub internal methods.
- **Organisms** — behaviour and the four states; the four-state contract is a per-screen test checklist.
- **No broad DOM snapshots** — snapshot the data a component receives, not its markup.
- **At least one automated check runs at the narrow viewport** — the e2e suite (or a representative subset) at minimum supported width as well as the primary. (Mechanism: the active pack.)

## Definition of done — verify a change

Run it; don't infer from reading the code.

- [ ] A **new** screen's initial build is verified against its `design/` mockup — rendered and looked at (screenshot or equivalent). No mockup? The spec sketched and approved the screen first (full loop: `design/README.md`). Later iterations verify against the running app, not the mockup.
- [ ] Dev server started; the touched screen loaded.
- [ ] All four states forced to render — not just read in the code.
- [ ] One keyboard-only pass: tab order sane, focus visible, Esc/Enter behave on any modal.
- [ ] Exercised at the declared primary form factor **and** at ~320 px + 200% zoom — nothing overflows, clips, or scrolls sideways; fixed chrome doesn't overlap content.
- [ ] Evidence stated: which states you exercised and what you saw.
