import SwiftData
import SwiftUI

@main
struct EchoApp: App {
  private let modelContainer: ModelContainer
  private let todayViewModel: TodayViewModel

  init() {
    do {
      let container = try EchoModelContainerFactory.makePersistent()
      modelContainer = container
      todayViewModel = TodayViewModel(
        repository: SwiftDataEchoEntryRepository(modelContainer: container)
      )
    } catch {
      preconditionFailure("Echo could not initialize its local data store.")
    }
  }

  var body: some Scene {
    WindowGroup {
      AppShellView(todayViewModel: todayViewModel)
    }
    .modelContainer(modelContainer)
  }
}
