import Foundation
import SleepAudioKit
import SleepCore
import SleepDomain

/// Capture, analysis, clip playback and the Snore Interrupter's audio: the
/// shared SleepAudioKit (SleepGuard uses the same), conformed to the ports.
/// The shell builds them through these factories.
public enum SleepAudioAdapter {
  @MainActor
  public static func makeClipPlayer() -> any ClipPlayerPort {
    ClipPlayerEngine()
  }

  /// Clip waveforms read from the files.
  public static func makeClipWaveformSource() -> any ClipWaveformSourcePort {
    ClipWaveform()
  }

  /// The Snore Interrupter's player at night: full volume, `nudge` (a
  /// haptic) now and every 2 s while it plays.
  @MainActor
  public static func makeMelodyPlayer(nudge: @escaping @MainActor () -> Void) -> any MelodyPlayerPort {
    MelodyPlayback(nudge: nudge)
  }

  /// The picker's and the recorder's preview: quieter, no nudge.
  @MainActor
  public static func makePreviewPlayer() -> any MelodyPlayerPort {
    MelodyPlayback(volume: 0.8, nudge: nil)
  }

  /// Recordings someone made, kept in `directory`; built-ins from `SleepMelodies`.
  @MainActor
  public static func makeMelodyStore(directory: URL) -> any MelodyStorePort {
    MelodyFiles(directory: directory)
  }

  @MainActor
  public static func makeMelodyRecorder() -> any MelodyRecorderPort {
    MelodyRecording()
  }

  /// Microphone capture; event clips are written to `clipsDirectory`.
  @MainActor
  public static func makeAudioCapture(clipsDirectory: URL) -> any AudioCapturePort {
    CaptureEngine(clipsDirectory: clipsDirectory)
  }

  #if DEBUG
  /// Debug only: a snore-like clip, so sample nights have something to play.
  public static func writeSampleClip(to url: URL, seconds: TimeInterval, intensity: SnoreIntensity) throws {
    try SampleClip.write(to: url, seconds: seconds, intensity: intensity)
  }
  #endif
}
