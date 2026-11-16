import Foundation
import SleepDomain

/// An `AudioCapturePort` a test drives: it sends samples, and checks which
/// clips were started, finished and discarded.
@MainActor
public final class FakeAudioCapture: AudioCapturePort {
  public enum Call: Equatable {
    case start
    case startClip(UUID)
    case finishClip
    case discardClip
    case stop
  }

  public private(set) var calls: [Call] = []
  public var permission = true
  /// Thrown by the next `start`.
  public var startError: AudioCaptureError?
  private var continuation: AsyncStream<CaptureSample>.Continuation?
  private var openClip: UUID?

  public init() {}

  public func requestPermission() async -> Bool {
    permission
  }

  public func start() throws -> AsyncStream<CaptureSample> {
    calls.append(.start)
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

  /// `<id>.m4a` for the open clip.
  public func finishClip() async -> String? {
    calls.append(.finishClip)
    defer { openClip = nil }
    return openClip.map { "\($0.uuidString).m4a" }
  }

  public func discardClip() {
    calls.append(.discardClip)
    openClip = nil
  }

  public func stop() {
    calls.append(.stop)
    openClip = nil
    continuation?.finish()
    continuation = nil
  }
}
