import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The loaded nights list in UIKit: a plain list layout with a header per
/// month and a cell per day, each drawn by the shared `NightMonthHeader` and
/// `NightDayCard`. It owns which days are expanded and offers delete by
/// swiping; what a tap or a delete means is its owner's call.
final class NightsListController: UICollectionViewController {
  private let theme: Theme
  private let onOpen: (NightSummary) -> Void
  private let onDelete: (NightDay) -> Void
  private var items = NightsListItems(months: [])
  private var expanded: Set<NightDay.ID> = []
  private var dataSource: UICollectionViewDiffableDataSource<NightMonth.ID, NightDay.ID>!

  init(theme: Theme, onOpen: @escaping (NightSummary) -> Void, onDelete: @escaping (NightDay) -> Void) {
    self.theme = theme
    self.onOpen = onOpen
    self.onDelete = onDelete
    super.init(collectionViewLayout: UICollectionViewFlowLayout())
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("Created in code by HistoryViewController")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.setCollectionViewLayout(makeLayout(), animated: false)
    collectionView.backgroundColor = .clear
    collectionView.contentInset.bottom = 10
    dataSource = makeDataSource()
  }

  /// Shows `months`, keeping expanded days that are still there.
  func show(_ months: [NightMonth], animated: Bool) {
    loadViewIfNeeded()
    items = NightsListItems(months: months)
    expanded = items.listed(expanded)
    var snapshot = NSDiffableDataSourceSnapshot<NightMonth.ID, NightDay.ID>()
    for section in items.sections {
      snapshot.appendSections([section.month])
      snapshot.appendItems(section.days, toSection: section.month)
    }
    // A day keeps its identifier when its nights change: redraw every cell.
    snapshot.reconfigureItems(snapshot.itemIdentifiers)
    dataSource.apply(snapshot, animatingDifferences: animated)
  }

  /// A plain list: no separators, a header per month, delete on swipe.
  private func makeLayout() -> UICollectionViewLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    configuration.headerMode = .supplementary
    configuration.headerTopPadding = 0
    configuration.trailingSwipeActionsConfigurationProvider = { [weak self] in self?.swipeActions(at: $0) }
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<NightMonth.ID, NightDay.ID> {
    let cell = UICollectionView.CellRegistration<UICollectionViewListCell, NightDay.ID> { [weak self] cell, _, id in
      guard let self, let day = items.day(id) else { return }
      cell.contentConfiguration = theme.hosting {
        NightDayCard(
          day: day, isExpanded: expanded.contains(id), onOpen: onOpen,
          onToggle: { [weak self] in self?.toggle(id) }, onDeleteRequest: { [weak self] in self?.onDelete(day) })
      }
      .margins(.horizontal, 16)
      .margins(.vertical, 8)
      cell.backgroundConfiguration = .clear()
    }
    let header = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
      elementKind: UICollectionView.elementKindSectionHeader)
    { [weak self] view, _, indexPath in
      guard let self, let month = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
      view.contentConfiguration = theme.hosting {
        NightMonthHeader(month: month)
      }
      .margins(.horizontal, 20)
      view.backgroundConfiguration = .clear()
    }
    let dataSource = UICollectionViewDiffableDataSource<NightMonth.ID, NightDay.ID>(collectionView: collectionView) {
      collectionView, indexPath, id in
      collectionView.dequeueConfiguredReusableCell(using: cell, for: indexPath, item: id)
    }
    dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
      collectionView.dequeueConfiguredReusableSupplementary(using: header, for: indexPath)
    }
    return dataSource
  }

  private func toggle(_ id: NightDay.ID) {
    if expanded.remove(id) == nil { expanded.insert(id) }
    var snapshot = dataSource.snapshot()
    snapshot.reconfigureItems([id])
    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func swipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let id = dataSource.itemIdentifier(for: indexPath), let day = items.day(id) else { return nil }
    let delete = UIContextualAction(style: .destructive, title: Strings.actionDelete) { [weak self] _, _, done in
      self?.onDelete(day)
      done(true)
    }
    delete.image = UIImage(systemName: "trash")
    return UISwipeActionsConfiguration(actions: [delete])
  }

  override func collectionView(_: UICollectionView, shouldHighlightItemAt _: IndexPath) -> Bool {
    false
  }
}
