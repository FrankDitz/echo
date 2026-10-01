import SwiftUI

struct TodayView: View {
  let viewModel: TodayViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService

  @State private var draft = ""
  @State private var selectedEntry: EchoEntry?
  @State private var entryPendingDeletion: EchoEntry?
  @State private var isConfirmingDeletion = false
  @FocusState private var isComposerFocused: Bool

  var body: some View {
    EchoPage(spacing: EchoLayout.sectionSpacing) {
      EchoScreenHeader(
        title: "Today",
        subtitle: viewModel.displayedDate.formatted(
          .dateTime.weekday(.wide).month(.wide).day().year()
        )
      )
      TodayCaptureControl(
        draft: $draft,
        isFocused: $isComposerFocused,
        saveState: viewModel.saveState,
        onSubmit: submitDraft
      )
      entrySection
    }
    .task {
      await viewModel.load()
      await highlightViewModel.load()
    }
    .sheet(item: $selectedEntry) { entry in
      EntryEditorView(
        entry: entry,
        aiService: aiService,
        onSave: { rawText in
          await viewModel.updateEntry(id: entry.id, rawText: rawText)
        },
        onSaveAssistedText: { text in
          await viewModel.saveAssistedText(entryID: entry.id, text: text)
        }
      )
    }
    .confirmationDialog(
      "Delete this entry?",
      isPresented: $isConfirmingDeletion,
      titleVisibility: .visible
    ) {
      Button("Delete Entry", role: .destructive) {
        deletePendingEntry()
      }
      Button("Cancel", role: .cancel) {
        entryPendingDeletion = nil
      }
    } message: {
      Text("This permanently removes the entry from Echo and cannot be undone.")
    }
  }

  private var entrySection: some View {
    VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
      Text("Today’s Entries")
        .font(EchoTypography.sectionTitle)

      if viewModel.isLoading && viewModel.entries.isEmpty {
        EchoLoadingState(
          title: "Loading today’s entries…",
          minHeight: EchoLayout.compactStateHeight
        )
      } else if viewModel.entries.isEmpty {
        EchoEmptyState(
          title: "A quiet day so far",
          systemImage: "text.page",
          description: "Write whenever there is something you want to remember.",
          minHeight: EchoLayout.mediumStateHeight
        )
      } else {
        ForEach(viewModel.entries) { entry in
          TodayEntryRow(
            entry: entry,
            highlightViewModel: highlightViewModel,
            onOpen: { selectedEntry = entry },
            onDelete: { confirmDeletion(of: entry) }
          )
          if entry.id != viewModel.entries.last?.id {
            Divider()
          }
        }
      }

      if let failureMessage {
        EchoErrorState(message: failureMessage)
      }
    }
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

  private func confirmDeletion(of entry: EchoEntry) {
    entryPendingDeletion = entry
    isConfirmingDeletion = true
  }

  private func deletePendingEntry() {
    guard let entry = entryPendingDeletion else { return }
    entryPendingDeletion = nil

    Task {
      if await viewModel.deleteEntry(id: entry.id), selectedEntry?.id == entry.id {
        selectedEntry = nil
      }
    }
  }
}

private struct TodayCaptureControl: View {
  @Binding var draft: String
  let isFocused: FocusState<Bool>.Binding
  let saveState: TodayEntrySaveState
  let onSubmit: () -> Void

  var body: some View {
    EchoSurface {
      VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
        TextField("Write something…", text: $draft, axis: .vertical)
          .focused(isFocused)
          .lineLimit(3...10)
          .textFieldStyle(.plain)
          .font(EchoTypography.body)
          .accessibilityLabel("New journal entry")

        Divider()

        HStack(spacing: EchoLayout.rowSpacing) {
          saveStatus
          Spacer()
          Button("New Entry", systemImage: "plus", action: onSubmit)
            .buttonStyle(.borderedProminent)
            .disabled(!containsWriting)
            .keyboardShortcut(.return, modifiers: [.command])
        }
      }
    }
  }

  @ViewBuilder
  private var saveStatus: some View {
    switch saveState {
    case .idle:
      #if os(macOS)
        Text("⌘↩ to save")
          .foregroundStyle(.tertiary)
      #else
        Text("Ready when you are")
          .foregroundStyle(.tertiary)
      #endif
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

  private var containsWriting: Bool {
    draft.contains(where: { !$0.isWhitespace })
  }
}

private struct TodayEntryRow: View {
  let entry: EchoEntry
  let highlightViewModel: EntryHighlightViewModel
  let onOpen: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.rowSpacing) {
      Button(action: onOpen) {
        EchoEntryPresentation(text: entry.rawText, lineLimit: 6) {
          Text(entry.createdAt, format: .dateTime.hour().minute())
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Opens the entry editor")

      Menu("Entry Actions", systemImage: "ellipsis") {
        EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
        Button("Edit", systemImage: "pencil", action: onOpen)
        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
      }
      .labelStyle(.iconOnly)
      .accessibilityLabel("Entry actions")
    }
    .padding(.vertical, EchoLayout.microSpacing)
    .contextMenu {
      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
      Button("Edit", systemImage: "pencil", action: onOpen)
      Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
    }
  }
}
