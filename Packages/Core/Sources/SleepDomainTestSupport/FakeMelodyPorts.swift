import Foundation
import SleepCore
import SleepDomain

/// A `MelodyPlayer` a test drives: it records what played, and `finish()`
/// ends the melody as its length or file would.
@MainActor
public final class FakeMelodyPlayer: MelodyPlayer {
  public struct Play: Equatable {
    public let url: URL
    public let loops: Bool
    public let duration: TimeInterval?

    public init(url: URL, loops: Bool, duration: TimeInterval?) {
      self.url = url
      self.loops = loops
      self.duration = duration
    }
  }

  public private(set) var plays: [Play] = []
  public private(set) var stops = 0
  /// When false, `play` fails.
  public var starts = true
  private var onFinish: (@MainActor () -> Void)?

  public init() {}

  public var isPlaying: Bool { onFinish != nil }

  public func play(_ url: URL, loops: Bool, duration: TimeInterval?, onFinish: @escaping @MainActor () -> Void) -> Bool {
    guard starts else { return false }
    plays.append(Play(url: url, loops: loops, duration: duration))
    self.onFinish = onFinish
    return true
  }

  public func stop() {
    stops += 1
    onFinish = nil
  }

  /// The melody ends by itself.
  public func finish() {
    let done = onFinish
    onFinish = nil
    done?()
  }
}

/// Recordings in memory; every melody has a file URL named after it.
@MainActor
public final class FakeMelodyStore: MelodyStore {
  public private(set) var saved: [Melody]

  public init(recordings: [Melody] = []) {
    saved = recordings
  }

  public func recordings() -> [Melody] { saved }

  public func url(for melody: Melody) -> URL? {
    URL(fileURLWithPath: "/melodies/\(melody.filename)")
  }

  public func save(take _: URL, name: String) -> Melody? {
    let id = CustomMelodies.nextID(stored: 0, existing: saved)
    let melody = Melody(id: id, filename: CustomMelodies.filename(id: id), customName: name)
    saved.append(melody)
    return melody
  }

  public func delete(_ melody: Melody) {
    saved.removeAll { $0.id == melody.id }
  }
}

/// A `MelodyRecorder` a test drives: `reachLimit()` ends the take as the
/// maximum length would.
@MainActor
public final class FakeMelodyRecorder: MelodyRecorder {
  public var permission = true
  public var elapsed: TimeInterval = 0
  public private(set) var isRecording = false
  public private(set) var discards = 0
  /// A take exists until it's discarded, as in `AVMelodyRecorder`: stopping
  /// (by hand or at the limit) keeps it.
  private var hasTake = false
  private var onLimit: (@MainActor () -> Void)?

  public init() {}

  public func requestPermission() async -> Bool { permission }

  public func start(onLimit: @escaping @MainActor () -> Void) throws {
    isRecording = true
    hasTake = true
    self.onLimit = onLimit
  }

  public func stop() -> URL? {
    isRecording = false
    return hasTake ? URL(fileURLWithPath: "/tmp/take.m4a") : nil
  }

  public func discard() {
    discards += 1
    isRecording = false
    hasTake = false
  }

  public func reachLimit() {
    isRecording = false
    onLimit?()
  }
}
