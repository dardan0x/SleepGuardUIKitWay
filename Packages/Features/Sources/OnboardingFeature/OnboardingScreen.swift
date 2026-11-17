import SleepCore
import SleepGuardContentKit
import SwiftUI

public struct OnboardingDependencies {
  /// The microphone is already allowed (the page then shows it granted).
  public var microphoneGranted: @MainActor () -> Bool
  public var requestMicrophone: @MainActor () async -> Bool
  /// Apple Health, in a brand that has it; `nil`: no Health page.
  public var requestHealth: (@MainActor () async -> Bool)?

  public init(
    microphoneGranted: @escaping @MainActor () -> Bool,
    requestMicrophone: @escaping @MainActor () async -> Bool,
    requestHealth: (@MainActor () async -> Bool)?)
  {
    self.microphoneGranted = microphoneGranted
    self.requestMicrophone = requestMicrophone
    self.requestHealth = requestHealth
  }
}

public struct OnboardingRoutes {
  /// Onboarding is over. `healthGranted`: Health was allowed here.
  /// `startRecording`: "Start recording" rather than "Just browsing".
  public var finish: @MainActor (_ healthGranted: Bool, _ startRecording: Bool) -> Void

  public init(finish: @escaping @MainActor (_ healthGranted: Bool, _ startRecording: Bool) -> Void) {
    self.finish = finish
  }
}

/// First launch, hosting the shared onboarding content: asks for Apple Health
/// (in a brand that has it) and the microphone, then finishes. A granted
/// permission shows for a moment before the next page, as in SleepGuard.
public struct OnboardingScreen: View {
  static let grantedPause: Duration = .seconds(0.8)

  let dependencies: OnboardingDependencies
  let routes: OnboardingRoutes
  @State private var page = OnboardingPage.welcome
  @State private var microphone = OnboardingPermission.notAsked
  @State private var health = OnboardingPermission.notAsked

  public init(dependencies: OnboardingDependencies, routes: OnboardingRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  var pages: OnboardingPages {
    OnboardingPages(hasHealth: dependencies.requestHealth != nil)
  }

  public var body: some View {
    OnboardingContent(
      pages: pages, current: $page, microphone: microphone, health: health,
      onRequestMicrophone: { Task { await requestMicrophone() } },
      onRequestHealth: { Task { await requestHealth() } },
      onStartRecording: { routes.finish(health == .granted, true) },
      onBrowse: { routes.finish(health == .granted, false) })
      .onAppear {
        if dependencies.microphoneGranted() { microphone = .granted }
      }
  }

  func requestMicrophone() async {
    microphone = .requesting
    let granted = await dependencies.requestMicrophone()
    microphone = granted ? .granted : .notAsked
    await moveOn(from: .microphone, granted: granted)
  }

  func requestHealth() async {
    guard let request = dependencies.requestHealth else { return }
    health = .requesting
    let granted = await request()
    health = granted ? .granted : .notAsked
    await moveOn(from: .health, granted: granted)
  }

  /// "Granted" for a moment, then the next page; denied moves on at once.
  private func moveOn(from current: OnboardingPage, granted: Bool) async {
    if granted { try? await Task.sleep(for: Self.grantedPause) }
    withAnimation { page = pages.next(after: current) }
  }
}
