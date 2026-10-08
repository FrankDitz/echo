import SwiftUI

enum EchoPrimarySection: String, CaseIterable, Identifiable {
  case today = "Today"
  case timeline = "Timeline"
  case reflection = "Day Reflection"
  case highlights = "Highlights"

  var id: Self { self }

  var keyboardShortcut: KeyEquivalent {
    switch self {
    case .today: "1"
    case .timeline: "2"
    case .reflection: "3"
    case .highlights: "4"
    }
  }
}

struct EchoPrimaryNavigation: View {
  @Binding var selection: EchoPrimarySection
  let showSettings: () -> Void

  @Environment(\.echoVisualWorld) private var world
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
      ZStack {
        Rectangle()
          .fill(.ultraThinMaterial)

        LinearGradient(
          colors: [world.surfaceFill.opacity(0.94), world.surfaceFill.opacity(0.72)],
          startPoint: .top,
          endPoint: .bottom
        )
      }
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
          withAnimation(EchoMotion.animation(reduceMotion: reduceMotion)) {
            selection = section
          }
        } label: {
          VStack(spacing: EchoLayout.tightSpacing) {
            Text(section.rawValue)
              .lineLimit(1)
            Capsule()
              .fill(selection == section ? world.accent : Color.clear)
              .frame(width: 36, height: 2)
          }
          .font(EchoTypography.primaryNavigation)
          .foregroundStyle(selection == section ? world.accent : world.secondaryText)
          .padding(.horizontal, EchoLayout.inlineSpacing)
          .padding(.top, EchoLayout.inlineSpacing)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(section.keyboardShortcut, modifiers: [.command])
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
          withAnimation(EchoMotion.animation(reduceMotion: reduceMotion)) {
            selection = section
          }
        } label: {
          VStack(spacing: EchoLayout.microSpacing) {
            Text(section.rawValue)
              .lineLimit(1)
              .minimumScaleFactor(0.78)
            Capsule()
              .fill(selection == section ? world.accent : Color.clear)
              .frame(width: 30, height: 2)
          }
          .font(.caption.weight(selection == section ? .semibold : .regular))
          .foregroundStyle(selection == section ? world.accent : world.secondaryText)
          .padding(.horizontal, EchoLayout.tightSpacing)
          .padding(.top, EchoLayout.tightSpacing)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(section.keyboardShortcut, modifiers: [.command])
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
      Image(systemName: EchoIcon.settings)
        .font(.body.weight(.medium))
        .foregroundStyle(world.secondaryText)
        .frame(width: 40, height: 40)
    }
    .buttonStyle(.plain)
    .keyboardShortcut(",", modifiers: [.command])
    .accessibilityLabel("Settings")
  }

  private var compactSettingsButton: some View {
    Button(action: showSettings) {
      Image(systemName: EchoIcon.settings)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(world.secondaryText)
        .frame(width: 36, height: 36)
    }
    .buttonStyle(.plain)
    .keyboardShortcut(",", modifiers: [.command])
    .accessibilityLabel("Settings")
  }
}
