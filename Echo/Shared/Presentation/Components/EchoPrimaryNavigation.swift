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
#if os(iOS)
    compactNavigation
#else
    regularNavigation
#endif
  }

  private var compactNavigation: some View {
    HStack(spacing: 0) {
      ForEach(EchoPrimarySection.allCases) { section in
        compactNavigationButton(section)
      }
    }
    .padding(.horizontal, 4)
    .offset(y: 17)
    .frame(maxWidth: .infinity, minHeight: 60)
    .background {
      Rectangle()
        .fill(world.surfaceFill.opacity(0.98))
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }
    .overlay(alignment: .top) {
      Rectangle()
        .fill(world.separator)
        .frame(height: EchoShape.hairlineWidth)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Primary navigation")
    .dynamicTypeSize(...DynamicTypeSize.large)
  }

  private var regularNavigation: some View {
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
    .dynamicTypeSize(...DynamicTypeSize.large)
  }

  private func compactNavigationButton(_ section: EchoPrimarySection) -> some View {
    Button {
      withAnimation(EchoMotion.animation(reduceMotion: reduceMotion)) {
        selection = section
      }
    } label: {
      VStack(spacing: 3) {
        Image(systemName: section.systemImage)
          .font(.system(size: 17, weight: selection == section ? .bold : .semibold))
          .frame(height: 20)

        Text(section.compactLabel)
          .font(.system(size: 11, weight: selection == section ? .bold : .semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.72)

        Capsule()
          .fill(selection == section ? world.accent : .clear)
          .frame(width: 22, height: 3)
      }
      .foregroundStyle(selection == section ? world.accent : world.secondaryText)
      .frame(maxWidth: .infinity, minHeight: 54)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(section.rawValue)
    .accessibilityValue(selection == section ? "Selected" : "")
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

#if os(macOS)
  struct EchoDesktopNavigation: View {
    @Binding var selection: EchoPrimarySection
    let isCompact: Bool
    let showSearch: () -> Void
    let showSettings: () -> Void

    @Environment(\.echoVisualWorld) private var world
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        brand
          .padding(.bottom, 28)

        searchButton
          .padding(.bottom, 18)

        VStack(spacing: 7) {
          ForEach(EchoPrimarySection.allCases) { section in
            navigationButton(section)
          }
        }

        Spacer(minLength: 24)

        privacyStatus
          .padding(.bottom, 12)

        utilityButton(
          title: "Settings",
          systemImage: EchoIcon.settings,
          action: showSettings
        )
        .keyboardShortcut(",", modifiers: [.command])
      }
      .padding(.horizontal, isCompact ? 12 : 18)
      .padding(.top, 24)
      .padding(.bottom, 18)
      .frame(width: isCompact ? 82 : 224, alignment: .leading)
      .frame(maxHeight: .infinity)
      .background {
        ZStack {
          Rectangle().fill(.ultraThinMaterial)
          LinearGradient(
            colors: [
              world.surfaceFill.opacity(0.98),
              world.canvas.opacity(0.94),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        }
      }
      .overlay(alignment: .trailing) {
        Rectangle()
          .fill(world.separator.opacity(0.7))
          .frame(width: EchoShape.hairlineWidth)
      }
      .foregroundStyle(world.primaryText)
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Primary navigation")
    }

    private var brand: some View {
      HStack(spacing: 10) {
        ZStack(alignment: .topTrailing) {
          Text(isCompact ? "E" : "Echo")
            .font(world.displayFont(size: isCompact ? 34 : 38, weight: .bold))

          Image(systemName: "crown.fill")
            .font(.system(size: 9, weight: .black))
            .foregroundStyle(world.accent)
            .offset(x: isCompact ? 7 : 9, y: -3)
        }

        if !isCompact {
          Spacer(minLength: 0)
          Text("JOURNAL")
            .font(.system(size: 8, weight: .black))
            .tracking(1.7)
            .foregroundStyle(world.secondaryText)
        }
      }
      .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Echo journal")
      .accessibilityAddTraits(.isHeader)
    }

    private var searchButton: some View {
      utilityButton(
        title: "Search writing",
        systemImage: "magnifyingglass",
        action: showSearch
      )
      .keyboardShortcut("f", modifiers: [.command])
    }

    private var privacyStatus: some View {
      HStack(spacing: 10) {
        Image(systemName: "lock.fill")
          .font(.caption.weight(.bold))
          .foregroundStyle(world.accent)
          .frame(width: 20)

        if !isCompact {
          VStack(alignment: .leading, spacing: 2) {
            Text("PRIVATE")
              .font(.system(size: 9, weight: .black))
              .tracking(1.4)
            Text("Stored on this Mac")
              .font(.caption2)
              .foregroundStyle(world.secondaryText)
          }
        }
      }
      .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
      .padding(.horizontal, 12)
      .background(world.selectedFill.opacity(0.24), in: RoundedRectangle(cornerRadius: 10))
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Private, stored on this Mac")
    }

    private func navigationButton(_ section: EchoPrimarySection) -> some View {
      Button {
        withAnimation(EchoMotion.animation(reduceMotion: reduceMotion)) {
          selection = section
        }
      } label: {
        HStack(spacing: 12) {
          Image(systemName: section.systemImage)
            .font(.system(size: 17, weight: selection == section ? .bold : .semibold))
            .frame(width: 24)

          if !isCompact {
            Text(section.rawValue)
              .font(.subheadline.weight(selection == section ? .bold : .semibold))
              .lineLimit(1)
          }

          Spacer(minLength: 0)

          if selection == section, !isCompact {
            Circle()
              .fill(world.accent)
              .frame(width: 6, height: 6)
          }
        }
        .foregroundStyle(selection == section ? world.primaryText : world.secondaryText)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .background {
          if selection == section {
            RoundedRectangle(cornerRadius: 11)
              .fill(world.selectedFill.opacity(0.62))
              .overlay(alignment: .leading) {
                Capsule()
                  .fill(world.accent)
                  .frame(width: 3, height: 24)
                  .padding(.leading, 4)
              }
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .keyboardShortcut(section.keyboardShortcut, modifiers: [.command])
      .help(section.rawValue)
      .accessibilityLabel(section.rawValue)
      .accessibilityValue(selection == section ? "Selected" : "")
    }

    private func utilityButton(
      title: String,
      systemImage: String,
      action: @escaping () -> Void
    ) -> some View {
      Button(action: action) {
        HStack(spacing: 12) {
          Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 24)

          if !isCompact {
            Text(title)
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)
          }

          Spacer(minLength: 0)
        }
        .foregroundStyle(world.primaryText)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(world.surfaceFill.opacity(0.46), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(world.separator.opacity(0.6), lineWidth: EchoShape.hairlineWidth)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help(title)
      .accessibilityLabel(title)
    }
  }
#endif

struct EchoBrandHeader: View {
  let showSearch: () -> Void
  let showSettings: () -> Void

  @Environment(\.echoVisualWorld) private var world

  var body: some View {
#if os(iOS)
    compactHeader
#else
    regularHeader
#endif
  }

  private var compactHeader: some View {
    HStack(spacing: 10) {
      ZStack(alignment: .topTrailing) {
        Text("Echo")
          .font(world.displayFont(size: 27))
          .foregroundStyle(world.primaryText)

        Image(systemName: "crown.fill")
          .font(.system(size: 8, weight: .bold))
          .foregroundStyle(world.accent)
          .offset(x: 8, y: -2)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Echo")
      .accessibilityAddTraits(.isHeader)

      Spacer()

      Button(action: showSearch) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 17, weight: .semibold))
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Search journal")

      Button(action: showSettings) {
        Image(systemName: "line.3.horizontal")
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open menu and settings")
    }
    .foregroundStyle(world.primaryText)
    .padding(.horizontal, 18)
    .padding(.vertical, 7)
    .frame(maxWidth: .infinity)
    .background(world.canvas.opacity(0.94))
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(world.separator.opacity(0.42))
        .frame(height: EchoShape.hairlineWidth)
    }
    .dynamicTypeSize(...DynamicTypeSize.large)
  }

  private var regularHeader: some View {
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
    .dynamicTypeSize(...DynamicTypeSize.large)
  }
}
