import SwiftUI

enum EchoSurfaceStyle {
  case standard
  case accent(opacity: Double)
}

struct EchoSurface<Content: View>: View {
  let style: EchoSurfaceStyle
  let padding: CGFloat
  let cornerRadius: CGFloat
  private let content: Content

  init(
    style: EchoSurfaceStyle = .standard,
    padding: CGFloat = EchoLayout.surfacePadding,
    cornerRadius: CGFloat = EchoShape.surfaceRadius,
    @ViewBuilder content: () -> Content
  ) {
    self.style = style
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  var body: some View {
    content
      .padding(padding)
      .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius))
      .overlay {
        if case .standard = style {
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
              Color.secondary.opacity(EchoMaterialMetrics.subtleBorderOpacity),
              lineWidth: EchoShape.hairlineWidth
            )
        }
      }
  }

  private var fill: AnyShapeStyle {
    switch style {
    case .standard:
      AnyShapeStyle(.background)
    case .accent(let opacity):
      AnyShapeStyle(Color.accentColor.opacity(opacity))
    }
  }
}
