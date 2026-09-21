import SwiftUI

enum PCTheme {
    static let ink = Color(red: 0.035, green: 0.10, blue: 0.20)
    static let inkRaised = Color(red: 0.055, green: 0.17, blue: 0.29)
    static let lime = Color(red: 1.0, green: 0.83, blue: 0.18)
    static let aqua = Color(red: 0.10, green: 0.76, blue: 0.82)
    static let coral = Color(red: 1.0, green: 0.38, blue: 0.34)
    static let sky = Color(red: 0.20, green: 0.72, blue: 0.96)
    static let ocean = Color(red: 0.02, green: 0.52, blue: 0.78)
    static let sand = Color(red: 1.0, green: 0.78, blue: 0.40)
    static let textSecondary = Color.white.opacity(0.62)
    static let border = Color.white.opacity(0.16)
    static let panel = inkRaised.opacity(0.94)
}

struct PCBackground: View {
    var accent: Color = PCTheme.aqua

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [PCTheme.sky, Color(red: 0.36, green: 0.86, blue: 0.94)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(PCTheme.lime)
                    .frame(width: min(proxy.size.width, proxy.size.height) * 0.28)
                    .blur(radius: 1)
                    .offset(x: proxy.size.width * 0.36, y: -proxy.size.height * 0.38)

                Image(systemName: "cloud.fill")
                    .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.18))
                    .foregroundStyle(.white.opacity(0.78))
                    .offset(x: -proxy.size.width * 0.34, y: -proxy.size.height * 0.30)

                BeachWave(amplitude: 26)
                    .fill(PCTheme.ocean.opacity(0.92))
                    .frame(height: proxy.size.height * 0.34)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                BeachWave(amplitude: 18)
                    .fill(PCTheme.sand)
                    .frame(height: proxy.size.height * 0.17)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                RadialGradient(
                    colors: [accent.opacity(0.16), .clear],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 430
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct BeachWave: Shape {
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: amplitude))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.5, y: amplitude * 0.55),
            control1: CGPoint(x: rect.width * 0.16, y: -amplitude * 0.15),
            control2: CGPoint(x: rect.width * 0.34, y: amplitude * 1.35)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: amplitude),
            control1: CGPoint(x: rect.width * 0.66, y: -amplitude * 0.10),
            control2: CGPoint(x: rect.width * 0.84, y: amplitude * 1.25)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct PCLogo: View {
    var compact = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 13)
                    .fill(PCTheme.lime)
                Image(systemName: "tennis.racket")
                    .font(.system(size: compact ? 15 : 19, weight: .black))
                    .foregroundStyle(PCTheme.ink)
            }
            .frame(width: compact ? 34 : 42, height: compact ? 34 : 42)

            Text("PaddleCounter")
                .font(compact ? .headline : .title3.bold())
                .foregroundStyle(.white)
                .shadow(color: PCTheme.ink.opacity(0.28), radius: 2, y: 1)
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
        .background(PCTheme.ink.opacity(0.78), in: Capsule())
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
