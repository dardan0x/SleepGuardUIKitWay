import Foundation
import SleepAudioKit
import SleepDomain

// The kit's types already have the ports' shape; these only say so.

extension CaptureEngine: AudioCapturePort {}

extension ClipPlayerEngine: ClipPlayerPort {}

extension MelodyPlayback: MelodyPlayerPort {}

extension MelodyRecording: MelodyRecorderPort {}

extension MelodyFiles: MelodyStorePort {}

extension ClipWaveform: ClipWaveformSourcePort {
  /// The player's 300 bars.
  public func waveform(of url: URL, duration: TimeInterval?) async -> [Float] {
    await waveform(of: url, duration: duration, pointCount: 300)
  }
}
