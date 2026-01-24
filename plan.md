# Pelagos: SVG Tree Parsing Library

## Overview
Swift library that parses SVG files into a strongly-typed tree data structure using Nodal for XML parsing. Output is data structures only - no rendering.

## Progress

### Completed
- [x] Phase 1: Foundation
- [x] Phase 2: Basic Shapes
- [x] Phase 3: Path Support
- [x] Phase 4: Structure
- [x] Phase 5: Paint Servers
- [x] Phase 6: Effects & Content
- [x] Phase 7: Styles

---

## Core Design

### Protocol Hierarchy
```swift
protocol Element: Identifiable { var id: String? { get } }
protocol GraphicElement: Element { var presentation: PresentationAttributes { get } }
protocol ContainerElement: Element { var children: [any GraphicElement] { get } }
```

### Supported Elements (matching SwiftDraw)
- **Shapes:** `Rect`, `Circle`, `Ellipse`, `Line`, `Polyline`, `Polygon`, `Path`
- **Structural:** `SVG` (root), `Group`, `Use`, `Anchor`, `Switch`
- **Paint:** `LinearGradient`, `RadialGradient`, `Pattern`, `GradientStop`
- **Effects:** `ClipPath`, `Mask`, `Filter`
- **Content:** `Text`, `Image`
- **Definitions:** `Defs` container

### Key Value Types
- `Length` - value + unit (px, em, %, etc.)
- `Color` - named, rgb, rgba, p3, currentColor, none
- `Fill` - color, url reference, or none
- `Transform` - matrix, translate, scale, rotate, skewX, skewY
- `PathSegment` - all SVG path commands (M, L, H, V, C, S, Q, T, A, Z)
- `PresentationAttributes` - stroke, fill, opacity, transform, clip-path, mask, filter, fonts

---

## File Structure
```
Sources/Pelagos/
├── Pelagos.swift                 # Public entry point (SVGParser)
├── Model/
│   ├── Elements/                 # SVG, Group, Use, etc.
│   ├── Shapes/                   # Rect, Circle, Path, etc.
│   ├── Paint/                    # Color, Fill, Gradients, Pattern
│   ├── Effects/                  # ClipPath, Mask, Filter
│   └── Style/                    # PresentationAttributes, Transform, Length
├── Values/                       # Enums: LineCap, LineJoin, FillRule, etc.
├── Path/                         # PathSegment, PathParser
└── Parsing/                      # SVGParser, element parsers, attribute parsers
```

---

## Parsing Strategy

1. **Entry Point:** `SVGParser.parse(url:)`, `parse(data:)`, `parse(string:)`
2. **Two-Pass Parsing:**
   - Pass 1: Build tree, collect definitions (elements with `id`), parse `<style>`
   - Pass 2: Resolve `href` references, apply CSS cascade
3. **Cascade Order:** element attrs → class rules → id rules → inline style

---

## Implementation Phases

### Phase 1: Foundation
- [ ] Package.swift with Nodal dependency
- [ ] Value types: `Point`, `Length`, `Color`, `Fill`
- [ ] Enums: `LineCap`, `LineJoin`, `FillRule`, `DisplayMode`, `TextAnchor`
- [ ] `PresentationAttributes`, `Transform`

### Phase 2: Basic Shapes
- [ ] Protocols: `Element`, `GraphicElement`, `ContainerElement`
- [ ] Shape structs: `Rect`, `Circle`, `Ellipse`, `Line`, `Polyline`, `Polygon`
- [ ] `SVGParser` skeleton with Nodal integration
- [ ] Shape parsing

### Phase 3: Path Support
- [ ] `PathSegment` enum (all SVG commands)
- [ ] Path data parser for `d` attribute
- [ ] `Path` struct

### Phase 4: Structure
- [ ] `Group`, `SVG` root, `Defs` container
- [ ] Child element parsing for containers
- [ ] Definition registry

### Phase 5: Paint Servers
- [ ] `LinearGradient`, `RadialGradient`, `GradientStop`
- [ ] `Pattern`
- [ ] `href` reference handling between gradients

### Phase 6: Effects & Content
- [ ] `ClipPath`, `Mask`, `Filter`
- [ ] `Text`, `Image`
- [ ] `Use`, `Anchor`, `Switch`

### Phase 7: Styles
- [ ] `<style>` element parsing
- [ ] CSS cascade implementation

---

## Key Design Decisions
- **Structs** for all model types (value semantics)
- **Preserve units** in `Length` rather than converting to pixels
- **Store URL references** rather than eagerly resolving (avoids circular issues)
- **Optional properties** in `PresentationAttributes` for cascade merging

---

## Dependencies
- Nodal (local: ../Nodal) - XML parsing

---

## Notes
- `href` references are preserved on elements/gradients; resolution is left to callers.
- CSS selector support is limited to element/class/id selectors (no descendant/attribute selectors).
