import SwiftUI

struct TimelineView: View {
  let viewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @Environment(\.timeZone) private var timeZone

  var body: some View {
    EchoPage(spacing: EchoLayout.compactSectionSpacing) {
      EchoScreenHeader(
        title: "Timeline",
        subtitle: "Previous days, kept in one quiet place."
      )
      timelineContent
    }
    .task {
      await viewModel.load()
    }
    .refreshable {
      await viewModel.load()
    }
  }

  @ViewBuilder
  private var timelineContent: some View {
    if viewModel.isLoading && viewModel.days.isEmpty {
      EchoLoadingState(title: "Loading your timeline…")
    } else if viewModel.days.isEmpty {
      EchoEmptyState(
        title: "Your story starts here",
        systemImage: "clock.arrow.circlepath",
        description: "Days with journal entries will gather here over time."
      )
    } else {
      ForEach(viewModel.days) { day in
        NavigationLink {
          DayDetailView(
            day: day,
            highlightViewModel: highlightViewModel,
            aiService: aiService,
            journalRepository: journalRepository
          )
        } label: {
          TimelineDayNavigationRow(day: day, timeZone: timeZone)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this day’s entries")
      }

      if viewModel.failure != nil {
        EchoErrorState(
          message: "The timeline could not be refreshed. Showing the last loaded days."
        )
      }
    }
  }
}

private struct TimelineDayNavigationRow: View {
  let day: EchoDay
  let timeZone: TimeZone

  var body: some View {
    EchoSurface {
      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
        HStack(alignment: .firstTextBaseline) {
          Text(displayDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
            .font(EchoTypography.contentTitle)
          Spacer()
          Text(entryCountLabel)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
        }

        if let preview = day.entries.last?.rawText {
          Text(preview)
            .font(EchoTypography.body)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var displayDate: Date {
    day.id.date(in: timeZone) ?? day.entries[0].createdAt
  }

  private var entryCountLabel: String {
    day.entryCount == 1 ? "1 entry" : "\(day.entryCount) entries"
  }
}
