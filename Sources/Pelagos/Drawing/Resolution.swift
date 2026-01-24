import Foundation

public struct DrawingBounds: Sendable {
    public var minX: Double
    public var minY: Double
    public var width: Double
    public var height: Double

    public var maxX: Double { minX + width }
    public var maxY: Double { minY + height }

    public init(minX: Double, minY: Double, width: Double, height: Double) {
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
    }
}

public enum PatternAxis: Sendable {
    case x
    case y
}

public func resolveGradientCoordinate(
    _ length: Length?,
    bounds: DrawingBounds,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        return bounds.minX + bounds.width * fraction
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}

public func resolveGradientRadius(
    _ length: Length?,
    bounds: DrawingBounds,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        let scale = max(bounds.width, bounds.height)
        return scale * fraction
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}

public func resolvePatternPosition(
    _ length: Length?,
    bounds: DrawingBounds,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double,
    axis: PatternAxis
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        switch axis {
        case .x:
            return bounds.minX + bounds.width * fraction
        case .y:
            return bounds.minY + bounds.height * fraction
        }
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}

public func resolvePatternSize(
    _ length: Length?,
    bounds: DrawingBounds,
    viewRef: Double,
    units: GradientUnits,
    defaultValue: Double,
    axis: PatternAxis
) -> Double {
    let value = length?.value ?? defaultValue
    switch units {
    case .objectBoundingBox:
        let fraction = length?.unit == .percent ? value / 100 : value
        let size = axis == .x ? bounds.width : bounds.height
        return size * fraction
    case .userSpaceOnUse:
        if length?.unit == .percent {
            return viewRef * (value / 100)
        }
        return length?.resolvedValue() ?? defaultValue
    }
}
