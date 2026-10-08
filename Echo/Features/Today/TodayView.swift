import SwiftUI

struct TodayView: View {
  let viewModel: TodayViewModel
  let highlightViewModel: EntryHighlightViewModel
  let aiService: any EchoAIService
  let voiceCaptureViewModel: VoiceCaptureViewModel

  @State private var draft = ""
  @State private var marksNextEntryImportant = false
  @State private var selectedEntry: EchoEntry?
  @State private var entryPendingDeletion: EchoEntry?
  @State private var isConfirmingDeletion = false
  @FocusState private var isComposerFocused: Bool

  var body: some View {
    EchoWorldCanvas(screen: .today) {
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
      await carryForwardViewModel.loadToday()
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
      .echoPrivacyProtected()
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
      todayHero(isWide: false)
      promptHeader(isWide: false)
      carryForwardCard
      captureControl
      quickCaptureActions
      voiceStatus
      entrySection(isWide: false)
      memorySection
    }
    .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
    .padding(.horizontal, EchoLayout.pageHorizontalPadding)
    .padding(.bottom, EchoLayout.pageVerticalPadding)
    .frame(maxWidth: .infinity)
    .frame(minHeight: max(availableHeight, 0), alignment: .top)
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
          todayHero(isWide: true)
          promptHeader(isWide: true)
          carryForwardCard
          captureControl
          quickCaptureActions
          voiceStatus
          memorySection
        }
        .frame(maxWidth: 610, alignment: .leading)

