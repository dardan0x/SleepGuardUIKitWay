import Foundation
import SleepDomain

/// An `AudioCapture` a test drives: it sends samples, and checks which
/// clips were started, closed, compressed and discarded.
@MainActor
public final class FakeAudioCapture: AudioCapture {
  public enum Call: Equatable {
    case warmUp
    case coolDown
    case start
    case startClip(UUID)
    case closeClip
    case compressClip(String)
    case discardClip
    case pause
    case resume
    case stop
  }

  public private(set) var calls: [Call] = []
  /// The raw audio file the last `start` was asked to keep.
  public private(set) var rawAudioFileName: String?
  /// Between `pause` and `resume`: a test stops sending samples, as the
  /// microphone would.
  public private(set) var isPaused = false
  public var permission = true
  /// Thrown by the next `start`.
  public var startError: AudioCaptureError?
  /// When false, `compressClip` fails and returns the raw name.
  public var compresses = true
  private var continuation: AsyncStream<CaptureSample>.Continuation?
  private var openClip: UUID?

  public init() {}

  public func requestPermission() async -> Bool {
    permission
  }

  public func warmUp() throws {
    calls.append(.warmUp)
  }

  public func coolDown() {
    calls.append(.coolDown)
  }

  public func start(rawAudioFileName: String?) throws -> AsyncStream<CaptureSample> {
    calls.append(.start)
    self.rawAudioFileName = rawAudioFileName
    if let startError { throw startError }
    let (stream, continuation) = AsyncStream.makeStream(of: CaptureSample.self)
    self.continuation = continuation
    return stream
  }

  /// Delivers a sample to the stream `start` returned.
  public func send(_ sample: CaptureSample) {
    continuation?.yield(sample)
  }

  public func startClip(id: UUID) throws {
    guard continuation != nil else { throw AudioCaptureError.notListening }
    calls.append(.startClip(id))
    openClip = id
  }

  /// `<id>.caf` for the open clip.
  public func closeClip() -> String? {
    calls.append(.closeClip)
    defer { openClip = nil }
    return openClip.map { "\($0.uuidString).caf" }
  }

  /// `<id>.m4a` for `<id>.caf`.
  public func compressClip(named name: String) async -> String {
    calls.append(.compressClip(name))
    guard compresses else { return name }
    return name.replacingOccurrences(of: ".caf", with: ".m4a")
  }

  public func discardClip() {
    calls.append(.discardClip)
    openClip = nil
  }

  public func pause() {
    calls.append(.pause)
    isPaused = true
  }

  public func resume() {
    calls.append(.resume)
    isPaused = false
  }

  public func stop() {
    calls.append(.stop)
    continuation?.finish()
    continuation = nil
  }
}
