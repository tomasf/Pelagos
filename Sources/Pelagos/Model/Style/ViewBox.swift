import Foundation

/// The viewBox attribute value
public struct ViewBox: Hashable, Sendable {
    public var minX: Double
    public var minY: Double
    public var width: Double
    public var height: Double

    public init(minX: Double, minY: Double, width: Double, height: Double) {
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
    }
}
