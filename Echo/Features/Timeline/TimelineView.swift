import SwiftUI

struct TimelineView: View {
  let viewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedDayID: EchoDayIdentifier?
  @State private var searchQuery = ""
  @State private var isShowingCalendar = false
  @FocusState private var isSearchFocused: Bool

  @Environment(\.timeZone) private var timeZone
  @Environment(\.calendar) private var calendar
  @Environment(\.echoVisualWorld) private var world
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    EchoWorldCanvas {
      GeometryReader { proxy in
        ScrollView {
          let isWide = proxy.size.width >= EchoLayout.wideLayoutBreakpoint

          Group {
            if isWide {
              HStack(alignment: .top, spacing: 48) {
                VStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
                  timelineHeader
                  searchControl
                }
                .frame(width: 300, alignment: .leading)

                LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
                  timelineContent(isWide: true)
                }
                .frame(maxWidth: 760, alignment: .leading)
              }
            } else {
              LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
                searchControl
                timelineContent(isWide: false)
              }
            }
          }
          .frame(
            maxWidth: isWide ? EchoLayout.wideContentMaxWidth : EchoLayout.contentMaxWidth,
            alignment: .leading
          )
          .padding(.horizontal, isWide ? 40 : EchoLayout.pageHorizontalPadding)
          .padding(.vertical, isWide ? 32 : EchoLayout.pageVerticalPadding)
          .frame(maxWidth: .infinity)
          .frame(minHeight: max(proxy.size.height, 0), alignment: .top)
        }
        .scrollIndicators(.hidden)
        .refreshable {
          await viewModel.load()
        }
      }
    }
    .task {
      await viewModel.load()
    }
    .sheet(isPresented: $isShowingCalendar) {
      TimelineCalendarBrowser(
        days: viewModel.days,
        selectedDayID: $selectedDayID,
        initialDate: stripAnchorDate
      )
      .echoPrivacyProtected()
    }
  }

  private var timelineHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text("YOUR HISTORY")
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.5)
        .foregroundStyle(world.accent)

      Text("Timeline")
        .font(EchoTypography.editorialDisplay)
        .foregroundStyle(world.primaryText)
        .accessibilityAddTraits(.isHeader)

      Text("Every day you have written, kept in one quiet place.")
        .font(EchoTypography.supporting)
        .foregroundStyle(world.primaryText.opacity(0.82))
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private func timelineContent(isWide: Bool) -> some View {
    if containsSearchQuery {
      searchContent
    } else if viewModel.isLoading && viewModel.days.isEmpty {
      EchoLoadingState(title: "Loading your timeline…")
    } else {
      recentDateStrip(isWide: isWide)

      if viewModel.days.isEmpty {
        EchoSurface {
          EchoEmptyState(
            title: "Your story starts here",
            systemImage: "clock.arrow.circlepath",
            description: "Days with journal entries will gather here over time.",
            minHeight: EchoLayout.compactStateHeight
          )
        }
      } else {
        timelineRail
      }

      if viewModel.failure != nil {
        EchoErrorState(
          message: "The timeline could not be refreshed. Showing the last loaded days."
        )
      }
    }
  }

  private var searchControl: some View {
    HStack(spacing: EchoLayout.rowSpacing) {
      Button {
        isSearchFocused = true
      } label: {
        Image(systemName: "magnifyingglass")
          .font(.body.weight(.semibold))
          .foregroundStyle(world.accent)
          .frame(width: 30, height: 30)
      }
      .buttonStyle(.plain)
      .keyboardShortcut("f", modifiers: [.command])
      .accessibilityLabel("Focus journal search")

      TextField("Search your writing", text: $searchQuery)
        .focused($isSearchFocused)
        .textFieldStyle(.plain)
        .submitLabel(.search)
        .onSubmit {
          Task { await viewModel.search(searchQuery) }
        }

      if viewModel.isSearching {
        ProgressView()
          .controlSize(.small)
          .accessibilityLabel("Searching")
      } else if containsSearchQuery {
        Button {
          searchQuery = ""
          Task { await viewModel.search("") }
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(world.secondaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear search")
      }
    }
    .padding(.horizontal, EchoLayout.contentSpacing)
    .frame(minHeight: 48)
    .background {
      Capsule().fill(.ultraThinMaterial)
      Capsule().fill(world.surfaceFill.opacity(0.58))
    }
    .overlay {
      Capsule().stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
    }
    .task(id: searchQuery) {
      guard containsSearchQuery else {
        await viewModel.search("")
        return
      }
      try? await Task.sleep(for: .milliseconds(250))
      guard !Task.isCancelled else { return }
      await viewModel.search(searchQuery)
    }
  }

  @ViewBuilder
  private var searchContent: some View {
    if viewModel.isSearching && viewModel.searchResults.isEmpty {
      EchoLoadingState(title: "Searching your writing…", minHeight: EchoLayout.compactStateHeight)
    } else if viewModel.searchFailed {
      EchoErrorState(message: "Search could not be completed. Your journal remains on this device.")
    } else if viewModel.searchResults.isEmpty {
      EchoSurface {
        EchoEmptyState(
          title: "No matching entries",
          systemImage: "text.magnifyingglass",
          description: "Try a different word or phrase. Search includes original and assisted writing.",
          minHeight: EchoLayout.compactStateHeight
        )
      }
    } else {
      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
        HStack {
          Text("SEARCH RESULTS")
            .font(EchoTypography.editorialEyebrow)
            .tracking(1.4)
            .foregroundStyle(world.secondaryText)
          Spacer()
          Text(viewModel.searchResults.count, format: .number)
            .font(EchoTypography.metadata)
            .foregroundStyle(.secondary)
        }

        EchoReadabilityPanel(padding: 0) {
          VStack(spacing: 0) {
            ForEach(viewModel.searchResults) { result in
              NavigationLink {
                destination(for: result.sourceDay, focusedEntryID: result.entry.id)
              } label: {
                searchResultRow(result)
              }
              .buttonStyle(.plain)
              .accessibilityHint("Opens the complete source day")

              if result.id != viewModel.searchResults.last?.id {
                Divider()
                  .overlay(world.separator.opacity(0.7))
              }
            }
          }
        }
      }
    }
  }

  private func searchResultRow(_ result: TimelineSearchResult) -> some View {
    HStack(alignment: .top, spacing: EchoLayout.contentSpacing) {
      VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
        Text(
          result.entry.createdAt.formatted(
            .dateTime.weekday(.abbreviated).month(.abbreviated).day().year().hour().minute()
          ).uppercased()
        )
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.1)
        .foregroundStyle(world.secondaryText)

        Text(result.entry.preferredText)
          .font(EchoTypography.body)
          .lineSpacing(4)
          .lineLimit(4)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Image(systemName: "chevron.right")
        .font(.caption.weight(.bold))
        .foregroundStyle(world.accent)
        .padding(.top, EchoLayout.inlineSpacing)
    }
    .padding(EchoLayout.surfacePadding)
    .contentShape(Rectangle())
  }

  private var containsSearchQuery: Bool {
    searchQuery.contains(where: { !$0.isWhitespace })
  }

  private func recentDateStrip(isWide: Bool) -> some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      HStack {
        Text(stripDateRangeLabel)
          .tracking(1.6)

        Spacer()

        Button {
          isShowingCalendar = true
        } label: {
          Label("Browse month", systemImage: "calendar")
            .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open calendar browser")
      }
      .font(EchoTypography.metadata)
      .foregroundStyle(world.secondaryText)
      .padding(.horizontal, isWide ? 22 : 14)
      .padding(.top, isWide ? 18 : 12)

      Group {
        if dynamicTypeSize.isAccessibilitySize {
          ScrollView(.horizontal) {
            dateTiles(isWide: isWide, usesFixedWidth: true)
          }
          .scrollIndicators(.hidden)
        } else {
          dateTiles(isWide: isWide, usesFixedWidth: false)
        }
      }
      .padding(.bottom, isWide ? 16 : 10)
    }
    .background {
      Rectangle()
        .fill(.ultraThinMaterial)
      Rectangle()
        .fill(world.canvas.opacity(0.06))
    }
    .overlay {
      VStack(spacing: 0) {
        Rectangle()
          .fill(world.separator.opacity(0.7))
          .frame(height: EchoShape.hairlineWidth)
        Spacer()
        Rectangle()
          .fill(world.separator.opacity(0.7))
          .frame(height: EchoShape.hairlineWidth)
      }
    }
  }

  private func dateTiles(isWide: Bool, usesFixedWidth: Bool) -> some View {
    HStack(spacing: 0) {
      ForEach(Array(dateStripDates.enumerated()), id: \.element) { index, date in
        if index > 0 {
          Rectangle()
            .fill(world.separator.opacity(0.72))
            .frame(width: EchoShape.hairlineWidth, height: isWide ? 52 : 44)
            .accessibilityHidden(true)
        }

        if let day = day(for: date) {
          Button {
            selectedDayID = day.id
          } label: {
            TimelineDateTile(
              date: date,
              isSelected: day.id == selectedTimelineDay?.id,
              hasEntries: true,
              isWide: isWide,
              usesFixedWidth: usesFixedWidth
            )
          }
          .buttonStyle(.plain)
          .accessibilityHint("Shows this day’s entries in the timeline")
        } else {
          TimelineDateTile(
            date: date,
            isSelected: false,
            hasEntries: false,
            isWide: isWide,
            usesFixedWidth: usesFixedWidth
          )
        }
      }
    }
    .padding(.horizontal, isWide ? 8 : 2)
  }

  private var timelineRail: some View {
    EchoReadabilityPanel(padding: EchoLayout.contentSpacing) {
      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
        HStack {
          Text(selectedTimelineDay.map(displayDate(for:)) ?? stripAnchorDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
            .font(EchoTypography.metadata)
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(world.secondaryText)

          Spacer()

          Text(selectedTimelineDay?.entryCount ?? 0, format: .number)
            .font(EchoTypography.metadata)
            .foregroundStyle(.secondary)
            .accessibilityLabel(
              "\(selectedTimelineDay?.entryCount ?? 0) \((selectedTimelineDay?.entryCount ?? 0) == 1 ? "entry" : "entries")"
            )
        }
        .padding(.horizontal, EchoLayout.tightSpacing)

        if let selectedTimelineDay {
          let entries = Array(selectedTimelineDay.entries.reversed())

          ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
            NavigationLink {
              destination(for: selectedTimelineDay, focusedEntryID: entry.id)
            } label: {
              TimelineEntryRailRow(
                entry: entry,
                showsContinuation: index < entries.count - 1
              )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens this entry in its day reflection")
          }
        }
      }
    }
  }

  private var stripAnchorDate: Date {
    selectedTimelineDay.map(displayDate(for:))
      ?? viewModel.days.first.map(displayDate(for:))
      ?? viewModel.mostRecentTimelineDate
  }

  private var selectedTimelineDay: EchoDay? {
    guard let selectedDayID else { return viewModel.days.first }
    return viewModel.days.first(where: { $0.id == selectedDayID }) ?? viewModel.days.first
  }

  private var dateStripDates: [Date] {
    (-6...0).compactMap { offset in
      calendar.date(byAdding: .day, value: offset, to: stripAnchorDate)
    }
  }

  private var stripDateRangeLabel: String {
    guard let first = dateStripDates.first, let last = dateStripDates.last else {
      return stripAnchorDate.formatted(.dateTime.month(.abbreviated).year()).uppercased()
    }

    let firstMonth = calendar.component(.month, from: first)
    let firstYear = calendar.component(.year, from: first)
    let lastMonth = calendar.component(.month, from: last)
    let lastYear = calendar.component(.year, from: last)

    if firstMonth == lastMonth && firstYear == lastYear {
      return last.formatted(.dateTime.month(.abbreviated).year()).uppercased()
    }

    let firstLabel = first.formatted(.dateTime.month(.abbreviated).year()).uppercased()
    let lastLabel = last.formatted(.dateTime.month(.abbreviated).year()).uppercased()
    return "\(firstLabel)  —  \(lastLabel)"
  }

  private func day(for date: Date) -> EchoDay? {
    let identifier = EchoDayIdentifier(containing: date, calendar: calendar)
    return viewModel.days.first(where: { $0.id == identifier })
  }

  private func displayDate(for day: EchoDay) -> Date {
    day.id.date(in: timeZone) ?? day.entries[0].createdAt
  }

  private func destination(for day: EchoDay, focusedEntryID: UUID? = nil) -> some View {
    DayDetailView(
      day: day,
      highlightViewModel: highlightViewModel,
      aiService: aiService,
      journalRepository: journalRepository,
      focusedEntryID: focusedEntryID
    )
  }
}

