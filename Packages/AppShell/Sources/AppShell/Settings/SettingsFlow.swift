import FactoryKit
import ScreenKit
import SettingsFeature
import SleepAudio
import SleepDomain
import UIKit

/// The Settings tab: Settings, and the profile editor as a sheet over it.
/// Opens the system Settings for a denied permission, and the App Store page
/// when the brand has one.
final class SettingsFlow: TabFlow {
  let tab = AppTab.settings
  let navigator: any Navigator
  private let factory: SettingsFactory
  private let device: DeviceServices
  private let appStoreID: String?
  private let container: Container
  /// Debug: re-seeding the sample nights; awaited by tests.
  private(set) var seeding: Task<Void, Never>?

  init(navigator: any Navigator, container: Container) {
    self.navigator = navigator
    self.container = container
    factory = SettingsFactory(container: container)
    device = container.deviceServices()
    appStoreID = container.brand().configuration.appStoreID
  }

  func start() {
    #if DEBUG
    let addSampleNights: (@MainActor () -> Void)? = { [weak self] in self?.addSampleNights() }
    #else
    let addSampleNights: (@MainActor () -> Void)? = nil
    #endif
    var rateApp: (@MainActor () -> Void)?
    if let url = appStoreID.flatMap(Self.reviewURL(appStoreID:)) {
      rateApp = { [device] in device.openURL(url) }
    }
    navigator.setRoot(factory.make(routes: SettingsRoutes(
      openProfile: { [weak self] in self?.openProfile() },
      openSystemSettings: device.openSettings,
      rateApp: rateApp,
      addSampleNights: addSampleNights)))
  }

  /// The App Store's write-a-review page.
  static func reviewURL(appStoreID: String) -> URL? {
    URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
  }

  private func openProfile() {
    navigator.present(
      factory.makeProfileEditor(routes: ProfileEditorRoutes(close: { [weak self] in self?.navigator.dismiss() })),
      style: .sheet(detents: [.large]))
  }

  #if DEBUG
  private func addSampleNights() {
    let repository = container.sessionRepository()
    let clips = container.storageLocation().clipsDirectory
    seeding = Task {
      do {
        try await SampleNights.seed(repository) { name, seconds, intensity in
          try SleepAudio.writeSampleClip(to: clips.appendingPathComponent(name), seconds: seconds, intensity: intensity)
        }
      } catch {
        Log.storage.error("Seeding sample nights failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
  #endif
}
