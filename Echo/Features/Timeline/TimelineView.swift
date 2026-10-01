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
    EchoPage(spacing: EchoLayout.compactSectionSpacing) {
      timelineHeader
      timelineContent
    }
    .task {
      await viewModel.load()
    }
    .refreshable {
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
  private var timelineContent: some View {
    if viewModel.isLoading && viewModel.days.isEmpty {
      EchoLoadingState(title: "Loading your timeline…")
    } else {
      recentDateStrip

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

  private var recentDateStrip: some View {
    EchoSurface(padding: 0) {
      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
        Label(
          stripAnchorDate.formatted(.dateTime.month(.wide).year()),
          systemImage: "calendar"
        )
        .font(EchoTypography.metadata)
        .foregroundStyle(.secondary)
        .padding(.horizontal, EchoLayout.surfacePadding)
        .padding(.top, EchoLayout.contentSpacing)

        ScrollView(.horizontal) {
          LazyHStack(spacing: EchoLayout.inlineSpacing) {
            ForEach(dateStripDates, id: \.self) { date in
              if let day = day(for: date) {
                NavigationLink {
                  destination(for: day)
                } label: {
                  TimelineDateTile(
                    date: date,
                    isLatest: day.id == viewModel.days.first?.id,
                    hasEntries: true
                  )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens this day’s entries")
              } else {
                TimelineDateTile(
                  date: date,
                  isLatest: false,
                  hasEntries: false
                )
              }
            }
          }
          .padding(.horizontal, EchoLayout.surfacePadding)
          .padding(.bottom, EchoLayout.contentSpacing)
        }
        .scrollIndicators(.hidden)
      }
    }
  }

  private var timelineRail: some View {
    EchoSurface(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("Journal days")
            .font(EchoTypography.contentTitle)
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

        Divider()

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
    }
  }

  private var stripAnchorDate: Date {
    viewModel.days.first.map(displayDate(for:)) ?? viewModel.mostRecentTimelineDate
  }

  private var dateStripDates: [Date] {
    (-6...0).compactMap { offset in
      calendar.date(byAdding: .day, value: offset, to: stripAnchorDate)
    }
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

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    VStack(spacing: EchoLayout.tightSpacing) {
      Text(date, format: .dateTime.weekday(.abbreviated))
        .font(EchoTypography.metadata)
        .textCase(.uppercase)
      Text(date, format: .dateTime.day())
        .font(.title2.weight(.semibold))
    }
    .foregroundStyle(tileForeground)
    .frame(width: 54)
    .frame(minHeight: 62)
    .background(isLatest ? world.accent : world.selectedFill, in: RoundedRectangle(cornerRadius: 14))
    .overlay {
      if !isLatest {
        RoundedRectangle(cornerRadius: 14)
          .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
      }
    }
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
          .frame(width: 12, height: 12)
          .overlay {
            Circle().stroke(world.primaryText.opacity(0.55), lineWidth: 2)
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
        HStack(alignment: .firstTextBaseline) {
          Text(displayDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
            .font(EchoTypography.contentTitle)
          Spacer(minLength: EchoLayout.inlineSpacing)
          Text(entryCountLabel)
            .font(EchoTypography.metadata)
            .foregroundStyle(.secondary)
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
        }

        Text(day.entries.last?.rawText ?? "")
          .font(EchoTypography.body)
          .foregroundStyle(.secondary)
          .lineLimit(3)
          .lineSpacing(3)
          .frame(maxWidth: .infinity, alignment: .leading)
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
