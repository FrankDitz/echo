import Foundation
import Testing

@testable import Echo

@MainActor
@Suite("Today entry workflow")
struct TodayViewModelTests {
  @Test("Loading requests the current calendar day")
  func loadingCurrentDay() async throws {
    let date = try makeDate("2026-10-03T12:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: try makeDate("2026-10-03T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional morning note."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { date }
    )

    await viewModel.load()

    #expect(viewModel.entries == [entry])
    #expect(viewModel.displayedDate == date)
    #expect(viewModel.failure == nil)
    #expect(
      await repository.lastRequestedDay()
        == EchoDayIdentifier(containing: date, calendar: calendar)
    )
  }

  @Test("Creating preserves the writing and reports a saved state")
  func creatingEntry() async throws {
    let date = try makeDate("2026-10-03T15:30:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let repository = TodayEntryRepositoryStub()
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { date }
    )
    let rawText = "  A fictional note with intentional spacing.  "

    let created = await viewModel.createEntry(rawText: rawText)

    let stored = try #require(await repository.allEntries().first)
    #expect(created)
    #expect(stored.rawText == rawText)
    #expect(stored.createdAt == date)
    #expect(stored.modifiedAt == date)
    #expect(viewModel.entries == [stored])
    #expect(viewModel.saveState == .saved)
  }

  @Test("Creating can mark an entry important in the same capture workflow")
  func creatingImportantEntry() async throws {
    let date = try makeDate("2026-10-03T15:30:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entries = TodayEntryRepositoryStub()
    let highlights = TodayHighlightRepositoryStub(highlights: [])
    let viewModel = TodayViewModel(
      repository: entries,
      highlightRepository: highlights,
      calendar: calendar,
      now: { date }
    )

    let created = await viewModel.createEntry(
      rawText: "A fictional thought worth remembering.",
      markImportant: true
    )

    let entry = try #require(await entries.allEntries().first)
    let highlight = try #require(await highlights.highlight(for: .entry(entry.id)))
    #expect(created)
    #expect(highlight.target == .entry(entry.id))
    #expect(highlight.createdAt == date)
    #expect(viewModel.saveState == .saved)
    #expect(viewModel.failure == nil)
  }

  @Test("Blank writing is not persisted")
  func rejectingBlankEntry() async {
    let repository = TodayEntryRepositoryStub()
    let viewModel = TodayViewModel(repository: repository)

    let created = await viewModel.createEntry(rawText: " \n\t ")

    #expect(!created)
    #expect(await repository.allEntries().isEmpty)
    #expect(viewModel.saveState == .idle)
  }

  @Test("Editing preserves creation time and advances modification time")
  func editingEntry() async throws {
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let modifiedAt = try makeDate("2026-10-03T11:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional first draft."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { modifiedAt }
    )
    await viewModel.load()

    let updated = await viewModel.updateEntry(
      id: entry.id,
      rawText: "A fictional revised draft."
    )

    let stored = try #require(await repository.entry(id: entry.id))
    #expect(updated)
    #expect(stored.createdAt == createdAt)
    #expect(stored.modifiedAt == modifiedAt)
    #expect(stored.rawText == "A fictional revised draft.")
    #expect(viewModel.saveState == .saved)
  }

  @Test("Deleting removes an entry only after persistence succeeds")
  func deletingEntry() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional disposable note."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { createdAt }
    )
    await viewModel.load()

    let deleted = await viewModel.deleteEntry(id: entry.id)

    #expect(deleted)
    #expect(viewModel.entries.isEmpty)
    #expect(await repository.allEntries().isEmpty)
  }

  @Test("Persistence failures retain the current entry list")
  func persistenceFailure() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional retained note."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { createdAt }
    )
    await viewModel.load()
    await repository.setFailure(.delete)

    let deleted = await viewModel.deleteEntry(id: entry.id)

    #expect(!deleted)
    #expect(viewModel.entries == [entry])
    #expect(viewModel.failure == .deleteEntry)
  }

  @Test("Saving assisted text never replaces the original writing")
  func savingAssistedText() async throws {
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let assistedAt = try makeDate("2026-10-03T12:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "fictional original wording"
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { assistedAt }
    )
    await viewModel.load()

    let saved = await viewModel.saveAssistedText(
      entryID: entry.id,
      text: "Fictional original wording."
    )

    let stored = try #require(await repository.entry(id: entry.id))
    #expect(saved)
    #expect(stored.rawText == "fictional original wording")
    #expect(stored.polishedText == "Fictional original wording.")
    #expect(stored.modifiedAt == assistedAt)
    #expect(viewModel.entries.first == stored)
  }

  @Test("Assisted text is published only after persistence succeeds")
  func assistedTextPersistenceFailure() async throws {
    let createdAt = try makeDate("2026-10-03T09:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entry = EchoEntry(
      createdAt: createdAt,
      calendar: calendar,
      rawText: "A fictional unchanged note."
    )
    let repository = TodayEntryRepositoryStub(entries: [entry])
    let viewModel = TodayViewModel(
      repository: repository,
      calendar: calendar,
      now: { createdAt }
    )
    await viewModel.load()
    await repository.setFailure(.update)

    let saved = await viewModel.saveAssistedText(
      entryID: entry.id,
      text: "A fictional assisted note."
    )

    #expect(!saved)
    #expect(viewModel.entries == [entry])
    #expect(viewModel.failure == .updateEntry)
  }

  @Test("Loading resurfaces private memories without altering entries")
  func loadingMemorySignals() async throws {
    let now = try makeDate("2026-10-03T12:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let onThisDay = EchoEntry(
      createdAt: try makeDate("2025-10-03T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional memory from this date."
    )
    let unfinished = EchoEntry(
      createdAt: try makeDate("2026-10-01T09:00:00Z"),
      calendar: calendar,
      rawText: "Still thinking about a fictional next step."
    )
    let saved = EchoEntry(
      createdAt: try makeDate("2026-09-30T09:00:00Z"),
      calendar: calendar,
      rawText: "A fictional saved memory."
    )
    let repository = TodayEntryRepositoryStub(entries: [saved, unfinished, onThisDay])
    let highlightRepository = TodayHighlightRepositoryStub(
      highlights: [EchoHighlight(target: .entry(saved.id), createdAt: saved.createdAt)]
    )
    let viewModel = TodayViewModel(
      repository: repository,
      highlightRepository: highlightRepository,
      calendar: calendar,
      now: { now }
    )

    await viewModel.load()

    #expect(viewModel.memories.onThisDay == [onThisDay])
    #expect(viewModel.memories.unfinished == [unfinished])
    #expect(viewModel.memories.saved == [saved])
    #expect(await repository.allEntries().count == 3)
  }

  @Test("Voice capture saves, transcribes, and plays a private entry")
  func voiceCaptureWorkflow() async throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("EchoVoiceCaptureTests-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let entries = TodayEntryRepositoryStub()
    let attachments = VoiceAttachmentRepositoryStub()
    let service = VoiceCaptureServiceStub(transcript: "A fictional spoken memory.")
    let timestamp = try makeDate("2026-10-05T12:00:00Z")
    let capturePipeline = EchoEntryCapturePipeline(
      repository: entries,
      aiService: DeterministicLocalAIService(),
      calendar: calendar,
      now: { timestamp },
      processorIdentifier: "echo.test.local"
    )
    let viewModel = VoiceCaptureViewModel(
      entryRepository: entries,
      attachmentRepository: attachments,
      fileStore: EchoVoiceFileStore(rootDirectory: directory),
      service: service,
      capturePipeline: capturePipeline,
      calendar: calendar,
      now: { timestamp }
    )

    await viewModel.start()
    #expect(viewModel.state == .recording)
    let captured = try #require(await viewModel.stopAndSave())
    #expect(captured.refinementStatus == .processing)
    let entry = try #require(await viewModel.awaitPendingRefinement())
    let attachment = try #require(await attachments.attachment(for: entry.id))

    #expect(entry.type == .voice)
    #expect(entry.originalText == "A fictional spoken memory.")
    #expect(entry.rawText == "A fictional spoken memory.")
    #expect(entry.refinementStatus == .refined)
    #expect(attachment.transcript == "A fictional spoken memory.")
    #expect(viewModel.state == .ready)
    await viewModel.play(entryID: entry.id)
    #expect(viewModel.state == .ready)
    #expect(viewModel.statusMessage == "Finished playing the private recording.")
    #expect(service.playedURL?.lastPathComponent == attachment.relativeFileName)
  }

  @Test("Denied microphone permission creates no entry or file")
  func deniedVoicePermission() async throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("EchoDeniedVoiceTests-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let entries = TodayEntryRepositoryStub()
    let viewModel = VoiceCaptureViewModel(
      entryRepository: entries,
      attachmentRepository: VoiceAttachmentRepositoryStub(),
      fileStore: EchoVoiceFileStore(rootDirectory: directory),
      service: VoiceCaptureServiceStub(isPermissionGranted: false)
    )

    await viewModel.start()

    #expect(viewModel.state == .permissionDenied)
    #expect(await entries.allEntries().isEmpty)
    #expect(!FileManager.default.fileExists(atPath: directory.path))
  }

  @Test("Carry forward replaces tomorrow's thought and preserves its source")
  func carryingReflectionToTomorrow() async throws {
    let now = try makeDate("2026-10-03T12:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let repository = CarryForwardRepositoryStub()
    let viewModel = CarryForwardViewModel(
      repository: repository,
      calendar: calendar,
      now: { now }
    )
    let sourceDay = EchoDayIdentifier(containing: now, calendar: calendar)

    let saved = await viewModel.carryToTomorrow(
      text: "  What would make this easier to begin?  ",
      sourceKind: .dayReflectionQuestion,
      sourceDay: sourceDay
    )

    let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: now))
    let stored = try #require(
      await repository.carryForward(
        for: EchoDayIdentifier(containing: tomorrow, calendar: calendar)
      )
    )
    #expect(saved)
    #expect(stored.text == "What would make this easier to begin?")
    #expect(stored.sourceKind == .dayReflectionQuestion)
    #expect(stored.sourceDay == sourceDay)
    #expect(viewModel.actionState == .saved)
  }

  @Test("Today loads and releases a carried thought without touching its source")
  func loadingAndReleasingCarryForward() async throws {
    let now = try makeDate("2026-10-04T12:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let item = EchoCarryForward(
      text: "A fictional thought worth returning to.",
      sourceKind: .entry,
      sourceEntryID: UUID(),
      targetDay: EchoDayIdentifier(containing: now, calendar: calendar),
      createdAt: try makeDate("2026-10-03T20:00:00Z")
    )
    let repository = CarryForwardRepositoryStub(items: [item])
    let viewModel = CarryForwardViewModel(
      repository: repository,
      calendar: calendar,
      now: { now }
    )

    await viewModel.loadToday()
    #expect(viewModel.todayItem == item)

    let released = await viewModel.releaseToday()
    #expect(released)
    #expect(viewModel.todayItem == nil)
    #expect(await repository.allCarryForwards().isEmpty)
  }
}

