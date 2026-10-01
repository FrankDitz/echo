import SwiftUI

struct AppShellView: View {
  let todayViewModel: TodayViewModel
  let timelineViewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let highlightsViewModel: HighlightsViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository
  let visualWorldSelection: EchoVisualWorldSelection

  @State private var selection: AppSection = .today
  @State private var isShowingSettings = false

  var body: some View {
    NavigationStack {
      TabView(selection: $selection) {
        TodayView(
          viewModel: todayViewModel,
          highlightViewModel: highlightViewModel,
          aiService: aiService
        )
          .tag(AppSection.today)
          .tabItem {
            Label("Today", systemImage: "sun.max")
          }

        TimelineView(
          viewModel: timelineViewModel,
          highlightViewModel: highlightViewModel,
          aiService: aiService,
          journalRepository: journalRepository
        )
          .tag(AppSection.timeline)
          .tabItem {
            Label("Timeline", systemImage: "clock")
          }

        HighlightsView(
          viewModel: highlightsViewModel,
          highlightViewModel: highlightViewModel,
          aiService: aiService,
          journalRepository: journalRepository
        )
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
      SettingsView(visualWorldSelection: visualWorldSelection)
    }
  }

}

private enum AppSection: Hashable {
  case today
  case timeline
  case highlights

}
