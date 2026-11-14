import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
@testable import AppShell

struct SampleNightsTests {
  private let today = Date(timeIntervalSinceReferenceDate: 800_000_000)

  @Test func sameNightsEveryRun() {
    #expect(SampleNights.make(before: today) == SampleNights.make(before: today))
  }

  @Test func fourteenValidNightsNewestFirstBeforeToday() throws {
    let nights = SampleNights.make(before: today)
    #expect(nights.count == 14)
    #expect(nights.map(\.start) == nights.map(\.start).sorted(by: >))
    #expect(try #require(nights.first).end < today.addingTimeInterval(12 * 3600))
    for night in nights {
      #expect(night.duration >= 5.5 * 3600 && night.duration <= 9 * 3600)
      #expect(night.events.allSatisfy { $0.start >= night.start && $0.end <= night.end })
      #expect(night.events.map(\.start) == night.events.map(\.start).sorted())
      #expect(night.events.allSatisfy { event in event.bursts.allSatisfy { $0.endOffset <= event.duration } })
    }
  }

  /// Enough variety for lists and charts to show something.
  @Test func nightsVary() {
    let nights = SampleNights.make(before: today)
    let scores = nights.map { $0.score() }
    #expect(Set(scores).count > 5)
    #expect(scores.contains { $0 >= 80 } && scores.contains { $0 < 80 })
    #expect(nights.contains { !$0.sleepStages.isEmpty } && nights.contains { $0.sleepStages.isEmpty })
    #expect(nights.contains { $0.endReason == .lowBattery })
    #expect(nights.contains { $0.events.contains { $0.category == .sleepTalking } })
  }

  @Test func seedsAnEmptyStore() async throws {
    let repository = FakeSessionRepository()
    try await SampleNights.seedIfEmpty(repository, before: today)
    #expect(await repository.sessions.count == 14)
    let night = try #require(SampleNights.make(before: today).first)
    #expect(await repository.summaries[night.id] == night.summary())
  }

  @Test func leavesAStoreWithNightsAlone() async throws {
    let existing = SleepSession(start: today.addingTimeInterval(-30000), end: today.addingTimeInterval(-3000))
    let repository = FakeSessionRepository([existing])
    try await SampleNights.seedIfEmpty(repository, before: today)
    #expect(await repository.sessions.keys.sorted() == [existing.id])
    #expect(await repository.savedIDs.isEmpty)
  }
}

struct StorageLocationTests {
  @Test func withoutAnAppGroupItUsesApplicationSupport() {
    let location = StorageLocation.resolve(appGroup: nil)
    #expect(location.root == URL.applicationSupportDirectory.appendingPathComponent("SleepGuardUIKitWay", isDirectory: true))
    #expect(location.storeURL.lastPathComponent == "Nights.store")
    #expect(FileManager.default.fileExists(atPath: location.clipsDirectory.path))
  }
}
