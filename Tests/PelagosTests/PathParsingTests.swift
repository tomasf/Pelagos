import Testing
@testable import Pelagos

@Suite("Path Parsing")
struct PathParsingTests {
    @Test func `parses absolute moveTo command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 10 20")
        #expect(segments.count == 1)
        if case .moveTo(let point) = segments.first {
            #expect(point.x == 10)
            #expect(point.y == 20)
        } else {
            Issue.record("Expected moveTo")
        }
    }

    @Test func `parses relative moveTo command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("m 5 10")
        #expect(segments.count == 1)
        if case .moveToRelative(let point) = segments.first {
            #expect(point.x == 5)
            #expect(point.y == 10)
        } else {
            Issue.record("Expected moveToRelative")
        }
    }

    @Test func `parses absolute lineTo command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 L 100 200")
        #expect(segments.count == 2)
        if case .lineTo(let point) = segments[1] {
            #expect(point.x == 100)
            #expect(point.y == 200)
        } else {
            Issue.record("Expected lineTo")
        }
    }

    @Test func `parses horizontal line command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 H 50")
        #expect(segments.count == 2)
        if case .horizontalLineTo(let x) = segments[1] {
            #expect(x == 50)
        } else {
            Issue.record("Expected horizontalLineTo")
        }
    }

    @Test func `parses vertical line command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 V 75")
        #expect(segments.count == 2)
        if case .verticalLineTo(let y) = segments[1] {
            #expect(y == 75)
        } else {
            Issue.record("Expected verticalLineTo")
        }
    }

    @Test func `parses cubic bezier curve command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 C 10 20 30 40 50 60")
        #expect(segments.count == 2)
        if case .curveTo(let c1, let c2, let end) = segments[1] {
            #expect(c1.x == 10)
            #expect(c1.y == 20)
            #expect(c2.x == 30)
            #expect(c2.y == 40)
            #expect(end.x == 50)
            #expect(end.y == 60)
        } else {
            Issue.record("Expected curveTo")
        }
    }

    @Test func `parses smooth cubic bezier command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 S 30 40 50 60")
        #expect(segments.count == 2)
        if case .smoothCurveTo(let c2, let end) = segments[1] {
            #expect(c2.x == 30)
            #expect(c2.y == 40)
            #expect(end.x == 50)
            #expect(end.y == 60)
        } else {
            Issue.record("Expected smoothCurveTo")
        }
    }

    @Test func `parses quadratic bezier command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 Q 25 50 50 0")
        #expect(segments.count == 2)
        if case .quadraticCurveTo(let control, let end) = segments[1] {
            #expect(control.x == 25)
            #expect(control.y == 50)
            #expect(end.x == 50)
            #expect(end.y == 0)
        } else {
            Issue.record("Expected quadraticCurveTo")
        }
    }

    @Test func `parses arc command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 A 5 5 0 0 1 10 10")
        #expect(segments.count == 2)
        if case .arcTo(let rx, let ry, let xRot, let large, let sweep, let end) = segments[1] {
            #expect(rx == 5)
            #expect(ry == 5)
            #expect(xRot == 0)
            #expect(large == false)
            #expect(sweep == true)
            #expect(end.x == 10)
            #expect(end.y == 10)
        } else {
            Issue.record("Expected arcTo")
        }
    }

    @Test func `parses arc with large arc flag set`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 A 10 10 0 1 0 20 20")
        if case .arcTo(_, _, _, let large, let sweep, _) = segments[1] {
            #expect(large == true)
            #expect(sweep == false)
        } else {
            Issue.record("Expected arcTo")
        }
    }

    @Test func `parses close path command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 L 10 10 Z")
        #expect(segments.count == 3)
        if case .closePath = segments[2] {
            // Success
        } else {
            Issue.record("Expected closePath")
        }
    }

    @Test func `parses lowercase close path command`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 L 10 10 z")
        #expect(segments.count == 3)
        if case .closePath = segments[2] {
            // Success
        } else {
            Issue.record("Expected closePath")
        }
    }

    @Test func `parses path without spaces between commands`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M0,0L10,10Z")
        #expect(segments.count == 3)
    }

    @Test func `treats implicit lineTo after moveTo`() throws {
        let parser = PathParser()
        let segments = try parser.parse("M 0 0 10 10 20 20")
        #expect(segments.count == 3)
        if case .lineTo(_) = segments[1] {
            // Success
        } else {
            Issue.record("Expected implicit lineTo")
        }
    }
}
