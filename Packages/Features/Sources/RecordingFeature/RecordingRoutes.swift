import SleepCore

// What the recording screens need and where they go, built by the shell.

public struct RecordingPrestartDependencies {
  /// A short screen: SleepGuard shrinks the header below 874 pt of height.
  public var compactHeight: Bool
  /// Asks for the microphone (the capture port). `true` when granted.
  public var requestPermission: @MainActor () async -> Bool
  /// Plugged in or full: a night on battery may not last.
  public var isCharging: @MainActor () -> Bool

  public init(
    compactHeight: Bool,
    requestPermission: @escaping @MainActor () async -> Bool,
    isCharging: @escaping @MainActor () -> Bool)
  {
    self.compactHeight = compactHeight
    self.requestPermission = requestPermission
    self.isCharging = isCharging
  }
}

public struct RecordingPrestartRoutes {
  /// Microphone granted and charging (or the user chose to go on anyway).
  public var start: @MainActor () -> Void
  public var cancel: @MainActor () -> Void
  /// The app's page in Settings, to allow the microphone.
  public var openSettings: @MainActor () -> Void

  public init(
    start: @escaping @MainActor () -> Void,
    cancel: @escaping @MainActor () -> Void,
    openSettings: @escaping @MainActor () -> Void)
  {
    self.start = start
    self.cancel = cancel
    self.openSettings = openSettings
  }
}

public struct BedsideClockRoutes {
  /// Stopped after the minimum: the night, clips compressed, for the summary.
  public var finished: @MainActor (Night) -> Void
  /// Stopped early and discarded (the night, for its clips), or the
  /// microphone never started (`nil`).
  public var discarded: @MainActor (Night?) -> Void

  public init(finished: @escaping @MainActor (Night) -> Void, discarded: @escaping @MainActor (Night?) -> Void) {
    self.finished = finished
    self.discarded = discarded
  }
}

public struct SessionSummaryRoutes {
  /// Save the night (the flow commits it and reports a failure).
  public var save: @MainActor (Night) -> Void
  /// Throw it away, clips included.
  public var discard: @MainActor (Night) -> Void

  public init(save: @escaping @MainActor (Night) -> Void, discard: @escaping @MainActor (Night) -> Void) {
    self.save = save
    self.discard = discard
  }
}
