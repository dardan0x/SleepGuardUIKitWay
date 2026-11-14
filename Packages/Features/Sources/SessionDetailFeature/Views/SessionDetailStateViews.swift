import SleepGuardDesignKit
import SwiftUI

/// Placeholder gauge, stats and rows while the night loads.
struct SessionDetailLoadingView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 24) {
      HStack(spacing: 16) {
        Circle().stroke(theme.palette.bgElevated, lineWidth: 10).frame(width: 120, height: 120)
        VStack(spacing: 12) {
          ForEach(0..<2, id: \.self) { _ in
            RoundedRectangle(cornerRadius: theme.radii.card).fill(theme.palette.bgCard).frame(height: 54)
          }
        }
      }
      ForEach(0..<4, id: \.self) { _ in
        RoundedRectangle(cornerRadius: theme.radii.card).fill(theme.palette.bgCard).frame(height: 50)
      }
      Spacer()
    }
    .padding(20)
    .accessibilityHidden(true)
  }
}

struct SessionDetailErrorView: View {
  let onRetry: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(theme.palette.textTertiary)
        .accessibilityHidden(true)
      Text(Strings.recordingsErrorTitle)
        .font(theme.typography.font(size: 17, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)
      Button(Strings.actionTryAgain, action: onRetry)
        .font(theme.typography.font(size: 17, weight: .semibold))
        .foregroundStyle(theme.palette.accent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
