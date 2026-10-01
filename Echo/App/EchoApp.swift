import SwiftData
import SwiftUI

@main
struct EchoApp: App {
  @State private var visualWorldSelection = EchoVisualWorldSelection()

  private let modelContainer: ModelContainer
  private let todayViewModel: TodayViewModel
  private let timelineViewModel: TimelineViewModel
  private let highlightViewModel: EntryHighlightViewModel
  private let highlightsViewModel: HighlightsViewModel
  private let aiService: any EchoAIService
  private let journalRepository: any EchoOrganizedJournalRepository

  init() {
    do {
      let container = try EchoModelContainerFactory.makePersistent()
      let entryRepository = SwiftDataEchoEntryRepository(modelContainer: container)
      let highlightRepository = SwiftDataEchoHighlightRepository(modelContainer: container)
      let aiService = DeterministicLocalAIService()
      let journalRepository = SwiftDataEchoOrganizedJournalRepository(
        modelContainer: container
      )
      modelContainer = container
      self.aiService = aiService
      self.journalRepository = journalRepository
      todayViewModel = TodayViewModel(repository: entryRepository)
      timelineViewModel = TimelineViewModel(repository: entryRepository)
      highlightViewModel = EntryHighlightViewModel(repository: highlightRepository)
      highlightsViewModel = HighlightsViewModel(
        entryRepository: entryRepository,
        highlightRepository: highlightRepository,
        entryHighlightViewModel: highlightViewModel
      )
    } catch {
      preconditionFailure("Echo could not initialize its local data store.")
    }
  }

  var body: some Scene {
    WindowGroup {
      AppShellView(
        todayViewModel: todayViewModel,
        timelineViewModel: timelineViewModel,
        highlightViewModel: highlightViewModel,
        highlightsViewModel: highlightsViewModel,
        aiService: aiService,
        journalRepository: journalRepository,
        visualWorldSelection: visualWorldSelection
      )
      .environment(\.echoVisualWorld, visualWorldSelection.selectedWorld)
      .tint(visualWorldSelection.selectedWorld.accent)
      .preferredColorScheme(.dark)
    }
    .modelContainer(modelContainer)
  }
}
