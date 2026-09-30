import SwiftData
import SwiftUI

@main
struct EchoApp: App {
  private let modelContainer: ModelContainer
  private let todayViewModel: TodayViewModel
  private let timelineViewModel: TimelineViewModel
  private let highlightViewModel: EntryHighlightViewModel
  private let highlightsViewModel: HighlightsViewModel
  private let aiService: any EchoAIService

  init() {
    do {
      let container = try EchoModelContainerFactory.makePersistent()
      let entryRepository = SwiftDataEchoEntryRepository(modelContainer: container)
      let highlightRepository = SwiftDataEchoHighlightRepository(modelContainer: container)
      let aiService = DeterministicLocalAIService()
      modelContainer = container
      self.aiService = aiService
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
        aiService: aiService
      )
    }
    .modelContainer(modelContainer)
  }
}
