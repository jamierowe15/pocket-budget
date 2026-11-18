import Testing

/// Deliberately broken. This branch only proves CI blocks a failing test; it is never merged.
@Test func ciMustRejectThisBrokenTest() {
    #expect(1 + 1 == 3)
}
