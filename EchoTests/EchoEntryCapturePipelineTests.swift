import Foundation
import Testing

@testable import Echo

@Suite("Unified entry capture pipeline")
struct EchoEntryCapturePipelineTests {
  @Test("Original writing is persisted before refinement and remains preserved")
  func textCapture() async throws {
    let repository = CaptureEntryRepositoryStub()
    let timestamp = try makeDate("2026-10-07T12:00:00Z")
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let pipeline = EchoEntryCapturePipeline(
      repository: repository,
      aiService: DeterministicLocalAIService(),
      calendar: calendar,
      now: { timestamp },
      processorIdentifier: "echo.test.local"
    )

    let preserved = try await pipeline.preserve(
      "fictional thought without punctuation",
      id: try makeUUID("00000000-0000-0000-0000-000000000701"),
      createdAt: timestamp,
      type: .text,
      source: .user
    )
    #expect(await repository.entry(id: preserved.id)?.refinementStatus == .notRequested)

    let refined = await pipeline.refine(preserved)

    #expect(refined.originalText == "fictional thought without punctuation")
    #expect(refined.preferredText == "fictional thought without punctuation")
    #expect(refined.refinementStatus == .refined)
    #expect(refined.refinementProvenance?.processorIdentifier == "echo.test.local")
    #expect(await repository.entry(id: refined.id) == refined)
  }

  @Test("A refinement failure leaves the original entry safely persisted")
  func refinementFailure() async throws {
    let repository = CaptureEntryRepositoryStub()
    let timestamp = try makeDate("2026-10-07T12:00:00Z")
    let pipeline = EchoEntryCapturePipeline(
      repository: repository,
      aiService: FailingCaptureAIService(),
      calendar: try makeGregorianCalendar(timeZone: "UTC"),
      now: { timestamp }
    )
    let preserved = try await pipeline.preserve(
      "A fictional thought that must not be lost.",
      id: UUID(),
      createdAt: timestamp,
      type: .text,
      source: .user
    )

    let result = await pipeline.refine(preserved)

    #expect(result.originalText == preserved.originalText)
    #expect(result.rawText == preserved.rawText)
    #expect(result.refinementStatus == .failed)
    #expect(await repository.entry(id: preserved.id) == result)
  }

  @Test("A voice transcript replaces only the temporary placeholder")
  func voiceTranscript() async throws {
    let repository = CaptureEntryRepositoryStub()
    let timestamp = try makeDate("2026-10-07T12:00:00Z")
    let pipeline = EchoEntryCapturePipeline(
      repository: repository,
      aiService: DeterministicLocalAIService(),
      calendar: try makeGregorianCalendar(timeZone: "UTC"),
      now: { timestamp }
    )
    let placeholder = try await pipeline.preserve(
      "Voice entry",
      id: UUID(),
      createdAt: timestamp,
      type: .voice,
      source: .user
    )

    let transcript = try await pipeline.replaceOriginalText(
      "A fictional spoken memory.",
      for: placeholder
    )

    #expect(transcript.type == .voice)
    #expect(transcript.originalText == "A fictional spoken memory.")
    #expect(transcript.rawText == "A fictional spoken memory.")
    #expect(await repository.entry(id: transcript.id) == transcript)
  }
}

private actor CaptureEntryRepositoryStub: EchoEntryRepository {
  private var entries: [UUID: EchoEntry] = [:]

  func create(_ entry: EchoEntry) throws {
    entries[entry.id] = entry
  }

  func entry(id: UUID) -> EchoEntry? {
    entries[id]
  }

  func entries(for day: EchoDayIdentifier) -> [EchoEntry] {
    EchoEntryOrdering.chronological(entries.values.filter { $0.day == day })
  }

  func allEntries() -> [EchoEntry] {
    EchoEntryOrdering.chronological(Array(entries.values))
  }

  func update(_ entry: EchoEntry) throws {
    entries[entry.id] = entry
  }

  func delete(id: UUID) throws {
    entries[id] = nil
  }
}

private struct FailingCaptureAIService: EchoAIService {
  func cleanUp(_ rawText: String) async throws -> EchoAssistedWriting {
    throw EchoAIServiceError.emptyWriting
  }

  func polish(_ rawText: String) async throws -> EchoAssistedWriting {
    throw EchoAIServiceError.emptyWriting
  }

  func organize(_ day: EchoDay) async throws -> EchoOrganizedJournalDraft {
    throw EchoAIServiceError.emptyDay
  }

  func organizeWeek(
    entries: [EchoEntry],
    week: EchoWeekIdentifier
  ) async throws -> EchoWeeklyReflectionDraft {
    throw EchoAIServiceError.emptyDay
  }
}
