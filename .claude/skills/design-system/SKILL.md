---
name: design-system
description: Enforce consistent component naming, interaction patterns, accessibility standards, design tokens, and handoff conventions across all UI/UX design work
license: MIT
compatibility: claude-code
metadata:
  audience: design
  workflow: design-system
---
## What I do
- Standardize component naming so design and engineering share a common vocabulary.
- Provide a reusable interaction pattern library for common UI scenarios.
- Enforce WCAG 2.1 AA accessibility requirements as a non-negotiable baseline.
- Define design token naming conventions that are framework-agnostic.
- Specify the handoff format from `specs/design/` to implementation so nothing is lost in translation.

## Component naming conventions

All component names use **kebab-case**. This applies to file names, design layer names, token names, and any reference in design documents.

### Rule

```
<category>-<descriptor>[-<variant>]
```

- `category` — the component family (e.g., `button`, `input`, `modal`, `nav`)
- `descriptor` — the specific role or purpose (e.g., `primary`, `search`, `confirmation`)
- `variant` (optional) — a state or size modifier (e.g., `sm`, `lg`, `disabled`, `error`)

### Examples

| Correct | Incorrect | Why incorrect |
|---------|-----------|---------------|
| `button-primary` | `PrimaryButton` | PascalCase not allowed |
| `input-search` | `searchInput` | camelCase not allowed |
| `modal-confirmation` | `ConfirmModal` | Mixed case, wrong order |
| `nav-breadcrumb` | `Breadcrumb_Nav` | Underscores not allowed |
| `form-field-error` | `formFieldError` | camelCase not allowed |
| `card-product-sm` | `SmallProductCard` | Adjective-first ordering |

### Anti-patterns

- **PascalCase** — reserved for code class names, not design tokens or component names.
- **camelCase** — ambiguous in design tools; use kebab-case consistently.
- **Underscores** — use hyphens only; underscores are reserved for token sub-categories in some tools.
- **Abbreviations without context** — `btn-pri` is unclear; prefer `button-primary`.
- **Adjective-first ordering** — `small-card` is harder to scan than `card-sm`; category always comes first.

---

## Interaction pattern library

### Pattern 1: Modals

**Purpose:** Interrupt the user flow to require a focused action or present critical information.

**Open behavior:**
1. Trigger element (button, link) receives click/keypress.
2. Overlay fades in; modal panel slides or fades into view.
3. Focus is moved to the first focusable element inside the modal (close button or primary action).
4. Background content is inert (`aria-hidden="true"` on root, `inert` attribute where supported).

**Close behavior:**
1. User presses `Escape`, clicks the overlay, or activates the close button.
2. Focus returns to the element that triggered the modal.
3. Overlay and panel animate out; background content becomes interactive again.

**Focus trap:**
- Tab and Shift+Tab cycle only within the modal while it is open.
- No focus escapes to background content.
- If the modal contains a form, focus the first invalid field on failed submission.

**States to specify in design docs:** default open, loading (async action in progress), error (action failed), success (action completed before close).

---

### Pattern 2: Forms

**Validation states:**

| State | Visual indicator | When triggered |
|-------|-----------------|----------------|
| Default | Neutral border | On page load / before interaction |
| Focus | Highlighted border (brand color) | On field focus |
| Valid | Success indicator (icon or green border) | On blur after valid input |
| Invalid | Error border + error message below field | On blur or on submit attempt |
| Disabled | Muted background, no pointer events | When field is not applicable |

**Error display rules:**
- Error messages appear **below** the field they describe, never above or in a tooltip.
- Each error message is associated with its field via `aria-describedby`.
- On form submission failure, focus moves to the first invalid field.
- Error messages use plain language: "Enter a valid email address" not "Invalid input".
- Never clear error messages on focus — only on successful correction.

**Required field convention:**
- Mark required fields with an asterisk (`*`) and include a legend: "* Required field".
- Do not rely on color alone to indicate required status.

---

### Pattern 3: Navigation

**Active states:**
- The current page/section link is visually distinct (bold weight, accent underline, or background highlight).
- Active state must not rely on color alone — use a secondary indicator (underline, icon, weight).
- `aria-current="page"` is set on the active link.

**Breadcrumbs:**
- Breadcrumbs appear below the primary navigation, above the page heading.
- Each ancestor is a link; the current page is plain text (not a link).
- Separator character (e.g., `/` or `›`) is decorative and hidden from screen readers (`aria-hidden="true"`).
- The breadcrumb landmark uses `<nav aria-label="Breadcrumb">`.
- On mobile, collapse to show only the immediate parent with a back arrow.

**Mobile navigation:**
- Hamburger trigger has `aria-expanded` and `aria-controls` attributes.
- When the menu opens, focus moves to the first menu item.
- Closing the menu returns focus to the hamburger trigger.

---

### Pattern 4: Error states

**Empty state (no data):**
- Show an illustration or icon, a short heading, and a single call-to-action.
- Heading: describe what is missing ("No results found", "Your cart is empty").
- CTA: guide the user to the next logical action ("Browse products", "Start a search").
- Do not show empty tables or blank panels without explanation.

