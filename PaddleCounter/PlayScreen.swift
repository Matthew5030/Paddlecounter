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
                VStack(spacing: 18) {
                    header

                    if detectorIsReady {
                        readyCard
                    } else {
                        setupCard
                    }

                    Label("Audio is processed privately on this iPhone", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.top, 2)
                }
                .frame(maxWidth: PCTheme.contentWidth)
                .padding(.horizontal, PCTheme.pageInset)
                .padding(.top, 10)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var landscapeRally: some View {
        GeometryReader { proxy in
            ZStack {
                PCBackground(accent: PCTheme.lime)

                Color.black.opacity(0.05)

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
                    .padding(.horizontal, max(84, proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing + 40))
                    .accessibilityLabel("\(game.currentHits) hits")

                VStack {
                    HStack {
                        PCStatusPill(title: "Listening", colour: PCTheme.lime, pulses: true)
                        Spacer()
                        Button(action: onPrimaryAction) {
                            Label("End session", systemImage: "stop.fill")
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
                .padding(.top, proxy.safeAreaInsets.top + 12)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 12)
                .padding(.leading, proxy.safeAreaInsets.leading + 18)
                .padding(.trailing, proxy.safeAreaInsets.trailing + 18)
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

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                PCStatusPill(title: "Ready to play", colour: PCTheme.lime)
                Spacer()
                Image(systemName: "tennis.racket")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(PCTheme.lime)
                    .rotationEffect(.degrees(-12))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Turn. Set. Rally.")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                Text("Place your phone near the court, turn it sideways and let PaddleCounter handle the score.")
                    .font(.subheadline)
                    .foregroundStyle(PCTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                featureChip("Automatic rallies", icon: "timer")
                featureChip("Hands-free", icon: "waveform")
            }

            PCPrimaryButton(title: "Start session", systemImage: "play.fill", action: onPrimaryAction)

            Button(action: onCalibration) {
                Label("Retune paddle sound", systemImage: "scope")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .pcCard()
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

            PCPrimaryButton(title: "Set up detector", systemImage: "scope", action: onPrimaryAction)
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

    private func featureChip(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.86))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
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
