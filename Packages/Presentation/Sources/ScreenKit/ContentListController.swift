import UIKit

/// A screen's loaded content as a vertical UIKit list: one self-sizing row
/// per content configuration (a hosted shared view, or a UIKit one), in
/// order, scrolling. Setting `rows` redraws them. For screens whose content
/// is a few shared pieces stacked (the dashboard, trends, the player).
public final class ContentListController: UICollectionViewController {
  public struct Row {
    public let id: String
    public let configuration: any UIContentConfiguration
    /// Makes the row tappable (a UIKit text row such as "Show all").
    public let onTap: (@MainActor () -> Void)?

    public init(id: String, configuration: any UIContentConfiguration, onTap: (@MainActor () -> Void)? = nil) {
      self.id = id
      self.configuration = configuration
      self.onTap = onTap
    }
  }

  public var rows: [Row] = [] {
    didSet { apply() }
  }

  private let spacing: CGFloat
  private let insets: NSDirectionalEdgeInsets
  private var dataSource: UICollectionViewDiffableDataSource<Int, String>!

  public init(rows: [Row] = [], spacing: CGFloat = 0, insets: NSDirectionalEdgeInsets = .zero) {
    self.rows = rows
    self.spacing = spacing
    self.insets = insets
    super.init(collectionViewLayout: UICollectionViewFlowLayout())
  }

  @available(*, unavailable)
  public required init?(coder _: NSCoder) {
    fatalError("Created in code")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    collectionView.setCollectionViewLayout(layout(), animated: false)
    collectionView.backgroundColor = .clear
    let cell = UICollectionView.CellRegistration<UICollectionViewCell, String> { [weak self] cell, _, id in
      guard let row = self?.rows.first(where: { $0.id == id }) else { return }
      cell.contentConfiguration = row.configuration
      cell.accessibilityTraits = row.onTap == nil ? [] : .button
    }
    dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, id in
      collectionView.dequeueConfiguredReusableCell(using: cell, for: indexPath, item: id)
    }
    apply()
  }

  private func apply() {
    guard let dataSource else { return }
    var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
    snapshot.appendSections([0])
    snapshot.appendItems(rows.map(\.id))
    snapshot.reconfigureItems(rows.map(\.id))
    dataSource.apply(snapshot, animatingDifferences: false)
  }

  private func layout() -> UICollectionViewLayout {
    let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(120))
    let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = spacing
    section.contentInsets = insets
    return UICollectionViewCompositionalLayout(section: section)
  }

  override public func collectionView(_: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    row(at: indexPath)?.onTap != nil
  }

  override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    row(at: indexPath)?.onTap?()
  }

  private func row(at indexPath: IndexPath) -> Row? {
    dataSource.itemIdentifier(for: indexPath).flatMap { id in rows.first { $0.id == id } }
  }
}
