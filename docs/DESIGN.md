# RetinaAI — Design System
**SIH 26038 · Explainable DR Screening**
**Status: APPROVED — Single Source of Truth**

> Every future edit to this project — in this session or a new one — must re-read this file first and conform to it. Do not regenerate a palette, font choice, or copy voice from scratch in a later session if these values already define it.

---

## 1. Color Palette

This is an **achromatic palette with exactly two chromatic accents**. Nothing else is chromatic.

| Token | Value | Purpose |
|---|---|---|
| `--canvas` | `#f5f5f5` | Page background |
| `--surface-alt` | `#fafafa` | Sidebar, subtle section backgrounds |
| `--paper` | `#ffffff` | Cards, elevated surfaces |
| `--ink` | `#0a0a0a` | Primary text, headings |
| `--ink-soft` | `#171717` | Secondary text, labels |
| `--mid-gray` | `#737373` | Muted text, captions |
| `--hairline` | `#e5e5e5` | All borders — every card edge, every divider |
| `--teal` | `#0f766e` | AI confidence signal, healthy/passed indicator, AI-facing data only |
| `--amber` | `#b45309` | Clinical severity flag, lesion indicator, referable DR warning only |

### Hard Rules

- **The two accents are information, not decoration.** Teal = AI/confidence/healthy. Amber = clinical severity/lesion flag. Never use either color for branding, default buttons, or visual flourish.
- **No gradients anywhere, ever.** Not as hero backgrounds, not as text fills, not as card overlays, not as button fills.
- **No colored shadows, no glow effects.** The shadow definition below is the only permitted shadow.
- **No third chromatic color.** No blue, no purple, no green outside of teal. Use a gray value instead.
- **Current codebase violations to fix:** dark base `#0a0d14`, wrong teal `#2fd6ae`, gradient hero background, `Fraunces` display font, glow animations in `hero-shell`, `scan-ring` conic gradient.

---

## 2. Typography

**Primary font:** IBM Plex Sans — weights 400 / 500 / 600
**Monospace font:** IBM Plex Mono (data readouts, confidence scores, IDs, log output only)
**Do not use:** Fraunces, Inter, Geist, Space Grotesk, any serif display accent.

Google Fonts import:
```
https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600&display=swap
```

### Type Scale

| Name | Size | Weight | Tracking | Line-height | Usage |
|---|---|---|---|---|---|
| Display | 48px | 600 | -0.05em | 1.1 | Page hero headline only |
| Heading-lg | 36px | 600 | -0.09em | 1.11 | Section heroes |
| Heading | 30px | 600 | -0.075em | 1.2 | Section titles |
| Heading-sm | 24px | 600 | -0.06em | 1.33 | Card titles, panel headers |
| Subheading | 18px | 400 | -- | 1.56 | Subheadings, lead text |
| Body-lg | 16px | 400 | -- | 1.5 | Primary body copy |
| Body | 14px | 400 | -- | 1.43 | Secondary body, UI labels |
| Caption | 12px | 500 | +0.06em | 1.33 | UPPERCASE only, section eyebrows, data labels |

---

## 3. Spacing

**Base unit: 4px.** Every margin, padding, and gap must be one of the following:

| Token | Value |
|---|---|
| `--sp-1` | 4px |
| `--sp-2` | 8px |
| `--sp-3` | 12px |
| `--sp-4` | 16px |
| `--sp-5` | 20px |
| `--sp-6` | 24px |
| `--sp-12` | 48px |

**Layout constants:**
- Page max-width: 1280px
- Section vertical gap: 48px minimum, up to 80px
- Card internal padding: 20px
- Element gap (within cards): 8px

---

## 4. Border Radius

Exactly four permitted values. Nothing in between.

| Context | Value |
|---|---|
| Badges, tight UI elements | 6px |
| Nested inner elements (within cards) | 10px |
| Interactive elements (buttons, inputs) | 18px |
| Containers (cards, panels) | 24px |

**Violations in current codebase:** `border-radius: 12px`, `14px`, `16px` — none are in the permitted scale.

---

## 5. Shadows

One shadow value permitted, applied only to card-level containers:

```
0 0 0 1px rgba(23,23,23,0.05), 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px -1px rgba(0,0,0,0.1)
```

- Buttons get no shadow. Tonal contrast provides primary action affordance.
- No dramatic drop shadows. Current `0 28px 80px rgba(0,0,0,0.55)` modal shadow is a violation.
- Cards always keep the 1px hairline border (#e5e5e5).

---

## 6. Motion

Animation permitted only where it communicates state or progress — not decoration.

| Use | Permitted |
|---|---|
| Pipeline stage progress bar | Yes — width transition, 420ms |
| Reveal on scroll (opacity + translateY) | Yes — 700ms, single use per section |
| Button hover state change | Yes — background/border only, 150ms |
| Scan ring / sweep animation | No — decorative, blocked |
| Blob/beam/glow floating effects | No — blocked |
| Gradient text animation | No — blocked |
| Fade-in on every element universally | No — use sparingly |

Easing: `cubic-bezier(0.22, 1, 0.36, 1)` for all transitions.

---

## 7. Component Architecture Rules

- Every component gets visual properties from this system. No bespoke inline values outside the tables above.
- All CSS variables defined in `index.css` under `:root`. No inline style introducing a raw color not in the palette.
- The `glass-panel` class and dark card treatment (`rgba(18,22,31,0.9)`) are violations. This system uses `--paper: #ffffff` cards on `--canvas: #f5f5f5` backgrounds.
- The `hero-title` gradient text class is a violation and must be removed.

---

## 8. Pre-Build Sanity Check Notes

Checked 3 references on styles.refero.design before locking:

1. **"Clinical blueprint" shadcn/ui reference** — confirms achromatic + single teal accent reads as confident and medical. Differentiator from generic dashboards is information density with low decorative noise. This palette passes.

2. **Ora.ai product interface** — demonstrates a light/near-neutral base with one accent creates higher-trust feel for AI products than dark-mode defaults. White card surfaces with hairline borders feel more reliable than frosted-glass panels.

3. **Linear.app interface** — validates IBM Plex Sans choice. IBM Plex Mono pairs naturally for data readouts. Both have clear medical/technical software precedent.

**What felt off during sanity check:** The current dark base (`#0a0d14`) combined with glowing teal reads as "AI lab demo" rather than "clinical tool." The light canvas system corrects this — it will feel closer to Topcon ImageNet or Zeiss FORUM than a SaaS marketing page.
