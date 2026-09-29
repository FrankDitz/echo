import Foundation

protocol EchoHighlightRepository: Sendable {
  func create(_ highlight: EchoHighlight) async throws
  func highlight(for target: EchoHighlightTarget) async throws -> EchoHighlight?
  func allHighlights() async throws -> [EchoHighlight]
  func delete(id: UUID) async throws
}
