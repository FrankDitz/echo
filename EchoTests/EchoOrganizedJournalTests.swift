import Foundation
import Testing

@testable import Echo

@Suite("Organized journal domain")
struct EchoOrganizedJournalTests {
  @Test("Regeneration preserves identity and day while advancing content")
  func regeneration() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let day = EchoDayIdentifier(
      containing: try makeDate("2026-10-06T12:00:00Z"),
      calendar: calendar
    )
    let createdAt = try makeDate("2026-10-06T20:00:00Z")
    let regeneratedAt = try makeDate("2026-10-06T21:00:00Z")
    let firstSource = try makeUUID("00000000-0000-0000-0000-000000000901")
    let secondSource = try makeUUID("00000000-0000-0000-0000-000000000902")
    var journal = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000903"),
      day: day,
      createdAt: createdAt,
      body: "A fictional first organization.",
      title: "First title",
      themes: ["Focus"],
      keyMoments: ["Started the fictional project."],
      reflectionQuestions: ["What made the start possible?"],
      sourceEntryIDs: [firstSource],
      generator: .deterministicLocal
    )

    journal.regenerate(
      body: "A fictional regenerated organization.",
      title: "A clearer direction",
      themes: ["Clarity", "Momentum"],
      keyMoments: ["Connected the fictional ideas."],
      reflectionQuestions: ["What should happen next?"],
      sourceEntryIDs: [firstSource, secondSource],
      at: regeneratedAt
    )

    #expect(journal.day == day)
    #expect(journal.createdAt == createdAt)
    #expect(journal.modifiedAt == regeneratedAt)
    #expect(journal.body == "A fictional regenerated organization.")
    #expect(journal.title == "A clearer direction")
    #expect(journal.themes == ["Clarity", "Momentum"])
    #expect(journal.keyMoments == ["Connected the fictional ideas."])
    #expect(journal.reflectionQuestions == ["What should happen next?"])
    #expect(journal.sourceEntryIDs == [firstSource, secondSource])
    #expect(journal.generator == .deterministicLocal)
  }

  @Test("Organized journals round-trip through Codable")
  func codableRoundTrip() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let journal = EchoOrganizedJournal(
      day: EchoDayIdentifier(
        containing: try makeDate("2026-10-06T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: try makeDate("2026-10-06T20:00:00Z"),
      body: "A fictional organized journal.",
      title: "A fictional title",
      themes: ["Clarity"],
      keyMoments: ["A fictional key moment."],
      reflectionQuestions: ["A fictional question?"],
      sourceEntryIDs: [try makeUUID("00000000-0000-0000-0000-000000000904")],
      generator: .deterministicLocal
    )

    let decoded = try JSONDecoder().decode(
      EchoOrganizedJournal.self,
      from: JSONEncoder().encode(journal)
    )

    #expect(decoded == journal)
  }

  @Test("Legacy journals decode without structured reflection fields")
  func legacyCodablePayload() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let legacyJournal = EchoOrganizedJournal(
      id: try makeUUID("00000000-0000-0000-0000-000000000905"),
      day: EchoDayIdentifier(
        containing: try makeDate("2026-10-06T12:00:00Z"),
        calendar: calendar
      ),
      createdAt: try makeDate("2026-10-06T20:00:00Z"),
      body: "A legacy fictional journal.",
      sourceEntryIDs: [],
      generator: .deterministicLocal
    )
    var payload = try #require(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(legacyJournal))
        as? [String: Any]
    )
    payload.removeValue(forKey: "title")
    payload.removeValue(forKey: "themes")
    payload.removeValue(forKey: "keyMoments")
    payload.removeValue(forKey: "reflectionQuestions")

    let journal = try JSONDecoder().decode(
      EchoOrganizedJournal.self,
      from: JSONSerialization.data(withJSONObject: payload)
    )

    #expect(journal.title == nil)
    #expect(journal.themes.isEmpty)
    #expect(journal.keyMoments.isEmpty)
    #expect(journal.reflectionQuestions.isEmpty)
  }
}

@Suite("Weekly reflection domain")
struct EchoWeeklyReflectionTests {
  @Test("Week identity is stable and reflection regeneration preserves provenance")
  func weekIdentityAndRegeneration() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let week = EchoWeekIdentifier(
      containing: try makeDate("2026-10-07T12:00:00Z"),
      calendar: calendar
    )
    #expect(
      week == EchoWeekIdentifier(
        containing: try makeDate("2026-10-09T12:00:00Z"),
        calendar: calendar
      )
    )

    let source = try makeUUID("00000000-0000-0000-0000-000000000921")
    var reflection = EchoWeeklyReflection(
      week: week,
      createdAt: try makeDate("2026-10-11T20:00:00Z"),
      body: "A fictional first weekly reflection.",
      themes: ["Focus"],
      notableEntryIDs: [source],
      sourceEntryIDs: [source],
      question: "What mattered?",
      generator: .deterministicLocal
    )
    let id = reflection.id
    reflection.regenerate(
      body: "A fictional revised weekly reflection.",
      themes: ["Momentum"],
      notableEntryIDs: [source],
      sourceEntryIDs: [source],
      question: "What comes next?",
      at: try makeDate("2026-10-11T21:00:00Z")
    )

    #expect(reflection.id == id)
    #expect(reflection.week == week)
    #expect(reflection.themes == ["Momentum"])
    #expect(reflection.sourceEntryIDs == [source])
    #expect(reflection.question == "What comes next?")
  }
}
