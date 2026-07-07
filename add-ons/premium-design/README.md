# Add-on: premium-design

> Optional add-on. Opt in at Day-1 by keeping this directory (see `add-ons/README.md`). Agnostic approach; the active stack pack supplies the motion mechanism, font pipeline, and image path.

Raises the visual bar from the base's floor — consistent, token-driven, accessible — to **distinctive and premium**: screens a visitor reads in the first seconds as expensive, art-directed, and crafted. Adopt it when first impressions are a business outcome (a marketing site, a public landing surface, a product whose design *is* the pitch). It changes no architecture; it adds an art-direction step, a motion system, and a craft review gate on top of the base frontend contract — every base rule (tokens, archetypes, accessibility, responsive floor) still binds in full.

## Approach

- **Art-direct before building.** A premium screen starts from a short **design-direction note** in its spec (`specs/`) answering four things: the emotion the screen should create; what the visitor must notice in the first 3 seconds; one memorable visual motif carried across sections; the typographic and colour point of view. No direction note → build to the base bar, not this one. The note rides the existing spec gate — no second approval process.
- **Distinctive by tokens, not per screen.** The identity lives in the token tiers and the design guide — a deliberate type pairing and display scale, a palette with depth (accent, gradient and surface treatments), signature radius/shadow/border logic — so "premium" compounds across screens instead of being hand-painted onto one. If the result would pass for the component library's defaults, the token tier is where to fix it.
- **The hero is a gate.** The first screen is the highest-leverage surface and is verified on its own: a clear visual hook, dominant headline hierarchy, one premium-treated primary CTA, an intentional background treatment, and an entrance that reads as designed. A plain centred headline over a flat background does not pass without a strong treatment around it.
- **Motion is a small system, not sprinkles.** All motion draws from a shared set of motion primitives driven by duration/easing tokens: entrance/reveal, hover/press, and — only where it genuinely improves the feel — scroll reveal and subtle background movement. Restrained by default: motion supports hierarchy, never performs. It animates cheap-to-render properties, honours reduced-motion (base accessibility), and is checked against load and interaction performance before it ships.
- **Every interactive state is designed.** Hover, focus-visible, active/pressed, disabled, and in-flight states live on the shared primitives (base rule) with tokenised transitions. On this bar, a default-looking state is rework, not a nitpick.
- **Recompose, don't shrink.** Small screens get recomposed layouts — composition, whitespace, and tap comfort are re-decided per breakpoint where needed, within the base responsive floor (320 px / 200 % zoom, no overflow, no broken effects).
- **Elevate presentation, never invent facts.** Sharpening weak headings, adding supporting microcopy, and turning flat lists into visual sections (stats, process, comparison, timeline) is in scope; fake testimonials, invented metrics, and misleading claims are not.
- **No unfinished surface ships.** Placeholder-looking sections, missing empty/loading states, and stock defaults are ship-blockers on a premium surface — finish the section or cut it.

## The craft review — a per-screen gate

Before a premium screen is done, render it (base rule: observed, not inferred) at the primary form factor *and* mobile, and walk this list — a weak answer is rework, not a note:

first-screen impact · typographic rhythm and hierarchy · spacing consistency · palette sophistication and contrast · button and card polish · sections visually distinct, not stacked boxes · hover/focus refinement · animation taste and cost · mobile intentionality · zero rough edges.

## Binds to a stack

The active pack names: the motion mechanism (CSS transitions/keyframes and/or an animation library) and where motion primitives live; the font loading pipeline; the image/asset optimisation path; and the scroll-reveal mechanism, if any.

## Interactions

- **Base *Design guide* + *Visual quality bar*** (`apps/frontend/CLAUDE.md`) — this add-on raises the target, never loosens the floor: all never-violate gates (tokens only, archetypes, surface ladder, reuse-first) still hold. Premium is achieved *through* tokens, not around them.
- **`design/` mockups** — the design-direction note complements the mockup flow: a mockup stays the initial-build reference; the note supplies direction where no mockup exists, through the same spec gate.
- **Base *Accessibility baseline*** — unchanged and non-negotiable: contrast, focus visibility, reduced motion. A premium treatment that fails contrast is a defect, not a tradeoff.
- **Base *Simplicity first* / *Don't reinvent*** — polish is not licence for dependency sprawl: an animation or effects library must beat the CSS alternative on the record before it lands.