private struct TimelineCalendarBrowser: View {
  let days: [EchoDay]
  @Binding var selectedDayID: EchoDayIdentifier?

  @Environment(\.dismiss) private var dismiss
  @Environment(\.calendar) private var calendar
  @Environment(\.echoVisualWorld) private var world

  @State private var displayedMonth: Date

  init(
    days: [EchoDay],
    selectedDayID: Binding<EchoDayIdentifier?>,
    initialDate: Date
  ) {
    self.days = days
    _selectedDayID = selectedDayID
    _displayedMonth = State(initialValue: initialDate)
  }

  var body: some View {
    EchoWorldCanvas {
      VStack(spacing: EchoLayout.contentSpacing) {
        HStack {
          VStack(alignment: .leading, spacing: EchoLayout.microSpacing) {
            Text("JOURNAL CALENDAR")
              .font(EchoTypography.editorialEyebrow)
              .tracking(1.4)
              .foregroundStyle(world.accent)
            Text(monthStart, format: .dateTime.month(.wide).year())
              .font(EchoTypography.sectionTitle)
          }

          Spacer()

          monthButton(systemImage: "chevron.left", offset: -1)
          monthButton(systemImage: "chevron.right", offset: 1)

          Button("Done") { dismiss() }
            .buttonStyle(.borderedProminent)
            .tint(world.accent)
            .foregroundStyle(world.canvas)
        }

        EchoReadabilityPanel {
          VStack(spacing: EchoLayout.rowSpacing) {
            LazyVGrid(columns: calendarColumns, spacing: EchoLayout.inlineSpacing) {
              ForEach(Array(rotatedWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol.uppercased())
                  .font(EchoTypography.editorialEyebrow)
                  .foregroundStyle(world.secondaryText)
                  .frame(maxWidth: .infinity)
              }

              ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                if let date {
                  calendarDay(date)
                } else {
                  Color.clear
                    .frame(minHeight: 48)
                    .accessibilityHidden(true)
                }
              }
            }
          }
        }

        Text("Choose any day containing journal entries, including today.")
          .font(EchoTypography.supporting)
          .foregroundStyle(world.secondaryText)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: 620, alignment: .topLeading)
      .padding(EchoLayout.pageHorizontalPadding)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .frame(minWidth: 360, minHeight: 520)
  }

