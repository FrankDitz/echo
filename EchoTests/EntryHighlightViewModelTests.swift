import Foundation
import Testing

@testable import Echo

@MainActor
@Suite("Entry highlighting")
struct EntryHighlightViewModelTests {
  @Test("Loading restores persisted entry highlights")
  func loadingHighlights() async throws {
    let entryID = try makeUUID("00000000-0000-0000-0000-000000000601")
    let highlight = EchoHighlight(
      id: try makeUUID("00000000-0000-0000-0000-000000000602"),
      target: .entry(entryID),
      createdAt: try makeDate("2026-10-04T09:00:00Z")
    )
    let repository = HighlightRepositoryStub(highlights: [highlight])
    let viewModel = EntryHighlightViewModel(repository: repository)

    await viewModel.load()

    #expect(viewModel.isHighlighted(entryID))
    #expect(viewModel.failure == nil)
  }

  @Test("Toggling creates and then removes an entry highlight")
  func togglingHighlight() async throws {
    let entryID = try makeUUID("00000000-0000-0000-0000-000000000603")
    let date = try makeDate("2026-10-04T10:00:00Z")
    let repository = HighlightRepositoryStub()
    let viewModel = EntryHighlightViewModel(
      repository: repository,
      now: { date }
    )

    #expect(await viewModel.toggle(entryID: entryID))
    let created = try #require(await repository.allHighlights().first)
    #expect(created.target == .entry(entryID))
    #expect(created.createdAt == date)
    #expect(viewModel.isHighlighted(entryID))

    #expect(await viewModel.toggle(entryID: entryID))
    #expect(await repository.allHighlights().isEmpty)
    #expect(!viewModel.isHighlighted(entryID))
  }

  @Test("Persistence failure preserves the visible highlight state")
  func persistenceFailure() async throws {
    let entryID = try makeUUID("00000000-0000-0000-0000-000000000604")
    let repository = HighlightRepositoryStub(shouldFail: true)
    let viewModel = EntryHighlightViewModel(repository: repository)

    #expect(!(await viewModel.toggle(entryID: entryID)))
    #expect(!viewModel.isHighlighted(entryID))
    #expect(viewModel.failure == .update)
  }
}

private actor HighlightRepositoryStub: EchoHighlightRepository {
  private var highlights: [EchoHighlight]
  private let shouldFail: Bool

  init(highlights: [EchoHighlight] = [], shouldFail: Bool = false) {
    self.highlights = highlights
    self.shouldFail = shouldFail
  }

  func create(_ highlight: EchoHighlight) throws {
    if shouldFail { throw StubError.requestedFailure }
    highlights.append(highlight)
  }

  func highlight(for target: EchoHighlightTarget) -> EchoHighlight? {
    highlights.first(where: { $0.target == target })
  }

  func allHighlights() -> [EchoHighlight] {
    highlights
  }

  func delete(id: UUID) throws {
    if shouldFail { throw StubError.requestedFailure }
    highlights.removeAll(where: { $0.id == id })
  }

  private enum StubError: Error {
    case requestedFailure
  }
}
