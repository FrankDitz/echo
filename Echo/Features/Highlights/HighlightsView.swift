import SwiftUI

struct HighlightsView: View {
  let viewModel: HighlightsViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedItem: HighlightedEntry?

  var body: some View {
    EchoWorldCanvas {
      GeometryReader { geometry in
        ScrollView {
          if geometry.size.width >= EchoLayout.wideLayoutBreakpoint {
            HStack(alignment: .top, spacing: 64) {
              highlightsHeader
                .frame(width: 300, alignment: .leading)

              VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
                content
              }
              .frame(maxWidth: 620, alignment: .leading)
            }
            .frame(maxWidth: EchoLayout.wideContentMaxWidth, alignment: .topLeading)
            .padding(.horizontal, 40)
            .padding(.vertical, 56)
            .frame(maxWidth: .infinity, alignment: .top)
          } else {
            LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
              highlightsHeader
              content
            }
            .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
            .padding(.horizontal, EchoLayout.pageHorizontalPadding)
            .padding(.vertical, EchoLayout.pageVerticalPadding)
            .frame(maxWidth: .infinity)
          }
        }
        .scrollIndicators(.hidden)
      }
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
        .foregroundStyle(world.accent)

      Text("Highlights")
        .font(EchoTypography.editorialDisplay)
        .foregroundStyle(world.primaryText)
        .accessibilityAddTraits(.isHeader)

      Text("Meaningful moments, kept close.")
        .font(EchoTypography.supporting)
        .foregroundStyle(world.primaryText.opacity(0.82))
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
      VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
        filterRibbon

        EchoReadabilityPanel(padding: 0) {
          VStack(alignment: .leading, spacing: 0) {
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
                  .overlay(world.separator.opacity(0.7))
              }
            }
          }
        }
      }
    }

    if let failureMessage {
      EchoErrorState(message: failureMessage)
    }
  }

  private var filterRibbon: some View {
    Label(
      "\(viewModel.items.count) saved \(viewModel.items.count == 1 ? "moment" : "moments")",
      systemImage: "bookmark.fill"
    )
    .font(EchoTypography.metadata.weight(.semibold))
    .foregroundStyle(world.primaryText)
    .accessibilityLabel(
      "\(viewModel.items.count) saved \(viewModel.items.count == 1 ? "entry" : "entries")"
    )
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
