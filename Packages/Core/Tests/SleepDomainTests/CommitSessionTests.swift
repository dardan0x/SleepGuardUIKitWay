import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

struct CommitSessionTests {
  @Test func savesTheNightWithItsSummary() async throws {
    let night = Sample.night(events: [Sample.event(at: 3600), Sample.event(at: 7200)])
    let repository = FakeSessionRepository()

    try await CommitSession(sessions: repository)(night)

    #expect(await repository.savedIDs == [night.id])
    #expect(await repository.sessions[night.id] == night)
    #expect(await repository.summaries[night.id] == night.summary())
  }

  @Test func refusesANightUnderTheMinimum() async {
    let night = Sample.night(hours: (Night.minimumSaveDuration - 1) / 3600)
    let repository = FakeSessionRepository()
    await #expect(throws: CommitSession.Failure.tooShort) {
      try await CommitSession(sessions: repository)(night)
    }
    #expect(await repository.savedIDs.isEmpty)
  }

  @Test func aStoreFailureIsThrown() async {
    struct Broken: Error {}
    let repository = FakeSessionRepository()
    await repository.failNextCall(with: Broken())
    await #expect(throws: Broken.self) {
      try await CommitSession(sessions: repository)(Sample.night())
    }
  }
}
