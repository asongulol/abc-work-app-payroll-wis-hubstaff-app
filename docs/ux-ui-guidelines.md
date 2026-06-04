# UX/UI & Visual Design Guidelines (Research-Backed)

Apply these patterns when building or modifying any user-facing interface. They are
defaults grounded in usability research, not laws — deviate when the product context
clearly calls for it, but say why in a comment or the PR description.

Two organizing principles run through everything below:
1. **Function first.** Beauty earns trust and tolerance but never substitutes for a
   usable workflow. A "pretty but pointless" interface fails.
2. **Beauty is functional.** Users judge visual appeal in ~50ms, and that judgment
   shapes perceived usability, credibility, and how much friction they will forgive.
   Polish is a feature, not decoration — especially for software that must build trust.

---

## PART 1 — CORE USABILITY (the functional backbone)

### Navigation & Information Architecture
- Keep primary navigation persistent and visible; highlight the active item.
- Group related actions/content; avoid more than ~7 top-level nav items.
- Provide breadcrumbs for hierarchies deeper than two levels.
- Add search when content exceeds what a user can reasonably scan.
- Avoid deep menu hierarchies and poor searchability — both measurably extend task
  time and raise cognitive load in complex/data-heavy apps.

### Match Between System & the Real World
- Speak the user's language. Use words, concepts, and ordering familiar to the domain.
- Follow real-world and domain conventions; don't break established metaphors.
- Present information in a natural, logical order that mirrors how users think.

### System Status & Feedback
- Respond to every user action within ~100ms (even just a state change).
- Use loading indicators or skeleton screens for anything over ~300ms.
- For operations over ~10 seconds, show a step checklist with elapsed time, NOT a
  generic spinner — users need enough info to decide whether to wait or switch tasks.
- Confirm success explicitly; never leave users guessing whether an action worked.
- Implement all interactive states: default, hover, focus, active, disabled, loading,
  error, empty.
- Prefer optimistic UI updates with rollback on failure.

### Forms & Input (Baymard-backed)
- Use SINGLE-COLUMN layouts. Multi-column forms are consistently harder to complete.
- Use visible labels above/beside fields — never placeholder text alone.
- Mark BOTH required and optional fields explicitly.
- Cut fields aggressively — combine duplicates, auto-detect where possible.
- Ask for one phone number unless both are truly needed.
- Validate inline (on blur or as the user types), not only on submit.
- Show errors next to the field, in plain language, with how to fix it.
- Preserve user input on error or navigation — never make them retype.
- Use correct input types (email, tel, number, date) to trigger the right keyboard.
- Disable submit while a request is in flight.

### Affordances & Clickability
- Make interactive elements look interactive; static elements look static.
- Establish clear visual distinction between primary, secondary, and destructive actions.
- Touch targets >= 44x44px with adequate spacing.
- Use cursor changes (pointer, not-allowed) to reinforce behavior.

### Error Prevention & Recovery
- Require confirmation for destructive/irreversible actions; describe the consequence.
- Prefer Undo and auto-saved version history over confirmation dialogs for
  high-investment work.
- Show live previews while users configure or compose.
- Design helpful empty states: explain what goes here and offer the first action.
- Error messages must name what went wrong and link to resolution. Never write
  dead-ends like "Could not display data. Contact your administrator."

### Recognition over Recall
- Make options, actions, and elements visible rather than memorized.
- Show meaning on hover for domain codes/taxonomy (a code, role, or ID should reveal
  what it is). Don't make even trained users hold the taxonomy in their head.

### Flexibility & Efficiency
- Provide keyboard shortcuts/accelerators for experts; keep labeled primary paths for novices.
- Let users tailor frequent actions where it pays off.

### Progressive Disclosure
- Show the common path first; reveal advanced/rare options on demand.
- Use sensible defaults so most users never touch advanced settings.

### Help & Documentation
- Prefer in-context help (tooltips with a short description + shortcut) over forced tutorials.

