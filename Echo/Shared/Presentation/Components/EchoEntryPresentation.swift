import SwiftUI

struct EchoEntryPresentation<Metadata: View>: View {
  let text: String
  var lineLimit: Int?
  var lineSpacing: CGFloat
  var allowsSelection: Bool
  private let metadata: Metadata

  init(
    text: String,
    lineLimit: Int? = nil,
    lineSpacing: CGFloat = 4,
    allowsSelection: Bool = false,
    @ViewBuilder metadata: () -> Metadata
  ) {
    self.text = text
    self.lineLimit = lineLimit
    self.lineSpacing = lineSpacing
    self.allowsSelection = allowsSelection
    self.metadata = metadata()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      metadata
        .font(EchoTypography.metadata)
        .foregroundStyle(.secondary)

      if allowsSelection {
        entryText.textSelection(.enabled)
      } else {
        entryText
      }
    }
  }

  private var entryText: some View {
    Text(text)
      .font(EchoTypography.body)
      .lineSpacing(lineSpacing)
      .lineLimit(lineLimit)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
