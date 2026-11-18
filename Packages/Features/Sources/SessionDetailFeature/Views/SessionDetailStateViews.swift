import ScreenKit
import SleepGuardContentKit
import UIKit

/// Placeholder gauge, stats and rows while the night loads, in UIKit.
final class SessionDetailLoadingView: UIView {
  init(theme: Theme) {
    super.init(frame: .zero)
    let card = UIColor(theme.palette.bgCard)
    let gauge = RingView(color: UIColor(theme.palette.bgElevated), lineWidth: 10)
    let stats = Self.stack(spacing: 12, (0..<2).map { _ in Self.card(card, radius: theme.radii.card, height: 54) })
    let header = UIStackView(arrangedSubviews: [gauge, stats])
    header.spacing = 16
    header.alignment = .center
    let rows = (0..<4).map { _ in Self.card(card, radius: theme.radii.card, height: 50) }
    let content = Self.stack(spacing: 24, [header] + rows)
    content.translatesAutoresizingMaskIntoConstraints = false
    addSubview(content)
    NSLayoutConstraint.activate([
      gauge.widthAnchor.constraint(equalToConstant: 120),
      gauge.heightAnchor.constraint(equalToConstant: 120),
      content.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
      content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
    ])
    accessibilityElementsHidden = true
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("Created in code")
  }

  private static func stack(spacing: CGFloat, _ views: [UIView]) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = .vertical
    stack.spacing = spacing
    return stack
  }

  private static func card(_ color: UIColor, radius: CGFloat, height: CGFloat) -> UIView {
    let view = UIView()
    view.backgroundColor = color
    view.layer.cornerRadius = radius
    view.heightAnchor.constraint(equalToConstant: height).isActive = true
    return view
  }
}

/// A stroked circle: the gauge's place while loading.
private final class RingView: UIView {
  private let ring = CAShapeLayer()

  init(color: UIColor, lineWidth: CGFloat) {
    super.init(frame: .zero)
    ring.strokeColor = color.cgColor
    ring.fillColor = UIColor.clear.cgColor
    ring.lineWidth = lineWidth
    layer.addSublayer(ring)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("Created in code")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let inset = ring.lineWidth / 2
    ring.path = UIBezierPath(ovalIn: bounds.insetBy(dx: inset, dy: inset)).cgPath
  }
}

/// The night couldn't be loaded: a message and Try again, in UIKit.
final class SessionDetailErrorView: UIView {
  init(theme: Theme, onRetry: @escaping () -> Void) {
    super.init(frame: .zero)
    let icon = UIImageView(image: UIImage(
      systemName: "exclamationmark.triangle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48)))
    icon.tintColor = UIColor(theme.palette.textTertiary)
    icon.isAccessibilityElement = false
    let title = UILabel()
    title.text = Strings.recordingsErrorTitle
    title.font = theme.typography.uiFont(size: 17, weight: .semibold)
    title.textColor = UIColor(theme.palette.textPrimary)
    title.numberOfLines = 0
    title.textAlignment = .center
    var configuration = UIButton.Configuration.plain()
    configuration.attributedTitle = AttributedString(Strings.actionTryAgain, attributes: AttributeContainer([
      .font: theme.typography.uiFont(size: 17, weight: .semibold),
      .foregroundColor: UIColor(theme.palette.accent),
    ]))
    let retry = UIButton(configuration: configuration, primaryAction: UIAction { _ in onRetry() })
    let stack = UIStackView(arrangedSubviews: [icon, title, retry])
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
    ])
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("Created in code")
  }
}
