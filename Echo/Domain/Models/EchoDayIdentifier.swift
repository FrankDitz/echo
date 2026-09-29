import Foundation

/// A stable local calendar-day value captured when an entry is created.
struct EchoDayIdentifier: Codable, Hashable, Comparable, Sendable {
  let calendarIdentifier: Calendar.Identifier
  let era: Int
  let year: Int
  let month: Int
  let day: Int

  init(
    calendarIdentifier: Calendar.Identifier,
    era: Int,
    year: Int,
    month: Int,
    day: Int
  ) {
    self.calendarIdentifier = calendarIdentifier
    self.era = era
    self.year = year
    self.month = month
    self.day = day
  }

  init(containing date: Date, calendar: Calendar) {
    let components = calendar.dateComponents([.era, .year, .month, .day], from: date)

    guard
      let era = components.era,
      let year = components.year,
      let month = components.month,
      let day = components.day
    else {
      preconditionFailure("The calendar could not produce a complete day identifier.")
    }

    self.calendarIdentifier = calendar.identifier
    self.era = era
    self.year = year
    self.month = month
    self.day = day
  }

  static func < (lhs: EchoDayIdentifier, rhs: EchoDayIdentifier) -> Bool {
    if lhs.calendarIdentifier != rhs.calendarIdentifier {
      return String(describing: lhs.calendarIdentifier)
        < String(describing: rhs.calendarIdentifier)
    }
    if lhs.era != rhs.era { return lhs.era < rhs.era }
    if lhs.year != rhs.year { return lhs.year < rhs.year }
    if lhs.month != rhs.month { return lhs.month < rhs.month }
    return lhs.day < rhs.day
  }
}
