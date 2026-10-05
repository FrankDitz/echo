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
    let themes = recurringThemes(in: paragraphs)
    return EchoOrganizedJournalDraft(
      day: day.id,
      body: paragraphs.joined(separator: "\n\n"),
      title: reflectionTitle(themes: themes, entryCount: entries.count),
      themes: themes,
      keyMoments: Array(paragraphs.compactMap(keyMoment).prefix(3)),
      reflectionQuestions: reflectionQuestions(themes: themes),
      sourceEntryIDs: entries.map(\.id)
    )
  }

  private func reflectionTitle(themes: [String], entryCount: Int) -> String {
    guard let leadingTheme = themes.first else {
      return entryCount == 1 ? "A Moment in Focus" : "The Day in Focus"
    }
    return "\(leadingTheme) in Focus"
  }

  private func recurringThemes(in paragraphs: [String]) -> [String] {
    let stopWords: Set<String> = [
      "about", "after", "again", "also", "been", "before", "could", "from",
      "have", "into", "just", "more", "that", "their", "there", "they",
      "this", "today", "very", "what", "when", "where", "which", "with",
      "would", "your",
    ]
    var counts: [String: (count: Int, firstIndex: Int)] = [:]
    var index = 0

    for paragraph in paragraphs {
      for token in paragraph.lowercased().split(whereSeparator: { !$0.isLetter }) {
        let word = String(token)
        guard word.count >= 4, !stopWords.contains(word) else { continue }
        if let existing = counts[word] {
          counts[word] = (existing.count + 1, existing.firstIndex)
        } else {
          counts[word] = (1, index)
          index += 1
        }
      }
    }

    return counts
      .sorted { lhs, rhs in
        if lhs.value.count != rhs.value.count { return lhs.value.count > rhs.value.count }
        return lhs.value.firstIndex < rhs.value.firstIndex
      }
      .prefix(3)
      .map { $0.key.capitalized }
  }

  private func keyMoment(from paragraph: String) -> String? {
    let sentence = paragraph.split(
      omittingEmptySubsequences: true,
      whereSeparator: { ".!?\n".contains($0) }
    ).first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let sentence, !sentence.isEmpty else { return nil }
    return sentence.count > 120 ? String(sentence.prefix(117)) + "…" : sentence
  }

  private func reflectionQuestions(themes: [String]) -> [String] {
    if let theme = themes.first {
      return ["What about \(theme.lowercased()) would you like to carry forward?"]
    }
    return ["What from this day would you like to carry forward?"]
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