  private var monthStart: Date {
    calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
  }

  private var calendarColumns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: EchoLayout.tightSpacing), count: 7)
  }

  private var rotatedWeekdaySymbols: [String] {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    let startIndex = max(calendar.firstWeekday - 1, 0)
    return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
  }

  private var monthCells: [Date?] {
    guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart),
      let firstDay = calendar.date(bySetting: .day, value: dayRange.lowerBound, of: monthStart)
    else {
      return []
    }

    let weekday = calendar.component(.weekday, from: firstDay)
    let leadingCount = (weekday - calendar.firstWeekday + 7) % 7
    let leading = Array<Date?>(repeating: nil, count: leadingCount)
    let dates = dayRange.compactMap { day in
      calendar.date(bySetting: .day, value: day, of: monthStart)
    }
    return leading + dates.map(Optional.some)
  }

  private func calendarDay(_ date: Date) -> some View {
    let identifier = EchoDayIdentifier(containing: date, calendar: calendar)
    let day = days.first(where: { $0.id == identifier })
    let isSelected = selectedDayID == identifier

    return Button {
      selectedDayID = identifier
      dismiss()
    } label: {
      VStack(spacing: EchoLayout.microSpacing) {
        Text(date, format: .dateTime.day())
          .font(.body.weight(isSelected ? .bold : .medium))
          .frame(width: 36, height: 36)
          .foregroundStyle(isSelected ? world.canvas : world.primaryText)
          .background {
            if isSelected {
              Circle().fill(world.accent)
            }
          }

        Circle()
          .fill(day == nil ? Color.clear : world.accent)
          .frame(width: 4, height: 4)
      }
      .frame(maxWidth: .infinity, minHeight: 48)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(day == nil)
    .opacity(day == nil ? 0.38 : 1)
    .accessibilityLabel(
      "\(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())), \(day == nil ? "no entries" : "\(day?.entryCount ?? 0) entries")"
    )
    .accessibilityHint(day == nil ? "" : "Shows this day in Timeline")
  }

  private func monthButton(systemImage: String, offset: Int) -> some View {
    Button {
      if let newMonth = calendar.date(byAdding: .month, value: offset, to: monthStart) {
        displayedMonth = newMonth
      }
    } label: {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.bold))
        .frame(width: 36, height: 36)
        .background(.ultraThinMaterial, in: Circle())
        .overlay {
          Circle().stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(offset < 0 ? "Previous month" : "Next month")
  }
}

