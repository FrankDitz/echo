import SwiftUI

struct DayReflectionView: View {
  let todayViewModel: TodayViewModel
  let timelineViewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  var body: some View {
    Group {
      if let latestDay {
        DayDetailView(
          day: latestDay,
          highlightViewModel: highlightViewModel,
          aiService: aiService,
          journalRepository: journalRepository
        )
        .id(latestDay.id)
      } else if todayViewModel.isLoading || timelineViewModel.isLoading {
        EchoPage(spacing: EchoLayout.compactSectionSpacing) {
          reflectionHeader
          EchoLoadingState(title: "Loading your reflection…")
        }
      } else {
        EchoPage(spacing: EchoLayout.compactSectionSpacing) {
          reflectionHeader
          EchoSurface {
            EchoEmptyState(
              title: "A reflection needs a day",
              systemImage: "sparkles.rectangle.stack",
              description: "Write an entry first, then Echo can organize the day without changing your original words.",
              minHeight: EchoLayout.mediumStateHeight
            )
          }
        }
      }
    }
    .task {
      await todayViewModel.load()
      await timelineViewModel.load()
    }
  }

  private var latestDay: EchoDay? {
    EchoDay.grouping(todayViewModel.entries).last ?? timelineViewModel.days.first
  }

  private var reflectionHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text("DAY REFLECTION")
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.5)
        .foregroundStyle(.secondary)
      Text("Make sense of the day.")
        .font(EchoTypography.editorialDisplay)
        .accessibilityAddTraits(.isHeader)
      Text("Your original entries stay intact while Echo shapes a readable narrative.")
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }
}

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
    EchoSurface(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .firstTextBaseline) {
          Text("Original entries")
            .font(EchoTypography.contentTitle)
          Spacer()
          Text(day.entryCount, format: .number)
            .font(EchoTypography.metadata)
            .foregroundStyle(.secondary)
            .accessibilityLabel(entryCountLabel)
        }
        .padding(.horizontal, EchoLayout.surfacePadding)
        .padding(.vertical, EchoLayout.contentSpacing)

        Divider()

        ForEach(day.entries) { entry in
          DayDetailEntry(
            entry: entry,
            highlightViewModel: highlightViewModel,
            isFocusedSource: entry.id == focusedEntryID,
            isReflectionSource: organizationViewModel.journal?.sourceEntryIDs.contains(entry.id) == true
          )
          .id(entry.id)
          if entry.id != day.entries.last?.id {
            Divider()
              .padding(.leading, EchoLayout.surfacePadding + 38)
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

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text(
        date.formatted(
          .dateTime.weekday(.wide).month(.wide).day().year()
        ).uppercased()
      )
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.5)
        .foregroundStyle(.secondary)

      Text("Day Reflection")
        .font(EchoTypography.editorialDisplay)
        .accessibilityAddTraits(.isHeader)

      Text(entryCountLabel)
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
  }
}

private struct DayReflectionSection: View {
  let viewModel: DayOrganizationViewModel

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    EchoSurface(
      style: .accent(opacity: EchoMaterialMetrics.organizedJournalFillOpacity)
    ) {
      VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
        reflectionContent

        if !viewModel.isLoading {
          reflectionAction
        }

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
        .font(EchoTypography.editorialNarrative)
        .lineSpacing(6)
        .textSelection(.enabled)

      Divider()

      VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
        Label("Created privately on this device", systemImage: "lock.shield")
        Text(
          "\(journal.sourceEntryIDs.count) original \(journal.sourceEntryIDs.count == 1 ? "entry" : "entries") · Updated \(journal.modifiedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
        )
      }
      .font(EchoTypography.metadata)
      .foregroundStyle(.secondary)
    } else {
      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
        Image(systemName: "sparkles.rectangle.stack")
          .font(.title2.weight(.semibold))
          .foregroundStyle(world.accent)
        Text("Bring the day into focus")
          .font(EchoTypography.sectionTitle)
        Text("Echo can shape these entries into a readable reflection while keeping every original word unchanged.")
          .font(EchoTypography.supporting)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var reflectionAction: some View {
    Button {
      Task { await viewModel.generate() }
    } label: {
      HStack {
        Spacer()
        Label(
          viewModel.journal == nil ? "Organize Day" : "Regenerate Reflection",
          systemImage: viewModel.journal == nil ? "square.stack.3d.up" : "arrow.clockwise"
        )
        .font(.body.weight(.semibold))
        Spacer()
      }
      .frame(minHeight: 28)
      .padding(.vertical, EchoLayout.tightSpacing)
      .foregroundStyle(world.canvas)
      .background(world.accent, in: RoundedRectangle(cornerRadius: EchoShape.embeddedRadius))
      .contentShape(RoundedRectangle(cornerRadius: EchoShape.embeddedRadius))
    }
    .buttonStyle(.plain)
    .disabled(viewModel.isGenerating)
  }
}

private struct DayDetailEntry: View {
  @Environment(\.echoVisualWorld) private var world

  let entry: EchoEntry
  let highlightViewModel: EntryHighlightViewModel
  let isFocusedSource: Bool
  let isReflectionSource: Bool

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.rowSpacing) {
      Image(systemName: isReflectionSource ? "text.page.fill" : "text.page")
        .font(.body.weight(.medium))
        .foregroundStyle(isReflectionSource ? world.accent : world.secondaryText)
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
        HStack(alignment: .firstTextBaseline) {
          Text(entry.createdAt, format: .dateTime.hour().minute())
            .font(EchoTypography.metadata)
            .foregroundStyle(.secondary)
          if isReflectionSource {
            Text("USED IN REFLECTION")
              .font(EchoTypography.editorialEyebrow)
              .foregroundStyle(world.accent)
          }
        }

        Text(entry.rawText)
          .font(EchoTypography.body)
          .lineSpacing(4)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .font(.body)
    }
    .padding(EchoLayout.surfacePadding)
    .background(
      isFocusedSource
        ? world.selectedFill
        : Color.clear,
      in: RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
    )
    .overlay {
      if isFocusedSource {
        RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
          .stroke(
            world.accent.opacity(EchoMaterialMetrics.focusedSourceBorderOpacity),
            lineWidth: EchoShape.emphasizedBorderWidth
          )
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityValue(accessibilityValue)
  }

  private var accessibilityValue: String {
    [
      isReflectionSource ? "Used in reflection" : nil,
      isFocusedSource ? "Focused source entry" : nil,
    ]
    .compactMap { $0 }
    .joined(separator: ", ")
  }
}
