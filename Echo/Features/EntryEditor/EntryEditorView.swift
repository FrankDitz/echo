import SwiftUI

struct EntryEditorView: View {
  let entry: EchoEntry
  let aiService: any EchoAIService
  let onSave: (String) async -> Bool
  let onSaveAssistedText: (String) async -> Bool

  @Environment(\.dismiss) private var dismiss
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
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        TextEditor(text: $draft)
          .focused($isEditorFocused)
          .font(.body)
          .lineSpacing(5)
          .scrollContentBackground(.hidden)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .accessibilityLabel("Journal entry")

        assistanceSection

        Divider()

        HStack {
          Text(entry.createdAt, format: .dateTime.month().day().hour().minute())
            .foregroundStyle(.secondary)
          Spacer()
          saveStatus
        }
        .font(.footnote)
      }
      .padding(20)
      .navigationTitle("Entry")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            closeEditor()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            save()
          }
          .disabled(!canSave)
          .keyboardShortcut("s", modifiers: [.command])
        }
        ToolbarItem(placement: .secondaryAction) {
          Menu("Writing Assistance", systemImage: "wand.and.stars") {
            Button("Clean Up", systemImage: "text.alignleft") {
              generateAssistance(using: .cleanup)
            }
            Button("Polish", systemImage: "sparkles") {
              generateAssistance(using: .polish)
            }
          }
          .disabled(isDirty || isSaving || isGeneratingAssistance)
        }
      }
      .confirmationDialog(
        "Discard unsaved changes?",
        isPresented: $isConfirmingDiscard,
        titleVisibility: .visible
      ) {
        Button("Discard Changes", role: .destructive) {
          dismiss()
        }
        Button("Keep Editing", role: .cancel) {}
      }
    }
    .frame(minWidth: 360, minHeight: 420)
    .interactiveDismissDisabled(isDirty)
    .task {
      // Wait for the presented sheet to become the active focus scope.
      try? await Task.sleep(for: .milliseconds(300))
      isEditorFocused = true
    }
    .onChange(of: draft) {
      didSave = false
      saveFailed = false
    }
  }

  @ViewBuilder
  private var assistanceSection: some View {
    if isGeneratingAssistance {
      HStack(spacing: 10) {
        ProgressView()
          .controlSize(.small)
        Text("Preparing an assisted draft…")
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
    } else if let assistedText {
      VStack(alignment: .leading, spacing: 8) {
        Label("Assisted Draft", systemImage: "wand.and.stars")
          .font(.headline)
        Text(assistedText)
          .font(.body)
          .lineSpacing(4)
          .textSelection(.enabled)
        Text("Your original writing is preserved above.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    } else if assistanceFailed {
      Label("Writing assistance could not be generated or saved.", systemImage: "exclamationmark.triangle")
        .font(.footnote)
        .foregroundStyle(.red)
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
        .foregroundStyle(.red)
    } else if didSave {
      Label("Saved", systemImage: "checkmark.circle.fill")
        .foregroundStyle(.secondary)
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
