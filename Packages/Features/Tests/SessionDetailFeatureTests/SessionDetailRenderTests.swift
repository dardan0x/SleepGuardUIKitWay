import Foundation
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI
import Testing
import UIKit
@testable import SessionDetailFeature

/// Draws the detail content in two themes and checks the theme reaches it.
/// Set `TEST_RUNNER_DETAIL_RENDER_DIR` to keep the PNGs.
struct SessionDetailRenderTests {
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

  /// Eight hours: three snoring episodes, sleep talking, a cough.
  private func detail() -> SessionDetail {
    let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
    func event(_ minute: Double, _ seconds: TimeInterval, _ category: SoundCategory = .snoring, _ intensity: SnoreIntensity = .light) -> NightEvent {
      NightEvent(start: start.addingTimeInterval(minute * 60), duration: seconds, category: category, intensity: intensity)
    }
    let night = Night(start: start, end: start.addingTimeInterval(8 * 3600), events: [
      event(30, 45, .snoring, .light), event(32, 80, .snoring, .loud),
      event(140, 120, .snoring, .epic), event(200, 12, .sleepTalking, .quiet),
      event(260, 4, .coughing, .quiet), event(400, 60, .snoring, .quiet),
    ])
    return SessionDetail(session: night, summary: night.summary(), episodes: night.displayableEpisodes)
  }

  @Test func contentFollowsTheTheme() throws {
    let render = { (theme: Theme) throws -> Data in
      let view = SessionDetailContent(detail: detail(), onShowAll: {})
        .frame(width: 390)
        .background(theme.palette.bgPrimary)
        .environment(\.theme, theme)
      let renderer = ImageRenderer(content: view)
      renderer.scale = 2
      return try #require(renderer.uiImage?.pngData())
    }
    let sleepGuard = try render(.sleepGuard)
    let violet = try render(Self.violet)
    #expect(sleepGuard != violet)
    if let directory = ProcessInfo.processInfo.environment["DETAIL_RENDER_DIR"] {
      try sleepGuard.write(to: URL(fileURLWithPath: directory).appendingPathComponent("detail-sleepguard.png"))
      try violet.write(to: URL(fileURLWithPath: directory).appendingPathComponent("detail-violet.png"))
    }
  }
}
