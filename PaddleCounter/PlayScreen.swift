import SwiftUI

struct PlayScreen: View {
    @ObservedObject var game: GameController
    @ObservedObject var detector: AudioDetector

    let detectorIsReady: Bool
    let silenceSeconds: Double
    let onPrimaryAction: () -> Void
    let onManualHit: () -> Void
    let onCalibration: () -> Void
    let onSettings: () -> Void
    let onDiagnostics: () -> Void

    var body: some View {
        ZStack {
            PCBackground(accent: game.active ? PCTheme.lime : PCTheme.aqua)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    status
                    counterCard

                    if game.active {
                        liveSessionControls
                    } else if detectorIsReady {
                        readyControls
                    } else {
                        setupCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 110)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            PCLogo()
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(PCTheme.border))
            }
            .accessibilityLabel("Settings")
        }
    }

    private var status: some View {
        HStack {
            PCStatusPill(
                title: game.active ? "Listening live" : detectorIsReady ? "Ready to play" : "Setup needed",
                colour: game.active ? PCTheme.lime : detectorIsReady ? PCTheme.aqua : PCTheme.coral,
                pulses: game.active
            )
            Spacer()
            if game.active, let event = detector.recentEvents.first {
                Button(action: onDiagnostics) {
                    HStack(spacing: 5) {
                        Image(systemName: event.accepted ? "checkmark.circle.fill" : "waveform.badge.minus")
                        Text(event.confidence, format: .percent.precision(.fractionLength(0)))
                            .monospacedDigit()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(event.accepted ? PCTheme.lime : PCTheme.textSecondary)
                }
            }
        }
    }

    private var counterCard: some View {
        VStack(spacing: 8) {
            Text(game.active ? "CURRENT RALLY" : "HITS")
                .font(.caption.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(PCTheme.textSecondary)

            Text("\(game.currentHits)")
                .font(.system(size: 122, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(game.currentHits)))
                .animation(.snappy, value: game.currentHits)

            if game.active {
                Text("A \(silenceSeconds, specifier: "%.1f") second pause saves this rally")
                    .font(.subheadline)
                    .foregroundStyle(PCTheme.textSecondary)
            } else {
                Text(detectorIsReady ? "Put your phone down and let it count" : "Calibrate once, then play hands-free")
                    .font(.subheadline)
                    .foregroundStyle(PCTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 27)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.10), Color.white.opacity(0.045)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(PCTheme.border)
        )
    }

    private var liveSessionControls: some View {
        VStack(spacing: 16) {
            HStack {
                PCMetric(value: "\(game.sessionTotalHits)", label: "Session hits")
                Spacer()
                PCMetric(value: "\(game.completedRallies)", label: "Rallies", alignment: .center)
                Spacer()
                PCMetric(value: "\(game.bestRally)", label: "Best", alignment: .trailing)
            }
            .padding(20)
            .pcCard()

            Button(action: onManualHit) {
                Label("Add missed hit", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)

            primaryButton(title: "Finish session", icon: "stop.fill", destructive: true)
        }
    }

    private var readyControls: some View {
        VStack(spacing: 13) {
            primaryButton(title: "Start session", icon: "play.fill")

            Button(action: onCalibration) {
                Text("Retune the detector")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PCTheme.textSecondary)
            }
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "scope")
                    .font(.title2.bold())
                    .foregroundStyle(PCTheme.ink)
                    .frame(width: 46, height: 46)
                    .background(PCTheme.lime, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Teach it your paddle")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("A quick guided setup learns your hit and the indoor sounds it should ignore.")
                        .font(.subheadline)
                        .foregroundStyle(PCTheme.textSecondary)
                }
            }

            HStack(spacing: 8) {
                setupProgress(title: "Hits", count: detector.positiveExamples)
                setupProgress(title: "Noises", count: detector.negativeExamples)
            }

            primaryButton(title: "Set up detector", icon: "scope")
        }
        .padding(20)
        .pcCard()
    }

    private func setupProgress(title: String, count: Int) -> some View {
        HStack(spacing: 7) {
            Image(systemName: count >= 8 ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(count >= 8 ? PCTheme.lime : PCTheme.textSecondary)
            Text("\(title) \(min(count, 8))/8")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func primaryButton(title: String, icon: String, destructive: Bool = false) -> some View {
        Button(action: onPrimaryAction) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: destructive ? "chevron.right" : "arrow.right")
                    .font(.subheadline.bold())
            }
            .font(.headline)
            .foregroundStyle(destructive ? .white : PCTheme.ink)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(destructive ? PCTheme.coral : PCTheme.lime, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}
