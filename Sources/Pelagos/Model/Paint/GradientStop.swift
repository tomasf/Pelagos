import Foundation

/// A stop in a gradient
public struct GradientStop: Hashable, Sendable {
    public var offset: Double  // 0.0 to 1.0
    public var color: Color
    public var opacity: Double?

    public init(offset: Double, color: Color, opacity: Double? = nil) {
        self.offset = offset
        self.color = color
        self.opacity = opacity
    }
}
