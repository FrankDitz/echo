import Foundation
import SwiftData

@ModelActor
actor SwiftDataEchoHighlightRepository: EchoHighlightRepository {
  func create(_ highlight: EchoHighlight) async throws {
    guard try record(id: highlight.id) == nil else {
      throw EchoRepositoryError.duplicateHighlight(highlight.id)
    }
    guard try record(target: highlight.target) == nil else {
      throw EchoRepositoryError.duplicateHighlightTarget(highlight.target)
    }

    modelContext.insert(EchoPersistenceMapper.makeHighlightRecord(from: highlight))
    try modelContext.save()
  }

  func highlight(for target: EchoHighlightTarget) async throws -> EchoHighlight? {
    try record(target: target).map(EchoPersistenceMapper.makeHighlight)
  }

  func allHighlights() async throws -> [EchoHighlight] {
    try modelContext.fetch(FetchDescriptor<PersistentEchoHighlight>())
      .map(EchoPersistenceMapper.makeHighlight)
      .sorted(by: chronological)
  }

  func delete(id: UUID) async throws {
    guard let record = try record(id: id) else {
      throw EchoRepositoryError.highlightNotFound(id)
    }

    modelContext.delete(record)
    try modelContext.save()
  }

  private func record(id: UUID) throws -> PersistentEchoHighlight? {
    var descriptor = FetchDescriptor<PersistentEchoHighlight>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func record(
    target: EchoHighlightTarget
  ) throws -> PersistentEchoHighlight? {
    let kind = target.kind.rawValue
    let entityID = target.entityID
    var descriptor = FetchDescriptor<PersistentEchoHighlight>(
      predicate: #Predicate {
        $0.targetKindRawValue == kind && $0.targetEntityID == entityID
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func chronological(_ lhs: EchoHighlight, _ rhs: EchoHighlight) -> Bool {
    if lhs.createdAt != rhs.createdAt {
      return lhs.createdAt < rhs.createdAt
    }

    return lhs.id.uuidString < rhs.id.uuidString
  }
}
