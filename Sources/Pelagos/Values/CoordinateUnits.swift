import Foundation

/// Coordinate units used by gradients, patterns, clip paths, masks, and filters
public enum CoordinateUnits: String, Hashable, Sendable {
    case userSpaceOnUse
    case objectBoundingBox
}
