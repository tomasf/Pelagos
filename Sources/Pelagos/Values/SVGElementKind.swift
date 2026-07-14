import Foundation

/// The kind of SVG element being rendered.
///
/// Reported to renderers through ``SVGRenderer/beginElement(id:kind:)`` and
/// ``SVGRenderer/endElement(id:kind:)`` so they can react to element boundaries
/// (for example to filter, hit-test, or map drawing output back to source elements)
/// without depending on Pelagos's internal element types.
public enum SVGElementKind: Sendable, Hashable {
    case svg
    case group
    case anchor
    case `switch`
    case symbol
    case use
    case rect
    case circle
    case ellipse
    case line
    case polyline
    case polygon
    case path
    case text
    case image
    /// An element kind not otherwise represented by this enumeration.
    case other
}
