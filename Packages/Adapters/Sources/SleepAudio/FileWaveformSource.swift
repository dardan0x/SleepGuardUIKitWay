import AVFoundation
import SleepCore
import SleepDomain

/// `ClipWaveformSource` over the clip file: reads it in 1024-frame buffers and
/// feeds SleepCore's `WaveformAccumulator`, as SleepGuard's waveform
/// generator does. Reads off the caller's actor.
struct FileWaveformSource: ClipWaveformSource {
  @concurrent
  func waveform(of url: URL, duration: TimeInterval?) async -> [Float] {
    guard let file = try? AVAudioFile(forReading: url) else { return [] }
    let format = file.processingFormat
    let frames = Int(file.length)
    let limit = duration.map { min(frames, Int($0 * format.sampleRate)) } ?? frames
    guard limit > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else { return [] }

    var waveform = WaveformAccumulator(frames: limit)
    while file.framePosition < file.length, !waveform.isFull, !Task.isCancelled {
      guard (try? file.read(into: buffer)) != nil, let channel = buffer.floatChannelData?[0] else { break }
      waveform.add(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
    }
    return waveform.waveform
  }
}
