import Foundation
import Observation
import SleepCore

/// Where the first-launch onboarding is and what it asks: Apple Health (in a
/// brand that has it) and the microphone. A granted permission shows for a
/// moment before the next page, as in SleepGuard; finishing hands back
/// whether the person chose "Start recording".
@MainActor
@Observable
public final class OnboardingViewModel {
  public enum Permission: Equatable {
    case notAsked
    /// The system prompt is up.
    case requesting
    case granted
  }

  public static let grantedPause: Duration = .seconds(0.8)

  public let pages: OnboardingPages
  public private(set) var page: OnboardingPage
  public private(set) var microphone = Permission.notAsked
  public private(set) var health = Permission.notAsked
  let dependencies: OnboardingDependencies
  let routes: OnboardingRoutes
  private let pause: Duration

  public init(dependencies: OnboardingDependencies, routes: OnboardingRoutes, pause: Duration = grantedPause) {
    self.dependencies = dependencies
    self.routes = routes
    self.pause = pause
    pages = OnboardingPages(hasHealth: dependencies.requestHealth != nil)
    page = pages.first
    if dependencies.microphoneGranted() { microphone = .granted }
  }

  public var showsSkip: Bool {
    pages.showsSkip(on: page)
  }

  public var showsBack: Bool {
    pages.showsBack(on: page)
  }

  public func skip() {
    page = pages.last
  }

  public func back() {
    page = pages.previous(before: page)
  }

  public func next(after current: OnboardingPage) {
    page = pages.next(after: current)
  }

  /// A swipe landed on `page`.
  public func land(on page: OnboardingPage) {
    self.page = page
  }

  public func requestMicrophone() async {
    microphone = .requesting
    let granted = await dependencies.requestMicrophone()
    microphone = granted ? .granted : .notAsked
    await moveOn(from: .microphone, granted: granted)
  }

  public func requestHealth() async {
    guard let request = dependencies.requestHealth else { return }
    health = .requesting
    let granted = await request()
    health = granted ? .granted : .notAsked
    await moveOn(from: .health, granted: granted)
  }

  /// "Start recording" (`true`) or "Just browsing".
  public func finish(startRecording: Bool) {
    routes.finish(health == .granted, startRecording)
  }

  /// "Granted" for a moment, then the next page; denied moves on at once.
  private func moveOn(from current: OnboardingPage, granted: Bool) async {
    if granted { try? await Task.sleep(for: pause) }
    next(after: current)
  }
}
