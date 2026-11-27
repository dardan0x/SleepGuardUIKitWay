import Foundation
import Observation
import SleepCore
import SleepDomain

/// The Snore Interrupter's settings: a draft of the choice, saved on Save.
@MainActor
@Observable
public final class SnoreInterrupterViewModel {
  public private(set) var draft: SnoreInterrupterChoice
  private let store: any MelodyStorePort
  let routes: SnoreInterrupterRoutes

  public init(choice: SnoreInterrupterChoice, store: any MelodyStorePort, routes: SnoreInterrupterRoutes) {
    draft = choice
    self.store = store
    self.routes = routes
  }

  public var melodyName: String {
    Melody.resolve(id: draft.melodyID, custom: store.recordings()).name
  }

  public func setMode(_ mode: SnoreInterrupterMode) {
    draft.mode = mode
  }

  public func chooseSound() {
    routes.chooseSound(draft.melodyID) { [weak self] id in self?.draft.melodyID = id }
  }

  public func save() {
    routes.save(draft)
  }

  public func cancel() {
    routes.cancel()
  }
}
