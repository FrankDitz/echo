import Foundation
import SwiftData

enum EchoModelContainerFactory {
  static func makePersistent() throws -> ModelContainer {
    let schema = Schema(versionedSchema: EchoSchemaV4.self)
    let configuration = productionConfiguration(schema: schema)
    return try makeContainer(schema: schema, configuration: configuration)
  }

  static func makeInMemory() throws -> ModelContainer {
    let schema = Schema(versionedSchema: EchoSchemaV4.self)
    let configuration = ModelConfiguration(
      "EchoInMemory",
      schema: schema,
      isStoredInMemoryOnly: true,
      groupContainer: .none,
      cloudKitDatabase: .none
    )
    return try makeContainer(schema: schema, configuration: configuration)
  }

  static func makePersistent(at storeURL: URL) throws -> ModelContainer {
    precondition(storeURL.isFileURL, "A SwiftData store must use a file URL.")

    let schema = Schema(versionedSchema: EchoSchemaV4.self)
    let configuration = ModelConfiguration(
      "EchoDisposable",
      schema: schema,
      url: storeURL,
      cloudKitDatabase: .none
    )
    return try makeContainer(schema: schema, configuration: configuration)
  }

  static func productionConfiguration() -> ModelConfiguration {
    productionConfiguration(schema: Schema(versionedSchema: EchoSchemaV4.self))
  }

  private static func productionConfiguration(schema: Schema) -> ModelConfiguration {
    ModelConfiguration(
      "Echo",
      schema: schema,
      isStoredInMemoryOnly: false,
      groupContainer: .none,
      cloudKitDatabase: .none
    )
  }

  private static func makeContainer(
    schema: Schema,
    configuration: ModelConfiguration
  ) throws -> ModelContainer {
    try ModelContainer(
      for: schema,
      migrationPlan: EchoMigrationPlan.self,
      configurations: [configuration]
    )
  }
}
