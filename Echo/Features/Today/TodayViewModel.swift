import AVFoundation
import Foundation
import Observation
import Speech

enum EchoVoiceCaptureError: Error, Equatable {
  case permissionDenied
  case recordingUnavailable
  case transcriptionUnavailable
  case noRecording
}

@MainActor
protocol EchoVoiceCaptureService: AnyObject {
  func requestRecordingPermission() async -> Bool
  func startRecording(to url: URL) throws
  func stopRecording() throws -> TimeInterval
  func play(url: URL) throws -> TimeInterval
  func transcribeOnDevice(url: URL) async throws -> String
}

@MainActor
final class SystemEchoVoiceCaptureService: NSObject, EchoVoiceCaptureService {
  private var recorder: AVAudioRecorder?
  private var player: AVAudioPlayer?

  func requestRecordingPermission() async -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized:
      return true
    case .notDetermined:
      return await AVCaptureDevice.requestAccess(for: .audio)
    case .denied, .restricted:
      return false
    @unknown default:
      return false
    }
  }

  func startRecording(to url: URL) throws {
    #if os(iOS)
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
      try session.setActive(true)
    #endif

    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44_100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]
    let recorder = try AVAudioRecorder(url: url, settings: settings)
    guard recorder.record() else { throw EchoVoiceCaptureError.recordingUnavailable }
    self.recorder = recorder
  }

  func stopRecording() throws -> TimeInterval {
    guard let recorder else { throw EchoVoiceCaptureError.noRecording }
    let duration = recorder.currentTime
    recorder.stop()
    self.recorder = nil
    #if os(iOS)
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    #endif
    return duration
  }

  func play(url: URL) throws -> TimeInterval {
    let player = try AVAudioPlayer(contentsOf: url)
    guard player.play() else { throw EchoVoiceCaptureError.recordingUnavailable }
    self.player = player
    return player.duration
  }

  func transcribeOnDevice(url: URL) async throws -> String {
    guard await requestSpeechPermission(),
      let recognizer = SFSpeechRecognizer(),
      recognizer.isAvailable,
      recognizer.supportsOnDeviceRecognition
    else {
      throw EchoVoiceCaptureError.transcriptionUnavailable
    }

    let request = SFSpeechURLRecognitionRequest(url: url)
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = false

    return try await withCheckedThrowingContinuation { continuation in
      let completion = SpeechRecognitionCompletion(continuation: continuation)
      recognizer.recognitionTask(with: request) { result, error in
        if let error {
          completion.resume(throwing: error)
        } else if let result, result.isFinal {
          completion.resume(returning: result.bestTranscription.formattedString)
        }
      }
    }
  }

  private func requestSpeechPermission() async -> Bool {
    let status = SFSpeechRecognizer.authorizationStatus()
    if status == .authorized { return true }
    guard status == .notDetermined else { return false }
    return await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
    }
  }
}

private final class SpeechRecognitionCompletion: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<String, any Error>?

  init(continuation: CheckedContinuation<String, any Error>) {
    self.continuation = continuation
  }

  func resume(returning value: String) {
    take()?.resume(returning: value)
  }

  func resume(throwing error: any Error) {
    take()?.resume(throwing: error)
  }

  private func take() -> CheckedContinuation<String, any Error>? {
    lock.lock()
    defer { lock.unlock() }
    defer { continuation = nil }
    return continuation
  }
}

enum TodayEntrySaveState: Equatable {
  case idle
  case saving
  case saved
  case failed
}

enum TodayJournalFailure: Equatable {
  case loadEntries
  case createEntry
  case highlightEntry
  case updateEntry
  case deleteEntry
}

struct TodayMemorySnapshot: Equatable, Sendable {
  var onThisDay: [EchoEntry] = []
  var unfinished: [EchoEntry] = []
  var saved: [EchoEntry] = []
}

enum CarryForwardActionState: Equatable {
  case idle
  case saving
  case saved
  case failed
}

