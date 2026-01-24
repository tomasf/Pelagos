import Foundation

/// Base protocol for all SVG elements
public protocol SVGElement: Sendable {
    var id: String? { get }
}

/// Protocol for elements that can be rendered (have presentation attributes)
public protocol GraphicElement: SVGElement {
    var presentation: PresentationAttributes { get }
}

/// Protocol for elements that can contain child elements
public protocol ContainerElement: SVGElement {
    var children: [any GraphicElement] { get }
}

/// Protocol for elements that reference other elements via href
public protocol ReferencingElement: SVGElement {
    var href: String? { get }
}
