import SwiftUI

struct HighlightsView: View {
  let viewModel: HighlightsViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedItem: HighlightedEntry?

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
        header
        content
      }
      .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
      .padding(.horizontal, EchoLayout.pageHorizontalPadding)
      .padding(.vertical, EchoLayout.pageVerticalPadding)
      .frame(maxWidth: .infinity)
    }
    .background(groupedBackground)
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

  private var header: some View {
    VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
      Text("Highlights")
        .font(EchoTypography.screenTitle)
      Text("Meaningful moments, kept close.")
        .font(EchoTypography.screenSubtitle)
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
      Label(failureMessage, systemImage: "exclamationmark.triangle")
        .font(EchoTypography.status)
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
  let onOpen: () -> Void
  let onRemove: () -> Void

  var body: some View {
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
    .padding(EchoLayout.surfacePadding)
    .background(.background, in: RoundedRectangle(cornerRadius: EchoShape.surfaceRadius))
    .overlay {
      RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
        .stroke(
          Color.secondary.opacity(EchoMaterialMetrics.subtleBorderOpacity),
          lineWidth: EchoShape.hairlineWidth
        )
    }
    .contextMenu {
      Button("Remove Highlight", systemImage: "bookmark.slash", action: onRemove)
    }
  }
}
