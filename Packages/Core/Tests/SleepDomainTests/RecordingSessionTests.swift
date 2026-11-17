import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

/// The night a `RecordingSession` builds from scripted 50 ms samples.
///
/// The event cases are SleepGuard's `DetectionCharacterizationTests`, with the
/// same samples and the same expected lines: same shared rules, same night.
@MainActor
struct RecordingSessionTests {
  // MARK: - Snore events (SleepGuard's cases)

  @Test func sustainedSnoringBecomesOneEvent() async throws {
    let harness = try await Harness()
    await harness.silence(1)
    await harness.snore(3, db: -35, confidence: 0.6)
    await harness.silence(11)
    #expect(await harness.summary() == [
      "snoring light t=1.05 d=2.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-3.00]",
    ])
  }

  @Test func twoSnoringSamplesAreIgnored() async throws {
    let harness = try await Harness()
    await harness.snore(0.1, db: -35, confidence: 0.6)
    await harness.silence(11)
    #expect(await harness.summary() == [])
  }

  @Test(arguments: [(DetectionSensitivity.medium, false), (.high, true)])
  func minimumDurationDependsOnSensitivity(sensitivity: DetectionSensitivity, kept: Bool) async throws {
    let harness = try await Harness(sensitivity: sensitivity)
    await harness.snore(0.8, db: -35, confidence: 0.6)
    await harness.silence(11)
    #expect(await harness.summary().count == (kept ? 1 : 0))
  }

  @Test(arguments: [(Float(0.4), false), (0.6, true)])
  func shortEventsNeedHighConfidence(confidence: Float, kept: Bool) async throws {
    let harness = try await Harness()
    await harness.snore(2, db: -35, confidence: confidence)
    await harness.silence(11)
    #expect(await harness.summary().count == (kept ? 1 : 0))
  }

  @Test func briefPauseSplitsBurstsButNotTheEvent() async throws {
    let harness = try await Harness()
    await harness.snore(2, db: -35, confidence: 0.6)
    await harness.silence(2)
    await harness.snore(2, db: -35, confidence: 0.6)
    await harness.silence(11)
    #expect(await harness.summary() == [
      "snoring light t=0.05 d=5.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-2.00, 4.10-6.00]",
    ])
  }

  @Test func intensityKeepsTheLoudestTier() async throws {
    let harness = try await Harness()
    await harness.snore(1.5, db: -35, confidence: 0.6)
    await harness.snore(1.5, db: -15, confidence: 0.6)
    await harness.silence(11)
    #expect(await harness.summary() == [
      "snoring loud t=0.05 d=2.95 avg=-24.7 peak=-15.0 conf=0.60 bursts=[0.00-3.00]",
    ])
  }

  @Test func stopFinalizesTheOpenEvent() async throws {
    let harness = try await Harness()
    await harness.snore(4, db: -35, confidence: 0.6)
    _ = await harness.stop()
    #expect(await harness.summary() == [
      "snoring light t=0.05 d=3.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-3.95]",
    ])
  }

  // MARK: - Sleep talking (SleepGuard's cases)

  @Test func speechBecomesASleepTalkingEvent() async throws {
    let harness = try await Harness(sleepTalking: true)
    await harness.speech(2, db: -40, confidence: 0.8)
    await harness.silence(11)
    #expect(await harness.summary() == [
      "sleepTalking quiet t=0.05 d=1.95 avg=-40.0 peak=-40.0 conf=0.00 bursts=[]",
    ])
  }

  @Test func snoringEndsTheSpeechEventImmediately() async throws {
    let harness = try await Harness(sleepTalking: true)
    await harness.speech(2, db: -40, confidence: 0.8)
    await harness.snore(2, db: -35, confidence: 0.6)
    await harness.silence(11)
    #expect(await harness.summary() == [
      "sleepTalking quiet t=0.05 d=2.00 avg=-40.0 peak=-40.0 conf=0.00 bursts=[]",
      "snoring light t=2.05 d=1.95 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-2.00]",
    ])
  }

  @Test func speechIsIgnoredWhenSleepTalkingIsOff() async throws {
    let harness = try await Harness(sleepTalking: false)
    await harness.speech(2, db: -40, confidence: 0.8)
    await harness.silence(11)
    #expect(await harness.summary() == [])
  }

  // MARK: - Clips

  @Test func aKeptEventGetsItsCompressedClip() async throws {
    let harness = try await Harness()
    await harness.snore(3, db: -35, confidence: 0.6)
    await harness.silence(11)
    let draft = await harness.stop()
    let event = try #require(draft.events.first)
    #expect(event.clipFileName == "\(event.id.uuidString).m4a")
    #expect(harness.capture.calls == [
      .start, .startClip(event.id), .closeClip, .compressClip("\(event.id.uuidString).caf"), .stop,
    ])
  }

  @Test func aFailedCompressionKeepsTheRawClip() async throws {
    let harness = try await Harness()
    harness.capture.compresses = false
    await harness.snore(3, db: -35, confidence: 0.6)
    let draft = await harness.stop()
    let event = try #require(draft.events.first)
    #expect(event.clipFileName == "\(event.id.uuidString).caf")
  }

  @Test func aDiscardedEventLosesItsClip() async throws {
    let harness = try await Harness()
    await harness.snore(0.8, db: -35, confidence: 0.6)
    await harness.silence(11)
    _ = await harness.stop()
    #expect(harness.capture.calls.contains(.discardClip))
    #expect(!harness.capture.calls.contains(.closeClip))
  }

  // MARK: - The night and the screen

  @Test func theDraftKeepsTheLevelsAndBecomesTheNight() async throws {
    let harness = try await Harness()
    await harness.silence(1) // -60
    await harness.snore(1, db: -40, confidence: 0)
    let draft = await harness.stop()
    #expect(draft.sampleCount == 40)
    #expect(draft.averageDB == -50)
    #expect(draft.peakDB == -40)
    let night = draft.night(end: Sample.at(2))
    #expect(night.id == draft.id && night.start == Sample.start && night.duration == 2)
    #expect(night.peakDB == -40 && night.endReason == .stopped)
  }

  @Test func samplesFromTheCaptureStreamReachTheNightBeforeItEnds() async throws {
    let capture = FakeAudioCapture()
    let session = RecordingSession(capture: capture, start: Sample.start)
    _ = try await session.start()
    for tick in 1...80 {
      capture.send(Harness.sample(at: Double(tick) * 0.05, db: -35, snore: 0.6, speech: 0))
    }
    let draft = await session.stop(at: Sample.at(4))
    #expect(draft.sampleCount == 80)
    #expect(draft.events.count == 1)
  }

  @Test func snapshotsComeAtMostFiveTimesASecond() async throws {
    let capture = FakeAudioCapture()
    let session = RecordingSession(capture: capture, start: Sample.start)
    let snapshots = try await session.start()
    let reader = Task {
      var seen: [LiveSnapshot] = []
      for await snapshot in snapshots {
        seen.append(snapshot)
      }
      return seen
    }
    for tick in 1...20 { // 1 s
      await session.ingest(Harness.sample(at: Double(tick) * 0.05, db: -35, snore: 0.6, speech: 0))
      await Task.yield()
    }
    _ = await session.stop(at: Sample.at(1))
    let seen = await reader.value
    #expect(!seen.isEmpty && seen.count <= 5)
    #expect(seen.last?.snoreState == .light)
    #expect(zip(seen, seen.dropFirst()).allSatisfy { $1.time.timeIntervalSince($0.time) >= 0.2 - 1e-9 })
  }

  // MARK: - Checkpoints

  @Test func aSavedEventIsCheckpointedAtOnce() async throws {
    let checkpoints = FakeRecordingCheckpointStore()
    let harness = try await Harness(checkpoints: checkpoints)
    await harness.snore(3, db: -35, confidence: 0.6)
    await harness.silence(11)
    let night = try #require(await checkpoints.night)
    #expect(night.events.count == 1)
    #expect(night.start == Sample.start)
  }

  /// A quiet night is kept too: the first sample, then every 2 minutes.
  @Test func aQuietNightIsCheckpointedEveryTwoMinutes() async throws {
    let checkpoints = FakeRecordingCheckpointStore()
    let session = RecordingSession(capture: FakeAudioCapture(), checkpoints: checkpoints, start: Sample.start)
    _ = try await session.start()
    for second in 0...250 {
      await session.receive(Harness.sample(at: Double(second), db: -60, snore: 0, speech: 0))
    }
    #expect(await checkpoints.saved.map { $0.end.timeIntervalSince(Sample.start) } == [0, 120, 240])
  }

  @Test func stopCheckpointsTheWholeNightWithItsReason() async throws {
    let checkpoints = FakeRecordingCheckpointStore()
    let harness = try await Harness(checkpoints: checkpoints)
    await harness.snore(4, db: -35, confidence: 0.6)
    _ = await harness.session.stop(at: Sample.at(600), endReason: .lowBattery)
    let night = try #require(await checkpoints.night)
    #expect(night.duration == 600 && night.endReason == .lowBattery)
    #expect(night.events.first?.clipFileName?.hasSuffix(".m4a") == true)
  }

  // MARK: - Snore Interrupter (SleepGuard's cases)

  /// The melody pauses the mic; snoring resumes within the 3 s breathing
  /// delay, so the first gap counts as snoring and the event spans it.
  /// Resumed snoring plays the melody again; after the second gap nothing
  /// resumes, so the event ends at the last snoring sample before it.
  @Test func melodyGapWithResumedSnoringExtendsTheEvent() async throws {
    let harness = try await Harness(melody: .pausesMic)
    await harness.snore(2, db: -35, confidence: 0.6)
    await harness.silence(5)
    harness.interrupter?.stop()
    await harness.silence(1)
    await harness.snore(2, db: -35, confidence: 0.6)
    await harness.silence(3)
    harness.interrupter?.stop()
    await harness.silence(11)
    #expect(await harness.summary(gaps: true) == [
      "snoring light t=0.05 d=8.10 avg=-35.0 peak=-35.0 conf=0.60 bursts=[0.00-0.10, 8.10-8.10]",
      "gap t=0.15 d=6.85 resumed=true",
      "gap t=8.15 d=4.85 resumed=false",
    ])
    #expect(harness.player.plays.count == 2)
    #expect(harness.capture.calls.filter { $0 == .pause }.count == 2)
    #expect(harness.capture.calls.filter { $0 == .resume }.count == 2)
  }

  /// No snoring within the breathing delay: the event is cut back to before
  /// the melody (0.10 s, under every minimum) and discarded; the gap stays.
  @Test func melodyGapWithoutSnoringDiscardsTheEvent() async throws {
    let harness = try await Harness(melody: .pausesMic)
    await harness.snore(2, db: -35, confidence: 0.6)
    await harness.silence(5)
    harness.interrupter?.stop()
    await harness.silence(11)
    #expect(await harness.summary(gaps: true) == ["gap t=0.15 d=6.85 resumed=false"])
  }

  /// With the mic still live, sustained silence stops the melody, but only
  /// after its 4 s minimum play time.
  @Test func sustainedSilenceStopsTheMelodyAfterItsMinimumPlayTime() async throws {
    let harness = try await Harness(melody: .keepsMicLive)
    await harness.snore(1, db: -35, confidence: 0.6)
    await harness.silence(6)
    #expect(await harness.summary(gaps: true) == ["gap t=0.15 d=4.00 resumed=false"])
    #expect(harness.player.stops == 1)
  }

  /// The melody's own end (its length) records the gap the same way, and the
  /// night's end stops a melody still playing.
  @Test func theMelodyEndingByItselfOrWithTheNightLeavesAGap() async throws {
    let harness = try await Harness(melody: .pausesMic)
    await harness.snore(1, db: -35, confidence: 0.6)
    await harness.silence(2)
    harness.player.finish()
    await harness.silence(11)
    await harness.snore(1, db: -35, confidence: 0.6)
    let draft = await harness.stop()
    #expect(draft.recordingGaps.map(\.startOffset).count == 2)
    #expect(harness.capture.isPaused == false)
  }

  @Test func theSnapshotSaysWhileTheMelodyPlays() async throws {
    let harness = try await Harness(melody: .pausesMic)
    await harness.snore(1, db: -35, confidence: 0.6)
    #expect(await harness.snapshot { $0.melodyPlaying }?.melodyPlaying == true)
    harness.interrupter?.stop()
    await harness.silence(0.05)
    #expect(await harness.snapshot { !$0.melodyPlaying }?.melodyPlaying == false)
  }

  @Test func theRawLogNamesTheMode() async throws {
    let rawLog = FakeRawLogWriter()
    let capture = FakeAudioCapture()
    let interrupter = SnoreInterrupter(
      mode: .thirtySeconds, melodyID: 6, player: FakeMelodyPlayer(), store: FakeMelodyStore(), capture: capture)
    let session = RecordingSession(
      capture: capture, settings: .init(preserveRawAudio: true), rawLog: rawLog, interrupter: interrupter)
    _ = try await session.start()
    #expect(await rawLog.metadata?.snoreInterrupterMode == "thirtySeconds")
  }

  @Test func aStartFailureIsThrown() async throws {
    let capture = FakeAudioCapture()
    capture.startError = .noMicrophone
    let session = RecordingSession(capture: capture)
    await #expect(throws: AudioCaptureError.noMicrophone) { _ = try await session.start() }
  }
}

