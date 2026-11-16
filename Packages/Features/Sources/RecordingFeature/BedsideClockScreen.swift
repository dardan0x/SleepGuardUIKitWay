import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// The screen left on the nightstand while recording: events so far, a dim
/// clock, how long it has been recording with a level meter, the current
/// snoring tier, and Stop. Stopping before `Night.minimumSaveDuration` asks
/// first, as SleepGuard's does. The Snore Interrupter's overlay comes with F8.
public struct BedsideClockScreen: View {
  let model: LiveRecordingModel
  let routes: BedsideClockRoutes
  @State private var confirmingEarlyStop = false
  @Environment(\.theme) private var theme

  public init(model: LiveRecordingModel, routes: BedsideClockRoutes) {
    self.model = model
    self.routes = routes
  }

  public var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      VStack(spacing: 0) {
        HStack {
          Spacer()
          BedsideEventsBadge(count: model.eventCount)
        }
        .padding(.top, 16)
        .padding(.horizontal, 24)
        Spacer()
        BedsideClockFace(time: context.date)
        Spacer()
        BedsideRecordingStatus(elapsed: context.date.timeIntervalSince(model.start), db: model.db, time: context.date)
        Spacer()
        BedsideSnoreStatus(state: model.snoreState)
        Spacer()
        StopRecordingButton(height: 52) { stopTapped(at: context.date) }
          .disabled(model.phase != .recording)
          .padding(.horizontal, 24)
          .padding(.bottom, 32)
      }
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
    .task { await model.run() }
    .alert(Strings.sessionSummaryTooShortTitle, isPresented: $confirmingEarlyStop) {
      Button(Strings.actionKeepRecording, role: .cancel) {}
      Button(Strings.actionStopAnyway) {
        Task { await routes.discarded(model.stop()) }
      }
    } message: {
      Text(String(format: Strings.sessionSummaryTooShortMessageFormat, Int(Night.minimumSaveDuration / 60)))
    }
    .alert(Strings.sessionStartFailedAlertTitle, isPresented: .constant(model.phase == .failed)) {
      Button(Strings.actionOk, role: .cancel) { routes.discarded(nil) }
    } message: {
      Text(Strings.sessionStartFailedAlertMessage)
    }
  }

  private func stopTapped(at now: Date) {
    if model.isTooShort(at: now) {
      confirmingEarlyStop = true
    } else {
      Task { await routes.finished(model.stop()) }
    }
  }
}
