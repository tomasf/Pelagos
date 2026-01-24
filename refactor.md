# Pelagos Renderer API Simplification Plan

## Problem Summary

The current renderer architecture requires too much boilerplate. The `DrawCallback` protocol has 17+ methods (begin/end pairs for containers, individual draw methods for each shape type), and renderers still need to:
- Convert each shape type to paths
- Handle clip paths, gradients, patterns
- Manage graphics state and transforms

**Current `CGContextRenderer`:** ~540 lines + ~500 lines of helpers

## Root Cause

The current design exposes SVG's element-level structure to renderers, but renderers don't care about whether something is a `<rect>` vs `<circle>` - they just need to draw paths with paint.

## Proposed Solution: Primitive-Based Renderer Protocol

Replace the element-visitor pattern with a **drawing-primitive protocol**. Pelagos handles all SVG semantics (shapes→paths, inheritance, references) and emits only primitive drawing commands.

### New Protocol Design

```swift
public protocol SVGRenderer {
    associatedtype Path
    associatedtype NativeColor

    // Path construction (called by Pelagos to build paths)
    func makePath() -> Path
    func moveTo(_ path: inout Path, x: Double, y: Double)
    func lineTo(_ path: inout Path, x: Double, y: Double)
    func curveTo(_ path: inout Path, cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double)
    func quadTo(_ path: inout Path, cpx: Double, cpy: Double, x: Double, y: Double)
    func closePath(_ path: inout Path)
    func addRect(_ path: inout Path, x: Double, y: Double, width: Double, height: Double, rx: Double, ry: Double)
    func addEllipse(_ path: inout Path, cx: Double, cy: Double, rx: Double, ry: Double)

    // Color conversion
    func makeColor(r: UInt8, g: UInt8, b: UInt8, a: Double) -> NativeColor
    func makeColor(p3 r: Double, g: Double, b: Double, a: Double) -> NativeColor

    // Drawing operations (the only things renderers must implement)
    func fill(_ path: Path, color: NativeColor, rule: FillRule, opacity: Double)
    func stroke(_ path: Path, color: NativeColor, style: StrokeStyle)
    func fillGradient(_ path: Path, gradient: ResolvedGradient, rule: FillRule)
    func fillPattern(_ path: Path, pattern: ResolvedPattern, rule: FillRule)
    func drawText(_ text: ResolvedText, at: Point)
    func drawImage(_ image: ResolvedImage, in rect: Rect)

    // State management
    func save()
    func restore()
    func concatenate(_ transform: AffineTransform)
    func clip(_ path: Path, rule: FillRule)
}
```

### Key Changes

1. **Pelagos owns shape→path conversion**: Instead of `drawRect(resolved:)`, `drawCircle(resolved:)`, etc., Pelagos builds paths internally using the renderer's path API, then calls `fill()` or `stroke()`.

2. **No begin/end pairs**: Container elements (Group, SVG, Anchor, Switch) are handled entirely by Pelagos through save/restore and transform concatenation.

3. **Resolved gradient/pattern types**: Pelagos pre-resolves gradients and patterns into renderer-friendly structures with all coordinates computed.

4. **Default implementations for simple paths**: The protocol extension provides default `addRect`, `addEllipse` implementations using the basic path operations.

### Rendering Flow

```
svg.render(with: renderer)
  │
  ├─ Pelagos walks tree internally
  │   ├─ Inherits presentation attributes
  │   ├─ Resolves lengths to doubles
  │   ├─ Resolves color references
  │   └─ Builds transform stack
  │
  └─ For each visible element:
      ├─ renderer.save()
      ├─ renderer.concatenate(transforms)
      ├─ if clipPath: renderer.clip(buildClipPath())
      ├─ let path = buildPath(element)  // using renderer's path API
      ├─ if shouldFill:
      │   ├─ solid color → renderer.fill(path, color, rule, opacity)
      │   ├─ gradient → renderer.fillGradient(path, gradient, rule)
      │   └─ pattern → renderer.fillPattern(path, pattern, rule)
      ├─ if shouldStroke:
      │   └─ renderer.stroke(path, color, style)
      └─ renderer.restore()
```

## Implementation Plan

### Phase 1: Define New Protocol & Types

**Files to create:**
- `Sources/Pelagos/Rendering/SVGRenderer.swift` - New protocol
- `Sources/Pelagos/Rendering/RenderTypes.swift` - AffineTransform, StrokeStyle, ResolvedGradient, ResolvedPattern

**Types needed:**
```swift
struct AffineTransform { var a, b, c, d, tx, ty: Double }
struct StrokeStyle { var width, miterLimit: Double; var cap: LineCap; var join: LineJoin; var dash: [Double]?; var dashOffset: Double }
struct ResolvedGradient { /* fully resolved coords and colors */ }
struct ResolvedPattern { /* pattern content as child SVG */ }
```

### Phase 2: Implement Rendering Engine

**File:** `Sources/Pelagos/Rendering/SVGRenderEngine.swift`

Core rendering logic that:
1. Walks the SVG tree
2. Manages inherited state
3. Builds paths using renderer's path API
4. Calls renderer's fill/stroke/text/image methods

### Phase 3: CoreGraphics Renderer

**File:** `Sources/Pelagos/Rendering/CG/CGRenderer.swift`

Minimal implementation (~150 lines):
- Path = CGMutablePath
- NativeColor = CGColor
- Direct CGContext calls for fill/stroke/text/image

### Phase 4: Remove Old API

1. Delete old `Drawing/` directory entirely
2. Update any tests to use new API
3. Update PelagosCLI if it uses the renderer

## Files to Modify/Create

| File | Action |
|------|--------|
| `Rendering/SVGRenderer.swift` | Create - new protocol |
| `Rendering/RenderTypes.swift` | Create - supporting types |
| `Rendering/SVGRenderEngine.swift` | Create - core rendering logic |
| `Rendering/CG/CGRenderer.swift` | Create - new CG implementation |
| `Drawing/` | Delete - entire directory |

## Verification

1. **Unit tests**: Parse and render test SVGs, verify output images look correct
2. **API simplicity**: CGRenderer should be ~150 lines (down from ~540)
3. **CLI test**: Run PelagosCLI on sample SVGs to verify rendering works

## Benefits

- **Simpler renderer implementations**: ~70% less code
- **Better separation**: Pelagos owns all SVG semantics
- **Easier to port**: Adding a new renderer (Skia, Metal, Canvas) requires only primitive implementations
- **Type-safe paths**: Associated types allow platform-optimized path representations
