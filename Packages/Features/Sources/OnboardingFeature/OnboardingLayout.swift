import UIKit

/// Where the onboarding's parts go: Skip in a 44-point bar at the top, the
/// pages filling the middle, the dots and Back at the bottom (the shared
/// content's spacing).
enum OnboardingLayout {
  static func arrange(
    in screen: UIViewController, pager: UIViewController, skip: UIButton, dots: UIViewController, back: UIButton)
  {
    let view: UIView = screen.view
    for child in [pager, dots] {
      screen.addChild(child)
      child.view.backgroundColor = .clear
    }
    let bottom = UIStackView(arrangedSubviews: [dots.view, back])
    bottom.axis = .vertical
    bottom.alignment = .center
    bottom.spacing = 16
    for part in [skip, pager.view, bottom] as [UIView] {
      part.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(part)
    }
    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      skip.topAnchor.constraint(equalTo: guide.topAnchor),
      skip.heightAnchor.constraint(equalToConstant: 44),
      skip.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
      pager.view.topAnchor.constraint(equalTo: guide.topAnchor, constant: 44),
      pager.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pager.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottom.topAnchor.constraint(equalTo: pager.view.bottomAnchor),
      bottom.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      bottom.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -32),
    ])
    for child in [pager, dots] {
      child.didMove(toParent: screen)
    }
  }
}
