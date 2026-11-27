import Foundation
import SleepDomain

/// Answers with fixed bars and records which files were asked for.
public actor FakeClipWaveformSource: ClipWaveformSourcePort {
  public private(set) var requested: [String] = []
  private let bars: [Float]

  public init(bars: [Float] = [0.2, 1, 0.5]) {
    self.bars = bars
  }

  public func waveform(of url: URL, duration _: TimeInterval?) async -> [Float] {
    requested.append(url.lastPathComponent)
    return bars
  }
}
