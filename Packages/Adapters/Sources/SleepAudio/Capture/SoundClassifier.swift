import AVFoundation
import os
import SleepCore
import SoundAnalysis

/// Apple's built-in sound classifier on the microphone. Keeps its latest snore
/// and speech confidences; which classes count is SleepCore's
/// `SoundClassLabels`.
///
/// SoundAnalysis calls the observer on its own queue, so the confidences sit
/// behind a lock (their type is `Sendable`, so it's the checked one).
final class SoundClassifier: NSObject, SNResultsObserving, Sendable {
  private let latest = OSAllocatedUnfairLock(initialState: SoundClassLabels.Confidences(snore: 0, speech: 0))

  var confidences: SoundClassLabels.Confidences {
    latest.withLock { $0 }
  }

  /// An analyzer for buffers of `format` that reports to this observer, or
  /// `nil` when the classifier isn't available.
  func makeAnalyzer(format: AVAudioFormat) -> SNAudioStreamAnalyzer? {
    do {
      let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
      let analyzer = SNAudioStreamAnalyzer(format: format)
      try analyzer.add(request, withObserver: self)
      return analyzer
    } catch {
      Log.audio.error("Sound classifier unavailable: \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }

  func reset() {
    latest.withLock { $0 = SoundClassLabels.Confidences(snore: 0, speech: 0) }
  }

  // MARK: - SNResultsObserving

  func request(_: SNRequest, didProduce result: SNResult) {
    guard let result = result as? SNClassificationResult else { return }
    let confidences = SoundClassLabels.confidences(result.classifications.map { ($0.identifier, $0.confidence) })
    latest.withLock { $0 = confidences }
  }

  func request(_: SNRequest, didFailWithError error: Error) {
    Log.audio.error("Sound classification failed: \(error.localizedDescription, privacy: .public)")
  }
}

enum Log {
  static let audio = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SleepGuardUIKitWay", category: "audio")
}
