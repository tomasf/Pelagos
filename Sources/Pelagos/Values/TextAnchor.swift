import Foundation

/// The alignment of text relative to its anchor point.
///
/// Corresponds to the SVG `text-anchor` attribute.
public enum TextAnchor: String, Hashable, Sendable {
    /// Text begins at the anchor point (left-aligned for LTR text).
    case start
    /// Text is centered on the anchor point.
    case middle
    /// Text ends at the anchor point (right-aligned for LTR text).
    case end
}
