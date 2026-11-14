import Foundation
import SwiftData

/// Versioned from the first release, so the first breaking change has a place
/// to go. While V1 is current it points at the live record classes. Before a
/// breaking change: copy today's classes into `PersistenceSchemaV1` as nested
/// types, declare V2 with the live classes, add a `MigrationStage`, and add a
/// test that opens a V1 store on disk.
enum PersistenceSchemaV1: VersionedSchema {
  static let versionIdentifier = Schema.Version(1, 0, 0)

  static var models: [any PersistentModel.Type] {
    [SessionRecord.self, EventRecord.self]
  }
}

enum PersistenceMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [PersistenceSchemaV1.self]
  }

  static var stages: [MigrationStage] {
    []
  }
}

enum PersistenceSchema {
  typealias Current = PersistenceSchemaV1

  /// `url == nil` keeps the store in memory (tests, previews).
  static func container(at url: URL?) throws -> ModelContainer {
    let schema = Schema(versionedSchema: Current.self)
    let configuration = url.map { ModelConfiguration(schema: schema, url: $0) }
      ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, migrationPlan: PersistenceMigrationPlan.self, configurations: [configuration])
  }
}
