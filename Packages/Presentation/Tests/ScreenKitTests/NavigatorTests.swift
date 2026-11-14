import Testing
import UIKit
@testable import ScreenKit

struct NavigatorTests {
  private let first = UIViewController()
  private let second = UIViewController()
  private let third = UIViewController()

  @Test func setRootReplacesTheStack() {
    let navigator = NavigationControllerNavigator(animated: false)
    navigator.setRoot(first)
    navigator.push(second)
    navigator.setRoot(third)
    #expect(navigator.navigationController.viewControllers == [third])
  }

  @Test func pushPopAndPopToRoot() {
    let navigator = NavigationControllerNavigator(animated: false)
    navigator.setRoot(first)
    navigator.push(second)
    navigator.push(third)
    #expect(navigator.navigationController.viewControllers == [first, second, third])

    navigator.pop()
    #expect(navigator.navigationController.viewControllers == [first, second])

    navigator.push(third)
    navigator.popToRoot()
    #expect(navigator.navigationController.viewControllers == [first])
  }

  @Test func sheetStyleSetsDetentsAndGrabber() throws {
    let navigator = NavigationControllerNavigator(animated: false)
    navigator.configure(second, for: .sheet(detents: [.medium, .large]))
    #expect(second.modalPresentationStyle == .pageSheet)
    let sheet = try #require(second.sheetPresentationController)
    #expect(sheet.detents.map(\.identifier) == [.medium, .large])
    #expect(sheet.prefersGrabberVisible)
  }

  @Test func singleDetentSheetHasNoGrabber() throws {
    let navigator = NavigationControllerNavigator(animated: false)
    navigator.configure(second, for: .sheet(detents: [.large]))
    #expect(try #require(second.sheetPresentationController).prefersGrabberVisible == false)
  }

  @Test func fullScreenStyle() {
    let navigator = NavigationControllerNavigator(animated: false)
    navigator.configure(second, for: .fullScreen)
    #expect(second.modalPresentationStyle == .fullScreen)
  }

  @Test func anAlertKeepsItsOwnStyle() {
    let navigator = NavigationControllerNavigator(animated: false)
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    navigator.configure(alert, for: .alert)
    #expect(alert.modalPresentationStyle == .custom)
  }

  @Test func dismissWithNothingPresentedLeavesTheStackAlone() {
    let navigator = NavigationControllerNavigator(animated: false)
    navigator.setRoot(first)
    navigator.dismiss()
    #expect(navigator.navigationController.viewControllers == [first])
  }

  // Presenting and dismissing for real is checked in the app (F1-T6): package
  // tests have no window scene, and without one UIKit never finishes a
  // presentation, so such a test waits forever.
}
