import SwiftUI

enum EchoVisualWorldID: String, CaseIterable, Codable {
  case tealImmersion = "teal-immersion"
  case crimsonStatic = "crimson-static"
}

extension EchoVisualWorldID: Identifiable {
  var id: Self { self }
}

struct EchoVisualWorld {
  let id: EchoVisualWorldID
  let displayName: String
  let paletteDescription: String
  let backgroundAssetName: String
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

  static let tealImmersion = EchoVisualWorld(
    id: .tealImmersion,
    displayName: "Teal Immersion",
    paletteDescription: "Petroleum teal, luminous aqua, and warm city light.",
    backgroundAssetName: "TealImmersionBackground",
    canvas: Color(red: 0.015, green: 0.11, blue: 0.13),
    primaryText: Color(red: 0.94, green: 0.99, blue: 0.98),
    secondaryText: Color(red: 0.68, green: 0.84, blue: 0.83),
    accent: Color(red: 0.18, green: 0.94, blue: 0.9),
    separator: Color(red: 0.35, green: 0.79, blue: 0.77).opacity(0.34),
    error: Color(red: 1, green: 0.48, blue: 0.4),
    saved: Color(red: 0.41, green: 0.93, blue: 0.7),
    surfaceFill: Color(red: 0.02, green: 0.16, blue: 0.18).opacity(0.74),
    selectedFill: Color(red: 0.08, green: 0.48, blue: 0.47).opacity(0.42),
    contentShadow: Color.black.opacity(0.55)
  )

  static let crimsonStatic = EchoVisualWorld(
    id: .crimsonStatic,
    displayName: "Crimson Static",
    paletteDescription: "Oxblood, ember red, wet silver, and black-cherry rain.",
    backgroundAssetName: "CrimsonStaticBackground",
    canvas: Color(red: 0.09, green: 0.015, blue: 0.025),
    primaryText: Color(red: 1, green: 0.96, blue: 0.95),
    secondaryText: Color(red: 0.89, green: 0.72, blue: 0.71),
    accent: Color(red: 1, green: 0.28, blue: 0.23),
    separator: Color(red: 0.91, green: 0.45, blue: 0.43).opacity(0.38),
    error: Color(red: 1, green: 0.69, blue: 0.32),
    saved: Color(red: 0.94, green: 0.82, blue: 0.77),
    surfaceFill: Color(red: 0.13, green: 0.025, blue: 0.035).opacity(0.79),
    selectedFill: Color(red: 0.56, green: 0.06, blue: 0.07).opacity(0.44),
    contentShadow: Color.black.opacity(0.66)
  )

  static func resolve(_ id: EchoVisualWorldID) -> EchoVisualWorld {
    switch id {
    case .tealImmersion:
      .tealImmersion
    case .crimsonStatic:
      .crimsonStatic
    }
  }
}

private struct EchoVisualWorldKey: EnvironmentKey {
  static let defaultValue = EchoVisualWorld.tealImmersion
}

extension EnvironmentValues {
  var echoVisualWorld: EchoVisualWorld {
    get { self[EchoVisualWorldKey.self] }
    set { self[EchoVisualWorldKey.self] = newValue }
  }
}
