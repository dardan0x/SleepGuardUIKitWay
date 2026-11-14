import SleepGuardDesignKit
import SwiftUI

/// Temporary content for every tab until its feature exists. Built the way a
/// real screen is (plain values in, `Routes` closures out, theme from the
/// environment), so the shell's wiring is exercised end to end. Deleted once
/// every tab has a real flow.
struct PlaceholderScreen: View {
  let iconName: String
  let routes: PlaceholderRoutes
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: iconName)
        .font(.system(size: 44, weight: .semibold))
        .foregroundStyle(theme.palette.accent)
        .accessibilityHidden(true)

      Button(action: routes.showDetails) {
        Text(Strings.actionContinue)
          .font(theme.typography.font(size: 17, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.small))
      }
      .buttonStyle(ScaleButtonStyle())

      if let close = routes.close {
        Button(Strings.actionClose, action: close)
          .foregroundStyle(theme.palette.accent)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.palette.bgPrimary)
  }
}

struct PlaceholderRoutes {
  var showDetails: @MainActor () -> Void
  /// Only on a presented placeholder.
  var close: (@MainActor () -> Void)?
}
