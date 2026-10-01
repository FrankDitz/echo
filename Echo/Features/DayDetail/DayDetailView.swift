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
      EchoPage(spacing: EchoLayout.sectionSpacing) {
        DayDateHeader(
          date: displayDate,
          entryCountLabel: entryCountLabel
        )
        DayReflectionSection(viewModel: organizationViewModel)
        entries
      }
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

  private var entries: some View {
    EchoSurface(padding: EchoLayout.editorPadding) {
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
    }
  }

  private var displayDate: Date {
    day.id.date(in: timeZone) ?? day.entries[0].createdAt
  }

  private var entryCountLabel: String {
    day.entryCount == 1 ? "1 entry" : "\(day.entryCount) entries"
  }
}

private struct DayDateHeader: View {
  let date: Date
  let entryCountLabel: String

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text(date, format: .dateTime.weekday(.wide))
        .font(.title3.weight(.medium))
        .foregroundStyle(.secondary)
      Text(date, format: .dateTime.month(.wide).day().year())
        .font(EchoTypography.screenTitle)
      Text(entryCountLabel)
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct DayReflectionSection: View {
  let viewModel: DayOrganizationViewModel

  var body: some View {
    EchoSurface(
      style: .accent(opacity: EchoMaterialMetrics.organizedJournalFillOpacity)
    ) {
      VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
        HStack {
          Label("Organized Journal", systemImage: "wand.and.stars")
            .font(EchoTypography.contentTitle)
          Spacer()
          Button(
            viewModel.journal == nil ? "Organize Day" : "Regenerate",
            systemImage: viewModel.journal == nil ? "wand.and.stars" : "arrow.clockwise"
          ) {
            Task { await viewModel.generate() }
          }
          .buttonStyle(.bordered)
          .disabled(viewModel.isLoading || viewModel.isGenerating)
        }

        reflectionContent

        if viewModel.failure != nil {
          EchoErrorState(message: "The organized journal could not be loaded or saved.")
        }
      }
    }
  }

  @ViewBuilder
  private var reflectionContent: some View {
    if viewModel.isLoading {
      EchoLoadingState(title: "Loading organized journal…", minHeight: 0)
    } else if viewModel.isGenerating {
      EchoLoadingState(title: "Organizing this day…", minHeight: 0)
    } else if let journal = viewModel.journal {
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
  }
}

private struct DayDetailEntry: View {
  let entry: EchoEntry
  let highlightViewModel: EntryHighlightViewModel
  let isFocusedSource: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      EchoEntryPresentation(
        text: entry.rawText,
        lineSpacing: 5,
        allowsSelection: true
      ) {
        Text(entry.createdAt, format: .dateTime.hour().minute())
      }
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
