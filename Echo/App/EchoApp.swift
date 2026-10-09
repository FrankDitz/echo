import SwiftData
import SwiftUI

@main
struct EchoApp: App {
  @State private var visualWorldSelection: EchoVisualWorldSelection
  @State private var privacyLockController: EchoPrivacyLockController
  @State private var refinementPreferences: EchoRefinementPreferences

  private let visualQAConfiguration: EchoVisualQAConfiguration
  private let modelContainer: ModelContainer
  private let todayViewModel: TodayViewModel
  private let timelineViewModel: TimelineViewModel
  private let highlightViewModel: EntryHighlightViewModel
  private let highlightsViewModel: HighlightsViewModel
  private let aiService: any EchoAIService
  private let journalRepository: any EchoOrganizedJournalRepository
  private let weeklyReflectionViewModel: WeeklyReflectionViewModel
  private let voiceCaptureViewModel: VoiceCaptureViewModel
  private let dataExportService: EchoDataExportService
  private let dataRecoveryService: EchoDataRecoveryService
  private let carryForwardViewModel: CarryForwardViewModel

  init() {
    let visualQAConfiguration = EchoVisualQAConfiguration.current
    self.visualQAConfiguration = visualQAConfiguration
#if DEBUG
    _visualWorldSelection = State(
      initialValue: EchoVisualWorldSelection(
        preferenceStore: visualQAConfiguration.isEnabled
          ? VolatileEchoVisualWorldPreferenceStore()
          : UserDefaultsEchoVisualWorldPreferenceStore(),
        defaultID: visualQAConfiguration.worldID ?? .cornerstoneSignal
      )
    )
    _privacyLockController = State(
      initialValue: EchoPrivacyLockController(
        preferenceStore: visualQAConfiguration.isEnabled
          ? VolatileEchoPrivacyLockPreferenceStore()
          : UserDefaultsEchoPrivacyLockPreferenceStore()
      )
    )
#else
    _visualWorldSelection = State(initialValue: EchoVisualWorldSelection())
    _privacyLockController = State(initialValue: EchoPrivacyLockController())
#endif
    let refinementPreferences = EchoRefinementPreferences()
    _refinementPreferences = State(initialValue: refinementPreferences)
    do {
#if DEBUG
      let container = try visualQAConfiguration.isEnabled
        ? EchoModelContainerFactory.makeInMemory()
        : EchoModelContainerFactory.makePersistent()
      if visualQAConfiguration.isEnabled {
        try EchoVisualQAFixture.seed(modelContainer: container)
      }
#else
      let container = try EchoModelContainerFactory.makePersistent()
#endif
      let entryRepository = SwiftDataEchoEntryRepository(modelContainer: container)
      let highlightRepository = SwiftDataEchoHighlightRepository(modelContainer: container)
      let aiService = DeterministicLocalAIService()
      let capturePipeline = EchoEntryCapturePipeline(
        repository: entryRepository,
        refiner: ConfiguredEchoWritingRefiner(preferences: refinementPreferences)
      )
      let journalRepository = SwiftDataEchoOrganizedJournalRepository(
        modelContainer: container
      )
      let weeklyRepository = SwiftDataEchoWeeklyReflectionRepository(
        modelContainer: container
      )
      let voiceAttachmentRepository = SwiftDataEchoVoiceAttachmentRepository(
        modelContainer: container
      )
      let carryForwardRepository = SwiftDataEchoCarryForwardRepository(
        modelContainer: container
      )
      let voiceFileStore = try EchoVoiceFileStore.applicationSupport()
      let voiceLifecycle = EchoVoiceAttachmentLifecycle(
        repository: voiceAttachmentRepository,
        fileStore: voiceFileStore
      )
      modelContainer = container
      self.aiService = aiService
      self.journalRepository = journalRepository
      weeklyReflectionViewModel = WeeklyReflectionViewModel(
        entryRepository: entryRepository,
        reflectionRepository: weeklyRepository,
        aiService: aiService
      )
      voiceCaptureViewModel = VoiceCaptureViewModel(
        entryRepository: entryRepository,
        attachmentRepository: voiceAttachmentRepository,
        fileStore: voiceFileStore,
        service: SystemEchoVoiceCaptureService(),
        capturePipeline: capturePipeline
      )
      dataExportService = EchoDataExportService(
        entryRepository: entryRepository,
        highlightRepository: highlightRepository,
        journalRepository: journalRepository,
        weeklyRepository: weeklyRepository,
        carryForwardRepository: carryForwardRepository
      )
      dataRecoveryService = EchoDataRecoveryService(
        entryRepository: entryRepository,
        highlightRepository: highlightRepository,
        journalRepository: journalRepository,
        weeklyRepository: weeklyRepository,
        voiceAttachmentRepository: voiceAttachmentRepository,
        carryForwardRepository: carryForwardRepository,
        voiceFileStore: voiceFileStore
      )
      todayViewModel = TodayViewModel(
        repository: entryRepository,
        highlightRepository: highlightRepository,
        voiceLifecycle: voiceLifecycle,
        capturePipeline: capturePipeline
      )
      timelineViewModel = TimelineViewModel(repository: entryRepository)
      highlightViewModel = EntryHighlightViewModel(repository: highlightRepository)
      highlightsViewModel = HighlightsViewModel(
        entryRepository: entryRepository,
        highlightRepository: highlightRepository,
        entryHighlightViewModel: highlightViewModel
      )
      carryForwardViewModel = CarryForwardViewModel(repository: carryForwardRepository)
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
        aiService: aiService,
        journalRepository: journalRepository,
        weeklyReflectionViewModel: weeklyReflectionViewModel,
        voiceCaptureViewModel: voiceCaptureViewModel,
        dataExportService: dataExportService,
        dataRecoveryService: dataRecoveryService,
        visualWorldSelection: visualWorldSelection,
        privacyLockController: privacyLockController,
        refinementPreferences: refinementPreferences
      )
      .environment(\.echoVisualWorld, visualWorldSelection.selectedWorld)
      .environment(privacyLockController)
      .environment(carryForwardViewModel)
      .tint(visualWorldSelection.selectedWorld.accent)
      .preferredColorScheme(visualWorldSelection.selectedWorld.preferredColorScheme)
    }
    .modelContainer(modelContainer)
  }
}

