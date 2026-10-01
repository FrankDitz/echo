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
    EchoPage(spacing: EchoLayout.compactSectionSpacing) {
      promptHeader
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

  private var promptHeader: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      Text(
        viewModel.displayedDate.formatted(
          .dateTime.weekday(.wide).month(.wide).day().year()
        ).uppercased()
      )
      .font(EchoTypography.editorialEyebrow)
      .tracking(1.5)
      .foregroundStyle(.secondary)

      Text("What stayed with you?")
        .font(EchoTypography.editorialDisplay)
        .accessibilityAddTraits(.isHeader)
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .accessibilityElement(children: .combine)
  }

  private var entrySection: some View {
    EchoSurface(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("Raw entries")
            .font(EchoTypography.contentTitle)

          Spacer()

          if !viewModel.entries.isEmpty {
            Text(viewModel.entries.count, format: .number)
              .font(EchoTypography.metadata)
              .foregroundStyle(.secondary)
              .accessibilityLabel(
                "\(viewModel.entries.count) \(viewModel.entries.count == 1 ? "entry" : "entries")"
              )
          }
        }
        .padding(.horizontal, EchoLayout.surfacePadding)
        .padding(.vertical, EchoLayout.contentSpacing)

        Divider()

        if viewModel.isLoading && viewModel.entries.isEmpty {
          EchoLoadingState(
            title: "Loading today’s entries…",
            minHeight: EchoLayout.compactStateHeight
          )
          .padding(.horizontal, EchoLayout.surfacePadding)
        } else if viewModel.entries.isEmpty {
          EchoEmptyState(
            title: "A quiet day so far",
            systemImage: "text.page",
            description: "Write whenever there is something you want to remember.",
            minHeight: EchoLayout.compactStateHeight
          )
          .padding(.horizontal, EchoLayout.surfacePadding)
        } else {
          ForEach(viewModel.entries) { entry in
            TodayEntryRow(
              entry: entry,
              highlightViewModel: highlightViewModel,
              onOpen: { selectedEntry = entry },
              onDelete: { confirmDeletion(of: entry) }
            )
            .padding(.horizontal, EchoLayout.surfacePadding)
            if entry.id != viewModel.entries.last?.id {
              Divider()
                .padding(.leading, EchoLayout.surfacePadding)
            }
          }
        }

        if let failureMessage {
          EchoErrorState(message: failureMessage)
            .padding(EchoLayout.surfacePadding)
        }
      }
    }
  }

  @Environment(\.echoVisualWorld) private var world

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
  @Environment(\.echoVisualWorld) private var world

  @Binding var draft: String
  let isFocused: FocusState<Bool>.Binding
  let saveState: TodayEntrySaveState
  let onSubmit: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      HStack(alignment: .bottom, spacing: EchoLayout.rowSpacing) {
        Image(systemName: "square.and.pencil")
          .font(.body.weight(.semibold))
          .foregroundStyle(world.accent)
          .frame(minHeight: 32)

        TextField("Write a thought, moment, or idea…", text: $draft, axis: .vertical)
          .focused(isFocused)
          .lineLimit(1...6)
          .textFieldStyle(.plain)
          .font(EchoTypography.body)
          .accessibilityLabel("New journal entry")

        Button(action: onSubmit) {
          Image(systemName: "arrow.up")
            .font(.body.weight(.bold))
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .disabled(!containsWriting)
        .keyboardShortcut(.return, modifiers: [.command])
        .accessibilityLabel("Save entry")
      }
      .padding(.horizontal, EchoLayout.focusedContentInset)
      .padding(.vertical, EchoLayout.rowSpacing)
      .background {
        RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
          .fill(.ultraThinMaterial)
        RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
          .fill(world.surfaceFill)
      }
      .overlay {
        RoundedRectangle(cornerRadius: EchoShape.surfaceRadius)
          .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
      }
      .shadow(color: world.contentShadow.opacity(0.2), radius: 14, y: 6)

      HStack(spacing: EchoLayout.inlineSpacing) {
        saveStatus
        Spacer()
        #if os(macOS)
          Text("⌘↩ to save")
            .foregroundStyle(world.secondaryText)
        #endif
      }
      .font(EchoTypography.status)
      .padding(.horizontal, EchoLayout.microSpacing)
    }
  }

  @ViewBuilder
  private var saveStatus: some View {
    switch saveState {
    case .idle:
      Text("Private on this device")
        .foregroundStyle(world.secondaryText)
    case .saving:
      ProgressView()
        .controlSize(.small)
        .accessibilityLabel("Saving")
    case .saved:
      Label("Saved", systemImage: "checkmark.circle.fill")
        .foregroundStyle(world.saved)
    case .failed:
      Label("Not saved", systemImage: "exclamationmark.circle")
        .foregroundStyle(world.error)
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
      Text(entry.createdAt, format: .dateTime.hour().minute())
        .font(EchoTypography.metadata)
        .foregroundStyle(.secondary)
        .frame(width: 70, alignment: .leading)

      Button(action: onOpen) {
        Text(entry.rawText)
          .font(EchoTypography.body)
          .lineSpacing(4)
          .lineLimit(6)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
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
    .padding(.vertical, EchoLayout.rowSpacing)
    .contextMenu {
      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
      Button("Edit", systemImage: "pencil", action: onOpen)
      Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
    }
  }
}
