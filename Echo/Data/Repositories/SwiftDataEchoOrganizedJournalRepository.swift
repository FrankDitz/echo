import Foundation
import SwiftData

@ModelActor
actor SwiftDataEchoOrganizedJournalRepository: EchoOrganizedJournalRepository {
  func create(_ journal: EchoOrganizedJournal) async throws {
    guard try record(id: journal.id) == nil else {
      throw EchoRepositoryError.duplicateOrganizedJournal(journal.id)
    }
    guard try record(day: journal.day) == nil else {
      throw EchoRepositoryError.duplicateOrganizedJournalDay(journal.day)
    }

    modelContext.insert(try EchoPersistenceMapper.makeOrganizedJournalRecord(from: journal))
    try modelContext.save()
  }

  func journal(for day: EchoDayIdentifier) async throws -> EchoOrganizedJournal? {
    try record(day: day).map(EchoPersistenceMapper.makeOrganizedJournal)
  }

  func allJournals() async throws -> [EchoOrganizedJournal] {
    try modelContext.fetch(FetchDescriptor<PersistentEchoOrganizedJournal>())
      .map(EchoPersistenceMapper.makeOrganizedJournal)
      .sorted { lhs, rhs in
        if lhs.day != rhs.day { return lhs.day < rhs.day }
        return lhs.id.uuidString < rhs.id.uuidString
      }
  }

  func update(_ journal: EchoOrganizedJournal) async throws {
    guard let record = try record(id: journal.id) else {
      throw EchoRepositoryError.organizedJournalNotFound(journal.id)
    }

    try EchoPersistenceMapper.update(record, from: journal)
    try modelContext.save()
  }

  func delete(id: UUID) async throws {
    guard let record = try record(id: id) else {
      throw EchoRepositoryError.organizedJournalNotFound(id)
    }
    modelContext.delete(record)
    try modelContext.save()
  }

  private func record(id: UUID) throws -> PersistentEchoOrganizedJournal? {
    var descriptor = FetchDescriptor<PersistentEchoOrganizedJournal>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func record(day: EchoDayIdentifier) throws -> PersistentEchoOrganizedJournal? {
    let dayKey = try EchoPersistenceMapper.dayKey(for: day)
    var descriptor = FetchDescriptor<PersistentEchoOrganizedJournal>(
      predicate: #Predicate { $0.dayKey == dayKey }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}
