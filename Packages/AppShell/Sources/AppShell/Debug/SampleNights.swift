#if DEBUG
import Foundation
import SleepCore
import SleepDomain

/// Sample nights for Debug builds, so screens have data before recording
/// exists (F7). Generated from a fixed seed: the same nights, ids included,
/// on every run and every device, which keeps screenshots stable.
enum SampleNights {
  /// `count` nights, newest first, the newest starting the evening before `today`.
  static func make(count: Int = 14, before today: Date = .now, calendar: Calendar = .current) -> [Night] {
    var random = SeededRandom(seed: 0x5EED)
    let midnight = calendar.startOfDay(for: today)
    return (1...count).map { daysBack in
      let evening = calendar.date(byAdding: .day, value: -daysBack, to: midnight) ?? midnight
      return night(starting: evening.addingTimeInterval(22.5 * 3600), index: daysBack, random: &random)
    }
  }

  /// The longest sample clip. Longer events play their clip only (the player
  /// stops at the end of the file), which keeps seeding quick.
  static let maxClipSeconds: TimeInterval = 15

  /// Saves the sample nights if the store has none, and asks `writeClip` for
  /// each snoring event's clip (name, seconds, intensity), off the main actor.
  /// Leaves real data alone.
  static func seedIfEmpty(
    _ repository: any SessionRepository,
    before today: Date = .now,
    writeClip: @escaping @Sendable (String, TimeInterval, SnoreIntensity) throws -> Void = { _, _, _ in }) async throws
  {
    var current = await repository.observeSummaries().makeAsyncIterator()
    guard let existing = await current.next(), existing.isEmpty else { return }
    let nights = make(before: today)
    let clips = nights.flatMap(\.events).compactMap { event in
      event.clipFileName.map { ($0, min(event.duration, maxClipSeconds), event.intensity) }
    }
    try await Task.detached(priority: .utility) {
      for (name, seconds, intensity) in clips {
        try writeClip(name, seconds, intensity)
      }
    }.value
    for session in nights {
      try await repository.save(session, summary: session.summary())
    }
  }

  // MARK: - Generation

  private static func night(starting base: Date, index: Int, random: inout SeededRandom) -> Night {
    let start = base.addingTimeInterval(Double.random(in: 0...5400, using: &random))
    let duration = Double.random(in: 5.5...9, using: &random) * 3600

    var events: [NightEvent] = []
    for _ in 0..<Int.random(in: 0...6, using: &random) {
      events += episode(at: Double.random(in: 1800...(duration - 3600), using: &random), from: start, random: &random)
    }
    for _ in 0..<Int.random(in: 0...3, using: &random) {
      events.append(NightEvent(
        id: random.uuid(),
        start: start.addingTimeInterval(Double.random(in: 600...(duration - 600), using: &random)),
        duration: Double.random(in: 5...20, using: &random),
        category: .sleepTalking, intensity: .quiet,
        averageDB: -48, peakDB: -38, averageConfidence: 0.7))
    }

    let gaps = random.chance(0.3)
      ? [RecordingGap(
        startOffset: Double.random(in: 3600...(duration - 3600), using: &random),
        duration: Double.random(in: 60...300, using: &random),
        snoringResumed: random.chance(0.5))]
      : []

    return Night(
      id: random.uuid(),
      start: start,
      end: start.addingTimeInterval(duration),
      averageDB: -46, peakDB: events.map(\.peakDB).max() ?? -40,
      events: events.sorted { $0.start < $1.start },
      recordingGaps: gaps,
      sleepStages: index % 3 == 0 ? [] : stages(lasting: duration),
      endReason: index == 5 ? .lowBattery : .stopped)
  }

  /// One to four snoring events a few minutes apart: one episode.
  private static func episode(at offset: TimeInterval, from start: Date, random: inout SeededRandom) -> [NightEvent] {
    var events: [NightEvent] = []
    var cursor = offset
    for _ in 0..<Int.random(in: 1...4, using: &random) {
      let duration = Double.random(in: 8...90, using: &random)
      let intensity: SnoreIntensity = [.quiet, .light, .light, .loud, .loud, .epic][Int.random(in: 0...5, using: &random)]
      let firstBurst = duration * Double.random(in: 0.3...0.6, using: &random)
      let id = random.uuid() // drawn where it always was, so the nights stay the same
      events.append(NightEvent(
        id: id,
        start: start.addingTimeInterval(cursor),
        duration: duration,
        intensity: intensity,
        averageDB: [-44, -36, -24, -14][intensity.rank],
        peakDB: [-36, -28, -16, -6][intensity.rank],
        averageConfidence: Double.random(in: 0.5...0.95, using: &random),
        bursts: [
          SnoreBurst(startOffset: 0, endOffset: firstBurst),
          SnoreBurst(startOffset: firstBurst + 2, endOffset: duration),
        ],
        clipFileName: "\(id.uuidString).m4a"))
      cursor += duration + Double.random(in: 30...200, using: &random)
    }
    return events
  }

  /// 90-minute cycles of light, deep, light, REM and a moment awake.
  private static func stages(lasting duration: TimeInterval) -> [SleepStageSegment] {
    let cycle: [(SleepStage, TimeInterval)] = [(.light, 30), (.deep, 20), (.light, 15), (.rem, 20), (.awake, 5)]
    var segments: [SleepStageSegment] = []
    var offset: TimeInterval = 0
    while offset < duration {
      for (stage, minutes) in cycle where offset < duration {
        let length = min(minutes * 60, duration - offset)
        segments.append(SleepStageSegment(stage: stage, startOffset: offset, duration: length))
        offset += length
      }
    }
    return segments
  }
}

/// A deterministic generator (64-bit LCG): the same sequence on every run.
struct SeededRandom: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return state
  }

  mutating func chance(_ probability: Double) -> Bool {
    Double.random(in: 0..<1, using: &self) < probability
  }

  mutating func uuid() -> UUID {
    let a = next(), b = next()
    return withUnsafeBytes(of: (a, b)) { UUID(uuid: $0.load(as: uuid_t.self)) }
  }
}
#endif
