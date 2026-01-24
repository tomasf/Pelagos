import Foundation

/// A fill or stroke paint value
public enum Fill: Hashable, Sendable {
    case none
    case color(Color)
    case url(String)  // Reference to a paint server (gradient, pattern)
    case urlWithFallback(String, Color)
}
