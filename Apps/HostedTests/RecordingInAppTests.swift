import FactoryKit
import Foundation
import Testing
import UIKit
@testable import AppShell
@testable import RecordingFeature
@testable import ScreenKit
@testable import StatisticsFeature

/// The recording flow inside the running app: Start Recording on the
/// dashboard presents the prestart full screen over the tabs, and Cancel
/// takes it away. It stops before the microphone: a hosted test can't answer
/// the permission prompt. Set `TEST_RUNNER_SCREENSHOT_HOLD` (seconds) to
/// pause on the prestart for an outside `simctl io screenshot`.
@MainActor
struct RecordingInAppTests {
  @Test func startRecordingPresentsThePrestartFullScreenAndCancelCloses() async throws {
    let tabs = try await HostedApp.tabBar()
    let index = try #require(Container.shared.brand().configuration.tabs.firstIndex(of: .statistics))
    tabs.selectedIndex = index
    let navigation = try #require(tabs.selectedViewController as? UINavigationController)
    navigation.popToRootViewController(animated: false)
    let dashboard = try #require(navigation.viewControllers.first as? StatisticsViewController)

    dashboard.viewModel.routes.startRecording()

    let modal = try #require(await until { tabs.presentedViewController as? UINavigationController })
    #expect(modal.modalPresentationStyle == .fullScreen)
    let prestart = try #require(modal.viewControllers.first as? RecordingPrestartViewController)
    _ = await until { modal.isNavigationBarHidden ? true : nil }
    #expect(modal.isNavigationBarHidden)
    try await hold()

    prestart.viewModel.routes.cancel()
    let gone = await until { tabs.presentedViewController == nil ? true : nil }
    #expect(gone == true)
  }

  private func hold() async throws {
    if let seconds = ProcessInfo.processInfo.environment["SCREENSHOT_HOLD"].flatMap(Double.init) {
      try await Task.sleep(for: .seconds(seconds))
    }
  }

  /// Polls (UIKit transitions have no completion to await here) for up to 5 s.
  private func until<T>(_ condition: () -> T?) async -> T? {
    for _ in 0..<50 {
      if let value = condition() { return value }
      try? await Task.sleep(for: .milliseconds(100))
    }
    return nil
  }
}
