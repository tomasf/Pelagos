import Foundation
import Nodal

/// Parser for SVG documents
public struct SVGParser {
    public init() {}

    // MARK: - Public API

    /// Parse SVG from a URL
    public func parse(url: URL) throws -> SVG {
        let document = try Document(url: url)
        return try parse(document: document)
    }

    /// Parse SVG from data
    public func parse(data: Data) throws -> SVG {
        let document = try Document(data: data)
        return try parse(document: document)
    }

    /// Parse SVG from a string
    public func parse(string: String) throws -> SVG {
        let document = try Document(string: string)
        return try parse(document: document)
    }

    // MARK: - Internal Parsing

    private func parse(document: Document) throws -> SVG {
        guard let root = document.documentElement else {
            throw SVGParseError.noRootElement
        }

        guard root.name == "svg" else {
            throw SVGParseError.invalidRootElement(root.name)
        }

        var definitions = Definitions()
        var styleRules: [CSSRule] = []

        // First pass: collect definitions and styles
        collectDefinitions(from: root, into: &definitions, styles: &styleRules)

        // Second pass: parse the tree
        let children = try parseChildren(of: root, definitions: &definitions)

        return SVG(
            id: root[attribute: "id"],
            width: AttributeParser.parseLength(root[attribute: "width"]),
            height: AttributeParser.parseLength(root[attribute: "height"]),
            viewBox: AttributeParser.parseViewBox(root[attribute: "viewBox"]),
            preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(root[attribute: "preserveAspectRatio"]),
            children: children,
            definitions: definitions,
            presentation: PresentationParser.parse(from: root)
        )
    }

    // MARK: - Definition Collection

    private func collectDefinitions(from node: Node, into definitions: inout Definitions, styles: inout [CSSRule]) {
        // Skip non-element nodes
        guard node.kind == .element else { return }

        // Collect style elements
        if node.name == "style" {
            let cssText = node.textContent
            let rules = CSSParser.parse(cssText)
            styles.append(contentsOf: rules)
        }

        // Process defs container
        if node.name == "defs" {
            for child in node.elements {
                collectDefinition(from: child, into: &definitions)
            }
        }

        // Recurse
        for child in node.elements {
            collectDefinitions(from: child, into: &definitions, styles: &styles)
        }
    }

    private func collectDefinition(from node: Node, into definitions: inout Definitions) {
        guard let id = node[attribute: "id"], !id.isEmpty else { return }

        switch node.name {
        case "linearGradient":
            let stops = parseGradientStops(from: node)
            let gradient = ElementParsers.parseLinearGradient(from: node, stops: stops)
            definitions.gradients[id] = gradient

        case "radialGradient":
            let stops = parseGradientStops(from: node)
            let gradient = ElementParsers.parseRadialGradient(from: node, stops: stops)
            definitions.gradients[id] = gradient

        case "pattern":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs)) ?? []
            let pattern = ElementParsers.parsePattern(from: node, children: children)
            definitions.patterns[id] = pattern

