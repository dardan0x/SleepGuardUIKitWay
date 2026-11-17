import SleepCore
import SleepGuardContentKit
import SwiftUI

/// The screen left on the nightstand while recording: events so far, a dim
/// clock, how long it has been recording with a level meter, the current
/// snoring tier, and Stop. Stopping before `Night.minimumSaveDuration` asks
/// first, as SleepGuard's does. With the Snore Interrupter on, a note to mute
/// it for the night, and the melody's controls while it plays.
public struct BedsideClockScreen: View {
  let model: LiveRecordingModel
  let routes: BedsideClockRoutes
  @State private var confirmingEarlyStop = false

  public init(model: LiveRecordingModel, routes: BedsideClockRoutes) {
    self.model = model
    self.routes = routes
  }

  public var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      BedsideClockContent(
        time: context.date, elapsed: context.date.timeIntervalSince(model.start), eventCount: model.eventCount,
        db: model.db, snoreState: model.snoreState, canStop: model.phase == .recording,
        onStop: { stopTapped(at: context.date) },
        banner: {
          if model.interrupterArmed {
            BedsideMelodyDisclaimer(onMute: model.muteInterrupter)
              .padding(.top, 10)
              .padding(.horizontal, 20)
          }
        },
        overlay: {
          if let melody = model.playingMelody {
            BedsideMelodyOverlay(melodyName: melody.name, onMute: model.muteInterrupter, onStop: model.stopMelody)
          }
        })
    }
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
