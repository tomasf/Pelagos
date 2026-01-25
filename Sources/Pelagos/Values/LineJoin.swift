import Foundation

/// The shape used at the corners of stroked paths.
///
/// Corresponds to the SVG `stroke-linejoin` attribute.
public enum LineJoin: String, Hashable, Sendable {
    /// Sharp corners with a pointed tip (limited by miter limit).
    case miter
    /// Rounded corners with a circular arc.
    case round
    /// Flat corners with a straight line connecting the outer edges.
    case bevel
    /// Like miter, but clips the tip if it exceeds the miter limit.
    case miterClip = "miter-clip"
    /// Joins paths with circular arcs (SVG 2 feature).
    case arcs
}
