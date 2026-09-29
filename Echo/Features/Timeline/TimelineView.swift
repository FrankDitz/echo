import SwiftUI

struct TimelineView: View {
  let viewModel: TimelineViewModel

  @Environment(\.timeZone) private var timeZone

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        header
        timelineContent
      }
      .frame(maxWidth: 720, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
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
    VStack(alignment: .leading, spacing: 6) {
      Text("Timeline")
        .font(.largeTitle.weight(.bold))
      Text("Previous days, kept in one quiet place.")
        .font(.title3)
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
        TimelineDayRow(day: day, timeZone: timeZone)
      }

      if viewModel.failure != nil {
        Label(
          "The timeline could not be refreshed. Showing the last loaded days.",
          systemImage: "exclamationmark.triangle"
        )
        .font(.footnote)
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
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Text(displayDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
          .font(.title3.weight(.semibold))
        Spacer()
        Text(entryCountLabel)
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
      }

      if let preview = day.entries.last?.rawText {
        Text(preview)
          .font(.body)
          .foregroundStyle(.secondary)
          .lineLimit(3)
          .lineSpacing(3)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(18)
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
    .overlay {
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
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
