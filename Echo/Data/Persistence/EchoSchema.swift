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

enum EchoMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [EchoSchemaV1.self]
  }

  static var stages: [MigrationStage] {
    []
  }
}
