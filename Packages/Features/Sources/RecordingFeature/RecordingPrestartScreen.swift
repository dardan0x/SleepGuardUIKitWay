import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// Before a night: hosts the shared `PrestartContent`, with the start delay
/// in its options slot (the Snore Interrupter row comes with F8-T4). Start
/// checks the microphone and the charger first, as SleepGuard's prestart does.
public struct RecordingPrestartScreen: View {
  enum Alert {
    case microphone
    case charging
  }

  let dependencies: RecordingPrestartDependencies
  let routes: RecordingPrestartRoutes
  @State private var alert: Alert?
  @State private var preferences: AppPreferences?

  public init(dependencies: RecordingPrestartDependencies, routes: RecordingPrestartRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    PrestartContent(
      compact: dependencies.compactHeight,
      onStart: { Task { await startTapped() } },
      onCancel: routes.cancel)
    {
      PrestartDelayOptions(minutes: Binding(
        get: { preferences?.recordingDelayMinutes ?? 0 },
        set: {
          preferences?.recordingDelayMinutes = $0
          dependencies.saveDelay($0)
        }))
    }
    .task {
      preferences = await dependencies.loadPreferences()
    }
    .alert(Strings.sessionMicrophoneAlertTitle, isPresented: isShowing(.microphone)) {
      Button(Strings.actionCancel, role: .cancel) {}
      Button(Strings.sessionMicrophoneAlertOpenSettings, action: routes.openSettings)
    } message: {
      Text(Strings.sessionMicrophoneAlertMessage)
    }
    .alert(Strings.sessionChargingAlertTitle, isPresented: isShowing(.charging)) {
      Button(Strings.actionCancel, role: .cancel) {}
      Button(Strings.sessionChargingAlertStartAnyway) { routes.start(preferences ?? AppPreferences()) }
    } message: {
      Text(Strings.sessionChargingAlertMessage)
    }
  }

  private func startTapped() async {
    if preferences == nil {
      preferences = await dependencies.loadPreferences()
    }
    guard await dependencies.requestPermission() else {
      alert = .microphone
      return
    }
    guard dependencies.isCharging() else {
      alert = .charging
      return
    }
    routes.start(preferences ?? AppPreferences())
  }

  private func isShowing(_ kind: Alert) -> Binding<Bool> {
    Binding(get: { alert == kind }, set: { if !$0 { alert = nil } })
  }
}