private struct TimelineDateTile: View {
  let date: Date
  let isSelected: Bool
  let hasEntries: Bool
  let isWide: Bool
  let usesFixedWidth: Bool

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    VStack(spacing: 3) {
      Text(date, format: .dateTime.day())
        .font(isWide ? .title3.weight(.medium) : .body.weight(.medium))
        .frame(width: isWide ? 38 : 34, height: isWide ? 38 : 34)
        .background {
          if isSelected {
            Circle().fill(world.accent)
          }
        }

      Text(date, format: .dateTime.weekday(.abbreviated))
        .font(.caption2.weight(isSelected ? .bold : .medium))
        .textCase(.uppercase)

      Circle()
        .fill(hasEntries ? world.accent : Color.clear)
        .frame(width: 3, height: 3)
    }
    .foregroundStyle(tileForeground)
    .frame(
      minWidth: usesFixedWidth ? 78 : nil,
      maxWidth: usesFixedWidth ? 78 : .infinity
    )
    .frame(minHeight: isWide ? 72 : 64)
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(isSelected ? "Selected, " : "")\(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())), \(hasEntries ? "has entries" : "no entries")"
    )
  }

  private var tileForeground: Color {
    if isSelected { return world.canvas }
    return hasEntries ? world.primaryText : world.secondaryText.opacity(0.75)
  }
}

