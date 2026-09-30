import SwiftUI

struct EntryHighlightButton: View {
  let entryID: UUID
  let viewModel: EntryHighlightViewModel

  var body: some View {
    Button(action: toggle) {
      Label(title, systemImage: systemImage)
    }
    .disabled(viewModel.updatingEntryIDs.contains(entryID))
    .accessibilityHint(accessibilityHint)
  }

  private var isHighlighted: Bool {
    viewModel.isHighlighted(entryID)
  }

  private var title: String {
    isHighlighted ? "Remove Highlight" : "Highlight"
  }

  private var systemImage: String {
    isHighlighted ? "bookmark.fill" : "bookmark"
  }

  private var accessibilityHint: String {
    isHighlighted
      ? "Removes this entry from Highlights"
      : "Adds this entry to Highlights"
  }

  private func toggle() {
    Task {
      await viewModel.toggle(entryID: entryID)
    }
  }
}
