import Testing
@testable import Pelagos

@Suite("Pelagos")
struct PelagosTests {
    @Test func `library version is defined`() {
        #expect(!Pelagos.version.isEmpty)
    }
}