@MainActor
@Observable
final class CarryForwardViewModel {
  private let repository: any EchoCarryForwardRepository
  private let calendar: Calendar
  private let now: () -> Date

  private(set) var todayItem: EchoCarryForward?
  private(set) var actionState: CarryForwardActionState = .idle

  init(
    repository: any EchoCarryForwardRepository,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping () -> Date = Date.init
  ) {
    self.repository = repository
    self.calendar = calendar
    self.now = now
  }

  func loadToday() async {
    do {
      todayItem = try await repository.carryForward(
        for: EchoDayIdentifier(containing: now(), calendar: calendar)
      )
    } catch {
      actionState = .failed
    }
  }

  @discardableResult
  func carryToTomorrow(
    text: String,
    sourceKind: EchoCarryForwardSourceKind,
    sourceDay: EchoDayIdentifier? = nil,
    sourceEntryID: UUID? = nil
  ) async -> Bool {
    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanText.isEmpty,
      let tomorrow = calendar.date(byAdding: .day, value: 1, to: now())
    else { return false }

    actionState = .saving
    let item = EchoCarryForward(
      text: cleanText,
      sourceKind: sourceKind,
      sourceDay: sourceDay,
      sourceEntryID: sourceEntryID,
      targetDay: EchoDayIdentifier(containing: tomorrow, calendar: calendar),
      createdAt: now()
    )
    do {
      try await repository.replace(item)
      actionState = .saved
      return true
    } catch {
      actionState = .failed
      return false
    }
  }

  @discardableResult
  func releaseToday() async -> Bool {
    guard let todayItem else { return false }
    do {
      try await repository.delete(id: todayItem.id)
      self.todayItem = nil
      actionState = .idle
      return true
    } catch {
      actionState = .failed
      return false
    }
  }

  func resetActionState() {
    actionState = .idle
  }
}

@MainActor
@Observable
final class TodayViewModel {
  private let repository: any EchoEntryRepository
  private let highlightRepository: (any EchoHighlightRepository)?
  private let voiceLifecycle: EchoVoiceAttachmentLifecycle?
  private let capturePipeline: (any EchoEntryCapturing)?
  private let calendar: Calendar
  private let now: () -> Date

  private(set) var displayedDate: Date
  private(set) var entries: [EchoEntry] = []
  private(set) var isLoading = false
  private(set) var saveState: TodayEntrySaveState = .idle
  private(set) var failure: TodayJournalFailure?
  private(set) var memories = TodayMemorySnapshot()
  private(set) var isLoadingMemories = false

  init(
    repository: any EchoEntryRepository,
    highlightRepository: (any EchoHighlightRepository)? = nil,
    voiceLifecycle: EchoVoiceAttachmentLifecycle? = nil,
    capturePipeline: (any EchoEntryCapturing)? = nil,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping () -> Date = Date.init
  ) {
    self.repository = repository
    self.highlightRepository = highlightRepository
    self.voiceLifecycle = voiceLifecycle
    self.capturePipeline = capturePipeline
    self.calendar = calendar
    self.now = now
    self.displayedDate = now()
  }

  func load() async {
    let currentDate = now()
    let day = EchoDayIdentifier(containing: currentDate, calendar: calendar)

    displayedDate = currentDate
    isLoading = true
    defer { isLoading = false }

    do {
      entries = try await repository.entries(for: day)
      failure = nil
    } catch {
      failure = .loadEntries
    }

    await loadMemories(relativeTo: currentDate)
  }

