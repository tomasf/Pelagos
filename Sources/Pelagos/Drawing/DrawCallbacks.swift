import Foundation

public struct DrawContext: Sendable {
    public var presentation: PresentationAttributes
    public var resolvedPaint: ResolvedPaint
    public var transforms: [Transform]
    public var viewBox: ViewBox?
    public var viewSize: (width: Length?, height: Length?)
    public var definitions: Definitions

    public init(
        presentation: PresentationAttributes = PresentationAttributes(),
        resolvedPaint: ResolvedPaint = ResolvedPaint(),
        transforms: [Transform] = [],
        viewBox: ViewBox? = nil,
        viewSize: (width: Length?, height: Length?) = (nil, nil),
        definitions: Definitions = Definitions()
    ) {
        self.presentation = presentation
        self.resolvedPaint = resolvedPaint
        self.transforms = transforms
        self.viewBox = viewBox
        self.viewSize = viewSize
        self.definitions = definitions
    }
}

public struct ResolvedPaint: Sendable {
    public var fillColor: Color?
    public var strokeColor: Color?
    public var fillAlpha: Double
    public var strokeAlpha: Double
    public var fillRule: FillRule
    public var lineWidth: Double?
    public var lineCap: LineCap?
    public var lineJoin: LineJoin?
    public var miterLimit: Double?
    public var dashArray: [Double]?
    public var dashOffset: Double?

    public init(
        fillColor: Color? = nil,
        strokeColor: Color? = nil,
        fillAlpha: Double = 1,
        strokeAlpha: Double = 1,
        fillRule: FillRule = .nonzero,
        lineWidth: Double? = nil,
        lineCap: LineCap? = nil,
        lineJoin: LineJoin? = nil,
        miterLimit: Double? = nil,
        dashArray: [Double]? = nil,
        dashOffset: Double? = nil
    ) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.fillAlpha = fillAlpha
        self.strokeAlpha = strokeAlpha
        self.fillRule = fillRule
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.lineJoin = lineJoin
        self.miterLimit = miterLimit
        self.dashArray = dashArray
        self.dashOffset = dashOffset
    }
}

public struct DrawOptions: Sendable {
    public var resolveUseElements: Bool
    public var includeDefs: Bool
    public var inheritPresentation: Bool
    public var applyUseTranslation: Bool

    public init(
        resolveUseElements: Bool = true,
        includeDefs: Bool = false,
        inheritPresentation: Bool = true,
        applyUseTranslation: Bool = true
    ) {
        self.resolveUseElements = resolveUseElements
        self.includeDefs = includeDefs
        self.inheritPresentation = inheritPresentation
        self.applyUseTranslation = applyUseTranslation
    }
}

public enum DrawDirective: Sendable {
    case `continue`
    case skipChildren
    case stop
}

public struct ResolvedImage: Sendable {
    public var data: Data
    public var mimeType: String?

    public init(data: Data, mimeType: String? = nil) {
        self.data = data
        self.mimeType = mimeType
    }
}

public struct ResolvedImageLayout: Sendable {
    public var x: Double
    public var y: Double
    public var width: Double?
    public var height: Double?
}

public struct ResolvedText: Sendable {
    public var runs: [ResolvedTextRun]
    public var x: Double
    public var y: Double
    public var textAnchor: TextAnchor
}

public struct ResolvedTextRun: Hashable, Sendable {
    public var text: String
    public var fontFamily: String?
    public var fontSize: Double
    public var fillColor: Color?
    public var fillAlpha: Double

    public init(
        text: String,
        fontFamily: String?,
        fontSize: Double,
        fillColor: Color?,
        fillAlpha: Double
    ) {
        self.text = text
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fillColor = fillColor
        self.fillAlpha = fillAlpha
    }
}

public struct ResolvedRect: Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var rx: Double
    public var ry: Double
}

public struct ResolvedCircle: Sendable {
    public var cx: Double
    public var cy: Double
    public var r: Double
}

public struct ResolvedEllipse: Sendable {
    public var cx: Double
    public var cy: Double
    public var rx: Double
    public var ry: Double
}

public struct ResolvedLine: Sendable {
    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double
}

public struct ResolvedPolyline: Sendable {
    public var points: [Point]
}

