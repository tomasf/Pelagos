import Testing
@testable import Pelagos

@Suite("Color Parsing")
struct ColorParsingTests {
    @Test func `parses none as Color none`() {
        let color = AttributeParser.parseColor("none")
        #expect(color == Color.none)
    }

    @Test func `parses currentColor keyword`() {
        let color = AttributeParser.parseColor("currentColor")
        #expect(color == .currentColor)
    }

    @Test func `parses 3-digit hex colors`() {
        let color = AttributeParser.parseColor("#f00")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 255)
            #expect(g == 0)
            #expect(b == 0)
        } else {
            Issue.record("Expected RGB color")
        }
    }

    @Test func `parses 6-digit hex colors`() {
        let color = AttributeParser.parseColor("#00ff00")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 0)
            #expect(g == 255)
            #expect(b == 0)
        } else {
            Issue.record("Expected RGB color")
        }
    }

    @Test func `parses named colors`() {
        let color = AttributeParser.parseColor("red")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 255)
            #expect(g == 0)
            #expect(b == 0)
        } else {
            Issue.record("Expected RGB color")
        }
    }

    @Test func `parses rgb function syntax`() {
        let color = AttributeParser.parseColor("rgb(128, 64, 32)")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 128)
            #expect(g == 64)
            #expect(b == 32)
        } else {
            Issue.record("Expected RGB color")
        }
    }

    @Test func `parses rgba function with alpha`() {
        let color = AttributeParser.parseColor("rgba(255, 0, 0, 0.5)")
        if case .rgba(let r, let g, let b, let a) = color {
            #expect(r == 255)
            #expect(g == 0)
            #expect(b == 0)
            #expect(a == 0.5)
        } else {
            Issue.record("Expected RGBA color")
        }
    }

    @Test func `is case insensitive for named colors`() {
        let color = AttributeParser.parseColor("BLUE")
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 0)
            #expect(g == 0)
            #expect(b == 255)
        } else {
            Issue.record("Expected RGB color")
        }
    }
}