  private func loadMemories(relativeTo currentDate: Date) async {
    isLoadingMemories = true
    defer { isLoadingMemories = false }

    do {
      async let allEntriesRequest = repository.allEntries()
      async let highlightsRequest = highlightRepository?.allHighlights() ?? []
      let (allEntries, highlights) = try await (allEntriesRequest, highlightsRequest)
      let historicalEntries = allEntries.filter {
        $0.createdAt < currentDate
          && !calendar.isDate($0.createdAt, inSameDayAs: currentDate)
      }
      let recentCutoff =
        calendar.date(
          byAdding: .day,
          value: -90,
          to: currentDate
        ) ?? .distantPast
      let currentComponents = calendar.dateComponents([.month, .day], from: currentDate)
      let highlightedEntryIDs = Set(
        highlights.compactMap { highlight in
          highlight.target.kind == .entry ? highlight.target.entityID : nil
        }
      )

      memories = TodayMemorySnapshot(
        onThisDay: newestFirst(
          historicalEntries.filter { entry in
            let components = calendar.dateComponents([.month, .day], from: entry.createdAt)
            return components.month == currentComponents.month
              && components.day == currentComponents.day
          }
        ),
        unfinished: newestFirst(
          historicalEntries.filter { $0.createdAt >= recentCutoff && isUnfinished($0) }
        ),
        saved: newestFirst(
          historicalEntries.filter { highlightedEntryIDs.contains($0.id) }
        )
      )
    } catch {
      memories = TodayMemorySnapshot()
    }
  }

  private func isUnfinished(_ entry: EchoEntry) -> Bool {
    let text = entry.preferredText.lowercased()
    return text.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?")
      || ["still thinking", "need to", "want to", "come back", "later"]
        .contains(where: text.contains)
  }

  private func newestFirst(_ entries: [EchoEntry]) -> [EchoEntry] {
    Array(
      entries.sorted { lhs, rhs in
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
      }.prefix(3))
  }

  @discardableResult
  func createEntry(rawText: String, markImportant shouldHighlight: Bool = false) async -> Bool {
    guard containsWriting(rawText) else { return false }

    let timestamp = now()
    saveState = .saving
    do {
      let entry: EchoEntry
      if let capturePipeline {
        entry = try await capturePipeline.preserve(
          rawText,
          id: UUID(),
          createdAt: timestamp,
          type: .text,
          source: .user
        )
      } else {
        entry = EchoEntry(
          createdAt: timestamp,
          calendar: calendar,
          rawText: rawText
        )
        try await repository.create(entry)
      }
      entries = EchoEntryOrdering.chronological(entries + [entry])
      displayedDate = timestamp
      saveState = .saved
      failure = nil

      if shouldHighlight {
        await markImportant(entryID: entry.id)
      }

      if let capturePipeline {
        let processing = await capturePipeline.beginRefinement(entry)
        replaceVisibleEntry(processing)
        Task { [weak self] in
          let refined = await capturePipeline.finishRefinement(processing)
          self?.replaceVisibleEntry(refined)
        }
      }
      return true
    } catch {
      saveState = .failed
      failure = .createEntry
      return false
    }
  }

  @discardableResult
  func markImportant(entryID: UUID) async -> Bool {
    guard let highlightRepository else { return false }

    do {
      if try await highlightRepository.highlight(for: .entry(entryID)) == nil {
        try await highlightRepository.create(
          EchoHighlight(target: .entry(entryID), createdAt: now())
        )
      }
      return true
    } catch {
      failure = .highlightEntry
      return false
    }
  }

  @discardableResult
  func updateEntry(id: UUID, rawText: String) async -> Bool {
    guard containsWriting(rawText),
      let index = entries.firstIndex(where: { $0.id == id })
    else {
      return false
    }

    var entry = entries[index]
    entry.editRawText(rawText, at: now())

    saveState = .saving
    do {
      try await repository.update(entry)
      entries[index] = entry
      entries = EchoEntryOrdering.chronological(entries)
      saveState = .saved
      failure = nil
      return true
    } catch {
      saveState = .failed
      failure = .updateEntry
      return false
    }
  }

