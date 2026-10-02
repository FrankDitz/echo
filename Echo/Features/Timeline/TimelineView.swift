import SwiftUI

struct TimelineView: View {
  let viewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @Environment(\.timeZone) private var timeZone
  @Environment(\.calendar) private var calendar
  @Environment(\.echoVisualWorld) private var world

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

        Image(systemName: "calendar")
          .accessibilityHidden(true)
      }
      .font(EchoTypography.metadata)
      .foregroundStyle(world.secondaryText)
      .padding(.horizontal, isWide ? 22 : 14)
      .padding(.top, isWide ? 18 : 12)

      HStack(spacing: 0) {
        ForEach(dateStripDates, id: \.self) { date in
          if let day = day(for: date) {
            NavigationLink {
              destination(for: day)
            } label: {
              TimelineDateTile(
                date: date,
                isLatest: day.id == viewModel.days.first?.id,
                hasEntries: true,
                isWide: isWide
              )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens this day’s entries")
          } else {
            TimelineDateTile(
              date: date,
              isLatest: false,
              hasEntries: false,
              isWide: isWide
            )
          }
        }
      }
      .padding(.horizontal, isWide ? 12 : 4)
      .padding(.bottom, isWide ? 16 : 10)
    }
    .background {
      RoundedRectangle(cornerRadius: isWide ? 18 : 14)
        .fill(.ultraThinMaterial)
      RoundedRectangle(cornerRadius: isWide ? 18 : 14)
        .fill(world.canvas.opacity(0.1))
    }
    .overlay {
      RoundedRectangle(cornerRadius: isWide ? 18 : 14)
        .stroke(world.separator.opacity(0.75), lineWidth: EchoShape.hairlineWidth)
    }
    .shadow(color: world.contentShadow.opacity(0.15), radius: 14, y: 6)
  }

  private var timelineRail: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("JOURNAL DAYS")
          .font(EchoTypography.metadata)
          .tracking(1.4)
          .foregroundStyle(world.secondaryText)

        Spacer()

        Text(viewModel.days.count, format: .number)
          .font(EchoTypography.metadata)
          .foregroundStyle(.secondary)
          .accessibilityLabel(
            "\(viewModel.days.count) \(viewModel.days.count == 1 ? "day" : "days")"
          )
      }
      .padding(.horizontal, EchoLayout.surfacePadding)
      .padding(.vertical, EchoLayout.contentSpacing)

      Rectangle()
        .fill(world.separator.opacity(0.7))
        .frame(height: EchoShape.hairlineWidth)

      ForEach(Array(viewModel.days.enumerated()), id: \.element.id) { index, day in
        NavigationLink {
          destination(for: day)
        } label: {
          TimelineDayRailRow(
            day: day,
            displayDate: displayDate(for: day),
            showsContinuation: index < viewModel.days.count - 1
          )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this day’s entries")
      }
    }
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
      RoundedRectangle(cornerRadius: 16)
        .fill(world.canvas.opacity(0.08))
    }
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(world.separator.opacity(0.65), lineWidth: EchoShape.hairlineWidth)
    }
    .shadow(color: world.contentShadow.opacity(0.13), radius: 14, y: 6)
  }

  private var stripAnchorDate: Date {
    viewModel.days.first.map(displayDate(for:)) ?? viewModel.mostRecentTimelineDate
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

  private func destination(for day: EchoDay) -> some View {
    DayDetailView(
      day: day,
      highlightViewModel: highlightViewModel,
      aiService: aiService,
      journalRepository: journalRepository
    )
  }
}

private struct TimelineDateTile: View {
  let date: Date
  let isLatest: Bool
  let hasEntries: Bool
  let isWide: Bool

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    VStack(spacing: 3) {
      Text(date, format: .dateTime.day())
        .font(isWide ? .title3.weight(.medium) : .body.weight(.medium))
        .frame(width: isWide ? 38 : 34, height: isWide ? 38 : 34)
        .background {
          if isLatest {
            Circle().fill(world.accent)
          }
        }

      Text(date, format: .dateTime.weekday(.abbreviated))
        .font(.caption2.weight(isLatest ? .bold : .medium))
        .textCase(.uppercase)

      Circle()
        .fill(hasEntries ? world.accent : Color.clear)
        .frame(width: 3, height: 3)
    }
    .foregroundStyle(tileForeground)
    .frame(maxWidth: .infinity)
    .frame(minHeight: isWide ? 72 : 64)
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(isLatest ? "Latest entry, " : "")\(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())), \(hasEntries ? "has entries" : "no entries")"
    )
  }

  private var tileForeground: Color {
    if isLatest { return world.canvas }
    return hasEntries ? world.primaryText : world.secondaryText.opacity(0.75)
  }
}

private struct TimelineDayRailRow: View {
  let day: EchoDay
  let displayDate: Date
  let showsContinuation: Bool

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.contentSpacing) {
      VStack(spacing: 0) {
        Circle()
          .fill(world.accent)
          .frame(width: 10, height: 10)
          .overlay {
            Circle().stroke(world.primaryText.opacity(0.5), lineWidth: 1.5)
          }

        if showsContinuation {
          Rectangle()
            .fill(world.separator)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
        }
      }
      .frame(width: 16)

      VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
        Text(displayDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
          .font(EchoTypography.metadata)
          .tracking(0.7)
          .textCase(.uppercase)
          .foregroundStyle(world.secondaryText)

        HStack(alignment: .top, spacing: EchoLayout.inlineSpacing) {
          Text(day.entries.last?.rawText ?? "")
            .font(EchoTypography.body)
            .foregroundStyle(world.primaryText)
            .lineLimit(3)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)

          VStack(alignment: .trailing, spacing: EchoLayout.tightSpacing) {
            Text(entryCountLabel)
              .font(EchoTypography.metadata)
              .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(world.accent)
          }
        }
      }
      .padding(.bottom, showsContinuation ? EchoLayout.sectionSpacing : EchoLayout.surfacePadding)
    }
    .padding(.horizontal, EchoLayout.surfacePadding)
    .padding(.top, EchoLayout.surfacePadding)
    .accessibilityElement(children: .combine)
  }

  private var entryCountLabel: String {
    day.entryCount == 1 ? "1 entry" : "\(day.entryCount) entries"
  }
}
