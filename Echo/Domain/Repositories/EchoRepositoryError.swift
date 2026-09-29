import Foundation

enum EchoRepositoryError: Error, Equatable, Sendable {
  case duplicateEntry(UUID)
  case entryNotFound(UUID)
  case duplicateHighlight(UUID)
  case duplicateHighlightTarget(EchoHighlightTarget)
  case highlightNotFound(UUID)
}
