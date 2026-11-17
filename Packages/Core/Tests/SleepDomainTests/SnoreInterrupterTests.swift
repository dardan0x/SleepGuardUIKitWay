import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

/// When the interrupter plays, what it plays, and that the microphone comes
/// back however the melody stops.
@MainActor
struct SnoreInterrupterTests {
  let capture = FakeAudioCapture()
  let player = FakeMelodyPlayer()

  func make(
    mode: SnoreInterrupterMode = .fifteenSeconds, melodyID: Int = 4, recordings: [Melody] = []) -> SnoreInterrupter
  {
    SnoreInterrupter(
      mode: mode, melodyID: melodyID, player: player, store: FakeMelodyStore(recordings: recordings),
      capture: capture, now: { Sample.at(30) })
  }

  @Test func playsTheChosenMelodyForTheModesLengthWithTheMicPaused() {
    let interrupter = make()
    #expect(interrupter.play())
    #expect(player.plays == [.init(url: URL(fileURLWithPath: "/melodies/dragon-studio-bird-chittering-sfx-364487"), loops: false, duration: 15)])
    #expect(interrupter.playing?.id == 4)
    #expect(capture.calls == [.pause])
  }

  @Test func alwaysLoopsUntilStopped() {
    let interrupter = make(mode: .always)
    #expect(interrupter.play())
    #expect(player.plays.first?.loops == true)
    #expect(player.plays.first?.duration == nil)
  }

  @Test func offMutedOrAlreadyPlayingPlaysNothing() {
    #expect(!make(mode: .never).play())
    let muted = make()
    muted.mute()
    #expect(!muted.play())
    let playing = make()
    #expect(playing.play())
    #expect(!playing.play())
    #expect(player.plays.count == 1)
  }

  @Test func aDeletedRecordingFallsBackToTheDefault() {
    let interrupter = make(melodyID: 120)
    #expect(interrupter.play())
    #expect(interrupter.playing?.id == Melody.defaultID)
  }

  @Test func aRecordingPlaysItsOwnFile() {
    let mine = Melody(id: 100, filename: "custom_100.m4a", customName: "Mine")
    let interrupter = make(melodyID: 100, recordings: [mine])
    #expect(interrupter.play())
    #expect(player.plays.first?.url.lastPathComponent == "custom_100.m4a")
  }

  @Test func aPlayerThatFailsGivesTheMicBack() {
    player.starts = false
    let interrupter = make()
    #expect(!interrupter.play())
    #expect(capture.calls == [.pause, .resume])
    #expect(interrupter.playing == nil)
  }

  @Test(arguments: ["finish", "stop", "mute"])
  func everyEndResumesTheMicAndReportsOnce(end: String) {
    let interrupter = make()
    var stops: [Date] = []
    interrupter.onStopped = { stops.append($0) }
    _ = interrupter.play()
    switch end {
    case "finish": player.finish()
    case "stop": interrupter.stop()
    default: interrupter.mute()
    }
    interrupter.stop()
    #expect(stops == [Sample.at(30)])
    #expect(capture.calls == [.pause, .resume])
    #expect(interrupter.playing == nil)
    #expect(interrupter.isMuted == (end == "mute"))
  }
}
