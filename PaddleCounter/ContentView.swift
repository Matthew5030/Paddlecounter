import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var detector = AudioDetector()
    @StateObject private var game = GameController()
    @Query(sort: \SessionRecord.startedAt, order: .reverse) private var sessions: [SessionRecord]

    @AppStorage("rallySilenceSeconds") private var silenceSeconds = 3.0
    @AppStorage("minimumRallyHits") private var minimumHits = 1
    @AppStorage("detectionThreshold") private var detectionThreshold = 0.72

    @State private var selectedTab = 0
    @State private var errorMessage: String?
    @State private var showingSettings = false
    @State private var showingDiagnostics = false

    private var detectorIsReady: Bool {
        detector.positiveExamples >= 8 && detector.negativeExamples >= 8
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayScreen(
                game: game,
                detector: detector,
                detectorIsReady: detectorIsReady,
                silenceSeconds: silenceSeconds,
                onPrimaryAction: detectorIsReady ? toggleSession : { selectedTab = 1 },
                onManualHit: { game.hit(confidence: 1, context: context) },
                onCalibration: { selectedTab = 1 },
                onSettings: { showingSettings = true },
                onDiagnostics: { showingDiagnostics = true }
            )
            .tag(0)
            .tabItem { Label("Play", systemImage: "waveform") }

            CalibrationScreen(
                detector: detector,
                sessionIsActive: game.active,
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
            detector.onHit = { confidence in
                game.hit(confidence: confidence, context: context)
            }
            applySettings()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab != 1 && detector.isRunning && !game.active {
                detector.stop()
            }
        }
        .onChange(of: silenceSeconds) { _, _ in applySettings() }
        .onChange(of: minimumHits) { _, _ in applySettings() }
        .onChange(of: detectionThreshold) { _, _ in applySettings() }
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
                silenceSeconds: $silenceSeconds,
                minimumHits: $minimumHits,
                detectionThreshold: $detectionThreshold
            )
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsScreen(detector: detector)
        }
    }

    private func applySettings() {
        game.silenceSeconds = silenceSeconds
        game.minimumHits = minimumHits
        detector.threshold = Float(detectionThreshold)
    }

    private func toggleSession() {
        Task {
            if game.active {
                game.stop(context: context)
                detector.stop()
                return
            }

            do {
                detector.calibrationLabel = nil
                try await detector.start()
                game.startSession(context: context)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
