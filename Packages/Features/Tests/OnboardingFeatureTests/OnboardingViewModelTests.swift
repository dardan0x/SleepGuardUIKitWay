import SleepCore
import Testing
@testable import OnboardingFeature

/// The Health page comes only with a Health request; permissions are asked
/// through the dependencies and move on; Skip, Back and finishing.
@MainActor
struct OnboardingViewModelTests {
  private func viewModel(
    health: (@MainActor () async -> Bool)?, microphone: @escaping @MainActor () async -> Bool = { true },
    finish: @escaping @MainActor (Bool, Bool) -> Void = { _, _ in }) -> OnboardingViewModel
  {
    OnboardingViewModel(
      dependencies: OnboardingDependencies(
        microphoneGranted: { false }, requestMicrophone: microphone, requestHealth: health),
      routes: OnboardingRoutes(finish: finish),
      pause: .zero)
  }

  @Test func healthOnlyWithAHealthRequest() {
    #expect(viewModel(health: { true }).pages.pages.contains(.health))
    #expect(!viewModel(health: nil).pages.pages.contains(.health))
  }

  @Test func startsOnTheFirstPage() {
    let viewModel = viewModel(health: nil)
    #expect(viewModel.page == viewModel.pages.first)
    #expect(!viewModel.showsBack)
  }

  @Test func aDeniedMicrophoneMovesOnUnasked() async {
    var asked = 0
    let viewModel = viewModel(health: nil, microphone: {
      asked += 1
      return false
    })
    viewModel.land(on: .microphone)
    await viewModel.requestMicrophone()
    #expect(asked == 1)
    #expect(viewModel.microphone == .notAsked)
    #expect(viewModel.page == viewModel.pages.next(after: .microphone))
  }

  @Test func grantedHealthShowsGrantedAndFinishesWithIt() async {
    var finished: [(Bool, Bool)] = []
    let viewModel = viewModel(health: { true }, finish: { finished.append(($0, $1)) })
    viewModel.land(on: .health)
    await viewModel.requestHealth()
    #expect(viewModel.health == .granted)
    #expect(viewModel.page == viewModel.pages.next(after: .health))
    viewModel.finish(startRecording: true)
    #expect(finished.map(\.0) == [true])
    #expect(finished.map(\.1) == [true])
  }

  @Test func skipAndBack() {
    let viewModel = viewModel(health: { true })
    viewModel.skip()
    #expect(viewModel.page == viewModel.pages.last)
    viewModel.back()
    #expect(viewModel.page == viewModel.pages.previous(before: viewModel.pages.last))
  }
}
