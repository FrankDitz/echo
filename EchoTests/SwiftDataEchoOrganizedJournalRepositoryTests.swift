import Foundation
import SwiftData
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
      title: "A durable fictional title",
      themes: ["Clarity", "Momentum"],
      keyMoments: ["A fictional moment survived the restart."],
      reflectionQuestions: ["What should the fictional next step be?"],
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

  @Test("Version 2 journals and entries migrate without content loss")
  func versionTwoMigration() async throws {
    let location = try makeDisposableStoreLocation()
    defer { try? FileManager.default.removeItem(at: location.directory) }
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let day = EchoDayIdentifier(
      containing: try makeDate("2026-10-06T12:00:00Z"),
      calendar: calendar
    )
    let entry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000917"),
      createdAt: try makeDate("2026-10-06T18:00:00Z"),
      calendar: calendar,
      rawText: "A fictional entry kept through migration.",
      source: .user
    )
    let journalID = try makeUUID("00000000-0000-0000-0000-000000000918")

    do {
      let schema = Schema(versionedSchema: EchoSchemaV2.self)
      let configuration = ModelConfiguration(
        "EchoVersionTwoMigrationTest",
        schema: schema,
        url: location.store,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      let dayEncoder = JSONEncoder()
      dayEncoder.outputFormatting = [.sortedKeys]
      let dayPayload = try dayEncoder.encode(day)
      context.insert(try EchoPersistenceMapper.makeEntryRecord(from: entry))
      context.insert(
        PersistentEchoOrganizedJournal(
          id: journalID,
          dayKey: dayPayload.base64EncodedString(),
          dayPayload: dayPayload,
          createdAt: try makeDate("2026-10-06T20:00:00Z"),
          modifiedAt: try makeDate("2026-10-06T20:00:00Z"),
          body: "A fictional version two journal.",
          sourceEntryIDsPayload: try JSONEncoder().encode([entry.id]),
          generatorRawValue: EchoJournalGenerator.deterministicLocal.rawValue
        )
      )
      try context.save()
    }

    let migratedContainer = try EchoModelContainerFactory.makePersistent(at: location.store)
    let journalRepository = SwiftDataEchoOrganizedJournalRepository(
      modelContainer: migratedContainer
    )
    let entryRepository = SwiftDataEchoEntryRepository(modelContainer: migratedContainer)
    let migratedContext = ModelContext(migratedContainer)
    let legacyRecords = try migratedContext.fetch(
      FetchDescriptor<PersistentEchoOrganizedJournal>()
    )
    let currentRecords = try migratedContext.fetch(
      FetchDescriptor<PersistentEchoOrganizedJournalV3>()
    )
    #expect(legacyRecords.isEmpty, "The migration should retire version 2 journal rows.")
    #expect(currentRecords.count == 1, "The migration should create one version 3 row.")
    let migratedJournal = try #require(await journalRepository.journal(for: day))

    #expect(migratedJournal.id == journalID)
    #expect(migratedJournal.body == "A fictional version two journal.")
    #expect(migratedJournal.title == nil)
    #expect(migratedJournal.themes.isEmpty)
    #expect(try await entryRepository.entry(id: entry.id) == entry)
  }
}

@Suite("SwiftData weekly reflection repository")
struct SwiftDataEchoWeeklyReflectionRepositoryTests {
  @Test("Weekly reflections persist, update, and remain unique by week")
  func persistenceAndUniqueness() async throws {
    let location = try makeDisposableStoreLocation()
    defer { try? FileManager.default.removeItem(at: location.directory) }
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let week = EchoWeekIdentifier(
      containing: try makeDate("2026-10-07T12:00:00Z"),
      calendar: calendar
    )
    let source = try makeUUID("00000000-0000-0000-0000-000000000922")
    var reflection = EchoWeeklyReflection(
      id: try makeUUID("00000000-0000-0000-0000-000000000923"),
      week: week,
      createdAt: try makeDate("2026-10-11T20:00:00Z"),
      body: "A fictional durable weekly reflection.",
      themes: ["Clarity"],
      notableEntryIDs: [source],
      sourceEntryIDs: [source],
      question: "What should continue?",
      generator: .deterministicLocal
    )

    do {
      let repository = SwiftDataEchoWeeklyReflectionRepository(
        modelContainer: try EchoModelContainerFactory.makePersistent(at: location.store)
      )
      try await repository.create(reflection)
      await #expect(throws: EchoRepositoryError.duplicateWeeklyReflection(reflection.id)) {
        try await repository.create(reflection)
      }
      reflection.regenerate(
        body: "A fictional revised weekly reflection.",
        themes: ["Clarity", "Momentum"],
        notableEntryIDs: [source],
        sourceEntryIDs: [source],
        question: "What deserves more room?",
        at: try makeDate("2026-10-11T21:00:00Z")
      )
      try await repository.update(reflection)
    }

    let reopened = SwiftDataEchoWeeklyReflectionRepository(
      modelContainer: try EchoModelContainerFactory.makePersistent(at: location.store)
    )
    #expect(try await reopened.reflection(for: week) == reflection)
    #expect(try await reopened.allReflections() == [reflection])
  }
}

