import SleepCore
import SleepGuardContentKit
import SwiftUI

/// Plays a night's event clips (`ClipPlaybackModel`, built by the shell) in
/// the shared `PlayerContent`: the playing event with its waveform, back /
/// play / forward, enhanced audio, and the events to pick from. Starts on
/// appear; releases the player on close.
public struct PlayerScreen: View {
  @Bindable var model: ClipPlaybackModel

  public init(model: ClipPlaybackModel) {
    self.model = model
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        if model.currentEvent != nil, model.hasAudio {
          let playlist = model.playlist
          PlayerContent(
            clips: model.events.map {
              PlayerClip(id: $0.id, start: $0.start, duration: $0.duration, category: $0.category, intensity: $0.intensity)
            },
            index: playlist.index,
            isPlaying: model.isPlaying,
            currentTime: playlist.currentTime,
            totalDuration: playlist.totalDuration,
            waveform: model.waveform,
            isLoadingWaveform: model.isLoadingWaveform,
            isEnhanced: $model.isEnhanced,
            onToggle: { model.togglePlayback() },
            onSeek: { model.seek(toProgress: $0) },
            onSelect: { model.select($0) })
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
