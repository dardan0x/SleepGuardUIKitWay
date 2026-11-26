import Foundation
import SleepAudioKit
import SleepDomain

// The kit's types already have the ports' shape; these only say so.

extension CaptureEngine: AudioCapture {}

extension ClipPlayerEngine: ClipPlayer {}

extension MelodyPlayback: MelodyPlayer {}

extension MelodyRecording: MelodyRecorder {}

extension MelodyFiles: MelodyStore {}

extension ClipWaveform: ClipWaveformSource {
  /// The player's 300 bars.
  public func waveform(of url: URL, duration: TimeInterval?) async -> [Float] {
    await waveform(of: url, duration: duration, pointCount: 300)
  }
}
