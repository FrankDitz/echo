import SwiftUI

struct TimelineView: View {
  let viewModel: TimelineViewModel
  @Binding var selectedDayID: EchoDayIdentifier?
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository
  @Binding var isSearchRequested: Bool
  let onCapture: () -> Void

  @State private var searchQuery = ""
  @State private var isShowingCalendar = false
  @State private var isSearchPresented = false
  @FocusState private var isSearchFocused: Bool

  @Environment(\.timeZone) private var timeZone
  @Environment(\.calendar) private var calendar
  @Environment(\.echoVisualWorld) private var world
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    EchoWorldCanvas(screen: .timeline) {
      GeometryReader { proxy in
        ScrollView {
          let isWide = proxy.size.width >= EchoLayout.wideLayoutBreakpoint

          Group {
            if isWide {
              desktopTimelineWorkspace
            } else {
#if os(iOS)
              iPhoneTimelineContent
#else
              LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
                timelineHeader
                searchControl
                timelineContent(isWide: false)
              }
#endif
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
      if isSearchRequested {
        presentSearch()
      }
    }
    .onChange(of: isSearchRequested) { _, requested in
      if requested {
        presentSearch()
      }
    }
    .sheet(isPresented: $isShowingCalendar) {
      LifeCalendarView(
        days: viewModel.days,
        selectedDayID: $selectedDayID,
        initialDate: stripAnchorDate,
        showsDismissButton: true
      )
      .echoPrivacyProtected()
    }
  }

  private func presentSearch() {
    isSearchPresented = true
    isSearchFocused = true
    isSearchRequested = false
  }

#if os(iOS)
  private var iPhoneTimelineContent: some View {
    LazyVStack(alignment: .leading, spacing: 12) {
      iPhoneTimelineHeader

      if isSearchPresented || containsSearchQuery {
        searchControl
          .transition(.move(edge: .top).combined(with: .opacity))
      }

      if containsSearchQuery {
        searchContent
          .padding(.top, 4)
      } else if viewModel.isLoading && viewModel.days.isEmpty {
        EchoLoadingState(title: "Loading your timeline…")
      } else {
        iPhoneDateStrip

        if viewModel.days.isEmpty {
          EchoSurface {
            EchoEmptyState(
              title: "Your story starts here",
              systemImage: "clock.arrow.circlepath",
              description: "Days with journal entries will gather here over time.",
              minHeight: 140
            )
          }
        } else {
          iPhoneTimelineRail
        }

        if viewModel.failure != nil {
          EchoErrorState(
            message: "The timeline could not be refreshed. Showing the last loaded days."
          )
        }
      }
    }
    .animation(.easeInOut(duration: 0.2), value: isSearchPresented)
  }

  private var iPhoneTimelineHeader: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("Timeline")
        .font(world.displayFont(size: 42, weight: .black))
        .accessibilityAddTraits(.isHeader)
      Text(timelineMessage)
        .font(.system(size: 10, weight: .bold))
        .tracking(1.65)
        .foregroundStyle(world.accent)
    }
    .padding(.top, 10)
    .padding(.bottom, 4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background { EchoArtworkTitleScrim() }
    .shadow(color: world.contentShadow, radius: 8, y: 2)
    .accessibilityElement(children: .combine)
  }

  private var timelineMessage: String {
    switch world.id {
    case .cornerstoneSignal: "A RECORD OF GRACE"
    case .goldStandard: "A JOURNEY OF GRACE"
    case .kingdomGreen: "THE STORY YOU ARE LIVING"
    case .covenantBlue: "COURAGE, KEPT IN ORDER"
    }
  }

  private var iPhoneDateStrip: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack {
        Text(stripDateRangeLabel)
          .font(.system(size: 10, weight: .bold))
          .tracking(1.4)
        Spacer()
        Button {
          isShowingCalendar = true
        } label: {
          Image(systemName: "calendar")
            .frame(width: 30, height: 26)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open calendar browser")
      }

      HStack(spacing: 4) {
        ForEach(dateStripDates, id: \.self) { date in
          let day = day(for: date)
          Button {
            if let day { selectedDayID = day.id }
          } label: {
            VStack(spacing: 2) {
              Text(date, format: .dateTime.day())
                .font(.system(size: 14, weight: .bold))
              Text(date, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: 8, weight: .semibold))
                .textCase(.uppercase)
            }
            .foregroundStyle(
              day?.id == selectedTimelineDay?.id ? world.editorialPaper : world.primaryText
            )
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
              RoundedRectangle(cornerRadius: 8)
                .fill(
                  day?.id == selectedTimelineDay?.id
                    ? world.editorialInk : world.canvas.opacity(day == nil ? 0.14 : 0.54)
                )
            }
            .overlay {
              RoundedRectangle(cornerRadius: 8)
                .stroke(world.separator.opacity(0.65), lineWidth: 0.75)
            }
          }
          .buttonStyle(.plain)
          .disabled(day == nil)
          .opacity(day == nil ? 0.58 : 1)
        }
      }
    }
    .padding(10)
    .background(world.canvas.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(world.separator.opacity(0.72), lineWidth: 0.75)
    }
  }

  private var iPhoneTimelineRail: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(
          selectedTimelineDay.map(displayDate(for:)) ?? stripAnchorDate,
          format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year()
        )
        .font(.system(size: 10, weight: .bold))
        .tracking(1.35)
        .textCase(.uppercase)
        .foregroundStyle(world.primaryText.opacity(0.86))

        Spacer()

        Text(selectedTimelineDay?.entryCount ?? 0, format: .number)
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(world.accent)
      }
      .padding(.horizontal, 4)
      .padding(.bottom, 6)

      if let selectedTimelineDay {
        let entries = Array(selectedTimelineDay.entries.reversed())
        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
          NavigationLink {
            destination(for: selectedTimelineDay, focusedEntryID: entry.id)
          } label: {
            iPhoneTimelineEntry(
              entry,
              index: index,
              continues: index < entries.count - 1
            )
          }
          .buttonStyle(.plain)
          .accessibilityHint("Opens this entry in its day reflection")
        }
      }
    }
    .overlay(alignment: .bottomTrailing) {
      Button(action: onCapture) {
        Image(systemName: "plus")
          .font(.system(size: 19, weight: .bold))
          .foregroundStyle(world.editorialPaper)
          .frame(width: 48, height: 48)
          .background(world.editorialAccent, in: Circle())
          .overlay {
            Circle().stroke(world.editorialPaper.opacity(0.82), lineWidth: 1.5)
          }
          .shadow(color: world.contentShadow, radius: 9, y: 4)
      }
      .buttonStyle(.plain)
      .padding(.trailing, 2)
      .padding(.bottom, 8)
      .accessibilityLabel("Capture a new entry")
      .accessibilityHint("Opens Today and its journal composer")
    }
  }

  private func iPhoneTimelineEntry(
    _ entry: EchoEntry,
    index: Int,
    continues: Bool
  ) -> some View {
    let usesDarkCard = world.id == .covenantBlue && index.isMultiple(of: 2) == false
    let cardFill = usesDarkCard ? world.surfaceFill.opacity(0.96) : world.editorialPaper
    let cardInk = usesDarkCard ? world.primaryText : world.editorialInk
    let cardMuted = usesDarkCard ? world.secondaryText : world.editorialMuted
    let parts = timelineTextParts(entry.preferredText)

    return HStack(alignment: .top, spacing: 8) {
      VStack(spacing: 0) {
        Circle()
          .fill(world.accent)
          .frame(width: 12, height: 12)
          .overlay {
            Circle().stroke(world.editorialPaper, lineWidth: 1.5)
          }
        if continues {
          Rectangle()
            .fill(world.accent)
            .frame(width: 2)
            .frame(maxHeight: .infinity)
        }
      }
      .frame(width: 18)

      HStack(spacing: 9) {
        VStack(alignment: .leading, spacing: 2) {
          Text(entry.createdAt, format: .dateTime.hour().minute())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(cardMuted)
          Text(parts.title)
            .font(.system(size: 14, weight: .bold, design: .serif))
            .foregroundStyle(cardInk)
            .lineLimit(1)
          if let detail = parts.detail {
            Text(detail)
              .font(.system(size: 11))
              .foregroundStyle(cardInk.opacity(0.82))
              .lineLimit(2)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        ZStack {
          LinearGradient(
            colors: [world.editorialAccent.opacity(0.9), world.editorialInk],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          Image(systemName: entry.type == .voice ? "waveform" : "text.quote")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(world.editorialPaper)
        }
        .frame(width: 48, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .accessibilityHidden(true)

        Image(systemName: "ellipsis")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(cardMuted)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(cardFill, in: RoundedRectangle(cornerRadius: 10))
      .overlay {
        RoundedRectangle(cornerRadius: 10)
          .stroke(world.separator.opacity(0.65), lineWidth: 0.75)
      }
      .padding(.bottom, 7)
    }
  }

  private func timelineTextParts(_ text: String) -> (title: String, detail: String?) {
    let words = text.split(whereSeparator: \.isWhitespace).map(String.init)
    guard words.count > 5 else { return (text, nil) }
    return (words.prefix(4).joined(separator: " "), words.dropFirst(4).joined(separator: " "))
  }
#endif

  private var timelineHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text("YOUR HISTORY")
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.5)
        .foregroundStyle(world.accent)

      Text("Timeline")
        .font(world.displayFont(size: 38, weight: .medium))
        .foregroundStyle(world.primaryText)
        .accessibilityAddTraits(.isHeader)

      Text("Every day you have written, kept in one quiet place.")
        .font(EchoTypography.supporting)
        .foregroundStyle(world.primaryText.opacity(0.82))
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }

  private var desktopTimelineWorkspace: some View {
    VStack(alignment: .leading, spacing: 24) {
      HStack(alignment: .bottom, spacing: 48) {
        timelineHeader
          .frame(maxWidth: .infinity, alignment: .leading)
        searchControl
          .frame(width: 420)
      }

      if containsSearchQuery {
        searchContent
          .frame(maxWidth: 980, alignment: .leading)
      } else if viewModel.isLoading && viewModel.days.isEmpty {
        EchoLoadingState(title: "Loading your timeline…")
      } else if viewModel.days.isEmpty {
        EchoSurface {
          EchoEmptyState(
            title: "Your story starts here",
            systemImage: "clock.arrow.circlepath",
            description: "Days with journal entries will gather here over time.",
            minHeight: EchoLayout.compactStateHeight
          )
        }
      } else {
        HStack(alignment: .top, spacing: 22) {
          desktopDayNavigator
            .frame(width: 280)
          timelineRail
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }

      if viewModel.failure != nil {
        EchoErrorState(
          message: "The timeline could not be refreshed. Showing the last loaded days."
        )
      }
    }
  }

  private var desktopDayNavigator: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("RECENT DAYS")
            .font(EchoTypography.editorialEyebrow)
            .tracking(1.4)
            .foregroundStyle(world.accent)
          Text(stripDateRangeLabel)
            .font(EchoTypography.metadata)
            .foregroundStyle(world.secondaryText)
        }
        Spacer()
        Button {
          isShowingCalendar = true
        } label: {
          Image(systemName: "calendar")
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(world.accent)
        .accessibilityLabel("Open calendar browser")
      }
      .padding(18)

      Divider().overlay(world.separator)

      ForEach(dateStripDates.reversed(), id: \.self) { date in
        let day = day(for: date)
        Button {
          if let day { selectedDayID = day.id }
        } label: {
          HStack(spacing: 14) {
            VStack(spacing: 1) {
              Text(date, format: .dateTime.day())
                .font(world.displayFont(size: 25, weight: .bold))
              Text(date, format: .dateTime.weekday(.abbreviated))
                .font(EchoTypography.metadata)
                .textCase(.uppercase)
            }
            .frame(width: 46)

            VStack(alignment: .leading, spacing: 3) {
              Text(date, format: .dateTime.month(.wide))
                .font(EchoTypography.body.weight(.semibold))
              Text(day.map { "\($0.entryCount) \($0.entryCount == 1 ? "entry" : "entries")" } ?? "No writing")
                .font(EchoTypography.metadata)
                .foregroundStyle(world.secondaryText)
            }

            Spacer()
            Circle()
              .fill(day == nil ? world.separator : world.accent)
              .frame(width: 7, height: 7)
          }
          .foregroundStyle(
            day?.id == selectedTimelineDay?.id ? world.editorialPaper : world.primaryText
          )
          .padding(.horizontal, 14)
          .frame(minHeight: 66)
          .background(
            day?.id == selectedTimelineDay?.id
              ? world.editorialInk.opacity(0.94) : Color.clear
          )
          .overlay(alignment: .leading) {
            if day?.id == selectedTimelineDay?.id {
              Rectangle()
                .fill(world.accent)
                .frame(width: 4)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(day == nil)
        .opacity(day == nil ? 0.62 : 1)

        if date != dateStripDates.first {
          Divider().overlay(world.separator.opacity(0.65))
        }
      }
    }
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
      RoundedRectangle(cornerRadius: 16)
        .fill(world.surfaceFill.opacity(0.7))
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
    }
    .shadow(color: world.contentShadow.opacity(0.16), radius: 16, y: 6)
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

struct LifeCalendarView: View {
  let days: [EchoDay]
  @Binding var selectedDayID: EchoDayIdentifier?
  let showsDismissButton: Bool
  let onSelectDay: (() -> Void)?

  @Environment(\.dismiss) private var dismiss
  @Environment(\.calendar) private var calendar
  @Environment(\.echoVisualWorld) private var world

  @State private var displayedMonth: Date

  init(
    days: [EchoDay],
    selectedDayID: Binding<EchoDayIdentifier?>,
    initialDate: Date,
    showsDismissButton: Bool,
    onSelectDay: (() -> Void)? = nil
  ) {
    self.days = days
    _selectedDayID = selectedDayID
    self.showsDismissButton = showsDismissButton
    self.onSelectDay = onSelectDay
    _displayedMonth = State(initialValue: initialDate)
  }

  var body: some View {
    EchoWorldCanvas(screen: .calendar) {
#if os(iOS)
      compactLifeCalendar
#else
      GeometryReader { proxy in
        ScrollView {
          let isWide = proxy.size.width >= EchoLayout.wideLayoutBreakpoint

          VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
            VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
              Text("Life Calendar")
                .font(world.displayFont(size: isWide ? 58 : 46, weight: .black))
                .foregroundStyle(world.primaryText)
                .accessibilityAddTraits(.isHeader)

              Text("A MONTH IN PERSPECTIVE")
                .font(EchoTypography.editorialEyebrow)
                .tracking(1.6)
                .foregroundStyle(world.accent)
            }
            .shadow(color: world.contentShadow, radius: 10, y: 3)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            if isWide {
              HStack(alignment: .top, spacing: 32) {
                calendarPanel
                  .frame(maxWidth: 720)
                monthPerspective
                  .frame(width: 340)
              }
            } else {
              calendarPanel
              monthPerspective
            }
          }
          .frame(
            maxWidth: isWide ? EchoLayout.wideContentMaxWidth : EchoLayout.contentMaxWidth,
            alignment: .topLeading
          )
          .padding(.horizontal, isWide ? 40 : EchoLayout.pageHorizontalPadding)
          .padding(.vertical, isWide ? 36 : EchoLayout.pageVerticalPadding)
          .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
        }
        .scrollIndicators(.hidden)
      }
#endif
    }
    .frame(minWidth: 360, minHeight: 520)
  }

  private var compactLifeCalendar: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        compactCalendarMasthead
        compactCalendarContent
      }
      .frame(maxWidth: EchoLayout.contentMaxWidth)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private var compactCalendarMasthead: some View {
    VStack(alignment: .leading, spacing: 4) {
      Spacer(minLength: 30)
      Text("Life Calendar")
        .font(world.displayFont(size: 42, weight: .black))
        .tracking(-0.7)
        .foregroundStyle(world.primaryText)
        .accessibilityAddTraits(.isHeader)

      Text("A MONTH IN PERSPECTIVE.")
        .font(.system(size: 10, weight: .black))
        .tracking(2.2)
        .foregroundStyle(world.primaryText.opacity(0.86))
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .padding(.horizontal, 18)
    .padding(.bottom, 14)
    .frame(maxWidth: .infinity, minHeight: 116, alignment: .bottomLeading)
    .background { EchoArtworkTitleScrim() }
  }

  private var compactCalendarContent: some View {
    VStack(alignment: .leading, spacing: 10) {
      compactMonthBar
      compactSelectedDateBanner
      compactMonthGrid
      compactMonthSummary
      compactWritingSignals
    }
    .padding(.horizontal, 14)
    .padding(.top, 12)
    .padding(.bottom, 26)
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .background(world.canvas.opacity(0.96))
    .overlay(alignment: .top) {
      Rectangle()
        .fill(world.accent)
        .frame(height: 3)
    }
  }

  private var compactMonthBar: some View {
    HStack(spacing: 8) {
      compactMonthButton(systemImage: "chevron.left", offset: -1)

      Text(monthStart, format: .dateTime.month(.wide).year())
        .font(world.displayFont(size: 20, weight: .bold))
        .frame(maxWidth: .infinity)

      compactMonthButton(systemImage: "chevron.right", offset: 1)

      Button("Today") {
        selectToday()
      }
      .font(.caption.weight(.bold))
      .padding(.horizontal, 10)
      .frame(height: 32)
      .overlay {
        Capsule().stroke(compactBarInk.opacity(0.45), lineWidth: 0.8)
      }
      .buttonStyle(.plain)

      if showsDismissButton {
        Button("Done") { dismiss() }
          .font(.caption.weight(.bold))
          .buttonStyle(.plain)
      }
    }
    .foregroundStyle(compactBarInk)
    .padding(.horizontal, 10)
    .padding(.vertical, 7)
    .background(compactBarFill, in: RoundedRectangle(cornerRadius: 10))
  }

  private var compactSelectedDateBanner: some View {
    HStack(spacing: 7) {
      Image(systemName: isSelectedDateToday ? "crown.fill" : "calendar")
        .foregroundStyle(world.accent)

      Text(selectedDateContextLabel)
        .font(.system(size: 9, weight: .black))
        .tracking(1.25)
        .foregroundStyle(world.accent)

      Text(selectedDisplayDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
        .font(.caption.weight(.semibold))
        .foregroundStyle(world.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.76)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 10)
    .frame(minHeight: 28)
    .background(world.surfaceFill.opacity(0.64), in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(world.separator.opacity(0.55), lineWidth: 0.7)
    }
    .accessibilityElement(children: .combine)
  }

  private var compactMonthGrid: some View {
    LazyVGrid(columns: compactCalendarColumns, spacing: 2) {
      ForEach(Array(rotatedWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
        Text(symbol.uppercased())
          .font(.system(size: 9, weight: .black))
          .foregroundStyle(world.secondaryText)
          .frame(maxWidth: .infinity, minHeight: 18)
      }

      ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
        if let date {
          compactCalendarDay(date)
        } else {
          Color.clear
            .frame(minHeight: 43)
            .accessibilityHidden(true)
        }
      }
    }
    .padding(5)
    .background(world.surfaceFill.opacity(0.38), in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(world.separator.opacity(0.72), lineWidth: 0.8)
    }
    .dynamicTypeSize(...DynamicTypeSize.large)
  }

  private var compactMonthSummary: some View {
    HStack(alignment: .bottom, spacing: 14) {
      VStack(alignment: .leading, spacing: 2) {
        Text(monthDeltaLabel)
          .font(world.displayFont(size: 36, weight: .black))
          .foregroundStyle(compactSummaryAccent)
          .minimumScaleFactor(0.72)
          .lineLimit(1)

        Text("WRITING DAYS")
          .font(.system(size: 9, weight: .black))
          .tracking(1.4)
        Text(monthComparisonLabel)
          .font(.caption2.weight(.medium))
          .opacity(0.72)
      }
      .frame(width: 126, alignment: .leading)

      HStack(alignment: .bottom, spacing: 7) {
        ForEach(Array(weeklyEntryCounts.enumerated()), id: \.offset) { index, count in
          VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
              .fill(count == 0 ? compactSummaryInk.opacity(0.18) : compactSummaryAccent)
              .frame(height: max(7, min(CGFloat(count) * 6, 60)))
            Text("W\(index + 1)")
              .font(.system(size: 7, weight: .bold))
              .opacity(0.64)
          }
          .frame(maxWidth: .infinity, alignment: .bottom)
        }
      }
      .frame(maxWidth: .infinity, minHeight: 72, alignment: .bottom)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(
        "Weekly journal activity: \(weeklyEntryCounts.map(String.init).joined(separator: ", ")) entries"
      )
    }
    .foregroundStyle(compactSummaryInk)
    .padding(14)
    .background(compactSummaryFill, in: RoundedRectangle(cornerRadius: 12))
  }

  private var compactWritingSignals: some View {
    VStack(alignment: .leading, spacing: 9) {
      HStack {
        Text("Writing Signals")
          .font(.headline.weight(.bold))
        Spacer()
        Text("\(monthEntryCount) entries")
          .font(.caption.weight(.bold))
          .foregroundStyle(world.secondaryText)
      }

      HStack(spacing: 7) {
        compactSignal(
          title: "Written",
          value: monthDaysWithEntries.count,
          systemImage: "book.closed.fill"
        )
        compactSignal(title: "Voice", value: monthVoiceEntryCount, systemImage: "waveform")
        compactSignal(title: "Full days", value: monthFullDayCount, systemImage: "chart.bar.fill")
      }
    }
    .foregroundStyle(world.primaryText)
    .padding(12)
    .background(world.surfaceFill.opacity(0.82), in: RoundedRectangle(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(world.separator.opacity(0.62), lineWidth: 0.8)
    }
  }

  private func compactSignal(title: String, value: Int, systemImage: String) -> some View {
    VStack(spacing: 4) {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(world.accent)
      Text(value, format: .number)
        .font(.headline.weight(.bold))
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(world.secondaryText)
    }
    .frame(maxWidth: .infinity, minHeight: 62)
    .background(world.selectedFill.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
  }

  private func compactCalendarDay(_ date: Date) -> some View {
    let identifier = EchoDayIdentifier(containing: date, calendar: calendar)
    let day = days.first(where: { $0.id == identifier })
    let isSelected = isCalendarDateSelected(identifier, date: date)

    return Button {
      selectedDayID = identifier
      if showsDismissButton {
        dismiss()
      } else {
        onSelectDay?()
      }
    } label: {
      VStack(spacing: 2) {
        Text(date, format: .dateTime.day())
          .font(.caption.weight(isSelected ? .black : .semibold))

        Image(systemName: day == nil ? "circle.fill" : journalSignal(for: day, date: date))
          .font(.system(size: day == nil ? 5 : 11, weight: .bold))
          .opacity(day == nil ? 0.3 : 1)
      }
      .foregroundStyle(compactDayInk(isSelected: isSelected))
      .frame(maxWidth: .infinity, minHeight: 43)
      .background(
        compactDayFill(day: day, isSelected: isSelected),
        in: RoundedRectangle(cornerRadius: 6)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 6)
          .stroke(world.separator.opacity(0.5), lineWidth: 0.65)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(day == nil)
    .accessibilityLabel(
      "\(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())), \(day == nil ? "no entries" : "\(day?.entryCount ?? 0) entries")"
    )
    .accessibilityHint(day == nil ? "" : "Shows this day in Timeline")
  }

  private func compactMonthButton(systemImage: String, offset: Int) -> some View {
    Button {
      if let newMonth = calendar.date(byAdding: .month, value: offset, to: monthStart) {
        displayedMonth = newMonth
      }
    } label: {
      Image(systemName: systemImage)
        .font(.caption.weight(.black))
        .frame(width: 30, height: 30)
        .background(compactBarInk.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(offset < 0 ? "Previous month" : "Next month")
  }

  private func compactDayFill(day: EchoDay?, isSelected: Bool) -> Color {
    if isSelected { return compactSelectedDayFill }
    if day != nil { return world.selectedFill.opacity(0.42) }
    return world.surfaceFill.opacity(0.16)
  }

  private func compactDayInk(isSelected: Bool) -> Color {
    isSelected ? compactSelectedDayInk : world.primaryText
  }

  private var compactBarFill: Color {
    world.preferredColorScheme == .dark ? world.surfaceFill.opacity(0.96) : world.editorialInk
  }

  private var compactBarInk: Color {
    world.preferredColorScheme == .dark ? world.primaryText : world.editorialPaper
  }

  private var compactSelectedDayFill: Color {
    world.preferredColorScheme == .dark ? world.editorialPaper : world.editorialInk
  }

  private var compactSelectedDayInk: Color {
    world.preferredColorScheme == .dark ? world.editorialInk : world.editorialPaper
  }

  private var compactSummaryFill: Color {
    world.preferredColorScheme == .dark ? world.surfaceFill.opacity(0.98) : world.editorialInk
  }

  private var compactSummaryInk: Color {
    world.preferredColorScheme == .dark ? world.primaryText : world.editorialPaper
  }

  private var compactSummaryAccent: Color {
    world.id == .goldStandard ? world.canvas : world.accent
  }

  private var compactCalendarColumns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
  }

  private var monthEntryCount: Int {
    monthDaysWithEntries.reduce(0) { $0 + $1.entryCount }
  }

  private var monthVoiceEntryCount: Int {
    monthDaysWithEntries.flatMap(\.entries).filter { $0.type == .voice }.count
  }

  private var monthFullDayCount: Int {
    monthDaysWithEntries.filter { $0.entryCount >= 3 }.count
  }

  private var previousMonthDaysWithEntries: Int {
    guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthStart) else {
      return 0
    }
    return days.filter { day in
      guard let date = day.id.date(in: calendar.timeZone) else { return false }
      return calendar.isDate(date, equalTo: previousMonth, toGranularity: .month)
    }.count
  }

  private var monthDeltaLabel: String {
    let delta = monthDaysWithEntries.count - previousMonthDaysWithEntries
    if delta == 0 { return "STEADY" }
    return delta > 0 ? "+\(delta)" : "\(delta)"
  }

  private var monthComparisonLabel: String {
    let delta = monthDaysWithEntries.count - previousMonthDaysWithEntries
    if delta == 0 { return "Same as last month" }
    return delta > 0 ? "More than last month" : "Fewer than last month"
  }

  private var calendarPanel: some View {
    EchoReadabilityPanel {
      VStack(spacing: EchoLayout.contentSpacing) {
        ViewThatFits(in: .horizontal) {
          HStack(spacing: EchoLayout.tightSpacing) {
            monthTitle
            monthControls
          }

          VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
            monthTitle
            monthControls
          }
        }

        LazyVGrid(columns: calendarColumns, spacing: EchoLayout.tightSpacing) {
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
                .frame(minHeight: 56)
                .accessibilityHidden(true)
            }
          }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
      }
    }
  }

  private var monthTitle: some View {
    Text(monthStart, format: .dateTime.month(.wide).year())
      .font(EchoTypography.sectionTitle)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var monthControls: some View {
    HStack(spacing: EchoLayout.tightSpacing) {
      monthButton(systemImage: "chevron.left", offset: -1)
      monthButton(systemImage: "chevron.right", offset: 1)

      Button("Today") {
        selectToday()
      }
      .font(EchoTypography.metadata.weight(.semibold))
      .buttonStyle(.bordered)

      if showsDismissButton {
        Button("Done") { dismiss() }
          .font(EchoTypography.metadata.weight(.semibold))
          .buttonStyle(.borderedProminent)
          .tint(world.accent)
          .foregroundStyle(world.canvas)
      }
    }
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }

  private var monthPerspective: some View {
    EchoReadabilityPanel {
      VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
        VStack(alignment: .leading, spacing: EchoLayout.microSpacing) {
          Text("THIS MONTH")
            .font(EchoTypography.editorialEyebrow)
            .tracking(1.4)
            .foregroundStyle(world.accent)
          Text("Your writing rhythm")
            .font(EchoTypography.sectionTitle)
        }

        HStack(alignment: .firstTextBaseline, spacing: EchoLayout.tightSpacing) {
          Text(monthDaysWithEntries.count, format: .number)
            .font(world.displayFont(size: 44, weight: .black))
            .foregroundStyle(world.accent)
          Text(monthDaysWithEntries.count == 1 ? "journal day" : "journal days")
            .font(EchoTypography.supporting.weight(.semibold))
            .foregroundStyle(world.secondaryText)
        }

        HStack(alignment: .bottom, spacing: EchoLayout.tightSpacing) {
          ForEach(Array(weeklyEntryCounts.enumerated()), id: \.offset) { index, count in
            VStack(spacing: EchoLayout.microSpacing) {
              RoundedRectangle(cornerRadius: 4)
                .fill(count == 0 ? world.separator.opacity(0.35) : world.accent)
                .frame(height: max(8, CGFloat(count) * 8))
              Text("W\(index + 1)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(world.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
          }
        }
        .frame(height: 82, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly journal activity: \(weeklyEntryCounts.map(String.init).joined(separator: ", ")) entries")

        Divider()
          .overlay(world.separator)

        HStack(spacing: EchoLayout.contentSpacing) {
          calendarLegend("Written", systemImage: "book.closed.fill")
          calendarLegend("Voice", systemImage: "waveform")
          calendarLegend("Full day", systemImage: "chart.bar.fill")
        }

        Text("Select a marked day to revisit its complete timeline.")
          .font(EchoTypography.supporting)
          .foregroundStyle(world.secondaryText)
      }
    }
  }

  private var monthStart: Date {
    calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
  }

  private var selectedDisplayDate: Date {
    if let selectedDate = selectedDayID?.date(in: calendar.timeZone),
      calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month)
    {
      return selectedDate
    }

    if calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month) {
      return .now
    }

    return monthStart
  }

  private var isSelectedDateToday: Bool {
    calendar.isDateInToday(selectedDisplayDate)
  }

  private var selectedDateContextLabel: String {
    if isSelectedDateToday { return "TODAY" }
    if let selectedDate = selectedDayID?.date(in: calendar.timeZone),
      calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month)
    {
      return "SELECTED"
    }
    return "VIEWING"
  }

  private func selectToday() {
    let today = Date.now
    displayedMonth = today
    selectedDayID = EchoDayIdentifier(containing: today, calendar: calendar)
  }

  private func isCalendarDateSelected(_ identifier: EchoDayIdentifier, date: Date) -> Bool {
    if let selectedDate = selectedDayID?.date(in: calendar.timeZone),
      calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month)
    {
      return selectedDayID == identifier
    }

    return calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
      && calendar.isDateInToday(date)
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
    let isSelected = isCalendarDateSelected(identifier, date: date)

    return Button {
      selectedDayID = identifier
      if showsDismissButton {
        dismiss()
      } else {
        onSelectDay?()
      }
    } label: {
      VStack(spacing: 2) {
        Text(date, format: .dateTime.day())
          .font(.subheadline.weight(isSelected ? .bold : .medium))

        Image(systemName: journalSignal(for: day, date: date))
          .font(.caption2.weight(.bold))
          .opacity(day == nil ? 0 : 1)
      }
      .foregroundStyle(isSelected ? world.canvas : world.primaryText)
      .frame(maxWidth: .infinity, minHeight: 56)
      .background(
        isSelected ? world.accent : world.selectedFill.opacity(day == nil ? 0.08 : 0.28),
        in: RoundedRectangle(cornerRadius: 8)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(world.separator.opacity(day == nil ? 0.35 : 0.9), lineWidth: EchoShape.hairlineWidth)
      }
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

  private var monthDaysWithEntries: [EchoDay] {
    days.filter { day in
      guard let date = day.id.date(in: calendar.timeZone) else { return false }
      return calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
    }
  }

  private var weeklyEntryCounts: [Int] {
    var counts = Array(repeating: 0, count: 6)
    for day in monthDaysWithEntries {
      guard let date = day.id.date(in: calendar.timeZone) else { continue }
      let week = min(max((calendar.component(.day, from: date) - 1) / 7, 0), 5)
      counts[week] += day.entryCount
    }
    return counts
  }

  private func journalSignal(for day: EchoDay?, date: Date) -> String {
    guard let day else { return "circle" }
    if calendar.isDateInToday(date) { return "crown.fill" }
    if day.entries.contains(where: { $0.type == .voice }) { return "waveform" }
    if day.entryCount >= 3 { return "chart.bar.fill" }
    return "book.closed.fill"
  }

  private func calendarLegend(_ title: String, systemImage: String) -> some View {
    VStack(spacing: EchoLayout.microSpacing) {
      Image(systemName: systemImage)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(world.accent)
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(world.secondaryText)
    }
    .frame(maxWidth: .infinity)
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