public struct ResolvedPolygon: Sendable {
    public var points: [Point]
}

public protocol DrawCallback: Sendable {
    func beginSVG(_ svg: SVG, context: DrawContext) -> DrawDirective
    func endSVG(_ svg: SVG, context: DrawContext) -> DrawDirective
    func beginGroup(_ group: Group, context: DrawContext) -> DrawDirective
    func endGroup(_ group: Group, context: DrawContext) -> DrawDirective
    func beginAnchor(_ anchor: Anchor, context: DrawContext) -> DrawDirective
    func endAnchor(_ anchor: Anchor, context: DrawContext) -> DrawDirective
    func beginSwitch(_ switchNode: Switch, context: DrawContext) -> DrawDirective
    func endSwitch(_ switchNode: Switch, context: DrawContext) -> DrawDirective
    func drawRect(_ rect: Rect, resolved: ResolvedRect, context: DrawContext) -> DrawDirective
    func drawCircle(_ circle: Circle, resolved: ResolvedCircle, context: DrawContext) -> DrawDirective
    func drawEllipse(_ ellipse: Ellipse, resolved: ResolvedEllipse, context: DrawContext) -> DrawDirective
    func drawLine(_ line: Line, resolved: ResolvedLine, context: DrawContext) -> DrawDirective
    func drawPolyline(_ polyline: Polyline, resolved: ResolvedPolyline, context: DrawContext) -> DrawDirective
    func drawPolygon(_ polygon: Polygon, resolved: ResolvedPolygon, context: DrawContext) -> DrawDirective
    func drawPath(_ path: Path, context: DrawContext) -> DrawDirective
    func drawText(_ text: Text, resolved: ResolvedText, context: DrawContext) -> DrawDirective
    func drawImage(_ image: Image, resolved: ResolvedImage?, layout: ResolvedImageLayout, context: DrawContext) -> DrawDirective
    func use(_ use: Use, resolved: (any GraphicElement)?, context: DrawContext) -> DrawDirective
    func defs(_ defs: Defs, context: DrawContext) -> DrawDirective
}

public extension DrawCallback {
    func beginSVG(_ svg: SVG, context: DrawContext) -> DrawDirective { .continue }
    func endSVG(_ svg: SVG, context: DrawContext) -> DrawDirective { .continue }
    func beginGroup(_ group: Group, context: DrawContext) -> DrawDirective { .continue }
    func endGroup(_ group: Group, context: DrawContext) -> DrawDirective { .continue }
    func beginAnchor(_ anchor: Anchor, context: DrawContext) -> DrawDirective { .continue }
    func endAnchor(_ anchor: Anchor, context: DrawContext) -> DrawDirective { .continue }
    func beginSwitch(_ switchNode: Switch, context: DrawContext) -> DrawDirective { .continue }
    func endSwitch(_ switchNode: Switch, context: DrawContext) -> DrawDirective { .continue }
    func drawRect(_ rect: Rect, resolved: ResolvedRect, context: DrawContext) -> DrawDirective { .continue }
    func drawCircle(_ circle: Circle, resolved: ResolvedCircle, context: DrawContext) -> DrawDirective { .continue }
    func drawEllipse(_ ellipse: Ellipse, resolved: ResolvedEllipse, context: DrawContext) -> DrawDirective { .continue }
    func drawLine(_ line: Line, resolved: ResolvedLine, context: DrawContext) -> DrawDirective { .continue }
    func drawPolyline(_ polyline: Polyline, resolved: ResolvedPolyline, context: DrawContext) -> DrawDirective { .continue }
    func drawPolygon(_ polygon: Polygon, resolved: ResolvedPolygon, context: DrawContext) -> DrawDirective { .continue }
    func drawPath(_ path: Path, context: DrawContext) -> DrawDirective { .continue }
    func drawText(_ text: Text, resolved: ResolvedText, context: DrawContext) -> DrawDirective { .continue }
    func drawImage(_ image: Image, resolved: ResolvedImage?, layout: ResolvedImageLayout, context: DrawContext) -> DrawDirective { .continue }
    func use(_ use: Use, resolved: (any GraphicElement)?, context: DrawContext) -> DrawDirective { .continue }
    func defs(_ defs: Defs, context: DrawContext) -> DrawDirective { .continue }
}

