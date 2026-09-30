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

enum EchoMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [EchoSchemaV1.self, EchoSchemaV2.self]
  }

  static var stages: [MigrationStage] {
    [
      .lightweight(fromVersion: EchoSchemaV1.self, toVersion: EchoSchemaV2.self)
    ]
  }
}
