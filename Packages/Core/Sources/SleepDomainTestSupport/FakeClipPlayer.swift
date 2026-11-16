import Foundation
import SleepDomain

/// A `ClipPlayer` that records what it was asked and lets a test finish the
/// clip, interrupt, or move time. Files are "loaded" from `durations`.
@MainActor
public final class FakeClipPlayer: ClipPlayer {
  public enum Call: Equatable {
    case load(String)
    case play(from: TimeInterval, for: TimeInterval)
    case pause
    case stop
  }

  public private(set) var calls: [Call] = []
  /// Length per file name; a name missing here fails to load.
  public var durations: [String: TimeInterval]
  public var position: TimeInterval = 0
  public var isEnhanced = false
  public var onInterruption: (@MainActor () -> Void)?
  private var onFinish: (@MainActor () -> Void)?

  public init(durations: [String: TimeInterval] = [:]) {
    self.durations = durations
  }

  public struct LoadFailed: Error {}

  public func load(_ url: URL) throws -> TimeInterval {
    calls.append(.load(url.lastPathComponent))
    guard let duration = durations[url.lastPathComponent] else { throw LoadFailed() }
    position = 0
    return duration
  }

  public func play(from offset: TimeInterval, for duration: TimeInterval, onFinish: @escaping @MainActor () -> Void) throws {
    calls.append(.play(from: offset, for: duration))
    position = offset
    self.onFinish = onFinish
  }

  public func pause() {
    calls.append(.pause)
    onFinish = nil
  }

  public func stop() {
    calls.append(.stop)
    onFinish = nil
  }

  /// The clip played to its end.
  public func finish() {
    let finish = onFinish
    onFinish = nil
    finish?()
  }

  public func interrupt() {
    onFinish = nil
    onInterruption?()
  }
}
