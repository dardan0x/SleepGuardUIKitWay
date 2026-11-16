import Foundation
import Observation
import SleepCore
import SleepDomain

/// The night being recorded, for the bedside clock. Owns the
/// `RecordingSession` (an imperative resource: it listens until stopped), so
/// it is a state owner rather than view state. The shell builds it with the
/// capture port and keeps it for the whole night.
@MainActor
@Observable
public final class LiveRecordingModel {
  public enum Phase: Equatable {
    case starting
    case recording
    /// The microphone couldn't start.
    case failed
    case stopping
    case stopped
  }

  public private(set) var phase: Phase = .starting
  public private(set) var snapshot: LiveSnapshot?
  public let start: Date
  @ObservationIgnored private let session: RecordingSession

  public init(
    capture: any AudioCapturePort,
    settings: RecordingSession.Settings = .init(),
    checkpoints: (any RecordingCheckpointStore)? = nil,
    start: Date = Date())
  {
    self.start = start
    session = RecordingSession(capture: capture, settings: settings, checkpoints: checkpoints, start: start)
  }

  public var eventCount: Int {
    snapshot?.eventCount ?? 0
  }

  public var snoreState: DetectionState {
    snapshot?.snoreState ?? .none
  }

  /// Latest RMS level, dBFS.
  public var db: Float {
    snapshot?.db ?? AudioLevels.floorDB
  }

  /// Starts listening, then follows the snapshots until the night stops.
  /// Run it from the screen's `.task`; it does nothing once started.
  public func run() async {
    guard phase == .starting else { return }
    do {
      let snapshots = try await session.start()
      phase = .recording
      for await snapshot in snapshots {
        self.snapshot = snapshot
      }
    } catch {
      phase = .failed
    }
  }

  /// Stopping now would leave a night too short to save
  /// (`Night.minimumSaveDuration`).
  public func isTooShort(at now: Date) -> Bool {
    now.timeIntervalSince(start) < Night.minimumSaveDuration
  }

  /// Stops listening, finalizes the night and returns it, clips compressed.
  /// `.lowBattery` when the shell stops it before the battery runs out.
  public func stop(at end: Date = Date(), endReason: Night.EndReason = .stopped) async -> Night {
    phase = .stopping
    let draft = await session.stop(at: end, endReason: endReason)
    phase = .stopped
    return draft.night(end: end, endReason: endReason)
  }
}
