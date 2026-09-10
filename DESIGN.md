---
version: alpha
name: Kikin
description: >-
  Kikin is a fintech platform that pays supplier invoices to unlock working capital for growing businesses, combining
  environmental responsibility with financial pragmatism through a nature-inspired, high-contrast visual system.
logo:
  src: https://cdn.prod.website-files.com/635273ea37c256ef2835d522/65265117824778abff6ad0e4_Logo-black.svg
colors:
  surface: '#f3ede4'
  surface-dim: '#e5ddd2'
  surface-bright: '#faf7f3'
  surface-container-lowest: '#fefdfb'
  surface-container-low: '#f9f5f0'
  surface-container: '#f3ede4'
  surface-container-high: '#ede6db'
  surface-container-highest: '#e7dfd4'
  on-surface: '#122315'
  on-surface-variant: '#3d4a42'
  inverse-surface: '#122315'
  inverse-on-surface: '#f3ede4'
  outline: '#6b7a72'
  outline-variant: '#bcc4bc'
  surface-tint: '#55dd4a'
  primary: '#55dd4a'
  on-primary: '#0a1a08'
  primary-container: '#3b9b34'
  on-primary-container: '#f3ede4'
  inverse-primary: '#b0f127'
  secondary: '#73d3eb'
  on-secondary: '#0d3a47'
  secondary-container: '#1f5a6d'
  on-secondary-container: '#c5eef7'
  tertiary: '#3898ec'
  on-tertiary: '#ffffff'
  tertiary-container: '#1e5a9e'
  on-tertiary-container: '#e3f0ff'
  error: '#d32f2f'
  on-error: '#ffffff'
  error-container: '#ffcdd2'
  on-error-container: '#b71c1c'
  primary-fixed: '#b0f127'
  primary-fixed-dim: '#77e46e'
  on-primary-fixed: '#0a1a08'
  on-primary-fixed-variant: '#1f5a1a'
  secondary-fixed: '#c5eef7'
  secondary-fixed-dim: '#73d3eb'
  on-secondary-fixed: '#0d3a47'
  on-secondary-fixed-variant: '#1f5a6d'
  tertiary-fixed: '#e3f0ff'
  tertiary-fixed-dim: '#3898ec'
  on-tertiary-fixed: '#001a47'
  on-tertiary-fixed-variant: '#1e5a9e'
  background: '#f3ede4'
  on-background: '#122315'
  surface-variant: '#ddd5ca'
typography:
  display:
    fontFamily: Deacon, Graphik, Arial, sans-serif
    fontSize: 72px
    fontWeight: '700'
    lineHeight: 80px
    letterSpacing: '-0.04em'
  headline-lg:
    fontFamily: Deacon, Graphik, Arial, sans-serif
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: '-0.02em'
  headline-md:
    fontFamily: Deacon, Graphik, Arial, sans-serif
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: '-0.01em'
  title-lg:
    fontFamily: Graphik, Arial, sans-serif
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: 0em
  body-lg:
    fontFamily: Graphik, Arial, sans-serif
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Graphik, Arial, sans-serif
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  label-md:
    fontFamily: Graphik, Arial, sans-serif
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Graphik, Arial, sans-serif
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.08em
rounded:
  sm: 4px
  DEFAULT: 8px
  md: 10px
  lg: 16px
  xl: 20px
  full: 9999px
spacing:
  unit: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 24px
  container-max: 1280px
elevation:
  sm: 0 1px 2px rgba(18, 35, 21, 0.06)
  md: 0 4px 12px rgba(18, 35, 21, 0.08)
  lg: 0 16px 40px rgba(18, 35, 21, 0.12)
layout:
  containerMaxWidth: 1280px
  gridColumns: 12
