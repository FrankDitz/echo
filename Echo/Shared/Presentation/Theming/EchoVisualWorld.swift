import SwiftUI

enum EchoVisualWorldID: String, CaseIterable, Codable {
  // The raw value remains stable so existing appearance preferences migrate
  // without touching journal storage.
  case cornerstoneSignal = "teal-immersion"
  case goldStandard = "crimson-static"
  case kingdomGreen = "sodium-fog"
  case covenantBlue = "electric-blue-hour"
}

enum EchoScreenRole: Hashable {
  case today
  case timeline
  case reflection
  case highlights
  case calendar
  case editor
  case settings
  case utility
}

struct EchoVisualWorldArtwork {
  let today: String
  let timeline: String
  let reflection: String
  let highlights: String
  let calendar: String
  let editor: String
  let settings: String

  init(
    today: String,
    timeline: String,
    reflection: String,
    highlights: String,
    calendar: String,
    editor: String,
    settings: String
  ) {
    self.today = today
    self.timeline = timeline
    self.reflection = reflection
    self.highlights = highlights
    self.calendar = calendar
    self.editor = editor
    self.settings = settings
  }

  init(shared assetName: String) {
    today = assetName
    timeline = assetName
    reflection = assetName
    highlights = assetName
    calendar = assetName
    editor = assetName
    settings = assetName
  }

  func assetName(for screen: EchoScreenRole) -> String {
    switch screen {
    case .today: today
    case .timeline: timeline
    case .reflection: reflection
    case .highlights: highlights
    case .calendar: calendar
    case .editor: editor
    case .settings, .utility: settings
    }
  }
}

extension EchoVisualWorldID: Identifiable {
  var id: Self { self }
}

struct EchoVisualWorld {
  let id: EchoVisualWorldID
  let displayName: String
  let paletteDescription: String
  let artwork: EchoVisualWorldArtwork
  let canvas: Color
  let primaryText: Color
  let secondaryText: Color
  let accent: Color
  let separator: Color
  let error: Color
  let saved: Color
  let surfaceFill: Color
  let selectedFill: Color
  let contentShadow: Color
  let preferredColorScheme: ColorScheme

  static let cornerstoneSignal = EchoVisualWorld(
    id: .cornerstoneSignal,
    displayName: "Cornerstone Signal",
    paletteDescription: "Warm newsprint, carbon, petrol teal, vermilion, and gold.",
    artwork: EchoVisualWorldArtwork(
      today: "CornerstoneSignalBackground",
      timeline: "CornerstoneSignalTimelineBackground",
      reflection: "CornerstoneSignalReflectionBackground",
      highlights: "CornerstoneSignalHighlightsBackground",
      calendar: "CornerstoneSignalCalendarBackground",
      editor: "CornerstoneSignalReflectionBackground",
      settings: "CornerstoneSignalBackground"
    ),
    canvas: Color(red: 0.91, green: 0.87, blue: 0.76),
    primaryText: Color(red: 0.075, green: 0.07, blue: 0.06),
    secondaryText: Color(red: 0.26, green: 0.25, blue: 0.21),
    accent: Color(red: 0.76, green: 0.12, blue: 0.08),
    separator: Color(red: 0.08, green: 0.28, blue: 0.28).opacity(0.38),
    error: Color(red: 0.72, green: 0.06, blue: 0.04),
    saved: Color(red: 0.02, green: 0.31, blue: 0.3),
    surfaceFill: Color(red: 0.96, green: 0.93, blue: 0.84).opacity(0.92),
    selectedFill: Color(red: 0.86, green: 0.68, blue: 0.2).opacity(0.5),
    contentShadow: Color.black.opacity(0.24),
    preferredColorScheme: .light
  )

  static let goldStandard = EchoVisualWorld(
    id: .goldStandard,
    displayName: "Gold Standard",
    paletteDescription: "Mustard gold, charcoal, warm cream, and burnished light.",
    artwork: EchoVisualWorldArtwork(
      today: "GoldStandardBackground",
      timeline: "GoldStandardTimelineBackground",
      reflection: "GoldStandardReflectionBackground",
      highlights: "GoldStandardHighlightsBackground",
      calendar: "GoldStandardCalendarBackground",
      editor: "GoldStandardReflectionBackground",
      settings: "GoldStandardBackground"
    ),
    canvas: Color(red: 0.94, green: 0.63, blue: 0.06),
    primaryText: Color(red: 0.07, green: 0.06, blue: 0.045),
    secondaryText: Color(red: 0.17, green: 0.13, blue: 0.065),
    accent: Color(red: 0.08, green: 0.075, blue: 0.06),
    separator: Color(red: 0.25, green: 0.19, blue: 0.07).opacity(0.4),
    error: Color(red: 0.68, green: 0.09, blue: 0.045),
    saved: Color(red: 0.13, green: 0.33, blue: 0.2),
    surfaceFill: Color(red: 1, green: 0.94, blue: 0.76).opacity(0.91),
    selectedFill: Color(red: 0.98, green: 0.72, blue: 0.13).opacity(0.7),
    contentShadow: Color.black.opacity(0.25),
    preferredColorScheme: .light
  )

