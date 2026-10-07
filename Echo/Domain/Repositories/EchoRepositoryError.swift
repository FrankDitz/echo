import Foundation

enum EchoRepositoryError: Error, Equatable, Sendable {
  case duplicateEntry(UUID)
  case entryNotFound(UUID)
  case duplicateHighlight(UUID)
  case duplicateHighlightTarget(EchoHighlightTarget)
  case highlightNotFound(UUID)
  case duplicateOrganizedJournal(UUID)
  case duplicateOrganizedJournalDay(EchoDayIdentifier)
  case organizedJournalNotFound(UUID)
  case duplicateWeeklyReflection(UUID)
  case duplicateWeeklyReflectionWeek(EchoWeekIdentifier)
  case weeklyReflectionNotFound(UUID)
  case duplicateVoiceAttachment(UUID)
  case duplicateVoiceAttachmentEntry(UUID)
  case voiceAttachmentNotFound(UUID)
  case duplicateCarryForward(UUID)
  case duplicateCarryForwardTargetDay(EchoDayIdentifier)
  case carryForwardNotFound(UUID)
}
