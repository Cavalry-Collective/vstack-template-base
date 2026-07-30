# Add-on: premium design

Use this add-on when visual quality is part of the product's value proposition. It adds art direction, a small motion system, and a stricter craft review to the frontend baseline.

All base requirements for tokens, reusable components, responsiveness, accessibility, and performance still apply.

## Requirements

### Set the direction

Add a short design direction to the requirement spec. State:

- the emotion the screen should create;
- what the visitor should notice in the first three seconds;
- one visual motif to repeat;
- the typography and colour treatment.

Use an existing `design/` mockup as the initial-build reference. Stop if the design direction has not been approved.

### Build the visual system

- Define type, colour, gradient, surface, radius, border, and shadow treatments in tokens.
- Implement recurring treatments as shared primitives rather than painting each screen separately.
- Give the first viewport a clear focal point, dominant headline, primary action, and intentional background treatment.
- Do not ship the component library's default appearance without deliberate styling.

### Use motion deliberately

- Define shared duration and easing tokens with entrance, hover, and press primitives.
- Add scroll or background motion only when it improves hierarchy or orientation.
- Prefer transform and opacity, honour reduced motion, and remove effects that delay interaction.
- Check motion on representative mobile and low-power devices.

### Finish every state

- Design hover, focus-visible, active, disabled, loading, error, empty, and success states.
- Recompose layouts for small screens rather than shrinking the desktop composition.
- Support the base 320-pixel and 200-percent-zoom requirements.
- Improve presentation without inventing testimonials, metrics, customers, or product claims.
- Finish or remove placeholder-looking sections before release.

## Verify

Render every premium surface at its primary form factor and on mobile. Review first-screen impact, typography, spacing, palette, contrast, interactive states, motion cost, responsive composition, accessibility, and unfinished areas.

Record the reviewed screen sizes and observations in the PR.

## Binds to a stack

The active stack pack identifies the motion mechanism and primitive location, font pipeline, asset optimisation path, and any scroll-reveal mechanism.

## Interactions

- **Frontend design guide:** this add-on raises the visual target without replacing the base design system.
- **Accessibility baseline:** contrast, focus, reduced motion, zoom, and keyboard requirements remain mandatory.
- **Dependency rules:** add a visual-effects dependency only when the approved direction cannot reasonably use the existing stack.
