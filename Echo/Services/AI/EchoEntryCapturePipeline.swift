import Foundation

protocol EchoEntryCapturing: Sendable {
  func preserve(
    _ text: String,
    id: UUID,
    createdAt: Date,
    type: EchoEntryType,
    source: EchoEntrySource
  ) async throws -> EchoEntry
  func replaceOriginalText(_ text: String, for entry: EchoEntry) async throws -> EchoEntry
  func refine(_ entry: EchoEntry) async -> EchoEntry
}

struct EchoEntryCapturePipeline: EchoEntryCapturing {
  private let repository: any EchoEntryRepository
  private let aiService: any EchoAIService
  private let calendar: Calendar
  private let now: @Sendable () -> Date
  private let processorIdentifier: String
  private let modelIdentifier: String?

  init(
    repository: any EchoEntryRepository,
    aiService: any EchoAIService,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping @Sendable () -> Date = Date.init,
    processorIdentifier: String = "echo.deterministic-local",
    modelIdentifier: String? = nil
  ) {
    self.repository = repository
    self.aiService = aiService
    self.calendar = calendar
    self.now = now
    self.processorIdentifier = processorIdentifier
    self.modelIdentifier = modelIdentifier
  }

  func preserve(
    _ text: String,
    id: UUID = UUID(),
    createdAt: Date,
    type: EchoEntryType = .text,
    source: EchoEntrySource = .user
  ) async throws -> EchoEntry {
    let entry = EchoEntry(
      id: id,
      createdAt: createdAt,
      calendar: calendar,
      rawText: text,
      type: type,
      source: source
    )
    try await repository.create(entry)
    return entry
  }

  func replaceOriginalText(_ text: String, for entry: EchoEntry) async throws -> EchoEntry {
    let timestamp = now()
    let replacement = EchoEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      modifiedAt: timestamp,
      day: entry.day,
      rawText: text,
      polishedText: nil,
      originalText: text,
      type: entry.type,
      source: entry.source
    )
    try await repository.update(replacement)
    return replacement
  }

  func refine(_ entry: EchoEntry) async -> EchoEntry {
    var processing = entry
    processing.beginRefinement(at: now())

    do {
      try await repository.update(processing)
      let result = try await aiService.cleanUp(processing.rawText)
      let completedAt = now()
      processing.completeRefinement(
        text: result.text,
        provenance: EchoEntryRefinementProvenance(
          processorIdentifier: processorIdentifier,
          modelIdentifier: modelIdentifier,
          generatedAt: completedAt
        ),
        requiresReview: false,
        at: completedAt
      )
      try await repository.update(processing)
      return processing
    } catch {
      processing.failRefinement(at: now())
      try? await repository.update(processing)
      return processing
    }
  }
}
