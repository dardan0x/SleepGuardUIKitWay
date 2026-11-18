import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The profile editor, drawn by the shared `ProfileEditorContent`. Edits stay
/// on screen until Save or close, then are stored either way (SleepGuard
/// keeps edits on close too); Save also marks the profile completed.
public final class ProfileEditorViewController: ScreenController {
  let dependencies: ProfileEditorDependencies
  let routes: ProfileEditorRoutes
  private(set) var profile: SleepProfile?
  private var loading: Task<Void, Never>?
  /// Saving, awaited by tests.
  private(set) var finishing: Task<Void, Never>?

  public init(dependencies: ProfileEditorDependencies, routes: ProfileEditorRoutes, theme: Theme, chrome: ScreenChrome) {
    self.dependencies = dependencies
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    loading?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    loading = Task { [weak self, dependencies] in
      let profile = await dependencies.profiles.load()
      guard !Task.isCancelled else { return }
      self?.profile = profile
      self?.redraw()
    }
  }

  private func redraw() {
    guard profile != nil else { return }
    render(ProfileEditorContent(
      profile: Binding(
        get: { [weak self] in self?.profile ?? SleepProfile() },
        set: { [weak self] in
          self?.profile = $0
          self?.redraw()
        }),
      onSave: { [weak self] in self?.finish(completed: true) },
      onClose: { [weak self] in self?.finish(completed: false) }))
  }

  func finish(completed: Bool) {
    guard finishing == nil else { return }
    let (profiles, preferences, edited, close) = (dependencies.profiles, dependencies.preferences, profile, routes.close)
    finishing = Task {
      if let edited { try? await profiles.save(edited) }
      if completed {
        var stored = await preferences.load()
        stored.hasCompletedProfile = true
        await preferences.save(stored)
      }
      close()
    }
  }
}
