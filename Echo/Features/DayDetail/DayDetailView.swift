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
                  description:
                    "Write an entry first, then Echo can organize the day without changing your original words.",
                  minHeight: EchoLayout.mediumStateHeight
                )
              }
            }
          }
        }
      }
    }
    .safeAreaInset(edge: .top, spacing: 0) {
#if os(iOS)
      compactReflectionModePicker
#else
      reflectionModePicker
#endif
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

  private var compactReflectionModePicker: some View {
    HStack(spacing: 18) {
      ForEach(ReflectionMode.allCases) { mode in
        Button {
          reflectionMode = mode
        } label: {
          VStack(spacing: 4) {
            Text(mode == .daily ? "Daily" : "Weekly")
              .font(.caption.weight(reflectionMode == mode ? .bold : .semibold))
              .foregroundStyle(
                reflectionMode == mode ? world.primaryText : world.secondaryText
              )

            Capsule()
              .fill(reflectionMode == mode ? world.accent : Color.clear)
              .frame(height: 2)
          }
        }
        .buttonStyle(.plain)
      }

      Spacer()

      Text(reflectionMode == .daily ? "DAY READER" : "WEEKLY ECHO")
        .font(.system(size: 9, weight: .bold))
        .tracking(1.4)
        .foregroundStyle(world.secondaryText)
    }
    .padding(.horizontal, 18)
    .padding(.top, 5)
    .padding(.bottom, 4)
    .background(world.canvas.opacity(0.95))
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(world.separator.opacity(0.5))
        .frame(height: EchoShape.hairlineWidth)
    }
    .dynamicTypeSize(...DynamicTypeSize.large)
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
        .font(world.displayFont(size: 38, weight: .medium))
        .accessibilityAddTraits(.isHeader)
      Text("Your original entries stay intact while Echo shapes a readable narrative.")
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
    EchoWorldCanvas(screen: .reflection) {
      GeometryReader { geometry in
        ScrollView {
          let isWide = geometry.size.width >= EchoLayout.wideLayoutBreakpoint

          VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
            weekHeader

            if isWide {
              HStack(alignment: .top, spacing: 42) {
                reflectionPanel(isWide: true)
                  .frame(maxWidth: 680, alignment: .topLeading)

                VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
                  sourceDays
                }
                .frame(maxWidth: 420, alignment: .topLeading)
              }
            } else {
              reflectionPanel(isWide: false)
              sourceDays
            }
          }
          .frame(
            maxWidth: isWide ? EchoLayout.wideContentMaxWidth : EchoLayout.contentMaxWidth,
            alignment: .leading
          )
          .padding(.horizontal, isWide ? 40 : EchoLayout.pageHorizontalPadding)
          .padding(.vertical, isWide ? 36 : EchoLayout.pageVerticalPadding)
          .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
          reflectionDock { actionBar }
        }
      }
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
  private func reflectionPanel(isWide: Bool) -> some View {
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
            .font(
              isWide ? EchoTypography.editorialNarrative : EchoTypography.compactEditorialNarrative
            )
            .lineSpacing(isWide ? 6 : 4)
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
            CarryForwardCandidate(text: question) {
              await carryForwardViewModel.carryToTomorrow(
                text: question,
                sourceKind: .weeklyReflectionQuestion
              )
            }
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
          Text(
            "Weekly Echo can organize these entries locally while every original stays unchanged."
          )
          .font(EchoTypography.supporting)
          .foregroundStyle(.secondary)
        }
      }

      if viewModel.failure != nil {
        EchoErrorState(message: "This weekly reflection could not be loaded or saved.")
      }
      if carryForwardViewModel.actionState == .failed {
        EchoErrorState(message: "That thought could not be carried forward.")
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
        Button {
          selectedDay = day
        } label: {
          HStack(spacing: EchoLayout.rowSpacing) {
            VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
              Text(
                day.id.date(in: timeZone) ?? day.entries[0].createdAt,
                format: .dateTime.weekday(.wide).month(.abbreviated).day()
              )
              .font(EchoTypography.body.weight(.semibold))
              Text(day.entries.first?.preferredText ?? "")
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

  private func reflectionDock<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View {
    content()
      .frame(maxWidth: 520)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, EchoLayout.pageHorizontalPadding)
      .padding(.vertical, EchoLayout.tightSpacing)
      .background(.ultraThinMaterial)
      .overlay(alignment: .top) {
        Rectangle()
          .fill(world.separator)
          .frame(height: EchoShape.hairlineWidth)
      }
  }

  private func weekButton(systemImage: String, offset: Int, disabled: Bool) -> some View {
    Button {
      Task { await viewModel.moveWeek(by: offset) }
    } label: {
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
    return
      "\(start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
  }

  @Environment(CarryForwardViewModel.self) private var carryForwardViewModel
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
    EchoWorldCanvas(screen: .reflection) {
      GeometryReader { geometry in
        ScrollViewReader { proxy in
          ScrollView {
            if geometry.size.width >= EchoLayout.wideLayoutBreakpoint {
              HStack(alignment: .top, spacing: 42) {
                VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
                  dayHeader
                  DayReflectionSection(
                    viewModel: organizationViewModel,
                    sourceDay: day.id,
                    isCompact: false
                  )
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
#if os(iOS)
              compactReflectionReader
#else
              LazyVStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
                dayHeader
                DayReflectionSection(
                  viewModel: organizationViewModel,
                  sourceDay: day.id,
                  isCompact: true
                )
                entries
              }
              .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
              .padding(.horizontal, EchoLayout.pageHorizontalPadding)
              .padding(.vertical, EchoLayout.pageVerticalPadding)
              .frame(maxWidth: .infinity)
#endif
            }
          }
          .scrollIndicators(.hidden)
          .safeAreaInset(edge: .bottom, spacing: 0) {
            reflectionActionDock
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
    }
  }

  private var dayHeader: some View {
    DayDateHeader(
      date: displayDate,
      entryCountLabel: entryCountLabel
    )
  }

  private var compactReflectionReader: some View {
    CompactDayReflectionReader(
      day: day,
      displayDate: displayDate,
      focusedEntryID: focusedEntryID,
      viewModel: organizationViewModel,
      highlightViewModel: highlightViewModel
    )
    .frame(maxWidth: EchoLayout.contentMaxWidth)
    .frame(maxWidth: .infinity)
  }

  private var reflectionActionDock: some View {
    ReflectionActionBar(viewModel: organizationViewModel)
      .frame(maxWidth: 610)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, EchoLayout.pageHorizontalPadding)
      .padding(.top, EchoLayout.microSpacing)
      .padding(.bottom, EchoLayout.tightSpacing)
      .background {
#if os(iOS)
        world.editorialPaper
#else
        Rectangle().fill(.ultraThinMaterial)
#endif
      }
      .overlay(alignment: .top) {
        Rectangle()
          .fill(world.separator)
          .frame(height: EchoShape.hairlineWidth)
      }
  }

  private var entries: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        Text("Source entries")
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
          isReflectionSource: organizationViewModel.journal?.sourceEntryIDs.contains(entry.id)
            == true,
          onCarryForward: {
            await carryForwardViewModel.carryToTomorrow(
              text: entry.preferredText,
              sourceKind: .entry,
              sourceDay: day.id,
              sourceEntryID: entry.id
            )
          }
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
  @Environment(CarryForwardViewModel.self) private var carryForwardViewModel

  private var displayDate: Date {
    day.id.date(in: timeZone) ?? day.entries[0].createdAt
  }

  private var entryCountLabel: String {
    day.entryCount == 1 ? "1 entry" : "\(day.entryCount) entries"
  }
}

private struct CompactDayReflectionReader: View {
  let day: EchoDay
  let displayDate: Date
  let focusedEntryID: UUID?
  let viewModel: DayOrganizationViewModel
  let highlightViewModel: EntryHighlightViewModel

  @Environment(\.echoVisualWorld) private var world
  @Environment(CarryForwardViewModel.self) private var carryForwardViewModel

  var body: some View {
    LazyVStack(alignment: .leading, spacing: 0) {
      masthead
      editorialPage
    }
  }

  private var masthead: some View {
    VStack(alignment: .leading, spacing: 6) {
      Spacer(minLength: 22)

      Text(displayDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year()))
        .font(.caption.weight(.bold))
        .textCase(.uppercase)
        .tracking(1.25)

      HStack(alignment: .lastTextBaseline) {
        Text("Reflection")
          .font(world.displayFont(size: 24, weight: .bold))
          .accessibilityAddTraits(.isHeader)
        Spacer()
        Text(day.entryCount == 1 ? "1 source" : "\(day.entryCount) sources")
          .font(.caption.weight(.semibold))
      }
    }
    .foregroundStyle(world.primaryText)
    .shadow(color: world.contentShadow, radius: 9, y: 3)
    .padding(.horizontal, 18)
    .padding(.bottom, 14)
    .frame(maxWidth: .infinity, minHeight: 92, alignment: .bottomLeading)
    .background { EchoArtworkTitleScrim() }
  }

  private var editorialPage: some View {
    VStack(alignment: .leading, spacing: 16) {
      if viewModel.isLoading {
        EchoLoadingState(title: "Loading organized journal…", minHeight: 220)
      } else if viewModel.isGenerating {
        EchoLoadingState(title: "Organizing this day…", minHeight: 220)
      } else if let journal = viewModel.journal {
        journalContent(journal)
      } else {
        emptyJournal
      }

      if viewModel.failure != nil {
        EchoErrorState(message: "The organized journal could not be loaded or saved.")
      }
      if carryForwardViewModel.actionState == .failed {
        EchoErrorState(message: "That thought could not be carried forward.")
      }
    }
    .foregroundStyle(world.editorialInk)
    .padding(.horizontal, 18)
    .padding(.top, 20)
    .padding(.bottom, 30)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(world.editorialPaper)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(world.editorialAccent)
        .frame(height: 3)
    }
  }

  @ViewBuilder
  private func journalContent(_ journal: EchoOrganizedJournal) -> some View {
    Text(journal.title ?? "A Day in Perspective")
      .font(world.displayFont(size: 39, weight: .bold))
      .tracking(-0.8)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityAddTraits(.isHeader)

    HStack(spacing: 5) {
      Rectangle()
        .fill(world.editorialAccent)
        .frame(width: 42, height: 3)
      ForEach(0..<4, id: \.self) { _ in
        Circle()
          .fill(world.editorialAccent.opacity(0.5))
          .frame(width: 3, height: 3)
      }
    }
    .accessibilityHidden(true)

    Text("MY REFLECTION")
      .font(.caption.weight(.black))
      .tracking(1.35)
      .foregroundStyle(world.editorialAccent)

    Text(journal.body)
      .font(.system(size: 16, weight: .regular, design: .serif))
      .lineSpacing(4)
      .fixedSize(horizontal: false, vertical: true)
      .textSelection(.enabled)

    if !journal.themes.isEmpty {
      sectionHeading("Themes", count: nil)

      ScrollView(.horizontal) {
        HStack(spacing: 7) {
          ForEach(Array(journal.themes.enumerated()), id: \.element) { index, theme in
            Label(theme, systemImage: themeIcon(at: index))
              .font(.caption.weight(.semibold))
              .foregroundStyle(index == 0 ? world.editorialPaper : world.editorialInk)
              .padding(.horizontal, 11)
              .padding(.vertical, 7)
              .background(
                index == 0
                  ? world.editorialAccent
                  : world.editorialInk.opacity(0.055),
                in: Capsule()
              )
              .overlay {
                Capsule()
                  .stroke(world.editorialInk.opacity(0.15), lineWidth: 0.75)
              }
          }
        }
      }
      .scrollIndicators(.hidden)
    }

    sectionHeading("Source Entries", count: day.entryCount)

    VStack(spacing: 0) {
      ForEach(Array(day.entries.enumerated()), id: \.element.id) { index, entry in
        CompactReflectionSourceRow(
          entry: entry,
          visualIndex: index,
          isFocused: entry.id == focusedEntryID,
          isReflectionSource: journal.sourceEntryIDs.contains(entry.id),
          highlightViewModel: highlightViewModel,
          onCarryForward: {
            await carryForwardViewModel.carryToTomorrow(
              text: entry.preferredText,
              sourceKind: .entry,
              sourceDay: day.id,
              sourceEntryID: entry.id
            )
          }
        )
        .id(entry.id)

        if entry.id != day.entries.last?.id {
          Divider().overlay(world.editorialInk.opacity(0.12))
        }
      }
    }
    .background(world.editorialInk.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(world.editorialInk.opacity(0.13), lineWidth: 0.75)
    }

    if !journal.keyMoments.isEmpty {
      sectionHeading("Worth Remembering", count: nil)
      VStack(alignment: .leading, spacing: 10) {
        ForEach(journal.keyMoments, id: \.self) { moment in
          CompactCarryForwardRow(text: moment) {
            await carryForwardViewModel.carryToTomorrow(
              text: moment,
              sourceKind: .dayReflectionKeyMoment,
              sourceDay: day.id
            )
          }
        }
      }
    }

    if !journal.reflectionQuestions.isEmpty {
      sectionHeading("Carry Into Tomorrow", count: nil)
      ForEach(journal.reflectionQuestions, id: \.self) { question in
        CompactCarryForwardRow(text: question, emphasized: true) {
          await carryForwardViewModel.carryToTomorrow(
            text: question,
            sourceKind: .dayReflectionQuestion,
            sourceDay: day.id
          )
        }
      }
    }

    Label(
      "Created privately from \(journal.sourceEntryIDs.count) original \(journal.sourceEntryIDs.count == 1 ? "entry" : "entries")",
      systemImage: "lock.shield.fill"
    )
    .font(.caption2.weight(.medium))
    .foregroundStyle(world.editorialMuted)
  }

  private var emptyJournal: some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: "sparkles.rectangle.stack")
        .font(.title2.weight(.bold))
        .foregroundStyle(world.editorialAccent)
      Text("Bring the day into focus")
        .font(world.displayFont(size: 32, weight: .bold))
      Text(
        "Echo can shape these entries into a readable reflection while keeping every original word unchanged."
      )
      .font(.system(size: 16, design: .serif))
      .foregroundStyle(world.editorialMuted)
    }
    .frame(minHeight: 220, alignment: .topLeading)
  }

  private func sectionHeading(_ title: String, count: Int?) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.headline.weight(.bold))
      Spacer()
      if let count {
        Text(count, format: .number)
          .font(.caption.weight(.bold))
          .foregroundStyle(world.editorialMuted)
      }
    }
  }

  private func themeIcon(at index: Int) -> String {
    ["crown.fill", "hourglass", "chart.bar.fill", "sparkles"][index % 4]
  }
}

