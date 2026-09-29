import SwiftUI

struct TodayView: View {
  let viewModel: TodayViewModel

  @State private var draft = ""
  @FocusState private var isComposerFocused: Bool

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 28) {
        dateHeader
        quickComposer
        entrySection
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
  }

  private var dateHeader: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Today")
        .font(.largeTitle.weight(.bold))
      Text(
        viewModel.displayedDate.formatted(
          .dateTime.weekday(.wide).month(.wide).day().year()
        )
      )
      .font(.title3)
      .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private var quickComposer: some View {
    VStack(alignment: .leading, spacing: 14) {
      TextField("Write something…", text: $draft, axis: .vertical)
        .focused($isComposerFocused)
        .lineLimit(3...10)
        .textFieldStyle(.plain)
        .font(.body)
        .accessibilityLabel("New journal entry")

      Divider()

      HStack(spacing: 12) {
        saveStatus
        Spacer()
        Button("New Entry", systemImage: "plus") {
          submitDraft()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!containsWriting)
        .keyboardShortcut(.return, modifiers: [.command])
      }
    }
    .padding(18)
    .background(.background, in: RoundedRectangle(cornerRadius: 18))
    .overlay {
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
    }
  }

  @ViewBuilder
  private var saveStatus: some View {
    switch viewModel.saveState {
    case .idle:
      Text("⌘↩ to save")
        .foregroundStyle(.tertiary)
    case .saving:
      ProgressView()
        .controlSize(.small)
        .accessibilityLabel("Saving")
    case .saved:
      Label("Saved", systemImage: "checkmark.circle.fill")
        .foregroundStyle(.secondary)
    case .failed:
      Label("Not saved", systemImage: "exclamationmark.circle")
        .foregroundStyle(.red)
    }
  }

  private var entrySection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Today’s Entries")
        .font(.title2.weight(.semibold))

      if viewModel.isLoading && viewModel.entries.isEmpty {
        ProgressView("Loading today’s entries…")
          .frame(maxWidth: .infinity, minHeight: 160)
      } else if viewModel.entries.isEmpty {
        ContentUnavailableView(
          "A quiet day so far",
          systemImage: "text.page",
          description: Text("Write whenever there is something you want to remember.")
        )
        .frame(maxWidth: .infinity, minHeight: 220)
      } else {
        ForEach(viewModel.entries) { entry in
          TodayEntryRow(entry: entry)
          if entry.id != viewModel.entries.last?.id {
            Divider()
          }
        }
      }

      if let failureMessage {
        Label(failureMessage, systemImage: "exclamationmark.triangle")
          .font(.footnote)
          .foregroundStyle(.red)
      }
    }
  }

  private var containsWriting: Bool {
    draft.contains(where: { !$0.isWhitespace })
  }

  private var failureMessage: String? {
    switch viewModel.failure {
    case .loadEntries:
      "Today’s entries could not be loaded."
    case .createEntry:
      "This entry could not be saved. Your draft is still here."
    case .updateEntry:
      "The entry could not be updated."
    case .deleteEntry:
      "The entry could not be deleted."
    case nil:
      nil
    }
  }

  private func submitDraft() {
    let text = draft
    Task {
      if await viewModel.createEntry(rawText: text) {
        draft = ""
        isComposerFocused = true
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

private struct TodayEntryRow: View {
  let entry: EchoEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(entry.createdAt, format: .dateTime.hour().minute())
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(entry.rawText)
        .font(.body)
        .lineSpacing(4)
        .lineLimit(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}
