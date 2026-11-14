import UIKit

/// Temporary root screen until the shell exists (F1-T6): proves each brand
/// launches with its own name and colours. Delete it in F1-T6.
final class PlaceholderViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(named: "LaunchBackground")

    let name = UILabel()
    name.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    name.font = .preferredFont(forTextStyle: .largeTitle)
    name.textColor = UIColor(named: "BrandAccent")
    name.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(name)
    NSLayoutConstraint.activate([
      name.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      name.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
