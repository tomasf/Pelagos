import Testing
@testable import Pelagos

@Suite("Transform Parsing")
struct TransformParsingTests {
    @Test func `parses translate with two arguments`() {
        let transforms = AttributeParser.parseTransform("translate(10, 20)")
        #expect(transforms?.count == 1)
        if case .translate(let x, let y) = transforms?.first {
            #expect(x == 10)
            #expect(y == 20)
        } else {
            Issue.record("Expected translate transform")
        }
    }

    @Test func `parses translate with one argument`() {
        let transforms = AttributeParser.parseTransform("translate(15)")
        #expect(transforms?.count == 1)
        if case .translate(let x, let y) = transforms?.first {
            #expect(x == 15)
            #expect(y == 0)
        } else {
            Issue.record("Expected translate transform")
        }
    }

    @Test func `parses uniform scale`() {
        let transforms = AttributeParser.parseTransform("scale(2)")
        #expect(transforms?.count == 1)
        if case .scale(let x, let y) = transforms?.first {
            #expect(x == 2)
            #expect(y == 2)
        } else {
            Issue.record("Expected scale transform")
        }
    }

    @Test func `parses non-uniform scale`() {
        let transforms = AttributeParser.parseTransform("scale(2, 3)")
        #expect(transforms?.count == 1)
        if case .scale(let x, let y) = transforms?.first {
            #expect(x == 2)
            #expect(y == 3)
        } else {
            Issue.record("Expected scale transform")
        }
    }

    @Test func `parses rotation without center`() {
        let transforms = AttributeParser.parseTransform("rotate(45)")
        #expect(transforms?.count == 1)
        if case .rotate(let angle, let cx, let cy) = transforms?.first {
            #expect(angle == 45)
            #expect(cx == nil)
            #expect(cy == nil)
        } else {
            Issue.record("Expected rotate transform")
        }
    }

    @Test func `parses rotation with center point`() {
        let transforms = AttributeParser.parseTransform("rotate(90, 50, 50)")
        #expect(transforms?.count == 1)
        if case .rotate(let angle, let cx, let cy) = transforms?.first {
            #expect(angle == 90)
            #expect(cx == 50)
            #expect(cy == 50)
        } else {
            Issue.record("Expected rotate transform")
        }
    }

    @Test func `parses skewX`() {
        let transforms = AttributeParser.parseTransform("skewX(30)")
        #expect(transforms?.count == 1)
        if case .skewX(let angle) = transforms?.first {
            #expect(angle == 30)
        } else {
            Issue.record("Expected skewX transform")
        }
    }

    @Test func `parses skewY`() {
        let transforms = AttributeParser.parseTransform("skewY(15)")
        #expect(transforms?.count == 1)
        if case .skewY(let angle) = transforms?.first {
            #expect(angle == 15)
        } else {
            Issue.record("Expected skewY transform")
        }
    }

    @Test func `parses matrix transform`() {
        let transforms = AttributeParser.parseTransform("matrix(1, 0, 0, 1, 10, 20)")
        #expect(transforms?.count == 1)
        if case .matrix(let a, let b, let c, let d, let e, let f) = transforms?.first {
            #expect(a == 1)
            #expect(b == 0)
            #expect(c == 0)
            #expect(d == 1)
            #expect(e == 10)
            #expect(f == 20)
        } else {
            Issue.record("Expected matrix transform")
        }
    }

    @Test func `parses multiple transforms in sequence`() {
        let transforms = AttributeParser.parseTransform("translate(10, 20) rotate(45) scale(2, 3)")
        #expect(transforms?.count == 3)
    }
}
