# Pelagos

Pelagos is an SVG parsing and rendering library for Swift. It parses SVG documents into a structured representation and renders them through a pluggable renderer architecture.

## Overview

Pelagos separates SVG processing into two distinct phases:

1. **Parsing** transforms SVG markup into a tree of Swift types representing elements, attributes, and styling information.

2. **Rendering** walks the parsed tree and translates it into drawing commands through a renderer protocol.

This separation allows the same parsed SVG to be rendered to different backends or processed for purposes other than drawing.

## Renderers

The `SVGRenderer` protocol defines the interface between Pelagos and a graphics backend. Pelagos handles all SVG semantics—tree traversal, style inheritance, coordinate transformations, length unit resolution, and shape-to-path conversion—then calls primitive methods on the renderer to perform actual drawing.

A renderer implementation provides:

- **Path construction**: Creating paths and adding lines, curves, and shapes
- **Drawing operations**: Filling and stroking paths with colors, gradients, or patterns
- **Text and image rendering**: Drawing text runs and embedded images
- **State management**: Saving/restoring graphics state, applying transforms, and setting clip paths

Pelagos includes `CGRenderer`, a complete renderer implementation for Core Graphics. Custom renderers can target other graphics APIs or extract geometry for non-rendering purposes such as hit testing or shape analysis.

## Supported SVG Features

**Elements**: rect, circle, ellipse, line, polyline, polygon, path, text, tspan, image, g, defs, symbol, use, clipPath, linearGradient, radialGradient, pattern

**Styling**: Fill and stroke colors, opacity, stroke width, line caps and joins, miter limits, dash arrays, fill rules

**Paint servers**: Linear and radial gradients with stop colors and opacity, patterns with nested content, gradient/pattern inheritance via href

**Transforms**: translate, rotate, scale, skewX, skewY, matrix

**Text**: Font family, size, weight, and style; text anchoring; tspan positioning

**Other**: viewBox and preserveAspectRatio, CSS style blocks, class and ID selectors, currentColor, data URI images