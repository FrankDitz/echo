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
  private let carryForwardRepository: any EchoCarryForwardRepository

  init(
    entryRepository: any EchoEntryRepository,
    highlightRepository: any EchoHighlightRepository,
    journalRepository: any EchoOrganizedJournalRepository,
    weeklyRepository: any EchoWeeklyReflectionRepository,
    carryForwardRepository: any EchoCarryForwardRepository
  ) {
    self.entryRepository = entryRepository
    self.highlightRepository = highlightRepository
    self.journalRepository = journalRepository
    self.weeklyRepository = weeklyRepository
    self.carryForwardRepository = carryForwardRepository
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
    async let carryForwards = carryForwardRepository.allCarryForwards()

    let snapshot = EchoExportSnapshot(
      generatedAt: generatedAt,
      timeZone: timeZone,
      entries: try await entries,
      highlights: try await highlights,
      journals: try await journals,
      weeklyReflections: try await weeklyReflections,
      carryForwards: try await carryForwards
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

struct EchoRecoveryResult: Equatable, Sendable {
  let addedEntries: Int
  let addedHighlights: Int
  let addedJournals: Int
  let addedWeeklyReflections: Int
  let addedVoiceAttachments: Int
  let addedCarryForwards: Int
  let skippedExistingItems: Int

  var summary: String {
    let added =
      addedEntries + addedHighlights + addedJournals
      + addedWeeklyReflections + addedVoiceAttachments + addedCarryForwards
    return "Added \(added) items and kept \(skippedExistingItems) existing items unchanged."
  }
}

enum EchoRecoveryError: LocalizedError, Equatable {
  case unsupportedVersion(Int)
  case invalidArchive

  var errorDescription: String? {
    switch self {
    case .unsupportedVersion:
      return "This backup was created by an unsupported version of Echo."
    case .invalidArchive:
      return "This file is not a valid Echo recovery backup."
    }
  }
}

struct EchoDataRecoveryService: Sendable {
  private let entryRepository: any EchoEntryRepository
  private let highlightRepository: any EchoHighlightRepository
  private let journalRepository: any EchoOrganizedJournalRepository
  private let weeklyRepository: any EchoWeeklyReflectionRepository
  private let voiceAttachmentRepository: any EchoVoiceAttachmentRepository
  private let carryForwardRepository: any EchoCarryForwardRepository
  private let voiceFileStore: EchoVoiceFileStore

  init(
    entryRepository: any EchoEntryRepository,
    highlightRepository: any EchoHighlightRepository,
    journalRepository: any EchoOrganizedJournalRepository,
    weeklyRepository: any EchoWeeklyReflectionRepository,
    voiceAttachmentRepository: any EchoVoiceAttachmentRepository,
    carryForwardRepository: any EchoCarryForwardRepository,
    voiceFileStore: EchoVoiceFileStore
  ) {
    self.entryRepository = entryRepository
    self.highlightRepository = highlightRepository
    self.journalRepository = journalRepository
    self.weeklyRepository = weeklyRepository
    self.voiceAttachmentRepository = voiceAttachmentRepository
    self.carryForwardRepository = carryForwardRepository
    self.voiceFileStore = voiceFileStore
  }

  func makeRecoveryArchive(generatedAt: Date = .now) async throws -> EchoDataExport {
    async let entries = entryRepository.allEntries()
    async let highlights = highlightRepository.allHighlights()
    async let journals = journalRepository.allJournals()
    async let weeklyReflections = weeklyRepository.allReflections()
    async let voiceAttachments = voiceAttachmentRepository.allAttachments()
    async let carryForwards = carryForwardRepository.allCarryForwards()

    let attachments = try await voiceAttachments
    var voiceFiles: [EchoRecoveryVoiceFile] = []
    for attachment in attachments {
      let url = try voiceFileStore.url(for: attachment)
      voiceFiles.append(
        EchoRecoveryVoiceFile(
          attachmentID: attachment.id,
          data: try Data(contentsOf: url)
        )
      )
    }

    let archive = EchoRecoveryArchive(
      formatVersion: EchoRecoveryArchive.currentVersion,
      createdAt: generatedAt,
      entries: try await entries,
      highlights: try await highlights,
      journals: try await journals,
      weeklyReflections: try await weeklyReflections,
      carryForwards: try await carryForwards,
      voiceAttachments: attachments,
      voiceFiles: voiceFiles
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    let dateStamp = Self.fileDateFormatter.string(from: generatedAt)
    return EchoDataExport(
      data: try encoder.encode(archive),
      suggestedFileName: "Echo Recovery \(dateStamp).echobackup"
    )
  }

  func restore(from data: Data) async throws -> EchoRecoveryResult {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let archive: EchoRecoveryArchive
    do {
      archive = try decoder.decode(EchoRecoveryArchive.self, from: data)
    } catch {
      throw EchoRecoveryError.invalidArchive
    }
    guard archive.formatVersion == EchoRecoveryArchive.currentVersion else {
      throw EchoRecoveryError.unsupportedVersion(archive.formatVersion)
    }
    try validate(archive)

    let currentEntries = try await entryRepository.allEntries()
    let availableEntryIDs = Set(currentEntries.map(\.id)).union(archive.entries.map(\.id))
    guard archive.voiceAttachments.allSatisfy({ availableEntryIDs.contains($0.entryID) }) else {
      throw EchoRecoveryError.invalidArchive
    }

    var addedEntries = 0
    var addedHighlights = 0
    var addedJournals = 0
    var addedWeeklyReflections = 0
    var addedVoiceAttachments = 0
    var addedCarryForwards = 0
    var skipped = 0

    let currentEntryIDs = Set(currentEntries.map(\.id))
    for entry in archive.entries {
      if currentEntryIDs.contains(entry.id) {
        skipped += 1
      } else {
        try await entryRepository.create(entry)
        addedEntries += 1
      }
    }

    for highlight in archive.highlights {
      if try await highlightRepository.highlight(for: highlight.target) != nil {
        skipped += 1
      } else {
        try await highlightRepository.create(highlight)
        addedHighlights += 1
      }
    }

    for journal in archive.journals {
      if try await journalRepository.journal(for: journal.day) != nil {
        skipped += 1
      } else {
        try await journalRepository.create(journal)
        addedJournals += 1
      }
    }

    for reflection in archive.weeklyReflections {
      if try await weeklyRepository.reflection(for: reflection.week) != nil {
        skipped += 1
      } else {
        try await weeklyRepository.create(reflection)
        addedWeeklyReflections += 1
      }
    }

    for carryForward in archive.carryForwards {
      if try await carryForwardRepository.carryForward(for: carryForward.targetDay) != nil {
        skipped += 1
      } else {
        try await carryForwardRepository.create(carryForward)
        addedCarryForwards += 1
      }
    }

    let audioByAttachmentID = Dictionary(
      uniqueKeysWithValues: archive.voiceFiles.map { ($0.attachmentID, $0.data) }
    )
    for attachment in archive.voiceAttachments {
      if try await voiceAttachmentRepository.attachment(for: attachment.entryID) != nil {
        skipped += 1
        continue
      }
      guard let audio = audioByAttachmentID[attachment.id] else {
        throw EchoRecoveryError.invalidArchive
      }
      let destination = try voiceFileStore.destinationURL(for: attachment.id)
      let restoredAttachment = EchoVoiceAttachment(
        id: attachment.id,
        entryID: attachment.entryID,
        createdAt: attachment.createdAt,
        relativeFileName: destination.lastPathComponent,
        duration: attachment.duration,
        format: attachment.format,
        transcript: attachment.transcript
      )
      try audio.write(to: destination, options: .atomic)
      do {
        try await voiceAttachmentRepository.create(restoredAttachment)
      } catch {
        try? FileManager.default.removeItem(at: destination)
        throw error
      }
      addedVoiceAttachments += 1
    }

    return EchoRecoveryResult(
      addedEntries: addedEntries,
      addedHighlights: addedHighlights,
      addedJournals: addedJournals,
      addedWeeklyReflections: addedWeeklyReflections,
      addedVoiceAttachments: addedVoiceAttachments,
      addedCarryForwards: addedCarryForwards,
      skippedExistingItems: skipped
    )
  }

  private func validate(_ archive: EchoRecoveryArchive) throws {
    let entryIDs = archive.entries.map(\.id)
    let highlightIDs = archive.highlights.map(\.id)
    let highlightTargets = archive.highlights.map(\.target)
    let journalIDs = archive.journals.map(\.id)
    let journalDays = archive.journals.map(\.day)
    let weeklyIDs = archive.weeklyReflections.map(\.id)
    let weeks = archive.weeklyReflections.map(\.week)
    let carryForwardIDs = archive.carryForwards.map(\.id)
    let carryForwardDays = archive.carryForwards.map(\.targetDay)
    let attachmentIDs = archive.voiceAttachments.map(\.id)
    let attachmentEntryIDs = archive.voiceAttachments.map(\.entryID)
    let voiceFileIDs = archive.voiceFiles.map(\.attachmentID)
    guard isUnique(entryIDs), isUnique(highlightIDs), isUnique(highlightTargets),
      isUnique(journalIDs), isUnique(journalDays), isUnique(weeklyIDs), isUnique(weeks),
      isUnique(carryForwardIDs), isUnique(carryForwardDays), isUnique(attachmentIDs),
      isUnique(attachmentEntryIDs), isUnique(voiceFileIDs),
      Set(attachmentIDs) == Set(voiceFileIDs)
    else {
      throw EchoRecoveryError.invalidArchive
    }
  }

  private func isUnique<Value: Hashable>(_ values: [Value]) -> Bool {
    Set(values).count == values.count
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

private struct EchoRecoveryArchive: Codable, Sendable {
  static let currentVersion = 1

  let formatVersion: Int
  let createdAt: Date
  let entries: [EchoEntry]
  let highlights: [EchoHighlight]
  let journals: [EchoOrganizedJournal]
  let weeklyReflections: [EchoWeeklyReflection]
  let carryForwards: [EchoCarryForward]
  let voiceAttachments: [EchoVoiceAttachment]
  let voiceFiles: [EchoRecoveryVoiceFile]

  init(
    formatVersion: Int,
    createdAt: Date,
    entries: [EchoEntry],
    highlights: [EchoHighlight],
    journals: [EchoOrganizedJournal],
    weeklyReflections: [EchoWeeklyReflection],
    carryForwards: [EchoCarryForward],
    voiceAttachments: [EchoVoiceAttachment],
    voiceFiles: [EchoRecoveryVoiceFile]
  ) {
    self.formatVersion = formatVersion
    self.createdAt = createdAt
    self.entries = entries
    self.highlights = highlights
    self.journals = journals
    self.weeklyReflections = weeklyReflections
    self.carryForwards = carryForwards
    self.voiceAttachments = voiceAttachments
    self.voiceFiles = voiceFiles
  }

  private enum CodingKeys: String, CodingKey {
    case formatVersion, createdAt, entries, highlights, journals, weeklyReflections
    case carryForwards, voiceAttachments, voiceFiles
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    formatVersion = try container.decode(Int.self, forKey: .formatVersion)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    entries = try container.decode([EchoEntry].self, forKey: .entries)
    highlights = try container.decode([EchoHighlight].self, forKey: .highlights)
    journals = try container.decode([EchoOrganizedJournal].self, forKey: .journals)
    weeklyReflections = try container.decode(
      [EchoWeeklyReflection].self,
      forKey: .weeklyReflections
    )
    carryForwards =
      try container.decodeIfPresent(
        [EchoCarryForward].self,
        forKey: .carryForwards
      ) ?? []
    voiceAttachments = try container.decode(
      [EchoVoiceAttachment].self,
      forKey: .voiceAttachments
    )
    voiceFiles = try container.decode([EchoRecoveryVoiceFile].self, forKey: .voiceFiles)
  }
}

private struct EchoRecoveryVoiceFile: Codable, Sendable {
  let attachmentID: UUID
  let data: Data
}

private struct EchoExportSnapshot {
  let generatedAt: Date
  let timeZone: TimeZone
  let entries: [EchoEntry]
  let highlights: [EchoHighlight]
  let journals: [EchoOrganizedJournal]
  let weeklyReflections: [EchoWeeklyReflection]
  let carryForwards: [EchoCarryForward]
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
      "",
    ]

    if days.isEmpty && snapshot.weeklyReflections.isEmpty && snapshot.carryForwards.isEmpty {
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
        sections.append("### Entries")
        sections.append("")
        for entry in dayEntries {
          let marker = highlightedEntryIDs.contains(entry.id) ? " · Saved" : ""
          sections.append("#### \(time(entry.createdAt, in: snapshot.timeZone))\(marker)")
          sections.append("")
          sections.append(entry.preferredText)
          if entry.preferredText != entry.originalText {
            sections.append("")
            sections.append("**Original capture**")
            sections.append("")
            sections.append(entry.originalText)
          }
          sections.append("")
        }
      }
    }

    if !snapshot.weeklyReflections.isEmpty {
      sections.append("# Weekly reflections")
      sections.append("")
      for reflection in snapshot.weeklyReflections.sorted(by: { $0.week < $1.week }) {
        sections.append(
          "## Week \(reflection.week.weekOfYear), \(reflection.week.yearForWeekOfYear)")
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

    if !snapshot.carryForwards.isEmpty {
      sections.append("# Carried forward")
      sections.append("")
      for item in snapshot.carryForwards.sorted(by: { $0.targetDay < $1.targetDay }) {
        sections.append("## For \(dayTitle(item.targetDay, in: snapshot.timeZone))")
        sections.append("")
        sections.append(item.text)
        sections.append("")
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
      .foregroundColor: CGColor(gray: 0.08, alpha: 1),
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
