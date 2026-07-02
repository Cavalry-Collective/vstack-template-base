# Rule Inventory — the zero-loss ledger (T004, FR-004)

> **Disposition log (T022, 2026-07-03).** Streamlining pass complete for the root + generic tiers and meta docs; every rule below verified kept unless annotated here. Exceptions, by file:
> - **CLAUDE.md**: #12 → one-line rule + `design/README.md` owns the lifecycle (F-014); #15 → merged into #23; #29 detail → `specs/README.md` owns slice rules (F-015); #35 detail → `db/CLAUDE.md` owns (F-024). No removals.
> - **README.md**: all 16 kept; #14 generalized (pack staging detail → pack `infra.md`); new steps added (specs cleanup, brand-swap note). No removals.
> - **apps/backend/CLAUDE.md**: #40–#54 relocated (sections promoted); #2/#3/#5/#22 reworded (stack names trimmed). All 56 kept.
> - **apps/frontend/CLAUDE.md**: single-owner merges per F-021 (#5, #13–16, #19, #21, #37, #76, #81, #85, #87 halves); pointers per F-014/F-022/F-038 (#90, #95, #97, #101, #102); 2 rules ADDED (pagination window, dialog sizing — hoisted per F-030). All 102 kept.
> - **db/CLAUDE.md** + migrations README: all 11 kept; 3 rules ADDED (money, timestamps, unique→409 — hoisted per F-030); shared-DB rule single-owner here (F-024).
> - **infra/CLAUDE.md**: all 34 kept; root-principle restatements → pointer (#3/#5/#30 partial); approval/environment rules single-owner in Guardrails (#7, #26, #28, #31); GCP reframed as replaceable default (#2, #25 — F-025).
> - **specs/README.md, design/README.md, add-ons/**, **PR template**: all 55 kept; #2 (specs) gains the directory escape hatch (F-007); 4 rules ADDED to otp-auth (CSPRNG, single-use, bounded TTL, max attempts — F-005).
> - **stacks/README.md**: #6/#15 reworded by F-008 (five-file canon, absence-is-a-statement); rules ADDED: replacements-only registers (F-028), standalone packs (F-031), per-area skeleton + manifest shape (F-029). All 15 accounted.
> - **Stack packs**: dispositions recorded per pack in the US4 pass (below in each pack's section spirit); hoisted duplicates marked `merged → db/CLAUDE.md` / `apps/frontend/CLAUDE.md`.
>
> Zero rules removed anywhere; zero removals lacking an approved finding.

**Captured**: 2026-07-03 at commit bdd463d, before any streamlining edit.

Every actionable rule in the non-vendored guidance corpus, one line per rule, grouped by source file. **Rule ID = `<file> #<n>`** (file heading + ordinal within it) — a practical adaptation of the data model's `R-###`. **Disposition convention**: a rule with no annotation is `kept` (still present in the streamlined file, possibly reworded). Only exceptions are annotated inline during US2/US4/US5: `[merged → <file>#<n>]`, `[moved → <file>]`, or `[REMOVED — F-### approval]`. The T022/T035 sweeps verify no rule is missing an owner and no removal lacks an approved finding.

## CLAUDE.md (root)

1. Never use persistent file-based memory; record cross-session notes in the **Learnings** section instead.
2. Read the matching area file before working there: `apps/backend/CLAUDE.md`, `apps/frontend/CLAUDE.md`, `db/CLAUDE.md`, `infra/CLAUDE.md`.
3. Migrations live under `db/migrations/` and are reversible.
4. Stack packs: one chosen at instantiation, rest deleted; read the adopted pack's matching appendix before working in an area.
5. Add-ons: every directory kept under `add-ons/` is adopted — read its README and follow it whenever touching that capability.
6. If Common commands are still `<pm>`/TODO: detect the real command from lockfile/manifest/Makefile/CI; never run literal `<pm>`; never guess a package manager; if undeterminable, stop and ask.
7. After learning real commands, offer to fill in the Common commands block and `.github/workflows/ci.yml`.
8. When instantiating the template, work through the README Day-1 checklist before feature work.
9. Deployment goes through CI/CD with workflows under `.github/workflows/`; never invoke a local deploy path as part of normal work.
10. Backend: onion architecture (Domain → Service → Repo/Controller), dependencies inward via ports; cross-cutting concerns as decorators/aspects, not per-handler middleware.
11. Frontend: store/services/pages/components layering; consistent loading/error/empty/success states; reuse base UI primitives.
12. `design/` mockups are reference only (not buildable); source for visual design/screen inventory/copy/flows on a screen's *initial build* only; never copy mockup code; after first build the running app is the reference — don't re-check later changes against the mockup; point mockup files at the spec when planning a new screen.
13. Keep cross-cutting concerns in shared decorators/plugins (backend) or hooks/services (frontend); don't duplicate them.
14. Keep `utils/`/`lib/` pure and un-peppered.
15. Use real libraries instead of hand-rolling — especially dates.
16. Config: read from environment in one place per app, validated at startup against a declared schema, fail fast with a named error; `.env.example` is the canonical documented variable list, updated in the same change that adds a key; inner layers never read config directly — it is passed inward as values.
17. Readable code is a review priority; assess whether names make intent clear without reconstructing implementation.
18. Naming: no non-standard abbreviations; precise over short; no misleading names; no single-letter variables except trivial loop counters/math convention; names reflect business meaning, not mechanics.
19. Think before coding: state assumptions, ask when uncertain, present multiple interpretations, suggest simpler alternatives and push back, name confusion instead of proceeding.
20. Simplicity/YAGNI: minimum code, nothing speculative; every added complexity must defeat the explicitly rejected simpler alternative; "might want later" is not justification; rewrite 200 lines to 50.
21. Change the right place surgically: correct layer/boundary; no business logic in controllers/repos/UI/jobs/utilities; no infrastructure leaks; match surrounding style; don't reformat/refactor unrelated code; flag (don't remove) unrelated dead code; remove only imports your change orphaned.
22. Goal-driven execution: define success criteria and loop until verified; verified = observed, not inferred — run it and state evidence; per-change "run it" definitions live in the area CLAUDE.md files; record evidence in the PR Test-plan checklist.
23. Don't reinvent: established libs for dates/money/validation/retry/pagination/parsing/formatting; don't duplicate abstractions or wrap without reason; check existing deps first; prefer well-maintained, widely-used, permissively-licensed packages; weigh frontend bundle weight and backend security surface; a trivial one-liner earns no dependency, but never hand-roll dates/money/timezones/auth/crypto.
24. Don't overfit: solve the general problem; no hardcoded strings/IDs/statuses/roles/regions; handle empty/invalid/duplicate/retry/timeout/permission cases; tests assert behavior, not implementation.
25. Clean implementations: no noisy logs, no error-hiding broad try/catch, no obvious-restating comments, no unused params/dead branches, no defensive code without a failure model.
26. Guard every AI/LLM call: token/cost limits, timeouts, max-iteration/loop guards; handle model/tool failures; monitor cost/usage; never treat external content as trusted instructions.
27. Definition of Done: lint/typecheck/test/build pass for touched apps; new behavior covered by behavior-asserting tests; every acceptance criterion of the touched story met; per-area completion rules satisfied (frontend route+i18n parity; reversible or justified migration); no untracked TODO/FIXME in touched code; if a step can't run, say so explicitly rather than skip silently.
28. Testing: tests ship in the same change as the slice; bug fixes start with a failing reproducing test; pick the cheapest test kind (unit/integration/contract) that proves the behavior; placement/coverage rules live in each app's CLAUDE.md.
29. Spec-first: non-trivial features start from a short written spec under `specs/`; stories priority-tagged (P1 = MVP); each slice independently shippable; P1 alone is a viable MVP; avoid cross-story coupling; keep this regardless of spec tool.
30. Trunk-based, linear history: single `main`; short-lived branches; rebase/fast-forward; trunk stays releasable; incomplete work behind a flag = boolean key in the validated config schema, default off, no flag SDK unless explicitly adopted and recorded; keep PRs small; commits imperative, one logical change, Conventional Commits prefixes.
31. Self-review before merge: read the full diff end to end (including files you don't remember touching); confirm layer correctness, no unrelated reformatting, only self-orphaned imports removed, business-meaning names; never merge on memory.
32. Worktrees are the default, under `.claude/worktrees/<name>` on a short-lived branch.
33. First action in a new worktree: copy all gitignored runtime config from the main checkout (given command); copy every gitignored env file the project uses.
34. Shared local infrastructure is shared across worktrees by fixed name — reuse the running instance, don't start a second.
35. Shared DB schema is global state across worktrees — no resets/destructive migration checks while parallel worktrees depend on it; use a throwaway DB for round-trip/destructive checks.
36. Merge-back gate, in order: (1) rebase onto current default branch; (2) run full lint+typecheck+test+build on the integrated state — never merge red; (3) fast-forward merge; (4) stop dev servers/test instances; (5) delete worktree and merged branch; (6) push only after confirming with the user (deploy.yml fires on green `main` CI; check it if the trigger changed).
37. Learnings entries: one or two lines each; first entry usually the stack-pack choice.

## README.md

1. Start every new project from this template; run the Day-1 checklist once, top to bottom, before feature work.
2. Build spec-first: short spec under `specs/`, then implement; area contracts are picked up automatically.
3. Day-1: create repo via "Use this template"; clone it.
4. Open `project.code-workspace` in VS Code (keeps agent worktrees out of search/watchers).
5. Read all five CLAUDE.md contract files.
6. Pack path: pick one `stacks/` pack; `rm -rf` every other pack directory; copy the pack's **dev** command block into root CLAUDE.md Common commands (delete the banner) and its **CI** block into `ci.yml` — never paste a dev-only migration command into CI; record the choice in root CLAUDE.md Learnings (`Stack: <pack-name>; appendices under stacks/<pack-name>/`).
7. Agnostic path: keep or delete `stacks/`; fill the toolchain yourself.
8. Add-ons: keep the capability directories you want, delete the rest — every kept directory is adopted.
9. Agnostic toolchain fill-in: replace the seven `<pm>`/TODO commands and delete the banner; fill `ci.yml` TODOs including i18n key-parity and migration up/down round-trip; fill the `deploy.yml` TODO; add a real `.env.example` (whitelisted in `.gitignore`).
10. Declare the primary form factor in `apps/frontend/CLAUDE.md` (`mobile-first | desktop-first | responsive-equal`).
11. Rebrand and confirm the design guide before building any screen: edit the primitive tier in `tokens.css` (or regenerate from your brand), open the guide in a browser, confirm coherence; don't build screens against an unconfirmed system.
12. Copy gitignored runtime config (`.env`, secrets) into the local checkout.
13. Protect `main`: branch protection requiring CI to pass before merge; on ship-on-main packs, green-CI-before-merge *is* the deploy gate.
14. Stand up staging if the pack defines one (vercel: `develop` branch + dedicated Neon branch, migrated with the pack's manual runbook).
15. Confirm green: watch the first CI run pass; run the two greps to confirm no placeholder survives; optionally delete the README checklist after instantiation.
16. If the server-first `nextjs-nestjs-postgres` pack is chosen, soften the SPA framing in root CLAUDE.md ("the single-page app" → "the web frontend") and the What's-included "Frontend SPA" row.

## specs/README.md

1. Non-trivial features start from a short written spec here before implementation.
2. One file per feature: `YYYY-MM-DD-<feature-name>.md`.
3. Tag stories P1 (MVP, must ship) / P2 / P3; each story independently shippable; avoid cross-story coupling; P1 alone forms a viable MVP.
4. Spec contents: Goal (one sentence); priority-tagged user stories with acceptance criteria *plus how each is verified* (exact command/endpoint/screen+states); Out of scope list; Open questions with deadline or owner; UX & non-functional notes (form-factor impact, loading/error/empty states, perf/security) as one short list.
5. A UI story building a new screen names the `design/` mockup file(s) it implements; "matches the referenced mockup" is part of done for the initial build; later iterations verify against the running app.
6. If no mockup exists for a new screen: record under Open questions and resolve before implementation — don't invent the design.
7. Workflow: spec approved → short-lived branch → PR that links the spec.
8. A story is done only when every acceptance criterion is demonstrated by its stated verification; capture evidence in the PR Test-plan checklist.
9. Merged specs stay as a record of the decision.

## design/README.md

1. `design/` is reference only, not part of the buildable workspace; drop mockups here as the source for visual design, screen inventory, copy, and flows.
2. Do not copy mockup code into the apps.
3. The folder also holds the design guide (`design-guide.html` + `tokens.css`) — the visual keystone confirmed before any UI work.
4. Keep the inventory table current as screens are added; columns: screen (semantic name) · mockup file/folder · owning spec.
5. The screen name must match the central route registry in `apps/frontend/CLAUDE.md`; the table carries no route column (the registry stays the only route→URL surface).
6. One file or folder per screen, named by the screen's semantic name — never by tool export names.
7. Show flows via mockup ordering/links or an optional flow file; don't mandate separate flow diagrams.
8. A screen's initial build is verified against its design reference — never declared done from reading code; later changes verify against the running app, not the mockup.
9. With a mockup: after the first build, run the app, view at the declared primary form factor plus the other end of the responsive baseline, compare to the mockup, iterate until layout/spacing/hierarchy/copy match; capture and actually look at rendered output (screenshot or equivalent); capture tool is per-project, the view-and-compare step is mandatory.
10. Without a mockup, non-trivial new screen: sketch screens/copy/flow in the feature spec and get approval there (reuse the spec gate, no second approval process); never improvise UI for a non-trivial new screen.
11. Minor changes to an existing screen: build to `apps/frontend/CLAUDE.md` conventions and note "built to convention, no mockup" in the PR.

## apps/backend/CLAUDE.md

1. Read this file before touching anything under `apps/backend/`; repo-wide rules live in the root `CLAUDE.md`.
2. If a stack pack is adopted, read its `backend.md` appendix before working here; its conflict register overrides this file for that stack only.
3. Treat file extensions and framework specifics in examples (`container.js`, Express/Fastify-style) as illustrative, not mandates.
4. Dependencies point inward; nothing in an inner ring knows anything about an outer ring; the domain depends on nothing.
5. Inner rings needing outer capabilities define a port (interface in typed languages; agreed duck-typed shape, optionally a JSDoc `@typedef`, in untyped); the implementation is supplied from outside.
6. Data crosses boundaries translated: DTOs at the edge, domain objects inside; HTTP requests, DB rows, and SDK objects never travel inward and are never imported or named by the domain.
7. Boundary test: what's outside must be swappable without touching what's inside; if a change wants an outward dependency, reshape the change, not the rule.
8. Four rings from centre out: Domain → Service → Repo/Controller; Repo and Controller are peer outer adapters that never depend on each other.
9. Domain holds entities, value objects, domain services, invariants, and defines the ports; pure and stateless — no I/O, DB handle, clock, network, or framework types; never names a technology.
10. Express domain rules so they are testable in isolation (a rule testable only via a database is mis-shaped); keep the domain ring small, dense, protected.
11. Service orchestrates one use case end to end and owns the transaction boundary — one transaction per use case.
12. Service depends only on the domain and its ports; never touches HTTP concepts, builds queries, or reaches for framework globals.
13. Repo ring implements the ports (DB repositories + external-service clients); each adapter carries a mapper so storage/external shapes stop at this boundary.
14. Repo never holds business rules; branching beyond what a query/call needs means a rule leaked out of the domain.
15. Controller handlers validate input, invoke exactly one use case, map the result out; auth guards live here.
16. Controller never holds business logic, transactions, or queries, and never reaches past the service into the repo ring.
17. Organise by feature first, layers within: `modules/<feature>/{domain,service,repo,controller,dtos}` plus `shared/{aspects,utils}` and a composition root; add a ring folder only when it earns one.
18. A module never imports another module's inner rings — cross-module use goes through the other module's service or a shared port.
19. `shared/utils/` is pure/stateless with no I/O or framework; `shared/aspects/` wrap a ring and depend inward only.
20. Wire ports to implementations only in the composition root; inner rings receive dependencies via constructor/factory and never import a concrete adapter.
21. The composition root is the only place knowing both a port and its implementation; adapter swaps happen there and nowhere else.
22. Manual constructor wiring by default; adopt a DI container only when the graph grows unwieldy.
23. Test per ring: domain = pure unit tests (no mocks/I/O); service = use-case tests with in-memory port fakes; repo = integration tests against a real DB/sandbox; controller = contract tests (status codes, validation, guards, schemas); most coverage in the inner rings, thinning outward.
24. Verify a backend change: run the touched module's tests; exercise the endpoint over HTTP (happy path + at least one error path); confirm status code, error shape, and correlation id; state what you observed, not just that you ran it.
25. REST naming: plural lowercase nouns, hyphens for multi-word, parent–child in path segments.
26. Version/visibility prefixes `/internal/v1` and `/external/v1`; default to internal when unclear; never expose externally until consumers, permissions, and contract are clear.
27. Methods: GET retrieve, POST create, PUT full replace, DELETE remove; no PATCH by default — only as a project-wide decision with documented merge semantics; flag method/intent mismatches.
28. Pagination: `page`/`recordsPerPage`/`sortBy`/`sortOrder` params after resource filters; one envelope `{data, page, recordsPerPage, totalRecords}`; empty result is `200` + `[]`, never `404`; flag unbounded list endpoints.
29. Use the standard status-code set (200/201/204/400/401/403/404/409/429/500); flag unclear or misleading codes.
30. One error envelope `{error:{code,message,correlationId}}` produced only at the single error-mapping site; `code` is stable SCREAMING_SNAKE_CASE in domain terms (clients branch on it, never parse `message`); `message` is human-safe (no stack traces/SQL/internal ids); `400` may add `error.details` `[{field,message}]`.
31. Correlation id also travels as the `x-correlation-id` header on every response, success or failure.
32. Success shapes: single resource is the bare object; lists use the pagination envelope.
33. Every endpoint defines permissions, request/response schema, validation rules, and error behaviour; every field defines name, type, required/optional, description, constraints.
34. Cross-cutting concerns are decorators/aspects declared once and applied declaratively; scope each to the subtree that needs it, not globally; each obeys the dependency rule and passes data inward as plain values.
35. Edge guards reject unauthenticated requests; authorisation depending on domain state lives in the domain/use case.
36. Request context/identity is established at the edge and passed inward as an argument, never read from a global.
37. Logging: one shared path carrying the correlation id; structured key/value records at levels (error/warn/info/debug-behind-flag); never log secrets, tokens, credentials, auth headers, or PII — redact at the boundary, log identifiers not payloads; log a failure once, where handled.
38. Audit trail is distinct from logging: one shared `record()` call per meaningful state change (actor, action, target, before/after) in the service ring, to durable queryable storage, carrying the correlation id.
39. The domain raises failures in domain terms; the controller ring is the single place mapping them to transport responses.
40. Validate state transitions against the rules before applying a status/lifecycle change — never merely because an external request/callback/event asked.
41. Treat every external API, callback, webhook, queue, and event as untrusted and unreliable; the integration is a repo-ring adapter, its decisions live in the domain.
42. Idempotency: handle retries/replays without duplicating actions; key on the primary business record id unless a clearer business key exists.
43. Concurrency: assume parallel workers; use conditional updates, locking, transactions, or version checks.
44. Validate structure, required fields, types, business rules, authenticity, and ownership before sending or applying anything.
45. Where order matters, process by event time / sequence / business rule, not arrival order.
46. Classify failures (transient/permanent/invalid/unsupported/duplicate/unknown); retry only transient with bounded retries + backoff and a defined final-failure path.
47. Never treat a timeout, transport error, malformed/ambiguous response as success; preserve valid data and route to reconciliation or manual recovery.
48. Gate risky integrations (SMS/email/payment/push) behind a default-off validated-config boolean read in one place, routing to a no-op sink when off; flipping it off is the rollback.
49. Parameterised data access only — never interpolate request data into query/filter strings.
50. Secrets come from the environment, never hardcoded/committed/echoed; inner rings receive config as injected values, not globals.
51. Verify ownership on every client-supplied id before acting on the record.
52. Send standard security headers + CSP from one shared place; roll out new/tightened CSP report-only first, then enforce (exact set: stack pack).
53. SSRF guard on user-supplied URLs: allowed schemes and public hosts only; reject loopback/private/link-local/metadata targets, validated at save *and* call time.
54. Secrets stored through the API are write-only: never returned on read (only a "configured" indicator); blank on update means keep existing.
55. Dates/timezones, phone canonicalisation, identifiers, CSV, and schema validation use an established library via a single shared helper — never hand-rolled (root rule).
56. Schema changes only via reversible migrations under `db/`; never issue DDL from application code — repo adapters read the schema, never mutate it.

## apps/frontend/CLAUDE.md

1. Read this file before touching anything under `apps/frontend/`; repo-wide rules live in the root `CLAUDE.md`.
2. If a stack pack is adopted, read its `frontend.md` appendix first; its conflict register overrides this file for that stack only.
3. Two axes never blur: horizontal layers (store/service/page/component) and vertical feature slices; components follow atomic design.
4. Mirror the prescribed `src/` layout (store, services, pages, components/{atoms,molecules,organisms/<feature>,templates}, i18n, lib, single route registry, single token source); file extensions/framework specifics are illustrative.
5. Atoms/molecules are grouped by type, shared globally, and carry no business vocabulary; organisms are grouped by feature; a feature slice spans `store/<f>` + `services/<f>` + `organisms/<f>` and is removable as a unit.
6. Promote code into `atoms/`/`molecules/`/`lib/` only once genuinely shared — not in anticipation of reuse.
7. Each layer depends only on layers beneath it, never upward.
8. Store owns application state, one slice per domain; may depend on services; never imports a page or renders.
9. Services own all data fetching/mutation; each domain mirrors a backend route group; all network access lives here; never hold view state.
10. The backend endpoint contract is the single source of truth for shapes and status codes; the service mirrors it, never invents its own shape.
11. Prefer a generated/shared contract artifact; otherwise every contract change is one PR touching backend endpoint + mirroring frontend service together.
12. Validate responses against the declared shape so a contract break surfaces as a typed error feeding the `error` state.
13. Pages compose organisms, hold no business logic, never fetch directly or embed reusable UI inline.
14. Templates arrange organisms with no real data and hold no business logic.
15. Organisms may use atoms/molecules/lib; never imported by a primitive.
16. Shared primitives depend only on the UI library and design tokens; never know a feature or page.
17. Loading/error/empty/success states handled consistently on every data-backed screen.
18. Empty states are designed, not blank: state why + primary next action; distinguish first-run, no-results/filtered, and access-restricted; a load failure is an error state with retry, never an empty state.
19. Don't accumulate one-off helpers in `src/lib/` — co-locate with the only caller until reuse appears.
20. URLs stay clean and human-meaningful; never expose internal build/source paths.
21. One central route registry; register the route the moment the page is created; audit routing by reading the registry; maintain no second route list anywhere.
22. Build URLs via named routes from the registry, never by concatenating path strings.
23. Lock the visual system in the design guide (`design/design-guide.html`, rendered live from `design/tokens.css`) before building any screen; the guide is foundations-only by design.
24. Confirm-the-guide gate: for a new project or rebrand, no screen/component work until the guide reflects the brand, is browser-reviewed, and signed off; established systems don't re-gate small additions, but a new foundational token lands in the guide first.
25. Customise by editing the primitive token tier, not screens; semantic tier and guide re-derive.
26. Every component consumes semantic tokens, follows the guide's state ladder and focus spec, and meets its accessibility floor; a component violating a foundation is the defect; recurring cross-project patterns earn a guide specimen.
27. Gate 1: every colour, size, space, and duration resolves to a semantic token — a hex or px literal in a screen is a defect.
28. Gate 2: pick the screen archetype before building; its zones, rhythm, and width are fixed, never re-derived per page.
29. Gate 3: surface ladder — no card-like container inside another; separate in order whitespace → background shift → border → divider (tables/dense rows only).
30. Gate 4: reuse first — archetype → documented pattern → existing screens/primitives → extend a primitive → only then new, with the PR recording why nothing fit.
31. Gate 5: one density app-wide, set at the token layer, never mixed within a page hierarchy.
32. Gate 6: forms and view states follow the guide's composition patterns; the pattern outranks the component library's defaults.
33. Declare the primary form factor + supported viewport range at setup (deliberate placeholder).
34. One shared layout supplies all standing furniture; pages provide content only; the layout owns every clearance/inset via one clearance token; top-spacing variants are a layout prop the page picks.
35. Layouts are responsive by default across the declared range; no fixed pixel widths that break reflow.
36. One token source, three tiers (primitive/semantic/component); pages and components consume semantic tokens and never reach past them to raw primitives.
37. Guard committed token values against their documented scale with a check.
38. Author from the smallest supported width up; floor is WCAG reflow at 320 CSS px and 200% text zoom.
39. Prefer intrinsic sizing; reusable components adapt to container width; add viewport breakpoints last, only for genuine page-level layout changes.
40. No horizontal overflow at minimum width: atomic values never wrap mid-token (shared no-wrap primitive); free text wraps/truncates; flex/grid children get `min-width: 0`; wide tables/code scroll in their own box, never the page.
41. Reserve fixed/sticky chrome space with one semantic clearance token applied by the shared layout, never re-measured per page.
42. Size full-bleed sections to content, not viewport; prefer `svh` over `vh`; `dvh` only deliberately.
43. Treat configurable copy as variable-length (survives one-word and three-line values); balance headings by default.
44. Multi-field rows collapse to full width below the breakpoint, each field keeping a legible min-width.
45. Adapt by disclosure, never by hiding meaning — collapse nav into a menu; never drop destinations/actions on small screens.
46. Render overlays and fixed chrome in a top-level portal.
47. Reset/restore scroll in an effect keyed on the actual route/view change; a keep-alive surface has one explicit scroll owner.
48. Global-nav visibility is a denylist of chrome-less routes, not an allowlist.
49. Under the soft keyboard the flex column scrolls (`overflow-y: auto`; non-shrinkable panels `flex-shrink: 0`), it does not squeeze.
50. Type: one modular scale; ≤2 font families; ~4 sizes and ~2 weights per screen; 60–75ch body measure; a new size is a new scale step in tokens.
51. Spacing: every margin/padding/gap resolves to an existing scale step; fix the scale, not the instance.
52. Hierarchy: exactly one primary (filled) action per view; one H1 per page; heading levels never skip.
53. Colour: semantic intent tokens; never encode meaning in colour alone (pair with text/icon); limit accent surfaces so the primary CTA dominates.
54. Content aligns to the shared layout's grid/gutters; density follows the declared form factor and stays consistent within a view.
55. Control states (pressed/active, focus-visible, disabled) are defined on shared primitives from semantic tokens; touch-primary paths always show press feedback; surface the headless foundation's focus-visible, don't suppress it.
56. In-flight feedback stays on the triggering control (inline busy + disable); full-screen/section loading only for a screen's initial fetch.
57. Prefer optimistic updates for low-risk mutations with rollback + error message; blocking spinners only for genuinely blocking waits.
58. Initial load uses skeletons matching final layout; short waits use a spinner; no spinner-to-content layout shift.
59. Delay busy indicators (~150 ms) with a minimum visible time; debounce live search/filter (~250 ms); tunable defaults, not magic numbers.
60. Move focus deliberately after navigational/destructive actions (next logical element, confirmation, or back to trigger).
61. Validation: validate a field on blur after first interaction, whole form on submit; re-validate erroring fields on change; never error on first keystroke.
62. Field errors inline, `aria-describedby`-associated, conveyed by more than colour; failed submit moves focus to first invalid field.
63. Destructive actions require an explicit confirm naming the consequence; irreversible/high-risk actions require deliberate (typed) confirmation.
64. Warn before discarding meaningful unsaved edits on route change and browser unload; not for trivial inputs.
65. Disable the submit control in flight and prevent re-submission; surface progress via the shared loading/error/success convention.
66. Uniform capitalization project-wide; default sentence case except proper nouns.
67. Action labels are verb-first and specific ("Save changes", not "OK"/"Submit").
68. Error copy is actionable and blame-free; never exposes stack traces, status codes, internal ids, or raw exception text.
69. Empty/loading/success copy is concise and human.
70. Centralize user-facing copy (i18n dictionaries or a single strings module); no hardcoded display literals in components.
71. Five atomic tiers over a headless foundation you never skip; the foundation is a dependency, not a folder, and solves focus/keyboard/widget-ARIA for components routed through it.
72. Tier crossover test: speaks the business's language → organism (feature-owned); generic → atom/molecule (shared).
73. Reuse-first: search `atoms/`/`molecules/` before building; a second variant of an existing component is the canonical failure.
74. Never build a one-off header, button, input, modal, table, or icon button; wrap shared components from the start.
75. No feature-specific atoms or molecules: genuinely generic → global `molecules/`; business-meaning → organism.
76. Audit periodically for duplicated components; two components rendering the same thing are a defect to merge.
77. Colour tokens meet WCAG 2.1 AA against intended backgrounds (4.5:1 body, 3:1 large text/UI boundaries) — a constraint on the token set.
78. Every interactive element keyboard-reachable/operable; visible focus indicator; never remove the outline without a token-based replacement.
79. Logical focus order; modals trap focus and restore to trigger on close.
80. All inputs labeled; icon-only controls have accessible names; images have alt text or are marked decorative.
81. One H1, no skipped heading levels, correct landmark regions.
82. Honour `prefers-reduced-motion`; never convey essential feedback by motion alone.
83. Never convey state by colour alone; announce dynamic updates via live region or managed focus.
84. Touch targets ~44×44px minimum on touch-primary form factors only.
85. Content reflows at 320 px width and 200% zoom; genuinely 2-D content scrolls in its own box.
86. An automated a11y check runs in CI alongside lint/test/build; automation is the floor, not the bar.
87. i18n (if multilingual): one reference language; one dictionary per language under `src/i18n/`; every new key added to every language in the same change; CI key-parity check failing on drift in both directions; keys named by meaning, not location.
88. Never reimplement what the UI library gives you; typography/buttons/inputs are wrapped through the shared atoms/molecules tier.
89. Cross-cutting concerns live in shared hooks/services, never duplicated per screen.
90. Use libraries instead of hand-rolling — especially dates (root rule).
91. No secrets or API keys in the SPA bundle; secrets stay server-side behind a backend endpoint.
92. Treat all rendered server/user data as untrusted; rely on default escaping; never inject raw HTML with unsanitised input.
93. Auth tokens live in the one agreed store/service, never scattered or hand-read in views.
94. App sends security headers + CSP at the framework's header layer; report-only first, then enforce; allow-list only real origins; never `unsafe-inline`/`*` to silence reports.
95. Render an unobtrusive version tag sourced from the package manifest at build time; bump semver every release.
96. Detect stale bundles and show a dismissible "Refresh to update" prompt; never force a reload.
97. Correlation id is never discarded: shared error path reads it from failed responses, shows it as an error reference in the UI, and attaches it to telemetry.
98. One shared services-layer auth interceptor: 401 → login preserving the requested URL and returning after sign-in; 403 → shared forbidden state, no login bounce; guard redirect loops; sign-out clears client/store state; token/session refresh is one shared concern.
99. Analytics (if shipped) go through one shared service/hook with a by-meaning event taxonomy; UI stories name their key events in the spec; stay vendor-agnostic.
100. Testing: store slices and lib helpers as plain units; services with network mocked at the edge (assert request shape + response/error mapping); organisms for behaviour + the four states; no broad DOM snapshots; at least one automated check runs at the narrow viewport.
101. Verify: a new screen's initial build is verified against its `design/` mockup by rendering and looking; no mockup → sketch in spec and get approval; later iterations verify against the running app.
102. Verify: start the dev server, load the touched screen, force all four states, do a keyboard-only pass, exercise the primary form factor plus minimum width and 200% zoom, and state what you observed.

## db/CLAUDE.md

1. Read this file before touching anything under `db/`; if a stack pack is adopted, read its `db.md` appendix first; its conflict register wins for that stack only.
2. Migration files are timestamp-prefixed with a short description, monotonic, never reused; never a hand-incremented sequence; before merging, rebase and confirm your migration sorts after everything on trunk.
3. Every migration is reversible (up + down) OR carries an explicit irreversible-change justification comment — never neither.
4. Never edit a merged/applied migration; fix forward with a new one.
5. Keep schema migrations separate from data backfills; backfills are batched, idempotent, resumable.
6. Destructive/non-additive changes follow expand → migrate → contract across separate migrations/releases.
7. Prove the round-trip (up, down, up) on a throwaway scratch DB before merging; state the evidence observed.
8. Run each migration in a transaction where the engine supports it.
9. Seed/reset scripts are idempotent and non-production only; use realistic, named seed data (not `user1`/`user2`); seeds back the test-mode add-on picker if adopted.
10. The local DB is global state shared across worktrees; run round-trip/destructive checks against a throwaway DB, never the shared one, while parallel worktrees depend on the schema.

## db/migrations/README.md

1. Migrations live in this folder; rules are in `../CLAUDE.md` (pointer only — the file contains no rules of its own).

## infra/CLAUDE.md

1. Read this file before touching anything under `infra/`; if the adopted stack pack ships an `infra.md`, read it first; its conflict register wins for that stack only.
2. GCP is the template's blessed cloud; (GCP)-marked items apply there; on AWS/Azure use the equivalent context/auth/discovery tooling.
3. Prefer the smallest change that solves the request; scope to the requested environment and outcome.
4. Optimize for readability and straightforward rollback; prefer stable patterns over clever abstractions; preserve existing repo conventions absent strong reason.
5. Treat all infrastructure changes as potentially high impact until proven otherwise.
6. Run Terraform commands from inside `infra/<workload>/`, never from `infra/` or the git root.
7. Never assume a change applies to all environments; make the target environment explicit in summaries and approvals.
8. Set up observability (metrics, logs, product analytics for user-facing apps; retained and queryable) from day 1; give it its own concern file where IaC owns it; platform wiring lives in the stack pack.
9. At the start of each chat, verify active cloud auth/context, run the provider's context-listing command outside the sandbox, show contexts, and ask which to use; never assume the previous context.
10. Read-only tasks (inspection, search, tracing, `fmt -check`, `validate`, `plan`, diffs) proceed automatically without confirmation between steps.
11. Mutations follow the sequence: understand env/outcome → inspect config → smallest change → format+validate → plan → present the risk-review format → ask approval before `apply`.
12. Prefer explicit individually named `resource` blocks; no `for_each`/`count`/`dynamic`/`locals` collections to generate resources unless the user requests it or a clear repo convention requires it.
13. Favor repetition over abstraction when it improves readability, reviewability, importability, and rollback clarity.
14. No `lifecycle.ignore_changes` unless the user confirms the diff is noisy and intentionally acceptable.
15. Prefer importing existing resources over replacing them; replace only when explicitly requested or clearly safer; after import, Terraform is that resource's source of truth.
16. Import the smallest scope; never bulk-import a project/folder/org unless explicitly requested; large imports may bootstrap drafts with a provider export tool.
17. Generated import output is scaffolding: reshape to the folder's conventions (named blocks, no generated loops, no ignore_changes, provider-default churn removed) before merging.
18. Before import approval: identify exact environment/resources, confirm import IDs and addresses, run plan, review all drift, call out additions/changes/replacements/deletions/IAM/networking/stateful risk.
19. Present every apply request in the prescribed format: plan summary (environment), planned actions (add/change/replace/destroy, skipping empty sections), and a four-dimension risk checklist (security, availability, data durability, cost).
20. `infra/` is organized per workload; each subdirectory is a self-contained Terraform root module with its own `backend.tf` and `terraform.tfvars`, mapping to a single project.
21. No cross-workload references or shared local modules without explicit approval; new workloads follow the same self-contained pattern.
22. Introduce `infra/modules/` only after concrete duplication across at least two workloads; keep modules focused on the genuinely shared concern; modules still follow the explicit authoring style.
23. Group `.tf` files by concern with predictable names; avoid excessive fragmentation; split oversized categories with still-specific names.
24. Commit `.terraform.lock.hcl` (adding teammate/CI platforms via `terraform providers lock`); keep `.terraform/`, plan artifacts, and generated local execution artifacts out of version control; plan files are local and ephemeral.
25. Do not use default VPCs/subnets; use a custom-mode network with explicit subnets, ranges, firewall rules, and NAT; call out existing default-VPC usage and propose migration; same intent on any provider.
26. Never run destructive actions without explicit confirmation; never `terraform apply` without explicit user approval.
27. Treat deletion, replacement, and security-boundary changes as high risk; production requires extra caution even for small changes.
28. Always state the target environment before asking approval; never hide or collapse destructive/replacement actions in the plan summary.
29. Never edit Terraform state directly unless the user explicitly requests a state operation with risks explained.
30. Do only what the request asks; avoid unrelated refactors/renames/moves; call out assumptions; keep environment boundaries strict; state explicitly when a shared-module change affects multiple environments.
31. Never apply without a reviewed plan; if a plan cannot run, never guess the impact — explain why; always state the environment being planned/applied.
32. Never commit secrets, credentials, keys, tokens, certificates, or private data; no hardcoded secrets in `.tf` or checked-in `.tfvars`; inject via CI/CD env vars, secret managers, runtime injection, or gitignored local overrides.
33. Mark sensitive input variables `sensitive = true`; avoid sensitive outputs.
34. Out of scope unless explicitly requested: broad architecture migrations, provider/platform switches, state/backend migrations, CI policy changes, cross-environment restructuring, module redesign beyond the task.

## stacks/README.md

1. A stack pack rides on top of the base: adds bindings and resolves conflicts, never restates the base.
2. Exactly one pack is chosen at instantiation; delete the rest so "the adopted pack" is unambiguous.
3. Packs are guidance-as-text: config/command snippets to copy — no installed deps, lockfiles, or scaffolding in the buildable tree.
4. Name packs `<frontend>-<backend>-<database>`, lowercase-hyphenated; append the client/ORM when it is the distinguishing choice.
5. Platform exception: a platform-identity pack may be named for the platform; its README records the would-be triple; rename if a second pack on that platform appears.
6. Every pack carries at least README.md, backend.md, frontend.md, db.md; `infra.md` is the only optional fifth. *(superseded by the five-file canon if F-008 is approved)*
7. Additions-only: if a line is true without naming the stack, it does not belong in a pack.
8. Register or obey: any base override (even structural) exists only via a conflict-register entry; a silent contradiction invalidates the pack; layer separation and one-way dependencies may never be dropped.
9. Verbatim precedence line atop every appendix.
10. Conflict register ends every appendix; entry shape: Base says / In this stack / Because / Concretely (one checkable DO/DON'T); a zero-conflict appendix states the no-conflicts line.
11. No project-specific values: no DB URLs, secrets, env, per-project form-factor declarations, or route tables.
12. Size discipline: each appendix well under 200 lines, terse and checkable.
13. Activation by instruction: each area's CLAUDE.md points at the adopted pack's matching appendix; appendices are read in place from `stacks/` (no generated copies).
14. To add a pack: create the four files, precedence line + register, write the manifest README (identity, mapping, dev+CI `<pm>` blocks, deploy-seam pointer); nothing else to wire.
15. `infra.md` may be added later under the same invariants. *(superseded by the five-file canon if F-008 is approved)*

## stacks/nextjs-nestjs-postgres/ (README.md, backend.md, frontend.md, db.md)

*README.md*

1. Identity: Next.js App Router (server-first) / NestJS / Postgres via Prisma; TypeScript or plain JS with JS-path notes per appendix.
2. Conflicts live in the appendices, never in the manifest.
3. Day-1: delete every other `stacks/*` directory; copy the dev block over root Common commands (delete the banner); copy the CI block into `ci.yml`; never the same block in both.
4. Never `prisma migrate dev` in CI (it can reset the DB or prompt); CI uses `prisma migrate deploy`.
5. Suggested toolchain pnpm workspaces; the seven root verbs bound (bootstrap/dev/lint/typecheck/test/build/migrate = `prisma migrate dev` locally).
6. CI: Postgres service container; `pnpm install --frozen-lockfile`; `prisma generate`; `migrate deploy`; typecheck; both builds; non-watch tests; keep one verb per base placeholder if swapping tools.
7. Zod is the schema library at the NestJS edge and for Next form/response schemas; a shared shape is defined once and reused; no class-validator.
8. Deploy seam: `prisma migrate deploy` + Next build ship through the cloud pipeline per `infra/CLAUDE.md`; pack ships no infra.md. *(superseded by the n/a-stub if F-009 is approved)*

*backend.md*

9. Rules are language-neutral; TS is the default spine; JS deltas flagged `JS:` or collected in `## JavaScript path`.
10. HTTP: NestJS on the Fastify adapter (rejected: Express); Express acceptable with a concrete reason recorded in the pack README.
11. Prisma is owned by `db/`; this file covers only how it is consumed in the repo ring.
12. One base feature module = one Nest `@Module()`; keep the base ring folders inside each module — never flatten to Nest's `*.controller.ts`/`*.service.ts` naming.
13. `<feature>.module.ts` is the module's composition root; `shared/aspects/` → an exported `SharedModule`; `shared/utils/` stays framework-free.
14. Cross-module use goes through the exported service provider or a shared port token — never another module's `domain/`/`repo/`.
15. `domain/` is plain classes/functions with zero Nest and zero Prisma imports; entities are constructed by hand, never container-resolved.
16. No third-party `nestjs-prisma`; the pack ships its own `PrismaService`.
17. A port stays in `domain/` plus a DI token: TS decorator-free abstract class as type+token; JS a `Symbol` token.
18. Composition root = the module `providers` array; no `container.js`, no hand-rolled wiring graph.
19. Inner code never imports a concrete adapter; services depend on port tokens by constructor injection only.
20. Validation: Zod via a custom `ZodValidationPipe` (rejected: class-validator); DTOs are Zod schemas in `dtos/`.
21. Prisma types never appear in DTOs; controllers map domain → response DTOs explicitly; never spread a domain entity or return a Prisma row.
22. The single global exception filter is the only domain-error → HTTP mapping site; `domain/`/`service/` throw plain domain errors, never `HttpException`.
23. Aspect mapping: auth = Guard, validation = Pipe, request context = ALS seeder, logging = global interceptor, errors = one filter, audit = injectable `AuditService`, transactions = service ring.
24. Prefer `@UseGuards`/`@UseInterceptors`/module providers over `app.useGlobalX()`; only the error filter and the single correlation-id+logging path register globally.
25. All audit/analytics events flow through one injectable `AuditService`; never scattered across handlers.
26. A use case = one `@Injectable()` in `service/` depending only on domain + port tokens.
27. Transaction boundary: `TransactionRunner` UoW port in `domain/`, implemented in `repo/` over Prisma's interactive transaction; the service never names `Prisma.TransactionClient`; no tx via ALS.
28. `TransactionRunner` only for multi-repository-write use cases; single writes rely on the repo's own atomic call.
29. No nested use-case transactions; a use-case service never calls another use-case service — compose in domain services.
30. Repos implement port tokens over `PrismaClient`, bound in `providers`; every repo carries a mapper; Prisma rows never cross inward.
31. Explicit `select`s — no implicit full-row returns where a subset suffices.
32. One `PrismaService` (extends `PrismaClient`, connect/disconnect on module init/destroy) in a shared `PrismaModule`; never `new PrismaClient()` in a repository.
33. External gateways (storage, mail/SMS, payments, translation) are repo-ring adapters with their own mappers.
34. HTTP integrations bind to `@nestjs/axios`/fetch wrapper with per-call timeout, bounded retry+backoff, idempotency keys; queues via BullMQ/`@nestjs/schedule`; base Integrations rules apply unchanged.
35. Request context: `AsyncLocalStorage` (recommend `nestjs-cls`) seeded by a DI-capable guard/interceptor — not request-scoped providers, not global `app.use()` middleware.
36. The seeder honours inbound `x-request-id`/`x-correlation-id`.
37. Inner rings never read ALS; the controller pulls context at the edge and passes plain values inward.
38. Cookies: register `@fastify/cookie` at bootstrap; read/write at the edge, passed inward as values.
39. Config: `@nestjs/config` + one Zod schema validated at boot, fail fast; no `process.env` reads outside the config module.
40. Lint boundaries: domain bans `@nestjs/*`+`@prisma/client`; service bans `repo/`+`PrismaClient`; `@prisma/client` only under `repo/`+`PrismaService`; `HttpException` only controller ring + filter; `process.env` only config module.
41. Testing: domain by plain instantiation; service via `Test.createTestingModule` + in-memory port fakes; controller/e2e via Fastify `.inject()`; repo integration against real Postgres — never mock Prisma.
42. Bootstrap registers the global filter, global `ZodValidationPipe`, `@fastify/cookie`, and the correlation-id/logging path.
43. `internal`/`external` is a path segment, not a Nest version; the version segment is the `v1` token only; default internal.
44. The Next.js server tier is an internal trusted consumer on `/internal/v1`; only genuinely third-party consumers use `/external/v1`.
45. JS path: Babel required (specified plugin set, order matters) or the SWC builder; `Symbol` port tokens via `@Inject`; Zod schemas duck-typed.
46. Register entries (12): Nest fills the unchosen slot; `providers` array replaces `container.js`; port tokens; global-registration limits; `TransactionRunner`; ALS context; ring folders kept; internal/external route shape; exception filter only; one `AuditService`; repo ring not Prisma-only; Prisma forward-only flag (mechanics in db.md).

*frontend.md*

47. A file is a Server Component unless it opens `'use client'`; reach for client only at an interaction leaf, directive placed leaf-ward — never on a page/layout "to be safe".
48. Next `layout` files are the base shared layout; the `app/` tree is the route registry.
49. JS or TS, project's choice; one language per app; JS uses `jsconfig.json` for aliases.
50. App location pinned to `src/app/`; colocated non-route code lives elsewhere under `src/`.
51. Folder mapping: `pages/`→app segments (four-state files); `store/` client state only; `services/{server,client}` split by execution context with Server Actions in dedicated files; atomic tiers unchanged; `routes.<ext>` replaced by the `app/` tree + a link-helper.
52. Network access lives in `services/`; Server Components call `services/server/`; Client Components mutate via a Server Action (default) or `services/client/`; ad-hoc `fetch`/`axios`/SDK in a component is forbidden (grep smell).
53. State home URL → Server → Client; Next 15+ is uncached-by-default — opt into caching explicitly per call; never copy server data into a `store/` slice.
54. Mutations: Server Action → `revalidatePath`/`revalidateTag`; a write without revalidation is a bug; `'use server'` files export only async functions; `services/client/` direct calls only when an action can't, justified in the PR.
55. `services/server/` wraps the NestJS `/internal/v1` API: one base URL, forwards auth, propagates the correlation id; a Server Component never reaches the DB; validate responses with the shared Zod schema.
56. Build parameterized hrefs through a `routes` link-helper — never a raw URL string literal; static routes may be literal; `<Link>` default; `typedRoutes` optional TS-only.
57. Four states: `loading.*`+Suspense+shared skeleton; `error.*` (Client Component) wiring `reset()` into shared `<ErrorState>` and surfacing the correlation id; `global-error.*` for root-layout failures; shared `<EmptyState>`; `not-found.*`+`notFound()`.
58. Radix UI is the blessed headless foundation, wrapped as atoms; swap only by recording it in `apps/frontend/CLAUDE.md`; never mix two.
59. Interactive atoms/molecules are correctly client leaves; do not hand-roll a server-only control to dodge `'use client'`.
60. Tokens must be consumable by Server Components without a client runtime; runtime CSS-in-JS forcing `'use client'` at the token boundary is disallowed; global tokens declared once on `:root` in the root layout.
61. Only RSC-serializable props cross into client leaves; format dates on one side with timezone/locale pinned; move focus to the main landmark on navigation and announce via a live region.
62. Zod schemas for forms and API responses, shared with the NestJS edge, defined once.
63. i18n: load the active locale's dictionary server-side per request; pin locale to a route segment (`app/[locale]/`); keep the parity check.
64. Versioning: render the `v<version>` banner; refresh prompt only for long-lived/PWA sessions; no default `version.json` poll; don't disable Next's chunk recovery.
65. Testing additions: Server Actions/data-access with the API mocked at the network edge (assert request shape, auth+correlation forwarding, revalidation); test the four-state + `not-found` + `global-error` files; assert hrefs resolve through the helper.
66. Register entries (5): SPA→App Router; services fetch server-side; `app/` tree replaces `routes.<ext>`; store holds client state only; platform-handled deployment skew.

*db.md*

67. One `schema.prisma` owned by the backend; never hand-write DDL outside a generated migration's SQL.
68. Models PascalCase singular `@@map`ped to snake_case plural tables; fields camelCase `@map`ped to snake_case columns.
69. Name both sides of every relation with a named FK; declare `onDelete` explicitly; `Cascade` only with a stated reason.
70. Prisma `enum` for fixed sets; Postgres enums are append-only — one value per migration, never use a freshly-added value as a default in the same migration.
71. IDs: `uuid()` for externally-exposed ids; `autoincrement()` only for internal-only tables with a stated reason.
72. Every model carries `createdAt`/`updatedAt` stored `timestamptz`.
73. Money/quantity is `Decimal(p,s)`, never `Float`; Prisma `Decimal` stops at the mapper; `Json` only for genuinely schemaless payloads.
74. Soft delete is opt-in (`deletedAt`, filtered in the repo ring); no global soft-delete middleware; uniqueness on soft-deletable columns is a partial unique index.
75. `migrations.path = "db/migrations"` in the root `prisma.config.*`; config-file-only, no env override.
76. Reversibility: additive changes forward-only; destructive changes are expand-and-contract or a `-- IRREVERSIBLE:` header stating why + recovery path.
77. The base "prove the down path" is met by the §CI gates (apply-from-zero + drift gate); state observed evidence.
78. Review generated SQL (`--create-only`): no unintended DROP, no unguarded NOT NULL on populated tables, no lock-heavy DDL on hot tables, enum rule respected.
79. Never edit an applied migration — fix forward.
80. Naming: `--name <verb_noun>` snake_case, never `update`/`fix`; one logical change per migration.
81. `migrate deploy` in CI/release; `migrate dev` local-only.
82. Structural DDL in migration SQL; backfills are idempotent re-runnable scripts under `db/backfills/`, never inside migrate SQL.
83. Expand → backfill (asserting row counts, non-zero exit on mismatch) → switch → contract.
84. Zero-downtime: every migration safe against previously-deployed code.
85. `prisma generate` outputs a backend-only client; only the repo ring imports it.
86. HARD RULE: the Next.js app never imports Prisma and never touches the database.
87. Mapper discipline: Prisma result objects (incl. `Decimal`/`Json`/relations) stop at the repo boundary, both directions.
88. `TransactionRunner` is defined in backend.md; this file binds it to `prisma.$transaction`; the service never imports `$transaction`.
89. Keep transactions short — no network/LLM/external calls inside; set explicit `timeout`/`maxWait`; array form only for independent writes.
90. One shared Postgres server, one database per worktree (`app_<sanitized-branch>`, 63-byte cap); re-point `DATABASE_URL` after copying `.env`; drop on teardown; never migrate/reset another worktree's DB.
91. Explicit `connection_limit`; `pgbouncer=true` behind a pooler, avoiding session-level prepared statements.
92. Seed via `prisma db seed` configured at `migrations.seed`; idempotent, realistic minimal; reset = `prisma migrate reset`.
93. Index every FK and frequent filter/sort column (`@@index`) — Postgres doesn't auto-index FKs.
94. Unique constraints encode business invariants; map unique-violation → domain conflict → 409.
95. Avoid N+1 with `include`/`select` in one query; select only needed columns.
96. Pagination binds the base REST params; whitelist sortable columns before dynamic `orderBy`; prefer keyset/cursor over deep `skip`.
97. CI: apply-from-zero on scratch DB; drift gate (`migrate status` + `migrate diff --from-migrations … --exit-code`, `--to-schema` not the legacy flag, shadow-DB flag per version); seed run twice.
98. Register entries (6): forward-only reversibility; replacing the three base round-trip surfaces; migrations-home redirect; Nest DI as composition root; `TransactionRunner` binding direction; per-worktree databases.

## stacks/taro-fastify-mysql-tencent/ (README.md, backend.md, frontend.md, db.md, infra.md)

*README.md*

1. Identity: Taro 4 H5 (React 18, plain JS) / Fastify 4 CJS / MySQL 8 CynosDB via Knex; Tencent Cloud (SCF web+migrate functions, COS, VOD, EdgeOne); `tencentcloud` Terraform; GitHub Actions deploy.
2. `-tencent` suffix marks the load-bearing platform; lift to another cloud → triple stays, suffix changes.
3. Ships the optional infra.md (platform is load-bearing).
4. Day-1: delete other packs; copy the dev block; apply CI notes to `ci.yml`; never the same block in both; record the stack choice in root `CLAUDE.md` Learnings.
5. Toolchain: pnpm workspaces, Node 20/pnpm 9, backend CommonJS (no `"type": "module"`), pin `packageManager`.
6. Root verbs bound; typecheck is an explicit no-op; the backend test suite is destructive against a `*_test` schema.
7. CI: `mysql:8` service; vitest against `*_test` (one-time `test:db:setup`); migration up→down→up round-trip; i18n key-parity; the two OpenAPI drift guards; Playwright e2e runs separately with `x-tenant: test`.
8. Validation: Fastify JSON Schema on every route, request and response; schemas under `schemas/<domain>.js`; OpenAPI is the source of truth.
9. Deploy seam: this pack fills `deploy.yml`; push to default branch → build, one SCF zip, resume CynosDB, `terraform apply`, out-of-band code push, invoke migrate function, smoke test; protect the default branch so push = merge + deploy.

*backend.md*

10. Fastify 4 used directly; plugins/hooks/decorators are the aspect mechanism.
11. Plain JavaScript CommonJS; no typecheck (explicit no-op); esbuild bundle is packaging, not typechecking.
12. Layout is layer-first: `routes/ services/ repos/ schemas/ lib/ utils/ plugins/ db/` (registered override).
13. Every route declares request and response JSON Schemas; OpenAPI source of truth with `lint:openapi`+`lint:schemas` drift guards.
14. `routes/` are thin: attach schema, run guards, call one `services/` function, shape the reply; never touch Knex/repos; no business rules.
15. `services/` orchestrate use cases, own `knex.transaction`, enforce rules, call `lib/`, emit audit; never see `request`/`reply`; raise `HttpError`.
16. `repos/` are Knex query building only; first arg is `db` (knex or trx) then named args; no rules, no `HttpError`.
17. All schemas in `schemas/` (no inline); `lib/` side-effecting integrations; `utils/` pure no-I/O; `plugins/` are the aspects.
18. Config validated at boot in the entry; fail fast on missing env; values flow inward; no `process.env` in rings.
19. `plugins/db.js` provides the single Knex instance; repos never construct their own.
20. `plugins/ctx.js` packs `{requestId, sourceIp, userAgent, logger}` into `request.ctx`, passed inward as a value; the id rides `x-request-id` end to end.
21. One global error handler in `app.js` maps `HttpError` → the base error envelope; rings never shape an HTTP response; rate limits set `retryAfterSeconds`.
22. `plugins/auth.js` guards as `preHandler`s on the scopes that need them.
23. `plugins/tenant.js` resolves `x-tenant` (missing/unknown ⇒ `production`, fail-closed), cached in memory.
24. Scope-to-subtree = plugin encapsulation; only db, cookie, ctx, tenant, and the error handler register app-wide.
25. Audit: services call `services/audit.record(ctx, …)` — one durable append per state change; never `lib/audit` directly.
26. `DEV_OTP_SINK` and `EMAIL_SENDING_ENABLED` are the default-off booleans routing SMS/email to a stdout sink.
27. test-mode binding: `x-tenant: test` signal; `skipOtpChecks()` swaps delivery only (challenge still issued/verified); test-only reads return empty for `production`.
28. otp-auth binding: model A self-managed store — HMAC-SHA256 hash, short TTL, timing-safe verify; one `otp_challenge` table with a `purpose` column driving the rate limit; Tencent SMS/SES delivery; E.164 via `libphonenumber-js`; phone and email as two identity records on one account.
29. Dual entry sharing one `buildApp()`: `handler.js` listens on the SCF port (no per-request wrapper; `scf_bootstrap` is the container entry); `server.js` local with swagger-ui + multipart in non-prod.
30. One function serves `/api/*` and the built H5 bundle via `@fastify/static`.
31. Deploy bundle: esbuild with all SQL drivers external, only `mysql2` installed into the zip; `migrate.js` bundled as a separate function.
32. Serverless: never rely on instance memory for correctness; finish all work inside the request; tolerate a resuming CynosDB on cold paths.
33. Vitest; service tests drive the use case on real Knex against `*_test` (most coverage sits here); route via `app.inject()`; repo integration on `*_test`; unset `DEV_OTP_SINK` so OTP paths exercise the real verify.
34. Register entries (3): layer-first with no domain ring/DI container (discipline kept); CJS no-typecheck with an esbuild bundle; services raise `HttpError` with one global handler (transport leak accepted deliberately; repos never throw it).

*frontend.md*

35. Taro 4 H5 target only, React 18 function components, plain JS; typecheck no-op.
36. Built static and served by the backend; `TARO_APP_API_BASE=/api` same-origin so cookies stay first-party and CORS never enters.
37. State: Zustand, one slice per domain; slices may call services, never import a page or render.
38. REST-only through `src/services/` over a shared `api.js` wrapper injecting `x-tenant` + credentials and mapping the error envelope to a typed error.
39. Routing = two files kept in sync: `app.config.js` registers every page; `config/index.js` `customRoutes` maps internal path → clean URL; add both entries when a page is created; keep no third route→URL list.
40. Compare routes against the customRoute alias, never the internal `/pages/...` path.
41. Portal anything that must survive navigation to `document.body`; the base portal rule is mandatory here.
42. `Taro.redirectTo` collapses the stack and skips the enter transition; custom switch animations require portalled fixed chrome.
43. Patch `history.pushState`/`replaceState` once to emit an event; drive all chrome off a single `usePathname`.
44. Capital `Px` opts a value out of `postcss-pxtransform`; lowercase `px` is rem-rescaled.
45. Re-implement a Taro built-in (pull-to-refresh) when the real scroll container is body-portalled.
46. `src/styles/tokens.css` mirrors the confirmed design guide; one token source, three tiers; semantic tokens only.
47. Author colours as hex, not oklch (in-app WebView support) — a real H5 constraint.
48. Mobile-first base styles + `min-width` queries; viewport meta and safe-area insets belong to the shared layout.
49. Full-height surfaces use `100dvh` with `100vh` fallback (registered); scrollable input pages use `min-height`.
50. Wide content scrolls in its own `overflow-x:auto` box; atomic values `white-space: nowrap`.
51. Test at a phone viewport: Playwright mobile-first with `x-tenant: test`.
52. Base atomic tiers unchanged; DRY gate applies (shared `<PageHeader>` for every nav bar).
53. Video: `vod-js-sdk-v6` upload with a short-lived backend signature; `hls.js` playback; client uploads direct to VOD, transcode is VOD's job.
54. Keeps the base `version.json` poll + dismissible refresh banner + `v<version>` tag; PWA; `version.json` served `no-store`.
55. i18n en/zh under `src/i18n/`; CI `i18n:check` enforces parity both directions; keys named by meaning.
56. Test-user picker: one-tap picker on the login screen, fed by a `test`-tenant-gated endpoint returning empty in `production`.
57. Register entries (2): two-file route registry replaces `routes.<ext>`; `100dvh`+`100vh` fallback overrides the base svh preference.

*db.md*

58. Knex migrations with real paired up/down; base reversibility and round-trip rules apply verbatim; keep Knex's timestamp prefix — never hand-numbered sequences.
59. Knex query builder, no ORM; values bound by Knex; `db.raw()` only for `ON DUPLICATE KEY UPDATE`/`INSERT IGNORE`.
60. Migrations under `db/migrations/`, run via the root `migrate` verb; each exports `up(knex)`/`down(knex)`.
61. Every up ships its real down, or the base justification comment; one logical change per migration (MySQL DDL auto-commits).
62. Separate schema from data; backfills batched, idempotent, resumable (nullable → backfill → enforce later).
63. snake_case; every table carries `created_at`/`updated_at`; index every FK and frequent filter/sort column.
64. MySQL 8 `CHECK` validates existing rows — enforce such invariants in the service when legacy data may violate them.
65. Native MySQL `ENUM` acceptable for fixed sets; widening is a plain reversible migration.
66. One Knex instance per process from `plugins/db.js`; repos take `db` first, then named args.
67. Mappers at the boundary: snake_case rows ↔ camelCase DTOs; no raw row inward; explicit column lists over `SELECT *`.
68. Multi-write use cases open `knex.transaction` in the service and pass `trx` as each repo's `db`; single writes rely on statement atomicity.
69. Local MySQL is one fixed-name shared container; no per-worktree databases in this stack.
70. Seed realistic named accounts + content, idempotent, upsert by business key.
71. Test suite is destructive; the runner refuses unless `DB_NAME` ends `_test`; `pnpm test` auto-suffixes; `test:db:setup` is the idempotent one-time setup.
72. Production migrations run in a dedicated SCF event function invoked after `terraform apply`; keep every migration backward-compatible (expand→migrate→contract).
73. Register entry (1): controlled data seeds do run against production inside the migrate function (idempotent, non-fatal); `resetSchema` never reaches prod except as an explicit opt-in flag.

*infra.md*

74. `tencentcloud` Terraform provider; base workflow, risk-review format, and approval guardrails apply unchanged.
75. `infra/terraform/` per-environment root modules (`envs/<env>/`) calling shared `modules/` (permitted: 2+ envs share the shape); keep explicit-resource/no-`for_each` style inside modules.
76. Auth via `TENCENTCLOUD_SECRET_ID/KEY`; verify account+region with `tccli` before any plan/apply; confirm the target environment; never assume prior context.
77. One SCF Web Function (`type = "HTTP"`) runs the app, `listen()`ing on the platform port, serving API + H5.
78. A separate migrate event function (~900s timeout, no HTTP trigger, CAM-authenticated), pipeline-invoked, never public.
79. Terraform owns function config/env/CAM role/triggers — not the code zip; code pushed out-of-band via `UpdateFunctionCode`; one explicit resource per object.
80. Author a VPC + one private subnet for the VPC-locked CynosDB; outbound uses public-net egress — no NAT gateway; EdgeOne fronts the function URL; the direct SCF URL stays unadvertised.
81. CynosDB `SERVERLESS` (min/max CCU); the pipeline resumes a paused cluster before `apply`; tolerate first-hit latency on cold paths.
82. Serverless-tier physical backups are hard-capped at 7 days; longer retention via automatic logical dump → COS.
83. DB credentials injected via pipeline secrets, never committed (rejected: SSM/KMS on cost).
84. Media COS bucket private (AES256 + versioning); signed GET / presigned PUT minted server-side; role prefix-scoped; lifecycle rule expires orphaned uploads; cross-region DR replication.
85. VOD upload signing uses a permanent scoped CAM sub-user key (STS unsupported); a VOD procedure transcodes to adaptive HLS + cover; the unsigned callback is validated by FileId ownership + an authoritative VOD read.
86. EdgeOne zone fronts app + api domains; WAF + rate limiting live there; mainland deployments need ICP filing; a response-header rule strips the injected `Content-Disposition` until filing lands; budget ICP lead time.
87. `deploy.yml` filled: ordered 7-step pipeline; branch protection makes push=deploy safe.
88. SCF logs drain to CLS; set topic retention explicitly (platform default is short).
89. Register entries (2): Tencent replaces the GCP blessing; deploy triggers on push + `workflow_dispatch` instead of `workflow_run`, gated by branch protection; no second deploy path.

## stacks/vercel/ (README.md, backend.md, frontend.md, db.md, infra.md)

*README.md*

1. Identity: Next.js App Router TS / Fastify plain JS ESM / Postgres Neon via node-pg-migrate + `pg`; two Vercel projects + Blob; Vercel Terraform provider.
2. Platform-exception naming; would-be triple `nextjs-fastify-postgres`; rename if a second Vercel pack appears.
3. Ships the optional infra.md (platform is the pack's identity).
4. Day-1: delete other packs; copy the dev block (delete the banner); apply CI notes; never the same block in both; record the Learnings entry.
5. Toolchain: pnpm workspaces, root ESM, Node 22; pin `packageManager`; keep the Node major synced between `engines` and Terraform `node_version`.
6. Root verbs bound; backend build/typecheck are explicit no-ops.
7. CI: `postgres:16` service; lint; frontend `tsc --noEmit`; backend `node --test`; `next build`; migration round-trip up→down→up; seed twice; Playwright runs against a preview via `E2E_BASE_URL`, not in this job.
8. Zod on both sides; shared shapes defined once.
9. Deploys = Vercel's GitHub integration; `ci.yml` is the merge gate; protect `main`; `deploy.yml` is never filled — delete the stub; local `vercel deploy` is emergency-only.

*backend.md*

10. Fastify 5 used directly; plugins/hooks/decorators are the aspect mechanism.
11. Plain JavaScript ESM; build/typecheck are explicit no-op scripts (rejected: TypeScript).
12. Folder layout: the base shape verbatim (`modules/<feature>/…`, `shared/`, `container.js`).
13. Zod DTOs at the controller edge; one Zod schema parses env at boot.
14. `container.js` is an Awilix container: factories registered `asFunction`/`asValue`, resolved once at boot; rings never import awilix; `buildContainer({env, overrides})` swaps test fakes.
15. One Fastify plugin per module (`controller/routes.js`) registered under one `/internal/v1` prefix + `/health`; add `/external/v1` only when a genuine third-party consumer exists.
16. A handler validates with the module's Zod DTO, invokes one use case, maps to a response DTO.
17. Aspects: `env.js` fail-fast config; `db.js` single `pg.Pool` + `withTransaction`; `request-context.js` correlation id passed inward as a value; `errors.js` single `setErrorHandler` → base envelope + `x-correlation-id`; `auth.js` cookie-session `preHandler` guards.
18. Only the error handler, request context, cookie plugin, and DB pool register app-wide.
19. Sessions are signed HTTP-only cookies (stateless; no session store).
20. `TRUST_PROXY=true` in deployed environments.
21. `@fastify/rate-limit` in-memory per-instance store is an acceptable soft limit; shared store only when a limit must be globally exact.
22. `@fastify/helmet` once at bootstrap; the API sets its own headers; default CSP fine for a JSON API.
23. SSRF guard: public `https` only; resolve the host and reject loopback/private/link-local/metadata IPs, checked at config-save and immediately before the outbound fetch.
24. Admin secrets are write-only: read DTO masks + `…Set` flag; blank update preserves the stored value.
25. `src/server.js` dual entry: Vercel handler lazily builds the app (no top-level await), dispatches via `app.server.emit("request")`; never `listen()` on Vercel; local listener when `!process.env.VERCEL`.
26. `vercel.json` catch-all rewrite → one function; Fastify's router stays in charge.
27. Serverless: never rely on instance memory for correctness; finish all work inside the request — no fire-and-forget after the response.
28. `node:test` runner (rejected: Jest/Vitest); domain plain units; service via container `overrides`; controller via `app.inject()`; repo integration against real Postgres with `--test-concurrency=1` where shared.
29. Register entries (2): stack bound for real with no build/typecheck; Awilix from day one replaces manual wiring.

*frontend.md*

30. App Router under `src/app/`, TypeScript; Server Component default; `'use client'` at the smallest interaction leaf only.
31. REST-only data flow: no Server Actions, no direct DB; every read/mutation goes through `services/` to `/internal/v1` (rejected: Server Actions/route-handler access).
32. Plain `fetch` through services — no react-query/SWR by default; add only when client cache invalidation genuinely appears.
33. State: React Context providers under `src/store/`, one per domain, seeded with server-fetched data (rejected: Redux/Zustand; registered divergence).
34. `/api` proxy: `rewrites()` maps `/api/:path*` → `${BACKEND_URL}/internal/v1/:path*`; browser talks only to the frontend origin; cookies first-party, no CORS.
35. `services/http.ts` (browser) maps the error envelope to a typed `ApiError` carrying the correlation id; `services/server-api.ts` (RSC) calls `BACKEND_URL` directly and forwards incoming cookies.
36. A `fetch` inlined in a component is the greppable smell.
37. `BACKEND_URL` must be present at build time and runtime.
38. Folder mapping: pages→app segments; store→context providers; services split browser/RSC; atomic tiers unchanged; tokens → Tailwind 4 `@theme` CSS variables.
39. Parameterized hrefs through `src/lib/routes.ts` — never hand-concatenated; `<Link>` default.
40. Four states: `loading.tsx`/Suspense skeletons; `error.tsx` with `reset()` → shared `<ErrorState>` + correlation id; `global-error.tsx`; shared `<EmptyState>`; `not-found.tsx`+`notFound()`.
41. Tailwind 4 CSS-first; the `@theme` declaration is the single token source; semantic tokens via utilities.
42. Radix primitives wrapped as atoms; `class-variance-authority` variants; `clsx`+`tailwind-merge` in one `cn()`; `lucide-react` icons; `next/font`; no prebuilt styled kit on top; swap the headless lib only by recording it.
43. Mobile-first stepped utilities; no custom breakpoints without a real reason.
44. Prefer intrinsic sizing (clamp, auto-fit grids, flex-wrap) before breakpoints.
45. Component responsiveness uses `@container` queries; viewport breakpoints for page-level layout.
46. No `tailwind.config`; header clearance and screen gutter are semantic tokens, not magic numbers.
47. One `<Container>`/`<Section>` atom owns the gutter idiom; hand-composed gutter strings are the greppable smell.
48. Full-bleed hero: content-driven `min-h` + `py-*`; never `h-screen`/`100vh`; never `aspect-[…]` on a flex child; `min-h-[100svh]` for true fill; clearance from the layout token; top-anchor copy.
49. Atomic values `whitespace-nowrap`; long unbreakables `overflow-wrap`; `truncate max-w-*` inside `min-w-0` parents; wide tables/code in `overflow-x-auto`.
50. `text-balance` is the heading default, set in the shared heading atom.
51. `<DataTable>` primitive: `overflow-x-auto` wrapper, nowrap columns, windowed pagination ≤ ~7 slots.
52. Modal sizing fixed once: `w-full max-w-[calc(100%-2rem)] sm:max-w-lg`; don't re-solve per feature.
53. Images: `next/image` `fill` + explicit `sizes` + aspect wrapper; art-direct via `object-position`; `unoptimized` only for `data:` URLs and the logo.
54. Version inlined via `env.NEXT_PUBLIC_APP_VERSION`; render the `v<version>` tag; no `version.json` poll (registered).
55. Wire `@vercel/analytics` and `@vercel/speed-insights` in the root layout; enable both on the frontend Vercel project.
56. Security headers via `next.config` `headers()`: HSTS, nosniff, `X-Frame-Options: DENY`, referrer policy, CSP report-only → promote once reports are clean; allow-list actual origins.
57. Testing: `tsc --noEmit` + `next build` + Playwright e2e covering every screen's four states; a second mobile device project beside desktop; add a unit runner only when a slice/service accrues real branching logic (registered).
58. Register entries (5): SPA→App Router; `app/` tree replaces the route registry; seeded context providers; platform-handled skew; e2e-first testing default.

*db.md*

59. node-pg-migrate with real paired up/down — base reversibility and round-trip rules apply verbatim.
60. `pg` directly, no ORM (rejected: Prisma/Drizzle); repos are thin mappers over explicit SQL.
61. Migrations under `db/migrations/` via the root `migrate` verb; create with `node-pg-migrate create <verb_noun>`; epoch-ms prefix satisfies the base.
62. Migrations are CommonJS `.cjs` (the workspace is ESM; a `.js` migration fails to load); each exports `up(pgm)`/`down(pgm)`.
63. Every up ships its real down; a genuinely irreversible change sets `exports.down = false` and carries the justification comment — never silently.
64. Each migration runs in a transaction by default; disable per migration only for DDL that demands it, with a comment.
65. Prefer `pgm` builders; drop to `pgm.sql` otherwise.
66. Run migrations against the direct (non-pooled) connection string — DDL through a transaction pooler misbehaves.
67. snake_case; uuid PKs via `gen_random_uuid()`; `created_at`/`updated_at` `timestamptz` on every table.
68. Index every FK and frequent filter/sort column explicitly.
69. Fixed value sets are `text` + `CHECK`, not native enums (rejected: enum types are effectively one-way).
70. Money is integer minor units or `numeric(p,s)`, never float; unique constraints encode invariants; unique-violation → 409.
71. One `pg.Pool` per process (`max: DB_POOL_MAX`); repos receive it via the container.
72. Keep `DB_POOL_MAX` single-digit in production; runtime `DATABASE_URL` points at Neon's pooled endpoint.
73. Parameterized `$1` queries only; string-built SQL is the greppable violation.
74. Mappers at the boundary; raw rows never cross inward; explicit column lists.
75. `withTransaction(work)` from the db aspect; repos accept an optional client; services never import `pg`; no transaction for a single write.
76. Local Postgres is one fixed-name `postgres:16` container with start-or-run semantics, shared across worktrees.
77. Seed `db/seed-dev.<ext>` idempotent, non-production only.
78. One database per worktree (`app_<sanitized-branch>`); bootstrap creates it if missing; drop on teardown; round-trip/destructive checks run against your own worktree DB only.
79. CI: apply from zero; round-trip up→down→up; seed twice.
80. Deploys do not run migrations — run them manually before the push that needs them, against the target Neon branch's direct connection string; verify `pgmigrations` and affected tables.
81. A shell-set `DATABASE_URL` wins over `--env-file`.
82. Migrate then push; keep every migration backward-compatible (expand→migrate→contract).
83. Staging `develop`: same runbook on its own Neon branch; `vercel env pull --git-branch=develop` does not export the branch-scoped `DATABASE_URL` — read it from Terraform state or the console; never migrate through the Neon-injected `POSTGRES_URL` (points at production).
84. Register entry (1): per-worktree databases on the shared fixed-name server.

*infra.md*

85. Vercel Terraform provider; base workflow, risk-review format, and approval guardrails apply unchanged.
86. One self-contained workload directory: `versions.tf`, `providers.tf` (`api_token` from `TF_VAR_vercel_api_token`, never committed), `variables.tf`, plus `web.tf`/`api.tf`/`storage.tf`.
87. Two `vercel_project` resources with `root_directory` per app; pin `node_version` (synced with `engines`) and function region via `resource_config`.
88. One explicit resource block per environment variable, `sensitive = true` for secrets; never duplicate integration-injected vars (`DATABASE_URL`, `BLOB_READ_WRITE_TOKEN`).
89. The state file holds secret values — remote access-controlled backend from day 1; never commit state.
90. Context check: `vercel whoami` via `VERCEL_TOKEN`; confirm team/project with the user before plan/apply.
91. Both projects declare `git_repository` with `production_branch = "main"`; grant the Vercel GitHub App repo access on day 1.
92. `ci.yml` is the merge gate, not the deploy pipeline; protect `main` so PRs merge only on green CI.
93. `deploy.yml` is never filled in — delete the stub (or reduce to a pointer) on day 1 so no second deploy path exists (registered).
94. A push deploys API and frontend together — releases must be backward-compatible; expand-first; migrate the Neon branch before the push.
95. Point Playwright at a preview URL via `E2E_BASE_URL`.
96. `.vercelignore` keeps `.env*`, `infra/`, `design/`, `docs/`, `.claude/` out of uploads.
97. Local token `vercel deploy` is the emergency path only.
98. Staging: `develop`-branch preview environments on both projects; web preview's `BACKEND_URL` points at the API preview alias; a dedicated long-lived Neon branch backs it, Terraform-authored; develop migrations are manual too.
99. Enable Vercel Observability on both projects; ship runtime logs off-platform via a log drain.
100. The log drain is integration-owned, NOT Terraform — authoring a `vercel_log_drain` resource creates a duplicate drain; widen coverage in the integration's settings.
101. Recover log-only outcomes from the dashboard request logs, not `vercel logs` (~2-minute live tail).
102. Register entries (2): Vercel replaces the GCP blessing; Vercel's git integration replaces `deploy.yml` (delete the stub; confirm-before-push stands).

## add-ons/README.md

1. An add-on is `add-ons/<name>/` containing a single `README.md` of agnostic guidance — docs only, no dependencies, lockfiles, or scaffolding.
2. `<name>` is lowercase, hyphenated, capability-named.
3. Adoption is keeping the directory; opting out is deleting it — every directory present under `add-ons/` is adopted; the Day-1 checklist is where a fresh project chooses.
4. Activation is by instruction from the always-loaded root `CLAUDE.md`; the add-on's README is the single source of truth, edited in place — no generated copy.
5. Invariants: agnostic (never names a framework, table, SDK, or cloud); states the approach concisely (SOP, not history); names its stack seam in a "Binds to a stack" section; names its interactions with base rules and other add-ons; stays well under ~150 lines.
6. Stack packs vs add-ons: exactly one pack; zero or more add-ons; the active pack supplies each adopted add-on's concrete bindings.
7. Adding an add-on: write the README per the invariants; add a bindings section to each active stack pack's appendices; wire it into the root `README.md` Day-1 "choose your add-ons" step.

## add-ons/test-mode/README.md

1. Test mode is a first-class runtime mode that stubs external side effects; distinct from a feature flag and from seed data.
2. Select the mode per request from an inbound client signal (header, signed cookie, tenant); no or unknown signal = production — fail closed. Never infer test mode from hostname or build flag; never store it where a live request can pick it up.
3. Stub the side effect, don't skip the flow: the code path still runs, only the external step is replaced by a sink, with any user-needed value made knowable. Don't branch business logic on the mode past that boundary.
4. Select credentials by the record being acted on, not the caller's session.
5. Every test-only affordance is gated on the mode and fails closed — unreachable and empty/denied in production; test mode is never a way to skip verification or payment.
6. Test-user picker: fed by a test-mode-gated, unauthenticated read that returns empty in production; rendered only on the login screen and only under the mode signal; backed by realistic, named, run-stable seed accounts.
7. "Fails closed" is asserted in the test suite, not hoped.
8. The stack pack supplies: the mode signal and where it's resolved, each integration's sink, and the picker endpoint plus its gate.
9. Interactions: adopt together with otp-auth; the mode signal and test credentials are validated config.

## add-ons/otp-auth/README.md

1. Choose model A (self-managed: store hashed code + short TTL + purpose) or B (provider-owned); under either you still own rate-limiting, idempotency, the test bypass, and delivery-failure handling; under A also hashing, TTL, and timing-safe verify.
2. One purpose-scoped flow: login/signup/contact-change share a single challenge mechanism with a `purpose` discriminator; a code minted for one purpose never satisfies another; add a purpose rather than fork a second flow.
3. Phone and email are interchangeable proofs of one account — model both from the start.
4. Canonicalise the target before storing or sending (phone → E.164 via a library, never hand-rolled); reject unsupported regions with a clear error; store the canonical form.
5. Issue a session only after a successful verify; from there the session is the base auth concern.
6. Idempotent verify: unique constraint on the natural key (target + purpose) so a retry/double-submit race resolves to `409`; the client treats `409` as "already done, proceed".
7. A knowable test code exists only behind test mode; the verify path still runs — only delivery is stubbed.
8. Log every send and verify with `{purpose, masked target, test-mode, provider status, correlation id}` — never the code or the full contact.
9. Rate-limit send and verify (per target, per challenge); answer `429` with a retry hint.
10. Surface delivery failures — "provider accepted" is not "user received"; classify transient vs permanent; never swallow a failed send.
11. Admin-issued fallback code: per-account, hashed, short-lived, revocable, behind its own flag.
12. Select credentials by the record's mode, not the caller's session; live credentials never fall back to a test default.
13. The stack pack supplies: model choice and concrete store/provider, hashing + TTL utilities, the phone-canonicalisation library, the rate-limit store, and how the test-mode code is produced.

## .github/PULL_REQUEST_TEMPLATE.md

1. Every PR names the spec it implements or "N/A" with a one-line reason.
2. Test plan records the commands run and output observed — actual evidence, not "tests pass".
3. Checklist: lint/test/build pass locally (or name the unwired check and why); every acceptance criterion demonstrated with evidence; tests cover the changed behaviour where a harness exists; happy path plus reachable error/empty paths exercised.
4. Schema changes: migration verified per `db/CLAUDE.md`'s merge gate — or the irreversible change is justified in the spec; the section is deleted when there's no schema change.
5. UI changes: all four data states verified; keyboard-only pass; new screens compared to their `design/` mockup, existing-screen changes built to convention; all user-facing strings via i18n or the single strings module; verified at minimum supported width; before/after screenshots at the primary form factor and the narrow width.
6. Notes disclose deployment steps, feature flags, and follow-ups; incomplete work must be behind a flag.

## .github/ISSUE_TEMPLATE/bug.md

1. Bug reports are auto-labelled `bug` and require: a clear description, numbered reproduction steps, expected vs actual behaviour, and environment.

## .github/ISSUE_TEMPLATE/feature.md

1. Feature requests are auto-labelled `enhancement` and require: the problem, the proposed solution, alternatives considered, and acceptance criteria as checkboxes.
