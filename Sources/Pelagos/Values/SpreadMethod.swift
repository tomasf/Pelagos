import Foundation

/// How a gradient extends beyond its defined bounds.
///
/// Corresponds to the SVG `spreadMethod` attribute on gradients.
public enum SpreadMethod: String, Hashable, Sendable {
    /// The gradient colors at the edges extend infinitely.
    case pad
    /// The gradient repeats in reverse, creating a mirror effect.
    case reflect
    /// The gradient repeats from the beginning.
    case `repeat`
}
