import Foundation

/// Protocol for gradient elements
public protocol GradientElement: SVGElement, Sendable {
    var stops: [GradientStop] { get }
    var gradientUnits: GradientUnits? { get }
    var gradientTransform: [Transform]? { get }
    var spreadMethod: SpreadMethod? { get }
    var href: String? { get }
}
