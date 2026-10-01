import SwiftUI

struct EchoScreenHeader: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
      Text(title)
        .font(EchoTypography.screenTitle)
      Text(subtitle)
        .font(EchoTypography.screenSubtitle)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }
}
