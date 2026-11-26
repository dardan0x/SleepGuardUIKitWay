import AVFoundation
import Foundation
import SleepDomain
import Testing
@testable import SleepAudio

/// The capture's buffer work and clip files, on generated audio: the
/// simulator's microphone can't be driven from a test, so the engine itself
/// is checked on a device (F7 tracker).
@Suite(.serialized)
struct CaptureTests {
  private static let rate = 44100.0

  /// A mono tone at `hz` and `amplitude`, `frames` long; silence at 0 Hz.
  private func tone(hz: Float, amplitude: Float = 0.5, frames: Int = 1024) throws -> AVAudioPCMBuffer {
    let format = try #require(AVAudioFormat(standardFormatWithSampleRate: Self.rate, channels: 1))
    let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)))
    buffer.frameLength = AVAudioFrameCount(frames)
    let samples = try #require(buffer.floatChannelData?[0])
    for index in 0..<frames {
      samples[index] = hz == 0 ? 0 : amplitude * sin(2 * .pi * hz * Float(index) / Float(Self.rate))
    }
    return buffer
  }

  private func temporaryURL(_ ext: String) -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
  }

  @Test func levelsOfAToneAreItsRMSAndPeak() throws {
    let processor = CaptureProcessor()
    let time = Date(timeIntervalSince1970: 100)
    let sample = try processor.process(tone(hz: 441, amplitude: 0.5, frames: 4410), at: time)
    #expect(sample.time == time)
    #expect(abs(sample.db - -9.03) < 0.05) // 0.5 / √2
    #expect(abs(sample.peakDB - -6.02) < 0.05)
  }

  @Test func silenceIsFarBelowAnySound() throws {
    let sample = try CaptureProcessor().process(tone(hz: 0), at: .now)
    #expect(sample.db < -100)
    #expect(sample.peakDB < -100)
  }

  /// SleepCore's score on this transform: snore-band tones high, a whistle low.
  @Test func aSnoreBandToneScoresHighAndAHighToneLow() throws {
    let processor = CaptureProcessor()
    try processor.begin(format: tone(hz: 200).format, computesSpectrum: true)
    defer { processor.end() }
    #expect(try processor.process(tone(hz: 200), at: .now).spectralScore > 0.9)
    #expect(try processor.process(tone(hz: 3000), at: .now).spectralScore < 0.1)
  }

  /// The FFT runs only when its score is logged (F13-T6).
  @Test func withoutTheRawLogTheSpectrumIsSkipped() throws {
    let processor = CaptureProcessor()
    try processor.begin(format: tone(hz: 200).format, computesSpectrum: false)
    defer { processor.end() }
    #expect(try processor.process(tone(hz: 200), at: .now).spectralScore == 0)
  }

  @Test func confidencesStartAtZeroWithTheClassifierAttached() throws {
    let processor = CaptureProcessor()
    let buffer = try tone(hz: 200, frames: 4410)
    processor.begin(format: buffer.format, computesSpectrum: true)
    defer { processor.end() }
    let sample = processor.process(buffer, at: .now)
    #expect(sample.snoreConfidence == 0)
    #expect(sample.speechConfidence == 0)
  }

  @Test func aClipHoldsTheBuffersWrittenWhileOpen() throws {
    let url = temporaryURL("caf")
    defer { try? FileManager.default.removeItem(at: url) }
    let processor = CaptureProcessor()
    let buffer = try tone(hz: 200, frames: 4410)
    _ = processor.process(buffer, at: .now) // before: not in the clip
    try processor.writeClip(to: AVAudioFile(forWriting: url, settings: buffer.format.settings))
    _ = processor.process(buffer, at: .now)
    _ = processor.process(buffer, at: .now)
    processor.closeClip()
    _ = processor.process(buffer, at: .now) // after: not in the clip
    #expect(try AVAudioFile(forReading: url).length == 8820)
  }

  @Test func aClipCompressesToASmallerM4AOfTheSameLength() async throws {
    let raw = temporaryURL("caf")
    let compressed = temporaryURL("m4a")
    defer {
      try? FileManager.default.removeItem(at: raw)
      try? FileManager.default.removeItem(at: compressed)
    }
    let buffer = try tone(hz: 200, frames: Int(Self.rate) * 2)
    do {
      let file = try AVAudioFile(forWriting: raw, settings: buffer.format.settings)
      try file.write(from: buffer)
    }
    #expect(await ClipCompressor.compress(from: raw, to: compressed))
    let rawSize = try #require(try FileManager.default.attributesOfItem(atPath: raw.path)[.size] as? Int)
    let size = try #require(try FileManager.default.attributesOfItem(atPath: compressed.path)[.size] as? Int)
    #expect(size < rawSize / 10)
    let duration = try await AVURLAsset(url: compressed).load(.duration).seconds
    #expect(abs(duration - 2) < 0.1)
  }

  @MainActor
  @Test func aClipNeedsTheCaptureToBeListening() {
    let capture = EngineAudioCapture(clipsDirectory: FileManager.default.temporaryDirectory)
    #expect(throws: AudioCaptureError.notListening) { try capture.startClip(id: UUID()) }
  }
}
