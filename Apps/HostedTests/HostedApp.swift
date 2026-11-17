import Foundation
import Testing
import UIKit
@testable import OnboardingFeature
@testable import ScreenKit

/// The running app's tab bar. A fresh install opens on the onboarding, so
/// this finishes it the way "Just browsing" does, then waits for the tabs.
@MainActor
enum HostedApp {
  static func tabBar() async throws -> UITabBarController {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    for _ in 0..<100 {
      for window in scene.windows {
        if let tabs = window.rootViewController as? UITabBarController { return tabs }
        if let navigation = window.rootViewController as? UINavigationController,
           let onboarding = navigation.viewControllers.first as? HostingScreen<OnboardingScreen>
        {
          onboarding.rootView.content.routes.finish(false, false)
        }
      }
      try await Task.sleep(for: .milliseconds(50))
    }
    throw HostedAppError.noTabBar
  }

  enum HostedAppError: Error {
    case noTabBar
  }
}