components:
  button-primary:
    backgroundColor: '{colors.primary}'
    textColor: '{colors.on-primary}'
    typography: '{typography.label-md}'
    rounded: '{rounded.lg}'
    padding: 12px 24px
    height: 48px
    border: none
    transition: all 200ms ease-out
  button-primary-hover:
    backgroundColor: '{colors.primary-fixed-dim}'
    textColor: '{colors.on-primary}'
    boxShadow: 0 4px 12px rgba(85, 221, 74, 0.24)
  button-primary-active:
    backgroundColor: '{colors.primary-container}'
    textColor: '{colors.on-primary-container}'
  button-secondary:
    backgroundColor: transparent
    textColor: '{colors.primary}'
    typography: '{typography.label-md}'
    rounded: '{rounded.lg}'
    padding: 12px 24px
    height: 48px
    border: 1px solid {colors.outline-variant}
    transition: all 200ms ease-out
  button-secondary-hover:
    backgroundColor: '{colors.surface-container-high}'
    textColor: '{colors.primary}'
    borderColor: '{colors.outline}'
  button-secondary-light:
    backgroundColor: transparent
    textColor: '{colors.on-surface}'
    typography: '{typography.label-md}'
    rounded: '{rounded.lg}'
    padding: 12px 24px
    height: 48px
    border: 1px solid rgba(18, 35, 21, 0.2)
  card:
    backgroundColor: '{colors.surface-container}'
    rounded: '{rounded.lg}'
    padding: '{spacing.md}'
    border: 1px solid {colors.outline-variant}
    boxShadow: '{elevation.sm}'
  card-elevated:
    backgroundColor: '{colors.surface-container-low}'
    rounded: '{rounded.lg}'
    padding: '{spacing.md}'
    border: 1px solid {colors.outline-variant}
    boxShadow: '{elevation.md}'
  card-hover:
    backgroundColor: '{colors.surface-container-high}'
    boxShadow: '{elevation.md}'
    transition: all 200ms ease-out
  input-field:
    backgroundColor: '{colors.surface-container-lowest}'
    textColor: '{colors.on-surface}'
    typography: '{typography.body-md}'
    rounded: '{rounded.DEFAULT}'
    padding: '{spacing.sm}'
    border: 1px solid {colors.outline-variant}
    height: 44px
  input-field-focus:
    borderColor: '{colors.primary}'
    boxShadow: 0 0 0 3px rgba(85, 221, 74, 0.12)
  badge-primary:
    backgroundColor: '{colors.primary-container}'
    textColor: '{colors.on-primary-container}'
    typography: '{typography.label-sm}'
    rounded: '{rounded.full}'
    padding: 4px 12px
  badge-secondary:
    backgroundColor: '{colors.secondary-container}'
    textColor: '{colors.on-secondary-container}'
    typography: '{typography.label-sm}'
    rounded: '{rounded.full}'
    padding: 4px 12px
  list-item:
    backgroundColor: transparent
    rounded: '{rounded.md}'
    padding: '{spacing.sm}'
    transition: all 150ms ease-out
  list-item-hover:
    backgroundColor: '{colors.surface-container-high}'
    textColor: '{colors.primary}'
  nav-link:
    textColor: '{colors.on-surface}'
    typography: '{typography.body-md}'
    fontWeight: '500'
    transition: color 150ms ease-out
  nav-link-active:
    textColor: '{colors.primary}'
    fontWeight: '600'
---

## Overview

