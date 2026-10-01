import SwiftUI

struct HighlightsView: View {
  let viewModel: HighlightsViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedItem: HighlightedEntry?

  var body: some View {
    EchoPage(spacing: EchoLayout.compactSectionSpacing) {
      highlightsHeader
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

  private var highlightsHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text("SAVED WRITING")
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.5)
        .foregroundStyle(.secondary)

      Text("Highlights")
        .font(EchoTypography.editorialDisplay)
        .accessibilityAddTraits(.isHeader)

      Text("Meaningful moments, kept close.")
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading && viewModel.items.isEmpty {
      EchoLoadingState(title: "Loading your highlights…")
    } else if viewModel.items.isEmpty {
      EchoSurface {
        EchoEmptyState(
          title: "Nothing highlighted yet",
          systemImage: "bookmark",
          description: "Highlight an entry when you find a moment worth keeping close.",
          minHeight: EchoLayout.mediumStateHeight
        )
      }
    } else {
      EchoSurface(padding: 0) {
        VStack(alignment: .leading, spacing: 0) {
          savedHeader

          Divider()

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

            if item.id != viewModel.items.last?.id {
              Divider()
                .padding(.leading, EchoLayout.surfacePadding)
            }
          }
        }
      }
    }

    if let failureMessage {
      EchoErrorState(message: failureMessage)
    }
  }

  private var savedHeader: some View {
    HStack(spacing: EchoLayout.rowSpacing) {
      Label("Saved", systemImage: "bookmark.fill")
        .font(EchoTypography.primaryNavigation)
        .foregroundStyle(world.canvas)
        .padding(.horizontal, EchoLayout.contentSpacing)
        .padding(.vertical, EchoLayout.tightSpacing)
        .background(world.accent, in: Capsule())

      Spacer()

      Text(viewModel.items.count, format: .number)
        .font(EchoTypography.metadata)
        .foregroundStyle(.secondary)
        .accessibilityLabel(
          "\(viewModel.items.count) saved \(viewModel.items.count == 1 ? "entry" : "entries")"
        )
    }
    .padding(.horizontal, EchoLayout.surfacePadding)
    .padding(.vertical, EchoLayout.contentSpacing)
  }

  @Environment(\.echoVisualWorld) private var world

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

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.contentSpacing) {
      Button(action: onOpen) {
        VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
          Text(item.entry.rawText)
            .font(EchoTypography.body)
            .lineSpacing(4)
            .lineLimit(5)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

          Text(
            item.entry.createdAt.formatted(
              .dateTime.month(.abbreviated).day().year()
            ).uppercased()
          )
          .font(EchoTypography.editorialEyebrow)
          .tracking(1.2)
          .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Opens the original day and entry")

      Button(action: onRemove) {
        Image(systemName: "bookmark.fill")
          .font(.title3.weight(.semibold))
          .foregroundStyle(world.accent)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Remove Highlight")
      .accessibilityHint("Removes this entry from Highlights")
    }
    .padding(EchoLayout.surfacePadding)
    .contextMenu {
      Button("Remove Highlight", systemImage: "bookmark.slash", action: onRemove)
    }
  }
}
