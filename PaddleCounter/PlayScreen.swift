import SwiftUI

struct PlayScreen: View {
    @ObservedObject var game: GameController
    @ObservedObject var detector: AudioDetector
    @State private var celebration: RallyCelebration?

    let detectorIsReady: Bool
    let onPrimaryAction: () -> Void
    let onCalibration: () -> Void
    let onSettings: () -> Void

    var body: some View {
        Group {
            if game.active {
                landscapeRally
            } else {
                portraitHome
            }
        }
        .toolbar(game.active ? .hidden : .visible, for: .tabBar)
        .onChange(of: game.currentHits) { _, hitCount in
            showCelebration(for: hitCount)
        }
    }

    private var portraitHome: some View {
        ZStack {
            PCBackground(accent: PCTheme.lime)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    status
                    counterCard

                    if detectorIsReady {
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

    private var landscapeRally: some View {
        GeometryReader { proxy in
            ZStack {
                PCBackground(accent: PCTheme.lime)

                if let celebration {
                    MilestoneBurst(celebration: celebration)
                        .transition(.scale(scale: 0.55).combined(with: .opacity))
                }

                Text("\(game.currentHits)")
                    .font(.system(
                        size: min(proxy.size.height * 0.78, proxy.size.width * 0.48),
                        weight: .black,
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .foregroundStyle(celebration?.colour ?? .white)
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .contentTransition(.numericText(value: Double(game.currentHits)))
                    .animation(.snappy, value: game.currentHits)
                    .shadow(color: PCTheme.ink.opacity(0.42), radius: 3, y: 3)
                    .scaleEffect(celebration == nil ? 1 : 1.08)
                    .animation(.spring(duration: 0.34, bounce: 0.52), value: celebration)
                    .padding(.horizontal, 120)

                VStack {
                    HStack {
                        PCStatusPill(title: "Listening", colour: PCTheme.lime, pulses: true)
                        Spacer()
                        Button(action: onPrimaryAction) {
                            Label("Finish", systemImage: "stop.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(PCTheme.coral, in: Capsule())
                                .shadow(color: PCTheme.ink.opacity(0.22), radius: 3, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(20)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func showCelebration(for hitCount: Int) {
        guard game.active,
              let newCelebration = RallyCelebration.milestone(for: hitCount) else { return }

        withAnimation(.spring(duration: 0.32, bounce: 0.48)) {
            celebration = newCelebration
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(760))
            guard celebration == newCelebration else { return }
            withAnimation(.easeOut(duration: 0.24)) {
                celebration = nil
            }
        }
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
                title: detectorIsReady ? "Ready to play" : "Setup needed",
                colour: detectorIsReady ? PCTheme.aqua : PCTheme.coral
            )
            Spacer()
        }
    }

    private var counterCard: some View {
        VStack(spacing: 8) {
            Text("HITS")
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

            Text(detectorIsReady ? "Turn sideways, put your phone down and play" : "Calibrate once, then play hands-free")
                .font(.subheadline)
                .foregroundStyle(PCTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 27)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [PCTheme.inkRaised, PCTheme.ink],
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
                Image(systemName: "tennis.racket")
                    .font(.title2.bold())
                    .foregroundStyle(PCTheme.ink)
                    .frame(width: 46, height: 46)
                    .background(PCTheme.lime, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Teach it your paddle")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("A quick guided setup learns the acoustic signature of your paddle.")
                        .font(.subheadline)
                        .foregroundStyle(PCTheme.textSecondary)
                }
            }

            setupProgress(title: "Paddle hits", count: detector.positiveExamples)

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

    private func primaryButton(title: String, icon: String) -> some View {
        Button(action: onPrimaryAction) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.subheadline.bold())
            }
            .font(.headline)
            .foregroundStyle(PCTheme.ink)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(PCTheme.lime, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

private struct MilestoneBurst: View {
    let celebration: RallyCelebration

    private let angles = Array(stride(from: 0.0, to: 360.0, by: 30.0))

    var body: some View {
        ZStack {
            Circle()
                .stroke(celebration.colour.opacity(0.68), lineWidth: 8)
                .frame(width: 240, height: 240)

            Circle()
                .stroke(Color.white.opacity(0.58), lineWidth: 3)
                .frame(width: 310, height: 310)

            ForEach(Array(angles.enumerated()), id: \.offset) { index, angle in
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "circle.fill")
                    .font(.system(size: index.isMultiple(of: 2) ? 25 : 10, weight: .black))
                    .foregroundStyle(index.isMultiple(of: 3) ? PCTheme.coral : celebration.colour)
                    .offset(y: -188)
                    .rotationEffect(.degrees(angle))
            }
        }
        .shadow(color: celebration.colour.opacity(0.38), radius: 16)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private extension RallyCelebration {
    var colour: Color {
        switch self {
        case .ten: PCTheme.lime
        case .twentyFive: .white
        case .fifty: PCTheme.aqua
        case .century: PCTheme.coral
        }
    }
}
