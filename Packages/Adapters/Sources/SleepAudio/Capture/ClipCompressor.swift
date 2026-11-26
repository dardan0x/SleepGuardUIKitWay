import AVFoundation
import Foundation
import SleepLogging

/// Compresses a raw event clip (.caf) to mono HE-AAC (.m4a) at about 12 kbps,
/// with the same codec choice as SleepGuard's `EventClipCompressor`.
///
/// HE-AAC stays clear at low bitrates where AAC-LC smears, and constrained VBR
/// spends almost nothing on the breathing gaps between bursts. Snore energy is
/// mostly below 1.5 kHz, so a low sample rate is enough, but HE-AAC rejects
/// 16 kHz: the rate comes from the codec's own list (lowest ≥ 16 kHz). Falls
/// back to AAC-LC at 24 kbps.
///
/// Unlike SleepGuard's (an asset reader and writer driven on a dispatch
/// queue), this reads, converts to mono at that rate, and encodes in one
/// synchronous loop off the caller's actor: no queue, nothing shared.
enum ClipCompressor {
  @concurrent
  static func compress(from sourceURL: URL, to destinationURL: URL) async -> Bool {
    try? FileManager.default.removeItem(at: destinationURL)
    do {
      try encode(from: sourceURL, to: destinationURL)
      return true
    } catch {
      Log.audio.error("Clip compression failed for \(sourceURL.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
      try? FileManager.default.removeItem(at: destinationURL)
      return false
    }
  }

  private struct ConversionFailed: Error {}

  private static func encode(from sourceURL: URL, to destinationURL: URL) throws {
    let input = try AVAudioFile(forReading: sourceURL)
    let formatID: AudioFormatID
    let sampleRate: Double
    let bitRate: Int
    if let rate = encodeSampleRate(for: kAudioFormatMPEG4AAC_HE, atLeast: 16000) {
      (formatID, sampleRate, bitRate) = (kAudioFormatMPEG4AAC_HE, rate, 12000)
    } else {
      let rate = encodeSampleRate(for: kAudioFormatMPEG4AAC, atLeast: 16000) ?? 44100
      (formatID, sampleRate, bitRate) = (kAudioFormatMPEG4AAC, rate, 24000)
    }
    // Releasing the file at the end of this function finishes the encode.
    let output = try AVAudioFile(
      forWriting: destinationURL,
      settings: [
        AVFormatIDKey: formatID,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: 1,
        AVEncoderBitRateKey: bitRate,
        AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_VariableConstrained,
      ],
      commonFormat: .pcmFormatFloat32, interleaved: false)

    let chunk: AVAudioFrameCount = 8192
    let sourceFormat = input.processingFormat
    let ratio = output.processingFormat.sampleRate / sourceFormat.sampleRate
    guard let converter = AVAudioConverter(from: sourceFormat, to: output.processingFormat),
          let converted = AVAudioPCMBuffer(pcmFormat: output.processingFormat, frameCapacity: AVAudioFrameCount(Double(chunk) * ratio) + 1024)
    else { throw ConversionFailed() }

    while true {
      var error: NSError?
      // The input block is `@Sendable`: it makes its own buffer per chunk.
      let status = converter.convert(to: converted, error: &error) { _, inputStatus in
        guard input.framePosition < input.length,
              let source = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: chunk),
              (try? input.read(into: source, frameCount: chunk)) != nil, source.frameLength > 0
        else {
          inputStatus.pointee = .endOfStream
          return nil
        }
        inputStatus.pointee = .haveData
        return source
      }
      if let error { throw error }
      if converted.frameLength > 0 { try output.write(from: converted) }
      if status == .endOfStream || status == .error { break }
    }
  }

  /// Lowest encode rate ≥ `floor` that `formatID` supports, its highest if
  /// none reaches the floor, or `nil` when the codec is unavailable. Only a
  /// listed rate is safe: an unsupported one fails inside the encoder.
  private static func encodeSampleRate(for formatID: AudioFormatID, atLeast floor: Double) -> Double? {
    var format = formatID
    var size: UInt32 = 0
    let specifierSize = UInt32(MemoryLayout<AudioFormatID>.size)
    guard AudioFormatGetPropertyInfo(kAudioFormatProperty_AvailableEncodeSampleRates, specifierSize, &format, &size) == noErr,
          size > 0 else { return nil }
    var ranges = [AudioValueRange](repeating: AudioValueRange(), count: Int(size) / MemoryLayout<AudioValueRange>.size)
    guard AudioFormatGetProperty(kAudioFormatProperty_AvailableEncodeSampleRates, specifierSize, &format, &size, &ranges) == noErr
    else { return nil }

    let standardRates = [16000.0, 22050, 24000, 32000, 44100, 48000]
    var supported: [Double] = []
    for range in ranges {
      if range.mMinimum == range.mMaximum {
        if range.mMinimum > 0 { supported.append(range.mMinimum) }
      } else {
        supported += standardRates.filter { $0 >= range.mMinimum && $0 <= range.mMaximum }
      }
    }
    supported.sort()
    return supported.first { $0 >= floor } ?? supported.last
  }
}
