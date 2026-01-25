import Foundation

/// An SVG radialGradient element
struct RadialGradient: GradientElement, Hashable, Sendable {
    var id: String?

    var cx: Length?
    var cy: Length?
    var r: Length?
    var fx: Length?
    var fy: Length?
    var fr: Length?

    var stops: [GradientStop]
    var gradientUnits: CoordinateUnits?
    var gradientTransform: [Transform]?
    var spreadMethod: SpreadMethod?
    var href: String?

    init(
        id: String? = nil,
        cx: Length? = nil,
        cy: Length? = nil,
        r: Length? = nil,
        fx: Length? = nil,
        fy: Length? = nil,
        fr: Length? = nil,
        stops: [GradientStop] = [],
        gradientUnits: CoordinateUnits? = nil,
        gradientTransform: [Transform]? = nil,
        spreadMethod: SpreadMethod? = nil,
        href: String? = nil
    ) {
        self.id = id
        self.cx = cx
        self.cy = cy
        self.r = r
        self.fx = fx
        self.fy = fy
        self.fr = fr
        self.stops = stops
        self.gradientUnits = gradientUnits
        self.gradientTransform = gradientTransform
        self.spreadMethod = spreadMethod
        self.href = href
    }
}