private struct TimelineEntryRailRow: View {
  let entry: EchoEntry
  let showsContinuation: Bool

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.contentSpacing) {
      VStack(spacing: 0) {
        Circle()
          .fill(world.accent)
          .frame(width: 13, height: 13)
          .overlay {
            Circle().stroke(world.primaryText.opacity(0.65), lineWidth: 1.5)
          }

        if showsContinuation {
          Rectangle()
            .fill(world.accent.opacity(0.8))
            .frame(width: 1.5)
            .frame(maxHeight: .infinity)
        }
      }
      .frame(width: 18)

      VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
        Text(entry.createdAt, format: .dateTime.hour().minute())
          .font(EchoTypography.metadata)
          .tracking(0.7)
          .foregroundStyle(world.secondaryText)

        HStack(alignment: .top, spacing: EchoLayout.inlineSpacing) {
          Text(entry.preferredText)
            .font(EchoTypography.body)
            .foregroundStyle(world.primaryText)
            .lineLimit(3)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)

          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(world.accent)
        }
      }
      .padding(.bottom, showsContinuation ? EchoLayout.sectionSpacing : EchoLayout.tightSpacing)
    }
    .padding(.horizontal, EchoLayout.tightSpacing)
    .padding(.top, EchoLayout.rowSpacing)
    .accessibilityElement(children: .combine)
  }

}
