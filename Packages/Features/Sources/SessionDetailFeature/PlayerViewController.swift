import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// Plays a night's event clips (`PlayerViewModel`, built by the shell) in
/// the shared `PlayerContent`: the playing event with its waveform, back /
/// play / forward, enhanced audio, and the events to pick from. Redraws as
/// the model changes; starts when shown, releases the player when gone.
public final class PlayerViewController: ScreenController {
  let viewModel: PlayerViewModel
  private let list = ContentListController(insets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))

  public init(viewModel: PlayerViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    show(list)
    renderTracking { [weak self] in self?.render() }
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    viewModel.start()
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    viewModel.close()
  }

  private func render() {
    let model = viewModel
    if model.currentEvent != nil, model.hasAudio {
      let playlist = model.playlist
      let clips = model.events.map {
        PlayerClip(id: $0.id, start: $0.start, duration: $0.duration, category: $0.category, intensity: $0.intensity)
      }
      list.rows = [.init(id: "player", configuration: hosted {
        PlayerContent(
          clips: clips, index: playlist.index, isPlaying: model.isPlaying, currentTime: playlist.currentTime,
          totalDuration: playlist.totalDuration, waveform: model.waveform, isLoadingWaveform: model.isLoadingWaveform,
          isEnhanced: Binding(get: { model.isEnhanced }, set: { model.isEnhanced = $0 }),
          onToggle: { model.togglePlayback() }, onSeek: { model.seek(toProgress: $0) }, onSelect: { model.select($0) })
      })]
    } else if let event = model.currentEvent {
      list.rows = [.init(id: "no-audio", configuration: hosted {
        NoAudioCard(start: event.start, duration: event.duration, intensity: event.intensity)
      })]
    } else {
      list.rows = []
    }
  }
}
