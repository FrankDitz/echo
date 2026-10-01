import SwiftUI

struct HighlightsView: View {
  let viewModel: HighlightsViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedItem: HighlightedEntry?

  var body: some View {
    EchoPage(spacing: EchoLayout.compactSectionSpacing) {
      EchoScreenHeader(
        title: "Highlights",
        subtitle: "Meaningful moments, kept close."
      )
      content
    }
    .task {
      await viewModel.load()
    }
    .refreshable {
      await viewModel.load()
    }
    .navigationDestination(item: $selectedItem) { item in
      DayDetailView(
        day: item.sourceDay,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        journalRepository: journalRepository,
        focusedEntryID: item.entry.id
      )
    }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading && viewModel.items.isEmpty {
      EchoLoadingState(title: "Loading your highlights…")
    } else if viewModel.items.isEmpty {
      EchoEmptyState(
        title: "Nothing highlighted yet",
        systemImage: "bookmark",
        description: "Highlight an entry when you find a moment worth keeping close."
      )
    } else {
      ForEach(viewModel.items) { item in
        HighlightedEntryRow(
          item: item,
          onOpen: { selectedItem = item },
          onRemove: {
            Task {
              await viewModel.remove(entryID: item.entry.id)
            }
          }
        )
      }
    }

    if let failureMessage {
      EchoErrorState(message: failureMessage)
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
}

private struct HighlightedEntryRow: View {
  let item: HighlightedEntry
  let onOpen: () -> Void
  let onRemove: () -> Void

  var body: some View {
    EchoSurface {
      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
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

        Button(action: onOpen) {
          VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
            Text(item.entry.rawText)
              .font(EchoTypography.body)
              .lineSpacing(4)
              .frame(maxWidth: .infinity, alignment: .leading)

            Label("View in Day Detail", systemImage: "arrow.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the original day and entry")
      }
    }
    .contextMenu {
      Button("Remove Highlight", systemImage: "bookmark.slash", action: onRemove)
    }
  }
}
