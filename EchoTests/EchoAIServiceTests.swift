import Foundation
import Testing

@testable import Echo

@Suite("Provider-neutral AI service")
struct EchoAIServiceTests {
  private let service: any EchoAIService = DeterministicLocalAIService()

  @Test("Cleanup is deterministic and preserves paragraph meaning")
  func cleanup() async throws {
    let input = "  A   fictional morning.  \n\n\n  A quiet walk afterward. "

    let first = try await service.cleanUp(input)
    let second = try await service.cleanUp(input)

    #expect(first == second)
    #expect(first.text == "A fictional morning.\n\nA quiet walk afterward.")
    #expect(input == "  A   fictional morning.  \n\n\n  A quiet walk afterward. ")
  }

  @Test("Polish applies a predictable minimal transformation")
  func polish() async throws {
    let result = try await service.polish("  a fictional small moment  ")

    #expect(result.text == "A fictional small moment.")
  }

  @Test("Day organization preserves chronological source text and identity")
  func organizeDay() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let morning = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000801"),
      createdAt: try makeDate("2026-10-05T08:00:00Z"),
      calendar: calendar,
      rawText: "A fictional morning note."
    )
    let evening = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000802"),
      createdAt: try makeDate("2026-10-05T18:00:00Z"),
      calendar: calendar,
      rawText: "A fictional evening note."
    )
    let day = try #require(EchoDay.grouping([evening, morning]).first)

    let result = try await service.organize(day)

    #expect(result.day == morning.day)
    #expect(result.sourceEntryIDs == [morning.id, evening.id])
    #expect(
      result.body
        == "A fictional morning note.\n\nA fictional evening note."
    )
    #expect(day.entries == [morning, evening])
  }

  @Test("Blank writing is rejected without manufacturing content")
  func blankWriting() async {
    await #expect(throws: EchoAIServiceError.emptyWriting) {
      try await service.cleanUp(" \n\t ")
    }
    await #expect(throws: EchoAIServiceError.emptyWriting) {
      try await service.polish(" \n\t ")
    }
  }
}
