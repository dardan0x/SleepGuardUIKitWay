import FactoryKit
import ScreenKit
import SettingsFeature
import SleepGuardDesignKit
import SleepStrings
import UIKit

/// Builds the Settings screens: dependencies, then the view model, then the
/// screen (ADR 0008). Wiring only.
struct SettingsFactory {
  let container: Container

  func make(routes: SettingsRoutes) -> UIViewController {
    let device = container.deviceServices()
    #if DEBUG
    let showsDebugRows = true
    #else
    let showsDebugRows = false
    #endif
    let dependencies = SettingsDependencies(
      preferences: container.preferencesStore(),
      health: container.healthAccess(),
      enforceStorageLimits: container.enforceStorageLimits(),
      deleteAllData: container.deleteAllData(),
      version: device.appVersion(),
      microphone: device.microphone,
      requestMicrophone: { [capture = container.makeAudioCapture()()] in await capture.requestPermission() },
      notifications: device.notifications,
      requestNotifications: device.requestNotifications,
      showsDebugRows: showsDebugRows)
    return SettingsViewController(
      viewModel: SettingsViewModel(dependencies: dependencies, routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(title: Strings.tabSettings, hidesNavigationBar: true))
  }

  /// The profile editor draws its own handle and buttons: no bar.
  func makeProfileEditor(routes: ProfileEditorRoutes) -> UIViewController {
    let dependencies = ProfileEditorDependencies(profiles: container.profileStore(), preferences: container.preferencesStore())
    return ProfileEditorViewController(
      viewModel: ProfileEditorViewModel(dependencies: dependencies, routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(hidesNavigationBar: true))
  }
}