private struct CompactReflectionSourceRow: View {
  let entry: EchoEntry
  let visualIndex: Int
  let isFocused: Bool
  let isReflectionSource: Bool
  let highlightViewModel: EntryHighlightViewModel
  let onCarryForward: () async -> Bool

  @State private var didCarry = false
  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(spacing: 10) {
      ZStack {
        LinearGradient(
          colors: thumbnailColors,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        Image(systemName: entry.type == .voice ? "waveform" : "text.quote")
          .font(.caption.weight(.bold))
          .foregroundStyle(world.editorialPaper)
      }
      .frame(width: 43, height: 38)
      .clipShape(RoundedRectangle(cornerRadius: 7))
      .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 3) {
        Text(entry.preferredText)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(world.editorialInk)
          .lineLimit(1)
        Text(entry.createdAt, format: .dateTime.hour().minute())
          .font(.caption2.weight(.medium))
          .foregroundStyle(world.editorialMuted)
      }

      Spacer(minLength: 4)

      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .foregroundStyle(world.editorialAccent)

      Menu {
        Button(didCarry ? "Set for tomorrow" : "Carry to tomorrow", systemImage: "arrow.turn.down.right") {
          Task { didCarry = await onCarryForward() }
        }
      } label: {
        Image(systemName: didCarry ? "checkmark" : "ellipsis")
          .font(.subheadline.weight(.bold))
          .frame(width: 25, height: 34)
          .foregroundStyle(world.editorialInk)
      }
    }
    .padding(.horizontal, 9)
    .padding(.vertical, 7)
    .background(isFocused ? world.editorialAccent.opacity(0.12) : Color.clear)
    .accessibilityElement(children: .contain)
    .accessibilityValue(isReflectionSource ? "Used in reflection" : "")
  }

  private var thumbnailColors: [Color] {
    let base = world.editorialAccent
    return visualIndex.isMultiple(of: 2)
      ? [base.opacity(0.95), world.editorialInk]
      : [world.editorialInk.opacity(0.9), base.opacity(0.72)]
  }
}

