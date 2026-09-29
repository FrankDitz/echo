import SwiftData
import SwiftUI

@main
struct EchoApp: App {
  private let modelContainer: ModelContainer

  init() {
    do {
      modelContainer = try EchoModelContainerFactory.makePersistent()
    } catch {
      preconditionFailure("Echo could not initialize its local data store.")
    }
  }

  var body: some Scene {
    WindowGroup {
      AppShellView()
    }
    .modelContainer(modelContainer)
  }
}