#if DEBUG
  struct EchoVisualQAConfiguration {
    static let current = EchoVisualQAConfiguration(arguments: ProcessInfo.processInfo.arguments)

    let isEnabled: Bool
    let worldID: EchoVisualWorldID?
    let initialSection: EchoPrimarySection?

    init(arguments: [String]) {
      isEnabled = arguments.contains("-echoVisualQA")
      worldID = Self.value(after: "-echoVisualWorld", in: arguments)
        .flatMap(EchoVisualWorldID.init(rawValue:))
      initialSection = Self.value(after: "-echoScreen", in: arguments)
        .flatMap { value in
          EchoPrimarySection.allCases.first {
            $0.rawValue.lowercased().replacingOccurrences(of: " ", with: "-") == value.lowercased()
          }
        }
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
      guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
        return nil
      }
      return arguments[index + 1]
    }
  }

  private struct VolatileEchoVisualWorldPreferenceStore: EchoVisualWorldPreferenceStore {
    func loadSelectedWorldID() -> EchoVisualWorldID? { nil }
    func saveSelectedWorldID(_: EchoVisualWorldID) {}
  }

  private struct VolatileEchoPrivacyLockPreferenceStore: EchoPrivacyLockPreferenceStore {
    func loadIsEnabled() -> Bool { false }
    func saveIsEnabled(_: Bool) {}
  }

  private enum EchoVisualQAFixture {
    static func seed(modelContainer: ModelContainer) throws {
      let context = ModelContext(modelContainer)
      let calendar = Calendar(identifier: .gregorian)
      let today = calendar.startOfDay(for: .now)
      let phrases = [
        "Started the morning with prayer and a quiet plan for the day.",
        "A hard conversation became clearer when I slowed down and listened.",
        "Made steady progress on work that has felt intimidating.",
        "A small act of kindness reminded me that ordinary moments matter.",
        "Took a walk after dinner and finally found words for what I was feeling.",
        "Grateful for the patience to begin again without rushing the process.",
        "Called someone I had been meaning to check on and left encouraged.",
        "Ended the day tired, but proud that I stayed present through it.",
      ]
      var entries: [EchoEntry] = []

      for dayOffset in 0..<18 {
        let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
        let entryCount = dayOffset.isMultiple(of: 3) ? 3 : 2
        for entryOffset in 0..<entryCount {
          let hour = 8 + (entryOffset * 5)
          let timestamp = calendar.date(byAdding: .hour, value: hour, to: day) ?? day
          let rawText = phrases[(dayOffset + entryOffset) % phrases.count]
          let entry = EchoEntry(
            createdAt: timestamp,
            calendar: calendar,
            rawText: rawText,
            polishedText: rawText,
            type: entryOffset == 1 && dayOffset.isMultiple(of: 4) ? .voice : .text
          )
          entries.append(entry)
          context.insert(try EchoPersistenceMapper.makeEntryRecord(from: entry))
          context.insert(try EchoPersistenceMapper.makeEntryRefinementRecord(from: entry))
        }
      }

      for entry in entries.enumerated().compactMap({ index, entry in
        index.isMultiple(of: 5) ? entry : nil
      }) {
        let highlight = EchoHighlight(target: .entry(entry.id), createdAt: entry.createdAt)
        context.insert(EchoPersistenceMapper.makeHighlightRecord(from: highlight))
      }

      let todayEntries = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
      if let dayID = todayEntries.first?.day {
        let journal = EchoOrganizedJournal(
          day: dayID,
          createdAt: today,
          body:
            "Today moved between pressure and peace. Slowing down made room for better decisions, honest conversation, and gratitude for progress that did not need to be dramatic to matter.",
          title: "Clarity in the Waiting",
          themes: ["Trust", "Patience", "Growth"],
          keyMoments: ["Chose patience in a difficult conversation", "Made meaningful progress"],
          reflectionQuestions: ["What is worth carrying into tomorrow?"],
          sourceEntryIDs: todayEntries.map(\.id),
          generator: .deterministicLocal
        )
        context.insert(try EchoPersistenceMapper.makeOrganizedJournalRecord(from: journal))
      }

      try context.save()
    }
  }
#else
  struct EchoVisualQAConfiguration {
    static let current = EchoVisualQAConfiguration()
    let isEnabled = false
    let worldID: EchoVisualWorldID? = nil
    let initialSection: EchoPrimarySection? = nil
  }
#endif
