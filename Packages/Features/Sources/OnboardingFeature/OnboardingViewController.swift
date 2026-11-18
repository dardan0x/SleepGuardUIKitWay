import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// First launch, drawn from `OnboardingViewModel`: a `UIPageViewController`
/// over the shared onboarding pages, with Skip above and the shared dots and
/// Back below. Follows the view model's page; reports swipes to it.
public final class OnboardingViewController: ScreenController {
  let viewModel: OnboardingViewModel
  private(set) var requesting: Task<Void, Never>?
  private let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
  private var pageControllers: [OnboardingPage: UIHostingController<ThemedScreen<OnboardingPageView>>] = [:]
  private var shownPage: OnboardingPage?
  private lazy var dots = host(OnboardingDots(pages: viewModel.pages.pages, current: viewModel.page))
  private lazy var skip = textButton(Strings.actionSkip) { [weak self] in self?.viewModel.skip() }
  private lazy var back = textButton(Strings.actionBack) { [weak self] in self?.viewModel.back() }

  public init(viewModel: OnboardingViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    requesting?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    for page in viewModel.pages.pages {
      pageControllers[page] = host(pageView(page))
    }
    pager.dataSource = self
    pager.delegate = self
    dots.sizingOptions = .intrinsicContentSize
    OnboardingLayout.arrange(in: self, pager: pager, skip: skip, dots: dots, back: back)
    renderTracking { [weak self] in self?.render() }
  }

  /// Redraws the pages (permission states), the dots and the buttons, and
  /// turns to the view model's page.
  private func render() {
    let page = viewModel.page
    for (page, controller) in pageControllers {
      controller.rootView = ThemedScreen(theme: theme, content: pageView(page))
    }
    dots.rootView = ThemedScreen(theme: theme, content: OnboardingDots(pages: viewModel.pages.pages, current: page))
    skip.isHidden = !viewModel.showsSkip
    back.alpha = viewModel.showsBack ? 1 : 0
    back.isEnabled = viewModel.showsBack
    turn(to: page)
  }

  private func turn(to page: OnboardingPage) {
    guard page != shownPage, let controller = pageControllers[page] else { return }
    let pages = viewModel.pages.pages
    let forward = (pages.firstIndex(of: page) ?? 0) >= (shownPage.flatMap { pages.firstIndex(of: $0) } ?? 0)
    let animated = shownPage != nil && viewIfLoaded?.window != nil
    shownPage = page
    pager.setViewControllers([controller], direction: forward ? .forward : .reverse, animated: animated)
  }

  private func pageView(_ page: OnboardingPage) -> OnboardingPageView {
    let viewModel = viewModel
    return OnboardingPageView(
      page: page, microphone: Self.content(viewModel.microphone), health: Self.content(viewModel.health),
      onNext: { viewModel.next(after: page) },
      onRequestMicrophone: { [weak self] in self?.start { await viewModel.requestMicrophone() } },
      onRequestHealth: { [weak self] in self?.start { await viewModel.requestHealth() } },
      onStartRecording: { viewModel.finish(startRecording: true) },
      onBrowse: { viewModel.finish(startRecording: false) })
  }

  private func start(_ request: @escaping @MainActor () async -> Void) {
    guard requesting == nil else { return }
    requesting = Task { [weak self] in
      await request()
      self?.requesting = nil
    }
  }

  private static func content(_ permission: OnboardingViewModel.Permission) -> OnboardingPermission {
    switch permission {
    case .notAsked: .notAsked
    case .requesting: .requesting
    case .granted: .granted
    }
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
    shownPage = landed
    viewModel.land(on: landed)
  }

  private func page(of controller: UIViewController) -> OnboardingPage? {
    pageControllers.first { $0.value === controller }?.key
  }

  private func neighbour(of controller: UIViewController, offset: Int) -> UIViewController? {
    let pages = viewModel.pages.pages
    guard let current = page(of: controller), let index = pages.firstIndex(of: current) else { return nil }
    let next = index + offset
    return pages.indices.contains(next) ? pageControllers[pages[next]] : nil
  }
}
