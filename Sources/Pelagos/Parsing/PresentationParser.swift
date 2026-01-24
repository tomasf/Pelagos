import Foundation
import Nodal

/// Parser for presentation attributes from an SVG element
struct PresentationParser {
    static func parse(from node: Node) -> PresentationAttributes {
        var attrs = PresentationAttributes()

        // Fill properties
        attrs.fill = AttributeParser.parseFill(node[attribute: "fill"])
        attrs.fillOpacity = AttributeParser.parseDouble(node[attribute: "fill-opacity"])
        attrs.fillRule = AttributeParser.parseEnum(node[attribute: "fill-rule"], type: FillRule.self)

        // Stroke properties
        attrs.stroke = AttributeParser.parseFill(node[attribute: "stroke"])
        attrs.strokeOpacity = AttributeParser.parseDouble(node[attribute: "stroke-opacity"])
        attrs.strokeWidth = AttributeParser.parseLength(node[attribute: "stroke-width"])
        attrs.strokeLineCap = AttributeParser.parseEnum(node[attribute: "stroke-linecap"], type: LineCap.self)
        attrs.strokeLineJoin = AttributeParser.parseEnum(node[attribute: "stroke-linejoin"], type: LineJoin.self)
        attrs.strokeMiterLimit = AttributeParser.parseDouble(node[attribute: "stroke-miterlimit"])
        attrs.strokeDashArray = AttributeParser.parseDashArray(node[attribute: "stroke-dasharray"])
        attrs.strokeDashOffset = AttributeParser.parseLength(node[attribute: "stroke-dashoffset"])

        // Opacity and display
        attrs.opacity = AttributeParser.parseDouble(node[attribute: "opacity"])
        attrs.display = AttributeParser.parseEnum(node[attribute: "display"], type: DisplayMode.self)
        attrs.visibility = AttributeParser.parseEnum(node[attribute: "visibility"], type: Visibility.self)

        // Transform
        attrs.transform = AttributeParser.parseTransform(node[attribute: "transform"])

        // References
        attrs.clipPath = AttributeParser.parseURLReference(node[attribute: "clip-path"])
        attrs.mask = AttributeParser.parseURLReference(node[attribute: "mask"])
        attrs.filter = AttributeParser.parseURLReference(node[attribute: "filter"])

        // Font properties
        attrs.fontFamily = node[attribute: "font-family"]
        attrs.fontSize = AttributeParser.parseLength(node[attribute: "font-size"])
        attrs.fontStyle = AttributeParser.parseEnum(node[attribute: "font-style"], type: FontStyle.self)
        attrs.fontWeight = parseFontWeight(node[attribute: "font-weight"])

        // Text properties
        attrs.textAnchor = AttributeParser.parseEnum(node[attribute: "text-anchor"], type: TextAnchor.self)
        attrs.textDecoration = node[attribute: "text-decoration"]

        // CSS class
        attrs.cssClass = node[attribute: "class"]

        // Parse inline style attribute and merge
        if let style = node[attribute: "style"] {
            let styleAttrs = parseStyleAttribute(style)
            attrs = attrs.merged(with: styleAttrs)
        }

        return attrs
    }

    private static func parseFontWeight(_ string: String?) -> FontWeight? {
        guard let string = string?.trimmingCharacters(in: .whitespaces) else { return nil }

        switch string {
        case "normal": return .normal
        case "bold": return .bold
        case "bolder": return .bolder
        case "lighter": return .lighter
        default:
            if let value = Int(string) {
                return .numeric(value)
            }
            return nil
        }
    }

    private static func parseStyleAttribute(_ style: String) -> PresentationAttributes {
        var attrs = PresentationAttributes()

        let declarations = style.split(separator: ";")
        for declaration in declarations {
            let parts = declaration.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let property = String(parts[0]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

            switch property {
            case "fill":
                attrs.fill = AttributeParser.parseFill(value)
            case "fill-opacity":
                attrs.fillOpacity = AttributeParser.parseDouble(value)
            case "fill-rule":
                attrs.fillRule = AttributeParser.parseEnum(value, type: FillRule.self)
            case "stroke":
                attrs.stroke = AttributeParser.parseFill(value)
            case "stroke-opacity":
                attrs.strokeOpacity = AttributeParser.parseDouble(value)
            case "stroke-width":
                attrs.strokeWidth = AttributeParser.parseLength(value)
            case "stroke-linecap":
                attrs.strokeLineCap = AttributeParser.parseEnum(value, type: LineCap.self)
            case "stroke-linejoin":
                attrs.strokeLineJoin = AttributeParser.parseEnum(value, type: LineJoin.self)
            case "stroke-miterlimit":
                attrs.strokeMiterLimit = AttributeParser.parseDouble(value)
            case "stroke-dasharray":
                attrs.strokeDashArray = AttributeParser.parseDashArray(value)
            case "stroke-dashoffset":
                attrs.strokeDashOffset = AttributeParser.parseLength(value)
            case "opacity":
                attrs.opacity = AttributeParser.parseDouble(value)
            case "display":
                attrs.display = AttributeParser.parseEnum(value, type: DisplayMode.self)
            case "visibility":
                attrs.visibility = AttributeParser.parseEnum(value, type: Visibility.self)
            case "transform":
                attrs.transform = AttributeParser.parseTransform(value)
            case "clip-path":
                attrs.clipPath = AttributeParser.parseURLReference(value)
            case "mask":
                attrs.mask = AttributeParser.parseURLReference(value)
            case "filter":
                attrs.filter = AttributeParser.parseURLReference(value)
            case "font-family":
                attrs.fontFamily = value
            case "font-size":
                attrs.fontSize = AttributeParser.parseLength(value)
            case "font-style":
                attrs.fontStyle = AttributeParser.parseEnum(value, type: FontStyle.self)
            case "font-weight":
                attrs.fontWeight = parseFontWeight(value)
            case "text-anchor":
                attrs.textAnchor = AttributeParser.parseEnum(value, type: TextAnchor.self)
            case "text-decoration":
                attrs.textDecoration = value
            default:
                break
            }
        }

        return attrs
    }
}
