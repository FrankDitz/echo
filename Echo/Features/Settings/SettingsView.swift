import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var visualWorldSelection: EchoVisualWorldSelection
  let dataExportService: EchoDataExportService
  let dataRecoveryService: EchoDataRecoveryService
  let privacyLockController: EchoPrivacyLockController
  @Bindable var refinementPreferences: EchoRefinementPreferences

  @State private var exportDocument: EchoExportDocument?
  @State private var exportContentType = UTType.plainText
  @State private var exportFileName = "Echo Journal"
  @State private var isPreparingExport = false
  @State private var isShowingExporter = false
  @State private var isShowingRecoveryImporter = false
  @State private var isConfirmingRecovery = false
  @State private var pendingRecoveryData: Data?
  @State private var noticeMessage: String?

  var body: some View {
    NavigationStack {
      EchoWorldCanvas {
        ScrollView {
          VStack(alignment: .leading, spacing: EchoLayout.sectionSpacing) {
            EchoScreenHeader(
              title: "Visual World",
              subtitle: "Choose the atmosphere that surrounds your writing."
            )

            VStack(spacing: EchoLayout.rowSpacing) {
              ForEach(EchoVisualWorldID.allCases) { id in
                VisualWorldOption(
                  world: EchoVisualWorld.resolve(id),
                  isSelected: visualWorldSelection.selectedID == id
                ) {
                  visualWorldSelection.select(id)
                }
              }
            }

            EchoScreenHeader(
              title: "Writing Assistance",
              subtitle: "Choose whether Echo cleans up new entries after preserving the original."
            )

            EchoSurface {
              VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
                Picker("Automatic cleanup", selection: $refinementPreferences.provider) {
                  ForEach(EchoRefinementProvider.allCases) { provider in
                    Text(provider.title).tag(provider)
                  }
                }
                .pickerStyle(.segmented)

                Label(
                  refinementPreferences.provider == .onDevice
                    ? "Journal text is processed by Apple's on-device system language model. The original capture is always preserved first."
                    : "New entries are saved exactly as captured. You can enable on-device cleanup at any time.",
                  systemImage: refinementPreferences.provider == .onDevice
                    ? "apple.intelligence" : "text.badge.xmark"
                )
                .font(EchoTypography.supporting)
                .foregroundStyle(visualWorldSelection.selectedWorld.secondaryText)

                Text(
                  "Automatic cleanup corrects grammar, punctuation, capitalization, and speech-to-text sentence boundaries without summarizing or changing your meaning."
                )
                .font(EchoTypography.status)
                .foregroundStyle(visualWorldSelection.selectedWorld.secondaryText)
              }
            }

            EchoScreenHeader(
              title: "Privacy",
              subtitle: "Keep the journal hidden when Echo is not in use."
            )

            EchoSurface {
              VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
                HStack(spacing: EchoLayout.contentSpacing) {
                  Label("Echo Lock", systemImage: "lock.shield")
                    .font(EchoTypography.contentTitle)

                  Spacer()

                  Toggle(
                    "Echo Lock",
                    isOn: Binding(
                      get: { privacyLockController.isEnabled },
                      set: { shouldEnable in
                        Task { await privacyLockController.setEnabled(shouldEnable) }
                      }
                    )
                  )
                  .labelsHidden()
                  .disabled(privacyLockController.isAuthenticating)
                }

                Text(
                  "When enabled, Echo requires \(privacyLockController.authenticationMethodName) "
                    + "or your device passcode after leaving the app. Journal content is always "
                    + "hidden from the app switcher."
                )
                .font(EchoTypography.supporting)
                .foregroundStyle(visualWorldSelection.selectedWorld.secondaryText)

                if privacyLockController.isAuthenticating {
                  ProgressView("Verifying on this device…")
                    .font(EchoTypography.status)
                }

                if let notice = privacyLockController.noticeMessage {
                  Text(notice)
                    .font(EchoTypography.status)
                    .foregroundStyle(visualWorldSelection.selectedWorld.secondaryText)
                }

                if privacyLockController.isEnabled {
                  Button {
                    privacyLockController.lock()
                    dismiss()
                  } label: {
                    Label("Lock Echo Now", systemImage: "lock.fill")
                      .frame(maxWidth: .infinity)
                  }
                  .buttonStyle(
                    EchoDataActionButtonStyle(world: visualWorldSelection.selectedWorld)
                  )
                }
              }
            }

            EchoScreenHeader(
              title: "Your Data",
              subtitle: "Make a private, portable copy whenever you choose."
            )

            EchoSurface {
              VStack(alignment: .leading, spacing: EchoLayout.contentSpacing) {
                Label("Export journal", systemImage: "square.and.arrow.up")
                  .font(EchoTypography.contentTitle)

                Text(
                  "Echo prepares the file on this device and opens the system save panel. "
                    + "Nothing leaves the app until you select a destination."
                )
                .font(EchoTypography.supporting)
                .foregroundStyle(visualWorldSelection.selectedWorld.secondaryText)

                HStack(spacing: EchoLayout.rowSpacing) {
                  exportButton(
                    "Markdown",
                    systemImage: "doc.plaintext",
                    format: .markdown
                  )
                  exportButton(
                    "PDF",
                    systemImage: "doc.richtext",
                    format: .pdf
                  )
                }

                if isPreparingExport {
                  ProgressView("Preparing private file…")
                    .font(EchoTypography.status)
                }

                Divider()

                Label("Recovery backup", systemImage: "externaldrive.badge.timemachine")
                  .font(EchoTypography.contentTitle)

                Text(
                  "Create a complete local backup, including voice recordings, or merge one "
                    + "back into Echo. Restore never deletes or replaces current items."
                )
                .font(EchoTypography.supporting)
                .foregroundStyle(visualWorldSelection.selectedWorld.secondaryText)

                HStack(spacing: EchoLayout.rowSpacing) {
                  recoveryButton(
                    "Create Backup",
                    systemImage: "archivebox"
                  ) {
                    prepareRecoveryArchive()
                  }
                  recoveryButton(
                    "Restore Backup",
                    systemImage: "arrow.clockwise.icloud"
                  ) {
                    isShowingRecoveryImporter = true
                  }
                }
              }
            }

            Label(
              "Appearance stays separate from journal data. Exports are created only when you request one.",
              systemImage: "lock.shield"
            )
            .font(EchoTypography.supporting)
            .foregroundStyle(visualWorldSelection.selectedWorld.secondaryText)
          }
          .frame(maxWidth: EchoLayout.contentMaxWidth, alignment: .leading)
          .padding(.horizontal, EchoLayout.pageHorizontalPadding)
          .padding(.vertical, EchoLayout.pageVerticalPadding)
          .frame(maxWidth: .infinity)
        }
      }
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .echoSettingsMinimumSize()
    .fileExporter(
      isPresented: $isShowingExporter,
      document: exportDocument,
      contentType: exportContentType,
      defaultFilename: exportFileName
    ) { result in
      if case .failure(let error) = result {
        noticeMessage = error.localizedDescription
      }
      exportDocument = nil
    }
    .fileImporter(
      isPresented: $isShowingRecoveryImporter,
      allowedContentTypes: [.echoRecoveryArchive],
      allowsMultipleSelection: false,
      onCompletion: loadRecoveryArchive
    )
    .confirmationDialog(
      "Merge this backup into Echo?",
      isPresented: $isConfirmingRecovery,
      titleVisibility: .visible
    ) {
      Button("Restore Missing Items") {
        restorePendingArchive()
      }
      Button("Cancel", role: .cancel) {
        pendingRecoveryData = nil
      }
    } message: {
      Text("Existing entries and reflections stay unchanged. Echo only adds missing items.")
    }
    .alert(
      "Echo Data",
      isPresented: Binding(
        get: { noticeMessage != nil },
        set: { if !$0 { noticeMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(noticeMessage ?? "Please try again.")
    }
    .echoPrivacyProtected()
    .onDisappear {
      privacyLockController.cancelAuthentication()
    }
  }

  private func exportButton(
    _ title: String,
    systemImage: String,
    format: EchoExportFormat
  ) -> some View {
    Button {
      prepareExport(format)
    } label: {
      Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(EchoDataActionButtonStyle(world: visualWorldSelection.selectedWorld))
    .disabled(isPreparingExport)
  }

  private func recoveryButton(
    _ title: String,
    systemImage: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(EchoDataActionButtonStyle(world: visualWorldSelection.selectedWorld))
    .disabled(isPreparingExport)
  }

  private func prepareExport(_ format: EchoExportFormat) {
    isPreparingExport = true
    Task {
      defer { isPreparingExport = false }
      do {
        let export = try await dataExportService.makeExport(format: format)
        exportDocument = EchoExportDocument(data: export.data)
        exportContentType = format == .markdown ? .echoMarkdown : .pdf
        exportFileName = export.suggestedFileName
        isShowingExporter = true
      } catch {
        noticeMessage = error.localizedDescription
      }
    }
  }

  private func prepareRecoveryArchive() {
    isPreparingExport = true
    Task {
      defer { isPreparingExport = false }
      do {
        let export = try await dataRecoveryService.makeRecoveryArchive()
        exportDocument = EchoExportDocument(data: export.data)
        exportContentType = .echoRecoveryArchive
        exportFileName = export.suggestedFileName
        isShowingExporter = true
      } catch {
        noticeMessage = error.localizedDescription
      }
    }
  }

  private func loadRecoveryArchive(_ result: Result<[URL], any Error>) {
    do {
      let url = try result.get().first
      guard let url else { return }
      let isAccessing = url.startAccessingSecurityScopedResource()
      defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
      pendingRecoveryData = try Data(contentsOf: url)
      isConfirmingRecovery = true
    } catch {
      noticeMessage = error.localizedDescription
    }
  }

  private func restorePendingArchive() {
    guard let data = pendingRecoveryData else { return }
    pendingRecoveryData = nil
    isPreparingExport = true
    Task {
      defer { isPreparingExport = false }
      do {
        let result = try await dataRecoveryService.restore(from: data)
        noticeMessage = result.summary
      } catch {
        noticeMessage = error.localizedDescription
      }
    }
  }
}

extension View {
  @ViewBuilder
  fileprivate func echoSettingsMinimumSize() -> some View {
    #if os(macOS)
      frame(minWidth: 620, minHeight: 720)
    #else
      self
    #endif
  }
}

private struct EchoDataActionButtonStyle: ButtonStyle {
  let world: EchoVisualWorld

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(world.primaryText)
      .padding(.horizontal, EchoLayout.inlineSpacing)
      .padding(.vertical, 10)
      .background {
        RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
          .fill(world.selectedFill)
      }
      .overlay {
        RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
          .stroke(
            world.accent.opacity(configuration.isPressed ? 0.8 : 0.42),
            lineWidth: EchoShape.emphasizedBorderWidth
          )
      }
      .opacity(configuration.isPressed ? 0.78 : 1)
  }
}

private struct EchoExportDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.echoMarkdown, .pdf, .echoRecoveryArchive]

  let data: Data

  init(data: Data) {
    self.data = data
  }

  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}

extension UTType {
  fileprivate static let echoMarkdown = UTType("net.daringfireball.markdown") ?? .plainText
  fileprivate static let echoRecoveryArchive =
    UTType(
      filenameExtension: "echobackup",
      conformingTo: .data
    ) ?? .data
}

private struct VisualWorldOption: View {
  let world: EchoVisualWorld
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      EchoSurface {
        HStack(spacing: EchoLayout.contentSpacing) {
          Image(world.backgroundAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: 92, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: EchoShape.embeddedRadius))
            .overlay {
              RoundedRectangle(cornerRadius: EchoShape.embeddedRadius)
                .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
            }
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: EchoLayout.tightSpacing) {
            Text(world.displayName)
              .font(EchoTypography.contentTitle)

            Text(world.paletteDescription)
              .font(EchoTypography.supporting)
              .foregroundStyle(world.secondaryText)
              .multilineTextAlignment(.leading)
          }

          Spacer(minLength: EchoLayout.inlineSpacing)

          Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundStyle(isSelected ? world.accent : world.secondaryText)
            .accessibilityHidden(true)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityRepresentation {
      Button(world.displayName, action: action)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(
          "Changes Echo's appearance without changing journal entries."
        )
    }
  }
}
