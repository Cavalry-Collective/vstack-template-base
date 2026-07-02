# design — UI mockup / design reference

**Reference only — not part of the buildable workspace.** Drop generated or
hand-made design mockups here; they are the source for visual design, screen
inventory, copy, and flows. **Never copy mockup code** into the apps (its
framework is usually not the app stack).

This folder also holds the **design guide** — `design-guide.html` + `tokens.css`,
the visual keystone confirmed before any UI work (`apps/frontend/CLAUDE.md` →
*Design guide*). Everything below concerns the mockups.

## Layout

Keep mockups findable so "point the relevant mockup at the spec" is mechanical, not a hunt.

- **The inventory table (below) is the index — keep it current** as screens are added. Columns: **screen** (semantic name) · **mockup file/folder** · **owning spec**. The *screen* name must match its name in the central route registry (`apps/frontend/CLAUDE.md`), so a screen, its mockup, and its URL cross-reference through the registry — which stays the **only** route→URL surface, so this table carries no route column.
- **One file or folder per screen, named by the screen's semantic name** (matching the route registry) — never by tool export names like `screen-3-final-v2`.
- **Flows** are shown by mockup ordering/links or an optional flow file — don't mandate separate flow diagrams.

| Screen | Mockup file/folder | Owning spec |
|---|---|---|
| _(example) dashboard_ | `dashboard/` | `specs/2026-01-01-dashboard.md` |

## Building from a mockup

Mockups guide a screen's **initial build only**. Verify that build against the mockup by rendering and looking — never declare it done from reading the code. After the first build the screen drifts from the mockup by design: **later changes are verified against the running app, not the mockup.**

- **With a mockup — verify, don't assume.** After first building the screen, run the app and view it at the project's declared primary form factor plus the responsive baseline's other end (e.g. mobile + desktop); compare against the mockup and iterate until layout, spacing, visual hierarchy, and copy match. **Capture and actually look at the rendered output** (a screenshot or equivalent). The capture/visual-diff tool is a per-project choice; the view-and-compare step is mandatory.
- **Without a mockup — don't invent silently.** For a non-trivial **new** screen, sketch the screens/copy/flow in the feature's spec under `specs/` and get it approved there — reuse the spec gate, no second approval process. Never improvise UI for a non-trivial new screen with no reference. For minor changes to an existing screen, build to the conventions in `apps/frontend/CLAUDE.md` and note in the PR that it was "built to convention, no mockup."
