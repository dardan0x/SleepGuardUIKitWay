import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The profile editor, drawn from `ProfileEditorViewModel` by the shared
/// `ProfileEditorContent`.
public final class ProfileEditorViewController: ScreenController {
  let viewModel: ProfileEditorViewModel
  private var loading: Task<Void, Never>?
  /// Saving, awaited by tests.
  private(set) var finishing: Task<Void, Never>?

  public init(viewModel: ProfileEditorViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    loading?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
    loading = Task { [viewModel] in await viewModel.load() }
  }

  private func redraw() {
    guard viewModel.profile != nil else { return }
    let viewModel = viewModel
    render(ProfileEditorContent(
      // Live, so typing never reads a stale copy.
      profile: Binding(get: { viewModel.profile ?? SleepProfile() }, set: { viewModel.profile = $0 }),
      onSave: { [weak self] in self?.finish(completed: true) },
      onClose: { [weak self] in self?.finish(completed: false) }))
  }

  private func finish(completed: Bool) {
    guard finishing == nil else { return }
    finishing = Task { [viewModel] in await viewModel.finish(completed: completed) }
  }
}
