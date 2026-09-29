import Foundation

/// An extensible value rather than a closed enum so future entry types can decode safely.
struct EchoEntryType: RawRepresentable, Codable, Hashable, Sendable {
  let rawValue: String

  static let text = EchoEntryType(rawValue: "text")
}

/// Identifies where an entry originated without coupling Echo to another application.
struct EchoEntrySource: RawRepresentable, Codable, Hashable, Sendable {
  let rawValue: String

  static let user = EchoEntrySource(rawValue: "user")
}
