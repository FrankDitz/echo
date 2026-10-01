import SwiftUI

struct EchoWorldCanvas<Content: View>: View {
  @Environment(\.echoVisualWorld) private var world

  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ZStack {
      GeometryReader { proxy in
        Image(world.backgroundAssetName)
          .resizable()
          .scaledToFill()
          .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
          .clipped()
          .ignoresSafeArea()
      }
      .accessibilityHidden(true)

      LinearGradient(
        colors: [
          world.canvas.opacity(0.2),
          world.canvas.opacity(0.38),
          world.canvas.opacity(0.72),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .accessibilityHidden(true)

      content
    }
    .background(world.canvas)
    .foregroundStyle(world.primaryText, world.secondaryText)
    .tint(world.accent)
  }
}
