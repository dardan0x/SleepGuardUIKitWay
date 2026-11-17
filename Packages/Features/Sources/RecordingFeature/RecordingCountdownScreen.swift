import Foundation
import SleepCore
import SleepGuardContentKit
import SwiftUI

/// The start delay, counting down to `target` in the shared
/// `RecordingCountdownContent`. At zero, or on Start now, the night starts;
/// Cancel goes back to the prestart. The shell keeps the microphone warm
/// meanwhile, so the app isn't suspended.
public struct RecordingCountdownScreen: View {
  let target: Date
  let routes: RecordingCountdownRoutes
  @State private var seconds: Int

  public init(target: Date, routes: RecordingCountdownRoutes) {
    self.target = target
    self.routes = routes
    _seconds = State(initialValue: RecordingDelay.secondsLeft(until: target, now: Date()))
  }

  public var body: some View {
    RecordingCountdownContent(seconds: seconds, onCancel: routes.cancel, onStartNow: routes.start)
      .task {
        while !Task.isCancelled {
          seconds = RecordingDelay.secondsLeft(until: target, now: Date())
          if seconds == 0 {
            routes.start()
            return
          }
          try? await Task.sleep(for: .seconds(1))
        }
      }
  }
}
