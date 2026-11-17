import Foundation
import SleepCore

/// One night of recording: microphone samples in, a `RecordingDraft` out.
///
/// Each capture sample is classified (SleepCore's `SnoreClassifier` preset
/// and `SpeechClassifier`) and sent, timestamped, into the shared
/// `DetectionEngine`'s one ordered stream (ADR 0003, as in SleepGuard). The
/// engine runs the detection state machine on its own actor and hands each
/// batch of outputs back here, where they are performed in order: clips are
/// started, closed or discarded through the capture port, and events are
/// added to the draft. Compressing a clip runs beside detection, never in
/// its way.
///
/// It replaces SleepGuard's `RealtimeDetectionTracker` without the main
/// actor, SwiftData or a 50 ms loop: the samples arrive as a stream, and the
/// night in progress is a value, not an unsaved database record.
public actor RecordingSession {
  public struct Settings: Sendable, Equatable {
    public var sensitivity: DetectionSensitivity
    public var detectSleepTalking: Bool
    /// Keep the full audio and the sample log (`RawRecording`); needs a
    /// `RawLogWriter`.
    public var preserveRawAudio: Bool

    public init(sensitivity: DetectionSensitivity = .medium, detectSleepTalking: Bool = true, preserveRawAudio: Bool = false) {
      self.sensitivity = sensitivity
      self.detectSleepTalking = detectSleepTalking
      self.preserveRawAudio = preserveRawAudio
    }
  }

  /// Snapshots go out at most this often (5 Hz), by sample time.
  static let snapshotInterval: TimeInterval = 0.2
  /// A checkpoint at least this often (sample time), besides one per event,
  /// so a quiet night survives a crash too (SleepGuard: about 2 minutes).
  static let checkpointInterval: TimeInterval = 120
  /// Raw log samples are written in batches of this many (about a second).
  static let rawLogBatch = 40

  public private(set) var draft: RecordingDraft
  private let capture: any AudioCapturePort
  private let checkpoints: (any RecordingCheckpointStore)?
  private let settings: Settings
  private let rawLog: (any RawLogWriter)?
  private var rawSamples: [SnoreSample] = []
  private let snoreClassifier: SnoreClassifier
  private let speechClassifier = SpeechClassifier()
  private let engine: DetectionEngine
  private let messages: AsyncStream<DetectionEngine.Message>
  private let input: AsyncStream<DetectionEngine.Message>.Continuation
  private var engineTask: Task<Void, Never>?
  private var samplesTask: Task<Void, Never>?
  private var compressions: [Task<Void, Never>] = []
  private var snapshots: AsyncStream<LiveSnapshot>.Continuation?
  private var lastSnapshot: Date?
  private var lastCheckpoint: Date?
  private var lastSampleTime: Date?

  /// `checkpoints`: where the night in progress is kept while recording.
  /// `rawLog`: where samples go when `settings.preserveRawAudio` is on.
  public init(
    capture: any AudioCapturePort,
    settings: Settings = Settings(),
    checkpoints: (any RecordingCheckpointStore)? = nil,
    rawLog: (any RawLogWriter)? = nil,
    start: Date = Date())
  {
    self.capture = capture
    self.checkpoints = checkpoints
    self.settings = settings
    self.rawLog = settings.preserveRawAudio ? rawLog : nil
    draft = RecordingDraft(start: start)
    let classifier = SnoreClassifier.preset(settings.sensitivity)
    snoreClassifier = classifier
    engine = DetectionEngine(settings: DetectionStateMachine.Settings(
      minEventDuration: settings.sensitivity.minEventDuration,
      highConfidenceGate: classifier.highConfidenceGate,
      detectSleepTalking: settings.detectSleepTalking))
    (messages, input) = DetectionEngine.makeStream()
  }

  /// Starts listening and detecting. Returns the live snapshots (newest
  /// only, if the reader falls behind), which end when `stop` returns.
  public func start() async throws -> AsyncStream<LiveSnapshot> {
    precondition(engineTask == nil, "RecordingSession.start() called twice")
    let rawAudio = rawLog == nil ? nil : RawRecording.audioFileName(for: draft.id)
    let samples = try await capture.start(rawAudioFileName: rawAudio)
    await rawLog?.begin(night: draft.id, metadata: RawLogMetadata(
      sessionStart: draft.start, detectionSensitivity: settings.sensitivity.rawValue,
      detectSleepTalking: settings.detectSleepTalking, snoreInterrupterMode: "never"))
    let (stream, continuation) = AsyncStream.makeStream(of: LiveSnapshot.self, bufferingPolicy: .bufferingNewest(1))
    snapshots = continuation
    let engine = engine
    let messages = messages
    engineTask = Task {
      await engine.run(messages) { [weak self] batch in
        await self?.perform(batch) ?? []
      }
    }
    samplesTask = Task {
      for await sample in samples {
        await receive(sample)
      }
    }
    return stream
  }

  /// Stops listening, handles the samples still queued, finalizes an open
  /// event at `end`, waits for its clips to compress, checkpoints the whole
  /// night (kept until it is saved or discarded) and returns the draft.
  public func stop(at end: Date = Date(), endReason: Night.EndReason = .stopped) async -> RecordingDraft {
    await capture.stop()
    await samplesTask?.value
    input.yield(.finalize(at: end))
    input.finish()
    await engineTask?.value
    for compression in compressions {
      await compression.value
    }
    compressions = []
    await checkpoints?.save(draft.night(end: end, endReason: endReason))
    if let rawLog {
      await rawLog.append(rawSamples)
      rawSamples = []
      await rawLog.finish()
    }
    snapshots?.finish()
    return draft
  }

  // MARK: - Samples

  /// One sample from the capture: ingested, then a checkpoint when one is due.
  func receive(_ sample: CaptureSample) async {
    ingest(sample)
    if let rawLog, rawSamples.count >= Self.rawLogBatch {
      let batch = rawSamples
      rawSamples = []
      await rawLog.append(batch)
    }
    if lastCheckpoint.map({ sample.time.timeIntervalSince($0) >= Self.checkpointInterval }) ?? true {
      await checkpoint(at: sample.time)
    }
  }

  /// Classifies one sample and sends it to the engine. Internal so tests can
  /// script samples at exact times.
  func ingest(_ sample: CaptureSample) {
    lastSampleTime = sample.time
    draft.add(level: sample.db)
    // Loudness from the peak: snoring is impulsive, and one buffer's RMS
    // under-reports it. The spectral score stays out of the verdict, as in
    // SleepGuard: live detection has only been validated on the sound
    // classifier. The engine still gets the score for the event's averages.
    let state = snoreClassifier.classify(db: sample.peakDB, spectralScore: 0, snoreConfidence: sample.snoreConfidence)
    let isSpeech = speechClassifier.classify(db: sample.db, speechConfidence: sample.speechConfidence)
    let detection = DetectionInput(
      db: sample.db, spectralScore: sample.spectralScore, snoreConfidence: sample.snoreConfidence,
      snoreState: state, isSpeech: isSpeech)
    input.yield(.sample(detection, at: sample.time))
    if rawLog != nil {
      rawSamples.append(SnoreSample(
        elapsed: sample.time.timeIntervalSince(draft.start), db: sample.db, peakDB: sample.peakDB,
        spectralScore: sample.spectralScore, snoreConfidence: sample.snoreConfidence,
        speechConfidence: sample.speechConfidence, state: state))
    }

    if lastSnapshot.map({ sample.time.timeIntervalSince($0) >= Self.snapshotInterval }) ?? true {
      lastSnapshot = sample.time
      snapshots?.yield(LiveSnapshot(
        time: sample.time, db: sample.db, snoreState: state, isSpeech: isSpeech, eventCount: draft.events.count))
    }
  }

  /// Resumes once the engine has handled everything sent so far and this
  /// session has performed its outputs.
  func waitUntilProcessed() async {
    await withCheckedContinuation { done in
      input.yield(.barrier(done))
    }
  }

  // MARK: - Engine outputs

  private func perform(_ batch: DetectionEngine.Batch) async -> [DetectionEngine.Message] {
    for output in batch.outputs {
      switch output {
      case let .snoreEventStarted(id, _):
        // Without a clip the event is still kept.
        try? await capture.startClip(id: id)
      case let .snoreEventFinalized(event):
        let clip = await capture.closeClip()
        draft.events.append(NightEvent(
          id: event.id, start: event.start, duration: event.duration, category: .snoring,
          intensity: event.intensity, averageDB: event.averageDB, peakDB: event.peakDB,
          averageConfidence: event.averageConfidence, bursts: event.bursts, clipFileName: clip))
        if let clip { compress(clip, of: event.id) }
      case .snoreEventDiscarded:
        await capture.discardClip()
      case let .speechEventFinalized(event):
        draft.events.append(NightEvent(
          start: event.start, duration: event.duration, category: .sleepTalking,
          intensity: .quiet, averageDB: event.averageDB, peakDB: event.peakDB))
      case .melodyRequested, .melodyStopRequested, .eventClipClosed, .snoringResumedAfterMelody, .recordingGap:
        // The Snore Interrupter comes in F8. No melody plays, so nothing to do
        // and nothing to report back.
        break
      }
    }
    if batch.outputs.contains(where: \.savesAnEvent) {
      await checkpoint(at: batch.time)
    }
    return []
  }

  /// Keeps the night so far, ending at `time`.
  private func checkpoint(at time: Date) async {
    guard let checkpoints else { return }
    lastCheckpoint = time
    await checkpoints.save(draft.night(end: time))
  }

  /// Compresses the clip beside detection and points the event at the result.
  private func compress(_ clip: String, of eventID: UUID) {
    let capture = capture
    compressions.append(Task {
      let compressed = await capture.compressClip(named: clip)
      if let index = draft.events.firstIndex(where: { $0.id == eventID }) {
        draft.events[index].clipFileName = compressed
        await checkpoint(at: lastSampleTime ?? draft.start)
      }
    })
  }
}

private extension DetectionOutput {
  var savesAnEvent: Bool {
    switch self {
    case .snoreEventFinalized, .speechEventFinalized: true
    default: false
    }
  }
}