  @discardableResult
  func deleteEntry(id: UUID) async -> Bool {
    guard entries.contains(where: { $0.id == id }) else { return false }

    do {
      try await repository.delete(id: id)
      entries.removeAll(where: { $0.id == id })
      try? await voiceLifecycle?.removeAttachment(for: id)
      failure = nil
      return true
    } catch {
      failure = .deleteEntry
      return false
    }
  }

  func resetSaveState() {
    saveState = .idle
  }

  func retryRefinement(entryID: UUID) {
    guard let capturePipeline,
      let entry = entries.first(where: { $0.id == entryID })
    else { return }

    Task { [weak self] in
      let processing = await capturePipeline.beginRefinement(entry)
      self?.replaceVisibleEntry(processing)
      let refined = await capturePipeline.finishRefinement(processing)
      self?.replaceVisibleEntry(refined)
    }
  }

  @discardableResult
  func acceptRefinement(entryID: UUID) async -> Bool {
    await updateRefinementDecision(entryID: entryID, accepts: true)
  }

  @discardableResult
  func discardRefinement(entryID: UUID) async -> Bool {
    await updateRefinementDecision(entryID: entryID, accepts: false)
  }

  @discardableResult
  func saveAssistedText(entryID: UUID, text: String) async -> Bool {
    guard containsWriting(text),
      let index = entries.firstIndex(where: { $0.id == entryID })
    else {
      return false
    }

    var entry = entries[index]
    entry.setPolishedText(text, at: now())

    do {
      try await repository.update(entry)
      entries[index] = entry
      failure = nil
      return true
    } catch {
      failure = .updateEntry
      return false
    }
  }

  private func containsWriting(_ text: String) -> Bool {
    text.contains(where: { !$0.isWhitespace })
  }

  private func replaceVisibleEntry(_ entry: EchoEntry) {
    guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
    entries[index] = entry
  }

  private func updateRefinementDecision(entryID: UUID, accepts: Bool) async -> Bool {
    guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return false }
    var entry = entries[index]
    if accepts {
      entry.acceptRefinement(at: now())
    } else {
      entry.discardRefinement(at: now())
    }
    do {
      try await repository.update(entry)
      entries[index] = entry
      return true
    } catch {
      failure = .updateEntry
      return false
    }
  }
}

enum VoiceCaptureState: Equatable {
  case idle
  case requestingPermission
  case recording
  case processing
  case ready
  case playing
  case permissionDenied
  case failed
}

@MainActor
@Observable
final class VoiceCaptureViewModel {
  private let entryRepository: any EchoEntryRepository
  private let attachmentRepository: any EchoVoiceAttachmentRepository
  private let fileStore: EchoVoiceFileStore
  private let service: any EchoVoiceCaptureService
  private let capturePipeline: (any EchoEntryCapturing)?
  private let calendar: Calendar
  private let now: () -> Date
  private var pendingAttachmentID: UUID?
  private var pendingURL: URL?
  private var refinementTask: Task<EchoEntry, Never>?

  private(set) var state: VoiceCaptureState = .idle
  private(set) var statusMessage: String?

  init(
    entryRepository: any EchoEntryRepository,
    attachmentRepository: any EchoVoiceAttachmentRepository,
    fileStore: EchoVoiceFileStore,
    service: any EchoVoiceCaptureService,
    capturePipeline: (any EchoEntryCapturing)? = nil,
    calendar: Calendar = .autoupdatingCurrent,
    now: @escaping () -> Date = Date.init
  ) {
    self.entryRepository = entryRepository
    self.attachmentRepository = attachmentRepository
    self.fileStore = fileStore
    self.service = service
    self.capturePipeline = capturePipeline
    self.calendar = calendar
    self.now = now
  }

  func start() async {
    guard state != .recording, state != .processing else { return }
    state = .requestingPermission
    guard await service.requestRecordingPermission() else {
      state = .permissionDenied
      statusMessage = "Microphone access is off. Enable it in System Settings to record."
      return
    }

    do {
      let attachmentID = UUID()
      let url = try fileStore.destinationURL(for: attachmentID)
      try service.startRecording(to: url)
      pendingAttachmentID = attachmentID
      pendingURL = url
      statusMessage = "Recording stays on this device."
      state = .recording
    } catch {
      state = .failed
      statusMessage = "Echo could not start recording."
    }
  }

