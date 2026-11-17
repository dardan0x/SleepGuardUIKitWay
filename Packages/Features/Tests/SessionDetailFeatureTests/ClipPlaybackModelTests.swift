import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SessionDetailFeature

/// The playback state owner against a fake player: what plays, auto-advance,
/// seeking, interruptions, release.
@MainActor
struct ClipPlaybackModelTests {
  private let start = Date(timeIntervalSinceReferenceDate: 0)
  private let waveforms = FakeClipWaveformSource(bars: [0.25, 1, 0.5])

  /// Three clips of 10, 20 and 30 s; files `a`, `b`, `c` of the same length.
  private func make(startAt: Int? = nil, missing: Set<String> = [], fileDurations: [String: TimeInterval]? = nil)
    -> (ClipPlaybackModel, FakeClipPlayer)
  {
    let names = ["a", "b", "c"]
    let events = zip(names, [10.0, 20, 30]).enumerated().map { offset, pair in
      NightEvent(start: start.addingTimeInterval(Double(offset) * 600), duration: pair.1, intensity: .loud, clipFileName: "\(pair.0).m4a")
    }
    let urls = Dictionary(uniqueKeysWithValues: names.filter { !missing.contains($0) }.map {
      ("\($0).m4a", URL(fileURLWithPath: "/clips/\($0).m4a"))
    })
    let player = FakeClipPlayer(durations: fileDurations ?? ["a.m4a": 10, "b.m4a": 20, "c.m4a": 30])
    let model = ClipPlaybackModel(
      events: events, startEvent: startAt.map { events[$0].id }, player: player,
      files: FakeSessionFileStore(urls: urls), waveforms: waveforms)
    return (model, player)
  }

  // MARK: - Waveform (F10-T4b)

  @Test func theCurrentClipsWaveformLoads() async {
    let (model, _) = make(startAt: 1)
    model.start()
    #expect(model.isLoadingWaveform)
    await model.waveformLoading?.value
    #expect(model.waveform == [0.25, 1, 0.5])
    #expect(!model.isLoadingWaveform)
    #expect(await waveforms.requested == ["b.m4a"])
  }

  @Test func anotherClipLoadsItsOwnWaveform() async {
    let (model, _) = make()
    model.start()
    await model.waveformLoading?.value
    model.select(2)
    await model.waveformLoading?.value
    #expect(await waveforms.requested == ["a.m4a", "c.m4a"])
    #expect(model.waveform == [0.25, 1, 0.5])
  }

  @Test func aClipWithoutItsFileHasNoWaveform() async {
    let (model, _) = make(startAt: 1, missing: ["b"])
    model.start()
    #expect(model.waveform.isEmpty && !model.isLoadingWaveform)
    #expect(await waveforms.requested.isEmpty)
  }

  @Test func startPlaysTheChosenClip() {
    let (model, player) = make(startAt: 1)
    model.start()
    #expect(model.isPlaying && model.hasAudio)
    #expect(model.playlist.index == 1)
    #expect(player.calls == [.load("b.m4a"), .play(from: 0, for: 20)])
    #expect(player.isEnhanced)
  }

  @Test func aClipWithoutItsFileDoesNotPlay() {
    let (model, player) = make(missing: ["a"])
    model.start()
    #expect(!model.hasAudio && !model.isPlaying)
    #expect(player.calls.isEmpty)
  }

  @Test func clipsPlayOnThenStopBackAtTheFirst() {
    let (model, player) = make()
    model.start()
    player.finish()
    #expect(model.playlist.index == 1 && model.isPlaying)
    player.finish()
    player.finish()
    #expect(model.playlist.index == 0 && !model.isPlaying)
    #expect(player.calls.last == .load("a.m4a")) // ready to play again
  }

  @Test func pauseKeepsThePlaceAndPlayResumesFromIt() {
    let (model, player) = make()
    model.start()
    player.position = 4
    model.pause()
    #expect(!model.isPlaying && model.playlist.offset == 4)
    model.togglePlayback()
    #expect(player.calls.last == .play(from: 4, for: 6))
  }

  @Test func tickFollowsThePlayer() {
    let (model, player) = make()
    model.start()
    player.position = 7.5
    model.tick()
    #expect(model.playlist.currentTime == 7.5)
  }

  @Test func seekingAcrossClipsKeepsPlaying() {
    let (model, player) = make()
    model.start()
    model.seek(toProgress: 0.6) // 36 s: 6 s into c
    #expect(model.playlist.index == 2 && model.isPlaying)
    #expect(player.calls.suffix(3) == [.pause, .load("c.m4a"), .play(from: 6, for: 24)])
  }

  @Test func seekingPastTheEndParksAtTheLastClipsEnd() {
    let (model, _) = make()
    model.start()
    model.pause()
    model.seek(toProgress: 2)
    #expect(model.playlist.index == 2 && model.playlist.offset == 30 && !model.isPlaying)
  }

  @Test func aShorterFileLimitsTheClip() {
    let (model, player) = make(fileDurations: ["a.m4a": 6, "b.m4a": 20, "c.m4a": 30])
    model.start()
    #expect(player.calls.last == .play(from: 0, for: 6))
    model.pause()
    model.seek(inClip: 1)
    #expect(model.playlist.offset == 6)
  }

  /// Seeking to a clip's end while playing leaves nothing to play: the next
  /// clip starts, as in SleepGuard.
  @Test func seekingToTheEndWhilePlayingMovesOn() {
    let (model, _) = make()
    model.start()
    model.seek(inClip: 1)
    #expect(model.playlist.index == 1 && model.isPlaying)
  }

  @Test func nextAndPreviousStayInRange() {
    let (model, player) = make()
    model.start()
    model.previous()
    #expect(model.playlist.index == 0 && model.isPlaying)
    model.next()
    #expect(model.playlist.index == 1 && player.calls.last == .play(from: 0, for: 20))
  }

  @Test func anInterruptionStopsPlaying() {
    let (model, player) = make()
    model.start()
    player.position = 3
    player.interrupt()
    #expect(!model.isPlaying && model.playlist.offset == 3)
  }

  @Test func enhancedAudioReachesThePlayer() {
    let (model, player) = make()
    model.isEnhanced = false
    #expect(!player.isEnhanced)
  }

  @Test func closeReleasesThePlayer() {
    let (model, player) = make()
    model.start()
    model.close()
    #expect(!model.isPlaying && player.calls.last == .stop)
  }
}
