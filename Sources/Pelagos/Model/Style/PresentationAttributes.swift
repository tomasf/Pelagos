import Foundation

/// SVG presentation attributes that can be applied to graphic elements
public struct PresentationAttributes: Hashable, Sendable {
    // Fill properties
    public var fill: Fill?
    public var fillOpacity: Double?
    public var fillRule: FillRule?

    // Stroke properties
    public var stroke: Fill?
    public var strokeOpacity: Double?
    public var strokeWidth: Length?
    public var strokeLineCap: LineCap?
    public var strokeLineJoin: LineJoin?
    public var strokeMiterLimit: Double?
    public var strokeDashArray: [Length]?
    public var strokeDashOffset: Length?

    // Opacity and display
    public var opacity: Double?
    public var display: DisplayMode?
    public var visibility: Visibility?

    // Transform
    public var transform: [Transform]?

    // References
    public var clipPath: String?  // URL reference
    public var mask: String?      // URL reference
    public var filter: String?    // URL reference

    // Font properties
    public var fontFamily: String?
    public var fontSize: Length?
    public var fontStyle: FontStyle?
    public var fontWeight: FontWeight?

    // Text properties
    public var textAnchor: TextAnchor?
    public var textDecoration: String?

    // CSS class
    public var cssClass: String?

    public init() {}

    /// Merges another set of attributes on top of this one.
    /// Non-nil values in `other` override values in `self`.
    public func merged(with other: PresentationAttributes) -> PresentationAttributes {
        var result = self

        if let v = other.fill { result.fill = v }
        if let v = other.fillOpacity { result.fillOpacity = v }
        if let v = other.fillRule { result.fillRule = v }

        if let v = other.stroke { result.stroke = v }
        if let v = other.strokeOpacity { result.strokeOpacity = v }
        if let v = other.strokeWidth { result.strokeWidth = v }
        if let v = other.strokeLineCap { result.strokeLineCap = v }
        if let v = other.strokeLineJoin { result.strokeLineJoin = v }
        if let v = other.strokeMiterLimit { result.strokeMiterLimit = v }
        if let v = other.strokeDashArray { result.strokeDashArray = v }
        if let v = other.strokeDashOffset { result.strokeDashOffset = v }

        if let v = other.opacity { result.opacity = v }
        if let v = other.display { result.display = v }
        if let v = other.visibility { result.visibility = v }

        if let v = other.transform { result.transform = v }

        if let v = other.clipPath { result.clipPath = v }
        if let v = other.mask { result.mask = v }
        if let v = other.filter { result.filter = v }

        if let v = other.fontFamily { result.fontFamily = v }
        if let v = other.fontSize { result.fontSize = v }
        if let v = other.fontStyle { result.fontStyle = v }
        if let v = other.fontWeight { result.fontWeight = v }

        if let v = other.textAnchor { result.textAnchor = v }
        if let v = other.textDecoration { result.textDecoration = v }

        if let v = other.cssClass { result.cssClass = v }

        return result
    }
}