@Suite("SwiftData carry forward repository")
struct SwiftDataEchoCarryForwardRepositoryTests {
  @Test("Carry forwards persist, order, and delete by identity")
  func persistenceOrderingAndDeletion() async throws {
    let location = try makeDisposableStoreLocation()
    defer { try? FileManager.default.removeItem(at: location.directory) }
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let sourceDay = EchoDayIdentifier(
      containing: try makeDate("2026-10-06T12:00:00Z"),
      calendar: calendar
    )
    let firstTargetDay = EchoDayIdentifier(
      containing: try makeDate("2026-10-07T12:00:00Z"),
      calendar: calendar
    )
    let laterTargetDay = EchoDayIdentifier(
      containing: try makeDate("2026-10-08T12:00:00Z"),
      calendar: calendar
    )
    let first = EchoCarryForward(
      id: try makeUUID("00000000-0000-0000-0000-000000000931"),
      text: "What would make tomorrow feel deliberate rather than crowded?",
      sourceKind: .dayReflectionQuestion,
      sourceDay: sourceDay,
      targetDay: firstTargetDay,
      createdAt: try makeDate("2026-10-06T21:00:00Z")
    )
    let later = EchoCarryForward(
      id: try makeUUID("00000000-0000-0000-0000-000000000932"),
      text: "Keep the next useful step small.",
      sourceKind: .dayReflectionKeyMoment,
      sourceDay: sourceDay,
      targetDay: laterTargetDay,
      createdAt: try makeDate("2026-10-07T21:00:00Z")
    )

    do {
      let repository = SwiftDataEchoCarryForwardRepository(
        modelContainer: try EchoModelContainerFactory.makePersistent(at: location.store)
      )
      try await repository.create(first)
      try await repository.create(later)
    }

    let reopened = SwiftDataEchoCarryForwardRepository(
      modelContainer: try EchoModelContainerFactory.makePersistent(at: location.store)
    )
    #expect(try await reopened.carryForward(for: firstTargetDay) == first)
    #expect(try await reopened.allCarryForwards() == [later, first])

    try await reopened.delete(id: first.id)
    #expect(try await reopened.carryForward(for: firstTargetDay) == nil)
  }

  @Test("Only one carry forward can target a day")
  func uniqueness() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let targetDay = EchoDayIdentifier(
      containing: try makeDate("2026-10-07T12:00:00Z"),
      calendar: calendar
    )
    let repository = SwiftDataEchoCarryForwardRepository(
      modelContainer: try EchoModelContainerFactory.makeInMemory()
    )
    let carryForward = EchoCarryForward(
      id: try makeUUID("00000000-0000-0000-0000-000000000933"),
      text: "A fictional thought worth carrying.",
      sourceKind: .entry,
      sourceEntryID: try makeUUID("00000000-0000-0000-0000-000000000934"),
      targetDay: targetDay,
      createdAt: try makeDate("2026-10-06T21:00:00Z")
    )
    let duplicateDay = EchoCarryForward(
      id: try makeUUID("00000000-0000-0000-0000-000000000935"),
      text: "A second fictional thought.",
      sourceKind: .weeklyReflectionQuestion,
      targetDay: targetDay,
      createdAt: try makeDate("2026-10-06T22:00:00Z")
    )

    try await repository.create(carryForward)
    await #expect(throws: EchoRepositoryError.duplicateCarryForward(carryForward.id)) {
      try await repository.create(carryForward)
    }
    await #expect(
      throws: EchoRepositoryError.duplicateCarryForwardTargetDay(targetDay)
    ) {
      try await repository.create(duplicateDay)
    }
    await #expect(
      throws: EchoRepositoryError.carryForwardNotFound(duplicateDay.id)
    ) {
      try await repository.delete(id: duplicateDay.id)
    }
  }

  @Test("Replacing changes tomorrow's thought without creating a duplicate")
  func replacingCarryForward() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoCarryForwardRepository(modelContainer: container)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let targetDate = try makeDate("2026-10-05T12:00:00Z")
    let targetDay = EchoDayIdentifier(containing: targetDate, calendar: calendar)
    let original = EchoCarryForward(
      text: "A fictional original thought.",
      sourceKind: .entry,
      targetDay: targetDay,
      createdAt: try makeDate("2026-10-04T10:00:00Z")
    )
    let replacement = EchoCarryForward(
      text: "A fictional replacement question?",
      sourceKind: .dayReflectionQuestion,
      targetDay: targetDay,
      createdAt: try makeDate("2026-10-04T11:00:00Z")
    )

    try await repository.create(original)
    try await repository.replace(replacement)

    #expect(try await repository.carryForward(for: targetDay) == replacement)
    #expect(try await repository.allCarryForwards() == [replacement])
  }

  @Test("Version five stores migrate and accept carry forwards")
  func versionFiveMigration() async throws {
    let location = try makeDisposableStoreLocation()
    defer { try? FileManager.default.removeItem(at: location.directory) }
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: try makeDate("2026-10-06T18:00:00Z"),
      calendar: calendar,
      rawText: "A fictional entry kept through the carry-forward migration."
    )

    do {
      let schema = Schema(versionedSchema: EchoSchemaV5.self)
      let configuration = ModelConfiguration(
        "EchoVersionFiveMigrationTest",
        schema: schema,
        url: location.store,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      context.insert(try EchoPersistenceMapper.makeEntryRecord(from: entry))
      try context.save()
    }

    let migratedContainer = try EchoModelContainerFactory.makePersistent(at: location.store)
    let entryRepository = SwiftDataEchoEntryRepository(modelContainer: migratedContainer)
    let carryRepository = SwiftDataEchoCarryForwardRepository(
      modelContainer: migratedContainer
    )
    let targetDay = EchoDayIdentifier(
      containing: try makeDate("2026-10-07T12:00:00Z"),
      calendar: calendar
    )
    let carryForward = EchoCarryForward(
      text: entry.rawText,
      sourceKind: .entry,
      sourceDay: entry.day,
      sourceEntryID: entry.id,
      targetDay: targetDay,
      createdAt: try makeDate("2026-10-06T21:00:00Z")
    )
    try await carryRepository.create(carryForward)

    #expect(try await entryRepository.entry(id: entry.id) == entry)
    #expect(try await carryRepository.carryForward(for: targetDay) == carryForward)
  }
}
