import Foundation
import Nodal

/// Parsers for individual SVG element types
enum ElementParsers {
    // MARK: - Shape Parsing

    static func parseRect(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Rect {
        Rect(
            id: node[attribute: "id"],
            x: AttributeParser.parseLength(node[attribute: "x"]) ?? .zero,
            y: AttributeParser.parseLength(node[attribute: "y"]) ?? .zero,
            width: AttributeParser.parseLength(node[attribute: "width"]) ?? .zero,
            height: AttributeParser.parseLength(node[attribute: "height"]) ?? .zero,
            rx: AttributeParser.parseLength(node[attribute: "rx"]),
            ry: AttributeParser.parseLength(node[attribute: "ry"]),
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseCircle(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Circle {
        Circle(
            id: node[attribute: "id"],
            cx: AttributeParser.parseLength(node[attribute: "cx"]) ?? .zero,
            cy: AttributeParser.parseLength(node[attribute: "cy"]) ?? .zero,
            r: AttributeParser.parseLength(node[attribute: "r"]) ?? .zero,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseEllipse(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Ellipse {
        Ellipse(
            id: node[attribute: "id"],
            cx: AttributeParser.parseLength(node[attribute: "cx"]) ?? .zero,
            cy: AttributeParser.parseLength(node[attribute: "cy"]) ?? .zero,
            rx: AttributeParser.parseLength(node[attribute: "rx"]) ?? .zero,
            ry: AttributeParser.parseLength(node[attribute: "ry"]) ?? .zero,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseLine(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Line {
        Line(
            id: node[attribute: "id"],
            x1: AttributeParser.parseLength(node[attribute: "x1"]) ?? .zero,
            y1: AttributeParser.parseLength(node[attribute: "y1"]) ?? .zero,
            x2: AttributeParser.parseLength(node[attribute: "x2"]) ?? .zero,
            y2: AttributeParser.parseLength(node[attribute: "y2"]) ?? .zero,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parsePolyline(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Polyline {
        Polyline(
            id: node[attribute: "id"],
            points: AttributeParser.parsePoints(node[attribute: "points"]) ?? [],
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parsePolygon(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Polygon {
        Polygon(
            id: node[attribute: "id"],
            points: AttributeParser.parsePoints(node[attribute: "points"]) ?? [],
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parsePath(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) throws -> Path {
        let segments: [PathSegment]
        if let d = node[attribute: "d"] {
            segments = try PathParser().parse(d)
        } else {
            segments = []
        }

        return Path(
            id: node[attribute: "id"],
            segments: segments,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    // MARK: - Container Parsing

    static func parseGroup(from node: Node, children: [any GraphicElement], styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Group {
        Group(
            id: node[attribute: "id"],
            children: children,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseAnchor(from node: Node, children: [any GraphicElement], styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Anchor {
        Anchor(
            id: node[attribute: "id"],
            href: parseHref(from: node),
            target: node[attribute: "target"],
            children: children,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseSwitch(from node: Node, children: [any GraphicElement], styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Switch {
        Switch(
            id: node[attribute: "id"],
            children: children,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseSymbol(from node: Node, children: [any GraphicElement]) -> Symbol {
        Symbol(
            id: node[attribute: "id"],
            viewBox: AttributeParser.parseViewBox(node[attribute: "viewBox"]),
            preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(node[attribute: "preserveAspectRatio"]),
            children: children
        )
    }

    // MARK: - Use Element

    static func parseUse(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Use {
        Use(
            id: node[attribute: "id"],
            href: parseHref(from: node),
            x: AttributeParser.parseLength(node[attribute: "x"]),
            y: AttributeParser.parseLength(node[attribute: "y"]),
            width: AttributeParser.parseLength(node[attribute: "width"]),
            height: AttributeParser.parseLength(node[attribute: "height"]),
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    // MARK: - Gradient Parsing

    static func parseLinearGradient(from node: Node, stops: [GradientStop]) -> LinearGradient {
        LinearGradient(
            id: node[attribute: "id"],
            x1: AttributeParser.parseLength(node[attribute: "x1"]),
            y1: AttributeParser.parseLength(node[attribute: "y1"]),
            x2: AttributeParser.parseLength(node[attribute: "x2"]),
            y2: AttributeParser.parseLength(node[attribute: "y2"]),
            stops: stops,
            gradientUnits: AttributeParser.parseEnum(node[attribute: "gradientUnits"], type: GradientUnits.self),
            gradientTransform: AttributeParser.parseTransform(node[attribute: "gradientTransform"]),
            spreadMethod: AttributeParser.parseEnum(node[attribute: "spreadMethod"], type: SpreadMethod.self),
            href: parseHref(from: node)
        )
    }

    static func parseRadialGradient(from node: Node, stops: [GradientStop]) -> RadialGradient {
        RadialGradient(
            id: node[attribute: "id"],
            cx: AttributeParser.parseLength(node[attribute: "cx"]),
            cy: AttributeParser.parseLength(node[attribute: "cy"]),
            r: AttributeParser.parseLength(node[attribute: "r"]),
            fx: AttributeParser.parseLength(node[attribute: "fx"]),
            fy: AttributeParser.parseLength(node[attribute: "fy"]),
            fr: AttributeParser.parseLength(node[attribute: "fr"]),
            stops: stops,
            gradientUnits: AttributeParser.parseEnum(node[attribute: "gradientUnits"], type: GradientUnits.self),
            gradientTransform: AttributeParser.parseTransform(node[attribute: "gradientTransform"]),
            spreadMethod: AttributeParser.parseEnum(node[attribute: "spreadMethod"], type: SpreadMethod.self),
            href: parseHref(from: node)
        )
    }

    static func parseGradientStop(from node: Node) -> GradientStop? {
        let offsetString = node[attribute: "offset"] ?? "0"
        var offset: Double = 0

        if offsetString.hasSuffix("%") {
            offset = (Double(offsetString.dropLast()) ?? 0) / 100.0
        } else {
            offset = Double(offsetString) ?? 0
        }

        // stop-color can come from attribute or style
        var color: Color = .black
        if let stopColor = node[attribute: "stop-color"] {
            color = AttributeParser.parseColor(stopColor) ?? .black
        }

        var opacity = AttributeParser.parseDouble(node[attribute: "stop-opacity"])

        if let style = node[attribute: "style"] {
            let properties = AttributeParser.parseStyleAttributes(style)
            if let stopColor = properties["stop-color"] {
                color = AttributeParser.parseColor(stopColor) ?? color
            }
            if let stopOpacity = properties["stop-opacity"] {
                opacity = AttributeParser.parseDouble(stopOpacity) ?? opacity
            }
        }

        return GradientStop(offset: offset, color: color, opacity: opacity)
    }

    // MARK: - Pattern Parsing

    static func parsePattern(from node: Node, children: [any GraphicElement]) -> Pattern {
        Pattern(
            id: node[attribute: "id"],
            x: AttributeParser.parseLength(node[attribute: "x"]),
            y: AttributeParser.parseLength(node[attribute: "y"]),
            width: AttributeParser.parseLength(node[attribute: "width"]),
            height: AttributeParser.parseLength(node[attribute: "height"]),
            patternUnits: AttributeParser.parseEnum(node[attribute: "patternUnits"], type: GradientUnits.self),
            patternContentUnits: AttributeParser.parseEnum(node[attribute: "patternContentUnits"], type: GradientUnits.self),
            patternTransform: AttributeParser.parseTransform(node[attribute: "patternTransform"]),
            viewBox: AttributeParser.parseViewBox(node[attribute: "viewBox"]),
            preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(node[attribute: "preserveAspectRatio"]),
            href: parseHref(from: node),
            children: children
        )
    }

    // MARK: - Effects Parsing

    static func parseClipPath(from node: Node, children: [any GraphicElement]) -> ClipPath {
        ClipPath(
            id: node[attribute: "id"],
            clipPathUnits: AttributeParser.parseEnum(node[attribute: "clipPathUnits"], type: GradientUnits.self),
            children: children
        )
    }

    static func parseMask(from node: Node, children: [any GraphicElement]) -> Mask {
        Mask(
            id: node[attribute: "id"],
            x: AttributeParser.parseLength(node[attribute: "x"]),
            y: AttributeParser.parseLength(node[attribute: "y"]),
            width: AttributeParser.parseLength(node[attribute: "width"]),
            height: AttributeParser.parseLength(node[attribute: "height"]),
            maskUnits: AttributeParser.parseEnum(node[attribute: "maskUnits"], type: GradientUnits.self),
            maskContentUnits: AttributeParser.parseEnum(node[attribute: "maskContentUnits"], type: GradientUnits.self),
            children: children
        )
    }

    static func parseFilter(from node: Node, primitives: [FilterPrimitive]) -> Filter {
        Filter(
            id: node[attribute: "id"],
            x: AttributeParser.parseLength(node[attribute: "x"]),
            y: AttributeParser.parseLength(node[attribute: "y"]),
            width: AttributeParser.parseLength(node[attribute: "width"]),
            height: AttributeParser.parseLength(node[attribute: "height"]),
            filterUnits: AttributeParser.parseEnum(node[attribute: "filterUnits"], type: GradientUnits.self),
            primitiveUnits: AttributeParser.parseEnum(node[attribute: "primitiveUnits"], type: GradientUnits.self),
            primitives: primitives
        )
    }

    static func parseFilterPrimitive(from node: Node) -> FilterPrimitive? {
        let input = node[attribute: "in"]
        let result = node[attribute: "result"]

        let localName = node.localName
        guard node.expandedName.namespaceName == SVGNamespace.svg else { return nil }

        switch localName {
        case "feGaussianBlur":
            let stdDev = AttributeParser.parseDouble(node[attribute: "stdDeviation"]) ?? 0
            return .gaussianBlur(input: input, stdDeviation: stdDev, result: result)

        case "feColorMatrix":
            let type = AttributeParser.parseEnum(node[attribute: "type"], type: ColorMatrixType.self) ?? .matrix
            let values = AttributeParser.parseDoubleArray(node[attribute: "values"])
            return .colorMatrix(input: input, type: type, values: values, result: result)

        case "feOffset":
            let dx = AttributeParser.parseDouble(node[attribute: "dx"])
            let dy = AttributeParser.parseDouble(node[attribute: "dy"])
            return .offset(input: input, dx: dx, dy: dy, result: result)

        case "feBlend":
            let input2 = node[attribute: "in2"]
            let mode = AttributeParser.parseEnum(node[attribute: "mode"], type: BlendMode.self)
            return .blend(input: input, input2: input2, mode: mode, result: result)

        case "feComposite":
            let input2 = node[attribute: "in2"]
            let op = AttributeParser.parseEnum(node[attribute: "operator"], type: CompositeOperator.self)
            return .composite(input: input, input2: input2, operator_: op, result: result)

        case "feFlood":
            let floodColor = AttributeParser.parseColor(node[attribute: "flood-color"])
            let floodOpacity = AttributeParser.parseDouble(node[attribute: "flood-opacity"])
            return .flood(floodColor: floodColor, floodOpacity: floodOpacity, result: result)

        case "feMerge":
            // feMerge contains feMergeNode children
            return .merge(inputs: [], result: result)

        case "feMorphology":
            let op = AttributeParser.parseEnum(node[attribute: "operator"], type: MorphologyOperator.self)
            let radius = AttributeParser.parseDouble(node[attribute: "radius"])
            return .morphology(input: input, operator_: op, radius: radius, result: result)

        case "feTurbulence":
            let baseFreq = AttributeParser.parseDouble(node[attribute: "baseFrequency"])
            let numOctaves = node[attribute: "numOctaves"].flatMap { Int($0) }
            let seed = node[attribute: "seed"].flatMap { Int($0) }
            let type = AttributeParser.parseEnum(node[attribute: "type"], type: TurbulenceType.self)
            return .turbulence(baseFrequency: baseFreq, numOctaves: numOctaves, seed: seed, type: type, result: result)

        default:
            // Store unknown filter primitives with their attributes
            var attributes: [String: String] = [:]
            for (name, value) in node.attributes {
                attributes[name] = value
            }
            return .unknown(name: node.name, attributes: attributes)
        }
    }

    // MARK: - Content Parsing

    static func parseImage(from node: Node, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Image {
        Image(
            id: node[attribute: "id"],
            href: parseHref(from: node),
            x: AttributeParser.parseLength(node[attribute: "x"]),
            y: AttributeParser.parseLength(node[attribute: "y"]),
            width: AttributeParser.parseLength(node[attribute: "width"]),
            height: AttributeParser.parseLength(node[attribute: "height"]),
            preserveAspectRatio: AttributeParser.parsePreserveAspectRatio(node[attribute: "preserveAspectRatio"]),
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseText(from node: Node, content: [TextContent], styleRules: [CSSRule] = [], ancestors: [Node] = []) -> Text {
        Text(
            id: node[attribute: "id"],
            x: AttributeParser.parseLengthArray(node[attribute: "x"]),
            y: AttributeParser.parseLengthArray(node[attribute: "y"]),
            dx: AttributeParser.parseLengthArray(node[attribute: "dx"]),
            dy: AttributeParser.parseLengthArray(node[attribute: "dy"]),
            rotate: AttributeParser.parseDoubleArray(node[attribute: "rotate"]),
            textLength: AttributeParser.parseLength(node[attribute: "textLength"]),
            lengthAdjust: AttributeParser.parseEnum(node[attribute: "lengthAdjust"], type: LengthAdjust.self),
            content: content,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseTSpan(from node: Node, content: [TextContent], styleRules: [CSSRule] = [], ancestors: [Node] = []) -> TSpan {
        TSpan(
            id: node[attribute: "id"],
            x: AttributeParser.parseLengthArray(node[attribute: "x"]),
            y: AttributeParser.parseLengthArray(node[attribute: "y"]),
            dx: AttributeParser.parseLengthArray(node[attribute: "dx"]),
            dy: AttributeParser.parseLengthArray(node[attribute: "dy"]),
            rotate: AttributeParser.parseDoubleArray(node[attribute: "rotate"]),
            textLength: AttributeParser.parseLength(node[attribute: "textLength"]),
            lengthAdjust: AttributeParser.parseEnum(node[attribute: "lengthAdjust"], type: LengthAdjust.self),
            content: content,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    static func parseTextPath(from node: Node, content: String, styleRules: [CSSRule] = [], ancestors: [Node] = []) -> TextPath {
        TextPath(
            id: node[attribute: "id"],
            href: parseHref(from: node),
            startOffset: AttributeParser.parseLength(node[attribute: "startOffset"]),
            method: AttributeParser.parseEnum(node[attribute: "method"], type: TextPathMethod.self),
            spacing: AttributeParser.parseEnum(node[attribute: "spacing"], type: TextPathSpacing.self),
            content: content,
            presentation: PresentationParser.parse(from: node, styleRules: styleRules, ancestors: ancestors)
        )
    }

    // MARK: - Helper

    private static func parseHref(from node: Node) -> String? {
        let href = node[attribute: "href"] ?? node.xlinkAttribute("href")
        // Remove # prefix for local references
        if let href = href, href.hasPrefix("#") {
            return String(href.dropFirst())
        }
        return href
    }
}