private actor TodayEntryRepositoryStub: EchoEntryRepository {
  enum Operation {
    case create
    case update
    case delete
  }

  private var entriesByID: [UUID: EchoEntry]
  private var failure: Operation?
  private var requestedDay: EchoDayIdentifier?

  init(entries: [EchoEntry] = []) {
    entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
  }

  func setFailure(_ operation: Operation?) {
    failure = operation
  }

  func lastRequestedDay() -> EchoDayIdentifier? {
    requestedDay
  }

  func create(_ entry: EchoEntry) throws {
    if failure == .create { throw StubError.requestedFailure }
    entriesByID[entry.id] = entry
  }

  func entry(id: UUID) -> EchoEntry? {
    entriesByID[id]
  }

  func entries(for day: EchoDayIdentifier) -> [EchoEntry] {
    requestedDay = day
    return EchoEntryOrdering.chronological(
      entriesByID.values.filter { $0.day == day }
    )
  }

  func allEntries() -> [EchoEntry] {
    EchoEntryOrdering.chronological(Array(entriesByID.values))
  }

  func update(_ entry: EchoEntry) throws {
    if failure == .update { throw StubError.requestedFailure }
    entriesByID[entry.id] = entry
  }

  func delete(id: UUID) throws {
    if failure == .delete { throw StubError.requestedFailure }
    entriesByID[id] = nil
  }

  private enum StubError: Error {
    case requestedFailure
  }
}

