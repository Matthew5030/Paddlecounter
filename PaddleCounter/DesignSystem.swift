import SwiftUI

enum PCTheme {
    static let ink = Color(red: 0.035, green: 0.055, blue: 0.10)
    static let inkRaised = Color(red: 0.065, green: 0.09, blue: 0.15)
    static let lime = Color(red: 0.72, green: 0.96, blue: 0.32)
    static let aqua = Color(red: 0.24, green: 0.84, blue: 0.79)
    static let coral = Color(red: 1.0, green: 0.45, blue: 0.36)
    static let textSecondary = Color.white.opacity(0.62)
    static let border = Color.white.opacity(0.10)
    static let panel = Color.white.opacity(0.075)
}

struct PCBackground: View {
    var accent: Color = PCTheme.aqua

    var body: some View {
        ZStack {
            PCTheme.ink
            RadialGradient(
                colors: [accent.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct PCLogo: View {
    var compact = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 13)
                    .fill(PCTheme.lime)
                Image(systemName: "waveform")
                    .font(.system(size: compact ? 15 : 19, weight: .black))
                    .foregroundStyle(PCTheme.ink)
            }
            .frame(width: compact ? 34 : 42, height: compact ? 34 : 42)

            Text("PaddleCounter")
                .font(compact ? .headline : .title3.bold())
                .foregroundStyle(.white)
        }
    }
}

struct PCStatusPill: View {
    let title: String
    let colour: Color
    var pulses = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(colour)
                .frame(width: 8, height: 8)
                .shadow(color: pulses ? colour : .clear, radius: 7)
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.1)
        }
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(PCTheme.border))
    }
}

struct PCMetric: View {
    let value: String
    let label: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(PCTheme.textSecondary)
        }
    }
}

struct PCCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(PCTheme.panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(PCTheme.border, lineWidth: 1)
            )
    }
}

extension View {
    func pcCard() -> some View { modifier(PCCardModifier()) }
}
