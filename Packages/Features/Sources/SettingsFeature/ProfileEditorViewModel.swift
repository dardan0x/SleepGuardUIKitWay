import Foundation
import Observation
import SleepCore
import SleepDomain

/// The profile editor's draft. Edits stay here until Save or close, then are
/// stored either way (SleepGuard keeps edits on close too); Save also marks
/// the profile completed.
@MainActor
@Observable
public final class ProfileEditorViewModel {
  /// `nil` until loaded.
  public var profile: SleepProfile?
  let dependencies: ProfileEditorDependencies
  let routes: ProfileEditorRoutes
  private var finished = false

  public init(dependencies: ProfileEditorDependencies, routes: ProfileEditorRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public func load() async {
    let loaded = await dependencies.profiles.load()
    if !Task.isCancelled { profile = loaded }
  }

  /// Saves (once), then closes. `completed`: Save rather than close.
  public func finish(completed: Bool) async {
    guard !finished else { return }
    finished = true
    if let profile { try? await dependencies.profiles.save(profile) }
    if completed {
      var stored = await dependencies.preferences.load()
      stored.hasCompletedProfile = true
      await dependencies.preferences.save(stored)
    }
    routes.close()
  }
}
