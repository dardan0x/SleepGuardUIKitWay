import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
@testable import RecordingFeature

/// The bedside clock's state owner over a fake capture: start, live values,
/// a failed start, the early-stop rule, and the night it hands back.
struct LiveRecordingModelTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  private func sample(_ seconds: TimeInterval, db: Float = -35, snore: Float = 0.6) -> CaptureSample {
    CaptureSample(
      time: start.addingTimeInterval(seconds), db: db, peakDB: db, spectralScore: 0,
      snoreConfidence: snore, speechConfidence: 0)
  }

  @Test func runStartsListeningAndFollowsTheSnapshots() async throws {
    let capture = FakeAudioCapture()
    let model = LiveRecordingModel(capture: capture, start: start)
    #expect(model.phase == .starting)
    #expect(model.db == AudioLevels.floorDB && model.snoreState == .none && model.eventCount == 0)
    let running = Task { await model.run() }
    try await waitUntil { model.phase == .recording }
    capture.send(sample(0.05, db: -30))
    try await waitUntil { model.snapshot != nil }
    #expect(model.db == -30)
    #expect(model.snoreState == .light)
    _ = await model.stop(at: start.addingTimeInterval(1))
    await running.value
    #expect(model.phase == .stopped)
  }

  @Test func aStartThatFailsShowsAsFailed() async {
    let capture = FakeAudioCapture()
    capture.startError = .noMicrophone
    let model = LiveRecordingModel(capture: capture, start: start)
    await model.run()
    #expect(model.phase == .failed)
  }

  @Test func stoppingBeforeTheMinimumIsTooShort() {
    let model = LiveRecordingModel(capture: FakeAudioCapture(), start: start)
    #expect(model.isTooShort(at: start.addingTimeInterval(Night.minimumSaveDuration - 1)))
    #expect(!model.isTooShort(at: start.addingTimeInterval(Night.minimumSaveDuration)))
  }

  @Test func stopReturnsTheNightWithItsEvents() async throws {
    let capture = FakeAudioCapture()
    let model = LiveRecordingModel(capture: capture, start: start)
    let running = Task { await model.run() }
    try await waitUntil { model.phase == .recording }
    for tick in 1...60 { // 3 s of snoring
      capture.send(sample(Double(tick) * 0.05))
    }
    // The event's clip starts while still listening, as on a real night.
    try await waitUntil { capture.calls.contains { if case .startClip = $0 { true } else { false } } }
    let night = await model.stop(at: start.addingTimeInterval(3))
    await running.value
    #expect(night.start == start && night.duration == 3)
    #expect(night.events.count == 1)
    #expect(night.events.first?.clipFileName?.hasSuffix(".m4a") == true)
  }

  /// Polls a main-actor condition the model reaches through its own tasks.
  private func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0..<200 where !condition() {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(condition())
  }
}
