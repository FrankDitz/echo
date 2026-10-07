import SwiftData

enum EchoSchemaV1: VersionedSchema {
  static let versionIdentifier = Schema.Version(1, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistentEchoEntry.self,
      PersistentEchoHighlight.self,
    ]
  }
}

enum EchoSchemaV2: VersionedSchema {
  static let versionIdentifier = Schema.Version(2, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistentEchoEntry.self,
      PersistentEchoHighlight.self,
      PersistentEchoOrganizedJournal.self,
    ]
  }
}

enum EchoSchemaV3: VersionedSchema {
  static let versionIdentifier = Schema.Version(3, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistentEchoEntry.self,
      PersistentEchoHighlight.self,
      PersistentEchoOrganizedJournal.self,
      PersistentEchoOrganizedJournalV3.self,
    ]
  }
}

enum EchoSchemaV4: VersionedSchema {
  static let versionIdentifier = Schema.Version(4, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistentEchoEntry.self,
      PersistentEchoHighlight.self,
      PersistentEchoOrganizedJournal.self,
      PersistentEchoOrganizedJournalV3.self,
      PersistentEchoWeeklyReflection.self,
    ]
  }
}

enum EchoSchemaV5: VersionedSchema {
  static let versionIdentifier = Schema.Version(5, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistentEchoEntry.self,
      PersistentEchoHighlight.self,
      PersistentEchoOrganizedJournal.self,
      PersistentEchoOrganizedJournalV3.self,
      PersistentEchoWeeklyReflection.self,
      PersistentEchoVoiceAttachment.self,
    ]
  }
}

enum EchoSchemaV6: VersionedSchema {
  static let versionIdentifier = Schema.Version(6, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistentEchoEntry.self,
      PersistentEchoHighlight.self,
      PersistentEchoOrganizedJournal.self,
      PersistentEchoOrganizedJournalV3.self,
      PersistentEchoWeeklyReflection.self,
      PersistentEchoVoiceAttachment.self,
      PersistentEchoCarryForward.self,
    ]
  }
}

enum EchoSchemaV7: VersionedSchema {
  static let versionIdentifier = Schema.Version(7, 0, 0)

  static var models: [any PersistentModel.Type] {
    [
      PersistentEchoEntry.self,
      PersistentEchoHighlight.self,
      PersistentEchoOrganizedJournal.self,
      PersistentEchoOrganizedJournalV3.self,
      PersistentEchoWeeklyReflection.self,
      PersistentEchoVoiceAttachment.self,
      PersistentEchoCarryForward.self,
      PersistentEchoEntryRefinement.self,
    ]
  }
}

enum EchoMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [
      EchoSchemaV1.self,
      EchoSchemaV2.self,
      EchoSchemaV3.self,
      EchoSchemaV4.self,
      EchoSchemaV5.self,
      EchoSchemaV6.self,
      EchoSchemaV7.self,
    ]
  }

  static var stages: [MigrationStage] {
    [
      .lightweight(fromVersion: EchoSchemaV1.self, toVersion: EchoSchemaV2.self),
      .custom(
        fromVersion: EchoSchemaV2.self,
        toVersion: EchoSchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
          let legacyJournals = try context.fetch(
            FetchDescriptor<PersistentEchoOrganizedJournal>()
          )
          for legacy in legacyJournals {
            context.insert(
              PersistentEchoOrganizedJournalV3(
                id: legacy.id,
                dayKey: legacy.dayKey,
                dayPayload: legacy.dayPayload,
                createdAt: legacy.createdAt,
                modifiedAt: legacy.modifiedAt,
                body: legacy.body,
                sourceEntryIDsPayload: legacy.sourceEntryIDsPayload,
                generatorRawValue: legacy.generatorRawValue
              )
            )
            context.delete(legacy)
          }
          try context.save()
        }
      ),
      .lightweight(fromVersion: EchoSchemaV3.self, toVersion: EchoSchemaV4.self),
      .lightweight(fromVersion: EchoSchemaV4.self, toVersion: EchoSchemaV5.self),
      .lightweight(fromVersion: EchoSchemaV5.self, toVersion: EchoSchemaV6.self),
      .lightweight(fromVersion: EchoSchemaV6.self, toVersion: EchoSchemaV7.self),
    ]
  }
}