private actor TodayHighlightRepositoryStub: EchoHighlightRepository {
  private var highlights: [EchoHighlight]

  init(highlights: [EchoHighlight]) {
    self.highlights = highlights
  }

  func create(_ highlight: EchoHighlight) {
    highlights.append(highlight)
  }

  func highlight(for target: EchoHighlightTarget) -> EchoHighlight? {
    highlights.first { $0.target == target }
  }

  func allHighlights() -> [EchoHighlight] {
    highlights
  }

  func delete(id: UUID) {
    highlights.removeAll { $0.id == id }
  }
}

private actor CarryForwardRepositoryStub: EchoCarryForwardRepository {
  private var itemsByTargetDay: [EchoDayIdentifier: EchoCarryForward]

  init(items: [EchoCarryForward] = []) {
    itemsByTargetDay = Dictionary(uniqueKeysWithValues: items.map { ($0.targetDay, $0) })
  }

  func create(_ carryForward: EchoCarryForward) {
    itemsByTargetDay[carryForward.targetDay] = carryForward
  }

  func replace(_ carryForward: EchoCarryForward) {
    itemsByTargetDay[carryForward.targetDay] = carryForward
  }

  func carryForward(for targetDay: EchoDayIdentifier) -> EchoCarryForward? {
    itemsByTargetDay[targetDay]
  }

  func allCarryForwards() -> [EchoCarryForward] {
    Array(itemsByTargetDay.values)
  }

  func delete(id: UUID) {
    itemsByTargetDay = itemsByTargetDay.filter { $0.value.id != id }
  }
}

