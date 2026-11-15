import SleepGuardDesignKit
import SwiftUI

/// No nights yet: an invitation to record the first one.
struct StatisticsEmptyView: View {
  let onStartRecording: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "moon.fill")
        .font(.system(size: 32))
        .foregroundStyle(theme.palette.accent)
        .frame(width: 80, height: 80)
        .background(theme.palette.accent.opacity(0.15), in: .circle)
        .accessibilityHidden(true)
      VStack(spacing: 4) {
        Text(Strings.sessionPrestartTitle)
          .font(theme.typography.font(size: 20, weight: .semibold))
          .foregroundStyle(theme.palette.textPrimary)
        Text(Strings.statsEmptyMessage)
          .font(theme.typography.font(size: 15))
          .foregroundStyle(theme.palette.textSecondary)
          .multilineTextAlignment(.center)
      }
      StartRecordingButton(height: 56, action: onStartRecording)
        .padding(.top, 10)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Placeholder shapes while the nights load.
struct StatisticsLoadingView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 16) {
      RoundedRectangle(cornerRadius: theme.radii.small).fill(theme.palette.bgCard).frame(height: 64)
      Circle().stroke(theme.palette.bgElevated, lineWidth: 10).frame(width: 120, height: 120)
      ForEach(0..<2, id: \.self) { _ in
        RoundedRectangle(cornerRadius: theme.radii.card).fill(theme.palette.bgCard).frame(height: 54)
      }
      Spacer()
    }
    .padding(20)
    .accessibilityHidden(true)
  }
}
