import Foundation
import Observation
import SleepCore
import SleepDomain

/// Choosing the interrupter's sound: a tap chooses and previews (3 s, as
/// SleepGuard's), a second tap stops the preview; recordings can be added
/// and deleted.
@MainActor
@Observable
public final class MelodyPickerViewModel {
  static let previewLength: TimeInterval = 3

  public private(set) var selectedID: Int
  public private(set) var previewingID: Int?
  public private(set) var recordings: [Melody] = []
  private let store: any MelodyStorePort
  private let preview: any MelodyPlayerPort
  let routes: MelodyPickerRoutes

  public init(selectedID: Int, store: any MelodyStorePort, preview: any MelodyPlayerPort, routes: MelodyPickerRoutes) {
    self.selectedID = selectedID
    self.store = store
    self.preview = preview
    self.routes = routes
  }

  public func reload() {
    recordings = store.recordings()
  }

  public func select(_ melody: Melody) {
    selectedID = melody.id
    guard previewingID != melody.id, let url = store.url(for: melody) else { return stopPreview() }
    stopPreview()
    if preview.play(url, loops: false, duration: Self.previewLength, onFinish: { [weak self] in self?.previewingID = nil }) {
      previewingID = melody.id
    }
  }

  public func record() {
    stopPreview()
    routes.record { [weak self] melody in
      self?.reload()
      self?.selectedID = melody.id
    }
  }

  public func delete(_ melody: Melody) {
    store.delete(melody)
    reload()
    if selectedID == melody.id { selectedID = Melody.defaultID }
  }

  public func done() {
    stopPreview()
    routes.done(selectedID)
  }

  public func stopPreview() {
    preview.stop()
    previewingID = nil
  }
}
