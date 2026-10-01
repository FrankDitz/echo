import SwiftUI

struct DayDetailView: View {
  let day: EchoDay
  let highlightViewModel: EntryHighlightViewModel
  var focusedEntryID: UUID?

  @State private var organizationViewModel: DayOrganizationViewModel

  init(
    day: EchoDay,
    highlightViewModel: EntryHighlightViewModel,
    aiService: any EchoAIService,
    journalRepository: any EchoOrganizedJournalRepository,
    focusedEntryID: UUID? = nil
  ) {
    self.day = day
    self.highlightViewModel = highlightViewModel
    self.focusedEntryID = focusedEntryID
    _organizationViewModel = State(
      initialValue: DayOrganizationViewModel(
        day: day,
        aiService: aiService,
        repository: journalRepository
      )
    )
  }

  @Environment(\.timeZone) private var timeZone

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
          header
          organizedJournal
          entries
        }
        .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
        .padding(.horizontal, EchoLayout.pageHorizontalPadding)
        .padding(.vertical, EchoLayout.pageVerticalPadding)
        .frame(maxWidth: .infinity)
      }
      .background(groupedBackground)
      .navigationTitle("Day Detail")
      .task {
        await highlightViewModel.load()
        await organizationViewModel.load()
        if let focusedEntryID {
          proxy.scrollTo(focusedEntryID, anchor: .center)
        }
      }
    }
  }

  private var organizedJournal: some View {
    VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
      HStack {
        Label("Organized Journal", systemImage: "wand.and.stars")
          .font(EchoTypography.contentTitle)
        Spacer()
        Button(
          organizationViewModel.journal == nil ? "Organize Day" : "Regenerate",
          systemImage: organizationViewModel.journal == nil ? "wand.and.stars" : "arrow.clockwise"
        ) {
          Task { await organizationViewModel.generate() }
        }
        .buttonStyle(.bordered)
        .disabled(
          organizationViewModel.isLoading || organizationViewModel.isGenerating
        )
      }

      if organizationViewModel.isLoading {
        ProgressView("Loading organized journal…")
      } else if organizationViewModel.isGenerating {
        ProgressView("Organizing this day…")
      } else if let journal = organizationViewModel.journal {
        Text(journal.body)
          .font(EchoTypography.body)
          .lineSpacing(5)
          .textSelection(.enabled)
        Text("Created locally from \(journal.sourceEntryIDs.count) raw \(journal.sourceEntryIDs.count == 1 ? "entry" : "entries").")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        Text("Create a readable daily narrative while keeping every original entry unchanged.")
          .font(EchoTypography.supporting)
          .foregroundStyle(.secondary)
      }

      if organizationViewModel.failure != nil {
        Label(
          "The organized journal could not be loaded or saved.",
          systemImage: "exclamationmark.triangle"
        )
        .font(EchoTypography.status)
        .foregroundStyle(.red)
      }
    }
    .padding(EchoLayout.surfacePadding)
    .background(
      Color.accentColor.opacity(EchoMaterialMetrics.organizedJournalFillOpacity),
      in: RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text(displayDate, format: .dateTime.weekday(.wide))
        .font(.title3.weight(.medium))
        .foregroundStyle(.secondary)
      Text(displayDate, format: .dateTime.month(.wide).day().year())
        .font(EchoTypography.screenTitle)
      Text(entryCountLabel)
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private var entries: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(day.entries) { entry in
        DayDetailEntry(
          entry: entry,
          highlightViewModel: highlightViewModel,
          isFocusedSource: entry.id == focusedEntryID
        )
        .id(entry.id)
        if entry.id != day.entries.last?.id {
          Divider()
            .padding(.vertical, EchoLayout.editorPadding)
        }
      }
    }
    .padding(EchoLayout.editorPadding)
    .background(.background, in: RoundedRectangle(cornerRadius: EchoShape.surfaceRadius))
    .overlay {
      RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
        .stroke(
          Color.secondary.opacity(EchoMaterialMetrics.subtleBorderOpacity),
          lineWidth: EchoShape.hairlineWidth
        )
    }
  }

  private var displayDate: Date {
    day.id.date(in: timeZone) ?? day.entries[0].createdAt
  }

  private var entryCountLabel: String {
    day.entryCount == 1 ? "1 entry" : "\(day.entryCount) entries"
  }

  private var groupedBackground: Color {
    #if os(iOS)
      Color(uiColor: .systemGroupedBackground)
    #else
      Color(nsColor: .windowBackgroundColor)
    #endif
  }
}

private struct DayDetailEntry: View {
  let entry: EchoEntry
  let highlightViewModel: EntryHighlightViewModel
  let isFocusedSource: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text(entry.createdAt, format: .dateTime.hour().minute())
        .font(EchoTypography.metadata)
        .foregroundStyle(.secondary)
      Text(entry.rawText)
        .font(EchoTypography.body)
        .lineSpacing(5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
        .buttonStyle(.borderless)
        .font(.subheadline)
    }
    .padding(isFocusedSource ? EchoLayout.focusedContentInset : 0)
    .background(
      isFocusedSource
        ? Color.accentColor.opacity(EchoMaterialMetrics.focusedSourceFillOpacity)
        : Color.clear,
      in: RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
    )
    .overlay {
      if isFocusedSource {
        RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
          .stroke(
            Color.accentColor.opacity(EchoMaterialMetrics.focusedSourceBorderOpacity),
            lineWidth: EchoShape.emphasizedBorderWidth
          )
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityValue(isFocusedSource ? "Highlighted source entry" : "")
  }
}
