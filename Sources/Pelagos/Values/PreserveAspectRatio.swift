import Foundation

/// The preserveAspectRatio attribute value
public struct PreserveAspectRatio: Hashable, Sendable {
    public enum Alignment: String, Hashable, Sendable {
        case none
        case xMinYMin
        case xMidYMin
        case xMaxYMin
        case xMinYMid
        case xMidYMid
        case xMaxYMid
        case xMinYMax
        case xMidYMax
        case xMaxYMax
    }

    public enum MeetOrSlice: String, Hashable, Sendable {
        case meet
        case slice
    }

    public var alignment: Alignment
    public var meetOrSlice: MeetOrSlice

    public init(alignment: Alignment = .xMidYMid, meetOrSlice: MeetOrSlice = .meet) {
        self.alignment = alignment
        self.meetOrSlice = meetOrSlice
    }

    public static let `default` = PreserveAspectRatio()
}
