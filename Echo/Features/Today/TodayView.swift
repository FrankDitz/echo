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
    EchoWorldCanvas {
      GeometryReader { proxy in
        ScrollView {
          Group {
            if proxy.size.width >= EchoLayout.wideLayoutBreakpoint {
              wideContent(availableSize: proxy.size)
            } else {
              compactContent(availableHeight: proxy.size.height)
            }
          }
        }
        .scrollIndicators(.hidden)
      }
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

  private func compactContent(availableHeight: CGFloat) -> some View {
    LazyVStack(alignment: .leading, spacing: 20) {
      Color.clear
        .frame(height: heroOffset(for: availableHeight))
        .accessibilityHidden(true)

      promptHeader(isWide: false)
      captureControl
      entrySection(isWide: false)
    }
    .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
    .padding(.horizontal, EchoLayout.pageHorizontalPadding)
    .padding(.bottom, EchoLayout.pageVerticalPadding)
    .frame(maxWidth: .infinity)
    .frame(minHeight: availableHeight, alignment: .top)
  }

  private func wideContent(availableSize: CGSize) -> some View {
    VStack(alignment: .leading, spacing: 30) {
      HStack(spacing: EchoLayout.rowSpacing) {
        Capsule()
          .fill(world.accent)
          .frame(width: 30, height: 3)

        Text(
          viewModel.displayedDate.formatted(
            .dateTime.weekday(.wide).month(.wide).day().year()
          ).uppercased()
        )
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.8)
        .foregroundStyle(world.secondaryText)

        Spacer()

        Label("PRIVATE · ON DEVICE", systemImage: "lock.fill")
          .font(EchoTypography.metadata)
          .tracking(1.1)
          .foregroundStyle(world.secondaryText)
      }

      HStack(alignment: .top, spacing: 72) {
        VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
          promptHeader(isWide: true)
          captureControl
        }
        .frame(maxWidth: 610, alignment: .leading)

        entrySection(isWide: true)
          .frame(width: min(max(availableSize.width * 0.34, 390), 470))
      }
    }
    .frame(maxWidth: EchoLayout.wideContentMaxWidth, alignment: .leading)
    .padding(.horizontal, 40)
    .padding(.top, 92)
    .padding(.bottom, 64)
    .frame(maxWidth: .infinity, minHeight: availableSize.height, alignment: .top)
  }

  private func promptHeader(isWide: Bool) -> some View {
    Text("What stayed with you?")
      .font(isWide ? EchoTypography.wideEditorialPrompt : EchoTypography.editorialPrompt)
      .accessibilityAddTraits(.isHeader)
      .shadow(color: world.contentShadow, radius: 8, y: 2)
  }

  private var captureControl: some View {
    TodayCaptureControl(
      draft: $draft,
      isFocused: $isComposerFocused,
      saveState: viewModel.saveState,
      onSubmit: submitDraft
    )
  }

  private func entrySection(isWide: Bool) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("Raw entries")
          .font(.headline.weight(.semibold))

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
          minHeight: 104
        )
        .padding(.horizontal, EchoLayout.surfacePadding)
      } else if viewModel.entries.isEmpty {
        VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
          Text("A quiet day so far")
            .font(EchoTypography.body.weight(.semibold))
          Text("Write whenever there is something you want to remember.")
            .font(EchoTypography.supporting)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EchoLayout.surfacePadding)
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
    .background {
      if isWide {
        RoundedRectangle(cornerRadius: 14)
          .fill(.ultraThinMaterial)
        RoundedRectangle(cornerRadius: 14)
          .fill(world.surfaceFill.opacity(0.72))
      } else {
        Rectangle()
          .fill(world.canvas.opacity(0.18))
      }
    }
    .overlay {
      if isWide {
        RoundedRectangle(cornerRadius: 14)
          .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
      } else {
        VStack(spacing: 0) {
          Rectangle()
            .fill(world.separator)
            .frame(height: EchoShape.hairlineWidth)
          Spacer()
          Rectangle()
            .fill(world.separator.opacity(0.65))
            .frame(height: EchoShape.hairlineWidth)
        }
      }
    }
    .shadow(
      color: world.contentShadow.opacity(isWide ? 0.16 : 0.12),
      radius: isWide ? 16 : 8,
      y: isWide ? 6 : 3
    )
  }

  @Environment(\.echoVisualWorld) private var world
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private func heroOffset(for availableHeight: CGFloat) -> CGFloat {
    if horizontalSizeClass == .compact {
      return min(max(availableHeight * 0.34, 140), 286)
    }
    return min(max(availableHeight * 0.27, 96), 230)
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
  @Environment(\.echoVisualWorld) private var world

  @Binding var draft: String
  let isFocused: FocusState<Bool>.Binding
  let saveState: TodayEntrySaveState
  let onSubmit: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      HStack(spacing: EchoLayout.rowSpacing) {
        Image(systemName: "square.and.pencil")
          .font(.body.weight(.medium))
          .foregroundStyle(world.accent)
          .frame(width: 26, height: 28)
          .accessibilityHidden(true)

        Rectangle()
          .fill(world.separator)
          .frame(width: EchoShape.hairlineWidth, height: 30)

        TextField("Type a thought…", text: $draft, axis: .vertical)
          .focused(isFocused)
          .lineLimit(1...4)
          .textFieldStyle(.plain)
          .font(EchoTypography.body)
          .accessibilityLabel("New journal entry")

        Button(action: onSubmit) {
          Image(systemName: "arrow.up")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(world.canvas)
            .frame(width: 38, height: 38)
            .background(world.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!containsWriting)
        .opacity(containsWriting ? 1 : 0.48)
        .keyboardShortcut(.return, modifiers: [.command])
        .accessibilityLabel("Save entry")
      }
      .padding(.leading, EchoLayout.contentSpacing)
      .padding(.trailing, EchoLayout.tightSpacing)
      .padding(.vertical, EchoLayout.tightSpacing)
      .background {
        Capsule()
          .fill(.ultraThinMaterial)
        Capsule()
          .fill(world.canvas.opacity(0.3))
      }
      .overlay {
        Capsule()
          .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
      }
      .shadow(color: world.contentShadow.opacity(0.2), radius: 12, y: 5)

      if saveState != .idle {
        saveStatus
          .font(EchoTypography.status)
          .padding(.horizontal, EchoLayout.contentSpacing)
      }
    }
  }

  @ViewBuilder
  private var saveStatus: some View {
    switch saveState {
    case .idle:
      EmptyView()
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
          .lineLimit(3)
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
    .padding(.vertical, EchoLayout.contentSpacing)
    .contextMenu {
      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
      Button("Edit", systemImage: "pencil", action: onOpen)
      Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
    }
  }
}