public extension SVG {
    func walk(callback: DrawCallback, options: DrawOptions = DrawOptions()) {
        let resolvedPaint = resolvePaint(from: presentation)
        let resolvedDefinitions = resolveDefinitions(definitions)
        var rootContext = DrawContext(
            presentation: presentation,
            resolvedPaint: resolvedPaint,
            transforms: presentation.transform ?? [],
            viewBox: viewBox,
            viewSize: (width, height),
            definitions: resolvedDefinitions
        )

        if options.includeDefs {
            for defs in definitions.defs {
                if callback.defs(defs, context: rootContext) == .stop {
                    return
                }
            }
        }

        let directive = callback.beginSVG(self, context: rootContext)
        if directive == .stop { return }

        if directive != .skipChildren {
            if walkChildren(children, callback: callback, context: &rootContext, options: options) == false {
                return
            }
        }

        _ = callback.endSVG(self, context: rootContext)
    }
}

private func walkChildren(
    _ children: [any GraphicElement],
    callback: DrawCallback,
    context: inout DrawContext,
    options: DrawOptions
) -> Bool {
    for child in children {
        if walkElement(child, callback: callback, context: context, options: options) == false {
            return false
        }
    }
    return true
}

private func walkElement(
    _ element: any GraphicElement,
    callback: DrawCallback,
    context: DrawContext,
    options: DrawOptions
) -> Bool {
    if let group = element as? Group {
        var childContext = inheritContext(context, element: group, options: options)
        let directive = callback.beginGroup(group, context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkChildren(group.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.endGroup(group, context: childContext) != .stop
    }

    if let anchor = element as? Anchor {
        var childContext = inheritContext(context, element: anchor, options: options)
        let directive = callback.beginAnchor(anchor, context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkChildren(anchor.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.endAnchor(anchor, context: childContext) != .stop
    }

    if let switchNode = element as? Switch {
        var childContext = inheritContext(context, element: switchNode, options: options)
        let directive = callback.beginSwitch(switchNode, context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkSwitchChildren(switchNode.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.endSwitch(switchNode, context: childContext) != .stop
    }

        if let svg = element as? SVG {
        let resolvedPaint = resolvePaint(from: svg.presentation)
        var childContext = DrawContext(
            presentation: svg.presentation,
            resolvedPaint: resolvedPaint,
            transforms: svg.presentation.transform ?? [],
            viewBox: svg.viewBox,
            viewSize: (svg.width, svg.height),
            definitions: context.definitions
        )

        let directive = callback.beginSVG(svg, context: childContext)
        if directive == .stop { return false }
        if directive != .skipChildren {
            if walkChildren(svg.children, callback: callback, context: &childContext, options: options) == false {
                return false
            }
        }
        return callback.endSVG(svg, context: childContext) != .stop
    }

    if let use = element as? Use {
        var childContext = inheritContext(context, element: use, options: options)
        if options.applyUseTranslation {
            if let x = use.x?.value, let y = use.y?.value {
                childContext.transforms.append(.translate(x: x, y: y))
            } else if let x = use.x?.value {
                childContext.transforms.append(.translate(x: x, y: 0))
            } else if let y = use.y?.value {
                childContext.transforms.append(.translate(x: 0, y: y))
            }
        }

        let resolved = use.href.flatMap { context.definitions.elements[$0] }
        let directive = callback.use(use, resolved: resolved, context: childContext)
        if directive == .stop { return false }

        if options.resolveUseElements, directive != .skipChildren, let resolved {
            return walkElement(resolved, callback: callback, context: childContext, options: options)
        }
        return true
    }

    let leafContext = inheritContext(context, element: element, options: options)

    if let rect = element as? Rect {
        let resolved = resolveRect(rect, context: leafContext)
        return callback.drawRect(rect, resolved: resolved, context: leafContext) != .stop
    }
    if let circle = element as? Circle {
        let resolved = resolveCircle(circle, context: leafContext)
        return callback.drawCircle(circle, resolved: resolved, context: leafContext) != .stop
    }
    if let ellipse = element as? Ellipse {
        let resolved = resolveEllipse(ellipse, context: leafContext)
        return callback.drawEllipse(ellipse, resolved: resolved, context: leafContext) != .stop
    }
    if let line = element as? Line {
        let resolved = resolveLine(line, context: leafContext)
        return callback.drawLine(line, resolved: resolved, context: leafContext) != .stop
    }
    if let polyline = element as? Polyline {
        let resolved = ResolvedPolyline(points: polyline.points)
        return callback.drawPolyline(polyline, resolved: resolved, context: leafContext) != .stop
    }
    if let polygon = element as? Polygon {
        let resolved = ResolvedPolygon(points: polygon.points)
        return callback.drawPolygon(polygon, resolved: resolved, context: leafContext) != .stop
    }
    if let path = element as? Path {
        return callback.drawPath(path, context: leafContext) != .stop
    }
    if let text = element as? Text {
        let resolved = resolveText(text, context: leafContext)
        return callback.drawText(text, resolved: resolved, context: leafContext) != .stop
    }
    if let image = element as? Image {
        let resolved = resolveImage(from: image.href)
        let layout = resolveImageLayout(image, context: leafContext)
        return callback.drawImage(image, resolved: resolved, layout: layout, context: leafContext) != .stop
    }

    return true
}

private func resolveImage(from href: String?) -> ResolvedImage? {
    guard let href, href.hasPrefix("data:") else { return nil }
    return decodeDataURL(href)
}

private func resolveImageLayout(_ image: Image, context: DrawContext) -> ResolvedImageLayout {
    let refs = resolveViewReferences(context)
    let x = resolveLength(image.x, viewRef: refs.width, fontSize: refs.fontSize)
    let y = resolveLength(image.y, viewRef: refs.height, fontSize: refs.fontSize)
    let width = image.width.map { resolveLength($0, viewRef: refs.width, fontSize: refs.fontSize) }
    let height = image.height.map { resolveLength($0, viewRef: refs.height, fontSize: refs.fontSize) }
    return ResolvedImageLayout(x: x, y: y, width: width, height: height)
}

private func resolveRect(_ rect: Rect, context: DrawContext) -> ResolvedRect {
    let refs = resolveViewReferences(context)
    let x = resolveLength(rect.x, viewRef: refs.width, fontSize: refs.fontSize)
    let y = resolveLength(rect.y, viewRef: refs.height, fontSize: refs.fontSize)
    let width = resolveLength(rect.width, viewRef: refs.width, fontSize: refs.fontSize)
    let height = resolveLength(rect.height, viewRef: refs.height, fontSize: refs.fontSize)
    let rx = resolveLength(rect.rx ?? rect.ry, viewRef: refs.width, fontSize: refs.fontSize)
    let ry = resolveLength(rect.ry ?? rect.rx, viewRef: refs.height, fontSize: refs.fontSize)
    return ResolvedRect(x: x, y: y, width: width, height: height, rx: rx, ry: ry)
}

private func resolveCircle(_ circle: Circle, context: DrawContext) -> ResolvedCircle {
    let refs = resolveViewReferences(context)
    let cx = resolveLength(circle.cx, viewRef: refs.width, fontSize: refs.fontSize)
    let cy = resolveLength(circle.cy, viewRef: refs.height, fontSize: refs.fontSize)
    let r = resolveLength(circle.r, viewRef: min(refs.width, refs.height), fontSize: refs.fontSize)
    return ResolvedCircle(cx: cx, cy: cy, r: r)
}

private func resolveEllipse(_ ellipse: Ellipse, context: DrawContext) -> ResolvedEllipse {
    let refs = resolveViewReferences(context)
    let cx = resolveLength(ellipse.cx, viewRef: refs.width, fontSize: refs.fontSize)
    let cy = resolveLength(ellipse.cy, viewRef: refs.height, fontSize: refs.fontSize)
    let rx = resolveLength(ellipse.rx, viewRef: refs.width, fontSize: refs.fontSize)
    let ry = resolveLength(ellipse.ry, viewRef: refs.height, fontSize: refs.fontSize)
    return ResolvedEllipse(cx: cx, cy: cy, rx: rx, ry: ry)
}

private func resolveLine(_ line: Line, context: DrawContext) -> ResolvedLine {
    let refs = resolveViewReferences(context)
    let x1 = resolveLength(line.x1, viewRef: refs.width, fontSize: refs.fontSize)
    let y1 = resolveLength(line.y1, viewRef: refs.height, fontSize: refs.fontSize)
    let x2 = resolveLength(line.x2, viewRef: refs.width, fontSize: refs.fontSize)
    let y2 = resolveLength(line.y2, viewRef: refs.height, fontSize: refs.fontSize)
    return ResolvedLine(x1: x1, y1: y1, x2: x2, y2: y2)
}

private func resolveText(_ text: Text, context: DrawContext) -> ResolvedText {
    let refs = resolveViewReferences(context)
    let runs = buildResolvedTextRuns(
        from: text.content,
        basePresentation: context.presentation,
        viewRefHeight: refs.height
    )
    let x = resolveLength(text.x?.first, viewRef: refs.width, fontSize: refs.fontSize)
    let y = resolveLength(text.y?.first, viewRef: refs.height, fontSize: refs.fontSize)
    let dx = resolveLength(text.dx?.first, viewRef: refs.width, fontSize: refs.fontSize)
    let dy = resolveLength(text.dy?.first, viewRef: refs.height, fontSize: refs.fontSize)
    let anchor = context.presentation.textAnchor ?? .start
    return ResolvedText(runs: runs, x: x + dx, y: y + dy, textAnchor: anchor)
}

private func resolveTextRun(
    text: String,
    presentation: PresentationAttributes,
    fallbackFontSize: Double,
    viewRefHeight: Double
) -> ResolvedTextRun {
    let fontSize = presentation.fontSize?.resolvedValue(viewport: viewRefHeight) ?? fallbackFontSize
    let opacity = presentation.opacity ?? 1
    let fillOpacity = presentation.fillOpacity ?? 1
    let fillAlpha = opacity * fillOpacity
    let fillColor = resolveFillColor(from: presentation.fill)
    return ResolvedTextRun(
        text: text,
        fontFamily: presentation.fontFamily,
        fontSize: fontSize,
        fillColor: fillColor,
        fillAlpha: fillAlpha
    )
}

private func resolveViewReferences(_ context: DrawContext) -> (width: Double, height: Double, fontSize: Double) {
    let width = context.viewBox?.width
        ?? context.viewSize.width?.resolvedValue()
        ?? 0
    let height = context.viewBox?.height
        ?? context.viewSize.height?.resolvedValue()
        ?? 0
    let fontSize = context.presentation.fontSize?.resolvedValue(viewport: height) ?? 16
    return (width, height, fontSize)
}

private func resolveLength(_ length: Length?, viewRef: Double, fontSize: Double) -> Double {
    guard let length else { return 0 }
    return length.resolvedValue(fontSize: fontSize, viewport: viewRef)
}

private func decodeDataURL(_ href: String) -> ResolvedImage? {
    let parts = href.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2 else { return nil }

    let meta = String(parts[0])
    let payload = String(parts[1])
    guard meta.contains("base64"),
          let data = Data(base64Encoded: payload) else {
        return nil
    }

    let mimeType = meta
        .dropFirst("data:".count)
        .split(separator: ";", maxSplits: 1)
        .first
        .map(String.init)

    return ResolvedImage(data: data, mimeType: mimeType)
}

private func inheritContext(
    _ parent: DrawContext,
    element: any GraphicElement,
    options: DrawOptions
) -> DrawContext {
    var presentation = element.presentation
    if options.inheritPresentation {
        presentation = parent.presentation.merged(with: element.presentation)
    }

    var transforms = parent.transforms
    if let local = element.presentation.transform {
        transforms.append(contentsOf: local)
    }

    let resolvedPaint = resolvePaint(from: presentation)

    return DrawContext(
        presentation: presentation,
        resolvedPaint: resolvedPaint,
        transforms: transforms,
        viewBox: parent.viewBox,
        viewSize: parent.viewSize,
        definitions: parent.definitions
    )
}

private func buildResolvedTextRuns(
    from content: [TextContent],
    basePresentation: PresentationAttributes,
    viewRefHeight: Double
) -> [ResolvedTextRun] {
    var runs: [ResolvedTextRun] = []
    let baseFontSize = basePresentation.fontSize?.resolvedValue(viewport: viewRefHeight) ?? 16

    for item in content {
        switch item {
        case .text(let text):
            runs.append(resolveTextRun(
                text: text,
                presentation: basePresentation,
                fallbackFontSize: baseFontSize,
                viewRefHeight: viewRefHeight
            ))
        case .span(let tspan):
            let presentation = basePresentation.merged(with: tspan.presentation)
            runs.append(contentsOf: buildResolvedTextRuns(
                from: tspan.content,
                basePresentation: presentation,
                viewRefHeight: viewRefHeight
            ))
        case .reference(let textPath):
            let presentation = basePresentation.merged(with: textPath.presentation)
            runs.append(resolveTextRun(
                text: textPath.content,
                presentation: presentation,
                fallbackFontSize: baseFontSize,
                viewRefHeight: viewRefHeight
            ))
        }
    }
    return runs
}

private func walkSwitchChildren(
    _ children: [any GraphicElement],
    callback: DrawCallback,
    context: inout DrawContext,
    options: DrawOptions
) -> Bool {
    guard let first = children.first else { return true }
    return walkElement(first, callback: callback, context: context, options: options)
}

private func resolvePaint(from presentation: PresentationAttributes) -> ResolvedPaint {
    let opacity = presentation.opacity ?? 1
    let fillOpacity = presentation.fillOpacity ?? 1
    let strokeOpacity = presentation.strokeOpacity ?? 1
    let fontSize = presentation.fontSize?.resolvedValue() ?? 16

    let fillColor = resolveFillColor(from: presentation.fill)
    let strokeColor = resolveStrokeColor(from: presentation.stroke)

    let miterLimit = presentation.strokeMiterLimit ?? 4

    return ResolvedPaint(
        fillColor: fillColor,
        strokeColor: strokeColor,
        fillAlpha: opacity * fillOpacity,
        strokeAlpha: opacity * strokeOpacity,
        fillRule: presentation.fillRule ?? .nonzero,
        lineWidth: presentation.strokeWidth?.resolvedValue(fontSize: fontSize),
        lineCap: presentation.strokeLineCap,
        lineJoin: presentation.strokeLineJoin,
        miterLimit: miterLimit,
        dashArray: presentation.strokeDashArray?.map { $0.resolvedValue(fontSize: fontSize) },
        dashOffset: presentation.strokeDashOffset?.resolvedValue(fontSize: fontSize)
    )
}

private func resolveFillColor(from fill: Fill?) -> Color? {
    switch fill {
    case .some(.none):
        return nil
    case .some(.color(let color)):
        return resolveColor(color)
    case .some(.urlWithFallback(_, let fallback)):
        return resolveColor(fallback)
    case .some(.url):
        return nil
    case nil:
        return .black
    }
}

private func resolveStrokeColor(from stroke: Fill?) -> Color? {
    switch stroke {
    case .some(.none):
        return nil
    case .some(.color(let color)):
        return resolveColor(color)
    case .some(.urlWithFallback(_, let fallback)):
        return resolveColor(fallback)
    case .some(.url):
        return nil
    case nil:
        return nil
    }
}

private func resolveColor(_ color: Color) -> Color {
    switch color {
    case .named(let name):
        return Color.namedColors[name] ?? .black
    case .currentColor:
        return .black
    default:
        return color
    }
}

private func resolveDefinitions(_ definitions: Definitions) -> Definitions {
    var resolved = definitions
    guard !definitions.gradients.isEmpty else { return resolved }

    var gradients: [String: any GradientElement] = [:]
    gradients.reserveCapacity(definitions.gradients.count)
    for (key, gradient) in definitions.gradients {
        if let linear = gradient as? LinearGradient {
            var copy = linear
            copy.stops = resolveGradientStops(linear.stops)
            gradients[key] = copy
        } else if let radial = gradient as? RadialGradient {
            var copy = radial
            copy.stops = resolveGradientStops(radial.stops)
            gradients[key] = copy
        } else {
            gradients[key] = gradient
        }
    }
    resolved.gradients = gradients
    return resolved
}

private func resolveGradientStops(_ stops: [GradientStop]) -> [GradientStop] {
    stops.map { stop in
        var resolved = stop
        resolved.color = resolveColor(stop.color)
        return resolved
    }
}
