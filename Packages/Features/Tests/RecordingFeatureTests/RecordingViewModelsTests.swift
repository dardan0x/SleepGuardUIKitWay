import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
@testable import RecordingFeature

/// The decisions the recording screens' view models make before they route.
@MainActor
struct RecordingViewModelsTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  // MARK: - Summary

  @Test func aShortNightIsNotSaved() {
    var saved: [Night] = []
    let night = Night(start: start, end: start.addingTimeInterval(Night.minimumSaveDuration - 1))
    let viewModel = SessionSummaryViewModel(night: night, routes: SessionSummaryRoutes(save: { saved.append($0) }, discard: { _ in }))
    viewModel.save()
    #expect(saved.isEmpty)
    #expect(viewModel.alert == .tooShort)
  }

  @Test func aLongEnoughNightIsSaved() {
    var saved: [Night] = []
    let night = Night(start: start, end: start.addingTimeInterval(Night.minimumSaveDuration))
    let viewModel = SessionSummaryViewModel(night: night, routes: SessionSummaryRoutes(save: { saved.append($0) }, discard: { _ in }))
    viewModel.save()
    #expect(saved == [night])
  }

  // MARK: - Countdown

  @Test func theCountdownStartsTheNightOnceAtZero() {
    var started = 0
    let viewModel = RecordingCountdownViewModel(
      target: start.addingTimeInterval(60), routes: RecordingCountdownRoutes(cancel: {}, start: { started += 1 }),
      now: start)
    #expect(viewModel.seconds == 60)
    #expect(!viewModel.tick(now: start.addingTimeInterval(1)))
    #expect(viewModel.seconds == 59)
    #expect(viewModel.tick(now: start.addingTimeInterval(60)))
    viewModel.startNow()
    #expect(started == 1)
  }

  // MARK: - Prestart

  private func prestart(microphone: Bool, charging: Bool, started: @escaping @MainActor (AppPreferences) -> Void)
    -> RecordingPrestartViewModel
  {
    RecordingPrestartViewModel(
      dependencies: RecordingPrestartDependencies(
        compactHeight: false, requestPermission: { microphone }, isCharging: { charging },
        loadPreferences: { AppPreferences() }, saveDelay: { _ in }, hasInterrupter: false),
      routes: RecordingPrestartRoutes(start: started, cancel: {}, openSettings: {}, openInterrupter: { _ in }))
  }

  @Test func noMicrophoneAsksForSettings() async {
    var started = 0
    let viewModel = prestart(microphone: false, charging: true) { _ in started += 1 }
    await viewModel.start()
    #expect(viewModel.alert == .microphone)
    #expect(started == 0)
  }

  @Test func notChargingAsksThenCanStartAnyway() async {
    var started = 0
    let viewModel = prestart(microphone: true, charging: false) { _ in started += 1 }
    await viewModel.start()
    #expect(viewModel.alert == .charging)
    viewModel.startAnyway()
    #expect(viewModel.alert == nil)
    #expect(started == 1)
  }

  @Test func allowedAndChargingStarts() async {
    var started = 0
    let viewModel = prestart(microphone: true, charging: true) { _ in started += 1 }
    await viewModel.start()
    #expect(viewModel.alert == nil)
    #expect(started == 1)
    #expect(viewModel.interrupterMode == nil)
  }

  // MARK: - Recording a melody

  @Test func aTakeIsRecordedPlayedAndSaved() {
    let store = FakeMelodyStore()
    let recorder = FakeMelodyRecorder()
    let player = FakeMelodyPlayer()
    var done: [Melody?] = []
    let viewModel = RecordMelodyViewModel(store: store, recorder: recorder, playback: player, done: { done.append($0) })

    viewModel.toggleRecording()
    #expect(viewModel.state == .recording)
    viewModel.toggleRecording()
    #expect(viewModel.state == .recorded(isPlaying: false))
    viewModel.togglePlayback()
    #expect(viewModel.state == .recorded(isPlaying: true))
    player.finish()
    #expect(viewModel.state == .recorded(isPlaying: false))
    viewModel.save()
    #expect(done.count == 1)
    #expect(store.saved.count == 1)
  }

  @Test func reachingTheLimitEndsTheTake() {
    let recorder = FakeMelodyRecorder()
    let viewModel = RecordMelodyViewModel(
      store: FakeMelodyStore(), recorder: recorder, playback: FakeMelodyPlayer(), done: { _ in })
    viewModel.toggleRecording()
    recorder.reachLimit()
    #expect(viewModel.state == .recorded(isPlaying: false))
  }

  // MARK: - Picking a melody

  @Test func aTapPreviewsASecondTapStops() {
    let player = FakeMelodyPlayer()
    let viewModel = MelodyPickerViewModel(
      selectedID: Melody.defaultID, store: FakeMelodyStore(), preview: player,
      routes: MelodyPickerRoutes(record: { _ in }, done: { _ in }))
    let melody = Melody.resolve(id: Melody.defaultID, custom: [])
    viewModel.select(melody)
    #expect(viewModel.previewingID == melody.id)
    #expect(player.plays.last?.duration == MelodyPickerViewModel.previewLength)
    viewModel.select(melody)
    #expect(viewModel.previewingID == nil)
  }
}