**Error state (system or network error):**
- Show an error icon, a plain-language message, and a retry action where applicable.
- Message: explain what went wrong and what the user can do ("Something went wrong. Try again or contact support.").
- Log the error reference code in small text for support escalation.
- Never expose raw error codes or stack traces to end users.

**Loading state:**
- Use skeleton screens for content areas that load asynchronously.
- Use a spinner only for short operations (< 2 seconds) or button-level actions.
- Announce loading state to screen readers with `aria-live="polite"` or `aria-busy="true"`.
- Set a timeout message if loading exceeds 10 seconds ("This is taking longer than expected…").

**Partial error state (some items failed):**
- Render successfully loaded content; show an inline error banner for failed sections.
- Allow the user to retry only the failed section, not the entire page.

---

## Accessibility baseline

All UI designs must meet **WCAG 2.1 Level AA**. The following requirements are non-negotiable and must be documented in every design spec.

### Requirement 1: Keyboard navigation

Every interactive element must be reachable and operable using a keyboard alone.

- Tab order follows the visual reading order (left-to-right, top-to-bottom).
- No keyboard traps except intentional focus traps (modals, drawers) that have a documented escape mechanism.
- All actions available via mouse must have an equivalent keyboard shortcut or sequential tab path.
- Custom widgets (dropdowns, date pickers, sliders) implement the appropriate ARIA keyboard pattern from the [ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/).

### Requirement 2: Focus indicators

Visible focus indicators are required on all interactive elements.

- Focus ring must have a minimum contrast ratio of **3:1** against adjacent colors (WCAG 2.1 SC 1.4.11).
- Do not suppress the default focus outline with `outline: none` without providing a custom replacement.
- Focus indicators must be visible in both light and dark modes.
- Minimum focus indicator area: 2px solid outline or equivalent perimeter coverage.

### Requirement 3: Color contrast ratios

- **Normal text** (< 18pt / < 14pt bold): minimum contrast ratio **4.5:1** against background.
- **Large text** (≥ 18pt / ≥ 14pt bold): minimum contrast ratio **3:1** against background.
- **UI components and graphical objects** (icons, borders, chart elements): minimum **3:1** against adjacent colors.
- Do not use color as the **only** means of conveying information (e.g., red = error must also use an icon or text label).
- Verify contrast in both light and dark themes before handoff.

### Requirement 4: ARIA labels and roles

- All interactive elements without visible text labels must have an `aria-label` or `aria-labelledby`.
- Icon-only buttons: `<button aria-label="Close dialog">` — never leave unlabeled.
- Form inputs: always associate a `<label>` element or use `aria-label`/`aria-labelledby`.
- Landmark regions: use `<nav>`, `<main>`, `<header>`, `<footer>`, `<aside>` with unique `aria-label` when multiple of the same type exist on a page.
- Do not use ARIA roles to override native semantics unless there is no native HTML equivalent.

### Requirement 5: Screen reader announcements

Dynamic content changes must be announced to screen reader users without requiring a page reload.

- Use `aria-live="polite"` for non-critical updates (success messages, filter results).
- Use `aria-live="assertive"` only for critical, time-sensitive alerts (session expiry, payment failure).
- Status messages (form submission success, item added to cart) must be in an `aria-live` region even if they are visually visible.
- Page title must update on single-page application route changes.
- Loading states: set `aria-busy="true"` on the loading container and announce completion.

### Requirement 6: Images and media

- All informative images require descriptive `alt` text.
- Decorative images use `alt=""` (empty string) to be ignored by screen readers.
- Videos require captions; audio requires transcripts.
- Do not use images of text — use real text with CSS styling.

---

## Design token vocabulary

Design tokens are the single source of truth for visual decisions. All tokens use **kebab-case** and follow a `{category}-{property}-{scale|variant}` naming pattern. Tokens are framework-agnostic — they map to CSS custom properties, Figma variables, or any design tool.

### Spacing scale

Spacing tokens use a numeric scale based on a base unit (typically 4px or 8px).

```
space-{n}
```

| Token | Value (4px base) | Use case |
|-------|-----------------|----------|
| `space-0` | 0px | Reset / no spacing |
| `space-1` | 4px | Tight inline gaps |
| `space-2` | 8px | Component internal padding |
| `space-3` | 12px | Small component gaps |
| `space-4` | 16px | Standard padding / gap |
| `space-6` | 24px | Section internal spacing |
| `space-8` | 32px | Component-to-component gaps |
| `space-12` | 48px | Section-to-section gaps |
| `space-16` | 64px | Page-level spacing |

**Anti-patterns:** Do not use arbitrary pixel values in designs. If a spacing value does not exist in the scale, request a token addition — do not hardcode.

### Color tokens

Colors use a two-tier system: **primitive tokens** (raw values) and **semantic tokens** (purpose-driven aliases).

**Primitive tokens** (not used directly in components):
```
color-{hue}-{shade}
```
Example: `color-blue-500`, `color-red-300`, `color-neutral-900`

