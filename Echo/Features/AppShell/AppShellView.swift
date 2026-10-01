import SwiftUI

struct AppShellView: View {
  let todayViewModel: TodayViewModel
  let timelineViewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let highlightsViewModel: HighlightsViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository
  let visualWorldSelection: EchoVisualWorldSelection

  @State private var selection: EchoPrimarySection = .today
  @State private var isShowingSettings = false

  var body: some View {
    NavigationStack {
      selectedContent
        .safeAreaInset(edge: .top, spacing: 0) {
          EchoPrimaryNavigation(selection: $selection) {
            isShowingSettings = true
          }
        }
    }
    .sheet(isPresented: $isShowingSettings) {
      SettingsView(visualWorldSelection: visualWorldSelection)
    }
  }

  @ViewBuilder
  private var selectedContent: some View {
    switch selection {
    case .today:
      TodayView(
        viewModel: todayViewModel,
        highlightViewModel: highlightViewModel,
        aiService: aiService
      )
    case .timeline:
      TimelineView(
        viewModel: timelineViewModel,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        journalRepository: journalRepository
      )
    case .highlights:
      HighlightsView(
        viewModel: highlightsViewModel,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        journalRepository: journalRepository
      )
    }
  }
}
