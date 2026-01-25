import Foundation

/// A length value with an optional unit
struct Length: Hashable, Sendable {
    public enum Unit: String, Hashable, Sendable {
        case none = ""
        case px
        case em
        case ex
        case pt
        case pc
        case cm
        case mm
        case `in`
        case percent = "%"
    }

    public var value: Double
    public var unit: Unit

    public init(_ value: Double, _ unit: Unit = .none) {
        self.value = value
        self.unit = unit
    }

    public func resolvedValue(
        dpi: Double = 96,
        fontSize: Double = 16,
        viewport: Double? = nil
    ) -> Double {
        switch unit {
        case .percent:
            return (viewport ?? 0) * value / 100
        case .px, .none:
            return value
        case .in:
            return value * dpi
        case .cm:
            return value * dpi / 2.54
        case .mm:
            return value * dpi / 25.4
        case .pt:
            return value * dpi / 72
        case .pc:
            return value * dpi / 6
        case .em:
            return value * fontSize
        case .ex:
            return value * fontSize * 0.5
        }
    }

    public static let zero = Length(0)

    public static func px(_ value: Double) -> Length { Length(value, .px) }
    public static func em(_ value: Double) -> Length { Length(value, .em) }
    public static func percent(_ value: Double) -> Length { Length(value, .percent) }
}
