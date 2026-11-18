import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// First launch: a `UIPageViewController` over the shared onboarding pages,
/// with Skip above and the shared dots and Back below. Asks for Apple Health
/// (in a brand that has it) and the microphone, then finishes. A granted
/// permission shows for a moment before the next page, as in SleepGuard.
public final class OnboardingViewController: ScreenController {
  static let grantedPause: Duration = .seconds(0.8)

  let dependencies: OnboardingDependencies
  let routes: OnboardingRoutes
  let pages: OnboardingPages
  private(set) var page: OnboardingPage
  private(set) var microphone = OnboardingPermission.notAsked
  private(set) var health = OnboardingPermission.notAsked
  private(set) var requesting: Task<Void, Never>?
  private let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
  private var pageControllers: [OnboardingPage: UIHostingController<ThemedScreen<OnboardingPageView>>] = [:]
  private lazy var dots = host(OnboardingDots(pages: pages.pages, current: page))
  private lazy var skip = textButton(Strings.actionSkip) { [weak self] in self.map { $0.move(to: $0.pages.last) } }
  private lazy var back = textButton(Strings.actionBack) { [weak self] in
    self.map { $0.move(to: $0.pages.previous(before: $0.page)) }
  }

  public init(dependencies: OnboardingDependencies, routes: OnboardingRoutes, theme: Theme, chrome: ScreenChrome) {
    self.dependencies = dependencies
    self.routes = routes
    pages = OnboardingPages(hasHealth: dependencies.requestHealth != nil)
    page = pages.first
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    requesting?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    if dependencies.microphoneGranted() { microphone = .granted }
    for page in pages.pages {
      pageControllers[page] = host(pageView(page))
    }
    pager.dataSource = self
    pager.delegate = self
    pager.setViewControllers([pageControllers[page]].compactMap(\.self), direction: .forward, animated: false)
    dots.sizingOptions = .intrinsicContentSize
    OnboardingLayout.arrange(in: self, pager: pager, skip: skip, dots: dots, back: back)
    refresh()
  }

  /// Moves to `page` (Skip, Back, a page's buttons, after a permission).
  func move(to target: OnboardingPage) {
    guard target != page, let controller = pageControllers[target] else { return }
    let forward = (pages.pages.firstIndex(of: target) ?? 0) > (pages.pages.firstIndex(of: page) ?? 0)
    page = target
    pager.setViewControllers([controller], direction: forward ? .forward : .reverse, animated: viewIfLoaded?.window != nil)
    refresh()
  }

  func requestMicrophone() async {
    microphone = .requesting
    refresh()
    let granted = await dependencies.requestMicrophone()
    microphone = granted ? .granted : .notAsked
    await moveOn(from: .microphone, granted: granted)
  }

  func requestHealth() async {
    guard let request = dependencies.requestHealth else { return }
    health = .requesting
    refresh()
    let granted = await request()
    health = granted ? .granted : .notAsked
    await moveOn(from: .health, granted: granted)
  }

  /// "Granted" for a moment, then the next page; denied moves on at once.
  private func moveOn(from current: OnboardingPage, granted: Bool) async {
    refresh()
    if granted { try? await Task.sleep(for: Self.grantedPause) }
    move(to: pages.next(after: current))
  }

  private func start(_ request: @escaping @MainActor (OnboardingViewController) async -> Void) {
    guard requesting == nil else { return }
    requesting = Task { [weak self] in
      guard let self else { return }
      await request(self)
      requesting = nil
    }
  }

  /// Redraws the pages (permission states), the dots and the buttons.
  private func refresh() {
    for (page, controller) in pageControllers {
      controller.rootView = ThemedScreen(theme: theme, content: pageView(page))
    }
    dots.rootView = ThemedScreen(theme: theme, content: OnboardingDots(pages: pages.pages, current: page))
    skip.isHidden = !pages.showsSkip(on: page)
    back.alpha = pages.showsBack(on: page) ? 1 : 0
    back.isEnabled = pages.showsBack(on: page)
  }

  private func pageView(_ page: OnboardingPage) -> OnboardingPageView {
    OnboardingPageView(
      page: page, microphone: microphone, health: health,
      onNext: { [weak self] in self.map { $0.move(to: $0.pages.next(after: page)) } },
      onRequestMicrophone: { [weak self] in self?.start { await $0.requestMicrophone() } },
      onRequestHealth: { [weak self] in self?.start { await $0.requestHealth() } },
      onStartRecording: { [weak self] in self.map { $0.routes.finish($0.health == .granted, true) } },
      onBrowse: { [weak self] in self.map { $0.routes.finish($0.health == .granted, false) } })
  }

  private func textButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    var configuration = UIButton.Configuration.plain()
    configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([
      .font: theme.typography.uiFont(size: 15, weight: .medium),
      .foregroundColor: UIColor(theme.palette.textSecondary),
    ]))
    return UIButton(configuration: configuration, primaryAction: UIAction { _ in action() })
  }
}

extension OnboardingViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  public func pageViewController(_: UIPageViewController, viewControllerBefore controller: UIViewController) -> UIViewController? {
    neighbour(of: controller, offset: -1)
  }

  public func pageViewController(_: UIPageViewController, viewControllerAfter controller: UIViewController) -> UIViewController? {
    neighbour(of: controller, offset: 1)
  }

  /// A swipe landed on a page.
  public func pageViewController(
    _ pager: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController],
    transitionCompleted completed: Bool)
  {
    guard completed, let shown = pager.viewControllers?.first, let landed = page(of: shown) else { return }
    page = landed
    refresh()
  }

  private func page(of controller: UIViewController) -> OnboardingPage? {
    pageControllers.first { $0.value === controller }?.key
  }

  private func neighbour(of controller: UIViewController, offset: Int) -> UIViewController? {
    guard let current = page(of: controller), let index = pages.pages.firstIndex(of: current) else { return nil }
    let next = index + offset
    return pages.pages.indices.contains(next) ? pageControllers[pages.pages[next]] : nil
  }
}