**Semantic tokens** (used in component specs):
```
color-{role}-{variant}
```

| Token | Purpose |
|-------|---------|
| `color-brand-primary` | Primary brand action color |
| `color-brand-secondary` | Secondary brand accent |
| `color-surface-default` | Default page/card background |
| `color-surface-raised` | Elevated surface (cards, modals) |
| `color-surface-overlay` | Modal/drawer overlay background |
| `color-text-primary` | Primary body text |
| `color-text-secondary` | Secondary / muted text |
| `color-text-disabled` | Disabled text |
| `color-text-inverse` | Text on dark/brand backgrounds |
| `color-border-default` | Default input and card borders |
| `color-border-focus` | Focus ring color |
| `color-feedback-success` | Success state (icons, borders) |
| `color-feedback-warning` | Warning state |
| `color-feedback-error` | Error state |
| `color-feedback-info` | Informational state |

**Anti-patterns:** Do not reference primitive tokens (e.g., `color-blue-500`) in component specs — always use semantic tokens so themes can be swapped without updating every component.

### Typography scale

Typography tokens cover font size, line height, font weight, and font family.

**Font size:**
```
text-{scale}
```

| Token | Value | Use case |
|-------|-------|----------|
| `text-xs` | 12px / 0.75rem | Labels, captions, helper text |
| `text-sm` | 14px / 0.875rem | Secondary body, form labels |
| `text-base` | 16px / 1rem | Primary body text |
| `text-lg` | 18px / 1.125rem | Lead paragraphs |
| `text-xl` | 20px / 1.25rem | Card headings, subheadings |
| `text-2xl` | 24px / 1.5rem | Section headings (H3) |
| `text-3xl` | 30px / 1.875rem | Page subheadings (H2) |
| `text-4xl` | 36px / 2.25rem | Page headings (H1) |

**Font weight:**
```
font-{weight}
```

| Token | Value | Use case |
|-------|-------|----------|
| `font-regular` | 400 | Body text |
| `font-medium` | 500 | Emphasized labels, nav items |
| `font-semibold` | 600 | Subheadings, active states |
| `font-bold` | 700 | Headings, CTAs |

**Line height:**
```
leading-{scale}
```

| Token | Value | Use case |
|-------|-------|----------|
| `leading-tight` | 1.25 | Headings |
| `leading-snug` | 1.375 | Subheadings |
| `leading-normal` | 1.5 | Body text |
| `leading-relaxed` | 1.625 | Long-form content |

**Font family:**
```
font-family-{role}
```

| Token | Use case |
|-------|----------|
| `font-family-sans` | UI text, body, labels |
| `font-family-mono` | Code blocks, technical content |

---

## Handoff format

The handoff from design to implementation follows a defined path: `specs/design/` → senior-engineer implementation.

### Required deliverables checklist

A design handoff is **not complete** until all of the following are present in the design document at `specs/design/<feature-slug>-design-spec.md`:

- [ ] **Overview** — Feature description, design goals, and scope boundaries.
- [ ] **Target users** — Who uses this feature and their primary goals.
- [ ] **User flows** — Step-by-step flows for each primary use case (numbered steps).
- [ ] **Wireframe descriptions** — Text-based layout for each screen and state (default, loading, error, empty).
- [ ] **Component specifications** — For each new or modified component: purpose, props/inputs, variants, behavior.
- [ ] **Accessibility considerations** — Keyboard navigation, ARIA labels, color contrast notes, focus management.
- [ ] **Design token references** — All spacing, color, and typography decisions expressed as token names (not raw values).
- [ ] **Open questions** — Any unresolved decisions that require product or engineering input, listed as checkboxes.
- [ ] **Status field** — Set to `review` when ready for engineering; `approved` after PM sign-off.

### How to notify the senior-engineer

When the design spec is ready for implementation:

1. Set the document `**Status:**` field to `review`.
2. Leave a TD comment on the linked task:
   ```
   td_comment(task: "td-xxx", commentText: "Design spec ready at specs/design/<feature-slug>-design-spec.md. Status: review. Open questions: [list or 'none'].")
   ```
3. If there are open questions blocking implementation, list them explicitly in the comment — do not leave them only in the document.

### What constitutes a complete handoff

A handoff is **complete** when:

1. The design spec document exists at `specs/design/<feature-slug>-design-spec.md`.
2. All checklist items above are checked.
3. All design token references use semantic token names (no raw hex values or pixel values).
4. Accessibility considerations are documented for every interactive element.
5. The TD task has a comment pointing to the spec with status `review` or `approved`.
6. No open questions are blocking implementation (or they are explicitly flagged as non-blocking with a proposed default).

### Incomplete handoff indicators (do not proceed to implementation)

- Status is still `draft`.
- Wireframe descriptions reference colors by hex value instead of token names.
- Accessibility section is missing or says "TBD".
- Open questions include unresolved decisions about component behavior or data requirements.
- No TD comment linking the spec to the task.
