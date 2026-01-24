import Foundation

/// A point in 2D space
struct Point: Hashable, Sendable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    static let zero = Point(x: 0, y: 0)
}
