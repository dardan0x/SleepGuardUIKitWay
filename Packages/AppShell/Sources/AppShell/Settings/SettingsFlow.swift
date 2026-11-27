import ScreenKit
import SettingsFeature
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
  /// Debug builds: writes the sample nights into the store; `nil` in Release.
  private let seedSampleNights: (@MainActor () -> Task<Void, Never>)?
  /// Debug: re-seeding the sample nights; awaited by tests.
  private(set) var seeding: Task<Void, Never>?

  init(
    navigator: any Navigator,
    factory: SettingsFactory,
    device: DeviceServices,
    appStoreID: String?,
    seedSampleNights: (@MainActor () -> Task<Void, Never>)?)
  {
    self.navigator = navigator
    self.factory = factory
    self.device = device
    self.appStoreID = appStoreID
    self.seedSampleNights = seedSampleNights
  }

  func start() {
    var addSampleNights: (@MainActor () -> Void)?
    if seedSampleNights != nil {
      addSampleNights = { [weak self] in self?.addSampleNights() }
    }
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
    navigator.present(style: .sheet(detents: [.large])) { [factory] close in
      factory.makeProfileEditor(routes: ProfileEditorRoutes(close: close))
    }
  }

  private func addSampleNights() {
    seeding = seedSampleNights?()
  }
}
