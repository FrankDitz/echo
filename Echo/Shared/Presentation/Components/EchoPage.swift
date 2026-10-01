import SwiftUI

struct EchoPage<Content: View>: View {
  let spacing: CGFloat
  private let content: Content

  init(
    spacing: CGFloat,
    @ViewBuilder content: () -> Content
  ) {
    self.spacing = spacing
    self.content = content()
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: spacing) {
        content
      }
      .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
      .padding(.horizontal, EchoLayout.pageHorizontalPadding)
      .padding(.vertical, EchoLayout.pageVerticalPadding)
      .frame(maxWidth: .infinity)
    }
    .background(EchoPlatformColor.groupedBackground)
  }
}

enum EchoPlatformColor {
  static var groupedBackground: Color {
    #if os(iOS)
      Color(uiColor: .systemGroupedBackground)
    #else
      Color(nsColor: .windowBackgroundColor)
    #endif
  }
}
