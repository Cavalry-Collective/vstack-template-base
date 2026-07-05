# design/ — mockups and the design guide

**Reference only — not part of the buildable workspace.** Two things live here:

- **The design guide** — `design-guide.html` + `tokens.css`, the visual keystone confirmed before any UI work (gate + never-violate rules: `apps/frontend/CLAUDE.md` → *Design guide*; setup: `docs/getting-started.md`).
- **Screen mockups** — generated or hand-made references for visual design, screen inventory, copy, and flows. **Never copy mockup code into the apps** (its framework is usually not the app stack). Everything below concerns the mockups.

Mockups are the reference for a screen's **initial build only**. After that, the screen drifts as it's iterated — from then on the **running app is the reference**, and later changes are not re-checked against the mockup.

## Layout

Keep mockups findable so "point the relevant mockup at the spec" is mechanical, not a hunt.

- **The inventory table below is the index — keep it current.** Columns: **screen** (semantic name) · **mockup file/folder** · **owning spec**. The screen name must match its name in the central route registry (`apps/frontend/CLAUDE.md` → *URL routing*), so screen, mockup, and URL cross-reference through the registry — which stays the **only** route→URL surface (this table carries no route column on purpose).
- **One file or folder per screen, named by the screen's semantic name** — never tool-export names like `screen-3-final-v2`.
- **Flows** are shown by mockup ordering/links or an optional flow file — no mandated flow diagrams.

| Screen | Mockup file/folder | Owning spec |
|---|---|---|
| _(example) dashboard_ | `dashboard/` | `specs/<feature-dir>/` |

## Building from a mockup

A screen's **initial build** is verified against its design reference — never declared done from reading the code.

- **With a mockup — verify, don't assume.** After first building the screen, run the app and view it at the declared primary form factor plus the other end of the responsive baseline (e.g. mobile + desktop); compare against the mockup and iterate until layout, spacing, hierarchy, and copy match. **Capture and actually look at the rendered output** (screenshot or equivalent) — don't reason about the code and declare it done. The capture tool is a per-project choice; the view-and-compare step is mandatory regardless.
- **Without a mockup — don't invent silently.** A non-trivial **new** screen with no mockup gets its screens/copy/flow sketched in the feature's spec and approved there before building — reuse the spec gate, don't create a second approval process. Minor changes to an existing screen build to `apps/frontend/CLAUDE.md` conventions, noted in the PR as "built to convention, no mockup".
