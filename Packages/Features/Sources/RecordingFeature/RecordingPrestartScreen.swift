import SleepGuardContentKit
import SwiftUI

/// Before a night: hosts the shared `PrestartContent`. Start checks the
/// microphone and the charger first, as SleepGuard's prestart does. The start
/// delay and the Snore Interrupter rows (its options slot) come with F8.
public struct RecordingPrestartScreen: View {
  enum Alert {
    case microphone
    case charging
  }

  let dependencies: RecordingPrestartDependencies
  let routes: RecordingPrestartRoutes
  @State private var alert: Alert?

  public init(dependencies: RecordingPrestartDependencies, routes: RecordingPrestartRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    PrestartContent(
      compact: dependencies.compactHeight,
      onStart: { Task { await startTapped() } },
      onCancel: routes.cancel)
      .alert(Strings.sessionMicrophoneAlertTitle, isPresented: isShowing(.microphone)) {
        Button(Strings.actionCancel, role: .cancel) {}
        Button(Strings.sessionMicrophoneAlertOpenSettings, action: routes.openSettings)
      } message: {
        Text(Strings.sessionMicrophoneAlertMessage)
      }
      .alert(Strings.sessionChargingAlertTitle, isPresented: isShowing(.charging)) {
        Button(Strings.actionCancel, role: .cancel) {}
        Button(Strings.sessionChargingAlertStartAnyway, action: routes.start)
      } message: {
        Text(Strings.sessionChargingAlertMessage)
      }
  }

  private func startTapped() async {
    guard await dependencies.requestPermission() else {
      alert = .microphone
      return
    }
    guard dependencies.isCharging() else {
      alert = .charging
      return
    }
    routes.start()
  }

  private func isShowing(_ kind: Alert) -> Binding<Bool> {
    Binding(get: { alert == kind }, set: { if !$0 { alert = nil } })
  }
}
