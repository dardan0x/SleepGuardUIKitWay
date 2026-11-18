import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// Recording a sound of one's own, in the shared `RecordMelodyContent`:
/// record (up to SleepCore's maximum), play it back, then Save as "My Sound
/// N" or try again. Redraws ten times a second for the elapsed time. `done`
/// with the saved recording, or `nil` when backed out.
public final class RecordMelodyViewController: ScreenController {
  let store: any MelodyStore
  let recorder: any MelodyRecorder
  let playback: any MelodyPlayer
  let done: @MainActor (Melody?) -> Void
  private(set) var state: MelodyRecordingState = .idle
  private var canRecord = false
  private var take: URL?
  private var ticking: Task<Void, Never>?

  public init(
    store: any MelodyStore, recorder: any MelodyRecorder, playback: any MelodyPlayer,
    done: @escaping @MainActor (Melody?) -> Void, theme: Theme, chrome: ScreenChrome)
  {
    self.store = store
    self.recorder = recorder
    self.playback = playback
    self.done = done
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    ticking?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    redraw()
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    guard ticking == nil else { return }
    let recorder = recorder
    ticking = Task { [weak self] in
      let allowed = await recorder.requestPermission()
      self?.canRecord = allowed
      while !Task.isCancelled {
        self?.redraw()
        try? await Task.sleep(for: .milliseconds(100))
      }
    }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    ticking?.cancel()
    ticking = nil
  }

  private func redraw() {
    render(RecordMelodyContent(
      state: state, elapsed: recorder.elapsed, canRecord: canRecord,
      onRecordToggle: { [weak self] in self?.toggleRecording() },
      onPlayToggle: { [weak self] in self?.togglePlayback() },
      onSave: { [weak self] in self?.save() },
      onReRecord: { [weak self] in self?.reRecord() },
      onBack: { [weak self] in self?.back() }))
  }

  private func set(_ state: MelodyRecordingState) {
    self.state = state
    redraw()
  }

  func toggleRecording() {
    if state == .recording { return finishTake() }
    playback.stop()
    do {
      try recorder.start { [weak self] in self?.finishTake() }
      set(.recording)
    } catch {
      set(.idle)
    }
  }

  private func finishTake() {
    take = recorder.stop()
    set(take == nil ? .idle : .recorded(isPlaying: false))
  }

  private func togglePlayback() {
    guard case let .recorded(isPlaying) = state, let take else { return }
    if isPlaying {
      playback.stop()
      set(.recorded(isPlaying: false))
    } else if playback.play(take, loops: false, duration: nil, onFinish: { [weak self] in
      self?.set(.recorded(isPlaying: false))
    }) {
      set(.recorded(isPlaying: true))
    }
  }

  private func reRecord() {
    playback.stop()
    recorder.discard()
    take = nil
    set(.idle)
  }

  private func back() {
    playback.stop()
    recorder.discard()
    done(nil)
  }

  private func save() {
    guard let take else { return }
    playback.stop()
    let name = Melody.customName(number: CustomMelodies.nameNumber(existing: store.recordings()))
    if let melody = store.save(take: take, name: name) {
      done(melody)
    }
  }
}
