import SwiftData
import SwiftUI

@main
struct EchoApp: App {
  private let modelContainer: ModelContainer
  private let todayViewModel: TodayViewModel
  private let timelineViewModel: TimelineViewModel
  private let highlightViewModel: EntryHighlightViewModel

  init() {
    do {
      let container = try EchoModelContainerFactory.makePersistent()
      let entryRepository = SwiftDataEchoEntryRepository(modelContainer: container)
      let highlightRepository = SwiftDataEchoHighlightRepository(modelContainer: container)
      modelContainer = container
      todayViewModel = TodayViewModel(repository: entryRepository)
      timelineViewModel = TimelineViewModel(repository: entryRepository)
      highlightViewModel = EntryHighlightViewModel(repository: highlightRepository)
    } catch {
      preconditionFailure("Echo could not initialize its local data store.")
    }
  }

  var body: some Scene {
    WindowGroup {
      AppShellView(
        todayViewModel: todayViewModel,
        timelineViewModel: timelineViewModel,
        highlightViewModel: highlightViewModel
      )
    }
    .modelContainer(modelContainer)
  }
}
