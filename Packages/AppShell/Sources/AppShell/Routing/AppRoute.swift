import Foundation

/// Where a link opens the app: `<scheme>://start`, `<scheme>://session/<id>`,
/// `<scheme>://last7nights`, the same paths as SleepGuard's widget links.
/// The scheme is the brand's (Info.plist); iOS only hands this app its own,
/// so it isn't checked here.
public enum AppRoute: Equatable, Sendable {
  case startRecording
  case night(UUID)
  case lastSevenNights

  public init?(url: URL) {
    switch url.host() {
    case "start":
      self = .startRecording
    case "session":
      guard let id = UUID(uuidString: url.lastPathComponent) else { return nil }
      self = .night(id)
    case "last7nights":
      self = .lastSevenNights
    default:
      return nil
    }
  }
}