private struct CompactCarryForwardRow: View {
  let text: String
  var emphasized = false
  let action: () async -> Bool

  @State private var didCarry = false
  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      Image(systemName: emphasized ? "arrow.up.right" : "diamond.fill")
        .font(.caption2.weight(.bold))
        .foregroundStyle(world.editorialAccent)

      Text(text)
        .font(emphasized ? .subheadline.weight(.semibold) : .subheadline)
        .foregroundStyle(world.editorialInk)
        .frame(maxWidth: .infinity, alignment: .leading)

      Button {
        Task { didCarry = await action() }
      } label: {
        Image(systemName: didCarry ? "checkmark" : "arrow.turn.down.right")
          .font(.subheadline.weight(.semibold))
      }
      .buttonStyle(.plain)
      .foregroundStyle(world.editorialAccent)
      .accessibilityLabel(didCarry ? "Set for tomorrow" : "Carry to tomorrow")
    }
    .padding(12)
    .background(
      emphasized ? world.editorialAccent.opacity(0.1) : world.editorialInk.opacity(0.035),
      in: RoundedRectangle(cornerRadius: 10)
    )
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
      .foregroundStyle(world.accent)

      Text("Day Reflection")
        .font(EchoTypography.editorialDisplay)
        .accessibilityAddTraits(.isHeader)

      Text(entryCountLabel)
        .font(EchoTypography.supporting)
        .foregroundStyle(world.primaryText.opacity(0.82))
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }
}

