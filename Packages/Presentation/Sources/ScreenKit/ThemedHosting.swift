import SleepGuardDesignKit
import SwiftUI
import UIKit

public extension Theme {
  /// A cell's SwiftUI content with this theme in its environment: what a
  /// collection view that isn't a `ScreenController` uses. Creating hosting
  /// configurations or controllers anywhere else is a layering error, so no
  /// SwiftUI content can be drawn without the brand's theme (the
  /// environment's default is SleepGuard's).
  func hosting<Content: View>(@ViewBuilder _ content: () -> Content) -> UIHostingConfiguration<ThemedScreen<Content>, EmptyView> {
    UIHostingConfiguration { ThemedScreen(theme: self, content: content()) }
  }
}

/// A screen's content with the brand theme in its environment.
public struct ThemedScreen<Content: View>: View {
  let theme: Theme
  let content: Content

  public init(theme: Theme, content: Content) {
    self.theme = theme
    self.content = content
  }

  public var body: some View {
    content.environment(\.theme, theme)
  }
}
