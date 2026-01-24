import Foundation

/// SVG presentation attributes that can be applied to graphic elements
struct PresentationAttributes: Hashable, Sendable {
    // Fill properties
    var fill: Fill?
    var fillOpacity: Double?
    var fillRule: FillRule?

    // Stroke properties
    var stroke: Fill?
    var strokeOpacity: Double?
    var strokeWidth: Length?
    var strokeLineCap: LineCap?
    var strokeLineJoin: LineJoin?
    var strokeMiterLimit: Double?
    var strokeDashArray: [Length]?
    var strokeDashOffset: Length?

    // Opacity and display
    var opacity: Double?
    var display: DisplayMode?
    var visibility: Visibility?

    // Color (used by currentColor)
    var color: Color?

    // Transform
    var transform: [Transform]?

    // References
    var clipPath: String?  // URL reference
    var mask: String?      // URL reference
    var filter: String?    // URL reference

    // Font properties
    var fontFamily: String?
    var fontSize: Length?
    var fontStyle: FontStyle?
    var fontWeight: FontWeight?

    // Text properties
    var textAnchor: TextAnchor?
    var textDecoration: String?

    // CSS class
    var cssClass: String?

    init() {}

    /// Merges another set of attributes on top of this one.
    /// Non-nil values in `other` override values in `self`.
    func merged(with other: PresentationAttributes) -> PresentationAttributes {
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

        if let v = other.color { result.color = v }

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
