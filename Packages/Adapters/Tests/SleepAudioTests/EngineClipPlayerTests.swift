import AVFoundation
import Foundation
import SleepCore
import Testing
@testable import SleepAudio

/// The engine player on the simulator: a generated clip loads with its length,
/// plays to its end, pauses, reports interruptions, and gets its boost.
@MainActor
@Suite(.serialized)
struct EngineClipPlayerTests {
  /// A mono 440 Hz tone at `amplitude`, `seconds` long, as a CAF file.
  private func tone(seconds: Double, amplitude: Float = 0.25) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).caf")
    let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
    let frames = AVAudioFrameCount(seconds * 44100)
    let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
    buffer.frameLength = frames
    let samples = try #require(buffer.floatChannelData?[0])
    for index in 0..<Int(frames) {
      samples[index] = amplitude * sin(2 * .pi * 440 * Float(index) / 44100)
    }
    let file = try AVAudioFile(forWriting: url, settings: format.settings)
    try file.write(from: buffer)
    return url
  }

  @Test func loadsAndReportsTheLengthAndBoost() throws {
    let url = try tone(seconds: 0.5, amplitude: 0.354)
    defer { try? FileManager.default.removeItem(at: url) }
    let player = EngineClipPlayer()
    defer { player.stop() }
    let length = try player.load(url)
    #expect(abs(length - 0.5) < 0.01)
    #expect(abs(player.boostDB - 6.02) < 0.1) // half of −3 dBFS: +6 dB
  }

  @Test func playsToTheEndOfTheSpanThenFinishes() async throws {
    let url = try tone(seconds: 1)
    defer { try? FileManager.default.removeItem(at: url) }
    let player = EngineClipPlayer()
    defer { player.stop() }
    _ = try player.load(url)
    var finished = false
    try player.play(from: 0.2, for: 0.3) { finished = true }
    #expect(player.isPlaying)
    for _ in 0..<40 where !finished {
      try await Task.sleep(for: .milliseconds(100))
    }
    #expect(finished)
    #expect(!player.isPlaying)
    #expect(abs(player.position - 0.5) < 0.01)
  }

  @Test func pauseKeepsThePositionAndNeverFinishes() async throws {
    let url = try tone(seconds: 2)
    defer { try? FileManager.default.removeItem(at: url) }
    let player = EngineClipPlayer()
    defer { player.stop() }
    _ = try player.load(url)
    var finished = false
    try player.play(from: 0, for: 0.4) { finished = true }
    try await Task.sleep(for: .milliseconds(150))
    player.pause()
    let paused = player.position
    #expect(paused > 0.05 && paused < 0.4)
    try await Task.sleep(for: .milliseconds(500))
    #expect(!finished && player.position == paused)
  }

  @Test func reportsAnInterruptionWhilePlaying() async throws {
    let url = try tone(seconds: 2)
    defer { try? FileManager.default.removeItem(at: url) }
    let player = EngineClipPlayer()
    defer { player.stop() }
    _ = try player.load(url)
    var interrupted = false
    player.onInterruption = { interrupted = true }
    try player.play(from: 0, for: 2) {}
    NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil)
    for _ in 0..<20 where !interrupted {
      try await Task.sleep(for: .milliseconds(50))
    }
    #expect(interrupted && !player.isPlaying)
  }

  @Test func silentClipsGetNoBoost() throws {
    let url = try tone(seconds: 0.2, amplitude: 0)
    defer { try? FileManager.default.removeItem(at: url) }
    let player = EngineClipPlayer()
    defer { player.stop() }
    _ = try player.load(url)
    #expect(player.boostDB == 0)
  }
}
