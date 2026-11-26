import RecordingFeature
import ScreenKit
import SleepCore
import SleepDomain

/// The Snore Interrupter's settings from the prestart: its sheet, the sound
/// picker over it and the recorder over that; Save keeps the choice. Owned by
/// `RecordingFlow`, the way `NightDetailNavigation` is owned by a tab's flow.
final class InterrupterSettingsNavigation {
  private let navigator: any Navigator
  private let factory: RecordingFactory
  private let preferences: any PreferencesStore
  /// Loading the stored choice, then saving a new one; awaited by tests. A
  /// new one cancels the one before.
  private(set) var task: Task<Void, Never>?

  init(navigator: any Navigator, factory: RecordingFactory, preferences: any PreferencesStore) {
    self.navigator = navigator
    self.factory = factory
    self.preferences = preferences
  }

  deinit {
    task?.cancel()
  }

  /// Its settings as a sheet; Save keeps the choice and hands it back to
  /// the prestart's row. Nothing in a brand without the interrupter.
  func open(saved: @escaping @MainActor (SnoreInterrupterChoice) -> Void) {
    guard let store = factory.melodyStore else { return }
    run { [preferences, navigator, factory] in
      let stored = await preferences.load()
      guard !Task.isCancelled else { return }
      let choice = SnoreInterrupterChoice(mode: stored.interrupterMode, melodyID: stored.melodyID)
      navigator.present(style: .sheet(detents: [.large])) { close in
        factory.makeInterrupterSettings(choice: choice, store: store, routes: SnoreInterrupterRoutes(
          chooseSound: { [weak self] current, picked in self?.chooseSound(current: current, store: store, picked: picked) },
          save: { [weak self] choice in
            close()
            saved(choice)
            self?.keep(choice)
          },
          cancel: close))
      }
    }
  }

  private func keep(_ choice: SnoreInterrupterChoice) {
    run { [preferences] in
      var stored = await preferences.load()
      stored.interrupterMode = choice.mode
      stored.melodyID = choice.melodyID
      await preferences.save(stored)
    }
  }

  private func chooseSound(current: Int, store: any MelodyStore, picked: @escaping @MainActor (Int) -> Void) {
    navigator.present(style: .sheet(detents: [.large])) { [factory] close in
      factory.makeMelodyPicker(selectedID: current, store: store, routes: MelodyPickerRoutes(
        record: { [weak self] saved in self?.recordMelody(store: store, saved: saved) },
        done: { id in
          close()
          picked(id)
        }))
    }
  }

  private func recordMelody(store: any MelodyStore, saved: @escaping @MainActor (Melody) -> Void) {
    navigator.present(style: .sheet(detents: [.large])) { [factory] close in
      factory.makeRecordMelody(store: store) { melody in
        close()
        if let melody { saved(melody) }
      }
    }
  }

  /// One task at a time: the one before is cancelled, not leaked.
  private func run(_ operation: @escaping @MainActor () async -> Void) {
    task?.cancel()
    task = Task { await operation() }
  }
}
