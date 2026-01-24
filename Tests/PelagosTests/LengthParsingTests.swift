import Testing
@testable import Pelagos

@Suite("Length Parsing")
struct LengthParsingTests {
    @Test func `parses numbers without units`() {
        let length = AttributeParser.parseLength("42")
        #expect(length?.value == 42)
        #expect(length?.unit == Length.Unit.none)
    }

    @Test func `parses pixel values`() {
        let length = AttributeParser.parseLength("100px")
        #expect(length?.value == 100)
        #expect(length?.unit == .px)
    }

    @Test func `parses percentage values`() {
        let length = AttributeParser.parseLength("50%")
        #expect(length?.value == 50)
        #expect(length?.unit == .percent)
    }

    @Test func `parses em values`() {
        let length = AttributeParser.parseLength("1.5em")
        #expect(length?.value == 1.5)
        #expect(length?.unit == .em)
    }

    @Test func `parses negative values`() {
        let length = AttributeParser.parseLength("-10px")
        #expect(length?.value == -10)
        #expect(length?.unit == .px)
    }

    @Test func `parses decimal values`() {
        let length = AttributeParser.parseLength("3.14159")
        #expect(length?.value == 3.14159)
    }

    @Test func `returns nil for empty string`() {
        let length = AttributeParser.parseLength("")
        #expect(length == nil)
    }

    @Test func `returns nil for nil input`() {
        let length = AttributeParser.parseLength(nil)
        #expect(length == nil)
    }
}
