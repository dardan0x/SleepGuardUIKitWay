import AppShellTestSupport
import FactoryKit
import Foundation
import Testing
import UIKit
@testable import AppShell
@testable import LearnFeature
@testable import ScreenKit
import SleepGuardDesignKit

/// The Learn tab shows the brand's page, or the empty state without one.
@MainActor
struct LearnFlowTests {
  private func root(learnURL: URL?) throws -> HostingScreen<LearnScreen> {
    let spy = NavigatorSpy()
    let flow = LearnFlow(navigator: spy, container: Container.test(brand: TestBrand(tabs: [.learn], learnURL: learnURL)))
    flow.start()
    guard case let .setRoot(controller) = spy.calls.first,
          let screen = controller as? HostingScreen<LearnScreen> else { throw Unexpected() }
    return screen
  }

  private struct Unexpected: Error {}

  @Test func theBrandsPageIsShown() throws {
    let url = try #require(URL(string: "https://example.com/learn"))
    let screen = try root(learnURL: url)
    #expect(screen.rootView.content.url == url)
    #expect(screen.navigationItem.title == Strings.tabLearn)
  }

  @Test func withoutAPageTheEmptyStateShows() throws {
    #expect(try root(learnURL: nil).rootView.content.url == nil)
  }
}
