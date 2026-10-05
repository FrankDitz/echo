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
    #expect(result.title == "Fictional in Focus")
    #expect(result.themes == ["Fictional", "Note", "Morning"])
    #expect(result.keyMoments == [
      "A fictional morning note",
      "A fictional evening note",
    ])
    #expect(result.reflectionQuestions == [
      "What about fictional would you like to carry forward?"
    ])
    #expect(day.entries == [morning, evening])
  }

  @Test("Weekly organization keeps complete provenance and selects notable entries")
  func organizeWeek() async throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let short = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000803"),
      createdAt: try makeDate("2026-10-05T08:00:00Z"),
      calendar: calendar,
      rawText: "A fictional short note."
    )
    let long = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000804"),
      createdAt: try makeDate("2026-10-07T18:00:00Z"),
      calendar: calendar,
      rawText: "A fictional longer note about steady creative momentum."
    )
    let week = EchoWeekIdentifier(containing: short.createdAt, calendar: calendar)

    let result = try await service.organizeWeek(entries: [long, short], week: week)

    #expect(result.week == week)
    #expect(result.sourceEntryIDs == [short.id, long.id])
    #expect(result.notableEntryIDs.first == long.id)
    #expect(!result.themes.isEmpty)
    #expect(result.question != nil)
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
