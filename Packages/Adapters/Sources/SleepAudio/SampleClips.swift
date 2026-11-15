#if DEBUG
import AVFoundation
import SleepCore

public extension SleepAudio {
  /// Debug only: writes a snore-like clip (a rumbling tone that swells with
  /// each breath, louder for louder intensities) as AAC, so sample nights
  /// have something to play before recording exists (F7).
  static func writeSampleClip(to url: URL, seconds: TimeInterval, intensity: SnoreIntensity) throws {
    let rate = 16000.0
    guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1),
          let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(seconds * rate)),
          let samples = buffer.floatChannelData?[0]
    else { return }
    buffer.frameLength = buffer.frameCapacity
    let loudness: Float = [0.08, 0.18, 0.35, 0.6][intensity.rank]
    var noise: UInt32 = 0x5EED
    for index in 0..<Int(buffer.frameLength) {
      let time = Float(index) / Float(rate)
      let breath = max(0, sin(2 * .pi * time / 4)) // a snore every 4 s
      noise = noise &* 1_664_525 &+ 1_013_904_223
      let hiss = Float(noise >> 8) / Float(1 << 24) * 2 - 1
      let rumble = sin(2 * .pi * 95 * time + 3 * sin(2 * .pi * 7 * time))
      samples[index] = loudness * breath * breath * (0.7 * rumble + 0.3 * hiss)
    }
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: rate, AVNumberOfChannelsKey: 1,
    ]
    let file = try AVAudioFile(forWriting: url, settings: settings)
    try file.write(from: buffer)
  }
}
#endif
