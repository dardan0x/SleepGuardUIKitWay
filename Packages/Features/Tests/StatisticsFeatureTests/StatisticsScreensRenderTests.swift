import Foundation
import SleepCore
import SleepGuardDesignKit
import SwiftUI
import Testing
import UIKit
@testable import StatisticsFeature

/// Trends, Last 7 Nights and Calendar content in two themes; the theme reaches
/// them. Set `TEST_RUNNER_STATISTICS_RENDER_DIR` to keep the PNGs.
struct StatisticsScreensRenderTests {
  private let now = Date(timeIntervalSinceReferenceDate: 815_050_000)

  /// Twenty nights, one a day, with varied scores, snoring and loudness.
  private var nights: [NightSummary] {
    (0..<20).map { offset in
      let start = now.addingTimeInterval(-Double(offset + 1) * 86400 + 3600 * 14)
      return NightSummary(
        id: UUID(), start: start, end: start.addingTimeInterval(7.5 * 3600), score: 40 + (offset * 13) % 60,
        snoringDuration: Double((offset * 7) % 50) * 60, eventCount: offset % 5,
        loudestIntensity: [nil, .quiet, .light, .loud, .epic][offset % 5])
    }
  }

  private func render(_ view: some View, _ theme: Theme) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390).background(theme.palette.bgPrimary).environment(\.theme, theme))
    renderer.scale = 2
    return try #require(renderer.uiImage?.pngData())
  }

  @Test(arguments: ["trends", "last7", "calendar"])
  func screenFollowsTheTheme(name: String) throws {
    let content = switch name {
    case "trends": AnyView(TrendsContent(nights: nights, now: now))
    case "last7": AnyView(LastSevenNightsContent(nights: nights) { _ in })
    default: AnyView(CalendarContent(nights: nights, today: now) { _ in })
    }
    let sleepGuard = try render(content, .sleepGuard)
    let violet = try render(content, StatisticsRenderTests.violet)
    #expect(sleepGuard != violet)
    if let directory = ProcessInfo.processInfo.environment["STATISTICS_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name)-sleepguard.png"))
    }
  }

  @Test func calendarDescribesTheNightsLoudness() {
    #expect(CalendarContent.loudnessLabel(.epic) == Strings.statsCalendarLegendEpic)
    #expect(CalendarContent.loudnessLabel(.light) == Strings.statsCalendarLegendLight)
    #expect(CalendarContent.loudnessLabel(nil) == Strings.quietIntensityLabel)
  }

  @Test func lastSevenNightsBestAndWorstText() {
    #expect(LastSevenNightsContent.scoreAndDay(nil) == "0 ")
    let day = NightDay(date: now, nights: [NightSummary(id: UUID(), start: now, end: now, score: 91, snoringDuration: 0, eventCount: 0)])
    #expect(LastSevenNightsContent.scoreAndDay(day).hasPrefix("91 "))
  }
}
