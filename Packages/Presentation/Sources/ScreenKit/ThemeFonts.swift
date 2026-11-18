import SleepGuardDesignKit
import SwiftUI
import UIKit

public extension Typography {
  /// The theme's font for UIKit text (labels, buttons, segmented controls),
  /// the same face `font(size:weight:)` gives SwiftUI.
  func uiFont(size: CGFloat, weight: Font.Weight = .regular) -> UIFont {
    let base = UIFont.systemFont(ofSize: size, weight: Self.uiWeight(weight))
    guard let descriptor = base.fontDescriptor.withDesign(Self.uiDesign(design)) else { return base }
    return UIFont(descriptor: descriptor, size: size)
  }

  internal static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
    switch weight {
    case .ultraLight: .ultraLight
    case .thin: .thin
    case .light: .light
    case .medium: .medium
    case .semibold: .semibold
    case .bold: .bold
    case .heavy: .heavy
    case .black: .black
    default: .regular
    }
  }

  internal static func uiDesign(_ design: Font.Design) -> UIFontDescriptor.SystemDesign {
    switch design {
    case .rounded: .rounded
    case .serif: .serif
    case .monospaced: .monospaced
    default: .default
    }
  }
}
