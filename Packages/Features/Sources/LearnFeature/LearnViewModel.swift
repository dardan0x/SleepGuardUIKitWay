import Foundation
import Observation

/// The Learn tab: the brand's Learn page, or none (then "No content
/// available").
@MainActor
@Observable
public final class LearnViewModel {
  public let url: URL?

  public init(url: URL?) {
    self.url = url
  }
}
