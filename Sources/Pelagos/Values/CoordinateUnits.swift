import Foundation

/// The coordinate system used for gradient, pattern, clip path, mask, and filter coordinates.
///
/// Corresponds to SVG attributes like `gradientUnits`, `patternUnits`, `clipPathUnits`, etc.
public enum CoordinateUnits: String, Hashable, Sendable {
    /// Coordinates are in the current user coordinate system.
    case userSpaceOnUse
    /// Coordinates are relative to the bounding box of the element being painted (0-1 range).
    case objectBoundingBox
}
