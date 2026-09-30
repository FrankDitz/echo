import Foundation
import Testing

@testable import Echo

@Suite("SwiftData organized journal repository")
struct SwiftDataEchoOrganizedJournalRepositoryTests {
  @Test("Create, fetch, update, order, and delete journals")
  func crudAndOrdering() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let repository = SwiftDataEchoOrganizedJournalRepository(
      modelContainer: try EchoModelContainerFactory.makeInMemory()
    )
    let earlier = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000911"),
      day: EchoDayIdentifier(
        containing: try makeDate("2026-10-05T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: try makeDate("2026-10-05T20:00:00Z"),
      body: "A fictional earlier journal.",
      sourceEntryIDs: [try makeUUID("00000000-0000-0000-0000-000000000912")],
      generator: .deterministicLocal
    )
    var later = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000913"),
      day: EchoDayIdentifier(
        containing: try makeDate("2026-10-06T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: try makeDate("2026-10-06T20:00:00Z"),
      body: "A fictional later journal.",
      sourceEntryIDs: [try makeUUID("00000000-0000-0000-0000-000000000914")],
      generator: .deterministicLocal
    )

    try await repository.create(later)
    try await repository.create(earlier)
    #expect(try await repository.allJournals() == [earlier, later])
    #expect(try await repository.journal(for: earlier.day) == earlier)

    later.regenerate(
      body: "A fictional revised later journal.",
      sourceEntryIDs: later.sourceEntryIDs,
      at: try makeDate("2026-10-06T21:00:00Z")
    )
    try await repository.update(later)
    #expect(try await repository.journal(for: later.day) == later)

    try await repository.delete(id: earlier.id)
    #expect(try await repository.journal(for: earlier.day) == nil)
  }

  @Test("Journal identity and day uniqueness are enforced")
  func uniqueness() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let repository = SwiftDataEchoOrganizedJournalRepository(
      modelContainer: try EchoModelContainerFactory.makeInMemory()
    )
    let day = EchoDayIdentifier(
      containing: try makeDate("2026-10-06T12:00:00Z"),
      calendar: calendar
    )
    let journal = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000915"),
      day: day,
      createdAt: try makeDate("2026-10-06T20:00:00Z"),
      body: "A fictional journal.",
      sourceEntryIDs: [],
      generator: .deterministicLocal
    )
    let duplicateDay = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000916"),
      day: day,
      createdAt: try makeDate("2026-10-06T21:00:00Z"),
      body: "Another fictional journal.",
      sourceEntryIDs: [],
      generator: .deterministicLocal
    )
    try await repository.create(journal)

    await #expect(throws: EchoRepositoryError.duplicateOrganizedJournal(journal.id)) {
      try await repository.create(journal)
    }
    await #expect(throws: EchoRepositoryError.duplicateOrganizedJournalDay(day)) {
      try await repository.create(duplicateDay)
    }
  }

  @Test("A journal persists across container recreation")
  func durablePersistence() async throws {
    let location = try makeDisposableStoreLocation()
    defer { try? FileManager.default.removeItem(at: location.directory) }
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let journal = EchoOrganizedJournal(
      day: EchoDayIdentifier(
        containing: try makeDate("2026-10-06T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: try makeDate("2026-10-06T20:00:00Z"),
      body: "A fictional durable organized journal.",
      sourceEntryIDs: [],
      generator: .deterministicLocal
    )

    do {
      let repository = SwiftDataEchoOrganizedJournalRepository(
        modelContainer: try EchoModelContainerFactory.makePersistent(at: location.store)
      )
      try await repository.create(journal)
    }

    let reopenedRepository = SwiftDataEchoOrganizedJournalRepository(
      modelContainer: try EchoModelContainerFactory.makePersistent(at: location.store)
    )
    #expect(try await reopenedRepository.journal(for: journal.day) == journal)
  }
}
