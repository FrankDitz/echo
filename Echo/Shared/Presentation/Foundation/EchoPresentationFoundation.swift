import SwiftUI

enum EchoLayout {
  static let contentMaxWidth: CGFloat = 720
  static let pageHorizontalPadding: CGFloat = 20
  static let pageVerticalPadding: CGFloat = 24
  static let sectionSpacing: CGFloat = 28
  static let compactSectionSpacing: CGFloat = 24
  static let contentSpacing: CGFloat = 14
  static let rowSpacing: CGFloat = 12
  static let inlineSpacing: CGFloat = 8
  static let tightSpacing: CGFloat = 6
  static let microSpacing: CGFloat = 4
  static let surfacePadding: CGFloat = 18
  static let editorPadding: CGFloat = 20
  static let focusedContentInset: CGFloat = 14
  static let compactStateHeight: CGFloat = 160
  static let mediumStateHeight: CGFloat = 220
  static let regularStateHeight: CGFloat = 280
  static let largeStateHeight: CGFloat = 320
}

enum EchoShape {
  static let surfaceRadius: CGFloat = 18
  static let embeddedRadius: CGFloat = 12
  static let hairlineWidth: CGFloat = 0.5
  static let emphasizedBorderWidth: CGFloat = 1
}

enum EchoTypography {
  static let screenTitle = Font.largeTitle.weight(.bold)
  static let screenSubtitle = Font.title3
  static let sectionTitle = Font.title2.weight(.semibold)
  static let contentTitle = Font.title3.weight(.semibold)
  static let body = Font.body
  static let supporting = Font.subheadline
  static let metadata = Font.caption.weight(.semibold)
  static let status = Font.footnote
}

enum EchoMaterialMetrics {
  static let subtleBorderOpacity = 0.2
  static let organizedJournalFillOpacity = 0.06
  static let assistedWritingFillOpacity = 0.08
  static let focusedSourceFillOpacity = 0.1
  static let focusedSourceBorderOpacity = 0.35
}

enum EchoMotion {
  static let editorFocusDelay = Duration.milliseconds(300)
}
