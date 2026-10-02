import SwiftUI

struct TimelineView: View {
  let viewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @State private var selectedDayID: EchoDayIdentifier?

  @Environment(\.timeZone) private var timeZone
  @Environment(\.calendar) private var calendar
  @Environment(\.echoVisualWorld) private var world
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    EchoWorldCanvas {
      GeometryReader { proxy in
        ScrollView {
          let isWide = proxy.size.width >= EchoLayout.wideLayoutBreakpoint

          LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
            if isWide {
              timelineHeader
            }
            timelineContent(isWide: isWide)
          }
          .frame(
            maxWidth: isWide ? 960 : EchoLayout.contentMaxWidth,
            alignment: .leading
          )
          .padding(.horizontal, isWide ? 40 : EchoLayout.pageHorizontalPadding)
          .padding(.vertical, isWide ? 46 : EchoLayout.pageVerticalPadding)
          .frame(maxWidth: .infinity)
          .frame(minHeight: proxy.size.height, alignment: .top)
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
  }

  private var timelineHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text("YOUR HISTORY")
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.5)
        .foregroundStyle(.secondary)

      Text("Timeline")
        .font(EchoTypography.editorialDisplay)
        .accessibilityAddTraits(.isHeader)

      Text("Previous days, kept in one quiet place.")
        .font(EchoTypography.supporting)
        .foregroundStyle(.secondary)
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private func timelineContent(isWide: Bool) -> some View {
    if viewModel.isLoading && viewModel.days.isEmpty {
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

  private func recentDateStrip(isWide: Bool) -> some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      HStack {
        Text(stripDateRangeLabel)
          .tracking(1.6)

        Spacer()

        Label("7-day view", systemImage: "calendar")
          .labelStyle(.titleAndIcon)
          .accessibilityLabel("Seven-day date browser")
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
    viewModel.days.first.map(displayDate(for:)) ?? viewModel.mostRecentTimelineDate
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
          Text(entry.rawText)
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
