import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI

/// The night's timeline, then the banners that explain gaps in it: detection
/// paused by the Snore Interrupter, or the night saved early on low battery.
struct SessionDetailTimeline: View {
  let detail: SessionDetail

  var body: some View {
    let night = detail.session
    VStack(spacing: 24) {
      NightTimeline(
        start: night.start, end: night.end,
        marks: DetailEventRow.make(episodes: detail.episodes, events: night.events, filter: .all).map {
          TimelineMark(start: $0.start, duration: $0.duration, category: $0.category, intensity: $0.intensity)
        },
        gaps: night.recordingGaps,
        eventCount: detail.summary.eventCount,
        snoringDuration: detail.summary.snoringDuration)

      if !night.recordingGaps.isEmpty {
        RecordingGapsBanner(totalGap: night.recordingGaps.reduce(0) { $0 + $1.duration })
      }
      if night.endReason == .lowBattery {
        LowBatteryBanner()
      }
    }
  }
}
