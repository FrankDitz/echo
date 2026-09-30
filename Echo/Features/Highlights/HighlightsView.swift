import SwiftUI

struct HighlightsView: View {
  let viewModel: HighlightsViewModel

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        header
        content
      }
      .frame(maxWidth: 720, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity)
    }
    .background(groupedBackground)
    .task {
      await viewModel.load()
    }
    .refreshable {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Highlights")
        .font(.largeTitle.weight(.bold))
      Text("Meaningful moments, kept close.")
        .font(.title3)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading && viewModel.items.isEmpty {
      ProgressView("Loading your highlights…")
        .frame(maxWidth: .infinity, minHeight: 280)
    } else if viewModel.items.isEmpty {
      ContentUnavailableView(
        "Nothing highlighted yet",
        systemImage: "bookmark",
        description: Text("Highlight an entry when you find a moment worth keeping close.")
      )
      .frame(maxWidth: .infinity, minHeight: 320)
    } else {
      ForEach(viewModel.items) { item in
        HighlightedEntryRow(item: item) {
          Task {
            await viewModel.remove(entryID: item.entry.id)
          }
        }
      }
    }

    if let failureMessage {
      Label(failureMessage, systemImage: "exclamationmark.triangle")
        .font(.footnote)
        .foregroundStyle(.red)
    }
  }

  private var failureMessage: String? {
    switch viewModel.failure {
    case .load:
      "Highlights could not be loaded."
    case .remove:
      "This highlight could not be removed."
    case nil:
      nil
    }
  }

  private var groupedBackground: Color {
    #if os(iOS)
      Color(uiColor: .systemGroupedBackground)
    #else
      Color(nsColor: .windowBackgroundColor)
    #endif
  }
}

private struct HighlightedEntryRow: View {
  let item: HighlightedEntry
  let onRemove: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Text(item.entry.createdAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Menu("Highlight Actions", systemImage: "bookmark.fill") {
          Button("Remove Highlight", systemImage: "bookmark.slash", action: onRemove)
        }
        .labelStyle(.iconOnly)
        .accessibilityLabel("Highlight actions")
      }

      Text(item.entry.rawText)
        .font(.body)
        .lineSpacing(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }
    .padding(18)
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
    .overlay {
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
    }
    .contextMenu {
      Button("Remove Highlight", systemImage: "bookmark.slash", action: onRemove)
    }
  }
}