private struct DayReflectionSection: View {
  let viewModel: DayOrganizationViewModel
  let sourceDay: EchoDayIdentifier
  let isCompact: Bool

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    EchoReadabilityPanel {
      VStack(
        alignment: .leading,
        spacing: isCompact ? EchoLayout.contentSpacing : EchoLayout.sectionSpacing
      ) {
        reflectionContent

        if viewModel.failure != nil {
          EchoErrorState(message: "The organized journal could not be loaded or saved.")
        }
        if carryForwardViewModel.actionState == .failed {
          EchoErrorState(message: "That thought could not be carried forward.")
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
        .font(
          isCompact ? EchoTypography.compactEditorialNarrative : EchoTypography.editorialNarrative
        )
        .lineSpacing(isCompact ? 4 : 6)
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
            CarryForwardCandidate(text: moment, style: .plain) {
              await carryForwardViewModel.carryToTomorrow(
                text: moment,
                sourceKind: .dayReflectionKeyMoment,
                sourceDay: sourceDay
              )
            }
          }
        }
      }

      if !journal.reflectionQuestions.isEmpty {
        Divider()
        ReflectionSectionLabel(title: "Keep thinking", systemImage: "quote.bubble")
        ForEach(journal.reflectionQuestions, id: \.self) { question in
          CarryForwardCandidate(text: question) {
            await carryForwardViewModel.carryToTomorrow(
              text: question,
              sourceKind: .dayReflectionQuestion,
              sourceDay: sourceDay
            )
          }
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
        Text(
          "Echo can shape these entries into a readable reflection while keeping every original word unchanged."
        )
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
      }
    }
  }

  @Environment(CarryForwardViewModel.self) private var carryForwardViewModel

}

