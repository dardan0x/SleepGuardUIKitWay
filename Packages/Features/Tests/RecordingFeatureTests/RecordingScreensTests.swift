import Foundation
import ScreenKit
import SleepCore
import SleepGuardDesignKit
import Testing
import UIKit
@testable import RecordingFeature

/// The rules the recording screens apply before they route: a short night
/// can't be saved, and the countdown starts the night at zero.
@MainActor
struct RecordingScreensTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  @Test func aShortNightIsNotSaved() {
    var saved: [Night] = []
    let night = Night(start: start, end: start.addingTimeInterval(Night.minimumSaveDuration - 1))
    let screen = SessionSummaryViewController(
      night: night, routes: SessionSummaryRoutes(save: { saved.append($0) }, discard: { _ in }),
      theme: .sleepGuard, chrome: ScreenChrome())
    screen.saveTapped()
    #expect(saved.isEmpty)
    #expect(screen.tooShortAlert().title == Strings.sessionSummaryTooShortTitle)
  }

  @Test func aLongEnoughNightIsSaved() {
    var saved: [Night] = []
    let night = Night(start: start, end: start.addingTimeInterval(Night.minimumSaveDuration))
    let screen = SessionSummaryViewController(
      night: night, routes: SessionSummaryRoutes(save: { saved.append($0) }, discard: { _ in }),
      theme: .sleepGuard, chrome: ScreenChrome())
    screen.saveTapped()
    #expect(saved == [night])
  }

  @Test func theCountdownStartsTheNightAtZero() {
    var started = 0
    let screen = RecordingCountdownViewController(
      target: start.addingTimeInterval(60), routes: RecordingCountdownRoutes(cancel: {}, start: { started += 1 }),
      theme: .sleepGuard, chrome: ScreenChrome())
    screen.loadViewIfNeeded()
    #expect(!screen.tick(now: start))
    #expect(screen.seconds == 60)
    #expect(started == 0)
    #expect(screen.tick(now: start.addingTimeInterval(60)))
    #expect(started == 1)
  }
}