private actor VoiceAttachmentRepositoryStub: EchoVoiceAttachmentRepository {
  private var attachments: [UUID: EchoVoiceAttachment] = [:]

  func create(_ attachment: EchoVoiceAttachment) {
    attachments[attachment.entryID] = attachment
  }

  func attachment(for entryID: UUID) -> EchoVoiceAttachment? {
    attachments[entryID]
  }

  func allAttachments() -> [EchoVoiceAttachment] {
    Array(attachments.values)
  }

  func update(_ attachment: EchoVoiceAttachment) {
    attachments[attachment.entryID] = attachment
  }

  func delete(id: UUID) {
    attachments = attachments.filter { $0.value.id != id }
  }
}

@MainActor
private final class VoiceCaptureServiceStub: EchoVoiceCaptureService {
  let isPermissionGranted: Bool
  let transcript: String
  private(set) var recordingURL: URL?
  private(set) var playedURL: URL?

  init(isPermissionGranted: Bool = true, transcript: String = "") {
    self.isPermissionGranted = isPermissionGranted
    self.transcript = transcript
  }

  func requestRecordingPermission() async -> Bool { isPermissionGranted }

  func startRecording(to url: URL) throws {
    recordingURL = url
    try Data("fictional recorded audio".utf8).write(to: url, options: .atomic)
  }

  func stopRecording() throws -> TimeInterval { 8.25 }

  func play(url: URL) throws -> TimeInterval {
    playedURL = url
    return 0
  }

  func transcribeOnDevice(url: URL) async throws -> String { transcript }
}
