import Foundation

/// An SVG radialGradient element
public struct RadialGradient: GradientElement, Hashable, Sendable {
    public var id: String?

    public var cx: Length?
    public var cy: Length?
    public var r: Length?
    public var fx: Length?
    public var fy: Length?
    public var fr: Length?

    public var stops: [GradientStop]
    public var gradientUnits: GradientUnits?
    public var gradientTransform: [Transform]?
    public var spreadMethod: SpreadMethod?
    public var href: String?

    public init(
        id: String? = nil,
        cx: Length? = nil,
        cy: Length? = nil,
        r: Length? = nil,
        fx: Length? = nil,
        fy: Length? = nil,
        fr: Length? = nil,
        stops: [GradientStop] = [],
        gradientUnits: GradientUnits? = nil,
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
