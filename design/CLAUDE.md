# Design principles

Apply these when creating or iterating **UI mockups in this folder only** — they do not govern actual app development (`apps/*` follows its own `CLAUDE.md` files). They are product-agnostic; product-specific rules (palette semantics, navigation model, component specifics) live in `design-guide.html` + `tokens.css`.

1. **Start simple, iterate.** Generate the minimum UI that serves the task and refine through iteration — first drafts tend to include things that aren't needed. Exception: patterns that are table-stakes in the domain ship complete from day one (see 3). Match effort to the artifact — a UI mockup gets no persistence, tests, or app mechanics.
2. **Research before designing.** Deep-research existing and similar products first. Users have spent years in established tools — follow the patterns they already know instead of inventing an alien experience. Divergence needs a defensible improvement; novelty alone is not one.
3. **Tables are the enterprise workhorse.** Growing collections get full datagrids — search, pagination, sort and filters in the column headers, customizable columns. A too-simple table is as wrong as a cluttered one.
4. **Order by attention, place by belonging.** Pages put what needs the user first and metrics last; the main content fills the available space. Every control, setting, and piece of information lives on the object it conceptually belongs to — no catch-all sections.
5. **Don't overload — disclose progressively.** Big forms become multi-step wizards; records show the most-used, basic details first with the rest behind tabs or accordions until needed. But don't hide what fits: show what there's room for.
6. **Realistic, business-logic-correct data.** Mock data must be causally consistent, at credible scale, with realistic edge cases. Metrics are honest: nothing fabricated; undefined shows as an em dash, never a fake zero.
7. **Every state designed.** Loading, empty, error, and success are all designed and reachable. Phone layouts are intentionally designed, never a compressed desktop.
8. **Consistency through reuse.** Build atomic-design style: shared atoms and molecules, so consistency is structural rather than disciplinary. One concept gets one name everywhere.
9. **Sweat the details.** Every visual encoding must decode at a glance. Signal only exceptions — healthy states stay silent. Direct manipulation gives fluid, live feedback — drag-and-drop shows its effect during the drag, not after the drop.

## Anti-patterns (remove on sight)

- **Commentary** — subtitles, taglines, explainer banners, self-narrating copy. The UI shows through structure (columns, icons, color, hierarchy); genuinely needed help lives in a tooltip or compact info panel, never a paragraph.
- **Elements that don't earn their place** — speculative features, configurability, or telemetry the current scope doesn't need.
- **Redundant marks** — the same fact shown twice: a name beside its avatar, duplicate pills, status echoed across columns.
- **Dead or misleading controls** — non-working buttons, fake links, disabled-looking actions. What can't act is absent, not broken-looking.
- **Cards or simple lists for growing collections** — use a datagrid (see 3).
- **Bold on data values** — in tables and rows, weight marks identity; color marks state.
- **Misalignment and clipping** — disjointed row lines, uncentered glyphs, overlapping or cut-off elements.
- **Wrapping toolbars or tab bars** — show what fits and overflow the rest into a … menu.
- **Scrolling content inside a modal** — the modal scrolls as a whole.
- **Non-standard icons** — X for delete, arrows for reorder. Use conventional metaphors: trash to delete, grip to reorder.
