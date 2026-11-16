import AVFoundation
import Foundation
import Testing
@testable import SleepAudio

/// The waveform read from a generated clip: 300 bars scaled to 1, the loud
/// half louder, a duration limit honoured, an unreadable file empty.
struct FileWaveformSourceTests {
  /// One second quiet, one second loud, 440 Hz.
  private func clip() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).caf")
    let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
    let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 88200))
    buffer.frameLength = 88200
    let samples = try #require(buffer.floatChannelData?[0])
    for index in 0..<88200 {
      let amplitude: Float = index < 44100 ? 0.1 : 0.8
      samples[index] = amplitude * sin(2 * .pi * 440 * Float(index) / 44100)
    }
    try AVAudioFile(forWriting: url, settings: format.settings).write(from: buffer)
    return url
  }

  @Test func barsFollowTheLoudness() async throws {
    let url = try clip()
    defer { try? FileManager.default.removeItem(at: url) }
    let bars = await FileWaveformSource().waveform(of: url, duration: nil)
    #expect(bars.count == 300)
    #expect(bars.max() == 1)
    let quiet = bars[0..<150].reduce(0, +) / 150
    let loud = bars[150...].reduce(0, +) / 150
    #expect(loud > quiet * 5)
  }

  /// Only the first second: every bar is the quiet part, so they even out near 1.
  @Test func aDurationLimitsTheBars() async throws {
    let url = try clip()
    defer { try? FileManager.default.removeItem(at: url) }
    let bars = await FileWaveformSource().waveform(of: url, duration: 1)
    #expect(bars.count == 300)
    #expect(bars.min() ?? 0 > 0.5)
  }

  @Test func anUnreadableFileHasNoBars() async {
    #expect(await FileWaveformSource().waveform(of: URL(fileURLWithPath: "/nope.caf"), duration: nil).isEmpty)
  }
}
