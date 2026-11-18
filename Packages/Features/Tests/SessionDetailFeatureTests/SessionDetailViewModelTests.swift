import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
@testable import SessionDetailFeature

/// Loading, failing and retrying; the filter; only events with a clip share.
@MainActor
struct SessionDetailViewModelTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  private func viewModel(
    _ repository: FakeSessionRepository, id: Night.ID, shared: @escaping @MainActor (NightEvent) -> Void = { _ in })
    -> SessionDetailViewModel
  {
    SessionDetailViewModel(
      dependencies: SessionDetailDependencies(
        nightID: id, loadDetail: LoadSessionDetail(sessions: repository, sleepStages: FakeSleepStagePort())),
      routes: SessionDetailRoutes(
        showAllEvents: { _, _ in }, playEvents: { _, _ in }, showStagesInfo: { _ in }, shareEvent: shared))
  }

  @Test func loadsTheNight() async {
    let night = Night(start: start, end: start.addingTimeInterval(3600))
    let viewModel = viewModel(FakeSessionRepository([night]), id: night.id)
    await viewModel.load()
    guard case let .loaded(detail) = viewModel.state else {
      Issue.record("not loaded")
      return
    }
    #expect(detail.session.id == night.id)
    #expect(!viewModel.needsLoading)
  }

  @Test func aFailedLoadShowsTheErrorAndRetryLoadsAgain() async {
    let night = Night(start: start, end: start.addingTimeInterval(3600))
    let repository = FakeSessionRepository([night])
    struct Failure: Error {}
    await repository.failNextCall(with: Failure())
    let viewModel = viewModel(repository, id: night.id)
    await viewModel.load()
    guard case .error = viewModel.state else {
      Issue.record("expected the error")
      return
    }
    viewModel.retry()
    #expect(viewModel.needsLoading)
    await viewModel.load()
    guard case .loaded = viewModel.state else {
      Issue.record("not loaded after retry")
      return
    }
  }

  @Test func onlyAnEventWithAClipIsShared() async {
    let withClip = NightEvent(start: start, duration: 5, category: .sleepTalking, intensity: .quiet, clipFileName: "a.m4a")
    let without = NightEvent(start: start.addingTimeInterval(60), duration: 5, category: .noise, intensity: .quiet)
    let night = Night(start: start, end: start.addingTimeInterval(3600), events: [withClip, without])
    var shared: [NightEvent.ID] = []
    let viewModel = viewModel(FakeSessionRepository([night]), id: night.id, shared: { shared.append($0.id) })
    await viewModel.load()
    for row in EventListRow.rows(for: night) {
      viewModel.share(row)
    }
    #expect(shared == [withClip.id])
  }

  @Test func theFilterIsKept() {
    let viewModel = viewModel(FakeSessionRepository(), id: UUID())
    viewModel.select(.noise)
    #expect(viewModel.filter == .noise)
  }
}
