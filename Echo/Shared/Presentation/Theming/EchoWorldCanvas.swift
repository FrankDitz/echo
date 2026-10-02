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
        ZStack {
          Image(world.backgroundAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .clipped()

          if proxy.size.width >= EchoLayout.wideLayoutBreakpoint {
            LinearGradient(
              colors: [
                world.canvas.opacity(0.5),
                world.canvas.opacity(0.08),
                world.canvas.opacity(0.34),
              ],
              startPoint: .leading,
              endPoint: .trailing
            )

            LinearGradient(
              colors: [
                world.canvas.opacity(0.08),
                Color.clear,
                world.canvas.opacity(0.38),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          } else {
            LinearGradient(
              colors: [
                world.canvas.opacity(0.12),
                world.canvas.opacity(0.28),
                world.canvas.opacity(0.66),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          }
        }
        .ignoresSafeArea()
      }
      .accessibilityHidden(true)

      content
    }
    .background(world.canvas)
    .foregroundStyle(world.primaryText, world.secondaryText)
    .tint(world.accent)
  }
}
