import Foundation
import ScreenKit
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import SleepGuardDesignKit
import Testing
import UIKit
@testable import HistoryFeature

/// The list's identifiers follow SleepCore's months and days; the screen shows
/// empty, then the list; delete asks first and removes every night of the day.
@MainActor
struct HistoryViewControllerTests {
  private static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
  private let nights = [0.0, 1, 1.2, 40].map { days in
    Night(start: start.addingTimeInterval(-days * 86400), end: start.addingTimeInterval(-days * 86400 + 3600))
  }

  private func screen(_ repository: FakeSessionRepository) -> HistoryViewController {
    let screen = HistoryViewController(
      dependencies: HistoryDependencies(
        nights: repository, deleteNight: DeleteSession(sessions: repository, files: FakeSessionFileStore())),
      routes: HistoryRoutes(openNight: { _ in }), theme: .sleepGuard, chrome: ScreenChrome())
    screen.loadViewIfNeeded()
    return screen
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

  @Test func showsEmptyThenTheList() {
    let screen = screen(FakeSessionRepository())
    let loading = screen.stateChild
    screen.show([])
    let empty = screen.stateChild
    #expect(empty !== loading)
    screen.show(nights.map { $0.summary() })
    #expect(screen.stateChild is NightsListController)
  }

  @Test func deleteAsksFirst() throws {
    let screen = screen(FakeSessionRepository(nights))
    let day = try #require(NightMonth.months(from: nights.map { $0.summary() }).first?.days.first)
    let alert = screen.deleteConfirmation(for: day)
    #expect(alert.title == Strings.recordingsDetailRemoveTitle)
    #expect(alert.actions.map(\.title) == [Strings.actionRemove, Strings.actionDiscard])
    #expect(alert.actions.map(\.style) == [.destructive, .cancel])
  }

  @Test func deletingADayRemovesEachOfItsNights() async throws {
    let repository = FakeSessionRepository(nights)
    let screen = screen(repository)
    let day = try #require(
      NightMonth.months(from: nights.map { $0.summary() }).flatMap(\.days).first { $0.nights.count > 1 })
    screen.delete(day)
    await screen.deleting?.value
    #expect(await Set(repository.deletedIDs) == Set(day.nights.map(\.id)))
  }
}
