# ADR 0004: Sensory Modes & Low-Stimulation Accessibility Standard

## Status
Accepted

## Context
Many individuals seeking quiet contemplation or spiritual rest experience sensory overload, visual fatigue, or visual impairments (light sensitivity, low contrast sensitivity, migraines). Standard application theming typically offers only basic light and dark modes with high saturation accents.

## Decision
We implement four distinct Sensory Themes via `ThemeNotifier`:
1. **Sage Mode** (Default): Calming, organic desaturated green palette (`#4A7C59` on `#F4F7F5`) specifically designed for visual relaxation and nervous system ease.
2. **Clean Mode**: Neutral daylight white palette (`#FAFAFA`) with soft slate dividers and zero high-chroma elements.
3. **Charcoal Mode**: Deep slate and dark green theme (`#1A1D20` / `#24282D`) avoiding harsh pure-black OLED contrast for evening contemplation.
4. **Contrast Mode**: High-contrast black, white, and yellow (`#FFFF00` / `#FFFFFF` on `#000000`) compliant with WCAG AAA standards for low-vision accessibility.

## Consequences
- **Positive**: Exceptional visual ergonomics; directly supportive of neurodivergent and light-sensitive community members.
- **Trade-off**: Requires verifying all custom widgets and borders across all 4 themes.
