import SwiftUI

struct AppShellView: View {
  @State private var selection: AppSection = .today
  @State private var isShowingSettings = false

  var body: some View {
    NavigationStack {
      TabView(selection: $selection) {
        placeholder(
          title: "Today",
          systemImage: "square.and.pencil",
          description: "A quiet place for whatever is on your mind."
        )
        .tag(AppSection.today)
        .tabItem {
          Label("Today", systemImage: "sun.max")
        }

        placeholder(
          title: "Timeline",
          systemImage: "clock.arrow.circlepath",
          description: "Your days will gather here over time."
        )
        .tag(AppSection.timeline)
        .tabItem {
          Label("Timeline", systemImage: "clock")
        }

        placeholder(
          title: "Highlights",
          systemImage: "bookmark",
          description: "Meaningful moments will be easy to revisit."
        )
        .tag(AppSection.highlights)
        .tabItem {
          Label("Highlights", systemImage: "bookmark")
        }
      }
      .navigationTitle(selection.title)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Settings", systemImage: "gearshape") {
            isShowingSettings = true
          }
        }
      }
    }
    .sheet(isPresented: $isShowingSettings) {
      SettingsPlaceholderView()
    }
  }

  private func placeholder(
    title: String,
    systemImage: String,
    description: String
  ) -> some View {
    ContentUnavailableView(
      title,
      systemImage: systemImage,
      description: Text(description)
    )
  }
}

private enum AppSection: Hashable {
  case today
  case timeline
  case highlights

  var title: String {
    switch self {
    case .today:
      "Today"
    case .timeline:
      "Timeline"
    case .highlights:
      "Highlights"
    }
  }
}

private struct SettingsPlaceholderView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ContentUnavailableView(
        "Settings",
        systemImage: "gearshape",
        description: Text("Preferences will be added as Echo grows.")
      )
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .frame(minWidth: 340, minHeight: 240)
  }
}