  static let kingdomGreen = EchoVisualWorld(
    id: .kingdomGreen,
    displayName: "Kingdom Green",
    paletteDescription: "Deep emerald, warm ivory, near-black, and quiet antique gold.",
    artwork: EchoVisualWorldArtwork(
      today: "KingdomGreenBackground",
      timeline: "KingdomGreenTimelineBackground",
      reflection: "KingdomGreenReflectionBackground",
      highlights: "KingdomGreenHighlightsBackground",
      calendar: "KingdomGreenCalendarBackground",
      editor: "KingdomGreenReflectionBackground",
      settings: "KingdomGreenBackground"
    ),
    canvas: Color(red: 0.008, green: 0.16, blue: 0.105),
    primaryText: Color(red: 0.98, green: 0.96, blue: 0.86),
    secondaryText: Color(red: 0.78, green: 0.82, blue: 0.68),
    accent: Color(red: 0.91, green: 0.75, blue: 0.26),
    separator: Color(red: 0.78, green: 0.7, blue: 0.38).opacity(0.38),
    error: Color(red: 0.98, green: 0.39, blue: 0.28),
    saved: Color(red: 0.45, green: 0.9, blue: 0.64),
    surfaceFill: Color(red: 0.015, green: 0.22, blue: 0.14).opacity(0.86),
    selectedFill: Color(red: 0.39, green: 0.48, blue: 0.13).opacity(0.52),
    contentShadow: Color.black.opacity(0.58),
    preferredColorScheme: .dark
  )

  static let covenantBlue = EchoVisualWorld(
    id: .covenantBlue,
    displayName: "Covenant Blue",
    paletteDescription: "Covenant cobalt, midnight navy, warm white, and pale silver.",
    artwork: EchoVisualWorldArtwork(shared: "CovenantBlueBackground"),
    canvas: Color(red: 0.015, green: 0.075, blue: 0.22),
    primaryText: Color(red: 0.97, green: 0.975, blue: 0.94),
    secondaryText: Color(red: 0.7, green: 0.81, blue: 0.94),
    accent: Color(red: 0.25, green: 0.58, blue: 1),
    separator: Color(red: 0.52, green: 0.7, blue: 0.94).opacity(0.42),
    error: Color(red: 1, green: 0.4, blue: 0.32),
    saved: Color(red: 0.52, green: 0.9, blue: 0.78),
    surfaceFill: Color(red: 0.025, green: 0.12, blue: 0.31).opacity(0.86),
    selectedFill: Color(red: 0.08, green: 0.3, blue: 0.72).opacity(0.58),
    contentShadow: Color.black.opacity(0.62),
    preferredColorScheme: .dark
  )

  static func resolve(_ id: EchoVisualWorldID) -> EchoVisualWorld {
    switch id {
    case .cornerstoneSignal:
      .cornerstoneSignal
    case .goldStandard:
      .goldStandard
    case .kingdomGreen:
      .kingdomGreen
    case .covenantBlue:
      .covenantBlue
    }
  }

  func backgroundAssetName(for screen: EchoScreenRole) -> String {
    artwork.assetName(for: screen)
  }

  func displayFont(
    size: CGFloat,
    relativeTo textStyle: Font.TextStyle = .largeTitle,
    weight: Font.Weight = .bold
  ) -> Font {
    if id == .goldStandard {
      return Font.custom(
        "Avenir Next Condensed",
        size: size,
        relativeTo: textStyle
      )
      .weight(.heavy)
    }

    return .system(size: size, weight: weight, design: .serif)
  }
}

private struct EchoVisualWorldKey: EnvironmentKey {
  static let defaultValue = EchoVisualWorld.cornerstoneSignal
}

extension EnvironmentValues {
  var echoVisualWorld: EchoVisualWorld {
    get { self[EchoVisualWorldKey.self] }
    set { self[EchoVisualWorldKey.self] = newValue }
  }
}