// MARK: - Harness

/// SleepGuard's detection harness on a `RecordingSession`: one sample per
/// 50 ms from an integer tick, and a wait for the engine after each, as the
/// real spacing allows.
@MainActor
final class Harness {
  /// The Snore Interrupter, as SleepGuard's harness scripts it: the real one
  /// pauses the microphone; `keepsMicLive` sends samples through anyway.
  enum Melody { case pausesMic, keepsMicLive }

  let capture: FakeAudioCapture
  let player: FakeMelodyPlayer
  let session: RecordingSession
  let interrupter: SnoreInterrupter?
  private(set) var latest: LiveSnapshot?
  private let clock: TickClock
  private let micStaysLive: Bool
  private var stopped: RecordingDraft?
  private var snapshotsTask: Task<Void, Never>?

  init(
    sensitivity: DetectionSensitivity = .medium,
    sleepTalking: Bool = false,
    checkpoints: FakeRecordingCheckpointStore? = nil,
    melody: Melody? = nil) async throws
  {
    micStaysLive = melody == .keepsMicLive
    let capture = FakeAudioCapture()
    let player = FakeMelodyPlayer()
    let clock = TickClock()
    self.capture = capture
    self.player = player
    self.clock = clock
    interrupter = melody.map { _ in
      SnoreInterrupter(
        mode: .always, melodyID: 6, player: player, store: FakeMelodyStore(), capture: capture,
        now: { Sample.at(Double(clock.tick) * 0.05) })
    }
    session = RecordingSession(
      capture: capture, settings: .init(sensitivity: sensitivity, detectSleepTalking: sleepTalking),
      checkpoints: checkpoints, interrupter: interrupter, start: Sample.start)
    let snapshots = try await session.start()
    snapshotsTask = Task { [weak self] in
      for await snapshot in snapshots {
        self?.latest = snapshot
      }
    }
  }

