import Foundation
import SleepCore
import Testing
@testable import HistoryFeature

struct HistorySectionsTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  /// 23:00 on `day` of November 2026, UTC.
  private func night(day: Int, hour: Int = 23, score: Int = 80, hours: Double = 8, events: Int = 2, month: Int = 11) -> NightSummary {
    let start = calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    return NightSummary(id: UUID(), start: start, end: start.addingTimeInterval(hours * 3600), score: score, snoringDuration: 0, eventCount: events)
  }

  @Test func groupsByMonthThenDayNewestFirst() {
    let sections = HistorySections.make(
      from: [night(day: 3), night(day: 20), night(day: 28, month: 10), night(day: 12)],
      calendar: calendar)
    #expect(sections.map { calendar.component(.month, from: $0.month) } == [11, 10])
    #expect(sections[0].days.map { calendar.component(.day, from: $0.date) } == [20, 12, 3])
    #expect(sections[1].days.count == 1)
  }

  @Test func nightsStartingTheSameDayShareARowNewestFirst() throws {
    let nap = night(day: 5, hour: 14, score: 90, hours: 1, events: 0)
    let late = night(day: 5, hour: 23, score: 60, hours: 7, events: 4)
    let day = try #require(HistorySections.make(from: [nap, late], calendar: calendar).first?.days.first)
    #expect(day.nights.map(\.id) == [late.id, nap.id])
    #expect(day.averageScore == 75) // (90 + 60) / 2
    #expect(day.totalDuration == 8 * 3600)
    #expect(day.totalEvents == 4)
  }

  @Test func noNightsNoSections() {
    #expect(HistorySections.make(from: [], calendar: calendar).isEmpty)
  }
}
