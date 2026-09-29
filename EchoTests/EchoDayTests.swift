import Foundation
import Testing

@testable import Echo

@Suite("Calendar day grouping")
struct EchoDayTests {
  @Test("Entries group by calendar day and sort chronologically")
  func groupingAndOrdering() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let firstMorning = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000201"),
      createdAt: try makeDate("2026-09-28T08:00:00Z"),
      calendar: calendar,
      rawText: "Fictional morning note."
    )
    let firstEvening = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000202"),
      createdAt: try makeDate("2026-09-28T20:00:00Z"),
      calendar: calendar,
      rawText: "Fictional evening note."
    )
    let nextDay = EchoEntry(
      id: try makeUUID("00000000-0000-0000-0000-000000000203"),
      createdAt: try makeDate("2026-09-29T09:00:00Z"),
      calendar: calendar,
      rawText: "Fictional next-day note."
    )

    let days = EchoDay.grouping([nextDay, firstEvening, firstMorning])

    #expect(days.count == 2)
    #expect(days[0].id == firstMorning.day)
    #expect(days[0].entries.map(\.id) == [firstMorning.id, firstEvening.id])
    #expect(days[0].entryCount == 2)
    #expect(days[1].id == nextDay.day)
    #expect(days[1].entries.map(\.id) == [nextDay.id])
  }

  @Test("Equal timestamps use stable UUID ordering")
  func deterministicTieBreaking() throws {
    let calendar = try makeGregorianCalendar(timeZone: "UTC")
    let timestamp = try makeDate("2026-09-29T09:00:00Z")
    let earlierID = try makeUUID("00000000-0000-0000-0000-000000000204")
    let laterID = try makeUUID("00000000-0000-0000-0000-000000000205")
    let earlier = EchoEntry(
      id: earlierID,
      createdAt: timestamp,
      calendar: calendar,
      rawText: "Fictional tie A."
    )
    let later = EchoEntry(
      id: laterID,
      createdAt: timestamp,
      calendar: calendar,
      rawText: "Fictional tie B."
    )

    let ordered = EchoEntryOrdering.chronological([later, earlier])

    #expect(ordered.map(\.id) == [earlierID, laterID])
  }

  @Test("Day identity honors the supplied calendar time zone")
  func timeZoneBoundary() throws {
    let timestamp = try makeDate("2026-09-30T01:30:00Z")
    let utc = try makeGregorianCalendar(timeZone: "UTC")
    let newYork = try makeGregorianCalendar(timeZone: "America/New_York")

    let utcDay = EchoDayIdentifier(containing: timestamp, calendar: utc)
    let newYorkDay = EchoDayIdentifier(containing: timestamp, calendar: newYork)

    #expect(utcDay.calendarIdentifier == .gregorian)
    #expect(newYorkDay.calendarIdentifier == .gregorian)
    #expect(utcDay.year == 2026)
    #expect(utcDay.month == 9)
    #expect(utcDay.day == 30)
    #expect(newYorkDay.year == 2026)
    #expect(newYorkDay.month == 9)
    #expect(newYorkDay.day == 29)
    #expect(utcDay != newYorkDay)
  }

  @Test("A captured day reconstructs a stable display date")
  func displayDate() throws {
    let timeZone = try #require(TimeZone(identifier: "America/New_York"))
    let day = EchoDayIdentifier(
      calendarIdentifier: .gregorian,
      era: 1,
      year: 2026,
      month: 3,
      day: 8
    )

    let date = try #require(day.date(in: timeZone))
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)

    #expect(components.year == 2026)
    #expect(components.month == 3)
    #expect(components.day == 8)
    #expect(components.hour == 12)
  }
}
