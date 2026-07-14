import Testing
@testable import Pelagos

/// A renderer that records element-boundary hooks and paint calls so tests can
/// assert the engine emits balanced begin/end pairs with correct ids and kinds.
private final class RecordingRenderer: SVGRenderer {
    typealias Path = Int
    typealias NativeColor = Int

    enum Event: Equatable {
        case begin(id: String?, kind: SVGElementKind)
        case fill(id: String?)
        case end(id: String?, kind: SVGElementKind)
    }

    private(set) var events: [Event] = []
    private var idStack: [String?] = []

    func makePath() -> Int { 0 }
    func moveTo(_ path: inout Int, x: Double, y: Double) {}
    func lineTo(_ path: inout Int, x: Double, y: Double) {}
    func curveTo(_ path: inout Int, cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) {}
    func quadTo(_ path: inout Int, cpx: Double, cpy: Double, x: Double, y: Double) {}
    func closePath(_ path: inout Int) {}
    func makeColor(from resolved: ResolvedColor) -> Int { 0 }

    func fill(_ path: Int, color: Int, rule: FillRule) { events.append(.fill(id: idStack.last ?? nil)) }
    func stroke(_ path: Int, color: Int, style: StrokeStyle) {}
    func strokeGradient(_ path: Int, gradient: ResolvedGradient, style: StrokeStyle) {}
    func fillGradient(_ path: Int, gradient: ResolvedGradient, rule: FillRule) {}
    func fillPattern(_ path: Int, pattern: ResolvedPattern, rule: FillRule) {}
    func drawText(_ text: ResolvedTextContent) {}
    func drawImage(_ image: ResolvedImageContent) {}

    func save() {}
    func restore() {}
    func concatenate(_ transform: AffineTransform) {}
    func clip(_ path: Int, rule: FillRule) {}
    func setOpacity(_ opacity: Double) {}

    func beginElement(id: String?, kind: SVGElementKind) {
        idStack.append(id)
        events.append(.begin(id: id, kind: kind))
    }

    func endElement(id: String?, kind: SVGElementKind) {
        idStack.removeLast()
        events.append(.end(id: id, kind: kind))
    }
}

@Suite("Element boundary hooks")
struct ElementHookTests {
    private func parse(_ string: String) throws -> SVG {
        try SVGParser().parse(string: string)
    }

    @Test func `emits balanced begin and end pairs with ids and kinds`() throws {
        let svg = try parse("""
            <svg width="100" height="100" viewBox="0 0 100 100">
                <g id="wrap">
                    <rect id="a" x="0" y="0" width="10" height="10" fill="red"/>
                </g>
            </svg>
            """)
        let renderer = RecordingRenderer()
        svg.render(with: renderer)

        // The group and rect are each bracketed by begin/end, with the rect's fill
        // occurring while the rect is the innermost open element.
        #expect(renderer.events == [
            .begin(id: "wrap", kind: .group),
            .begin(id: "a", kind: .rect),
            .fill(id: "a"),
            .end(id: "a", kind: .rect),
            .end(id: "wrap", kind: .group),
        ])
    }

    @Test func `reports kinds for different element types`() throws {
        let svg = try parse("""
            <svg width="100" height="100" viewBox="0 0 100 100">
                <circle cx="50" cy="50" r="10" fill="black"/>
                <path d="M0 0 L10 0 L10 10 Z" fill="black"/>
            </svg>
            """)
        let renderer = RecordingRenderer()
        svg.render(with: renderer)

        let kinds = renderer.events.compactMap { event -> SVGElementKind? in
            if case let .begin(_, kind) = event { kind } else { nil }
        }
        #expect(kinds == [.circle, .path])
    }
}
