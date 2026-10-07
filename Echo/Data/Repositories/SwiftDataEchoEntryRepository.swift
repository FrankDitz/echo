import Foundation
import SwiftData

@ModelActor
actor SwiftDataEchoEntryRepository: EchoEntryRepository {
  func create(_ entry: EchoEntry) async throws {
    guard try record(id: entry.id) == nil else {
      throw EchoRepositoryError.duplicateEntry(entry.id)
    }

    modelContext.insert(try EchoPersistenceMapper.makeEntryRecord(from: entry))
    modelContext.insert(try EchoPersistenceMapper.makeEntryRefinementRecord(from: entry))
    try modelContext.save()
  }

  func entry(id: UUID) async throws -> EchoEntry? {
    guard let record = try record(id: id) else { return nil }
    return try EchoPersistenceMapper.makeEntry(
      from: record,
      refinement: refinementRecord(entryID: id)
    )
  }

  func entries(for day: EchoDayIdentifier) async throws -> [EchoEntry] {
    let dayKey = try EchoPersistenceMapper.dayKey(for: day)
    let descriptor = FetchDescriptor<PersistentEchoEntry>(
      predicate: #Predicate { $0.dayKey == dayKey }
    )
    let entries = try modelContext.fetch(descriptor).map(makeEntry)
    return EchoEntryOrdering.chronological(entries)
  }

  func allEntries() async throws -> [EchoEntry] {
    let entries = try modelContext.fetch(FetchDescriptor<PersistentEchoEntry>())
      .map(makeEntry)
    return EchoEntryOrdering.chronological(entries)
  }

  func searchEntries(matching query: EchoEntrySearchQuery) async throws -> [EchoEntry] {
    guard !query.isEmpty else { return [] }

    // Search remains inside the existing app-container store. Echo does not create
    // a second index, export journal text, or expose content to system search.
    let entries = try modelContext.fetch(FetchDescriptor<PersistentEchoEntry>())
      .map(makeEntry)
      .filter(query.matches)

    return entries.sorted { lhs, rhs in
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt > rhs.createdAt
      }
      return lhs.id.uuidString < rhs.id.uuidString
    }
  }

  func update(_ entry: EchoEntry) async throws {
    guard let record = try record(id: entry.id) else {
      throw EchoRepositoryError.entryNotFound(entry.id)
    }

    try EchoPersistenceMapper.update(record, from: entry)
    if let refinement = try refinementRecord(entryID: entry.id) {
      try EchoPersistenceMapper.update(refinement, from: entry)
    } else {
      modelContext.insert(try EchoPersistenceMapper.makeEntryRefinementRecord(from: entry))
    }
    try modelContext.save()
  }

  func delete(id: UUID) async throws {
    guard let record = try record(id: id) else {
      throw EchoRepositoryError.entryNotFound(id)
    }

    modelContext.delete(record)
    if let refinement = try refinementRecord(entryID: id) {
      modelContext.delete(refinement)
    }
    try modelContext.save()
  }

  private func record(id: UUID) throws -> PersistentEchoEntry? {
    var descriptor = FetchDescriptor<PersistentEchoEntry>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func refinementRecord(entryID: UUID) throws -> PersistentEchoEntryRefinement? {
    var descriptor = FetchDescriptor<PersistentEchoEntryRefinement>(
      predicate: #Predicate { $0.entryID == entryID }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func makeEntry(from record: PersistentEchoEntry) throws -> EchoEntry {
    try EchoPersistenceMapper.makeEntry(
      from: record,
      refinement: refinementRecord(entryID: record.id)
    )
  }
}

@ModelActor
actor SwiftDataEchoVoiceAttachmentRepository: EchoVoiceAttachmentRepository {
  func create(_ attachment: EchoVoiceAttachment) async throws {
    guard try record(id: attachment.id) == nil else {
      throw EchoRepositoryError.duplicateVoiceAttachment(attachment.id)
    }
    guard try record(entryID: attachment.entryID) == nil else {
      throw EchoRepositoryError.duplicateVoiceAttachmentEntry(attachment.entryID)
    }
    modelContext.insert(EchoPersistenceMapper.makeVoiceAttachmentRecord(from: attachment))
    try modelContext.save()
  }

  func attachment(for entryID: UUID) async throws -> EchoVoiceAttachment? {
    try record(entryID: entryID).map(EchoPersistenceMapper.makeVoiceAttachment)
  }

  func allAttachments() async throws -> [EchoVoiceAttachment] {
    try modelContext.fetch(FetchDescriptor<PersistentEchoVoiceAttachment>())
      .map(EchoPersistenceMapper.makeVoiceAttachment)
      .sorted { lhs, rhs in
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
      }
  }

  func update(_ attachment: EchoVoiceAttachment) async throws {
    guard let record = try record(id: attachment.id) else {
      throw EchoRepositoryError.voiceAttachmentNotFound(attachment.id)
    }
    EchoPersistenceMapper.update(record, from: attachment)
    try modelContext.save()
  }

  func delete(id: UUID) async throws {
    guard let record = try record(id: id) else {
      throw EchoRepositoryError.voiceAttachmentNotFound(id)
    }
    modelContext.delete(record)
    try modelContext.save()
  }

  private func record(id: UUID) throws -> PersistentEchoVoiceAttachment? {
    var descriptor = FetchDescriptor<PersistentEchoVoiceAttachment>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func record(entryID: UUID) throws -> PersistentEchoVoiceAttachment? {
    var descriptor = FetchDescriptor<PersistentEchoVoiceAttachment>(
      predicate: #Predicate { $0.entryID == entryID }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}

enum EchoVoiceFileStoreError: Error, Equatable {
  case invalidFileName
}

struct EchoVoiceFileStore: Sendable {
  let rootDirectory: URL

  static func applicationSupport() throws -> Self {
    let base = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    return Self(
      rootDirectory:
        base
        .appendingPathComponent("Echo", isDirectory: true)
        .appendingPathComponent("VoiceAttachments", isDirectory: true)
    )
  }

  func prepareDirectory() throws {
    try FileManager.default.createDirectory(
      at: rootDirectory,
      withIntermediateDirectories: true,
      attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
    )
  }

  func destinationURL(for attachmentID: UUID) throws -> URL {
    try prepareDirectory()
    return rootDirectory.appendingPathComponent("\(attachmentID.uuidString.lowercased()).m4a")
  }

  func url(for attachment: EchoVoiceAttachment) throws -> URL {
    guard
      attachment.relativeFileName
        == URL(fileURLWithPath: attachment.relativeFileName).lastPathComponent,
      attachment.relativeFileName.lowercased().hasSuffix(".m4a")
    else {
      throw EchoVoiceFileStoreError.invalidFileName
    }
    return rootDirectory.appendingPathComponent(attachment.relativeFileName)
  }

  func deleteFile(for attachment: EchoVoiceAttachment) throws {
    let fileURL = try url(for: attachment)
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
    try FileManager.default.removeItem(at: fileURL)
  }
}

struct EchoVoiceAttachmentLifecycle: Sendable {
  let repository: any EchoVoiceAttachmentRepository
  let fileStore: EchoVoiceFileStore

  func removeAttachment(for entryID: UUID) async throws {
    guard let attachment = try await repository.attachment(for: entryID) else { return }
    try await repository.delete(id: attachment.id)
    try fileStore.deleteFile(for: attachment)
  }
}
