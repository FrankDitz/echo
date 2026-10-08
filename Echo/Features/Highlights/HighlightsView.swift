import SwiftUI

struct HighlightsView: View {
  let viewModel: HighlightsViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedItem: HighlightedEntry?
  @State private var selectedFilter: HighlightFilter = .saved

  var body: some View {
    EchoWorldCanvas(screen: .highlights) {
      GeometryReader { geometry in
        ScrollView {
          if geometry.size.width >= EchoLayout.wideLayoutBreakpoint {
            LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
              highlightsHeader
              content(isWide: true)
            }
            .frame(maxWidth: EchoLayout.wideContentMaxWidth, alignment: .topLeading)
            .padding(.horizontal, 40)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity, alignment: .top)
          } else {
            LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
              highlightsHeader
              content(isWide: false)
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
  private func content(isWide: Bool) -> some View {
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

        if filteredItems.isEmpty {
          EchoSurface {
            EchoEmptyState(
              title: "No \(selectedFilter.title.lowercased()) highlights",
              systemImage: selectedFilter.systemImage,
              description: "Choose another filter or save a matching entry.",
              minHeight: EchoLayout.compactStateHeight
            )
          }
        } else if isWide {
          LazyVGrid(
            columns: [
              GridItem(.flexible(), spacing: EchoLayout.contentSpacing, alignment: .top),
              GridItem(.flexible(), spacing: EchoLayout.contentSpacing, alignment: .top),
            ],
            alignment: .leading,
            spacing: EchoLayout.contentSpacing
          ) {
            ForEach(filteredItems) { item in
              EchoReadabilityPanel(padding: 0) {
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
          }
        } else {
          EchoReadabilityPanel(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(filteredItems) { item in
                HighlightedEntryRow(
                  item: item,
                  onOpen: { selectedItem = item },
                  onRemove: {
                    Task {
                      await viewModel.remove(entryID: item.entry.id)
                    }
                  }
                )

                if item.id != filteredItems.last?.id {
                  Divider()
                    .overlay(world.separator.opacity(0.7))
                }
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
    ScrollView(.horizontal) {
      HStack(spacing: EchoLayout.inlineSpacing) {
        ForEach(HighlightFilter.allCases) { filter in
          Button {
            selectedFilter = filter
          } label: {
            Label(filter.title, systemImage: filter.systemImage)
              .font(EchoTypography.metadata.weight(.semibold))
              .foregroundStyle(selectedFilter == filter ? world.canvas : world.primaryText)
              .padding(.horizontal, EchoLayout.contentSpacing)
              .padding(.vertical, EchoLayout.inlineSpacing)
              .background(
                selectedFilter == filter ? world.accent : world.surfaceFill.opacity(0.82),
                in: Capsule()
              )
              .overlay {
                Capsule().stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
              }
          }
          .buttonStyle(.plain)
        }
      }
    }
    .scrollIndicators(.hidden)
    .accessibilityLabel(
      "\(viewModel.items.count) saved \(viewModel.items.count == 1 ? "entry" : "entries")"
    )
  }

  @Environment(\.echoVisualWorld) private var world

  private var filteredItems: [HighlightedEntry] {
    switch selectedFilter {
    case .saved:
      viewModel.items
    case .text:
      viewModel.items.filter { $0.entry.type != .voice }
    case .voice:
      viewModel.items.filter { $0.entry.type == .voice }
    }
  }

  private enum HighlightFilter: String, CaseIterable, Identifiable {
    case saved
    case text
    case voice

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var systemImage: String {
      switch self {
      case .saved: "bookmark.fill"
      case .text: "text.alignleft"
      case .voice: "waveform"
      }
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

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.contentSpacing) {
      Button(action: onOpen) {
        VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
          Text(item.entry.preferredText)
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
