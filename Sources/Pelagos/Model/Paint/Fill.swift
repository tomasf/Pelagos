import Foundation

/// A fill or stroke paint value
enum Fill: Hashable, Sendable {
    case none
    case color(Color)
    case url(String)  // Reference to a paint server (gradient, pattern)
    case urlWithFallback(String, Color)
}
