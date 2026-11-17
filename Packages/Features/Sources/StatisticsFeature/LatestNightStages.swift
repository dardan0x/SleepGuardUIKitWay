import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// The latest night's sleep stages under the dashboard, when it has any. The
/// dashboard is built from summaries (no stages), so this reads the night
/// itself, again whenever its summary changes (stages added on opening it
/// change its score). Nothing is shown while loading or without stages.
struct LatestNightStages: View {
  let latest: NightSummary
  let nights: any SessionRepository
  let onInfo: @MainActor (SleepStageBreakdown) -> Void
  @State private var stages: SleepStageBreakdown?

  var body: some View {
    Group {
      if let stages {
        SleepStagesCard(breakdown: stages, start: latest.start, duration: latest.duration) { onInfo(stages) }
      }
    }
    .task(id: latest) {
      let night = try? await nights.session(id: latest.id)
      if !Task.isCancelled {
        stages = night.flatMap { SleepStageBreakdown(segments: $0.sleepStages) }
      }
    }
  }
}
