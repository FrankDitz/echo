import CoreGraphics
import CoreText
import Foundation

enum EchoExportFormat: Sendable {
  case markdown
  case pdf
}

struct EchoDataExport: Sendable {
  let data: Data
  let suggestedFileName: String
}

struct EchoDataExportService: Sendable {
  private let entryRepository: any EchoEntryRepository
  private let highlightRepository: any EchoHighlightRepository
  private let journalRepository: any EchoOrganizedJournalRepository
  private let weeklyRepository: any EchoWeeklyReflectionRepository

  init(
    entryRepository: any EchoEntryRepository,
    highlightRepository: any EchoHighlightRepository,
    journalRepository: any EchoOrganizedJournalRepository,
    weeklyRepository: any EchoWeeklyReflectionRepository
  ) {
    self.entryRepository = entryRepository
    self.highlightRepository = highlightRepository
    self.journalRepository = journalRepository
    self.weeklyRepository = weeklyRepository
  }

  func makeExport(
    format: EchoExportFormat,
    generatedAt: Date = .now,
    timeZone: TimeZone = .autoupdatingCurrent
  ) async throws -> EchoDataExport {
    async let entries = entryRepository.allEntries()
    async let highlights = highlightRepository.allHighlights()
    async let journals = journalRepository.allJournals()
    async let weeklyReflections = weeklyRepository.allReflections()

    let snapshot = EchoExportSnapshot(
      generatedAt: generatedAt,
      timeZone: timeZone,
      entries: try await entries,
      highlights: try await highlights,
      journals: try await journals,
      weeklyReflections: try await weeklyReflections
    )
    let markdown = EchoMarkdownExportRenderer.render(snapshot)
    let dateStamp = Self.fileDateFormatter.string(from: generatedAt)

    switch format {
    case .markdown:
      return EchoDataExport(
        data: Data(markdown.utf8),
        suggestedFileName: "Echo Journal \(dateStamp)"
      )
    case .pdf:
      return EchoDataExport(
        data: EchoPDFExportRenderer.render(markdown),
        suggestedFileName: "Echo Journal \(dateStamp)"
      )
    }
  }

  private static var fileDateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }
}

private struct EchoExportSnapshot {
  let generatedAt: Date
  let timeZone: TimeZone
  let entries: [EchoEntry]
  let highlights: [EchoHighlight]
  let journals: [EchoOrganizedJournal]
  let weeklyReflections: [EchoWeeklyReflection]
}

private enum EchoMarkdownExportRenderer {
  static func render(_ snapshot: EchoExportSnapshot) -> String {
    let highlightedEntryIDs = Set(
      snapshot.highlights
        .filter { $0.target.kind == .entry }
        .map(\.target.entityID)
    )
    let entriesByDay = Dictionary(grouping: snapshot.entries, by: \.day)
    let journalsByDay = Dictionary(
      uniqueKeysWithValues: snapshot.journals.map { ($0.day, $0) }
    )
    let days = Set(entriesByDay.keys).union(journalsByDay.keys).sorted()
    var sections = [
      "# Echo Journal",
      "",
      "Private export created \(timestamp(snapshot.generatedAt, in: snapshot.timeZone)).",
      ""
    ]

    if days.isEmpty && snapshot.weeklyReflections.isEmpty {
      sections.append("No journal content has been recorded yet.")
      return sections.joined(separator: "\n") + "\n"
    }

    for day in days {
      sections.append("## \(dayTitle(day, in: snapshot.timeZone))")
      sections.append("")

      if let journal = journalsByDay[day] {
        if let title = journal.title, !title.isEmpty {
          sections.append("### \(title)")
          sections.append("")
        }
        sections.append(journal.body)
        sections.append("")

        if !journal.themes.isEmpty {
          sections.append("**Themes:** \(journal.themes.joined(separator: ", "))")
          sections.append("")
        }
        if !journal.keyMoments.isEmpty {
          sections.append("**Key moments**")
          sections.append(contentsOf: journal.keyMoments.map { "- \($0)" })
          sections.append("")
        }
        if !journal.reflectionQuestions.isEmpty {
          sections.append("**Reflection questions**")
          sections.append(contentsOf: journal.reflectionQuestions.map { "- \($0)" })
          sections.append("")
        }
      }

      let dayEntries = EchoEntryOrdering.chronological(entriesByDay[day] ?? [])
      if !dayEntries.isEmpty {
        sections.append("### Original entries")
        sections.append("")
        for entry in dayEntries {
          let marker = highlightedEntryIDs.contains(entry.id) ? " · Saved" : ""
          sections.append("#### \(time(entry.createdAt, in: snapshot.timeZone))\(marker)")
          sections.append("")
          sections.append(entry.rawText)
          if let polishedText = entry.polishedText, !polishedText.isEmpty {
            sections.append("")
            sections.append("**Assisted version**")
            sections.append("")
            sections.append(polishedText)
          }
          sections.append("")
        }
      }
    }

    if !snapshot.weeklyReflections.isEmpty {
      sections.append("# Weekly reflections")
      sections.append("")
      for reflection in snapshot.weeklyReflections.sorted(by: { $0.week < $1.week }) {
        sections.append("## Week \(reflection.week.weekOfYear), \(reflection.week.yearForWeekOfYear)")
        sections.append("")
        sections.append(reflection.body)
        sections.append("")
        if !reflection.themes.isEmpty {
          sections.append("**Themes:** \(reflection.themes.joined(separator: ", "))")
          sections.append("")
        }
        if let question = reflection.question, !question.isEmpty {
          sections.append("**Question for the coming week:** \(question)")
          sections.append("")
        }
      }
    }

    return sections.joined(separator: "\n") + "\n"
  }

  private static func dayTitle(_ day: EchoDayIdentifier, in timeZone: TimeZone) -> String {
    guard let date = day.date(in: timeZone) else {
      return String(format: "%04d-%02d-%02d", day.year, day.month, day.day)
    }
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: day.calendarIdentifier)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    formatter.dateFormat = "EEEE, MMMM d, yyyy"
    return formatter.string(from: date)
  }

  private static func time(_ date: Date, in timeZone: TimeZone) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }

  private static func timestamp(_ date: Date, in timeZone: TimeZone) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

private enum EchoPDFExportRenderer {
  static func render(_ markdown: String) -> Data {
    let data = NSMutableData()
    guard let consumer = CGDataConsumer(data: data as CFMutableData) else { return Data() }
    var pageBox = CGRect(x: 0, y: 0, width: 612, height: 792)
    guard let context = CGContext(consumer: consumer, mediaBox: &pageBox, nil) else {
      return Data()
    }

    let attributes: [NSAttributedString.Key: Any] = [
      .font: CTFontCreateWithName("Helvetica" as CFString, 11, nil),
      .foregroundColor: CGColor(gray: 0.08, alpha: 1)
    ]
    let attributedText = NSAttributedString(string: markdown, attributes: attributes)
    let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
    var range = CFRange(location: 0, length: 0)
    let textBox = CGRect(x: 54, y: 54, width: 504, height: 684)

    repeat {
      context.beginPDFPage(nil)
      context.saveGState()
      context.textMatrix = .identity
      context.translateBy(x: 0, y: pageBox.height)
      context.scaleBy(x: 1, y: -1)
      let path = CGMutablePath()
      path.addRect(textBox)
      let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
      CTFrameDraw(frame, context)
      context.restoreGState()
      context.endPDFPage()

      let visibleRange = CTFrameGetVisibleStringRange(frame)
      range.location += visibleRange.length
    } while range.location < attributedText.length

    context.closePDF()
    return data as Data
  }
}
