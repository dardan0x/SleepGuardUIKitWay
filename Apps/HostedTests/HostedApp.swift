import Foundation
import Testing
import UIKit
@testable import BriefingFeature
@testable import OnboardingFeature
@testable import ScreenKit

/// The running app's tab bar. A fresh install opens on the onboarding, so
/// this finishes it the way "Just browsing" does, then waits for the tabs;
/// the morning briefing that the sample nights bring is closed, as a person
/// would (it shows once).
@MainActor
enum HostedApp {
  static func tabBar() async throws -> UITabBarController {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    for _ in 0..<100 {
      for window in scene.windows {
        if let tabs = window.rootViewController as? UITabBarController {
          await closeBriefing(over: tabs)
          return tabs
        }
        if let navigation = window.rootViewController as? UINavigationController,
           let onboarding = navigation.viewControllers.first as? OnboardingViewController
        {
          onboarding.viewModel.routes.finish(false, false)
        }
      }
      try await Task.sleep(for: .milliseconds(50))
    }
    throw HostedAppError.noTabBar
  }

  /// Waits a moment for the briefing; closes it if it comes.
  private static func closeBriefing(over tabs: UITabBarController) async {
    for _ in 0..<40 {
      if let briefing = tabs.presentedViewController as? BriefingViewController {
        briefing.viewModel.close()
        while tabs.presentedViewController != nil {
          try? await Task.sleep(for: .milliseconds(50))
        }
        return
      }
      if tabs.presentedViewController != nil { return }
      try? await Task.sleep(for: .milliseconds(50))
    }
  }

  enum HostedAppError: Error {
    case noTabBar
  }
}
