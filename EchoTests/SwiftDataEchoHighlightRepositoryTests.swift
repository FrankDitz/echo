import Foundation
import Testing

@testable import Echo

@Suite("SwiftData highlight repository")
struct SwiftDataEchoHighlightRepositoryTests {
  @Test("Create, fetch, order, and delete highlights")
  func crudAndOrdering() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoHighlightRepository(modelContainer: container)
    let first = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000501"),
      target: .entry(try makeUUID("00000000-0000-0000-0000-000000000502")),
      createdAt: try makeDate("2026-10-01T09:00:00Z")
    )
    let second = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000503"),
      target: .entry(try makeUUID("00000000-0000-0000-0000-000000000504")),
      createdAt: try makeDate("2026-10-01T10:00:00Z")
    )

    try await repository.create(second)
    try await repository.create(first)

    #expect(try await repository.highlight(for: first.target) == first)
    #expect(try await repository.allHighlights() == [first, second])

    try await repository.delete(id: first.id)
    #expect(try await repository.highlight(for: first.target) == nil)
  }

  @Test("Highlight identity and target uniqueness are enforced")
  func uniqueness() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoHighlightRepository(modelContainer: container)
    let id = try makeUUID("00000000-0000-0000-0000-000000000505")
    let target = EchoHighlightTarget.entry(
      try makeUUID("00000000-0000-0000-0000-000000000506")
    )
    let highlight = EchoHighlight(
      id: id,
      target: target,
      createdAt: try makeDate("2026-10-01T09:00:00Z")
    )
    let duplicateTarget = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000507"),
      target: target,
      createdAt: try makeDate("2026-10-01T10:00:00Z")
    )

    try await repository.create(highlight)

    await #expect(throws: EchoRepositoryError.duplicateHighlight(id)) {
      try await repository.create(highlight)
    }
    await #expect(throws: EchoRepositoryError.duplicateHighlightTarget(target)) {
      try await repository.create(duplicateTarget)
    }
  }
}
