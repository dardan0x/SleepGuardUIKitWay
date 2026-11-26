import AVFoundation
import SleepDomain
import SleepLogging

/// `MelodyPlayer` over AVAudioPlayer, with SleepGuard's haptic nudge every
/// 2 s while it plays (the shell supplies the nudge: haptics are UIKit's).
/// At night it plays in the capture's `.playAndRecord` session, which sends
/// it to the speaker; capture is paused meanwhile, so there is no feedback.
/// The picker's and the recorder's previews use it too.
@MainActor
final class AVMelodyPlayer: NSObject, MelodyPlayer {
  static let nudgeInterval: Duration = .seconds(2)

  /// Full volume at night; the picker's preview is quieter (SleepGuard: 0.8).
  private let volume: Float
  private let nudge: (@MainActor () -> Void)?
  private var player: AVAudioPlayer?
  private var onFinish: (@MainActor () -> Void)?
  private var timers: [Task<Void, Never>] = []

  init(volume: Float = 1, nudge: (@MainActor () -> Void)?) {
    self.volume = volume
    self.nudge = nudge
  }

  func play(_ url: URL, loops: Bool, duration: TimeInterval?, onFinish: @escaping @MainActor () -> Void) -> Bool {
    stop()
    do {
      let session = AVAudioSession.sharedInstance()
      if session.category != .playAndRecord {
        // Not recording (the picker's preview): a plain playback session.
        try session.setCategory(.playback)
      }
      try session.setActive(true)
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = volume
      player.numberOfLoops = loops ? -1 : 0
      player.delegate = self
      guard player.prepareToPlay(), player.play() else { return false }
      self.player = player
      self.onFinish = onFinish
    } catch {
      Log.audio.error("Melody didn't play: \(error.localizedDescription, privacy: .public)")
      return false
    }
    if let duration {
      timers.append(Task { [weak self] in
        try? await Task.sleep(for: .seconds(duration))
        guard !Task.isCancelled else { return }
        self?.finished()
      })
    }
    if let nudge {
      nudge()
      timers.append(Task {
        while !Task.isCancelled {
          try? await Task.sleep(for: Self.nudgeInterval)
          guard !Task.isCancelled else { return }
          nudge()
        }
      })
    }
    return true
  }

  func stop() {
    onFinish = nil
    timers.forEach { $0.cancel() }
    timers = []
    player?.delegate = nil
    player?.stop()
    player = nil
  }

  /// Its length is up or the file ended: stop, then tell once.
  private func finished() {
    let done = onFinish
    stop()
    done?()
  }
}

extension AVMelodyPlayer: AVAudioPlayerDelegate {
  nonisolated func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
    Task { @MainActor in self.finished() }
  }
}
