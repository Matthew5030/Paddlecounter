import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var detector: AudioDetector
    @Binding var silenceSeconds: Double
    @Binding var minimumHits: Int
    @Binding var soundSensitivity: Double
    @Binding var milestoneSoundsEnabled: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                PCTheme.ink.ignoresSafeArea()
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Rally pause", systemImage: "timer")
                                Spacer()
                                Text("\(silenceSeconds, specifier: "%.1f")s")
                                    .foregroundStyle(PCTheme.lime)
                                    .monospacedDigit()
                            }
                            Slider(value: $silenceSeconds, in: 1.5...8, step: 0.5)
                                .tint(PCTheme.lime)
                        }

                        Stepper("Minimum rally hits: \(minimumHits)", value: $minimumHits, in: 1...10)
                    } header: {
                        Text("Rallies")
                    } footer: {
                        Text("A quiet pause automatically saves the rally and resets the counter.")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Sound sensitivity", systemImage: "ear")
                                Spacer()
                                Text(sensitivityLabel)
                                    .foregroundStyle(PCTheme.aqua)
                            }
                            Slider(value: $soundSensitivity, in: 0...1, step: 0.05)
                                .tint(PCTheme.aqua)
                            HStack {
                                Text("Reject more")
                                Spacer()
                                Text("Hear quieter hits")
                            }
                            .font(.caption2)
                            .foregroundStyle(PCTheme.textSecondary)
                        }
                    } header: {
                        Text("Recognition")
                    } footer: {
                        Text("Smart is recommended. PaddleCounter listens for quieter impacts while its learned profile filters other sounds.")
                    }

                    Section {
                        Toggle(isOn: $milestoneSoundsEnabled) {
                            Label("Milestone sounds & haptics", systemImage: "sparkles")
                        }
                        .tint(PCTheme.lime)
                    } header: {
                        Text("Game feel")
                    } footer: {
                        Text("The visual burst stays on. Sounds and haptics play at 10, 25, 50 and 100 hits, then every 50 hits.")
                    }

                    Section {
                        Label("Audio never leaves this iPhone", systemImage: "lock.shield.fill")
                            .foregroundStyle(PCTheme.textSecondary)
                    } header: {
                        Text("Privacy")
                    }

                    Section {
                        NavigationLink {
                            DiagnosticsScreen(detector: detector)
                        } label: {
                            Label("Detector details", systemImage: "waveform.badge.magnifyingglass")
                        }
                    } header: {
                        Text("Testing")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(PCTheme.lime)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var sensitivityLabel: String {
        switch soundSensitivity {
        case ..<0.25: "Quiet room"
        case 0.25..<0.65: "Smart"
        case 0.65..<0.85: "Sensitive"
        default: "Very sensitive"
        }
    }
}

struct DiagnosticsScreen: View {
    @ObservedObject var detector: AudioDetector

    var body: some View {
        ZStack {
            PCBackground(accent: PCTheme.aqua)

            if detector.recentEvents.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(PCTheme.aqua)
                    Text("No candidates yet")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("Sharp sounds will appear here while the detector is listening.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PCTheme.textSecondary)
                }
                .padding(30)
            } else {
                ScrollView {
                    LazyVStack(spacing: 11) {
                        ForEach(detector.recentEvents) { event in
                            diagnosticRow(event)
                        }
                    }
                    .frame(maxWidth: PCTheme.contentWidth)
                    .padding(PCTheme.pageInset)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Detector details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private func diagnosticRow(_ event: DetectionEvent) -> some View {
        HStack(spacing: 13) {
            Image(systemName: event.accepted ? "checkmark" : "xmark")
                .font(.subheadline.bold())
                .foregroundStyle(event.accepted ? PCTheme.ink : .white)
                .frame(width: 36, height: 36)
                .background(event.accepted ? PCTheme.lime : PCTheme.coral, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(event.reason)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(distanceText(event))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PCTheme.textSecondary)
            }
            Spacer()
            Text(event.confidence, format: .percent.precision(.fractionLength(0)))
                .font(.headline.monospacedDigit())
                .foregroundStyle(event.accepted ? PCTheme.lime : .white)
        }
        .padding(15)
        .pcCard()
    }

    private func distanceText(_ event: DetectionEvent) -> String {
        let hit = event.positiveDistance.formatted(.number.precision(.fractionLength(2)))
        guard let ignored = event.negativeDistance else { return "Hit distance \(hit)" }
        return "Hit \(hit) · ignored \(ignored.formatted(.number.precision(.fractionLength(2))))"
    }
}
