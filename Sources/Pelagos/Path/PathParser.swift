import Foundation

/// Parser for SVG path data (the `d` attribute)
struct PathParser {
    init() {}

    func parse(_ data: String) throws -> [PathSegment] {
        var scanner = PathScanner(data)
        var segments: [PathSegment] = []

        while let command = scanner.scanCommand() {
            let newSegments = try parseCommand(command, scanner: &scanner)
            segments.append(contentsOf: newSegments)
        }

        return segments
    }

    private func parseCommand(_ command: Character, scanner: inout PathScanner) throws -> [PathSegment] {
        var segments: [PathSegment] = []

        switch command {
        case "M":
            guard let point = scanner.scanPoint() else { throw PathParseError.missingArguments }
            segments.append(.moveTo(point))
            // Subsequent points are implicit lineTo
            while let point = scanner.scanPoint() {
                segments.append(.lineTo(point))
            }

        case "m":
            guard let point = scanner.scanPoint() else { throw PathParseError.missingArguments }
            segments.append(.moveToRelative(point))
            while let point = scanner.scanPoint() {
                segments.append(.lineToRelative(point))
            }

        case "L":
            guard let point = scanner.scanPoint() else { throw PathParseError.missingArguments }
            segments.append(.lineTo(point))
            while let point = scanner.scanPoint() {
                segments.append(.lineTo(point))
            }

        case "l":
            guard let point = scanner.scanPoint() else { throw PathParseError.missingArguments }
            segments.append(.lineToRelative(point))
            while let point = scanner.scanPoint() {
                segments.append(.lineToRelative(point))
            }

        case "H":
            guard let x = scanner.scanNumber() else { throw PathParseError.missingArguments }
            segments.append(.horizontalLineTo(x))
            while let x = scanner.scanNumber() {
                segments.append(.horizontalLineTo(x))
            }

        case "h":
            guard let x = scanner.scanNumber() else { throw PathParseError.missingArguments }
            segments.append(.horizontalLineToRelative(x))
            while let x = scanner.scanNumber() {
                segments.append(.horizontalLineToRelative(x))
            }

        case "V":
            guard let y = scanner.scanNumber() else { throw PathParseError.missingArguments }
            segments.append(.verticalLineTo(y))
            while let y = scanner.scanNumber() {
                segments.append(.verticalLineTo(y))
            }

        case "v":
            guard let y = scanner.scanNumber() else { throw PathParseError.missingArguments }
            segments.append(.verticalLineToRelative(y))
            while let y = scanner.scanNumber() {
                segments.append(.verticalLineToRelative(y))
            }

        case "C":
            while let c1 = scanner.scanPoint(),
                  let c2 = scanner.scanPoint(),
                  let end = scanner.scanPoint() {
                segments.append(.curveTo(control1: c1, control2: c2, end: end))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "c":
            while let c1 = scanner.scanPoint(),
                  let c2 = scanner.scanPoint(),
                  let end = scanner.scanPoint() {
                segments.append(.curveToRelative(control1: c1, control2: c2, end: end))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "S":
            while let c2 = scanner.scanPoint(), let end = scanner.scanPoint() {
                segments.append(.smoothCurveTo(control2: c2, end: end))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "s":
            while let c2 = scanner.scanPoint(), let end = scanner.scanPoint() {
                segments.append(.smoothCurveToRelative(control2: c2, end: end))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "Q":
            while let control = scanner.scanPoint(), let end = scanner.scanPoint() {
                segments.append(.quadraticCurveTo(control: control, end: end))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "q":
            while let control = scanner.scanPoint(), let end = scanner.scanPoint() {
                segments.append(.quadraticCurveToRelative(control: control, end: end))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "T":
            guard let point = scanner.scanPoint() else { throw PathParseError.missingArguments }
            segments.append(.smoothQuadraticCurveTo(point))
            while let point = scanner.scanPoint() {
                segments.append(.smoothQuadraticCurveTo(point))
            }

        case "t":
            guard let point = scanner.scanPoint() else { throw PathParseError.missingArguments }
            segments.append(.smoothQuadraticCurveToRelative(point))
            while let point = scanner.scanPoint() {
                segments.append(.smoothQuadraticCurveToRelative(point))
            }

        case "A":
            while let arc = scanner.scanArcArguments() {
                segments.append(.arcTo(
                    rx: arc.rx,
                    ry: arc.ry,
                    xAxisRotation: arc.xAxisRotation,
                    largeArcFlag: arc.largeArcFlag,
                    sweepFlag: arc.sweepFlag,
                    end: arc.end
                ))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "a":
            while let arc = scanner.scanArcArguments() {
                segments.append(.arcToRelative(
                    rx: arc.rx,
                    ry: arc.ry,
                    xAxisRotation: arc.xAxisRotation,
                    largeArcFlag: arc.largeArcFlag,
                    sweepFlag: arc.sweepFlag,
                    end: arc.end
                ))
            }
            if segments.isEmpty { throw PathParseError.missingArguments }

        case "Z", "z":
            segments.append(.closePath)

        default:
            throw PathParseError.unknownCommand(command)
        }

        return segments
    }
}

enum PathParseError: Error, Equatable {
    case missingArguments
    case unknownCommand(Character)
    case invalidNumber
}

/// Internal scanner for path data
struct PathScanner {
    private var string: String
    private var index: String.Index

    init(_ string: String) {
        self.string = string
        self.index = string.startIndex
    }

    private var isAtEnd: Bool {
        index >= string.endIndex
    }

    private func peek() -> Character? {
        guard !isAtEnd else { return nil }
        return string[index]
    }

    private mutating func advance() {
        guard !isAtEnd else { return }
        index = string.index(after: index)
    }

    mutating func scanCommand() -> Character? {
        skipWhitespaceAndCommas()
        guard let c = peek(), c.isLetter else { return nil }
        advance()
        return c
    }

    mutating func scanNumber() -> Double? {
        skipWhitespaceAndCommas()
        guard !isAtEnd else { return nil }

        let start = index

        // Optional sign
        if let c = peek(), c == "-" || c == "+" {
            advance()
        }

        // Integer part
        while let c = peek(), c.isNumber {
            advance()
        }

        // Decimal part
        if let c = peek(), c == "." {
            advance()
            while let c = peek(), c.isNumber {
                advance()
            }
        }

        // Exponent part
        if let c = peek(), c == "e" || c == "E" {
            advance()
            if let sign = peek(), sign == "-" || sign == "+" {
                advance()
            }
            while let c = peek(), c.isNumber {
                advance()
            }
        }

        let numberString = String(string[start..<index])
        guard !numberString.isEmpty, numberString != "-", numberString != "+", numberString != "." else {
            index = start
            return nil
        }

        return Double(numberString)
    }

    mutating func scanPoint() -> Point? {
        let savedIndex = index
        guard let x = scanNumber(), let y = scanNumber() else {
            index = savedIndex
            return nil
        }
        return Point(x: x, y: y)
    }

    mutating func scanFlag() -> Bool? {
        skipWhitespaceAndCommas()
        guard let c = peek() else { return nil }
        if c == "0" {
            advance()
            return false
        } else if c == "1" {
            advance()
            return true
        }
        return nil
    }

    mutating func scanArcArguments() -> (rx: Double, ry: Double, xAxisRotation: Double, largeArcFlag: Bool, sweepFlag: Bool, end: Point)? {
        let savedIndex = index
        guard let rx = scanNumber(),
              let ry = scanNumber(),
              let xAxisRotation = scanNumber(),
              let largeArcFlag = scanFlag(),
              let sweepFlag = scanFlag(),
              let end = scanPoint() else {
            index = savedIndex
            return nil
        }
        return (rx, ry, xAxisRotation, largeArcFlag, sweepFlag, end)
    }

    private mutating func skipWhitespaceAndCommas() {
        while let c = peek(), c.isWhitespace || c == "," {
            advance()
        }
    }
}
