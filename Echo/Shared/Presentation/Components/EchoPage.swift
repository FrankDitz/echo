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
    EchoWorldCanvas {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: spacing) {
          content
        }
        .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
        .padding(.horizontal, EchoLayout.pageHorizontalPadding)
        .padding(.vertical, EchoLayout.pageVerticalPadding)
        .frame(maxWidth: .infinity)
      }
    }
  }
}
