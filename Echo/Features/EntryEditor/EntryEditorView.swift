import SwiftUI

struct EntryEditorView: View {
  let entry: EchoEntry
  let onSave: (String) async -> Bool

  @Environment(\.dismiss) private var dismiss
  @FocusState private var isEditorFocused: Bool
  @State private var draft: String
  @State private var savedText: String
  @State private var isSaving = false
  @State private var didSave = false
  @State private var saveFailed = false
  @State private var isConfirmingDiscard = false

  init(
    entry: EchoEntry,
    onSave: @escaping (String) async -> Bool
  ) {
    self.entry = entry
    self.onSave = onSave
    _draft = State(initialValue: entry.rawText)
    _savedText = State(initialValue: entry.rawText)
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
    .onAppear {
      isEditorFocused = true
    }
    .onChange(of: draft) {
      didSave = false
      saveFailed = false
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
}
