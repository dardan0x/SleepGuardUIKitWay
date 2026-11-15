import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// Plays a night's event clips (`ClipPlaybackModel`, built by the shell):
/// the playing event, a seek bar, back / play / forward, enhanced audio, and
/// the events to pick from. Starts on appear; releases the player on close.
public struct PlayerScreen: View {
  @Bindable var model: ClipPlaybackModel
  @Environment(\.theme) private var theme

  public init(model: ClipPlaybackModel) {
    self.model = model
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        if let event = model.currentEvent, model.hasAudio {
          PlayerCard(model: model, event: event)
          EnhancedAudioToggle(isOn: $model.isEnhanced)
          if model.events.count > 1 {
            PlayerEventList(model: model)
          }
        } else if let event = model.currentEvent {
          NoAudioCard(start: event.start, duration: event.duration, intensity: event.intensity)
        }
      }
      .padding(20)
    }
    .onAppear { model.start() }
    .onDisappear { model.close() }
  }
}

/// Header, seek bar, controls and the loudness key.
struct PlayerCard: View {
  let model: ClipPlaybackModel
  let event: NightEvent
  @Environment(\.theme) private var theme

  var body: some View {
    let playlist = model.playlist
    VStack(spacing: 24) {
      PlayerHeader(
        start: event.start, duration: playlist.totalDuration, intensity: event.intensity,
        number: playlist.index + 1, count: playlist.clips.count)
      PlayerProgress(currentTime: playlist.currentTime, totalDuration: playlist.totalDuration) {
        model.seek(toProgress: $0)
      }
      PlayerControls(
        isPlaying: model.isPlaying,
        onToggle: { model.togglePlayback() },
        onBack: { skip(-15) },
        onForward: { skip(15) })
      EventIntensityLegend()
    }
    .padding(20)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }

  /// Jumps 15 s on the joined timeline, as SleepGuard's player does.
  private func skip(_ seconds: TimeInterval) {
    let total = model.playlist.totalDuration
    guard total > 0 else { return }
    model.seek(toProgress: max(0, model.playlist.currentTime + seconds) / total)
  }
}

/// "EVENTS": each clip; tapping one plays it.
struct PlayerEventList: View {
  let model: ClipPlaybackModel
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Strings.recordingsDetailEventsLabel)
        .font(theme.typography.font(size: 12, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .tracking(1)
      VStack(spacing: 6) {
        ForEach(Array(model.events.enumerated()), id: \.element.id) { index, event in
          PlayerEventRow(
            start: event.start, duration: event.duration, category: event.category, intensity: event.intensity,
            isActive: model.playlist.index == index, isPlaying: model.isPlaying) { model.select(index) }
        }
      }
    }
  }
}