---

## PART 2 — VISUAL DESIGN (what makes it attractive)

### Visual Hierarchy
- Communicate priority through size, contrast, placement, spacing, and typography together.
- Make ONE action obviously primary; keep secondary actions quieter.
- Lay out for scan patterns: F-pattern for data/text-heavy screens, Z-pattern for simpler layouts.
- Aim for disciplined prioritization, not minimalism for its own sake. "Clean" means the
  important thing is impossible to miss — not that the page is empty.

### Typography
- Set the base (primary typeface, size, style) FIRST as a reference point.
- Create hierarchy with contrast first, then spacing. Font weight is the most striking lever.
- Use a consistent type scale; limit sizes and weights.
- Group related text via proximity; separate unrelated groups with space.
- Keep body line length readable (~50-75 characters).

### Color — the 60-30-10 rule
- 60% dominant/neutral (backgrounds, large surfaces, whitespace).
- 30% secondary (containers, nav, structure).
- 10% accent (CTAs, links, key interactive elements only).
- Start in grayscale; confirm text/background contrast before adding color.
- Use the accent SPARINGLY so the eye is drawn straight to key actions.
- Reserve semantic colors (red/yellow/green) strictly for status — never for branding.
- Never convey information by color alone — pair with icon, shape, or text.

### Whitespace
- Use generous space to let the design breathe and create clear focal points.
- Whitespace is what makes identical content read as premium vs. cramped.
- Use spacing to group (proximity) and separate, reinforcing hierarchy.

### Data Visualization & Tables
- Maximize the data-ink ratio: if a pixel isn't conveying information, remove it. Cut
  chartjunk — heavy gridlines, borders, drop shadows, 3D effects, decorative gradients.
- Choose the chart that fits the data; label directly instead of dense legends.
- Reserve semantic colors in charts for meaning; don't color bars by brand.
- On small screens, convert each wide-table row into a stacked card (card-stack pattern).

### Micro-interactions & Motion
- Every micro-interaction = trigger -> rules -> feedback -> loop/mode. Design all four.
- Use motion to confirm actions, show cause and effect, indicate state changes, guide
  attention, and improve perceived speed.
- Be restrained. Overused motion causes overload and motion sickness.
- Match motion to brand: restrained fades and crisp transitions for enterprise/clinical tools.
- ALWAYS support `prefers-reduced-motion`.
- Document motion tokens (durations, easing, density) in the design system.

### Speed as an aesthetic
- Perceived performance is part of perceived quality.
- Render layout/skeletons before data arrives; avoid layout shift after load.

---

## PART 3 — CONSISTENCY, ACCESSIBILITY & TRUST

### Consistency
- Reuse shared components, a single spacing scale, and design tokens.
- Keep icon meanings, terminology, and interaction patterns consistent. One symbol = one meaning.
- Keep primary actions in consistent locations across screens.
- Match platform conventions rather than inventing custom behavior.

### Accessibility (required, not optional)
- Use semantic HTML; reach for ARIA only when semantics fall short.
- Full keyboard navigation, logical tab order, visible focus indicators.
- WCAG AA contrast: 4.5:1 normal text, 3:1 large text and UI components.
- Alt text for meaningful images; mark decorative images as such.
- Don't rely on color alone.

### Trust & credibility
- Nearly half of credibility judgment is visual — invest in a coherent, professional first impression.
- Show data provenance: where a value came from, when it was updated, whether it's verified.
- Suppress duplicate and repetitive data entry: pre-fill known values, reuse captured data.
- Apply consistent completeness rules — signal what's missing rather than blocking the whole workflow.
- Surface patterns, not raw data: highlight overdue items, deadlines, and rule violations.
- Caution: because polish masks friction, validate usability by watching what users DO, not only what they say.

---

_Source: ux-ui-guidelines-v2 provided by the owner. Applies to all user-facing work on this project (admin `app/index.html`, portal `portal/index.html`) and future projects._
