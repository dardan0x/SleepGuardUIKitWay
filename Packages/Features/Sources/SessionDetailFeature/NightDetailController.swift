import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI
import UIKit

/// A loaded night in a UIKit compositional layout: the shared header, sleep
/// stages, timeline, banners and event rows are hosted cells; the event
/// filter is a native segmented control, the events title and "Show all" are
/// UIKit text. Shows the filter it's given; what an action means, choosing
/// a filter included, is its owner's call.
final class NightDetailController: UICollectionViewController {
  struct Actions {
    let play: (EventListRow) -> Void
    let showAll: ([EventListRow]) -> Void
    let share: (EventListRow) -> Void
    let stagesInfo: (SleepStageBreakdown) -> Void
    let select: (EventFilter) -> Void
  }

  private typealias Section = NightDetailItems.Section
  private typealias Item = NightDetailItems.Item

  let detail: SessionDetail
  private let theme: Theme
  private let actions: Actions
  private(set) var filter = EventFilter.all
  private var items: NightDetailItems
  private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

  init(detail: SessionDetail, theme: Theme, actions: Actions) {
    self.detail = detail
    self.theme = theme
    self.actions = actions
    items = NightDetailItems(night: detail.session, filter: .all)
    super.init(collectionViewLayout: UICollectionViewFlowLayout())
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("Created in code by SessionDetailViewController")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.setCollectionViewLayout(Self.layout(), animated: false)
    collectionView.backgroundColor = .clear
    dataSource = makeDataSource()
    apply(animated: false)
  }

  /// Shows the rows under `filter`.
  func show(filter: EventFilter) {
    guard filter != self.filter else { return }
    self.filter = filter
    items = NightDetailItems(night: detail.session, filter: filter)
    if isViewLoaded { apply(animated: true) }
  }

  private func apply(animated: Bool) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    for group in items.groups {
      snapshot.appendSections([group.section])
      snapshot.appendItems(group.items, toSection: group.section)
    }
    snapshot.reconfigureItems(snapshot.itemIdentifiers.filter { $0 == .eventsTitle || $0 == .showAll })
    dataSource.apply(snapshot, animatingDifferences: animated)
  }

  /// One full-width, self-sizing item per row; the shared content's spacing.
  private static func layout() -> UICollectionViewLayout {
    let configuration = UICollectionViewCompositionalLayoutConfiguration()
    configuration.interSectionSpacing = 24
    return UICollectionViewCompositionalLayout(sectionProvider: { _, _ in
      let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80))
      let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = 12
      section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
      return section
    }, configuration: configuration)
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
    let hosted = UICollectionView.CellRegistration<UICollectionViewCell, Item> { [weak self] cell, _, item in
      guard let self else { return }
      cell.contentConfiguration = UIHostingConfiguration { self.content(for: item).environment(\.theme, self.theme) }
        .margins(.all, 0)
    }
    let text = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, _, item in
      guard let self else { return }
      cell.contentConfiguration = textConfiguration(for: item)
      cell.backgroundConfiguration = .clear()
      cell.accessibilityTraits = item == .showAll ? .button : .header
    }
    let filter = UICollectionView.CellRegistration<FilterCell, Item> { [weak self] cell, _, _ in
      guard let self else { return }
      cell.configure(
        options: EventFilter.options(for: detail.session.events), selected: self.filter, theme: theme,
        onSelect: { [actions] in actions.select($0) })
    }
    return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
      switch item {
      case .filter: collectionView.dequeueConfiguredReusableCell(using: filter, for: indexPath, item: item)
      case .eventsTitle, .showAll: collectionView.dequeueConfiguredReusableCell(using: text, for: indexPath, item: item)
      default: collectionView.dequeueConfiguredReusableCell(using: hosted, for: indexPath, item: item)
      }
    }
  }

  @ViewBuilder
  private func content(for item: Item) -> some View {
    let night = detail.session
    switch item {
    case .header: NightDetailHeader(night: night, summary: detail.summary)
    case .stages:
      if let stages = items.stages {
        SleepStagesCard(breakdown: stages, start: night.start, duration: night.duration) { [actions] in
          actions.stagesInfo(stages)
        }
      }
    case .timeline: NightTimeline(night: night)
    case .gapsBanner: RecordingGapsBanner(totalGap: night.melodyGapsDuration)
    case .batteryBanner: LowBatteryBanner()
    case let .event(id):
      if let row = items.row(id) {
        EventRow(
          start: row.start, duration: row.duration, category: row.category, intensity: row.intensity,
          onPlay: { [actions] in actions.play(row) }, onShare: { [actions] in actions.share(row) })
      }
    case .filter, .eventsTitle, .showAll: EmptyView()
    }
  }

  private func textConfiguration(for item: Item) -> UIListContentConfiguration {
    var content = UIListContentConfiguration.cell()
    content.directionalLayoutMargins = .zero
    if item == .showAll {
      content.text = String(format: Strings.recordingsDetailShowAllFormat, items.rows.count)
      content.textProperties.font = theme.typography.uiFont(size: 15, weight: .medium)
      content.textProperties.color = UIColor(theme.palette.accent)
      content.textProperties.alignment = .center
      content.directionalLayoutMargins.bottom = 10
    } else {
      content.attributedText = NSAttributedString(
        string: String(format: filter.listTitle, items.rows.count),
        attributes: [
          .font: theme.typography.uiFont(size: 12, weight: .semibold),
          .foregroundColor: UIColor(theme.palette.textTertiary),
          .kern: 1,
        ])
    }
    return content
  }

  override func collectionView(_: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    dataSource.itemIdentifier(for: indexPath) == .showAll
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    if dataSource.itemIdentifier(for: indexPath) == .showAll { actions.showAll(items.rows) }
  }
}
