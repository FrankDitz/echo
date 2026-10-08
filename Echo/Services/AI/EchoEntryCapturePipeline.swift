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
  func beginRefinement(_ entry: EchoEntry) async -> EchoEntry
  func finishRefinement(_ entry: EchoEntry) async -> EchoEntry
  func refine(_ entry: EchoEntry) async -> EchoEntry
}

struct EchoEntryCapturePipeline: EchoEntryCapturing {
  private let repository: any EchoEntryRepository
  private let refiner: any EchoWritingRefiner
  private let calendar: Calendar
  private let now: @Sendable () -> Date

  init(
    repository: any EchoEntryRepository,
    refiner: any EchoWritingRefiner,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.repository = repository
    self.refiner = refiner
    self.calendar = calendar
    self.now = now
  }

  init(
    repository: any EchoEntryRepository,
    aiService: any EchoAIService,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping @Sendable () -> Date = Date.init,
    processorIdentifier: String = "echo.deterministic-local",
    modelIdentifier: String? = nil
  ) {
    self.init(
      repository: repository,
      refiner: EchoAIServiceWritingRefiner(
        service: aiService,
        processorIdentifier: processorIdentifier,
        modelIdentifier: modelIdentifier
      ),
      calendar: calendar,
      now: now
    )
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
    guard refiner.isEnabled else { return entry }

    let processing = await beginRefinement(entry)
    return await finishRefinement(processing)
  }

  func beginRefinement(_ entry: EchoEntry) async -> EchoEntry {
    guard refiner.isEnabled else { return entry }
    var processing = entry
    processing.beginRefinement(at: now())

    do {
      try await repository.update(processing)
      return processing
    } catch {
      processing.failRefinement(at: now())
      try? await repository.update(processing)
      return processing
    }
  }

  func finishRefinement(_ entry: EchoEntry) async -> EchoEntry {
    guard refiner.isEnabled, entry.refinementStatus == .processing else { return entry }
    var processing = entry

    do {
      let result = try await refiner.refine(processing.rawText)
      let completedAt = now()
      processing.completeRefinement(
        text: result.text,
        provenance: EchoEntryRefinementProvenance(
          processorIdentifier: refiner.processorIdentifier,
          modelIdentifier: refiner.modelIdentifier,
          generatedAt: completedAt
        ),
        requiresReview: refiner.requiresReview,
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
