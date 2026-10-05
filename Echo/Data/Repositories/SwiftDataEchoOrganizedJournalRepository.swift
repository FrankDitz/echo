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
    try modelContext.fetch(FetchDescriptor<PersistentEchoOrganizedJournalV3>())
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

  private func record(id: UUID) throws -> PersistentEchoOrganizedJournalV3? {
    var descriptor = FetchDescriptor<PersistentEchoOrganizedJournalV3>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func record(day: EchoDayIdentifier) throws -> PersistentEchoOrganizedJournalV3? {
    let dayKey = try EchoPersistenceMapper.dayKey(for: day)
    var descriptor = FetchDescriptor<PersistentEchoOrganizedJournalV3>(
      predicate: #Predicate { $0.dayKey == dayKey }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}

@ModelActor
actor SwiftDataEchoWeeklyReflectionRepository: EchoWeeklyReflectionRepository {
  func create(_ reflection: EchoWeeklyReflection) async throws {
    guard try record(id: reflection.id) == nil else {
      throw EchoRepositoryError.duplicateWeeklyReflection(reflection.id)
    }
    guard try record(week: reflection.week) == nil else {
      throw EchoRepositoryError.duplicateWeeklyReflectionWeek(reflection.week)
    }
    modelContext.insert(try EchoPersistenceMapper.makeWeeklyReflectionRecord(from: reflection))
    try modelContext.save()
  }

  func reflection(for week: EchoWeekIdentifier) async throws -> EchoWeeklyReflection? {
    try record(week: week).map(EchoPersistenceMapper.makeWeeklyReflection)
  }

  func allReflections() async throws -> [EchoWeeklyReflection] {
    try modelContext.fetch(FetchDescriptor<PersistentEchoWeeklyReflection>())
      .map(EchoPersistenceMapper.makeWeeklyReflection)
      .sorted { lhs, rhs in
        if lhs.week != rhs.week { return lhs.week > rhs.week }
        return lhs.id.uuidString < rhs.id.uuidString
      }
  }

  func update(_ reflection: EchoWeeklyReflection) async throws {
    guard let record = try record(id: reflection.id) else {
      throw EchoRepositoryError.weeklyReflectionNotFound(reflection.id)
    }
    try EchoPersistenceMapper.update(record, from: reflection)
    try modelContext.save()
  }

  func delete(id: UUID) async throws {
    guard let record = try record(id: id) else {
      throw EchoRepositoryError.weeklyReflectionNotFound(id)
    }
    modelContext.delete(record)
    try modelContext.save()
  }

  private func record(id: UUID) throws -> PersistentEchoWeeklyReflection? {
    var descriptor = FetchDescriptor<PersistentEchoWeeklyReflection>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func record(week: EchoWeekIdentifier) throws -> PersistentEchoWeeklyReflection? {
    let weekKey = try EchoPersistenceMapper.weekKey(for: week)
    var descriptor = FetchDescriptor<PersistentEchoWeeklyReflection>(
      predicate: #Predicate { $0.weekKey == weekKey }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}
