import Foundation

/// Pelagos: A Swift library for parsing SVG files into typed data structures.
///
/// Example usage:
/// ```swift
/// let parser = SVGParser()
/// let svg = try parser.parse(url: URL(fileURLWithPath: "image.svg"))
/// ```
///
/// The library parses SVG documents into a tree of strongly-typed Swift structs:
/// - `SVG`: Root element containing dimensions, viewBox, and child elements
/// - Shapes: `Rect`, `Circle`, `Ellipse`, `Line`, `Polyline`, `Polygon`, `Path`
/// - Containers: `Group`, `Anchor`, `Switch`, `Symbol`
/// - Paint servers: `LinearGradient`, `RadialGradient`, `Pattern`
/// - Effects: `ClipPath`, `Mask`, `Filter`
/// - Content: `Text`, `Image`, `Use`
///
/// All elements preserve their original SVG attributes and support:
/// - Presentation attributes (fill, stroke, opacity, transform, etc.)
/// - URL references to definitions (gradients, clip paths, masks)
/// - Length values with units preserved (px, em, %, etc.)
public enum Pelagos {
    /// The library version
    public static let version = "0.1.0"
}

// Re-export main types for convenience
public typealias SVGDocument = SVG
