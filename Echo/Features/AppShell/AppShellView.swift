import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

struct AppShellView: View {
  let todayViewModel: TodayViewModel
  let timelineViewModel: TimelineViewModel
  let highlightViewModel: EntryHighlightViewModel
  let highlightsViewModel: HighlightsViewModel
  let aiService: any EchoAIService
  let journalRepository: any EchoOrganizedJournalRepository
  let weeklyReflectionViewModel: WeeklyReflectionViewModel
  let voiceCaptureViewModel: VoiceCaptureViewModel
  let dataExportService: EchoDataExportService
  let dataRecoveryService: EchoDataRecoveryService
  let visualWorldSelection: EchoVisualWorldSelection
  let privacyLockController: EchoPrivacyLockController
  let refinementPreferences: EchoRefinementPreferences

  @State private var selection: EchoPrimarySection = .today
  @State private var selectedTimelineDayID: EchoDayIdentifier?
  @State private var isShowingSettings = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    ZStack {
      NavigationStack {
        selectedContent
          .id(selection)
          .transition(.opacity)
          .safeAreaInset(edge: .top, spacing: 0) {
            EchoBrandHeader {
              isShowingSettings = true
            }
          }
          .safeAreaInset(edge: .bottom, spacing: 0) {
            primaryNavigation
          }
      }
      .accessibilityHidden(isPrivacyShieldVisible)
      if !privacyLockController.isApplicationActive || privacyLockController.isLocked {
        EchoPrivacyShield(
          privacyLockController: privacyLockController,
          isApplicationActive: privacyLockController.isApplicationActive
        )
        .zIndex(100)
      }
    }
    .animation(EchoMotion.animation(reduceMotion: reduceMotion), value: selection)
    .sheet(isPresented: $isShowingSettings) {
      SettingsView(
        visualWorldSelection: visualWorldSelection,
        dataExportService: dataExportService,
        dataRecoveryService: dataRecoveryService,
        privacyLockController: privacyLockController,
        refinementPreferences: refinementPreferences
      )
    }
    .onChange(of: scenePhase, initial: true) { _, phase in
      switch phase {
      case .active:
        privacyLockController.applicationDidBecomeActive()
        Task { await privacyLockController.unlockIfNeeded() }
      case .inactive, .background:
        privacyLockController.applicationWillResignActive()
      @unknown default:
        privacyLockController.applicationWillResignActive()
      }
    }
    .onReceive(
      NotificationCenter.default.publisher(for: echoApplicationDidBecomeActiveNotification)
    ) { _ in
      privacyLockController.applicationDidBecomeActive()
      Task { await privacyLockController.unlockIfNeeded() }
    }
    .onReceive(
      NotificationCenter.default.publisher(for: echoApplicationWillResignActiveNotification)
    ) { _ in
      privacyLockController.applicationWillResignActive()
    }
  }

  private var isPrivacyShieldVisible: Bool {
    !privacyLockController.isApplicationActive || privacyLockController.isLocked
  }

  private var primaryNavigation: some View {
    EchoPrimaryNavigation(selection: $selection)
  }

  @ViewBuilder
  private var selectedContent: some View {
    switch selection {
    case .today:
      TodayView(
        viewModel: todayViewModel,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        voiceCaptureViewModel: voiceCaptureViewModel
      )
    case .timeline:
      TimelineView(
        viewModel: timelineViewModel,
        selectedDayID: $selectedTimelineDayID,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        journalRepository: journalRepository
      )
    case .calendar:
      LifeCalendarView(
        days: timelineViewModel.days,
        selectedDayID: $selectedTimelineDayID,
        initialDate: timelineViewModel.mostRecentTimelineDate,
        showsDismissButton: false
      ) {
        selection = .timeline
      }
      .task {
        await timelineViewModel.load()
      }
    case .reflection:
      DayReflectionView(
        todayViewModel: todayViewModel,
        timelineViewModel: timelineViewModel,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        journalRepository: journalRepository,
        weeklyViewModel: weeklyReflectionViewModel
      )
    case .highlights:
      HighlightsView(
        viewModel: highlightsViewModel,
        highlightViewModel: highlightViewModel,
        aiService: aiService,
        journalRepository: journalRepository
      )
    }
  }
}

struct EchoPrivacyShield: View {
  @Environment(\.echoVisualWorld) private var world
  let privacyLockController: EchoPrivacyLockController
  let isApplicationActive: Bool

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      RadialGradient(
        colors: [world.accent.opacity(0.24), .clear],
        center: .top,
        startRadius: 8,
        endRadius: 540
      )
      .ignoresSafeArea()

      VStack(spacing: EchoLayout.contentSpacing) {
        Image(systemName: "lock.shield.fill")
          .font(.system(size: 44, weight: .semibold))
          .foregroundStyle(world.accent)
          .accessibilityHidden(true)

        Text("Echo is private")
          .font(EchoTypography.screenTitle)
          .foregroundStyle(world.primaryText)

        Text("Your journal is hidden until you unlock it.")
          .font(EchoTypography.supporting)
          .foregroundStyle(world.secondaryText)
          .multilineTextAlignment(.center)

        if isApplicationActive, privacyLockController.isEnabled {
          Button {
            Task { await privacyLockController.unlockIfNeeded() }
          } label: {
            if privacyLockController.isAuthenticating {
              ProgressView()
                .frame(maxWidth: .infinity)
            } else {
              Label(
                "Unlock with \(privacyLockController.authenticationMethodName)",
                systemImage: "lock.open.fill"
              )
              .frame(maxWidth: .infinity)
            }
          }
          .buttonStyle(.borderedProminent)
          .tint(world.accent)
          .disabled(privacyLockController.isAuthenticating)
          .frame(maxWidth: 360)

          if let notice = privacyLockController.noticeMessage {
            Text(notice)
              .font(EchoTypography.status)
              .foregroundStyle(world.secondaryText)
              .multilineTextAlignment(.center)
              .frame(maxWidth: 420)
          }
        }
      }
      .padding(EchoLayout.pageHorizontalPadding)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Echo privacy lock")
  }
}

private struct EchoPrivacyProtectionModifier: ViewModifier {
  @Environment(EchoPrivacyLockController.self) private var privacyLockController

  func body(content: Content) -> some View {
    content
      .accessibilityHidden(isPrivacyShieldVisible)
      .overlay {
        if isPrivacyShieldVisible {
          EchoPrivacyShield(
            privacyLockController: privacyLockController,
            isApplicationActive: privacyLockController.isApplicationActive
          )
        }
      }
  }

  private var isPrivacyShieldVisible: Bool {
    !privacyLockController.isApplicationActive || privacyLockController.isLocked
  }
}

#if os(macOS)
  private let echoApplicationDidBecomeActiveNotification =
    NSApplication.didBecomeActiveNotification
  private let echoApplicationWillResignActiveNotification =
    NSApplication.willResignActiveNotification
#else
  private let echoApplicationDidBecomeActiveNotification =
    UIApplication.didBecomeActiveNotification
  private let echoApplicationWillResignActiveNotification =
    UIApplication.willResignActiveNotification
#endif

extension View {
  func echoPrivacyProtected() -> some View {
    modifier(EchoPrivacyProtectionModifier())
  }
}
