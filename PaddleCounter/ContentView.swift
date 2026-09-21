import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var detector = AudioDetector()
    @StateObject private var game = GameController()
    @StateObject private var milestoneFeedback = MilestoneFeedback()
    @Query(sort: \SessionRecord.startedAt, order: .reverse) private var sessions: [SessionRecord]

    @AppStorage("rallySilenceSeconds") private var silenceSeconds = 3.0
    @AppStorage("minimumRallyHits") private var minimumHits = 1
    @AppStorage("soundSensitivity") private var soundSensitivity = 0.9
    @AppStorage("sensitivityTuningVersion") private var sensitivityTuningVersion = 0
    @AppStorage("milestoneSoundsEnabled") private var milestoneSoundsEnabled = true

    @State private var selectedTab = 0
    @State private var errorMessage: String?
    @State private var showingSettings = false

    private var detectorIsReady: Bool {
        detector.positiveExamples >= 8
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayScreen(
                game: game,
                detector: detector,
                detectorIsReady: detectorIsReady,
                onPrimaryAction: detectorIsReady ? toggleSession : { selectedTab = 1 },
                onCalibration: { selectedTab = 1 },
                onSettings: { showingSettings = true }
            )
            .tag(0)
            .tabItem { Label("Play", systemImage: "waveform") }

            CalibrationScreen(
                detector: detector,
                sessionIsActive: game.active,
                soundSensitivity: $soundSensitivity,
                onError: { errorMessage = $0 }
            )
            .tag(1)
            .tabItem { Label("Calibrate", systemImage: "scope") }

            HistoryScreen(sessions: sessions)
                .tag(2)
                .tabItem { Label("History", systemImage: "chart.bar.fill") }
        }
        .tint(PCTheme.lime)
        .task {
            if sensitivityTuningVersion < 2 {
                soundSensitivity = max(soundSensitivity, 0.9)
                sensitivityTuningVersion = 2
            }
            detector.onHit = { confidence in
                game.hit(confidence: confidence, context: context)
            }
            game.onMilestone = { celebration in
                guard milestoneFeedback.isEnabled else { return }
                detector.suppressForPlayback(celebration.playbackSuppression)
                milestoneFeedback.play(celebration)
            }
            applySettings()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab != 1 && detector.isRunning && !game.active {
                detector.stop()
            }
            if !game.active { requestOrientation(.portrait) }
        }
        .onChange(of: silenceSeconds) { _, _ in applySettings() }
        .onChange(of: minimumHits) { _, _ in applySettings() }
        .onChange(of: soundSensitivity) { _, _ in applySettings() }
        .onChange(of: milestoneSoundsEnabled) { _, _ in applySettings() }
        .alert(
            "PaddleCounter",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                detector: detector,
                silenceSeconds: $silenceSeconds,
                minimumHits: $minimumHits,
                soundSensitivity: $soundSensitivity,
                milestoneSoundsEnabled: $milestoneSoundsEnabled
            )
        }
    }

    private func applySettings() {
        game.silenceSeconds = silenceSeconds
        game.minimumHits = minimumHits
        detector.sensitivity = soundSensitivity
        milestoneFeedback.isEnabled = milestoneSoundsEnabled
    }

    private func toggleSession() {
        Task {
            if game.active {
                game.stop(context: context)
                detector.stop()
                requestOrientation(.portrait)
                return
            }

            do {
                detector.calibrationLabel = nil
                try await detector.start()
                game.startSession(context: context)
                requestOrientation(.landscape)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func requestOrientation(_ orientations: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { _ in }
    }
}
