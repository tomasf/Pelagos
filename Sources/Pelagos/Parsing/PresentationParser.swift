import Foundation
import Nodal

/// Parser for presentation attributes from an SVG element
struct PresentationParser {
    static func parse(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> PresentationAttributes {
        var attrs = parseAttributes(from: node)

        if !styleRules.isEmpty {
            var elementRules: [CSSRule] = []
            var classRules: [CSSRule] = []
            var idRules: [CSSRule] = []

            for rule in styleRules {
                if let specificity = matchSpecificity(for: rule, node: node, ancestors: ancestors) {
                    switch specificity {
                    case .element:
                        elementRules.append(rule)
                    case .class:
                        classRules.append(rule)
                    case .id:
                        idRules.append(rule)
                    }
                }
            }

            for rule in elementRules {
                attrs = attrs.merged(with: parseStyleProperties(rule.properties))
            }

            for rule in classRules {
                attrs = attrs.merged(with: parseStyleProperties(rule.properties))
            }

            for rule in idRules {
                attrs = attrs.merged(with: parseStyleProperties(rule.properties))
            }
        }

        // Inline styles take highest precedence
        if let style = node[attribute: "style"] {
            let inlineAttrs = parseStyleProperties(AttributeParser.parseStyleAttributes(style))
            attrs = attrs.merged(with: inlineAttrs)
        }

        return attrs
    }

    private static func parseAttributes(from node: Node) -> PresentationAttributes {
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

        // Color (for currentColor)
        attrs.color = AttributeParser.parseColor(node[attribute: "color"])

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

    private static func parseStyleProperties(_ properties: [String: String]) -> PresentationAttributes {
        var attrs = PresentationAttributes()

        for (property, value) in properties {
            switch property.lowercased() {
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
            case "color":
                attrs.color = AttributeParser.parseColor(value)
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

    private enum SelectorSpecificity: Int {
        case element = 0
        case `class` = 1
        case id = 2
    }

    private static func matchSpecificity(for rule: CSSRule, node: Node, ancestors: [Node]) -> SelectorSpecificity? {
        let selectors = rule.selector.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var best: SelectorSpecificity?

        for selector in selectors {
            if let specificity = matchSelector(selector, node: node, ancestors: ancestors) {
                if best == nil || specificity.rawValue > best!.rawValue {
                    best = specificity
                }
            }
        }

        return best
    }

    private struct AttributeSelector {
        var name: String
        var value: String?
    }

    private struct CompoundSelector {
        var tagName: String?
        var id: String?
        var classes: [String]
        var attributes: [AttributeSelector]
    }

    private static func matchSelector(_ selector: String, node: Node, ancestors: [Node]) -> SelectorSpecificity? {
        let parts = splitSelector(selector)
        guard !parts.isEmpty else { return nil }

        var compounds: [CompoundSelector] = []
        for part in parts {
            guard let compound = parseCompoundSelector(part) else { return nil }
            compounds.append(compound)
        }

        guard matches(compounds.last, node: node) else { return nil }

        if compounds.count > 1 {
            var ancestorIndex = ancestors.count - 1
            for compound in compounds.dropLast().reversed() {
                var found = false
                while ancestorIndex >= 0 {
                    if matches(compound, node: ancestors[ancestorIndex]) {
                        found = true
                        ancestorIndex -= 1
                        break
                    }
                    ancestorIndex -= 1
                }
                if !found {
                    return nil
                }
            }
        }

        if compounds.contains(where: { $0.id != nil }) {
            return .id
        }
        if compounds.contains(where: { !$0.classes.isEmpty || !$0.attributes.isEmpty }) {
            return .class
        }
        if compounds.contains(where: { $0.tagName != nil }) {
            return .element
        }

        return nil
    }

    private static func splitSelector(_ selector: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var bracketDepth = 0

        for char in selector {
            if char == "[" {
                bracketDepth += 1
            } else if char == "]", bracketDepth > 0 {
                bracketDepth -= 1
            }

            if char.isWhitespace && bracketDepth == 0 {
                if !current.isEmpty {
                    parts.append(current)
                    current = ""
                }
                continue
            }

            current.append(char)
        }

        if !current.isEmpty {
            parts.append(current)
        }

        return parts
    }

    private static func parseCompoundSelector(_ selector: String) -> CompoundSelector? {
        if selector.isEmpty {
            return nil
        }

        var tagName: String?
        var id: String?
        var classes: [String] = []
        var attributes: [AttributeSelector] = []

        var remaining = selector[...]

        if let first = remaining.first, first != "." && first != "#" && first != "[" {
            let name = remaining.prefix { $0 != "." && $0 != "#" && $0 != "[" }
            tagName = String(name)
            remaining = remaining.dropFirst(name.count)
        }

        while let first = remaining.first {
            if first == "#" {
                remaining = remaining.dropFirst()
                let name = remaining.prefix { $0 != "." && $0 != "#" && $0 != "[" }
                id = String(name)
                remaining = remaining.dropFirst(name.count)
            } else if first == "." {
                remaining = remaining.dropFirst()
                let name = remaining.prefix { $0 != "." && $0 != "#" && $0 != "[" }
                classes.append(String(name))
                remaining = remaining.dropFirst(name.count)
            } else if first == "[" {
                remaining = remaining.dropFirst()
                let content = remaining.prefix { $0 != "]" }
                guard remaining.dropFirst(content.count).first == "]" else { return nil }
                remaining = remaining.dropFirst(content.count + 1)

                let parts = content.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard let name = parts.first, !name.isEmpty else { return nil }
                var value: String?
                if parts.count == 2 {
                    value = String(parts[1]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                }
                attributes.append(AttributeSelector(name: String(name), value: value))
            } else {
                return nil
            }
        }

        return CompoundSelector(tagName: tagName, id: id, classes: classes, attributes: attributes)
    }

    private static func matches(_ compound: CompoundSelector?, node: Node) -> Bool {
        guard let compound else { return false }

        if let tagName = compound.tagName, tagName != "*" && !matchesTagName(tagName, node: node) {
            return false
        }

        if let id = compound.id, id != node[attribute: "id"] {
            return false
        }

        if !compound.classes.isEmpty {
            let classList = (node[attribute: "class"] ?? "")
                .split(whereSeparator: { $0.isWhitespace })
                .map { String($0) }
            for className in compound.classes where !classList.contains(className) {
                return false
            }
        }

        for attribute in compound.attributes {
            let (prefix, localName) = splitQualifiedName(attribute.name)
            guard let value = node.attribute(localName: localName, prefix: prefix) else { return false }
            if let expected = attribute.value, value != expected {
                return false
            }
        }

        return true
    }

    private static func matchesTagName(_ tagName: String, node: Node) -> Bool {
        let (prefix, localName) = splitQualifiedName(tagName)

        if let prefix {
            guard node.localName == localName else { return false }
            guard let namespaceURI = node.namespacesInScope[prefix] else { return false }
            return node.expandedName.namespaceName == namespaceURI
        }

        return node.expandedName.namespaceName == SVGNamespace.svg &&
            node.localName == localName
    }

    private static func splitQualifiedName(_ name: String) -> (prefix: String?, localName: String) {
        if let separator = name.firstIndex(of: ":") {
            let prefix = String(name[..<separator])
            let localName = String(name[name.index(after: separator)...])
            return (prefix.isEmpty ? nil : prefix, localName)
        }
        if let separator = name.firstIndex(of: "|") {
            let prefix = String(name[..<separator])
            let localName = String(name[name.index(after: separator)...])
            return (prefix.isEmpty ? nil : prefix, localName)
        }
        return (nil, name)
    }
}
