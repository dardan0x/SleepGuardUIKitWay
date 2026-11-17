import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

public struct SnoreInterrupterRoutes {
  /// The sound picker, starting at `current`; `picked` with the choice.
  public var chooseSound: @MainActor (_ current: Int, _ picked: @escaping @MainActor (Int) -> Void) -> Void
  public var save: @MainActor (SnoreInterrupterChoice) -> Void
  public var cancel: @MainActor () -> Void

  public init(
    chooseSound: @escaping @MainActor (_ current: Int, _ picked: @escaping @MainActor (Int) -> Void) -> Void,
    save: @escaping @MainActor (SnoreInterrupterChoice) -> Void,
    cancel: @escaping @MainActor () -> Void)
  {
    self.chooseSound = chooseSound
    self.save = save
    self.cancel = cancel
  }
}

/// The Snore Interrupter's settings, hosting the shared content: a draft of
/// the choice, saved on Save.
public struct SnoreInterrupterScreen: View {
  let store: any MelodyStore
  let routes: SnoreInterrupterRoutes
  @State private var draft: SnoreInterrupterChoice

  public init(choice: SnoreInterrupterChoice, store: any MelodyStore, routes: SnoreInterrupterRoutes) {
    self.store = store
    self.routes = routes
    _draft = State(initialValue: choice)
  }

  public var body: some View {
    SnoreInterrupterSettingsContent(
      mode: $draft.mode,
      melodyName: Melody.resolve(id: draft.melodyID, custom: store.recordings()).name,
      onSound: { routes.chooseSound(draft.melodyID) { draft.melodyID = $0 } },
      onSave: { routes.save(draft) },
      onCancel: routes.cancel)
  }
}

public struct MelodyPickerRoutes {
  /// Record a new sound; `saved` with it.
  public var record: @MainActor (_ saved: @escaping @MainActor (Melody) -> Void) -> Void
  /// Done, with the chosen melody's id.
  public var done: @MainActor (Int) -> Void

  public init(
    record: @escaping @MainActor (_ saved: @escaping @MainActor (Melody) -> Void) -> Void,
    done: @escaping @MainActor (Int) -> Void)
  {
    self.record = record
    self.done = done
  }
}

/// Choosing the interrupter's sound, hosting the shared picker: a tap chooses
/// and previews (3 s, as SleepGuard's), a second tap stops the preview.
public struct MelodyPickerScreen: View {
  static let previewLength: TimeInterval = 3

  let store: any MelodyStore
  let preview: any MelodyPlayer
  let routes: MelodyPickerRoutes
  @State private var selectedID: Int
  @State private var previewingID: Int?
  @State private var recordings: [Melody] = []

  public init(selectedID: Int, store: any MelodyStore, preview: any MelodyPlayer, routes: MelodyPickerRoutes) {
    self.store = store
    self.preview = preview
    self.routes = routes
    _selectedID = State(initialValue: selectedID)
  }

  public var body: some View {
    MelodyPickerContent(
      custom: recordings, selectedID: selectedID, previewingID: previewingID,
      onRecord: {
        stopPreview()
        routes.record { melody in
          recordings = store.recordings()
          selectedID = melody.id
        }
      },
      onSelect: select,
      onDelete: { melody in
        store.delete(melody)
        recordings = store.recordings()
        if selectedID == melody.id { selectedID = Melody.defaultID }
      },
      onDone: {
        stopPreview()
        routes.done(selectedID)
      })
      .onAppear { recordings = store.recordings() }
      .onDisappear(perform: stopPreview)
  }

  private func select(_ melody: Melody) {
    withAnimation(.spring(duration: 0.25)) { selectedID = melody.id }
    guard previewingID != melody.id, let url = store.url(for: melody) else { return stopPreview() }
    stopPreview()
    if preview.play(url, loops: false, duration: Self.previewLength, onFinish: { previewingID = nil }) {
      previewingID = melody.id
    }
  }

  private func stopPreview() {
    preview.stop()
    previewingID = nil
  }
}
