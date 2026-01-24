import Foundation

/// The stroke-linejoin attribute value
public enum LineJoin: String, Hashable, Sendable {
    case miter
    case round
    case bevel
    case miterClip = "miter-clip"
    case arcs
}
