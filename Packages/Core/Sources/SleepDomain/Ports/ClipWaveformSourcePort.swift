import Foundation

/// A clip's waveform for the player: its audio as 0...1 bars (SleepCore's
/// `WaveformAccumulator`). Implemented by `SleepAudioAdapter`, which reads the file.
public protocol ClipWaveformSourcePort: Sendable {
  /// The bars of the file at `url`, over its first `duration` seconds (`nil`:
  /// all of it). Empty when the file can't be read.
  func waveform(of url: URL, duration: TimeInterval?) async -> [Float]
}
