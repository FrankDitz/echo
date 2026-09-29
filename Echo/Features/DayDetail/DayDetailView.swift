import SwiftUI

struct DayDetailView: View {
  let day: EchoDay

  @Environment(\.timeZone) private var timeZone

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 28) {
        header
        entries
      }
      .frame(maxWidth: 720, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity)
    }
    .background(groupedBackground)
    .navigationTitle("Day Detail")
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(displayDate, format: .dateTime.weekday(.wide))
        .font(.title3.weight(.medium))
        .foregroundStyle(.secondary)
      Text(displayDate, format: .dateTime.month(.wide).day().year())
        .font(.largeTitle.weight(.bold))
      Text(entryCountLabel)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private var entries: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(day.entries) { entry in
        DayDetailEntry(entry: entry)
        if entry.id != day.entries.last?.id {
          Divider()
            .padding(.vertical, 20)
        }
      }
    }
    .padding(20)
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
    .overlay {
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
    }
  }

  private var displayDate: Date {
    day.id.date(in: timeZone) ?? day.entries[0].createdAt
  }

  private var entryCountLabel: String {
    day.entryCount == 1 ? "1 entry" : "\(day.entryCount) entries"
  }

  private var groupedBackground: Color {
    #if os(iOS)
      Color(uiColor: .systemGroupedBackground)
    #else
      Color(nsColor: .windowBackgroundColor)
    #endif
  }
}

private struct DayDetailEntry: View {
  let entry: EchoEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(entry.createdAt, format: .dateTime.hour().minute())
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(entry.rawText)
        .font(.body)
        .lineSpacing(5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }
    .accessibilityElement(children: .combine)
  }
}
