import Foundation

/// The algorithm used to determine what parts of a path are inside the shape.
///
/// Corresponds to the SVG `fill-rule` attribute.
public enum FillRule: String, Hashable, Sendable {
    /// A point is inside if a ray from it crosses a non-zero sum of path directions.
    case nonzero
    /// A point is inside if a ray from it crosses an odd number of path segments.
    case evenodd
}
