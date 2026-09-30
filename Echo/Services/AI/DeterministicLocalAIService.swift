import Foundation

/// A predictable, offline stand-in used to build the assisted-writing experience.
/// It performs no inference, network request, credential lookup, or logging.
struct DeterministicLocalAIService: EchoAIService {
  func cleanUp(_ rawText: String) async throws -> EchoAssistedWriting {
    let text = normalized(rawText)
    guard !text.isEmpty else { throw EchoAIServiceError.emptyWriting }
    return EchoAssistedWriting(text: text)
  }

  func polish(_ rawText: String) async throws -> EchoAssistedWriting {
    let cleaned = try await cleanUp(rawText).text
    let capitalized = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
    let terminalCharacters: Set<Character> = [".", "?", "!", "…"]
    let text = terminalCharacters.contains(capitalized.last ?? " ")
      ? capitalized
      : capitalized + "."
    return EchoAssistedWriting(text: text)
  }

  func organize(_ day: EchoDay) async throws -> EchoOrganizedJournalDraft {
    guard !day.entries.isEmpty else { throw EchoAIServiceError.emptyDay }

    let entries = EchoEntryOrdering.chronological(day.entries)
    let paragraphs = entries.map { normalized($0.rawText) }
    return EchoOrganizedJournalDraft(
      day: day.id,
      body: paragraphs.joined(separator: "\n\n"),
      sourceEntryIDs: entries.map(\.id)
    )
  }

  private func normalized(_ rawText: String) -> String {
    let normalizedNewlines = rawText.replacingOccurrences(of: "\r\n", with: "\n")
    let lines = normalizedNewlines.components(separatedBy: "\n").map { line in
      line.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    var paragraphs: [String] = []
    var currentParagraph: [String] = []
    for line in lines {
      if line.isEmpty {
        if !currentParagraph.isEmpty {
          paragraphs.append(currentParagraph.joined(separator: " "))
          currentParagraph = []
        }
      } else {
        currentParagraph.append(line)
      }
    }
    if !currentParagraph.isEmpty {
      paragraphs.append(currentParagraph.joined(separator: " "))
    }

    return paragraphs.joined(separator: "\n\n")
  }
}
