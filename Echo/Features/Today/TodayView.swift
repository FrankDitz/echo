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
    ScrollView {
      LazyVStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
        dateHeader
        quickComposer
        entrySection
      }
      .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
      .padding(.horizontal, EchoLayout.pageHorizontalPadding)
      .padding(.vertical, EchoLayout.pageVerticalPadding)
      .frame(maxWidth: .infinity)
    }
    .background(groupedBackground)
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

  private var dateHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
      Text("Today")
        .font(EchoTypography.screenTitle)
      Text(
        viewModel.displayedDate.formatted(
          .dateTime.weekday(.wide).month(.wide).day().year()
        )
      )
      .font(EchoTypography.screenSubtitle)
      .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private var quickComposer: some View {
    VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
      TextField("Write something…", text: $draft, axis: .vertical)
        .focused($isComposerFocused)
        .lineLimit(3...10)
        .textFieldStyle(.plain)
        .font(EchoTypography.body)
        .accessibilityLabel("New journal entry")

      Divider()

      HStack(spacing: EchoLayout.rowSpacing) {
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
    .padding(EchoLayout.surfacePadding)
    .background(.background, in: RoundedRectangle(cornerRadius: EchoShape.surfaceRadius))
    .overlay {
      RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
        .stroke(
          Color.secondary.opacity(EchoMaterialMetrics.subtleBorderOpacity),
          lineWidth: EchoShape.hairlineWidth
        )
    }
  }

  @ViewBuilder
  private var saveStatus: some View {
    switch viewModel.saveState {
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

  private var entrySection: some View {
    VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
      Text("Today’s Entries")
        .font(EchoTypography.sectionTitle)

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
        Label(failureMessage, systemImage: "exclamationmark.triangle")
          .font(EchoTypography.status)
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
  let highlightViewModel: EntryHighlightViewModel
  let onOpen: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.rowSpacing) {
      Button(action: onOpen) {
        VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
          Text(entry.createdAt, format: .dateTime.hour().minute())
            .font(EchoTypography.metadata)
            .foregroundStyle(.secondary)
          Text(entry.rawText)
            .font(EchoTypography.body)
            .lineSpacing(4)
            .lineLimit(6)
            .frame(maxWidth: .infinity, alignment: .leading)
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
