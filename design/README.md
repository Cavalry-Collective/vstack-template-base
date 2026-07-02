# design — UI mockup / design reference

**Reference only — not part of the buildable workspace.** Drop generated or
hand-made design mockups here and use them as the source for visual design, screen
inventory, copy, and flows. **Do not copy the mockup code** into the apps (its
framework is usually not the app stack). See the *UI mockup / design reference*
section in the root `CLAUDE.md`.

## Layout

Keep mockups findable so "point the relevant mockup at the spec" is mechanical, not a hunt.

- **Inventory table (below) is the index — keep it current** as screens are added. Columns: **screen** (semantic name) · **mockup file/folder** · **owning spec**. The *screen* name must match its name in the central route registry (`apps/frontend/CLAUDE.md`), so a screen, its mockup, and its URL cross-reference through the registry — which stays the **only** route→URL surface (the frontend file forbids a second list, so this table carries no route column).
- **One file or folder per screen, named by the screen's semantic name** (matching the route registry) — never by tool export names like `screen-3-final-v2`.
- **Flows** are shown by mockup ordering/links or an optional flow file — don't mandate separate flow diagrams.

| Screen | Mockup file/folder | Owning spec |
|---|---|---|
| _(example) dashboard_ | `dashboard/` | `specs/2026-01-01-dashboard.md` |

## Building from a mockup

A screen's **initial build** is verified against its design reference — never declared done from reading the code. Mockups guide that first build only: once a screen is iterated and improved it drifts from the mockup by design, so **later changes are verified against the running app, not re-checked against the mockup**.

- **With a mockup — verify, don't assume.** After first building a screen that has a mockup, run the app and view the built screen at the project's declared primary form factor plus the responsive baseline's other end (e.g. mobile + desktop), compare against the mockup, and iterate until layout, spacing, visual hierarchy, and copy match. **Capture and actually look at the rendered output** (a screenshot or equivalent) — don't reason about the code and declare it done. This is the success marker for the screen's **initial build** (ties to root `CLAUDE.md` *Goal-driven execution*). The capture/visual-diff tool is a per-project choice; the view-and-compare-against-reference step is mandatory regardless of tool.
- **Without a mockup — don't invent silently.** For a non-trivial **new** screen with no mockup, sketch the screens/copy/flow in the feature's spec under `specs/` and get it approved there before building — reuse the existing spec gate, don't create a second approval process. For minor changes to an existing screen, build to the conventions in `apps/frontend/CLAUDE.md` and note in the PR that it was "built to convention, no mockup." Never improvise UI for a non-trivial new screen with no reference.
