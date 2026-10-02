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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    NavigationStack {
      if selection == .today {
        selectedContent
          .id(selection)
          .transition(.opacity)
          .overlay(alignment: .top) {
            primaryNavigation
          }
      } else {
        selectedContent
          .id(selection)
          .transition(.opacity)
          .safeAreaInset(edge: .top, spacing: 0) {
            primaryNavigation
          }
      }
    }
    .animation(EchoMotion.animation(reduceMotion: reduceMotion), value: selection)
    .sheet(isPresented: $isShowingSettings) {
      SettingsView(visualWorldSelection: visualWorldSelection)
    }
  }

  private var primaryNavigation: some View {
    EchoPrimaryNavigation(selection: $selection) {
      isShowingSettings = true
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
    case .reflection:
      DayReflectionView(
        todayViewModel: todayViewModel,
        timelineViewModel: timelineViewModel,
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
