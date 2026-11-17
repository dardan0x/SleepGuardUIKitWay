import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// Recording a sound of one's own, hosting the shared content: record (up
/// to SleepCore's maximum), play it back, then Save as "My Sound N" or try
/// again. `done` with the saved recording, or `nil` when backed out.
public struct RecordMelodyScreen: View {
  let store: any MelodyStore
  let recorder: any MelodyRecorder
  let playback: any MelodyPlayer
  let done: @MainActor (Melody?) -> Void
  @State private var state: MelodyRecordingState = .idle
  @State private var canRecord = false
  @State private var take: URL?

  public init(
    store: any MelodyStore, recorder: any MelodyRecorder, playback: any MelodyPlayer,
    done: @escaping @MainActor (Melody?) -> Void)
  {
    self.store = store
    self.recorder = recorder
    self.playback = playback
    self.done = done
  }

  public var body: some View {
    TimelineView(.periodic(from: .now, by: 0.1)) { _ in
      RecordMelodyContent(
        state: state, elapsed: recorder.elapsed, canRecord: canRecord,
        onRecordToggle: toggleRecording, onPlayToggle: togglePlayback,
        onSave: save,
        onReRecord: {
          playback.stop()
          recorder.discard()
          take = nil
          state = .idle
        },
        onBack: {
          playback.stop()
          recorder.discard()
          done(nil)
        })
    }
    .task { canRecord = await recorder.requestPermission() }
  }

  private func toggleRecording() {
    if state == .recording {
      finishTake()
      return
    }
    playback.stop()
    do {
      try recorder.start { finishTake() }
      state = .recording
    } catch {
      state = .idle
    }
  }

  private func finishTake() {
    take = recorder.stop()
    state = take == nil ? .idle : .recorded(isPlaying: false)
  }

  private func togglePlayback() {
    guard case let .recorded(isPlaying) = state, let take else { return }
    if isPlaying {
      playback.stop()
      state = .recorded(isPlaying: false)
    } else if playback.play(take, loops: false, duration: nil, onFinish: { state = .recorded(isPlaying: false) }) {
      state = .recorded(isPlaying: true)
    }
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
