import SleepCore
import SleepGuardContentKit
import UIKit

/// The event filter as a native segmented control, in the theme's font.
final class FilterCell: UICollectionViewCell {
  private let control = UISegmentedControl()
  private var options: [EventFilter] = []
  private var onSelect: ((EventFilter) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    control.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(control)
    NSLayoutConstraint.activate([
      control.topAnchor.constraint(equalTo: contentView.topAnchor),
      control.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      control.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      control.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
    ])
    control.addAction(UIAction { [weak self] _ in self?.selectionChanged() }, for: .valueChanged)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("Created in code by NightDetailController")
  }

  func configure(options: [EventFilter], selected: EventFilter, theme: Theme, onSelect: @escaping (EventFilter) -> Void) {
    self.options = options
    self.onSelect = onSelect
    control.removeAllSegments()
    for (index, option) in options.enumerated() {
      control.insertSegment(withTitle: option.title, at: index, animated: false)
    }
    control.selectedSegmentIndex = options.firstIndex(of: selected) ?? UISegmentedControl.noSegment
    control.setTitleTextAttributes([.font: theme.typography.uiFont(size: 13, weight: .medium)], for: .normal)
  }

  private func selectionChanged() {
    guard options.indices.contains(control.selectedSegmentIndex) else { return }
    onSelect?(options[control.selectedSegmentIndex])
  }
}
