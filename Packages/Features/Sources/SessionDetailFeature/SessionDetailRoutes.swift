import SleepCore
import SleepDomain

public struct SessionDetailDependencies: Sendable {
  public var nightID: Night.ID
  /// Loads the night (reads only).
  public var loadDetail: LoadSessionDetailUseCase
  /// Then adds sleep stages when available.
  public var enrichDetail: EnrichNightWithStagesUseCase

  public init(nightID: Night.ID, loadDetail: LoadSessionDetailUseCase, enrichDetail: EnrichNightWithStagesUseCase) {
    self.nightID = nightID
    self.loadDetail = loadDetail
    self.enrichDetail = enrichDetail
  }
}

public struct SessionDetailRoutes {
  /// "Show all": every row under the current filter, and the night's events
  /// (the sheet's Play needs them to find an episode's clips).
  public var showAllEvents: @MainActor ([EventListRow], [NightEvent]) -> Void
  /// Play: the events to play in order, starting with the given one.
  public var playEvents: @MainActor ([NightEvent], NightEvent.ID) -> Void
  /// The info button on the sleep stages: the stages sheet.
  public var showStagesInfo: @MainActor (SleepStageBreakdown) -> Void
  /// Share on a row: that event's clip.
  public var shareEvent: @MainActor (NightEvent) -> Void

  public init(
    showAllEvents: @escaping @MainActor ([EventListRow], [NightEvent]) -> Void,
    playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void,
    showStagesInfo: @escaping @MainActor (SleepStageBreakdown) -> Void,
    shareEvent: @escaping @MainActor (NightEvent) -> Void)
  {
    self.showAllEvents = showAllEvents
    self.playEvents = playEvents
    self.showStagesInfo = showStagesInfo
    self.shareEvent = shareEvent
  }
}
