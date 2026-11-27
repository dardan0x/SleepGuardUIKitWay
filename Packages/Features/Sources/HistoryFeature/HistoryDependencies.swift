import SleepCore
import SleepDomain

public struct HistoryDependencies: Sendable {
  /// The nights. A plain read, so the screen holds the port itself.
  public var nights: any SessionRepository
  /// A day's nights, all at once.
  public var deleteNights: DeleteSessions

  public init(nights: any SessionRepository, deleteNights: DeleteSessions) {
    self.nights = nights
    self.deleteNights = deleteNights
  }
}

public struct HistoryRoutes {
  /// The row's summary, so the next screen can show the night's date at once.
  public var openNight: @MainActor (NightSummary) -> Void

  public init(openNight: @escaping @MainActor (NightSummary) -> Void) {
    self.openNight = openNight
  }
}
