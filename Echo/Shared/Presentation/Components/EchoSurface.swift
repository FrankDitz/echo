import SwiftUI

enum EchoSurfaceStyle {
  case standard
  case accent(opacity: Double)
}

struct EchoSurface<Content: View>: View {
  @Environment(\.echoVisualWorld) private var world

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
      .foregroundStyle(world.primaryText, world.secondaryText)
      .background {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(.ultraThinMaterial)
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(fill)
      }
      .shadow(color: world.contentShadow.opacity(0.18), radius: 16, y: 7)
      .overlay {
        if case .standard = style {
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
              world.separator,
              lineWidth: EchoShape.hairlineWidth
            )
        }
      }
  }

  private var fill: AnyShapeStyle {
    switch style {
    case .standard:
      AnyShapeStyle(world.canvas.opacity(0.18))
    case .accent(let opacity):
      AnyShapeStyle(world.accent.opacity(max(opacity, 0.12)))
    }
  }
}

struct EchoReadabilityPanel<Content: View>: View {
  @Environment(\.echoVisualWorld) private var world

  let padding: CGFloat
  let cornerRadius: CGFloat
  private let content: Content

  init(
    padding: CGFloat = EchoLayout.surfacePadding,
    cornerRadius: CGFloat = 16,
    @ViewBuilder content: () -> Content
  ) {
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  var body: some View {
    content
      .padding(padding)
      .foregroundStyle(world.primaryText, world.secondaryText)
      .background {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(.ultraThinMaterial)
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(world.surfaceFill.opacity(0.76))
      }
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(world.separator.opacity(0.9), lineWidth: EchoShape.hairlineWidth)
      }
      .shadow(color: world.contentShadow.opacity(0.26), radius: 18, y: 8)
  }
}
