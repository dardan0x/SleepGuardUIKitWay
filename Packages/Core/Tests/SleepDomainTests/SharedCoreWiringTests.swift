import SleepCore
import Testing

/// The domain builds on the shared SleepCore release. Replaced by real domain
/// tests in F2.
struct SharedCoreWiringTests {
  /// An empty night scores the maximum: the formula's first guard.
  @Test func sleepCoreIsLinked() {
    let score = SleepScore.compute(SleepInputs(totalDuration: 0), config: .default)
    #expect(score == SleepScoreConfig.default.maxScore)
  }
}
