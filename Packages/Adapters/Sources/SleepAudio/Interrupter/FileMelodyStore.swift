import Foundation
import SleepCore
import SleepDomain
import SleepMelodies

/// `MelodyStore` over files: recordings live in `directory` with a JSON list
/// beside them; built-in melodies come from the shared `SleepMelodies`. Ids
/// and file names follow SleepCore's `CustomMelodies`.
@MainActor
final class FileMelodyStore: MelodyStore {
  private struct Index: Codable {
    var melodies: [Melody] = []
    var nextID = CustomMelodies.firstID
  }

  private let directory: URL
  private var index: Index

  init(directory: URL) {
    self.directory = directory
    index = (try? JSONDecoder().decode(Index.self, from: Data(contentsOf: directory.appendingPathComponent(Self.indexName))))
      ?? Index()
  }

  static let indexName = "melodies.json"

  func recordings() -> [Melody] {
    index.melodies
  }

  func url(for melody: Melody) -> URL? {
    guard melody.isCustom else { return SleepMelodies.url(for: melody) }
    let url = directory.appendingPathComponent(melody.filename)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  func save(take: URL, name: String) -> Melody? {
    let id = CustomMelodies.nextID(stored: index.nextID, existing: index.melodies)
    let melody = Melody(id: id, filename: CustomMelodies.filename(id: id), customName: name)
    let destination = directory.appendingPathComponent(melody.filename)
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try? FileManager.default.removeItem(at: destination)
      try FileManager.default.moveItem(at: take, to: destination)
    } catch {
      Log.audio.error("Recording not saved: \(error.localizedDescription, privacy: .public)")
      return nil
    }
    index.melodies.append(melody)
    index.nextID = id + 1
    persist()
    return melody
  }

  func delete(_ melody: Melody) {
    guard melody.isCustom else { return }
    try? FileManager.default.removeItem(at: directory.appendingPathComponent(melody.filename))
    index.melodies.removeAll { $0.id == melody.id }
    persist()
  }

  private func persist() {
    do {
      try JSONEncoder().encode(index).write(to: directory.appendingPathComponent(Self.indexName), options: .atomic)
    } catch {
      Log.audio.error("Recordings list not saved: \(error.localizedDescription, privacy: .public)")
    }
  }
}
