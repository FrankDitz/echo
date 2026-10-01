import SwiftUI

struct EchoScreenHeader: View {
  let title: String
  let subtitle: String

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
      Text(title)
        .font(EchoTypography.screenTitle)
        .foregroundStyle(world.primaryText)
      Text(subtitle)
        .font(EchoTypography.screenSubtitle)
        .foregroundStyle(world.secondaryText)
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
  }
}
