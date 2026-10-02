import SwiftUI

struct EntryEditorView: View {
  let entry: EchoEntry
  let aiService: any EchoAIService
  let onSave: (String) async -> Bool
  let onSaveAssistedText: (String) async -> Bool

  @Environment(\.dismiss) private var dismiss
  @Environment(\.echoVisualWorld) private var world
  @FocusState private var isEditorFocused: Bool
  @State private var draft: String
  @State private var savedText: String
  @State private var isSaving = false
  @State private var didSave = false
  @State private var saveFailed = false
  @State private var isConfirmingDiscard = false
  @State private var assistedText: String?
  @State private var isGeneratingAssistance = false
  @State private var assistanceFailed = false

  init(
    entry: EchoEntry,
    aiService: any EchoAIService,
    onSave: @escaping (String) async -> Bool,
    onSaveAssistedText: @escaping (String) async -> Bool
  ) {
    self.entry = entry
    self.aiService = aiService
    self.onSave = onSave
    self.onSaveAssistedText = onSaveAssistedText
    _draft = State(initialValue: entry.rawText)
    _savedText = State(initialValue: entry.rawText)
    _assistedText = State(initialValue: entry.polishedText)
  }

  var body: some View {
    EchoWorldCanvas {
      GeometryReader { proxy in
        let isWide = proxy.size.width >= 760

        VStack(spacing: 0) {
          editorHeader(isWide: isWide)

          ScrollView {
            VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
              writingCanvas(isWide: isWide)
              assistanceSection
            }
            .frame(maxWidth: isWide ? 860 : EchoLayout.contentMaxWidth, alignment: .leading)
            .padding(.horizontal, isWide ? 36 : EchoLayout.pageHorizontalPadding)
            .padding(.top, isWide ? 28 : EchoLayout.contentSpacing)
            .padding(.bottom, EchoLayout.sectionSpacing)
            .frame(maxWidth: .infinity)
          }
          .scrollIndicators(.hidden)
        }
      }
    }
    .frame(minWidth: 360, minHeight: 520)
    .interactiveDismissDisabled(isDirty)
    .confirmationDialog(
      "Discard unsaved changes?",
      isPresented: $isConfirmingDiscard,
      titleVisibility: .visible
    ) {
      Button("Discard Changes", role: .destructive) {
        dismiss()
      }
      Button("Keep Editing", role: .cancel) {}
    } message: {
      Text("Your last saved version will remain in Echo.")
    }
    .task {
      // Wait for the presented sheet to become the active focus scope.
      try? await Task.sleep(for: EchoMotion.editorFocusDelay)
      isEditorFocused = true
    }
    .onChange(of: draft) {
      didSave = false
      saveFailed = false
    }
  }

  private func editorHeader(isWide: Bool) -> some View {
    HStack(spacing: EchoLayout.contentSpacing) {
      Button(action: closeEditor) {
        Image(systemName: "xmark")
          .font(.subheadline.weight(.bold))
          .frame(width: 38, height: 38)
          .background(.ultraThinMaterial, in: Circle())
          .overlay {
            Circle()
              .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
          }
      }
      .buttonStyle(.plain)
      .keyboardShortcut(.cancelAction)
      .accessibilityLabel("Close entry editor")

      VStack(alignment: .leading, spacing: EchoLayout.microSpacing) {
        Text("PRIVATE ENTRY")
          .font(EchoTypography.editorialEyebrow)
          .tracking(1.5)
          .foregroundStyle(world.accent)

        Text(
          entry.createdAt.formatted(
            isWide
              ? .dateTime.weekday(.wide).month(.wide).day().year().hour().minute()
              : .dateTime.month(.abbreviated).day().hour().minute()
          )
        )
        .font(isWide ? EchoTypography.contentTitle : EchoTypography.supporting.weight(.semibold))
        .lineLimit(1)
      }

      Spacer(minLength: EchoLayout.inlineSpacing)

      saveStatus
        .font(EchoTypography.status)

      Button(action: save) {
        Label("Save", systemImage: "checkmark")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(world.canvas)
          .padding(.horizontal, isWide ? 20 : 14)
          .frame(minHeight: 40)
          .background(world.accent, in: Capsule())
      }
      .buttonStyle(.plain)
      .disabled(!canSave)
      .opacity(canSave ? 1 : 0.5)
      .keyboardShortcut("s", modifiers: [.command])
    }
    .foregroundStyle(world.primaryText)
    .padding(.horizontal, isWide ? 28 : EchoLayout.pageHorizontalPadding)
    .padding(.vertical, EchoLayout.rowSpacing)
    .background {
      Rectangle()
        .fill(.ultraThinMaterial)
      Rectangle()
        .fill(world.surfaceFill.opacity(0.76))
    }
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(world.separator)
        .frame(height: EchoShape.hairlineWidth)
    }
  }

  private func writingCanvas(isWide: Bool) -> some View {
    EchoReadabilityPanel(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Label("Original writing", systemImage: "text.cursor")
            .font(EchoTypography.metadata)
            .foregroundStyle(world.secondaryText)

          Spacer()

          Text(wordCountLabel)
            .font(EchoTypography.metadata)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, EchoLayout.editorPadding)
        .padding(.vertical, EchoLayout.rowSpacing)

        Divider()

        TextEditor(text: $draft)
          .focused($isEditorFocused)
          .font(isWide ? .system(.title3, design: .serif) : EchoTypography.body)
          .foregroundStyle(world.primaryText)
          .lineSpacing(isWide ? 7 : 5)
          .scrollContentBackground(.hidden)
          .padding(EchoLayout.editorPadding)
          .frame(minHeight: isWide ? 330 : 250)
          .accessibilityLabel("Original journal entry")

        Divider()

        assistanceControls
          .padding(EchoLayout.contentSpacing)
      }
    }
  }

  private var assistanceControls: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: EchoLayout.rowSpacing) {
        assistanceLabel
        Spacer(minLength: EchoLayout.contentSpacing)
        assistanceButtons
      }

      VStack(alignment: .leading, spacing: EchoLayout.rowSpacing) {
        assistanceLabel
        assistanceButtons
      }
    }
  }

  private var assistanceLabel: some View {
    VStack(alignment: .leading, spacing: EchoLayout.microSpacing) {
      Text("Writing assistance")
        .font(EchoTypography.supporting.weight(.semibold))
      Text(isDirty ? "Save changes before creating a new assisted draft." : "Creates a separate draft. Your original stays intact.")
        .font(EchoTypography.status)
        .foregroundStyle(.secondary)
    }
  }

  private var assistanceButtons: some View {
    HStack(spacing: EchoLayout.inlineSpacing) {
      assistanceButton(title: "Clean Up", systemImage: "text.alignleft", operation: .cleanup)
      assistanceButton(title: "Polish", systemImage: "sparkles", operation: .polish)
    }
  }

  private func assistanceButton(
    title: String,
    systemImage: String,
    operation: AssistanceOperation
  ) -> some View {
    Button {
      generateAssistance(using: operation)
    } label: {
      Label(title, systemImage: systemImage)
        .font(EchoTypography.status.weight(.semibold))
        .padding(.horizontal, EchoLayout.rowSpacing)
        .frame(minHeight: 36)
        .background(world.canvas.opacity(0.16), in: Capsule())
        .overlay {
          Capsule()
            .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
        }
    }
    .buttonStyle(.plain)
    .disabled(isDirty || isSaving || isGeneratingAssistance)
  }

  @ViewBuilder
  private var assistanceSection: some View {
    if isGeneratingAssistance {
      HStack(spacing: EchoLayout.inlineSpacing) {
        ProgressView()
          .controlSize(.small)
        Text("Preparing an assisted draft…")
      }
      .font(EchoTypography.status)
      .foregroundStyle(.secondary)
    } else if let assistedText {
      EchoReadabilityPanel {
        VStack(alignment: .leading, spacing: EchoLayout.inlineSpacing) {
          HStack {
            Label("ASSISTED DRAFT", systemImage: "wand.and.stars")
              .font(EchoTypography.editorialEyebrow)
              .tracking(1.3)
              .foregroundStyle(world.accent)

            Spacer()

            Label("Original preserved", systemImage: "lock.fill")
              .font(EchoTypography.metadata)
              .foregroundStyle(world.secondaryText)
          }

          Divider()

          Text(assistedText)
            .font(EchoTypography.editorialNarrative)
            .lineSpacing(6)
            .textSelection(.enabled)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else if assistanceFailed {
      EchoErrorState(message: "Writing assistance could not be generated or saved.")
    }
  }

  @ViewBuilder
  private var saveStatus: some View {
    if isSaving {
      ProgressView()
        .controlSize(.small)
        .accessibilityLabel("Saving")
    } else if saveFailed {
      Label("Not saved", systemImage: "exclamationmark.circle")
        .foregroundStyle(world.error)
    } else if didSave {
      Label("Saved", systemImage: "checkmark.circle.fill")
        .foregroundStyle(world.saved)
    } else if isDirty {
      Text("Unsaved changes")
        .foregroundStyle(.secondary)
    } else {
      Text("Saved")
        .foregroundStyle(.secondary)
    }
  }

  private var isDirty: Bool {
    draft != savedText
  }

  private var containsWriting: Bool {
    draft.contains(where: { !$0.isWhitespace })
  }

  private var wordCountLabel: String {
    let count = draft.split(whereSeparator: \.isWhitespace).count
    return count == 1 ? "1 word" : "\(count) words"
  }

  private var canSave: Bool {
    isDirty && containsWriting && !isSaving
  }

  private func save() {
    let text = draft
    isSaving = true
    saveFailed = false

    Task {
      if await onSave(text) {
        savedText = text
        didSave = true
      } else {
        saveFailed = true
      }
      isSaving = false
    }
  }

  private func closeEditor() {
    if isDirty {
      isConfirmingDiscard = true
    } else {
      dismiss()
    }
  }

  private func generateAssistance(using operation: AssistanceOperation) {
    let source = savedText
    isGeneratingAssistance = true
    assistanceFailed = false

    Task {
      do {
        let result: EchoAssistedWriting
        switch operation {
        case .cleanup:
          result = try await aiService.cleanUp(source)
        case .polish:
          result = try await aiService.polish(source)
        }

        if await onSaveAssistedText(result.text) {
          assistedText = result.text
        } else {
          assistanceFailed = true
        }
      } catch {
        assistanceFailed = true
      }
      isGeneratingAssistance = false
    }
  }
}

private enum AssistanceOperation {
  case cleanup
  case polish
}
