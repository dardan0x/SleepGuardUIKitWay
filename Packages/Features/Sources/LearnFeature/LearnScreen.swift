import SleepGuardContentKit
import SwiftUI

/// The Learn tab, hosting the shared `LearnContent`: the brand's Learn page,
/// or "No content available" when it has none.
public struct LearnScreen: View {
  let url: URL?

  public init(url: URL?) {
    self.url = url
  }

  public var body: some View {
    LearnContent(url: url)
  }
}
