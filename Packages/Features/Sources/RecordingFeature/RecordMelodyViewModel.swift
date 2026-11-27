import Foundation
import Observation
import SleepCore
import SleepDomain

/// Recording a sound of one's own: record (up to SleepCore's maximum), play
/// it back, then Save as "My Sound N" or try again. `done` with the saved
/// recording, or `nil` when backed out.
@MainActor
@Observable
public final class RecordMelodyViewModel {
  public enum State: Equatable {
    case idle
    case recording
    /// A take is ready; `isPlaying` while it plays back.
    case recorded(isPlaying: Bool)
  }

  public private(set) var state = State.idle
  public private(set) var canRecord = false
  private var take: URL?
  private let store: any MelodyStorePort
  private let recorder: any MelodyRecorderPort
  private let playback: any MelodyPlayerPort
  let done: @MainActor (Melody?) -> Void

  public init(
    store: any MelodyStorePort, recorder: any MelodyRecorderPort, playback: any MelodyPlayerPort,
    done: @escaping @MainActor (Melody?) -> Void)
  {
    self.store = store
    self.recorder = recorder
    self.playback = playback
    self.done = done
  }

  /// How long the take has been recording; not observed, read on each tick.
  public var elapsed: TimeInterval {
    recorder.elapsed
  }

  public func requestPermission() async {
    canRecord = await recorder.requestPermission()
  }

  public func toggleRecording() {
    if state == .recording { return finishTake() }
    playback.stop()
    do {
      try recorder.start { [weak self] in self?.finishTake() }
      state = .recording
    } catch {
      state = .idle
    }
  }

  public func togglePlayback() {
    guard case let .recorded(isPlaying) = state, let take else { return }
    if isPlaying {
      playback.stop()
      state = .recorded(isPlaying: false)
    } else if playback.play(take, loops: false, duration: nil, onFinish: { [weak self] in
      self?.state = .recorded(isPlaying: false)
    }) {
      state = .recorded(isPlaying: true)
    }
  }

  public func reRecord() {
    playback.stop()
    recorder.discard()
    take = nil
    state = .idle
  }

  public func back() {
    playback.stop()
    recorder.discard()
    done(nil)
  }

  public func save() {
    guard let take else { return }
    playback.stop()
    let name = Melody.customName(number: CustomMelodies.nameNumber(existing: store.recordings()))
    if let melody = store.save(take: take, name: name) {
      done(melody)
    }
  }

  private func finishTake() {
    take = recorder.stop()
    state = take == nil ? .idle : .recorded(isPlaying: false)
  }
}