        entrySection(isWide: true)
          .frame(width: min(max(availableSize.width * 0.34, 390), 470))
      }

    }
    .frame(maxWidth: EchoLayout.wideContentMaxWidth, alignment: .leading)
    .padding(.horizontal, 40)
    .padding(.top, 44)
    .padding(.bottom, 64)
    .frame(maxWidth: .infinity, minHeight: max(availableSize.height, 0), alignment: .top)
  }

  private func promptHeader(isWide: Bool) -> some View {
    Text("What stayed with you?")
      .font(isWide ? EchoTypography.wideEditorialPrompt : EchoTypography.editorialPrompt)
      .accessibilityAddTraits(.isHeader)
      .shadow(color: world.contentShadow, radius: 8, y: 2)
  }

  private func todayHero(isWide: Bool) -> some View {
    VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
      Text(
        viewModel.displayedDate.formatted(
          .dateTime.month(.abbreviated).day().year().weekday(.abbreviated)
        ).uppercased()
      )
      .font(EchoTypography.editorialEyebrow)
      .tracking(1.8)
      .foregroundStyle(world.accent)

      Text("Today")
        .font(
          isWide
            ? .system(size: 68, weight: .black, design: .serif)
            : .system(size: 52, weight: .black, design: .serif)
        )
        .accessibilityAddTraits(.isHeader)

      Text("BE WITH GOD. BE PRESENT. WRITE IT DOWN.")
        .font(EchoTypography.editorialEyebrow)
        .tracking(1.7)
        .foregroundStyle(world.primaryText.opacity(0.86))
    }
    .shadow(color: world.contentShadow, radius: 10, y: 3)
    .padding(.top, isWide ? 0 : 24)
    .accessibilityElement(children: .combine)
  }

  private var quickCaptureActions: some View {
    HStack(spacing: EchoLayout.inlineSpacing) {
      quickCaptureButton("Write", systemImage: EchoIcon.write) {
        isComposerFocused = true
      }
      quickCaptureButton(
        voiceCaptureViewModel.state == .recording ? "Stop" : "Voice",
        systemImage: voiceCaptureViewModel.state == .recording ? "stop.fill" : "waveform"
      ) {
        voiceAction()
      }
      quickCaptureButton(
        marksNextEntryImportant ? "Important" : "Mark Important",
        systemImage: marksNextEntryImportant ? "bookmark.fill" : "bookmark"
      ) {
        marksNextEntryImportant.toggle()
      }
    }
  }

  private func quickCaptureButton(
    _ title: String,
    systemImage: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .font(EchoTypography.metadata.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .frame(maxWidth: .infinity, minHeight: 42)
        .background(world.surfaceFill.opacity(0.88), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
        }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var carryForwardCard: some View {
    if let item = carryForwardViewModel.todayItem {
      EchoReadabilityPanel {
        HStack(alignment: .top, spacing: EchoLayout.contentSpacing) {
          Image(systemName: "arrow.turn.down.right")
            .font(.title3.weight(.semibold))
            .foregroundStyle(world.accent)
            .frame(width: 28)

          VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
            Text("CARRIED FORWARD")
              .font(EchoTypography.editorialEyebrow)
              .tracking(1.4)
              .foregroundStyle(world.accent)
            Text(item.text)
              .font(EchoTypography.contentTitle)
              .lineSpacing(3)
              .textSelection(.enabled)
            Text(carryForwardSourceLabel(for: item.sourceKind))
              .font(EchoTypography.metadata)
              .foregroundStyle(world.secondaryText)
          }

          Spacer(minLength: EchoLayout.tightSpacing)

          Button("Release") {
            Task { await carryForwardViewModel.releaseToday() }
          }
          .font(EchoTypography.metadata.weight(.semibold))
          .buttonStyle(.borderless)
          .foregroundStyle(world.accent)
          .accessibilityHint("Removes this thought from Today without deleting its source")
        }
      }
      .accessibilityElement(children: .contain)
    }
  }

  private func carryForwardSourceLabel(for kind: EchoCarryForwardSourceKind) -> String {
    switch kind {
    case .dayReflectionQuestion:
      "From a reflection question"
    case .dayReflectionKeyMoment:
      "From a key moment"
    case .weeklyReflectionQuestion:
      "From your weekly reflection"
    case .entry:
      "From an original entry"
    default:
      "From an earlier reflection"
    }
  }

  private var captureControl: some View {
    TodayCaptureControl(
      draft: $draft,
      markImportant: $marksNextEntryImportant,
      isFocused: $isComposerFocused,
      saveState: viewModel.saveState,
      onSubmit: submitDraft,
      onVoiceAction: voiceAction,
      isRecording: voiceCaptureViewModel.state == .recording
    )
  }

  @ViewBuilder
  private var voiceStatus: some View {
    if let message = voiceCaptureViewModel.statusMessage {
      Label(message, systemImage: voiceStatusIcon)
        .font(EchoTypography.metadata)
        .foregroundStyle(
          voiceCaptureViewModel.state == .failed
            || voiceCaptureViewModel.state == .permissionDenied ? world.error : world.secondaryText
        )
        .padding(.horizontal, EchoLayout.contentSpacing)
    }
  }

  private var voiceStatusIcon: String {
    switch voiceCaptureViewModel.state {
    case .recording: "record.circle.fill"
    case .processing: "waveform.badge.magnifyingglass"
    case .ready: "checkmark.circle.fill"
    case .playing: "speaker.wave.2.fill"
    case .permissionDenied, .failed: "exclamationmark.circle"
    case .idle, .requestingPermission: "mic"
    }
  }

  private func voiceAction() {
    Task {
      if voiceCaptureViewModel.state == .recording {
        if let entry = await voiceCaptureViewModel.stopAndSave() {
          await viewModel.load()
          if marksNextEntryImportant {
            await viewModel.markImportant(entryID: entry.id)
          }
          marksNextEntryImportant = false
          await highlightViewModel.load()
          if await voiceCaptureViewModel.awaitPendingRefinement() != nil {
            await viewModel.load()
          }
        }
      } else {
        await voiceCaptureViewModel.start()
      }
    }
  }

  private func entrySection(isWide: Bool) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("Entries")
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
        ForEach(Array(viewModel.entries.reversed())) { entry in
          TodayEntryRow(
            entry: entry,
            highlightViewModel: highlightViewModel,
            onPlay: entry.type == .voice
              ? {
                Task { await voiceCaptureViewModel.play(entryID: entry.id) }
              } : nil,
            onOpen: { selectedEntry = entry },
            onDelete: { confirmDeletion(of: entry) },
            onRetryRefinement: { viewModel.retryRefinement(entryID: entry.id) },
            onAcceptRefinement: {
              Task { await viewModel.acceptRefinement(entryID: entry.id) }
            },
            onDiscardRefinement: {
              Task { await viewModel.discardRefinement(entryID: entry.id) }
            }
          )
          .padding(.horizontal, EchoLayout.surfacePadding)
          if entry.id != viewModel.entries.first?.id {
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

  private var memorySection: some View {
    TodayMemorySection(
      snapshot: viewModel.memories,
      isLoading: viewModel.isLoadingMemories,
      onOpen: { selectedEntry = $0 }
    )
  }

  @Environment(\.echoVisualWorld) private var world
  @Environment(CarryForwardViewModel.self) private var carryForwardViewModel

  private var failureMessage: String? {
    switch viewModel.failure {
    case .loadEntries:
      "Today’s entries could not be loaded."
    case .createEntry:
      "This entry could not be saved. Your draft is still here."
    case .highlightEntry:
      "The entry was saved, but it could not be marked important."
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
      if await viewModel.createEntry(
        rawText: text,
        markImportant: marksNextEntryImportant
      ) {
        draft = ""
        marksNextEntryImportant = false
        await highlightViewModel.load()
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

private struct TodayMemorySection: View {
  let snapshot: TodayMemorySnapshot
  let isLoading: Bool
  let onOpen: (EchoEntry) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
      VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
        Text("MEMORY SIGNALS")
          .font(EchoTypography.editorialEyebrow)
          .tracking(1.5)
          .foregroundStyle(.secondary)
        Text("A few things worth meeting again.")
          .font(EchoTypography.sectionTitle)
      }

      if isLoading {
        EchoLoadingState(title: "Looking through your private journal…", minHeight: 80)
      } else if populatedLanes.isEmpty {
        EchoReadabilityPanel {
          Label("Your memories will gather here as you write.", systemImage: "sparkles")
            .font(EchoTypography.supporting)
            .foregroundStyle(world.secondaryText)
        }
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: EchoLayout.contentSpacing) {
            ForEach(populatedLanes) { lane in
              memoryLane(lane)
                .containerRelativeFrame(.horizontal, count: 1, spacing: EchoLayout.contentSpacing)
            }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
      }
    }
  }

  private var populatedLanes: [MemoryLane] {
    [
      MemoryLane(
        title: "On this day",
        systemImage: "calendar.badge.clock",
        entries: snapshot.onThisDay
      ),
      MemoryLane(
        title: "Unfinished thoughts",
        systemImage: "ellipsis.bubble",
        entries: snapshot.unfinished
      ),
      MemoryLane(
        title: "Saved memories",
        systemImage: "bookmark",
        entries: snapshot.saved
      ),
    ]
    .filter { !$0.entries.isEmpty }
  }

  private func memoryLane(_ lane: MemoryLane) -> some View {
    EchoReadabilityPanel {
      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
        Label(lane.title, systemImage: lane.systemImage)
          .font(EchoTypography.contentTitle)
          .foregroundStyle(world.accent)

        ForEach(lane.entries) { entry in
          Button {
            onOpen(entry)
          } label: {
            VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
              Text(entry.preferredText)
                .font(EchoTypography.supporting)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
              Text(entry.createdAt, format: .dateTime.month(.abbreviated).day().year())
                .font(EchoTypography.metadata)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          if entry.id != lane.entries.last?.id { Divider() }
        }
      }
    }
  }

  private struct MemoryLane: Identifiable {
    let title: String
    let systemImage: String
    let entries: [EchoEntry]

    var id: String { title }
  }

  @Environment(\.echoVisualWorld) private var world
}

private struct TodayCaptureControl: View {
  @Environment(\.echoVisualWorld) private var world

  @Binding var draft: String
  @Binding var markImportant: Bool
  let isFocused: FocusState<Bool>.Binding
  let saveState: TodayEntrySaveState
  let onSubmit: () -> Void
  let onVoiceAction: () -> Void
  let isRecording: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
      HStack(spacing: EchoLayout.rowSpacing) {
        Image(systemName: EchoIcon.write)
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

        Button {
          markImportant.toggle()
        } label: {
          Image(systemName: markImportant ? "bookmark.fill" : "bookmark")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(markImportant ? world.canvas : world.accent)
            .frame(width: 38, height: 38)
            .background(
              markImportant ? world.accent : world.canvas.opacity(0.18),
              in: Circle()
            )
            .overlay {
              Circle().stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          markImportant ? "Remove important marker from next entry" : "Mark next entry important"
        )
        .accessibilityValue(markImportant ? "On" : "Off")
        .help("Mark this thought important")

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

        Button(action: onVoiceAction) {
          Image(systemName: isRecording ? "stop.fill" : "mic.fill")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isRecording ? .white : world.canvas)
            .frame(width: 38, height: 38)
            .background(isRecording ? world.error : world.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop and save recording" : "Record voice entry")
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
        .symbolEffect(.bounce, value: saveState)
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
  let onPlay: (() -> Void)?
  let onOpen: () -> Void
  let onDelete: () -> Void
  let onRetryRefinement: () -> Void
  let onAcceptRefinement: () -> Void
  let onDiscardRefinement: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: EchoLayout.rowSpacing) {
      Text(entry.createdAt, format: .dateTime.hour().minute())
        .font(EchoTypography.metadata)
        .foregroundStyle(.secondary)
        .frame(width: 70, alignment: .leading)

      VStack(alignment: .leading, spacing: EchoLayout.microSpacing) {
        Button(action: onOpen) {
          Text(entry.preferredText)
            .font(EchoTypography.body)
            .lineSpacing(4)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the entry editor")

        refinementStatus
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if let onPlay {
        Button(action: onPlay) {
          Image(systemName: "play.fill")
            .foregroundStyle(world.accent)
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play voice entry")
      }

      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .font(.body)
        .foregroundStyle(world.accent)

      Menu("Entry Actions", systemImage: "ellipsis") {
        Button("Edit", systemImage: "pencil", action: onOpen)
        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
      }
      .labelStyle(.iconOnly)
      .accessibilityLabel("Entry actions")
    }
    .padding(.vertical, EchoLayout.contentSpacing)
    .padding(.horizontal, highlightViewModel.isHighlighted(entry.id) ? EchoLayout.tightSpacing : 0)
    .background {
      if highlightViewModel.isHighlighted(entry.id) {
        RoundedRectangle(cornerRadius: 10)
          .fill(world.accent.opacity(0.09))
      }
    }
    .overlay(alignment: .leading) {
      if highlightViewModel.isHighlighted(entry.id) {
        Capsule()
          .fill(world.accent)
          .frame(width: 3)
          .padding(.vertical, EchoLayout.tightSpacing)
          .accessibilityHidden(true)
      }
    }
    .contextMenu {
      EntryHighlightButton(entryID: entry.id, viewModel: highlightViewModel)
      Button("Edit", systemImage: "pencil", action: onOpen)
      Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
    }
  }

  @ViewBuilder
  private var refinementStatus: some View {
    switch entry.refinementStatus {
    case .notRequested:
      EmptyView()
    case .processing:
      Label("Refining…", systemImage: "sparkles")
        .foregroundStyle(world.accent)
    case .refined:
      Label("Cleaned up", systemImage: "checkmark.circle")
        .foregroundStyle(world.secondaryText)
    case .needsReview:
      HStack(spacing: EchoLayout.inlineSpacing) {
        Button("Review", action: onOpen)
        Button("Use", action: onAcceptRefinement)
        Button("Keep Original", action: onDiscardRefinement)
      }
      .buttonStyle(.borderless)
      .foregroundStyle(world.accent)
    case .failed:
      Button("Retry cleanup", systemImage: "arrow.clockwise", action: onRetryRefinement)
        .buttonStyle(.borderless)
        .foregroundStyle(world.error)
    }
  }

  @Environment(\.echoVisualWorld) private var world
}