  /// The latest snapshot once one matches: the harness reads the stream on
  /// its own task, a moment behind the session.
  func snapshot(where matches: (LiveSnapshot) -> Bool) async -> LiveSnapshot? {
    for _ in 0..<1000 {
      if let latest, matches(latest) { return latest }
      await Task.yield()
    }
    return latest
  }

  private var tick: Int {
    get { clock.tick }
    set { clock.tick = newValue }
  }

  static func sample(at seconds: TimeInterval, db: Float, snore: Float, speech: Float) -> CaptureSample {
    CaptureSample(
      time: Sample.at(seconds), db: db, peakDB: db, spectralScore: 0, snoreConfidence: snore, speechConfidence: speech)
  }

  func snore(_ seconds: Double, db: Float, confidence: Float) async {
    await feed(seconds, db: db, snore: confidence, speech: 0)
  }

  func speech(_ seconds: Double, db: Float, confidence: Float) async {
    await feed(seconds, db: db, snore: 0, speech: confidence)
  }

  func silence(_ seconds: Double) async {
    await feed(seconds, db: -60, snore: 0, speech: 0)
  }

  /// Ends the night at the last sample, as SleepGuard's clock did.
  func stop() async -> RecordingDraft {
    let draft = await session.stop(at: Sample.at(Double(tick) * 0.05))
    stopped = draft
    return draft
  }

