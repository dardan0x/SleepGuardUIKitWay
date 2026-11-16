import Foundation
import Observation
import SleepCore
import SleepDomain

/// Plays a night's event clips one after another. Owns the audio player, so
/// it is a state owner rather than view state: SleepCore's `ClipPlaylist`
/// decides what plays, the `ClipPlayer` makes it heard, and this keeps them in
/// step (position, auto-advance, seeking, interruptions).
@MainActor
@Observable
public final class ClipPlaybackModel {
  public let events: [NightEvent]
  public private(set) var playlist: ClipPlaylist
  public private(set) var isPlaying = false
  /// The current clip's file is loaded and can play.
  public private(set) var hasAudio = false
  /// Band-pass and peak boost; the player applies it from the next sample.
  public var isEnhanced: Bool {
    didSet { player.isEnhanced = isEnhanced }
  }

  @ObservationIgnored private let player: any ClipPlayer
  @ObservationIgnored private let files: any SessionFileStore
  @ObservationIgnored private let firstIndex: Int
  @ObservationIgnored private var fileDuration: TimeInterval = 0
  @ObservationIgnored private var ticking: Task<Void, Never>?

  /// `events` in play order; playback starts at `startEvent` (or the first).
  public init(events: [NightEvent], startEvent: NightEvent.ID?, player: any ClipPlayer, files: any SessionFileStore, isEnhanced: Bool = true) {
    self.events = events
    self.player = player
    self.files = files
    self.isEnhanced = isEnhanced
    playlist = ClipPlaylist(events: events)
    firstIndex = startEvent.flatMap { id in events.firstIndex { $0.id == id } } ?? 0
    player.isEnhanced = isEnhanced
    player.onInterruption = { [weak self] in self?.interrupted() }
  }

  public var currentEvent: NightEvent? {
    events.indices.contains(playlist.index) ? events[playlist.index] : nil
  }

  /// Loads the starting clip and plays it when it has audio.
  public func start() {
    playlist.select(firstIndex)
    load()
    if hasAudio { play() }
  }

  public func togglePlayback() {
    if isPlaying { pause() } else { play() }
  }

  public func play() {
    guard hasAudio else { return }
    let remaining = clipDuration - playlist.offset
    guard remaining > 0 else { return clipFinished() }
    do {
      try player.play(from: playlist.offset, for: remaining) { [weak self] in self?.clipFinished() }
      isPlaying = true
      startTicking()
    } catch {
      isPlaying = false
    }
  }

  public func pause() {
    guard isPlaying else { return }
    playlist.offset = min(player.position, clipDuration)
    player.pause()
    stopPlaying()
  }

  /// Plays the clip at `index` from its start.
  public func select(_ index: Int) {
    let wasPlaying = isPlaying
    if wasPlaying { pause() }
    guard playlist.select(index) else {
      if wasPlaying { play() }
      return
    }
    load()
    play()
  }

  public func next() {
    select(playlist.index + 1)
  }

  public func previous() {
    select(playlist.index - 1)
  }

  /// Moves to `progress` (0...1) of all clips, still playing if it was.
  /// Past the end: the end of the last clip.
  public func seek(toProgress progress: Double) {
    guard playlist.totalDuration > 0 else { return }
    guard progress <= 1 else {
      playlist.seek(toProgress: progress)
      load()
      playlist.offset = clipDuration
      return
    }
    let wasPlaying = isPlaying
    if wasPlaying { pause() }
    let previousIndex = playlist.index
    playlist.seek(toProgress: progress)
    let offset = playlist.offset
    if playlist.index != previousIndex { load() }
    playlist.offset = max(0, min(offset, clipDuration))
    if wasPlaying { play() }
  }

  /// Moves to `progress` (0...1) of the current clip, still playing if it was.
  public func seek(inClip progress: Double) {
    guard hasAudio else { return }
    let wasPlaying = isPlaying
    if wasPlaying { pause() }
    playlist.offset = max(0, min(progress * clipDuration, clipDuration))
    if wasPlaying { play() }
  }

  /// Stops and releases the audio engine (the sheet closed).
  public func close() {
    if isPlaying { playlist.offset = min(player.position, clipDuration) }
    stopPlaying()
    player.stop()
  }

  /// Reads the player's position into the playlist (every 0.1 s while playing).
  func tick() {
    guard isPlaying else { return }
    playlist.offset = min(player.position, clipDuration)
  }

  // MARK: - Private

  /// The current clip, as long as its file allows.
  private var clipDuration: TimeInterval {
    guard let clip = playlist.current else { return fileDuration }
    return min(clip.duration, fileDuration)
  }

  private func load() {
    hasAudio = false
    fileDuration = 0
    guard let name = playlist.current?.fileName, let url = files.url(forFileNamed: name) else { return }
    do {
      fileDuration = try player.load(url)
      hasAudio = true
    } catch {
      hasAudio = false
    }
  }

  private func clipFinished() {
    switch playlist.clipFinished() {
    case .playNext:
      load()
      if hasAudio { play() } else { stopPlaying() }
    case .stopAtStart:
      stopPlaying()
      load()
    }
  }

  private func interrupted() {
    tick()
    stopPlaying()
  }

  private func stopPlaying() {
    isPlaying = false
    ticking?.cancel()
    ticking = nil
  }

  private func startTicking() {
    ticking?.cancel()
    ticking = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(100))
        // Ends with the model, not only when cancelled.
        guard let self else { return }
        tick()
      }
    }
  }
}
