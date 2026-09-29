import Foundation
import Testing

func makeDate(_ value: String) throws -> Date {
  try #require(ISO8601DateFormatter().date(from: value))
}

func makeUUID(_ value: String) throws -> UUID {
  try #require(UUID(uuidString: value))
}

func makeGregorianCalendar(timeZone identifier: String) throws -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = try #require(TimeZone(identifier: identifier))
  return calendar
}
