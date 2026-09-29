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

func makeDisposableStoreLocation() throws -> (directory: URL, store: URL) {
  let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent("EchoTests-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(
    at: directory,
    withIntermediateDirectories: false
  )
  return (directory, directory.appendingPathComponent("Echo.store"))
}

func repositoryRoot() -> URL {
  URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .standardizedFileURL
}
