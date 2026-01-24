import Foundation

/// An SVG linearGradient element
struct LinearGradient: GradientElement, Hashable, Sendable {
    var id: String?

    var x1: Length?
    var y1: Length?
    var x2: Length?
    var y2: Length?

    var stops: [GradientStop]
    var gradientUnits: GradientUnits?
    var gradientTransform: [Transform]?
    var spreadMethod: SpreadMethod?
    var href: String?

    init(
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