Kikin is a fintech platform that bridges environmental responsibility with business pragmatism, offering invoice financing to unlock working capital without equity dilution. The visual system embodies 'Ecological Minimalism'—a design movement that pairs nature-inspired color palettes (deep forest greens, soft off-whites, bright neon accents) with architectural precision and high contrast. The UI evokes clarity and trustworthiness: a clean, light canvas (#f3ede4) anchored by a bold forest green (#122315) and energized by a vibrant neon-green primary accent (#55dd4a) that signals growth, sustainability, and forward momentum. Every interaction feels deliberate and grounded.

Kikin's voice is direct, optimistic, and grounded in business reality. The tone avoids hype; instead, it speaks in concrete terms about cash flow, supplier relationships, and environmental impact. Vocabulary leans technical-but-accessible: 'working capital,' 'invoice financing,' 'real-time analysis,' 'runway.' The brand personality is confident without arrogance—a trusted advisor who understands both the planet and the P&L. Example sentence in brand voice: 'Your suppliers get paid faster. You get the cash today. The planet gets a win.'

## Colors

The Kikin color system is rooted in a high-contrast, nature-inspired palette that prioritizes clarity and emotional resonance. Primary (#55dd4a, a vibrant neon-green) is the signature accent used exclusively on call-to-action buttons ('Get funding'), active navigation states, and key interactive elements. It signals growth and environmental alignment. Secondary (#73d3eb, a cool turquoise) supports data visualization and secondary actions, evoking trust and technology. Tertiary (#3898ec, a professional blue) reinforces institutional credibility in modals and status indicators.

The surface stack is anchored in warm, off-white tones: surface (#f3ede4) serves as the primary canvas, with surface-container-lowest (#fefdfb) used for input fields and surface-container-high (#ede6db) for hover sta

## Typography

The type system pairs a distinctive display typeface (Deacon, used for headlines and hero text) with a humanist sans-serif (Graphik) for body and UI copy. Display (72px, 700 weight, -0.04em letter-spacing) commands attention on hero sections and major headings, while headline-lg (48px, 700 weight) anchors section breaks. Body-lg (18px, 400 weight, 28px line-height) ensures readability in long-form content; body-md (16px, 400 weight) is the default for UI labels and descriptions. Label-md (14px, 600 weight, 0.05em letter-spacing) is applied to button text and form labels, creating visual hierarchy through weight rather than size. All text over busy backgrounds (e.g., hero illustrations) receives a subtle text-shadow: 0 2px 4px rgba(18, 35, 21, 0.15) to ensure legibility. Heading weights (60

## Layout

Kikin uses a 12-column fluid grid with a max-width of 1280px (1280px on desktop, 728px on tablet, full-width on mobile). The page rhythm is built on a semantic spacing scale: md (24px) for section gutters and card padding, lg (40px) for major section separation, and xl (64px) for hero-to-content transitions. Container padding uses gutter (24px) on desktop, reducing to md (24px) on tablet and sm (12px) on mobile. White-space is generous but purposeful—the off-white background (#f3ede4) breathes, allowing content to feel unhurried and premium. Cards and input fields use consistent padding (md: 24px) to create visual rhythm. The calculator frame and impact frame are responsive, scaling from 673px width on desktop to 100% on tablet (991px breakpoint), ensuring the interface adapts without cram

## Elevation & Depth

Depth in Kikin is conveyed through a restrained shadow system and subtle surface layering, avoiding the heavy drop-shadows of older design systems. Level 1 (Base): The off-white surface (#f3ede4) serves as the foundation with no shadow. Level 2 (Standard Card): Cards use a 1px border in outline-variant (#bcc4bc) and a soft shadow (0 1px 2px rgba(18, 35, 21, 0.06)) to separate from the background. Level 3 (Elevated/Modals): Elevated cards and modals use a stronger shadow (0 4px 12px rgba(18, 35, 21, 0.08)) and a border in outline (#6b7a72) to signal prominence. Interactive hover states on butto

## Shapes

The shape philosophy is 'Architectural Softness'—rounded corners are used strategically to soften the precision of a financial interface without sacrificing clarity. Buttons use lg (16px) border-radius, creating a friendly, approachable CTA that still feels professional. Cards and elevated surfaces use lg (16px) as well, establishing visual consistency. Input fields use the DEFAULT radius (8px), a middle ground that signals interactivity without the softness of buttons. Badges and pills use full (9999px) for maximum approachability in status indicators. The rationale: larger radii (16px+) on p

## Components

### Action Elements
Buttons are the primary call-to-action mechanism. Button-primary uses primary (#55dd4a) background with on-primary text (#0a1a08), 48px height, 12px vertical / 24px horizontal padding, and lg (16px) border-radius. On hover, the background shifts to primary-fixed-dim (#77e46e) and a contextual shadow (0 4px 12px rgba(85, 221, 74, 0.24)) appears, with a 200ms ease-out transition. On active/pressed, the background darkens to primary-container (#3b9b34). Button-secondary uses a transparent background with primary text and a 1px outline-variant border; on hover, it fills with surface-container-high (#ede6db). Button-secondary-light (used on dark backgrounds like the green navbar) uses on-surface text with a subtle rgba(18, 35, 21, 0.2) border.

### Containers & Surfaces
Card

## Do's and Don'ts

**Do**
- Do use primary (#55dd4a) exclusively on CTAs and active states—it's the brand's signature and should feel rare and intentional.
- Do maintain the 1px outline-variant border on all cards and inputs; it's the visual grammar that holds the system together.
- Do apply the 200ms ease-out transition to all interactive state changes (hover, focus, active) to create a cohesive, responsive feel.
- Do use the off-white surface (#f3ede4) as the default background; it's warm, premium, and reduces eye strain on financial dashboards.
- Do pair Deacon (display) with Graphik (body) for maximum brand distinctiveness; the contrast between geometric headlines and humanist body text is intentional.
- Do use md (24px) spacing as the default unit for card padding and section gutters; it's the visual rhythm of the system.

**Don't**
- Don't use primary (#55dd4a) on body text or backgrounds—it's reserved for interactive elements and will lose impact if overused.
- Don't apply shadows heavier than lg (0 16px 40px rgba(18, 35, 21, 0.12)); Kikin's aesthetic is light and precise, not dramatic.
- Don't mix rounded corners arbitrarily; stick to the defined scale (sm: 4px, DEFAULT: 8px, md: 10px, lg: 16px, xl: 20px, full: 9999px).
- Don't use the secondary (#73d3eb) or tertiary (#3898ec) colors as primary CTAs; they're supporting accents and will dilute the primary's authority.
- Don't apply text-shadow to body text on light backgrounds; it's only for text over illustrations or busy backgrounds.
- Don't exceed 1280px container max-width; the system is designed for focused, scannable layouts, not sprawling content.
