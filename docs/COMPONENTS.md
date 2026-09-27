# RetinaAI — Component Specification
**SIH 26038 · Explainable DR Screening**
**Status: APPROVED — Component inventory and style bindings**

> Every component must bind to radius, shadow, spacing, and color values from DESIGN.md. No bespoke values permitted.

---

## System-level tokens (bound to DESIGN.md)

```css
/* Applied to every component — no exceptions */
--radius-badge:   6px;
--radius-nested:  10px;
--radius-input:   18px;
--radius-card:    24px;
--card-shadow:    0 0 0 1px rgba(23,23,23,0.05), 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px -1px rgba(0,0,0,0.1);
--card-border:    1px solid #e5e5e5;
--card-padding:   20px;
--gap-element:    8px;
```

---

## 1. Navbar

**What it displays:** Logo wordmark + sub-label, 4 anchor links, one primary CTA button.
**Interactive:** Scroll-aware border-bottom opacity. Button opens ScreeningStudio overlay.
**Data binds to:** Nothing — static.

Style bindings:
- Height: 56px, fixed position
- Background: `--surface-alt` (#fafafa) on scroll, transparent at top
- Border-bottom: `--hairline` (#e5e5e5) when scrolled
- Logo mark: 28x28px, border-radius `--radius-nested` (10px), background `--ink` (#0a0a0a)
- Nav links: `--body` (14px/400), color `--mid-gray` on default, `--ink` on hover, underline in `--teal` on hover
- CTA: `--ink` (#0a0a0a) fill, `--paper` (#ffffff) text, `--radius-input` (18px), no shadow

---

## 2. Hero Section

**What it displays:** Eyebrow caption, display headline, body-lg subhead, two CTAs, three stat pills below.
**Interactive:** Primary CTA opens ScreeningStudio overlay. Secondary CTA scrolls to pipeline.
**Data binds to:** Nothing — static.

Style bindings:
- Background: `--canvas` (#f5f5f5) — no gradient, no image overlay
- Layout: two-column asymmetric grid (copy 1fr, right-side card 440px max), gap `--sp-12` (48px)
- Headline: Display scale (48px/600/-0.05em/1.1), color `--ink` (#0a0a0a)
- Subhead: Body-lg (16px/400/1.5), color `--mid-gray` (#737373), max-width 460px
- Primary CTA: `--ink` fill, white text, `--radius-input` (18px), padding 12px 24px
- Secondary CTA: transparent fill, `--ink` border (1px), `--ink` text, `--radius-input` (18px)
- Stat pills: 3 inline items, Caption scale, `--mid-gray` label, `--ink-soft` value, separated by `--hairline` dividers

---

## 3. HeroPreviewCard (right-side hero card)

**What it displays:** A static mockup of a fundus image thumbnail with 3 overlay badges showing quality score, grade, and a "passed" indicator. Purpose: makes the hero tangible.
**Interactive:** None — static decoration only.
**Data binds to:** Static demo values only.

Style bindings:
- Container: `--paper` (#ffffff) background, `--radius-card` (24px), `--card-shadow`, `--card-border`
- Padding: `--card-padding` (20px)
- Fundus image area: `--radius-nested` (10px), background `--ink-soft`/`#171717` (dark viewport), aspect-ratio 4/3
- Quality badge: Caption scale, `--teal` color, `--radius-badge` (6px), `rgba(15,118,110,0.1)` background
- Grade badge: Caption scale, `--amber` color if Grade 2+, `--radius-badge` (6px)

---

## 4. ContextStrip (trust numbers)

**What it displays:** Three factual statistics in a horizontal row. Numbers count up on scroll-in.
**Interactive:** Count-up animation on first intersection.
**Data binds to:** Static hardcoded values (77M, 1:100k, 90%).

Style bindings:
- Background: `--surface-alt` (#fafafa), border-top and border-bottom `--hairline`
- Padding: 28px top/bottom
- Stat number: Heading-lg scale (36px/600/-0.09em/1.11), `--ink` color
- Stat caption: Caption scale (12px/500/+0.06em), `--mid-gray` color

---

## 5. PipelineTrack

**What it displays:** 5 numbered stage nodes connected by a progress rail. Nodes animate in sequence on scroll.
**Interactive:** Nodes transition done/active/next states as animation plays. No click interaction.
**Data binds to:** Static STEPS array.

Style bindings:
- Section background: `--canvas`
- Rail: 2px dashed `--hairline`, horizontal
- Fill: `--teal` color, width transitions 0 to 86%, 420ms ease
- Node ring: 44px circle, border 1.5px `--hairline` default, `--teal` when active/done
- Node label: Body (14px/600), `--ink` on done, `--mid-gray` on next
- Node desc: Caption (12px/400), `--mid-gray`
- Stage number: IBM Plex Mono 10px, `--mid-gray`

---

## 6. ScreeningStudio (overlay workspace)

**What it displays:** Full-screen overlay with three-panel layout: left (image selection), center (image viewer), right (results).
**Interactive:** Sample selector, file upload, run button, image view tab switcher (Raw / Enhanced / Heatmap).
**Data binds to:** `/api/samples` (sample list), `/api/screen` (screening result).

Style bindings:
- Overlay backdrop: rgba(245,245,245,0.95) — matches canvas, not dark blur
- Panel container: `--paper` background, `--radius-card` (24px), `--card-shadow`, `--card-border`
- Left panel: 340px fixed width, `--surface-alt` background, `--card-border` right side
- Center panel: flex-1, image viewport `--radius-nested` (10px), background `--ink` (#0a0a0a) for fundus display
- Right panel: 300px fixed width, scrollable

---

## 7. SampleListItem

**What it displays:** Image filename, grade label, ground-truth grade badge.
**Interactive:** Click to select. Selected state changes background and border.
**Data binds to:** SampleItem from `/api/samples`.

Style bindings:
- Unselected: `--paper` bg, `--hairline` border, `--radius-nested` (10px)
- Selected: `rgba(15,118,110,0.06)` bg, `--teal` border color, `--radius-nested` (10px)
- Filename: Body (14px/500), `--ink-soft`
- Grade label: Caption (12px), `--mid-gray`
- Grade badge: Caption, `--radius-badge` (6px), `--amber` for Grade 2+, `--teal` for Grade 0

---

## 8. ImageViewport

**What it displays:** Fundus photograph in one of three views (Raw / CLAHE enhanced / Saliency map). Tab strip above.
**Interactive:** Tab switcher changes displayed image.
**Data binds to:** `result.images.raw`, `result.images.enhanced`, `result.images.heatmap`.

Style bindings:
- Viewport container: `--radius-nested` (10px), background #0a0a0a (fundus images need dark surround)
- Tab group: Caption scale, `--surface-alt` bg, `--hairline` border, active tab gets `--paper` bg + `--ink` text
- Active tab indicator: `--teal` 2px bottom line, not background fill
- Overlay badges (quality/CDR): `--radius-badge` (6px), Caption scale

---

## 9. QualityGateCard (Stage 1 result)

**What it displays:** Overall quality score, three sub-metrics (Focus / Illumination / FOV), each with a pass/fail indicator and numeric value.
**Interactive:** None.
**Data binds to:** `result.stage1Quality`.

Style bindings:
- Container: `--paper`, `--radius-card` (24px), `--card-shadow`, `--card-border`, `--card-padding`
- Header: Caption eyebrow "STAGE 1 — QUALITY GATE", `--mid-gray`
- Overall score: Heading-sm (24px/600), `--teal` if passed, `--amber` if borderline, `--ink` if failed
- Sub-metric rows: Body (14px), label `--mid-gray`, value `--ink-soft`, pass dot `--teal`, fail dot `--amber`
- Bar track: 4px height, `--hairline` bg, `--teal` fill

---

## 10. LesionCountCard (Stage 3 result)

**What it displays:** Dark lesion count (microaneurysms + hemorrhages) and bright lesion count (exudates). Cup-to-disc ratio and vessel density.
**Interactive:** None.
**Data binds to:** `result.stage3Segmentation`.

Style bindings:
- Container: same as QualityGateCard
- Header: Caption eyebrow "STAGE 3 — LESION COUNTS"
- Dark lesion count: Heading (30px/600), `--amber` color (clinical severity)
- Bright lesion count: Heading (30px/600), `--amber` if non-zero
- CDR value: IBM Plex Mono 14px, `--ink-soft`
- Vessel density: IBM Plex Mono 14px, `--ink-soft`

---

## 11. GradeCard (Stage 4 result)

**What it displays:** DR grade name, ICDR level number, ICD-10 code, confidence score, urgency/referral recommendation, DME risk.
**Interactive:** None.
**Data binds to:** `result.stage4Grading`.

Style bindings:
- Container: same as QualityGateCard
- Header: Caption eyebrow "STAGE 4 — DR GRADE"
- Grade number: Display scale (48px/600), `--ink` for Grade 0, `--amber` for Grade 2+
- Grade name: Heading-sm (24px/600), `--ink-soft`
- Confidence: IBM Plex Mono 14px, `--mid-gray` label, `--teal` value
- Urgency row: Body (14px/400), `--ink-soft`, `--amber` for urgent cases
- DME risk: Caption + inline colored dot (teal = none, amber = elevated)

---

## 12. ProbabilityBars (per-class confidence)

**What it displays:** 5 horizontal bars for ICDR Grade 0–4 probabilities. Active grade is highlighted.
**Interactive:** None.
**Data binds to:** `result.stage4Grading.probabilities[0..4]`.

Style bindings:
- Bar track: 4px height, `--hairline` bg
- Active grade bar fill: `--teal` if Grade 0, `--amber` if Grade 1-2, `--amber` darker if Grade 3-4
- Inactive grade bars: `--hairline` fill
- Label: Caption (12px), grade name left, percentage right, IBM Plex Mono for number

---

## 13. RoutingCard (Stage 5 / routing layer)

**What it displays:** Routing decision (AUTO_CLEAR / DOCTOR_REVIEW / OOD_FLAG / RETAKE), reason text, Mahalanobis distance.
**Interactive:** None.
**Data binds to:** `result.routing`.

Style bindings:
- Container: same as QualityGateCard
- Decision label: Caption eyebrow, colored by decision: `--teal` (AUTO_CLEAR), `--amber` (DOCTOR_REVIEW), `--ink-soft` (OOD_FLAG / RETAKE)
- Reason text: Body (14px/400), `--mid-gray`
- Mahalanobis distance: IBM Plex Mono (12px), `--mid-gray` label, `--ink-soft` value

---

## 14. EvidencePanel (Explainability section)

**What it displays:** Static section showing an SVG fundus diagram with lesion annotations and a sidebar with confidence bars per lesion type.
**Interactive:** None — static demo.
**Data binds to:** Static demo values.

Style bindings:
- Section background: `--surface-alt` (#fafafa)
- Card: `--paper`, `--radius-card`, `--card-shadow`, `--card-border`
- SVG fundus panel: `--radius-nested` (10px), background #0a0a0a
- Lesion annotation dots: `--amber` for active lesions, `--teal` for clear areas
- Confidence bar: 4px height, `--teal` fill
- Evidence row: Body (14px), `--ink-soft` label, IBM Plex Mono value, `--hairline` row separator

---

## 15. ValidationSection

**What it displays:** Two headline metric cards (Sensitivity 90%, Specificity 85%) and a comparison table vs. baseline.
**Interactive:** Count-up on scroll, bar width transition on scroll.
**Data binds to:** Static values (targets, not live measured).

Style bindings:
- Section background: `--canvas`
- Metric card: `--paper`, `--radius-card`, `--card-shadow`, `--card-border`, `--card-padding`
- Big number: Heading-lg (36px/600), `--ink`
- Label: Caption, `--mid-gray`
- Bar (pipeline): `--teal` fill
- Bar (baseline): `--hairline` fill (gray — not a third color)

---

## 16. DeploymentSection

**What it displays:** Four-node flow diagram (Capture, Queue, Inference, Review) with animated flow-dots on connecting pipes.
**Interactive:** Flow-dot animation on scroll-in.
**Data binds to:** Static NODES array.

Style bindings:
- Section background: `--canvas`
- Diagram card: `--paper`, `--radius-card`, `--card-shadow`, `--card-border`, padding 24px
- Active node (Inference): `--teal` border and fill dot
- Inactive nodes: `--hairline` border, `--surface-alt` fill
- Node label: Body (14px/600), `--ink-soft`
- Node sub: Caption (12px), `--mid-gray`
- Pipe connector: 2px dashed `--hairline`, flow-dot `--teal`

---

## 17. Footer

**What it displays:** Wordmark, 4 anchor links, legal note.
**Interactive:** Links scroll to sections.
**Data binds to:** Nothing — static.

Style bindings:
- Background: `--canvas` (#f5f5f5), border-top `--hairline`
- Wordmark: same as Navbar
- Links: Caption scale, `--mid-gray`, hover `--ink-soft`
- Legal note: Caption (12px), `--mid-gray`, max-width 480px
