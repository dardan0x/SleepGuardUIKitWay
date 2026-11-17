import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// The profile editor, drawn by the shared `ProfileEditorContent`. Edits stay
/// on screen until Save or close, then are stored either way (SleepGuard
/// keeps edits on close too); Save also marks the profile completed.
public struct ProfileEditorScreen: View {
  let dependencies: ProfileEditorDependencies
  let routes: ProfileEditorRoutes
  @State private var profile: SleepProfile?

  public init(dependencies: ProfileEditorDependencies, routes: ProfileEditorRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    Group {
      if profile != nil {
        ProfileEditorContent(
          profile: Binding(get: { profile ?? SleepProfile() }, set: { profile = $0 }),
          onSave: { finish(completed: true) },
          onClose: { finish(completed: false) })
      } else {
        Color.clear
      }
    }
    .task {
      profile = await dependencies.profiles.load()
    }
  }

  private func finish(completed: Bool) {
    let profiles = dependencies.profiles
    let preferences = dependencies.preferences
    let edited = profile
    Task {
      if let edited { try? await profiles.save(edited) }
      if completed {
        var stored = await preferences.load()
        stored.hasCompletedProfile = true
        await preferences.save(stored)
      }
      routes.close()
    }
  }
}
