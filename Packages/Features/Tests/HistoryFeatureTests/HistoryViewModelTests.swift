import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
@testable import HistoryFeature

/// The list's identifiers follow SleepCore's months and days; the view model
/// shows empty or the months, asks before deleting a day and deletes every
/// night of it, and reports a failed delete.
@MainActor
struct HistoryViewModelTests {
  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
  private let nights = [0.0, 1, 1.2, 40].map { days in
    Night(start: start.addingTimeInterval(-days * 86400), end: start.addingTimeInterval(-days * 86400 + 3600))
  }

  private func viewModel(_ repository: FakeSessionRepository, opened: @escaping @MainActor (NightSummary) -> Void = { _ in })
    -> HistoryViewModel
  {
    HistoryViewModel(
      dependencies: HistoryDependencies(
        nights: repository, deleteNights: DeleteSessionsUseCase(sessions: repository, files: FakeSessionFileStore())),
      routes: HistoryRoutes(openNight: opened))
  }

  private var aDayWithTwoNights: NightDay {
    get throws {
      try #require(NightMonth.months(from: nights.map { $0.summary() }).flatMap(\.days).first { $0.nights.count > 1 })
    }
  }

  @Test func itemsFollowTheMonthsAndDays() {
    let months = NightMonth.months(from: nights.map { $0.summary() }, calendar: .autoupdatingCurrent)
    let items = NightsListItems(months: months)
    #expect(items.sections.map(\.month) == months.map(\.id))
    #expect(items.sections.map(\.days) == months.map { $0.days.map(\.id) })
    let first = months[0].days[0]
    #expect(items.day(first.id) == first)
    #expect(items.listed([first.id, .distantPast]) == [first.id])
  }

  @Test func showsEmptyThenTheMonths() {
    let viewModel = viewModel(FakeSessionRepository())
    #expect(viewModel.state == .loading)
    viewModel.show([])
    #expect(viewModel.state == .empty)
    viewModel.show(nights.map { $0.summary() })
    guard case let .loaded(months) = viewModel.state else {
      Issue.record("not loaded")
      return
    }
    #expect(months.flatMap(\.days).flatMap(\.nights).count == nights.count)
  }

  @Test func openingANightRoutesIt() {
    var opened: [NightSummary] = []
    let viewModel = viewModel(FakeSessionRepository(), opened: { opened.append($0) })
    viewModel.open(nights[0].summary())
    #expect(opened == [nights[0].summary()])
  }

  @Test func deleteAsksFirstAndDeletesEveryNightOfTheDay() async throws {
    let repository = FakeSessionRepository(nights)
    let viewModel = viewModel(repository)
    let day = try aDayWithTwoNights
    viewModel.askToDelete(day)
    #expect(viewModel.alert == .confirmDelete(day))
    #expect(await repository.deletedIDs.isEmpty)

    await viewModel.confirmDelete()
    #expect(viewModel.alert == nil)
    #expect(await Set(repository.deletedIDs) == Set(day.nights.map(\.id)))
  }

  @Test func discardingTheQuestionDeletesNothing() async throws {
    let repository = FakeSessionRepository(nights)
    let viewModel = viewModel(repository)
    try viewModel.askToDelete(aDayWithTwoNights)
    viewModel.dismissAlert()
    await viewModel.confirmDelete()
    #expect(await repository.deletedIDs.isEmpty)
  }

  @Test func aFailedDeleteIsReported() async throws {
    let repository = FakeSessionRepository(nights)
    struct Failure: Error {}
    await repository.failNextCall(with: Failure())
    let viewModel = viewModel(repository)
    try viewModel.askToDelete(aDayWithTwoNights)
    await viewModel.confirmDelete()
    #expect(viewModel.alert == .deleteFailed)
  }

  /// A day is deleted in one write: when it fails, every night of the day is
  /// still there (the old loop could leave half a day).
  @Test func aFailedDayDeleteLeavesTheWholeDay() async throws {
    let repository = FakeSessionRepository(nights)
    let viewModel = viewModel(repository)
    let day = try aDayWithTwoNights
    viewModel.askToDelete(day)
    struct Failure: Error {}
    await repository.failDeletes(with: Failure())
    await viewModel.confirmDelete()
    #expect(viewModel.alert == .deleteFailed)
    for night in day.nights {
      #expect(await repository.sessions[night.id] != nil)
    }
  }
}
