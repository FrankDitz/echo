import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var visualWorldSelection: EchoVisualWorldSelection

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

            Label(
              "Appearance is stored separately from your journal. Changing it never changes your entries.",
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
  }
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
