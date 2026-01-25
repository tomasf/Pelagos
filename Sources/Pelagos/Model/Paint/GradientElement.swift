import Foundation

/// Protocol for gradient elements
protocol GradientElement: SVGElement, Sendable {
    var stops: [GradientStop] { get }
    var gradientUnits: CoordinateUnits? { get }
    var gradientTransform: [Transform]? { get }
    var spreadMethod: SpreadMethod? { get }
    var href: String? { get }
}