  func stopAndSave() async -> EchoEntry? {
    guard state == .recording,
      let attachmentID = pendingAttachmentID,
      let url = pendingURL
    else { return nil }

    state = .processing
    let timestamp = now()
    do {
      let duration = try service.stopRecording()
      var entry: EchoEntry
      if let capturePipeline {
        entry = try await capturePipeline.preserve(
          "Voice entry",
          id: UUID(),
          createdAt: timestamp,
          type: .voice,
          source: .user
        )
      } else {
        entry = EchoEntry(
          createdAt: timestamp,
          calendar: calendar,
          rawText: "Voice entry",
          type: .voice
        )
        try await entryRepository.create(entry)
      }
      var attachment = EchoVoiceAttachment(
        id: attachmentID,
        entryID: entry.id,
        createdAt: timestamp,
        relativeFileName: url.lastPathComponent,
        duration: duration
      )
      do {
        try await attachmentRepository.create(attachment)
      } catch {
        try? await entryRepository.delete(id: entry.id)
        try? fileStore.deleteFile(for: attachment)
        throw error
      }

      do {
        let transcript = try await service.transcribeOnDevice(url: url)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if !transcript.isEmpty {
          attachment.setTranscript(transcript)
          try await attachmentRepository.update(attachment)
          if let capturePipeline {
            entry = try await capturePipeline.replaceOriginalText(transcript, for: entry)
            entry = await capturePipeline.beginRefinement(entry)
            let processingEntry = entry
            refinementTask = Task {
              await capturePipeline.finishRefinement(processingEntry)
            }
          } else {
            entry = EchoEntry(
              id: entry.id,
              createdAt: entry.createdAt,
              modifiedAt: now(),
              day: entry.day,
              rawText: transcript,
              polishedText: nil,
              originalText: transcript,
              type: entry.type,
              source: entry.source
            )
            try await entryRepository.update(entry)
          }
          statusMessage =
            capturePipeline == nil
            ? "Saved with an on-device transcript."
            : "Captured. Cleanup is continuing in the background."
        } else {
          statusMessage = "Saved audio. No speech was detected for transcription."
        }
      } catch {
        statusMessage = "Saved audio. On-device transcription is unavailable."
      }

      pendingAttachmentID = nil
      pendingURL = nil
      state = .ready
      return entry
    } catch {
      try? FileManager.default.removeItem(at: url)
      pendingAttachmentID = nil
      pendingURL = nil
      state = .failed
      statusMessage = "The voice entry could not be saved."
      return nil
    }
  }

  func play(entryID: UUID) async {
    do {
      guard let attachment = try await attachmentRepository.attachment(for: entryID) else {
        throw EchoVoiceCaptureError.noRecording
      }
      let duration = try service.play(url: fileStore.url(for: attachment))
      state = .playing
      statusMessage = "Playing the private recording."
      let boundedDuration = min(max(duration, 0), 86_400)
      try? await Task.sleep(nanoseconds: UInt64(boundedDuration * 1_000_000_000))
      guard state == .playing else { return }
      state = .ready
      statusMessage = "Finished playing the private recording."
    } catch {
      state = .failed
      statusMessage = "The recording could not be played."
    }
  }

  func awaitPendingRefinement() async -> EchoEntry? {
    guard let refinementTask else { return nil }
    let entry = await refinementTask.value
    self.refinementTask = nil
    statusMessage =
      entry.refinementStatus == .failed
      ? "Saved. Cleanup can be retried from the entry."
      : "Saved with an on-device transcript."
    return entry
  }

  func resetStatus() {
    guard state != .recording, state != .processing else { return }
    state = .idle
    statusMessage = nil
  }
}
