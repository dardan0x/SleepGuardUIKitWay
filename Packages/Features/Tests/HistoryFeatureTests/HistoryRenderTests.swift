import SleepCore
import SleepGuardDesignKit
import SwiftUI
import Testing
import UIKit
@testable import HistoryFeature

/// Draws the day rows and the empty state in two themes and checks the theme
/// reaches them (the renders differ). The full `List` is UIKit-backed and
/// can't be drawn without a window; its layout is checked in the running app.
/// Set `TEST_RUNNER_HISTORY_RENDER_DIR` to keep the PNGs.
struct HistoryRenderTests {
  nonisolated static let violet: Theme = {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#120A24")
    theme.palette.bgCard = Color(hex: "#221640")
    theme.palette.accent = Color(hex: "#9B7BFF")
    theme.typography = Typography(design: .rounded)
    theme.radii = Radii(card: 24, small: 16)
    return theme
  }()

  /// Six nights on consecutive days, plus a nap on the second day.
  private func months() -> [HistoryMonth] {
    let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
    let scores = [92, 64, 78, 41, 85, 70]
    let events = [1, 6, 3, 11, 2, 4]
    var summaries: [NightSummary] = []
    for index in 0..<6 {
      let nightStart = start.addingTimeInterval(Double(-index) * 86400)
      summaries.append(NightSummary(
        id: UUID(), start: nightStart, end: nightStart.addingTimeInterval(7.5 * 3600),
        score: scores[index], snoringDuration: 0, eventCount: events[index]))
    }
    let napStart = start.addingTimeInterval(-86400 + 2 * 3600)
    summaries.append(NightSummary(
      id: UUID(), start: napStart, end: napStart.addingTimeInterval(3600), score: 95, snoringDuration: 0, eventCount: 0))
    return HistorySections.make(from: summaries, calendar: .current)
  }

  @Test func rowsAndEmptyStateFollowTheTheme() throws {
    let rows = { (theme: Theme) in
      VStack(spacing: 12) {
        ForEach(months().flatMap(\.days)) { day in
          HistoryDayRow(day: day, onOpen: { _ in })
        }
      }
      .padding(16)
      .frame(width: 390)
      .background(theme.palette.bgPrimary)
      .environment(\.theme, theme)
    }
    let empty = { (theme: Theme) in
      HistoryEmptyView().frame(width: 390, height: 400).background(theme.palette.bgPrimary).environment(\.theme, theme)
    }
    let images = try [
      ("history-rows-sleepguard", render(rows(.sleepGuard))),
      ("history-rows-violet", render(rows(Self.violet))),
      ("history-empty-sleepguard", render(empty(.sleepGuard))),
      ("history-empty-violet", render(empty(Self.violet))),
    ]
    #expect(images[0].1 != images[1].1)
    #expect(images[2].1 != images[3].1)
    if let directory = ProcessInfo.processInfo.environment["HISTORY_RENDER_DIR"] {
      for (name, png) in images {
        try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
      }
    }
  }

  private func render(_ view: some View) throws -> Data {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    return try #require(renderer.uiImage?.pngData())
  }
}
