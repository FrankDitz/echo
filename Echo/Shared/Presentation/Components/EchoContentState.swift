import SwiftUI

struct EchoLoadingState: View {
  let title: String
  var minHeight = EchoLayout.regularStateHeight

  var body: some View {
    ProgressView(title)
      .frame(maxWidth: .infinity, minHeight: minHeight)
  }
}

struct EchoEmptyState: View {
  let title: String
  let systemImage: String
  let description: String
  var minHeight = EchoLayout.largeStateHeight

  var body: some View {
    ContentUnavailableView(
      title,
      systemImage: systemImage,
      description: Text(description)
    )
    .frame(maxWidth: .infinity, minHeight: minHeight)
  }
}

struct EchoErrorState: View {
  let message: String

  var body: some View {
    Label(message, systemImage: "exclamationmark.triangle")
      .font(EchoTypography.status)
      .foregroundStyle(.red)
  }
}
