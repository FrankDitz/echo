import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var visualWorldSelection: EchoVisualWorldSelection
  let dataExportService: EchoDataExportService

  @State private var exportDocument: EchoExportDocument?
  @State private var exportContentType = UTType.plainText
  @State private var exportFileName = "Echo Journal"
  @State private var isPreparingExport = false
  @State private var isShowingExporter = false
  @State private var exportErrorMessage: String?

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
                  ProgressView("Preparing private export…")
                    .font(EchoTypography.status)
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
    .frame(minWidth: 360, minHeight: 420)
    .fileExporter(
      isPresented: $isShowingExporter,
      document: exportDocument,
      contentType: exportContentType,
      defaultFilename: exportFileName
    ) { result in
      if case .failure(let error) = result {
        exportErrorMessage = error.localizedDescription
      }
      exportDocument = nil
    }
    .alert(
      "Export couldn’t be prepared",
      isPresented: Binding(
        get: { exportErrorMessage != nil },
        set: { if !$0 { exportErrorMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(exportErrorMessage ?? "Please try again.")
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
    .buttonStyle(.bordered)
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
        exportErrorMessage = error.localizedDescription
      }
    }
  }
}

private struct EchoExportDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.echoMarkdown, .pdf]

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

private extension UTType {
  static let echoMarkdown = UTType("net.daringfireball.markdown") ?? .plainText
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
