import Foundation
import SleepCore
import SleepGuardDesignKit
import SwiftUI
import Testing
import UIKit
@testable import StatisticsFeature

/// The dashboard content and the empty state in two themes; the theme reaches
/// them. Set `TEST_RUNNER_STATISTICS_RENDER_DIR` to keep the PNGs.
struct StatisticsRenderTests {
  nonisolated static let violet: Theme = {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#120A24")
    theme.palette.bgCard = Color(hex: "#221640")
    theme.palette.bgElevated = Color(hex: "#3A2C66")
    theme.palette.accent = Color(hex: "#9B7BFF")
    theme.typography = Typography(design: .rounded)
    theme.radii = Radii(card: 24, small: 16)
    return theme
  }()

  private let now = Date(timeIntervalSinceReferenceDate: 815_050_000)
  private let routes = StatisticsRoutes(startRecording: {}, showTrends: {}, showLastSevenNights: {})

  /// Ten nights, the last one yesterday evening, with varied scores and snoring.
  private func dashboard() throws -> NightDashboard {
    let nights = (0..<10).map { offset in
      let start = now.addingTimeInterval(-Double(offset + 1) * 86400 + 3600 * 14)
      return NightSummary(
        id: UUID(), start: start, end: start.addingTimeInterval(7.5 * 3600), score: [82, 64, 91, 45, 77, 88, 70, 60, 95, 50][offset],
        snoringDuration: [300, 4000, 0, 6000, 1200, 200, 2500, 0, 0, 100][offset], eventCount: offset % 4)
    }
    return try #require(NightDashboard.make(from: nights, now: now))
  }

  private func render(_ view: some View, _ theme: Theme) throws -> Data {
    let renderer = ImageRenderer(content: view.frame(width: 390).background(theme.palette.bgPrimary).environment(\.theme, theme))
    renderer.scale = 2
    return try #require(renderer.uiImage?.pngData())
  }

  @Test func dashboardFollowsTheTheme() throws {
    let content = try StatisticsDashboardContent(dashboard: dashboard(), now: now, routes: routes).padding(.horizontal, 20)
    let sleepGuard = try render(content, .sleepGuard)
    let violet = try render(content, Self.violet)
    #expect(sleepGuard != violet)
    try save(sleepGuard, "dashboard-sleepguard.png")
    try save(violet, "dashboard-violet.png")
  }

  @Test func emptyStateFollowsTheTheme() throws {
    let empty = StatisticsEmptyView(onStartRecording: {}).frame(height: 600)
    let sleepGuard = try render(empty, .sleepGuard)
    #expect(try sleepGuard != render(empty, Self.violet))
    try save(sleepGuard, "empty-sleepguard.png")
  }

  private func save(_ png: Data, _ name: String) throws {
    guard let directory = ProcessInfo.processInfo.environment["STATISTICS_RENDER_DIR"] else { return }
    try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent(name))
  }
}
