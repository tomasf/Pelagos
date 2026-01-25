import Foundation

/// The shape used at the end of open subpaths when stroked.
///
/// Corresponds to the SVG `stroke-linecap` attribute.
public enum LineCap: String, Hashable, Sendable {
    /// The stroke ends exactly at the endpoint with no extension.
    case butt
    /// The stroke extends beyond the endpoint with a semicircular cap.
    case round
    /// The stroke extends beyond the endpoint with a rectangular cap.
    case square
}
