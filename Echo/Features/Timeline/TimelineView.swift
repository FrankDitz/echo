import SwiftUI

struct TimelineView: View {
  let viewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository

  @Environment(\.timeZone) private var timeZone

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: EchoLayout.compactSectionSpacing) {
        header
        timelineContent
      }
      .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
      .padding(.horizontal, EchoLayout.pageHorizontalPadding)
      .padding(.vertical, EchoLayout.pageVerticalPadding)
      .frame(maxWidth: .infinity)
    }
    .background(groupedBackground)
    .task {
      await viewModel.load()
    }
    .refreshable {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
      Text("Timeline")
        .font(EchoTypography.screenTitle)
      Text("Previous days, kept in one quiet place.")
        .font(EchoTypography.screenSubtitle)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var timelineContent: some View {
    if viewModel.isLoading && viewModel.days.isEmpty {
      ProgressView("Loading your timeline…")
        .frame(maxWidth: .infinity, minHeight: 280)
    } else if viewModel.days.isEmpty {
      ContentUnavailableView(
        "Your story starts here",
        systemImage: "clock.arrow.circlepath",
        description: Text("Days with journal entries will gather here over time.")
      )
      .frame(maxWidth: .infinity, minHeight: 320)
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
          TimelineDayRow(day: day, timeZone: timeZone)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this day’s entries")
      }

      if viewModel.failure != nil {
        Label(
          "The timeline could not be refreshed. Showing the last loaded days.",
          systemImage: "exclamationmark.triangle"
        )
        .font(EchoTypography.status)
        .foregroundStyle(.red)
      }
    }
  }

  private var groupedBackground: Color {
    #if os(iOS)
      Color(uiColor: .systemGroupedBackground)
    #else
      Color(nsColor: .windowBackgroundColor)
    #endif
  }
}

private struct TimelineDayRow: View {
  let day: EchoDay
  let timeZone: TimeZone

  var body: some View {
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
    .padding(EchoLayout.surfacePadding)
    .background(.background, in: RoundedRectangle(cornerRadius: EchoShape.surfaceRadius))
    .overlay {
      RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
        .stroke(
          Color.secondary.opacity(EchoMaterialMetrics.subtleBorderOpacity),
          lineWidth: EchoShape.hairlineWidth
        )
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
