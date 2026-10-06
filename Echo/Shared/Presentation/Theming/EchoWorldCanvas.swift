import SwiftUI

struct EchoWorldCanvas<Content: View>: View {
  @Environment(\.echoVisualWorld) private var world
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ZStack {
      GeometryReader { proxy in
        let canvasWidth = max(proxy.size.width, 0)
        let canvasHeight = max(proxy.size.height, 0)

        ZStack {
          Image(world.backgroundAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: canvasWidth, height: canvasHeight, alignment: .top)
            .clipped()
            .id(world.id)
            .transition(.opacity)

          if canvasWidth >= EchoLayout.wideLayoutBreakpoint {
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

          if reduceTransparency {
            world.canvas.opacity(0.68)
          }
        }
        .ignoresSafeArea()
        .animation(
          EchoMotion.animation(EchoMotion.ambient, reduceMotion: reduceMotion),
          value: world.id
        )
      }
      .accessibilityHidden(true)

      content
    }
    .background(world.canvas)
    .foregroundStyle(world.primaryText, world.secondaryText)
    .tint(world.accent)
  }
}
