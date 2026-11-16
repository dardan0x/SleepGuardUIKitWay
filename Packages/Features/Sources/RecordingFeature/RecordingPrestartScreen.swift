import SleepGuardDesignKit
import SwiftUI

/// Before a night: what to expect, two tips, Start and Cancel. Start checks
/// the microphone and the charger first, as SleepGuard's prestart does. The
/// start delay and the Snore Interrupter rows come with F8.
public struct RecordingPrestartScreen: View {
  enum Alert {
    case microphone
    case charging
  }

  let dependencies: RecordingPrestartDependencies
  let routes: RecordingPrestartRoutes
  @State private var alert: Alert?
  @Environment(\.theme) private var theme

  public init(dependencies: RecordingPrestartDependencies, routes: RecordingPrestartRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    let compact = dependencies.compactHeight
    ZStack(alignment: .bottom) {
      ScrollView {
        VStack(spacing: 0) {
          PrestartHeader(compact: compact)
            .padding(.top, compact ? 20 : 24)
          PrestartTipsCard()
            .padding(.top, compact ? 20 : 24)
          Color.clear.frame(height: 160)
        }
        .padding(.horizontal, 24)
      }

      VStack(spacing: 0) {
        StartRecordingButton(height: 56) {
          Task { await startTapped() }
        }
        Button(action: routes.cancel) {
          Text(Strings.actionCancel)
            .font(theme.typography.font(size: 17, weight: .medium))
            .foregroundStyle(theme.palette.textSecondary)
        }
      }
      .padding(.horizontal, 24)
      .background(theme.palette.bgPrimary.ignoresSafeArea(edges: .bottom))
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
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
