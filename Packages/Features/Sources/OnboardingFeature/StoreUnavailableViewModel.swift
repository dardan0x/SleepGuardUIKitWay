import Foundation
import Observation

/// "We couldn't open your sleep data": shown at launch instead of the app
/// when the nights database didn't open. The only way out is an update, when
/// the brand has an App Store page (`update` is `nil` otherwise).
@MainActor
@Observable
public final class StoreUnavailableViewModel {
  public let update: (@MainActor () -> Void)?

  public init(update: (@MainActor () -> Void)?) {
    self.update = update
  }
}
