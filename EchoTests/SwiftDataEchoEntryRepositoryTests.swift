import Foundation
import Testing

@testable import Echo

@Suite("SwiftData entry repository")
struct SwiftDataEchoEntryRepositoryTests {
  @Test("Create, fetch, update, and delete an entry")
  func crud() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoEntryRepository(modelContainer: container)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let id = try makeUUID("00000000-0000-0000-0000-000000000401")
    var entry = EchoEntry(
      id: id,
      createdAt: try makeDate("2026-10-01T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional persistence draft."
    )

    try await repository.create(entry)
    #expect(try await repository.entry(id: id) == entry)

    entry.editRawText(
      "A fictional persistence revision.",
      at: try makeDate("2026-10-01T10:30:00Z")
    )
    try await repository.update(entry)
    #expect(try await repository.entry(id: id) == entry)

    try await repository.delete(id: id)
    #expect(try await repository.entry(id: id) == nil)
  }

  @Test("Day queries and all-entry queries are chronological")
  func queriesAreChronological() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoEntryRepository(modelContainer: container)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let first = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000402"),
      createdAt: try makeDate("2026-10-01T08:00:00Z"),
      calendar: calendar,
      rawText: "Fictional early entry."
    )
    let second = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000403"),
      createdAt: try makeDate("2026-10-01T18:00:00Z"),
      calendar: calendar,
      rawText: "Fictional later entry."
    )
    let nextDay = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000404"),
      createdAt: try makeDate("2026-10-02T07:00:00Z"),
      calendar: calendar,
      rawText: "Fictional next-day entry."
    )

    try await repository.create(nextDay)
    try await repository.create(second)
    try await repository.create(first)

    #expect(try await repository.entries(for: first.day) == [first, second])
    #expect(try await repository.allEntries() == [first, second, nextDay])
  }

  @Test("Duplicate and missing identities produce domain repository errors")
  func identityErrors() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoEntryRepository(modelContainer: container)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let id = try makeUUID("00000000-0000-0000-0000-000000000405")
    let missingID = try makeUUID("00000000-0000-0000-0000-000000000406")
    let entry = EchoEntry(
      id: id,
      createdAt: try makeDate("2026-10-01T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional duplicate check."
    )

    try await repository.create(entry)

    await #expect(throws: EchoRepositoryError.duplicateEntry(id)) {
      try await repository.create(entry)
    }
    await #expect(throws: EchoRepositoryError.entryNotFound(missingID)) {
      try await repository.delete(id: missingID)
    }
  }

  @Test("Search is private, normalized, multi-term, and newest first")
  func search() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoEntryRepository(modelContainer: container)
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let older = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000408"),
      createdAt: try makeDate("2026-10-01T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional café visit beside the quiet river."
    )
    var newer = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000409"),
      createdAt: try makeDate("2026-10-02T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional morning beside the river."
    )
    newer.setPolishedText(
      "A calm fictional morning beside the river.",
      at: try makeDate("2026-10-02T09:05:00Z")
    )
    let unrelated = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000410"),
      createdAt: try makeDate("2026-10-03T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional train crossed the city."
    )

    try await repository.create(older)
    try await repository.create(newer)
    try await repository.create(unrelated)

    #expect(
      try await repository.searchEntries(
        matching: EchoEntrySearchQuery("FICTIONAL river")
      ) == [newer, older]
    )
    #expect(
      try await repository.searchEntries(
        matching: EchoEntrySearchQuery("CAFE")
      ) == [older]
    )
    #expect(
      try await repository.searchEntries(
        matching: EchoEntrySearchQuery("calm morning")
      ) == [newer]
    )
    #expect(
      try await repository.searchEntries(
        matching: EchoEntrySearchQuery("   ")
      ).isEmpty
    )
  }

  @Test("An entry survives recreating the persistent container")
  func persistsAcrossContainerRecreation() async throws {
    let location = try makeDisposableStoreLocation()
    defer { try? FileManager.default.removeItem(at: location.directory) }

    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000407"),
      createdAt: try makeDate("2026-10-01T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional durable entry."
    )

    try await persist(entry, at: location.store)
    let fetched = try await fetchEntry(id: entry.id, from: location.store)

    #expect(fetched == entry)
    #expect(
      location.store.standardizedFileURL.path.hasPrefix(
        FileManager.default.temporaryDirectory.standardizedFileURL.path
      )
    )
    #expect(
      !location.store.standardizedFileURL.path.hasPrefix(repositoryRoot().path)
    )
  }

  private func persist(_ entry: EchoEntry, at storeURL: URL) async throws {
    let container = try EchoModelContainerFactory.makePersistent(at: storeURL)
    let repository = SwiftDataEchoEntryRepository(modelContainer: container)
    try await repository.create(entry)
  }

  private func fetchEntry(id: UUID, from storeURL: URL) async throws -> EchoEntry? {
    let container = try EchoModelContainerFactory.makePersistent(at: storeURL)
    let repository = SwiftDataEchoEntryRepository(modelContainer: container)
    return try await repository.entry(id: id)
  }
}

@Suite("Voice attachment persistence and files")
struct SwiftDataEchoVoiceAttachmentRepositoryTests {
  @Test("Attachment lifecycle persists metadata and removes its private file")
  func lifecycle() async throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let repository = SwiftDataEchoVoiceAttachmentRepository(modelContainer: container)
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("EchoVoiceTests-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let fileStore = EchoVoiceFileStore(rootDirectory: directory)
    let attachmentID = try makeUUID("00000000-0000-0000-0000-000000000491")
    let entryID = try makeUUID("00000000-0000-0000-0000-000000000492")
    let fileURL = try fileStore.destinationURL(for: attachmentID)
    try Data("fictional audio bytes".utf8).write(to: fileURL, options: .atomic)
    var attachment = EchoVoiceAttachment(
      id: attachmentID,
      entryID: entryID,
      createdAt: try makeDate("2026-10-05T12:00:00Z"),
      relativeFileName: fileURL.lastPathComponent,
      duration: 12.5
    )

    try await repository.create(attachment)
    #expect(try await repository.attachment(for: entryID) == attachment)
    attachment.setTranscript("A fictional local transcript.")
    try await repository.update(attachment)
    #expect(try await repository.attachment(for: entryID) == attachment)
    #expect(FileManager.default.fileExists(atPath: fileURL.path))
    #expect(!fileURL.standardizedFileURL.path.hasPrefix(repositoryRoot().path))

    let lifecycle = EchoVoiceAttachmentLifecycle(repository: repository, fileStore: fileStore)
    try await lifecycle.removeAttachment(for: entryID)

    #expect(try await repository.attachment(for: entryID) == nil)
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
  }

  @Test("File store rejects paths that escape its private directory")
  func pathValidation() throws {
    let store = EchoVoiceFileStore(rootDirectory: FileManager.default.temporaryDirectory)
    let attachment = EchoVoiceAttachment(
      entryID: UUID(),
      createdAt: Date(timeIntervalSinceReferenceDate: 0),
      relativeFileName: "../escaped.m4a",
      duration: 1
    )

    #expect(throws: EchoVoiceFileStoreError.invalidFileName) {
      try store.url(for: attachment)
    }
  }
}
