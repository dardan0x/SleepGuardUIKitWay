import UIKit

/// The system share sheet for one file.
enum ShareSheet {
  static func make(_ url: URL) -> UIViewController {
    UIActivityViewController(activityItems: [url], applicationActivities: nil)
  }
}
