import Foundation
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

/// The fakes meet the same contracts as the adapters (whose runs are in
/// SleepPersistenceTests and SleepAudioTests).
struct PortContractTests {
  @Test func fakeSessionRepository() async {
    let violations = await PortContracts.sessionRepository { FakeSessionRepository() }
    #expect(violations == [])
  }

  @Test func fakeCheckpointStore() async {
    let violations = await PortContracts.checkpointStore { FakeRecordingCheckpointStore() }
    #expect(violations == [])
  }

  @Test func fakeProfileStore() async {
    let violations = await PortContracts.profileStore { FakeProfileStore() }
    #expect(violations == [])
  }

  @Test func fakeLifestyleLogStore() async {
    let violations = await PortContracts.lifestyleLogStore { FakeLifestyleLogStore() }
    #expect(violations == [])
  }

  @Test func fakePreferencesStore() async {
    let violations = await PortContracts.preferencesStore { FakePreferencesStore() }
    #expect(violations == [])
  }

  @Test @MainActor func fakeMelodyStore() {
    let violations = PortContracts.melodyStore({ FakeMelodyStore() }, take: { URL(fileURLWithPath: "/take.m4a") })
    #expect(violations == [])
  }
}