private struct CarryForwardCandidate: View {
  enum Style { case card, plain }

  let text: String
  var style: Style = .card
  let action: () async -> Bool

  @State private var didCarry = false
  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: EchoLayout.rowSpacing) {
      if style == .plain {
        Image(systemName: "diamond.fill")
          .font(.caption2)
          .foregroundStyle(world.accent)
          .accessibilityHidden(true)
      }
      Text(text)
        .font(style == .card ? EchoTypography.contentTitle : EchoTypography.supporting)
        .foregroundStyle(world.primaryText)
        .frame(maxWidth: .infinity, alignment: .leading)

      Button {
        Task { didCarry = await action() }
      } label: {
        Image(systemName: didCarry ? "checkmark" : "arrow.turn.down.right")
          .font(.subheadline.weight(.semibold))
          .frame(width: 30, height: 30)
      }
      .buttonStyle(.plain)
      .foregroundStyle(world.accent)
      .accessibilityLabel(didCarry ? "Set for tomorrow" : "Carry to tomorrow")
    }
    .padding(style == .card ? EchoLayout.contentSpacing : 0)
    .background(
      style == .card ? world.accent.opacity(0.14) : Color.clear,
      in: RoundedRectangle(cornerRadius: 12)
    )
    .animation(.easeOut(duration: 0.18), value: didCarry)
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
  let onCarryForward: () async -> Bool
  @State private var didCarry = false

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

        Text(entry.preferredText)
          .font(EchoTypography.body)
          .lineSpacing(4)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .font(.body)

      Button {
        Task { didCarry = await onCarryForward() }
      } label: {
        Image(systemName: didCarry ? "checkmark" : "arrow.turn.down.right")
      }
      .buttonStyle(.borderless)
      .font(.body)
      .foregroundStyle(world.accent)
      .accessibilityLabel(didCarry ? "Set for tomorrow" : "Carry entry to tomorrow")
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
    .accessibilityElement(children: .contain)
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
