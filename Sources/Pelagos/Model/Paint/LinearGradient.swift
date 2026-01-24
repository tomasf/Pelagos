import Foundation

/// An SVG linearGradient element
public struct LinearGradient: GradientElement, Hashable, Sendable {
    public var id: String?

    public var x1: Length?
    public var y1: Length?
    public var x2: Length?
    public var y2: Length?

    public var stops: [GradientStop]
    public var gradientUnits: GradientUnits?
    public var gradientTransform: [Transform]?
    public var spreadMethod: SpreadMethod?
    public var href: String?

    public init(
        id: String? = nil,
        x1: Length? = nil,
        y1: Length? = nil,
        x2: Length? = nil,
        y2: Length? = nil,
        stops: [GradientStop] = [],
        gradientUnits: GradientUnits? = nil,
        gradientTransform: [Transform]? = nil,
        spreadMethod: SpreadMethod? = nil,
        href: String? = nil
    ) {
        self.id = id
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.stops = stops
        self.gradientUnits = gradientUnits
        self.gradientTransform = gradientTransform
        self.spreadMethod = spreadMethod
        self.href = href
    }
}
