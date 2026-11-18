import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
@testable import SettingsFeature

/// Changes are written in order; a lower storage limit asks first; deleting
/// everything asks first; Health sync turns on only when allowed.
@MainActor
struct SettingsViewModelTests {
  private func viewModel(
    _ store: FakePreferencesStore, health: (any HealthAccess)? = nil) -> SettingsViewModel
  {
    let sessions = FakeSessionRepository()
    let files = FakeSessionFileStore()
    let checkpoints = FakeRecordingCheckpointStore()
    return SettingsViewModel(
      dependencies: SettingsDependencies(
        preferences: store, health: health,
        enforceStorageLimits: EnforceStorageLimits(
          sessions: sessions, files: files, checkpoints: checkpoints, preferences: store),
        deleteAllData: DeleteAllData(sessions: sessions, files: files, checkpoints: checkpoints),
        version: "1.0", microphone: { .granted }, requestMicrophone: { true },
        notifications: { .granted }, requestNotifications: { true }, showsDebugRows: false),
      routes: SettingsRoutes(openProfile: {}, openSystemSettings: {}, rateApp: nil, addSampleNights: nil))
  }

  @Test func changesAreWrittenInOrder() async {
    let store = FakePreferencesStore()
    let viewModel = viewModel(store)
    await viewModel.load()
    viewModel.change { $0.maxDays = 10 }
    viewModel.change { $0.maxDays = 20 }
    await viewModel.working?.value
    #expect(await store.preferences.maxDays == 20)
    #expect(viewModel.preferences?.maxDays == 20)
  }

  @Test func aLowerStorageLimitAsksFirst() async {
    var preferences = AppPreferences()
    preferences.storageLimitMB = 1000
    let store = FakePreferencesStore(preferences)
    let viewModel = viewModel(store)
    await viewModel.load()

    viewModel.setStorageLimit(megabytes: 500)
    #expect(viewModel.alert == .confirmLowerLimit(megabytes: 500))
    #expect(viewModel.preferences?.storageLimitMB == 1000)

    viewModel.confirmLowerLimit()
    await viewModel.working?.value
    #expect(viewModel.preferences?.storageLimitMB == 500)
    #expect(await store.preferences.storageLimitMB == 500)
  }

  @Test func aHigherLimitIsKeptAtOnce() async {
    let viewModel = viewModel(FakePreferencesStore())
    await viewModel.load()
    let higher = (viewModel.preferences?.storageLimitMB ?? 0) + 100
    viewModel.setStorageLimit(megabytes: higher)
    #expect(viewModel.alert == nil)
    #expect(viewModel.preferences?.storageLimitMB == higher)
  }

  @Test func deletingEverythingAsksFirst() async {
    let viewModel = viewModel(FakePreferencesStore())
    await viewModel.load()
    viewModel.askToDeleteAll()
    #expect(viewModel.alert == .confirmDeleteAll)
    viewModel.confirmDeleteAll()
    await viewModel.working?.value
    #expect(viewModel.alert == nil)
  }

  @Test func healthSyncFollowsTheAnswer() async {
    let store = FakePreferencesStore()
    let viewModel = viewModel(store, health: FakeHealthAccess(granted: false))
    await viewModel.load()
    viewModel.setHealthSync(true)
    await viewModel.working?.value
    await viewModel.working?.value
    #expect(viewModel.preferences?.syncToHealth == false)
  }
}
