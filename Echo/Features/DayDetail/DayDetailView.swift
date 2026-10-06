import SwiftUI

struct DayReflectionView: View {
  let todayViewModel: TodayViewModel
  let timelineViewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository
  let weeklyViewModel: WeeklyReflectionViewModel

  @State private var reflectionMode: ReflectionMode = .daily

  var body: some View {
    Group {
      if reflectionMode == .weekly {
        WeeklyReflectionView(
          viewModel: weeklyViewModel,
          highlightViewModel: highlightViewModel,
          aiService: aiService,
          journalRepository: journalRepository
        )
      } else {
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
      }
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      reflectionModePicker
    }
    .task {
      await todayViewModel.load()
      await timelineViewModel.load()
    }
  }

  private var reflectionModePicker: some View {
    HStack(spacing: EchoLayout.tightSpacing) {
      ForEach(ReflectionMode.allCases) { mode in
        Button {
          reflectionMode = mode
        } label: {
          Text(mode.title)
            .font(EchoTypography.metadata.weight(.semibold))
            .foregroundStyle(reflectionMode == mode ? world.canvas : world.primaryText)
            .padding(.horizontal, EchoLayout.contentSpacing)
            .padding(.vertical, EchoLayout.tightSpacing)
            .background(
              reflectionMode == mode ? world.accent : Color.clear,
              in: Capsule()
            )
        }
        .buttonStyle(.plain)
      }
      Spacer()
    }
    .padding(.horizontal, EchoLayout.pageHorizontalPadding)
    .padding(.vertical, EchoLayout.tightSpacing)
    .background(.ultraThinMaterial)
  }

  @Environment(\.echoVisualWorld) private var world

  private enum ReflectionMode: String, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }
    var title: String { self == .daily ? "Day Reflection" : "Weekly Echo" }
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

private struct WeeklyReflectionView: View {
  let viewModel: WeeklyReflectionViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedDay: EchoDay?
  @Environment(\.echoVisualWorld) private var world
  @Environment(\.timeZone) private var timeZone

  var body: some View {
    EchoWorldCanvas {
      ScrollView {
        VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
          weekHeader
          reflectionPanel
          sourceDays
          actionBar
        }
        .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
        .padding(.horizontal, EchoLayout.pageHorizontalPadding)
        .padding(.vertical, EchoLayout.pageVerticalPadding)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .task { await viewModel.load() }
    .sheet(item: $selectedDay) { day in
      DayDetailView(
        day: day,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        journalRepository: journalRepository
      )
      .echoPrivacyProtected()
    }
  }

  private var weekHeader: some View {
    HStack(alignment: .bottom, spacing: EchoLayout.contentSpacing) {
      VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
        Text("WEEKLY ECHO")
          .font(EchoTypography.editorialEyebrow)
          .tracking(1.5)
          .foregroundStyle(world.accent)
        Text(weekRangeLabel)
          .font(EchoTypography.editorialDisplay)
          .foregroundStyle(world.primaryText)
          .accessibilityAddTraits(.isHeader)
        Text("A wider view of what kept returning.")
          .font(EchoTypography.supporting)
          .foregroundStyle(world.primaryText.opacity(0.82))
      }
      Spacer()
      HStack(spacing: EchoLayout.tightSpacing) {
        weekButton(systemImage: "chevron.left", offset: -1, disabled: false)
        weekButton(systemImage: "chevron.right", offset: 1, disabled: !viewModel.canMoveForward)
      }
    }
  }

