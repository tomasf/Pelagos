import Foundation
import Nodal

/// Parser for individual SVG attribute values
struct AttributeParser {
    // MARK: - Length Parsing

    static func parseLength(_ string: String?) -> Length? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else {
            return nil
        }

        var value = string
        var unit: Length.Unit = .none

        // Check for unit suffix
        for u in [Length.Unit.percent, .px, .em, .ex, .pt, .pc, .cm, .mm, .in] {
            if value.hasSuffix(u.rawValue) {
                unit = u
                value = String(value.dropLast(u.rawValue.count))
                break
            }
        }

        guard let number = Double(value) else { return nil }
        return Length(number, unit)
    }

    static func parseOptionalLength(_ node: Node, _ name: String) -> Length? {
        parseLength(node[attribute: name])
    }

    // MARK: - Number Parsing

    static func parseDouble(_ string: String?) -> Double? {
        guard let string = string?.trimmingCharacters(in: .whitespaces) else { return nil }
        return Double(string)
    }

    // MARK: - Point List Parsing

    static func parsePoints(_ string: String?) -> [Point]? {
        guard let string = string else { return nil }

        var scanner = PathScanner(string)
        var points: [Point] = []

        while let point = scanner.scanPoint() {
            points.append(point)
        }

        return points.isEmpty ? nil : points
    }

    // MARK: - Color Parsing

    static func parseColor(_ string: String?) -> Color? {
        guard let string = string?.trimmingCharacters(in: .whitespaces).lowercased(), !string.isEmpty else {
            return nil
        }

        if string == "none" {
            return Color.none
        }

        if string == "currentcolor" {
            return .currentColor
        }

        // Named color
        if let namedColor = Color.namedColors[string] {
            return namedColor
        }

        // Hex color
        if string.hasPrefix("#") {
            return parseHexColor(String(string.dropFirst()))
        }

        // RGB/RGBA function
        if string.hasPrefix("rgb(") || string.hasPrefix("rgba(") {
            return parseRGBFunction(string)
        }

        // CSS color() function (e.g. display-p3)
        if string.hasPrefix("color(") {
            return parseColorFunction(string)
        }

        // Treat as named color
        return .named(string)
    }

    private static func parseHexColor(_ hex: String) -> Color? {
        let chars = Array(hex)

        switch chars.count {
        case 3: // #RGB
            guard let r = hexValue(chars[0]),
                  let g = hexValue(chars[1]),
                  let b = hexValue(chars[2]) else { return nil }
            return .rgb(red: UInt8(r * 17), green: UInt8(g * 17), blue: UInt8(b * 17))

        case 6: // #RRGGBB
            guard let r = hexValue(chars[0], chars[1]),
                  let g = hexValue(chars[2], chars[3]),
                  let b = hexValue(chars[4], chars[5]) else { return nil }
            return .rgb(red: UInt8(r), green: UInt8(g), blue: UInt8(b))

        case 8: // #RRGGBBAA
            guard let r = hexValue(chars[0], chars[1]),
                  let g = hexValue(chars[2], chars[3]),
                  let b = hexValue(chars[4], chars[5]),
                  let a = hexValue(chars[6], chars[7]) else { return nil }
            return .rgba(red: UInt8(r), green: UInt8(g), blue: UInt8(b), alpha: Double(a) / 255.0)

        default:
            return nil
        }
    }

    private static func hexValue(_ c: Character) -> Int? {
        Int(String(c), radix: 16)
    }

    private static func hexValue(_ c1: Character, _ c2: Character) -> Int? {
        Int(String([c1, c2]), radix: 16)
    }

    private static func parseRGBFunction(_ string: String) -> Color? {
        let isRGBA = string.hasPrefix("rgba(")
        let inner = string
            .replacingOccurrences(of: isRGBA ? "rgba(" : "rgb(", with: "")
            .replacingOccurrences(of: ")", with: "")

        let components = inner.split(whereSeparator: { $0 == "," || $0 == " " || $0 == "/" })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard components.count >= 3 else { return nil }

        func parseComponent(_ s: String, max: Double = 255) -> Double? {
            if s.hasSuffix("%") {
                guard let v = Double(s.dropLast()) else { return nil }
                return v / 100.0 * max
            }
            return Double(s)
        }

        guard let r = parseComponent(components[0]),
              let g = parseComponent(components[1]),
              let b = parseComponent(components[2]) else { return nil }

        if components.count >= 4 {
            guard let a = parseComponent(components[3], max: 1.0) else { return nil }
            return .rgba(red: UInt8(min(255, max(0, r))), green: UInt8(min(255, max(0, g))), blue: UInt8(min(255, max(0, b))), alpha: a)
        }

        return .rgb(red: UInt8(min(255, max(0, r))), green: UInt8(min(255, max(0, g))), blue: UInt8(min(255, max(0, b))))
    }

    private static func parseColorFunction(_ string: String) -> Color? {
        let inner = string
            .replacingOccurrences(of: "color(", with: "")
            .replacingOccurrences(of: ")", with: "")

        let components = inner.split(whereSeparator: { $0 == "," || $0 == " " || $0 == "/" })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard components.count >= 4 else { return nil }

        let colorSpace = components[0]
        let values = Array(components.dropFirst())

        func parseComponent(_ s: String) -> Double? {
            if s.hasSuffix("%") {
                guard let v = Double(s.dropLast()) else { return nil }
                return v / 100.0
            }
            return Double(s)
        }

        guard colorSpace == "display-p3",
              let r = parseComponent(values[0]),
              let g = parseComponent(values[1]),
              let b = parseComponent(values[2]) else { return nil }

        let alpha = values.count > 3 ? parseComponent(values[3]) : 1.0
        return .p3(red: r, green: g, blue: b, alpha: alpha ?? 1.0)
    }

    // MARK: - Style Parsing

    static func parseStyleAttributes(_ style: String) -> [String: String] {
        var properties: [String: String] = [:]

        let declarations = style.split(separator: ";")
        for declaration in declarations {
            let parts = declaration.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let property = String(parts[0]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            properties[property] = value
        }

        return properties
    }

    // MARK: - Fill Parsing

    static func parseFill(_ string: String?) -> Fill? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else {
            return nil
        }

        if string == "none" {
            return Fill.none
        }

        // URL reference
        if string.hasPrefix("url(") {
            let urlPart = extractURL(from: string)
            if let closeIdx = string.firstIndex(of: ")") {
                let rest = string[string.index(after: closeIdx)...].trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty, let fallback = parseColor(rest) {
                    return .urlWithFallback(urlPart, fallback)
                }
            }
            return .url(urlPart)
        }

        // Color
        if let color = parseColor(string) {
            return .color(color)
        }

        return nil
    }

    private static func extractURL(from string: String) -> String {
        var url = string
        if url.hasPrefix("url(") {
            url = String(url.dropFirst(4))
        }
        if let closeIdx = url.firstIndex(of: ")") {
            url = String(url[..<closeIdx])
        }
        // Remove quotes
        url = url.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        // Remove # prefix for local references
        if url.hasPrefix("#") {
            url = String(url.dropFirst())
        }
        return url
    }

    // MARK: - Transform Parsing

    static func parseTransform(_ string: String?) -> [Transform]? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else {
            return nil
        }

        var transforms: [Transform] = []
        var remaining = string

        while !remaining.isEmpty {
            remaining = remaining.trimmingCharacters(in: .whitespaces)
            guard !remaining.isEmpty else { break }

            // Find function name
            guard let parenIndex = remaining.firstIndex(of: "(") else { break }
            let name = String(remaining[..<parenIndex]).trimmingCharacters(in: .whitespaces)

            guard let closeIndex = remaining.firstIndex(of: ")") else { break }
            let argsString = String(remaining[remaining.index(after: parenIndex)..<closeIndex])
            let args = argsString.split(whereSeparator: { $0 == "," || $0 == " " })
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

            remaining = String(remaining[remaining.index(after: closeIndex)...])

            switch name {
            case "matrix" where args.count >= 6:
                transforms.append(.matrix(a: args[0], b: args[1], c: args[2], d: args[3], e: args[4], f: args[5]))

            case "translate":
                if args.count >= 2 {
                    transforms.append(.translate(x: args[0], y: args[1]))
                } else if args.count >= 1 {
                    transforms.append(.translate(x: args[0], y: 0))
                }

            case "scale":
                if args.count >= 2 {
                    transforms.append(.scale(x: args[0], y: args[1]))
                } else if args.count >= 1 {
                    transforms.append(.scale(x: args[0], y: args[0]))
                }

            case "rotate":
                if args.count >= 3 {
                    transforms.append(.rotate(angle: args[0], cx: args[1], cy: args[2]))
                } else if args.count >= 1 {
                    transforms.append(.rotate(angle: args[0], cx: nil, cy: nil))
                }

            case "skewX" where args.count >= 1:
                transforms.append(.skewX(angle: args[0]))

            case "skewY" where args.count >= 1:
                transforms.append(.skewY(angle: args[0]))

            default:
                break
            }
        }

        return transforms.isEmpty ? nil : transforms
    }

    // MARK: - ViewBox Parsing

    static func parseViewBox(_ string: String?) -> ViewBox? {
        guard let string = string else { return nil }

        let values = string.split(whereSeparator: { $0 == " " || $0 == "," })
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

        guard values.count >= 4 else { return nil }

        return ViewBox(minX: values[0], minY: values[1], width: values[2], height: values[3])
    }

    // MARK: - PreserveAspectRatio Parsing

    static func parsePreserveAspectRatio(_ string: String?) -> PreserveAspectRatio? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else {
            return nil
        }

        let parts = string.split(separator: " ").map { String($0) }
        guard !parts.isEmpty else { return nil }

        let alignmentMap: [String: PreserveAspectRatio.Alignment] = [
            "none": .none,
            "xMinYMin": .xMinYMin,
            "xMidYMin": .xMidYMin,
            "xMaxYMin": .xMaxYMin,
            "xMinYMid": .xMinYMid,
            "xMidYMid": .xMidYMid,
            "xMaxYMid": .xMaxYMid,
            "xMinYMax": .xMinYMax,
            "xMidYMax": .xMidYMax,
            "xMaxYMax": .xMaxYMax
        ]

        guard let alignment = alignmentMap[parts[0]] else { return nil }

        var meetOrSlice: PreserveAspectRatio.MeetOrSlice = .meet
        if parts.count > 1 {
            if parts[1] == "slice" {
                meetOrSlice = .slice
            }
        }

        return PreserveAspectRatio(alignment: alignment, meetOrSlice: meetOrSlice)
    }

    // MARK: - Enum Parsing

    static func parseEnum<T: RawRepresentable>(_ string: String?, type: T.Type) -> T? where T.RawValue == String {
        guard let string = string?.trimmingCharacters(in: .whitespaces) else { return nil }
        return T(rawValue: string)
    }

    // MARK: - URL Reference Parsing

    static func parseURLReference(_ string: String?) -> String? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else {
            return nil
        }

        if string.hasPrefix("url(") {
            return extractURL(from: string)
        }

        return nil
    }

    // MARK: - Dash Array Parsing

    static func parseDashArray(_ string: String?) -> [Length]? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty, string != "none" else {
            return nil
        }

        let values = string.split(whereSeparator: { $0 == "," || $0 == " " })
            .compactMap { parseLength(String($0)) }

        return values.isEmpty ? nil : values
    }

    // MARK: - Length Array Parsing

    static func parseLengthArray(_ string: String?) -> [Length]? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else {
            return nil
        }

        let values = string.split(whereSeparator: { $0 == "," || $0 == " " })
            .compactMap { parseLength(String($0)) }

        return values.isEmpty ? nil : values
    }

    // MARK: - Number Array Parsing

    static func parseDoubleArray(_ string: String?) -> [Double]? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else {
            return nil
        }

        let values = string.split(whereSeparator: { $0 == "," || $0 == " " })
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

        return values.isEmpty ? nil : values
    }
}
