import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The Snore Interrupter's settings, in the shared content: a draft of the
/// choice, saved on Save.
public final class SnoreInterrupterViewController: ScreenController {
  let store: any MelodyStore
  let routes: SnoreInterrupterRoutes
  private(set) var draft: SnoreInterrupterChoice

  public init(
    choice: SnoreInterrupterChoice, store: any MelodyStore, routes: SnoreInterrupterRoutes, theme: Theme,
    chrome: ScreenChrome)
  {
    self.store = store
    self.routes = routes
    draft = choice
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    redraw()
  }

  private func redraw() {
    let mode = Binding(get: { [weak self] in self?.draft.mode ?? .never }, set: { [weak self] in self?.setMode($0) })
    let routes = routes
    render(SnoreInterrupterSettingsContent(
      mode: mode,
      melodyName: Melody.resolve(id: draft.melodyID, custom: store.recordings()).name,
      onSound: { [weak self] in self?.chooseSound() },
      onSave: { [weak self] in self.map { routes.save($0.draft) } },
      onCancel: routes.cancel))
  }

  func setMode(_ mode: SnoreInterrupterMode) {
    draft.mode = mode
    redraw()
  }

  private func chooseSound() {
    routes.chooseSound(draft.melodyID) { [weak self] id in
      self?.draft.melodyID = id
      self?.redraw()
    }
  }
}

/// Choosing the interrupter's sound, in the shared picker: a tap chooses and
/// previews (3 s, as SleepGuard's), a second tap stops the preview.
public final class MelodyPickerViewController: ScreenController {
  static let previewLength: TimeInterval = 3

  let store: any MelodyStore
  let preview: any MelodyPlayer
  let routes: MelodyPickerRoutes
  private(set) var selectedID: Int
  private(set) var previewingID: Int?
  private var recordings: [Melody] = []

  public init(
    selectedID: Int, store: any MelodyStore, preview: any MelodyPlayer, routes: MelodyPickerRoutes, theme: Theme,
    chrome: ScreenChrome)
  {
    self.store = store
    self.preview = preview
    self.routes = routes
    self.selectedID = selectedID
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    recordings = store.recordings()
    redraw()
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopPreview()
  }

  private func redraw() {
    render(MelodyPickerContent(
      custom: recordings, selectedID: selectedID, previewingID: previewingID,
      onRecord: { [weak self] in self?.record() },
      onSelect: { [weak self] in self?.select($0) },
      onDelete: { [weak self] in self?.delete($0) },
      onDone: { [weak self] in
        guard let self else { return }
        stopPreview()
        routes.done(selectedID)
      }))
  }

  private func record() {
    stopPreview()
    routes.record { [weak self] melody in
      guard let self else { return }
      recordings = store.recordings()
      selectedID = melody.id
      redraw()
    }
  }

  private func delete(_ melody: Melody) {
    store.delete(melody)
    recordings = store.recordings()
    if selectedID == melody.id { selectedID = Melody.defaultID }
    redraw()
  }

  func select(_ melody: Melody) {
    selectedID = melody.id
    guard previewingID != melody.id, let url = store.url(for: melody) else { return stopPreview() }
    stopPreview()
    if preview.play(url, loops: false, duration: Self.previewLength, onFinish: { [weak self] in
      self?.previewingID = nil
      self?.redraw()
    }) {
      previewingID = melody.id
    }
    redraw()
  }

  private func stopPreview() {
    preview.stop()
    previewingID = nil
    redraw()
  }
}