  private func feed(_ seconds: Double, db: Float, snore: Float, speech: Float) async {
    for _ in 0..<Int((seconds / 0.05).rounded()) {
      tick += 1
      // A paused microphone sends nothing (SleepGuard dropped these samples).
      guard micStaysLive || !capture.isPaused else { continue }
      await session.ingest(Self.sample(at: Double(tick) * 0.05, db: db, snore: snore, speech: speech))
      await session.waitUntilProcessed()
      await Task.yield()
    }
  }

  /// One line per event in time order, in SleepGuard's harness format; then
  /// one per gap with `gaps`.
  func summary(gaps: Bool = false) async -> [String] {
    let draft: RecordingDraft = if let stopped { stopped } else { await session.draft }
    let events = draft.events.sorted { $0.start < $1.start }
    let eventLines = events.map { event in
      let bursts = event.bursts.map { "\(f($0.startOffset))-\(f($0.endOffset))" }.joined(separator: ", ")
      return "\(event.category.rawValue) \(event.intensity.rawValue) t=\(f(event.start.timeIntervalSince(Sample.start))) "
        + "d=\(f(event.duration)) avg=\(f(event.averageDB, 1)) peak=\(f(event.peakDB, 1)) "
        + "conf=\(f(event.averageConfidence)) bursts=[\(bursts)]"
    }
    guard gaps else { return eventLines }
    return eventLines + draft.recordingGaps.map {
      "gap t=\(f($0.startOffset)) d=\(f($0.duration)) resumed=\($0.snoringResumed)"
    }
  }

  private func f(_ value: Double, _ digits: Int = 2) -> String {
    String(format: "%.\(digits)f", value)
  }
}

/// The harness's sample clock, read by the interrupter when a melody stops.
@MainActor
final class TickClock {
  var tick = 0
}
