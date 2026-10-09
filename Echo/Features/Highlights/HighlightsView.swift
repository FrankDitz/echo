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
#if os(iOS)
      compactHighlights
#else
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
#endif
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

  private var compactHighlights: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        compactMasthead
        compactGallery
      }
      .frame(maxWidth: EchoLayout.contentMaxWidth)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private var compactMasthead: some View {
    VStack(alignment: .leading, spacing: 5) {
      Spacer(minLength: 52)
      Text("Highlights")
        .font(world.displayFont(size: 43, weight: .bold))
        .tracking(-0.6)
        .foregroundStyle(world.primaryText)
        .accessibilityAddTraits(.isHeader)

      Text("TRUTH WORTH RETURNING TO.")
        .font(.system(size: 10, weight: .black))
        .tracking(2.3)
        .foregroundStyle(world.primaryText.opacity(0.88))
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .padding(.horizontal, 18)
    .padding(.bottom, 17)
    .frame(maxWidth: .infinity, minHeight: 140, alignment: .bottomLeading)
  }

  @ViewBuilder
  private var compactGallery: some View {
    VStack(alignment: .leading, spacing: 12) {
      if viewModel.isLoading && viewModel.items.isEmpty {
        EchoLoadingState(title: "Loading your highlights…", minHeight: 280)
      } else if viewModel.items.isEmpty {
        EchoEmptyState(
          title: "Nothing highlighted yet",
          systemImage: "bookmark",
          description: "Highlight an entry when you find a moment worth keeping close.",
          minHeight: 280
        )
      } else {
        compactFilterRibbon

        if filteredItems.isEmpty {
          EchoEmptyState(
            title: "No \(selectedFilter.title.lowercased()) highlights",
            systemImage: selectedFilter.systemImage,
            description: "Choose another filter or save a matching entry.",
            minHeight: 220
          )
        } else {
          LazyVStack(alignment: .leading, spacing: 9) {
            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
              CompactHighlightedEntryCard(
                item: item,
                visualIndex: index,
                onOpen: { selectedItem = item },
                onRemove: {
                  Task { await viewModel.remove(entryID: item.entry.id) }
                }
              )
            }
          }
        }
      }

      if let failureMessage {
        EchoErrorState(message: failureMessage)
      }
    }
    .foregroundStyle(galleryInk)
    .padding(.horizontal, 14)
    .padding(.top, 12)
    .padding(.bottom, 28)
    .frame(maxWidth: .infinity, minHeight: 500, alignment: .topLeading)
    .background(galleryBackground)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(world.editorialAccent)
        .frame(height: 3)
    }
  }

  private var compactFilterRibbon: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 7) {
        ForEach(HighlightFilter.allCases) { filter in
          Button {
            selectedFilter = filter
          } label: {
            Label(filter.title, systemImage: filter.systemImage)
              .font(.caption.weight(.semibold))
              .foregroundStyle(compactFilterInk(for: filter))
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(compactFilterFill(for: filter), in: RoundedRectangle(cornerRadius: 9))
              .overlay {
                RoundedRectangle(cornerRadius: 9)
                  .stroke(galleryInk.opacity(0.16), lineWidth: 0.75)
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

  private var galleryBackground: Color {
    return switch world.id {
    case .goldStandard:
      world.canvas.opacity(0.96)
    case .kingdomGreen:
      world.canvas.opacity(0.95)
    case .covenantBlue, .cornerstoneSignal:
      world.editorialPaper.opacity(0.98)
    }
  }

  private var galleryInk: Color {
    return switch world.id {
    case .goldStandard, .covenantBlue, .cornerstoneSignal:
      world.editorialInk
    case .kingdomGreen:
      world.primaryText
    }
  }

  private func compactFilterFill(for filter: HighlightFilter) -> Color {
    guard selectedFilter == filter else {
      return world.id == .kingdomGreen
        ? world.surfaceFill.opacity(0.78)
        : world.editorialPaper.opacity(0.66)
    }

    return switch world.id {
    case .goldStandard:
      world.editorialInk
    case .kingdomGreen:
      world.editorialPaper
    case .covenantBlue, .cornerstoneSignal:
      world.editorialAccent
    }
  }

  private func compactFilterInk(for filter: HighlightFilter) -> Color {
    guard selectedFilter == filter else { return galleryInk }

    return switch world.id {
    case .goldStandard:
      world.canvas
    case .kingdomGreen:
      world.editorialInk
    case .covenantBlue, .cornerstoneSignal:
      world.editorialPaper
    }
  }

  private var highlightsHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text("SAVED WRITING")
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.5)
        .foregroundStyle(world.accent)

      Text("Highlights")
        .font(world.displayFont(size: 38, weight: .medium))
        .foregroundStyle(world.primaryText)
        .accessibilityAddTraits(.isHeader)

      Text("Meaningful moments, kept close.")
        .font(EchoTypography.supporting)
        .foregroundStyle(world.primaryText.opacity(0.82))
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
          LazyVStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
            ForEach(filteredItems) { item in
              EchoReadabilityPanel(padding: 0, cornerRadius: 12) {
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

private struct CompactHighlightedEntryCard: View {
  let item: HighlightedEntry
  let visualIndex: Int
  let onOpen: () -> Void
  let onRemove: () -> Void

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Button(action: onOpen) {
        HStack(alignment: .top, spacing: 10) {
          thumbnail

          VStack(alignment: .leading, spacing: 5) {
            Text(item.entry.preferredText)
              .font(.system(size: 14, weight: .medium, design: .serif))
              .lineSpacing(2)
              .lineLimit(3)
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 5) {
              Image(systemName: item.entry.type == .voice ? "waveform" : "text.alignleft")
              Text(
                item.entry.createdAt.formatted(
                  .dateTime.month(.abbreviated).day().year()
                ).uppercased()
              )
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(cardInk.opacity(0.6))
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Opens the original day and entry")

      VStack(spacing: 4) {
        Button(action: onRemove) {
          Image(systemName: "bookmark.fill")
            .font(.body.weight(.bold))
            .foregroundStyle(cardAccent)
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove Highlight")

        Menu {
          Button("Open original", systemImage: "arrow.up.right", action: onOpen)
          Button("Remove Highlight", systemImage: "bookmark.slash", role: .destructive, action: onRemove)
        } label: {
          Image(systemName: "ellipsis")
            .font(.subheadline.weight(.bold))
            .frame(width: 28, height: 28)
            .foregroundStyle(cardInk)
        }
      }
    }
    .foregroundStyle(cardInk)
    .padding(9)
    .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
    .background(cardFill, in: RoundedRectangle(cornerRadius: 11))
    .overlay {
      RoundedRectangle(cornerRadius: 11)
        .stroke(cardBorder, lineWidth: 0.8)
    }
    .shadow(color: world.contentShadow.opacity(0.18), radius: 5, y: 2)
    .contextMenu {
      Button("Open original", systemImage: "arrow.up.right", action: onOpen)
      Button("Remove Highlight", systemImage: "bookmark.slash", role: .destructive, action: onRemove)
    }
  }

  private var thumbnail: some View {
    ZStack {
      LinearGradient(
        colors: thumbnailColors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(spacing: 5) {
        Image(systemName: item.entry.type == .voice ? "waveform" : "quote.opening")
          .font(.title3.weight(.bold))
        Rectangle()
          .fill(.white.opacity(0.7))
          .frame(width: 24, height: 1)
      }
      .foregroundStyle(.white)
    }
    .frame(width: 72, height: 72)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(.white.opacity(0.28), lineWidth: 0.75)
    }
    .accessibilityHidden(true)
  }

  private var usesDarkCard: Bool {
    switch world.id {
    case .covenantBlue:
      !visualIndex.isMultiple(of: 2)
    case .cornerstoneSignal:
      visualIndex.isMultiple(of: 3)
    case .goldStandard, .kingdomGreen:
      false
    }
  }

  private var cardFill: Color {
    usesDarkCard ? world.surfaceFill.opacity(0.98) : world.editorialPaper
  }

  private var cardInk: Color {
    usesDarkCard ? world.primaryText : world.editorialInk
  }

  private var cardAccent: Color {
    usesDarkCard ? world.accent : world.editorialAccent
  }

  private var cardBorder: Color {
    usesDarkCard ? world.separator : world.editorialInk.opacity(0.12)
  }

  private var thumbnailColors: [Color] {
    let accent = usesDarkCard ? world.accent : world.editorialAccent
    return visualIndex.isMultiple(of: 2)
      ? [accent.opacity(0.95), cardInk.opacity(0.92)]
      : [cardInk.opacity(0.86), accent.opacity(0.74)]
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
