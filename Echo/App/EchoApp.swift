import SwiftData
import SwiftUI

@main
struct EchoApp: App {
  @State private var visualWorldSelection = EchoVisualWorldSelection()
  @State private var privacyLockController = EchoPrivacyLockController()
  @State private var refinementPreferences: EchoRefinementPreferences

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
    let refinementPreferences = EchoRefinementPreferences()
    _refinementPreferences = State(initialValue: refinementPreferences)
    do {
      let container = try EchoModelContainerFactory.makePersistent()
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
