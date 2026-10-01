import SwiftUI

enum EchoPrimarySection: String, CaseIterable, Identifiable {
  case today = "Today"
  case timeline = "Timeline"
  case reflection = "Day Reflection"
  case highlights = "Highlights"

  var id: Self { self }
}

struct EchoPrimaryNavigation: View {
  @Binding var selection: EchoPrimarySection
  let showSettings: () -> Void

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    ViewThatFits(in: .horizontal) {
      wideChrome
        .fixedSize(horizontal: true, vertical: false)
      compactChrome
    }
    .frame(maxWidth: EchoLayout.chromeMaxWidth)
    .padding(.horizontal, EchoLayout.pageHorizontalPadding)
    .padding(.vertical, EchoLayout.inlineSpacing)
    .frame(maxWidth: .infinity)
    .background {
      Rectangle().fill(world.canvas.opacity(0.28))
    }
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(world.separator)
        .frame(height: EchoShape.hairlineWidth)
    }
  }

  private var wideChrome: some View {
    HStack(spacing: EchoLayout.sectionSpacing) {
      wordmark
      navigationItems
      settingsButton
    }
  }

  private var compactChrome: some View {
    VStack(alignment: .leading, spacing: EchoLayout.microSpacing) {
      HStack {
        wordmark
        Spacer(minLength: EchoLayout.contentSpacing)
        compactSettingsButton
      }

      compactNavigationItems
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var wordmark: some View {
    Text("Echo")
      .font(EchoTypography.wordmark)
      .foregroundStyle(world.primaryText)
      .shadow(color: world.contentShadow, radius: 8, y: 2)
      .accessibilityAddTraits(.isHeader)
  }

  private var navigationItems: some View {
    HStack(spacing: EchoLayout.microSpacing) {
      ForEach(EchoPrimarySection.allCases) { section in
        Button {
          selection = section
        } label: {
          VStack(spacing: EchoLayout.tightSpacing) {
            Text(section.rawValue)
              .lineLimit(1)
            Capsule()
              .fill(selection == section ? world.accent : Color.clear)
              .frame(height: 3)
          }
          .font(EchoTypography.primaryNavigation)
          .foregroundStyle(selection == section ? world.accent : world.secondaryText)
          .padding(.horizontal, EchoLayout.inlineSpacing)
          .padding(.top, EchoLayout.inlineSpacing)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.rawValue)
        .accessibilityValue(selection == section ? "Selected" : "")
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Primary navigation")
  }

  private var compactNavigationItems: some View {
    HStack(spacing: EchoLayout.microSpacing) {
      ForEach(EchoPrimarySection.allCases) { section in
        Button {
          selection = section
        } label: {
          VStack(spacing: EchoLayout.microSpacing) {
            Text(section.rawValue)
              .lineLimit(1)
              .minimumScaleFactor(0.78)
            Capsule()
              .fill(selection == section ? world.accent : Color.clear)
              .frame(height: 3)
          }
          .font(.caption.weight(.semibold))
          .foregroundStyle(selection == section ? world.accent : world.secondaryText)
          .padding(.horizontal, EchoLayout.tightSpacing)
          .padding(.top, EchoLayout.tightSpacing)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(section.rawValue)
        .accessibilityValue(selection == section ? "Selected" : "")
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Primary navigation")
  }

  private var settingsButton: some View {
    Button(action: showSettings) {
      Image(systemName: "gearshape")
        .font(.body.weight(.semibold))
        .foregroundStyle(world.primaryText)
        .frame(width: 44, height: 44)
        .background(world.surfaceFill, in: Circle())
        .overlay {
          Circle()
            .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Settings")
  }

  private var compactSettingsButton: some View {
    Button(action: showSettings) {
      Image(systemName: "gearshape")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(world.primaryText)
        .frame(width: 38, height: 38)
        .background(world.surfaceFill, in: Circle())
        .overlay {
          Circle()
            .stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Settings")
  }
}