  @ViewBuilder
  private var reflectionPanel: some View {
    EchoReadabilityPanel {
      if viewModel.isLoading {
        EchoLoadingState(title: "Loading this week…", minHeight: 120)
      } else if viewModel.entries.isEmpty {
        EchoEmptyState(
          title: "A quiet week",
          systemImage: "calendar",
          description: "There are no entries to reflect on for this week.",
          minHeight: 120
        )
      } else if let reflection = viewModel.reflection {
        VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
          Text(reflection.body)
            .font(EchoTypography.editorialNarrative)
            .lineSpacing(6)
            .textSelection(.enabled)

          if !reflection.themes.isEmpty {
            Divider()
            ReflectionSectionLabel(title: "Recurring themes", systemImage: "repeat")
            ScrollView(.horizontal) {
              HStack(spacing: EchoLayout.tightSpacing) {
                ForEach(reflection.themes, id: \.self) { theme in
                  Text(theme)
                    .font(EchoTypography.metadata.weight(.semibold))
                    .foregroundStyle(world.canvas)
                    .padding(.horizontal, EchoLayout.rowSpacing)
                    .padding(.vertical, EchoLayout.inlineSpacing)
                    .background(world.accent, in: Capsule())
                }
              }
            }
            .scrollIndicators(.hidden)
          }

          if let question = reflection.question {
            Divider()
            ReflectionSectionLabel(title: "For the week ahead", systemImage: "arrow.up.right")
            Text(question)
              .font(EchoTypography.contentTitle)
              .padding(EchoLayout.contentSpacing)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(world.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
          }

          Divider()
          Label(
            "Built privately from \(reflection.sourceEntryIDs.count) original \(reflection.sourceEntryIDs.count == 1 ? "entry" : "entries")",
            systemImage: "lock.shield.fill"
          )
          .font(EchoTypography.metadata)
          .foregroundStyle(.secondary)
        }
      } else {
        VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
          Image(systemName: "calendar.badge.sparkles")
            .font(.title2.weight(.semibold))
            .foregroundStyle(world.accent)
          Text("Find the shape of the week")
            .font(EchoTypography.sectionTitle)
          Text("Weekly Echo can organize these entries locally while every original stays unchanged.")
            .font(EchoTypography.supporting)
            .foregroundStyle(.secondary)
        }
      }

      if viewModel.failure != nil {
        EchoErrorState(message: "This weekly reflection could not be loaded or saved.")
      }
    }
  }

  private var sourceDays: some View {
    VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
      HStack {
        Text("Source days")
          .font(EchoTypography.contentTitle)
        Spacer()
        Text(viewModel.entries.count, format: .number)
          .font(EchoTypography.metadata)
          .foregroundStyle(.secondary)
      }

      ForEach(viewModel.sourceDays) { day in
        Button { selectedDay = day } label: {
          HStack(spacing: EchoLayout.rowSpacing) {
            VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
              Text(day.id.date(in: timeZone) ?? day.entries[0].createdAt, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(EchoTypography.body.weight(.semibold))
              Text(day.entries.first?.rawText ?? "")
                .font(EchoTypography.supporting)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundStyle(world.accent)
          }
          .padding(EchoLayout.contentSpacing)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
          .overlay {
            RoundedRectangle(cornerRadius: 12)
              .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
          }
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var actionBar: some View {
    Button {
      Task { await viewModel.generate() }
    } label: {
      Label(
        viewModel.reflection == nil ? "Create Weekly Echo" : "Regenerate Weekly Echo",
        systemImage: viewModel.reflection == nil ? "sparkles" : "arrow.clockwise"
      )
      .font(.body.weight(.semibold))
      .frame(maxWidth: .infinity, minHeight: 48)
      .foregroundStyle(world.canvas)
      .background(world.accent, in: RoundedRectangle(cornerRadius: EchoShape.embeddedRadius))
    }
    .buttonStyle(.plain)
    .disabled(viewModel.entries.isEmpty || viewModel.isGenerating)
    .opacity(viewModel.entries.isEmpty ? 0.48 : 1)
  }

  private func weekButton(systemImage: String, offset: Int, disabled: Bool) -> some View {
    Button { Task { await viewModel.moveWeek(by: offset) } } label: {
      Image(systemName: systemImage)
        .frame(width: 38, height: 38)
        .background(.ultraThinMaterial, in: Circle())
        .overlay { Circle().stroke(world.separator, lineWidth: EchoShape.hairlineWidth) }
    }
    .buttonStyle(.plain)
    .disabled(disabled || viewModel.isLoading)
    .opacity(disabled ? 0.4 : 1)
  }

  private var weekRangeLabel: String {
    guard let start = viewModel.selectedWeek.startDate(in: timeZone) else { return "This Week" }
    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = timeZone
    let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
    return "\(start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
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
    EchoWorldCanvas {
      GeometryReader { geometry in
        ScrollViewReader { proxy in
          ScrollView {
            if geometry.size.width >= EchoLayout.wideLayoutBreakpoint {
              HStack(alignment: .top, spacing: 42) {
                VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
                  dayHeader
                  DayReflectionSection(viewModel: organizationViewModel)
                  ReflectionActionBar(viewModel: organizationViewModel)
                }
                .frame(maxWidth: 610, alignment: .leading)

                entries
                  .frame(maxWidth: 440, alignment: .topLeading)
              }
              .frame(maxWidth: EchoLayout.wideContentMaxWidth, alignment: .topLeading)
              .padding(.horizontal, 40)
              .padding(.vertical, 44)
              .frame(maxWidth: .infinity, alignment: .top)
            } else {
              LazyVStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
                dayHeader
                DayReflectionSection(viewModel: organizationViewModel)
                entries
                ReflectionActionBar(viewModel: organizationViewModel)
              }
              .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
              .padding(.horizontal, EchoLayout.pageHorizontalPadding)
              .padding(.vertical, EchoLayout.pageVerticalPadding)
              .frame(maxWidth: .infinity)
            }
          }
          .scrollIndicators(.hidden)
          .task {
            await highlightViewModel.load()
            await organizationViewModel.load()
            if let focusedEntryID {
              proxy.scrollTo(focusedEntryID, anchor: .center)
            }
          }
        }
      }
    }
  }

  private var dayHeader: some View {
    DayDateHeader(
      date: displayDate,
      entryCountLabel: entryCountLabel
    )
  }

  private var entries: some View {
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
      .padding(.horizontal, EchoLayout.contentSpacing)
      .padding(.vertical, EchoLayout.rowSpacing)

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
    .background {
      RoundedRectangle(cornerRadius: 14)
        .fill(.ultraThinMaterial)
      RoundedRectangle(cornerRadius: 14)
        .fill(world.canvas.opacity(0.08))
    }
    .overlay {
      RoundedRectangle(cornerRadius: 14)
        .stroke(world.separator.opacity(0.7), lineWidth: EchoShape.hairlineWidth)
    }
  }

  @Environment(\.echoVisualWorld) private var world

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
    EchoReadabilityPanel {
      VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
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
      if let title = journal.title {
        Text(title)
          .font(EchoTypography.editorialDisplay)
          .foregroundStyle(world.primaryText)
          .accessibilityAddTraits(.isHeader)
      }

      Text(journal.body)
        .font(EchoTypography.editorialNarrative)
        .lineSpacing(6)
        .textSelection(.enabled)

      if !journal.themes.isEmpty {
        ReflectionSectionLabel(title: "Themes", systemImage: "circle.hexagongrid")
        ScrollView(.horizontal) {
          HStack(spacing: EchoLayout.tightSpacing) {
            ForEach(journal.themes, id: \.self) { theme in
              Text(theme)
                .font(EchoTypography.metadata.weight(.semibold))
                .foregroundStyle(world.canvas)
                .padding(.horizontal, EchoLayout.rowSpacing)
                .padding(.vertical, EchoLayout.inlineSpacing)
                .background(world.accent, in: Capsule())
            }
          }
        }
        .scrollIndicators(.hidden)
      }

      if !journal.keyMoments.isEmpty {
        Divider()
        ReflectionSectionLabel(title: "Key moments", systemImage: "sparkles")
        VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
          ForEach(journal.keyMoments, id: \.self) { moment in
            Label(moment, systemImage: "diamond.fill")
              .font(EchoTypography.supporting)
              .symbolRenderingMode(.monochrome)
          }
        }
      }

      if !journal.reflectionQuestions.isEmpty {
        Divider()
        ReflectionSectionLabel(title: "Keep thinking", systemImage: "quote.bubble")
        ForEach(journal.reflectionQuestions, id: \.self) { question in
          Text(question)
            .font(EchoTypography.contentTitle)
            .foregroundStyle(world.primaryText)
            .padding(EchoLayout.contentSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(world.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
        }
      }

      Divider()
      VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
        Label("Created privately on this device", systemImage: "lock.shield.fill")
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

}

private struct ReflectionSectionLabel: View {
  let title: String
  let systemImage: String

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    Label(title, systemImage: systemImage)
      .font(EchoTypography.contentTitle)
      .foregroundStyle(world.primaryText)
  }
}

private struct ReflectionActionBar: View {
  let viewModel: DayOrganizationViewModel

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(spacing: EchoLayout.rowSpacing) {
      actionButton(
        title: "Organize",
        systemImage: "square.stack.3d.up",
        isPrimary: viewModel.journal == nil,
        isDisabled: false
      )

      actionButton(
        title: "Regenerate",
        systemImage: "arrow.clockwise",
        isPrimary: viewModel.journal != nil,
        isDisabled: viewModel.journal == nil
      )
    }
    .padding(.top, EchoLayout.tightSpacing)
  }

  private func actionButton(
    title: String,
    systemImage: String,
    isPrimary: Bool,
    isDisabled: Bool
  ) -> some View {
    Button {
      Task { await viewModel.generate() }
    } label: {
      Label(title, systemImage: systemImage)
        .font(.body.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 46)
        .foregroundStyle(isPrimary ? world.canvas : world.primaryText)
        .background {
          RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
            .fill(isPrimary ? world.accent : world.canvas.opacity(0.16))
          if !isPrimary {
            RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
              .fill(.ultraThinMaterial)
          }
        }
        .overlay {
          RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
            .stroke(
              isPrimary ? world.accent : world.separator,
              lineWidth: EchoShape.hairlineWidth
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: EchoShape.embeddedRadius))
    }
    .buttonStyle(.plain)
    .disabled(viewModel.isGenerating || isDisabled)
    .opacity(isDisabled ? 0.48 : 1)
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
