import Foundation
import SleepDomain

/// Capture, analysis and clip playback (AVFoundation). The adapters' types are
/// internal; the shell builds them through these factories.
public enum SleepAudio {
  @MainActor
  public static func makeClipPlayer() -> any ClipPlayer {
    EngineClipPlayer()
  }

  /// Microphone capture; event clips are written to `clipsDirectory`.
  @MainActor
  public static func makeAudioCapture(clipsDirectory: URL) -> any AudioCapturePort {
    EngineAudioCapture(clipsDirectory: clipsDirectory)
  }
}
