import SwiftUI

enum EchoPrimarySection: String, CaseIterable, Identifiable {
  case today = "Today"
  case timeline = "Timeline"
  case calendar = "Calendar"
  case reflection = "Day Reflection"
  case highlights = "Highlights"

  var id: Self { self }

  var keyboardShortcut: KeyEquivalent {
    switch self {
    case .today: "1"
    case .timeline: "2"
    case .calendar: "3"
    case .reflection: "4"
    case .highlights: "5"
    }
  }

  var systemImage: String {
    switch self {
    case .today: "house.fill"
    case .timeline: "list.bullet"
    case .calendar: "calendar"
    case .reflection: "chart.bar.fill"
    case .highlights: "bookmark.fill"
    }
  }

  var compactLabel: String {
    self == .reflection ? "Reflect" : rawValue
  }
}

struct EchoPrimaryNavigation: View {
  @Binding var selection: EchoPrimarySection

  @Environment(\.echoVisualWorld) private var world
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack(spacing: EchoLayout.microSpacing) {
      ForEach(EchoPrimarySection.allCases) { section in
        navigationButton(section)
      }
    }
    .frame(maxWidth: 720)
    .padding(.horizontal, EchoLayout.inlineSpacing)
    .padding(.vertical, EchoLayout.tightSpacing)
    .frame(maxWidth: .infinity)
    .background {
      ZStack {
        Rectangle()
          .fill(.ultraThinMaterial)

        LinearGradient(
          colors: [world.surfaceFill.opacity(0.98), world.surfaceFill.opacity(0.9)],
          startPoint: .top,
          endPoint: .bottom
        )
      }
    }
    .overlay(alignment: .top) {
      Rectangle()
        .fill(world.separator)
        .frame(height: EchoShape.hairlineWidth)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Primary navigation")
  }

  private func navigationButton(_ section: EchoPrimarySection) -> some View {
    Button {
      withAnimation(EchoMotion.animation(reduceMotion: reduceMotion)) {
        selection = section
      }
    } label: {
      VStack(spacing: EchoLayout.microSpacing) {
        Image(systemName: section.systemImage)
          .font(.system(size: 16, weight: selection == section ? .bold : .medium))
          .frame(height: 19)

        Text(section.compactLabel)
          .font(.caption2.weight(selection == section ? .bold : .medium))
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }
      .foregroundStyle(selection == section ? world.accent : world.secondaryText)
      .frame(maxWidth: .infinity, minHeight: 44)
      .background {
        if selection == section {
          RoundedRectangle(cornerRadius: 10)
            .fill(world.selectedFill.opacity(0.54))
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .keyboardShortcut(section.keyboardShortcut, modifiers: [.command])
    .accessibilityLabel(section.rawValue)
    .accessibilityValue(selection == section ? "Selected" : "")
  }
}

struct EchoBrandHeader: View {
  let showSettings: () -> Void

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
    HStack(spacing: EchoLayout.contentSpacing) {
      Text("Echo")
        .font(world.displayFont(size: 34))
        .foregroundStyle(world.primaryText)
        .shadow(color: world.contentShadow, radius: 8, y: 2)
        .accessibilityAddTraits(.isHeader)

      Image(systemName: "crown.fill")
        .font(.caption.weight(.bold))
        .foregroundStyle(world.accent)
        .offset(x: -14, y: -13)
        .accessibilityHidden(true)

      Spacer()

      Button(action: showSettings) {
        Image(systemName: EchoIcon.settings)
          .font(.body.weight(.semibold))
          .foregroundStyle(world.primaryText)
          .frame(width: 42, height: 42)
          .background(.ultraThinMaterial, in: Circle())
          .overlay {
            Circle().stroke(world.separator, lineWidth: EchoShape.hairlineWidth)
          }
      }
      .buttonStyle(.plain)
      .keyboardShortcut(",", modifiers: [.command])
      .accessibilityLabel("Settings")
    }
    .frame(maxWidth: EchoLayout.chromeMaxWidth)
    .padding(.horizontal, EchoLayout.pageHorizontalPadding)
    .padding(.vertical, EchoLayout.tightSpacing)
    .frame(maxWidth: .infinity)
  }
}
