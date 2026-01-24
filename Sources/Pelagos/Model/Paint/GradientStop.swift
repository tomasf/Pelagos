import Foundation

/// A stop in a gradient
struct GradientStop: Hashable, Sendable {
    var offset: Double  // 0.0 to 1.0
    var color: Color
    var opacity: Double?

    init(offset: Double, color: Color, opacity: Double? = nil) {
        self.offset = offset
        self.color = color
        self.opacity = opacity
    }
}
