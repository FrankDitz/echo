import Foundation
import Testing

@testable import Echo

@Suite("Model container privacy")
struct EchoModelContainerFactoryTests {
  @Test("Production storage resolves outside the source checkout")
  func productionStoreLocation() {
    let configuration = EchoModelContainerFactory.productionConfiguration()
    let checkoutPath = repositoryRoot().path + "/"

    #expect(configuration.url.isFileURL)
    #expect(!configuration.isStoredInMemoryOnly)
    #expect(!configuration.url.standardizedFileURL.path.hasPrefix(checkoutPath))
  }

  @Test("Repository tests can use storage with no filesystem backing")
  func inMemoryStorage() throws {
    let container = try EchoModelContainerFactory.makeInMemory()
    let configuration = try #require(container.configurations.first)

    #expect(configuration.isStoredInMemoryOnly)
  }
}
