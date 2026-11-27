import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

struct RefreshStaleSummariesUseCaseTests {
  private let current = SleepScore.cacheVersion(for: .default)

  @Test func recomputesOnlyStaleNightsAndStampsTheCurrentVersion() async throws {
    let stale = Sample.night(events: [Sample.event(at: 3600)])
    let fresh = Sample.night()
    let repository = FakeSessionRepository([stale])
    try await repository.save(fresh, summary: fresh.summary(), scoreVersion: current)

    let refreshed = try await RefreshStaleSummariesUseCase(sessions: repository)()

    #expect(refreshed == 1)
    #expect(await repository.summaryUpdates == [[stale.id]])
    #expect(await repository.summaries[stale.id] == stale.summary())
    #expect(await repository.scoreVersions[stale.id] == current)
  }

  @Test func writesInBatches() async throws {
    let nights = (0..<(RefreshStaleSummariesUseCase.batchSize + 5)).map { _ in Sample.night() }
    let repository = FakeSessionRepository(nights)

    try await RefreshStaleSummariesUseCase(sessions: repository)()

    #expect(await repository.summaryUpdates.map(\.count) == [RefreshStaleSummariesUseCase.batchSize, 5])
    #expect(try await repository.staleNightIDs(currentVersion: current).isEmpty)
  }

  @Test func nothingStaleWritesNothing() async throws {
    let night = Sample.night()
    let repository = FakeSessionRepository()
    try await repository.save(night, summary: night.summary(), scoreVersion: current)

    #expect(try await RefreshStaleSummariesUseCase(sessions: repository)() == 0)
    #expect(await repository.summaryUpdates.isEmpty)
  }
}
