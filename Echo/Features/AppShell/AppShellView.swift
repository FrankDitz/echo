import SwiftUI

struct AppShellView: View {
  let todayViewModel: TodayViewModel
  let timelineViewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let highlightsViewModel: HighlightsViewModel

  @State private var selection: AppSection = .today
  @State private var isShowingSettings = false

  var body: some View {
    NavigationStack {
      TabView(selection: $selection) {
        TodayView(
          viewModel: todayViewModel,
          highlightViewModel: highlightViewModel
        )
          .tag(AppSection.today)
          .tabItem {
            Label("Today", systemImage: "sun.max")
          }

        TimelineView(
          viewModel: timelineViewModel,
          highlightViewModel: highlightViewModel
        )
          .tag(AppSection.timeline)
          .tabItem {
            Label("Timeline", systemImage: "clock")
          }

        HighlightsView(viewModel: highlightsViewModel)
        .tag(AppSection.highlights)
        .tabItem {
          Label("Highlights", systemImage: "bookmark")
        }
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Settings", systemImage: "gearshape") {
            isShowingSettings = true
          }
        }
      }
    }
    .sheet(isPresented: $isShowingSettings) {
      SettingsPlaceholderView()
    }
  }

}

private enum AppSection: Hashable {
  case today
  case timeline
  case highlights

}

private struct SettingsPlaceholderView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ContentUnavailableView(
        "Settings",
        systemImage: "gearshape",
        description: Text("Preferences will be added as Echo grows.")
      )
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .frame(minWidth: 340, minHeight: 240)
  }
}
