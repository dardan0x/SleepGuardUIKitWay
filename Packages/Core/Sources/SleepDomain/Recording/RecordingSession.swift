import Foundation
import SleepCore

/// One night of recording: microphone samples in, a `RecordingDraft` out.
///
/// The capture delivers one reading per buffer (about 43–47 Hz). SleepCore's
/// `SampleDecimator` turns them into the fixed 20 Hz samples detection runs on
/// in SleepGuard too, on a time grid, so both apps feed the same samples for
/// the same sound. An interruption (a call) goes into the engine as
/// `captureDidPause` / `captureDidResume`, so the time without a microphone
/// becomes an interruption gap the score leaves out, not quiet sleep.
///
/// Each 20 Hz sample is classified (SleepCore's `SnoreClassifier` preset
/// and `SpeechClassifier`) and sent, timestamped, into the shared
/// `DetectionEngine`'s one ordered stream (ADR 0003, as in SleepGuard). The
/// engine runs the detection state machine on its own actor and hands each
/// batch of outputs back here, where they are performed in order: clips are
/// started, closed or discarded through the capture port, and events are
/// added to the draft. Compressing a clip runs beside detection, never in
/// its way, and so do disk writes: a checkpoint goes to a latest-wins writer
/// task (a newer night replaces one still waiting), raw-log batches to a
/// serial one. `stop` drains both before its final save, so nothing written
/// for the night lands after it is committed or discarded.
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
  /// Raw log samples are written in batches of this many (a second at 20 Hz).
  static let rawLogBatch = 20

  public private(set) var draft: RecordingDraft
  private let capture: any AudioCapture
  private let checkpoints: (any RecordingCheckpointStore)?
  private let settings: Settings
  private let rawLog: (any RawLogWriter)?
  private var rawSamples: [SnoreSample] = []
  private var decimator = SampleDecimator<CaptureSample>()
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
  private let interrupter: SnoreInterrupter?
  private var melodyPlaying = false
  /// The event's clip, closed when the melody paused the microphone; the
  /// event keeps it when it is finalized after the melody.
  private var closedClip: String?
  /// The newest night waiting for the checkpoint writer.
  private var pendingCheckpoint: Night?
  private var checkpointWriter: Task<Void, Never>?
  /// Raw-log batches waiting for the raw writer, in order.
  private var pendingRawBatches: [[SnoreSample]] = []
  private var rawWriter: Task<Void, Never>?

  /// `checkpoints`: where the night in progress is kept while recording.
  /// `rawLog`: where samples go when `settings.preserveRawAudio` is on.
  /// `interrupter`: the Snore Interrupter, for brands that have it (over the
  /// same `capture`).
  public init(
    capture: any AudioCapture,
    settings: Settings = Settings(),
    checkpoints: (any RecordingCheckpointStore)? = nil,
    rawLog: (any RawLogWriter)? = nil,
    interrupter: SnoreInterrupter? = nil,
    start: Date = Date())
  {
    self.capture = capture
    self.interrupter = interrupter
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
      detectSleepTalking: settings.detectSleepTalking,
      snoreInterrupterMode: (interrupter?.mode ?? .never).rawValue))
    if let interrupter {
      // Into the stream right away, so the gap is in order with the samples
      // and never queued behind `finalize`.
      let input = input
      await MainActor.run {
        interrupter.onStopped = { time in input.yield(.melodyDidStop(at: time)) }
      }
    }
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
      for await event in samples {
        await receive(event)
      }
    }
    return stream
  }

  /// Stops listening, handles the samples still queued, finalizes an open
  /// event at `end`, waits for its clips to compress, checkpoints the whole
  /// night (kept until it is saved or discarded) and returns the draft.
  public func stop(at end: Date = Date(), endReason: Night.EndReason = .stopped) async -> RecordingDraft {
    await interrupter?.stop()
    await capture.stop()
    await samplesTask?.value
    input.yield(.finalize(at: end))
    input.finish()
    await engineTask?.value
    for compression in compressions {
      await compression.value
    }
    compressions = []
    if let rawLog { enqueueRaw(rawSamples) }
    rawSamples = []
    await flushWrites()
    await checkpoints?.save(draft.night(end: end, endReason: endReason))
    await rawLog?.finish()
    snapshots?.finish()
    return draft
  }

  // MARK: - Samples

  /// One capture event. A reading goes through the decimator; each 20 Hz
  /// sample it yields is ingested, then a checkpoint follows when one is due.
  /// An interruption pauses and resumes detection, and restarts the grid.
  func receive(_ event: CaptureEvent) async {
    switch event {
    case let .sample(reading):
      for sample in decimator.add(reading, at: reading.time) {
        await receiveDecimated(CaptureSample(
          time: sample.time, db: sample.reading.db, peakDB: sample.reading.peakDB,
          spectralScore: sample.reading.spectralScore, snoreConfidence: sample.reading.snoreConfidence,
          speechConfidence: sample.reading.speechConfidence))
      }
    case let .interrupted(time):
      decimator.reset()
      input.yield(.captureDidPause(at: time))
    case let .resumed(time):
      decimator.reset()
      input.yield(.captureDidResume(at: time))
    }
  }

  private func receiveDecimated(_ sample: CaptureSample) async {
    ingest(sample)
    if rawLog != nil, rawSamples.count >= Self.rawLogBatch {
      enqueueRaw(rawSamples)
      rawSamples = []
    }
    if lastCheckpoint.map({ sample.time.timeIntervalSince($0) >= Self.checkpointInterval }) ?? true {
      checkpoint(at: sample.time)
    }
  }

  /// Classifies one 20 Hz sample and sends it to the engine. Internal so
  /// tests can script samples at exact times (past the decimator).
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
      snoreState: state, isSpeech: isSpeech, isMelodyPlaying: melodyPlaying)
    input.yield(.sample(detection, at: sample.time))
    if rawLog != nil {
      rawSamples.append(SnoreSample(
        elapsed: sample.time.timeIntervalSince(draft.start), db: sample.db, peakDB: sample.peakDB,
        spectralScore: sample.spectralScore, snoreConfidence: sample.snoreConfidence,
        speechConfidence: sample.speechConfidence, state: state))
    }

    if lastSnapshot.map({ sample.time.timeIntervalSince($0) >= Self.snapshotInterval }) ?? true {
      publish(time: sample.time, db: sample.db, snoreState: state, isSpeech: isSpeech)
    }
  }

  private func publish(time: Date, db: Float, snoreState: DetectionState, isSpeech: Bool) {
    lastSnapshot = time
    snapshots?.yield(LiveSnapshot(
      time: time, db: db, snoreState: snoreState, isSpeech: isSpeech, eventCount: draft.events.count,
      melodyPlaying: melodyPlaying))
  }

  /// Resumes once the engine has handled everything sent so far and this
  /// session has performed its outputs.
  func waitUntilProcessed() async {
    await withCheckedContinuation { done in
      input.yield(.barrier(done))
    }
  }

  // MARK: - Engine outputs

  /// Performs one batch; returns the engine's feedback (the melody started).
  private func perform(_ batch: DetectionEngine.Batch) async -> [DetectionEngine.Message] {
    var feedback: [DetectionEngine.Message] = []
    for output in batch.outputs {
      switch output {
      case let .snoreEventStarted(id, _):
        // Without a clip the event is still kept.
        try? await capture.startClip(id: id)
      case let .snoreEventFinalized(event):
        let open = await capture.closeClip()
        let clip = open ?? closedClip
        closedClip = nil
        draft.events.append(NightEvent(
          id: event.id, start: event.start, duration: event.duration, category: .snoring,
          intensity: event.intensity, averageDB: event.averageDB, peakDB: event.peakDB,
          averageConfidence: event.averageConfidence, bursts: event.bursts, clipFileName: clip))
        if let clip { compress(clip, of: event.id) }
      case .snoreEventDiscarded:
        // A clip closed for the melody is left for the launch cleanup
        // (`EnforceStorageLimits` removes files no night refers to).
        closedClip = nil
        await capture.discardClip()
      case let .speechEventFinalized(event):
        draft.events.append(NightEvent(
          start: event.start, duration: event.duration, category: .sleepTalking,
          intensity: .quiet, averageDB: event.averageDB, peakDB: event.peakDB))
      case .melodyRequested:
        if let interrupter, await interrupter.play() {
          melodyPlaying = true
          feedback.append(.melodyDidStart(at: batch.time))
          publish(time: batch.time, db: AudioLevels.floorDB, snoreState: .none, isSpeech: false)
        }
      case .melodyStopRequested:
        await interrupter?.stop()
      case .eventClipClosed:
        if let clip = await capture.closeClip() { closedClip = clip }
      case .snoringResumedAfterMelody:
        draft.recordingGaps = draft.recordingGaps.markingLastSnoringResumed()
      case let .recordingGap(start, duration):
        // The melody stopped: samples are live again, and the screen hears
        // it now rather than at the next sample.
        draft.recordingGaps = draft.recordingGaps.adding(start: start, duration: duration, nightStart: draft.start)
        melodyPlaying = false
        publish(time: batch.time, db: AudioLevels.floorDB, snoreState: .none, isSpeech: false)
      case let .interruptionGap(start, duration):
        // The microphone was taken (a call): the score leaves this time out.
        draft.recordingGaps = draft.recordingGaps.adding(
          start: start, duration: duration, nightStart: draft.start, kind: .interruption)
      }
    }
    if batch.outputs.contains(where: \.savesAnEvent) {
      checkpoint(at: batch.time)
    }
    return feedback
  }

  // MARK: - Writes

  /// Keeps the night so far, ending at `time`, without waiting for the disk:
  /// the writer saves the newest night waiting, one save at a time.
  private func checkpoint(at time: Date) {
    guard checkpoints != nil else { return }
    lastCheckpoint = time
    pendingCheckpoint = draft.night(end: time)
    if checkpointWriter == nil {
      checkpointWriter = Task { await writeCheckpoints() }
    }
  }

  private func writeCheckpoints() async {
    while let night = pendingCheckpoint {
      pendingCheckpoint = nil
      await checkpoints?.save(night)
    }
    checkpointWriter = nil
  }

  private func enqueueRaw(_ batch: [SnoreSample]) {
    guard !batch.isEmpty else { return }
    pendingRawBatches.append(batch)
    if rawWriter == nil {
      rawWriter = Task { await writeRaw() }
    }
  }

  private func writeRaw() async {
    while !pendingRawBatches.isEmpty {
      await rawLog?.append(pendingRawBatches.removeFirst())
    }
    rawWriter = nil
  }

  /// Resumes once every write handed to the writers so far has finished.
  /// Internal so tests can read the stores.
  func flushWrites() async {
    while let writer = checkpointWriter ?? rawWriter {
      await writer.value
    }
  }

  /// Compresses the clip beside detection and points the event at the result.
  private func compress(_ clip: String, of eventID: UUID) {
    let capture = capture
    compressions.append(Task {
      let compressed = await capture.compressClip(named: clip)
      if let index = draft.events.firstIndex(where: { $0.id == eventID }) {
        draft.events[index].clipFileName = compressed
        checkpoint(at: lastSampleTime ?? draft.start)
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
