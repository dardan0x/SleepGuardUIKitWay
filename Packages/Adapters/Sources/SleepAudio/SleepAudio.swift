import SleepDomain

/// Capture, analysis and clip playback (AVFoundation). The adapters' types are
/// internal; the shell builds them through these factories.
public enum SleepAudio {
  @MainActor
  public static func makeClipPlayer() -> any ClipPlayer {
    EngineClipPlayer()
  }
}
