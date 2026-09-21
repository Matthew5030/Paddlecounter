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

    var body: some View {
        TabView(selection: $selectedTab) {
            playView
                .tag(0)
                .tabItem { Label("Play", systemImage: "waveform") }
            calibrationView
                .tag(1)
                .tabItem { Label("Calibrate", systemImage: "tuningfork") }
            historyView
                .tag(2)
                .tabItem { Label("History", systemImage: "clock") }
        }
        .task {
            detector.onHit = { confidence in
                game.hit(confidence: confidence, context: context)
            }
            applySettings()
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
    }

    private var playView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text(game.active ? "CURRENT RALLY" : "READY")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if !game.active && !CalibrationStore.shared.profile.isReady {
                        Label("Calibration needs paddle hits and ignored sounds", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }

                    Text("\(game.currentHits)")
                        .font(.system(size: 108, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    if game.active {
                        Text("A rally saves after \(silenceSeconds, specifier: "%.1f") seconds without a recognised hit.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(game.active ? "Finish Session" : "Start Session") {
                        toggleSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if game.active {
                        Button("Add hit manually") {
                            game.hit(confidence: 1, context: context)
                        }
                    }

                    if game.active || !detector.recentEvents.isEmpty {
                        DiagnosticsView(detector: detector)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .navigationTitle("PaddleCounter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showingSettings = true
                    }
                }
            }
        }
    }

    private var calibrationView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Teach the detector both sides")
                        .font(.title2.bold())
                    Text("Keep the phone where it will sit during play. First record normal paddle hits, then record sounds it must reject.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    CalibrationCard(
                        title: "1. Paddle hits",
                        detail: "Make 15–30 typical hits, including softer and harder ones.",
                        count: detector.positiveExamples,
                        target: 15,
                        colour: .green,
                        isRecording: detector.isRunning && detector.calibrationLabel == .paddleHit,
                        buttonTitle: "Learn paddle hits"
                    ) {
                        toggleCalibration(.paddleHit)
                    }

                    CalibrationCard(
                        title: "2. Sounds to ignore",
                        detail: "Talk, clap, walk, bounce the ball and make other likely indoor noises.",
                        count: detector.negativeExamples,
                        target: 20,
                        colour: .orange,
                        isRecording: detector.isRunning && detector.calibrationLabel == .ignoredSound,
                        buttonTitle: "Learn ignored sounds"
                    ) {
                        toggleCalibration(.ignoredSound)
                    }

                    if CalibrationStore.shared.profile.isReady {
                        Label("Ready to test", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                    }

                    Button("Reset all calibration", role: .destructive) {
                        detector.resetCalibration()
                    }

                    Text("Only feature vectors are saved. Continuous microphone audio and conversations are never retained or uploaded.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Calibration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var historyView: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    Section(session.startedAt.formatted(date: .abbreviated, time: .shortened)) {
                        HStack {
                            Statistic(title: "Rallies", value: "\(session.rallies.count)")
                            Spacer()
                            Statistic(title: "Hits", value: "\(session.totalHits)")
                            Spacer()
                            Statistic(title: "Best", value: "\(session.best)")
                            Spacer()
                            Statistic(title: "Average", value: session.averageRally.formatted(.number.precision(.fractionLength(1))))
                        }

                        ForEach(session.rallies.sorted { $0.startedAt < $1.startedAt }) { rally in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(rally.startedAt.formatted(date: .omitted, time: .standard))
                                    Spacer()
                                    Text("\(rally.hits) hits").bold()
                                }
                                if rally.averageConfidence > 0 {
                                    Text("Average confidence \(rally.averageConfidence, format: .percent.precision(.fractionLength(0)))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "figure.pickleball",
                        description: Text("Completed rallies appear here automatically.")
                    )
                }
            }
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

            guard CalibrationStore.shared.profile.isReady else {
                selectedTab = 1
                errorMessage = "Record at least 8 paddle hits and 8 sounds to ignore before starting a session."
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

    private func toggleCalibration(_ label: CalibrationLabel) {
        Task {
            if detector.isRunning {
                detector.stop()
                return
            }
            do {
                try await detector.beginCalibration(label)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct CalibrationCard: View {
    let title: String
    let detail: String
    let count: Int
    let target: Int
    let colour: Color
    let isRecording: Bool
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(count)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(colour)
            }
            ProgressView(value: Double(min(count, target)), total: Double(target))
                .tint(colour)
            Button(isRecording ? "Stop recording" : buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(isRecording ? .red : colour)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct DiagnosticsView: View {
    @ObservedObject var detector: AudioDetector

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Detector diagnostics").font(.headline)
                Spacer()
                Text("Threshold \(detector.threshold, format: .percent.precision(.fractionLength(0)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if detector.recentEvents.isEmpty {
                Text("Waiting for a sharp sound…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(detector.recentEvents.prefix(6)) { event in
                    HStack(alignment: .top) {
                        Image(systemName: event.accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(event.accepted ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.reason).font(.subheadline)
                            Text(distanceSummary(event))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.confidence, format: .percent.precision(.fractionLength(0)))
                            .font(.subheadline.monospacedDigit().bold())
                    }
                }
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
    }

    private func distanceSummary(_ event: DetectionEvent) -> String {
        let hitDistance = event.positiveDistance.formatted(.number.precision(.fractionLength(2)))
        guard let negativeDistance = event.negativeDistance else {
            return "hit distance \(hitDistance)"
        }
        return "hit \(hitDistance) · ignored \(negativeDistance.formatted(.number.precision(.fractionLength(2))))"
    }
}

private struct Statistic: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline.monospacedDigit())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var silenceSeconds: Double
    @Binding var minimumHits: Int
    @Binding var detectionThreshold: Double

    var body: some View {
        NavigationStack {
            Form {
                Section("Rallies") {
                    VStack(alignment: .leading) {
                        Text("End after \(silenceSeconds, specifier: "%.1f") seconds")
                        Slider(value: $silenceSeconds, in: 1.5...8, step: 0.5)
                    }
                    Stepper("Minimum hits: \(minimumHits)", value: $minimumHits, in: 1...10)
                }

                Section("Detection") {
                    VStack(alignment: .leading) {
                        Text("Confidence threshold \(detectionThreshold, format: .percent.precision(.fractionLength(0)))")
                        Slider(value: $detectionThreshold, in: 0.55...0.95, step: 0.01)
                    }
                    Text("Raise this to reject more false hits; lower it if genuine hits are being missed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