        case "clipPath":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs)) ?? []
            let clipPath = ElementParsers.parseClipPath(from: node, children: children)
            definitions.clipPaths[id] = clipPath

        case "mask":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs)) ?? []
            let mask = ElementParsers.parseMask(from: node, children: children)
            definitions.masks[id] = mask

        case "filter":
            let primitives = parseFilterPrimitives(from: node)
            let filter = ElementParsers.parseFilter(from: node, primitives: primitives)
            definitions.filters[id] = filter

        case "symbol":
            var innerDefs = definitions
            let children = (try? parseChildren(of: node, definitions: &innerDefs)) ?? []
            let symbol = ElementParsers.parseSymbol(from: node, children: children)
            definitions.symbols[id] = symbol

        default:
            // Store other elements with ids for use references
            if let graphic = try? parseElement(node, definitions: &definitions) {
                definitions.elements[id] = graphic
            }
        }
    }

    // MARK: - Element Parsing

    private func parseChildren(of parent: Node, definitions: inout Definitions) throws -> [any GraphicElement] {
        var children: [any GraphicElement] = []

        for child in parent.elements {
            // Skip defs, style, and non-graphic elements
            if child.name == "defs" || child.name == "style" || child.name == "desc" ||
               child.name == "title" || child.name == "metadata" {
                continue
            }

            // Skip definition elements at top level (they're in defs)
            if ["linearGradient", "radialGradient", "pattern", "clipPath", "mask", "filter", "symbol"].contains(child.name) {
                // Still collect them if they have ids
                if child[attribute: "id"] != nil {
                    collectDefinition(from: child, into: &definitions)
                }
                continue
            }

            if let graphic = try? parseElement(child, definitions: &definitions) {
                children.append(graphic)

                // Register if it has an id
                if let id = graphic.id {
                    definitions.elements[id] = graphic
                }
            }
        }

        return children
    }

    private func parseElement(_ node: Node, definitions: inout Definitions) throws -> (any GraphicElement)? {
        switch node.name {
        // Shapes
        case "rect":
            return ElementParsers.parseRect(from: node)

        case "circle":
            return ElementParsers.parseCircle(from: node)

        case "ellipse":
            return ElementParsers.parseEllipse(from: node)

        case "line":
            return ElementParsers.parseLine(from: node)

        case "polyline":
            return ElementParsers.parsePolyline(from: node)

        case "polygon":
            return ElementParsers.parsePolygon(from: node)

        case "path":
            return try ElementParsers.parsePath(from: node)

        // Containers
        case "g":
            let children = try parseChildren(of: node, definitions: &definitions)
            return ElementParsers.parseGroup(from: node, children: children)

        case "svg":
            // Nested SVG
            let children = try parseChildren(of: node, definitions: &definitions)
            return SVG(
                id: node[attribute: "id"],
                width: AttributeParser.parseLength(node[attribute: "width"]),
                height: AttributeParser.parseLength(node[attribute: "height"]),
                viewBox: AttributeParser.parseViewBox(node[attribute: "viewBox"]),
                preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(node[attribute: "preserveAspectRatio"]),
                children: children,
                definitions: Definitions(),
                presentation: PresentationParser.parse(from: node)
            )

        case "a":
            let children = try parseChildren(of: node, definitions: &definitions)
            return ElementParsers.parseAnchor(from: node, children: children)

        case "switch":
            let children = try parseChildren(of: node, definitions: &definitions)
            return ElementParsers.parseSwitch(from: node, children: children)

        // References
        case "use":
            return ElementParsers.parseUse(from: node)

        // Content
        case "image":
            return ElementParsers.parseImage(from: node)

        case "text":
            let content = parseTextContent(from: node)
            return ElementParsers.parseText(from: node, content: content)

        default:
            // Unknown element - skip
            return nil
        }
    }

    // MARK: - Gradient Stops

    private func parseGradientStops(from node: Node) -> [GradientStop] {
        var stops: [GradientStop] = []

        for child in node.elements {
            if child.name == "stop", let stop = ElementParsers.parseGradientStop(from: child) {
                stops.append(stop)
            }
        }

        return stops
    }

    // MARK: - Filter Primitives

    private func parseFilterPrimitives(from node: Node) -> [FilterPrimitive] {
        var primitives: [FilterPrimitive] = []

        for child in node.elements {
            if let primitive = ElementParsers.parseFilterPrimitive(from: child) {
                primitives.append(primitive)
            }
        }

        return primitives
    }

    // MARK: - Text Content

    private func parseTextContent(from node: Node) -> [TextContent] {
        var content: [TextContent] = []

        for child in node.children {
            if child.kind == .text || child.kind == .cdata {
                let text = child.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    content.append(.text(text))
                }
            } else if child.kind == .element {
                switch child.name {
                case "tspan":
                    let innerContent = parseTextContent(from: child)
                    let tspan = ElementParsers.parseTSpan(from: child, content: innerContent)
                    content.append(.span(tspan))

                case "textPath":
                    let text = child.textContent
                    let textPath = ElementParsers.parseTextPath(from: child, content: text)
                    content.append(.reference(textPath))

                default:
                    break
                }
            }
        }

        return content
    }
}

// MARK: - Errors

public enum SVGParseError: Error {
    case noRootElement
    case invalidRootElement(String)
    case parsingFailed(String)
}

// MARK: - CSS Parsing (Basic)

struct CSSRule {
    var selector: String
    var properties: [String: String]
}

struct CSSParser {
    static func parse(_ css: String) -> [CSSRule] {
        var rules: [CSSRule] = []

        // Very basic CSS parsing - extract rule blocks
        let rulePattern = #"([^{]+)\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: rulePattern) else {
            return rules
        }

        let range = NSRange(css.startIndex..., in: css)
        let matches = regex.matches(in: css, range: range)

        for match in matches {
            guard let selectorRange = Range(match.range(at: 1), in: css),
                  let bodyRange = Range(match.range(at: 2), in: css) else { continue }

            let selector = String(css[selectorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let body = String(css[bodyRange])

            var properties: [String: String] = [:]
            let declarations = body.split(separator: ";")
            for declaration in declarations {
                let parts = declaration.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let property = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                properties[property] = value
            }

            rules.append(CSSRule(selector: selector, properties: properties))
        }

        return rules
    }
}

// MARK: - Node Extension for textContent

extension Node {
    var textContent: String {
        var result = ""
        for child in children {
            if child.kind == .text || child.kind == .cdata {
                result += child.value
            } else if child.kind == .element {
                result += child.textContent
            }
        }
        return result
    }
}
