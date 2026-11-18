import FactoryKit
import ScreenKit
import SettingsFeature
import SleepGuardDesignKit
import UIKit

/// Builds the Settings screens. Wiring only: resolve, build.
struct SettingsScreenComposer {
  let container: Container

  func make(routes: SettingsRoutes) -> UIViewController {
    let device = container.deviceServices()
    #if DEBUG
    let showsDebugRows = true
    #else
    let showsDebugRows = false
    #endif
    return SettingsViewController(
      dependencies: SettingsDependencies(
        preferences: container.preferencesStore(),
        health: container.healthAccess(),
        enforceStorageLimits: container.enforceStorageLimits(),
        deleteAllData: container.deleteAllData(),
        version: device.appVersion(),
        microphone: device.microphone,
        requestMicrophone: { [capture = container.makeAudioCapture()()] in await capture.requestPermission() },
        notifications: device.notifications,
        requestNotifications: device.requestNotifications,
        showsDebugRows: showsDebugRows),
      routes: routes,
      theme: container.theme(),
      chrome: ScreenChrome(title: Strings.tabSettings, largeTitle: true))
  }

  /// The profile editor draws its own handle and buttons: no bar.
  func makeProfileEditor(routes: ProfileEditorRoutes) -> UIViewController {
    ProfileEditorViewController(
      dependencies: ProfileEditorDependencies(profiles: container.profileStore(), preferences: container.preferencesStore()),
      routes: routes,
      theme: container.theme(),
      chrome: ScreenChrome(hidesNavigationBar: true))
  }
}
