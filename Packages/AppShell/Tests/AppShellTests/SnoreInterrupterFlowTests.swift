import AppShellTestSupport
import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import SwiftUI
import Testing
import UIKit
@testable import AppShell
@testable import RecordingFeature
@testable import ScreenKit

/// The Snore Interrupter in the recording flow: a brand without it has no
/// row and no interrupter at night; with it, the settings, picker and
/// recorder open as sheets, and Save keeps the choice.
@MainActor
struct SnoreInterrupterFlowTests {
  private struct Harness {
    let flow: RecordingFlow
    let spy: NavigatorSpy
    let container: Container
    /// Read directly: the container's singleton cache is shared between tests.
    let preferences: FakePreferencesStore
  }

  private func makeFlow(interrupter: Bool, preferences: AppPreferences = AppPreferences()) -> Harness {
    let container = Container.test(brand: TestBrand(snoreInterrupter: interrupter))
    let stored = FakePreferencesStore(preferences)
    container.preferencesStore.register { stored }
    let spy = NavigatorSpy()
    let flow = AppComposition(container: container).recordingFlow(navigator: spy, compactHeight: false) {}
    flow.start()
    return Harness(flow: flow, spy: spy, container: container, preferences: stored)
  }

  private func prestart(_ h: Harness) throws -> RecordingPrestartViewController {
    guard case let .setRoot(controller) = h.spy.calls.first,
          let screen = controller as? RecordingPrestartViewController else { throw Unexpected() }
    return screen
  }

  private func presented<Screen: UIViewController>(_ h: Harness, as _: Screen.Type) throws -> Screen {
    guard case let .present(controller, style) = h.spy.calls.last, style == .sheet(detents: [.large]),
          let screen = controller as? Screen else { throw Unexpected() }
    return screen
  }

  private struct Unexpected: Error {}

  @Test func aBrandWithoutItHasNoRowAndNoInterrupterAtNight() throws {
    let h = makeFlow(interrupter: false, preferences: with(.always))
    #expect(h.container.makeMelodyStore() == nil)
    let screen = try prestart(h)
    #expect(!screen.viewModel.dependencies.hasInterrupter)
    screen.viewModel.routes.openInterrupter { _ in }
    #expect(h.spy.calls.count == 1)
    screen.viewModel.routes.start(with(.always))
    #expect(h.flow.model?.interrupterArmed == false)
  }

  @Test func withItTheNightIsArmedByTheChosenMode() throws {
    let h = makeFlow(interrupter: true)
    #expect(try prestart(h).viewModel.dependencies.hasInterrupter)
    try prestart(h).viewModel.routes.start(with(.fifteenSeconds))
    #expect(h.flow.model?.interrupterArmed == true)
  }

  @Test func offIsNotArmed() throws {
    let h = makeFlow(interrupter: true)
    try prestart(h).viewModel.routes.start(with(.never))
    #expect(h.flow.model?.interrupterArmed == false)
  }

  @Test func savingTheSettingsKeepsTheChoiceAndHandsItBack() async throws {
    let h = makeFlow(interrupter: true)
    var handedBack: SnoreInterrupterChoice?
    try prestart(h).viewModel.routes.openInterrupter { handedBack = $0 }
    await h.flow.interrupter.task?.value
    let settings = try presented(h, as: SnoreInterrupterViewController.self)
    let choice = SnoreInterrupterChoice(mode: .thirtySeconds, melodyID: 3)
    settings.viewModel.routes.save(choice)
    await h.flow.interrupter.task?.value
    #expect(h.spy.calls.last == .dismiss(settings))
    #expect(handedBack == choice)
    let stored = await h.preferences.load()
    #expect(stored.interrupterMode == .thirtySeconds)
    #expect(stored.melodyID == 3)
  }

  @Test func theSoundPickerAndTheRecorderOpenOverIt() async throws {
    let h = makeFlow(interrupter: true)
    try prestart(h).viewModel.routes.openInterrupter { _ in }
    await h.flow.interrupter.task?.value
    var picked: Int?
    try presented(h, as: SnoreInterrupterViewController.self).viewModel.routes.chooseSound(6) { picked = $0 }
    let picker = try presented(h, as: MelodyPickerViewController.self)

    var recorded: Melody?
    picker.viewModel.routes.record { recorded = $0 }
    let recorder = try presented(h, as: RecordMelodyViewController.self)
    let mine = Melody(id: 100, filename: "custom_100.m4a", customName: "Mine")
    recorder.viewModel.done(mine)
    #expect(h.spy.calls.last == .dismiss(recorder))
    #expect(recorded == mine)

    picker.viewModel.routes.done(4)
    #expect(h.spy.calls.last == .dismiss(picker))
    #expect(picked == 4)
  }

  private func with(_ mode: SnoreInterrupterMode) -> AppPreferences {
    var preferences = AppPreferences()
    preferences.interrupterMode = mode
    return preferences
  }
}
