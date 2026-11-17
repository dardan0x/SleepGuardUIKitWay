import Foundation
import SleepDomain

/// Capture, analysis and clip playback (AVFoundation). The adapters' types are
/// internal; the shell builds them through these factories.
public enum SleepAudio {
  @MainActor
  public static func makeClipPlayer() -> any ClipPlayer {
    EngineClipPlayer()
  }

  /// Clip waveforms read from the files.
  public static func makeClipWaveformSource() -> any ClipWaveformSource {
    FileWaveformSource()
  }

  /// The Snore Interrupter's player at night: full volume, `nudge` (a
  /// haptic) now and every 2 s while it plays.
  @MainActor
  public static func makeMelodyPlayer(nudge: @escaping @MainActor () -> Void) -> any MelodyPlayer {
    AVMelodyPlayer(nudge: nudge)
  }

  /// The picker's and the recorder's preview: quieter, no nudge.
  @MainActor
  public static func makePreviewPlayer() -> any MelodyPlayer {
    AVMelodyPlayer(volume: 0.8, nudge: nil)
  }

  /// Recordings someone made, kept in `directory`; built-ins from `SleepMelodies`.
  @MainActor
  public static func makeMelodyStore(directory: URL) -> any MelodyStore {
    FileMelodyStore(directory: directory)
  }

  @MainActor
  public static func makeMelodyRecorder() -> any MelodyRecorder {
    AVMelodyRecorder()
  }

  /// Microphone capture; event clips are written to `clipsDirectory`.
  @MainActor
  public static func makeAudioCapture(clipsDirectory: URL) -> any AudioCapturePort {
    EngineAudioCapture(clipsDirectory: clipsDirectory)
  }
}
