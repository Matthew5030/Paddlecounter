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
    static let pageInset: CGFloat = 20
    static let contentWidth: CGFloat = 620
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
                    .frame(width: min(max(proxy.size.width * 0.34, 118), 180))
                    .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 2))
                    .position(x: proxy.size.width - 28, y: 74)

                Image(systemName: "cloud.fill")
                    .font(.system(size: min(max(proxy.size.width * 0.17, 62), 96)))
                    .foregroundStyle(.white.opacity(0.66))
                    .position(x: 38, y: 136)

                BeachWave(amplitude: 26)
                    .fill(PCTheme.ocean.opacity(0.92))
                    .frame(height: min(max(proxy.size.height * 0.30, 150), 260))
                    .frame(maxHeight: .infinity, alignment: .bottom)

                BeachWave(amplitude: 18)
                    .fill(PCTheme.sand)
                    .frame(height: min(max(proxy.size.height * 0.12, 72), 120))
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

struct PCPageHeader: View {
    let eyebrow: String
    let title: String
    let accent: Color
    var systemImage: String?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow.uppercased())
                    .font(.caption2.bold())
                    .tracking(1.5)
                    .foregroundStyle(accent)
                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 12)
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(accent)
                    .frame(width: 46, height: 46)
                    .background(PCTheme.ink.opacity(0.52), in: Circle())
                    .overlay(Circle().stroke(PCTheme.border))
            }
        }
    }
}

struct PCPrimaryButton: View {
    let title: String
    let systemImage: String
    var tint: Color = PCTheme.lime
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.subheadline.bold())
            }
            .font(.headline)
            .foregroundStyle(PCTheme.ink)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: PCTheme.ink.opacity(0.18), radius: 8, y: 5)
        }
        .buttonStyle(.plain)
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

struct SensitivityControl: View {
    @Binding var value: Double
    var tint: Color = PCTheme.aqua

    private var tuning: SensitivityTuning { SensitivityTuning(value) }
    private var percentage: Binding<Double> {
        Binding(get: { tuning.percent }, set: { value = $0 / 100 * 3 - 1 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sound sensitivity", systemImage: "ear")
                .font(.subheadline.weight(.semibold))
            HStack {
                Text(tuning.label)
                Spacer()
                Text("\(Int(tuning.percent.rounded())) / 100")
                    .monospacedDigit()
            }
            .font(.subheadline.bold())
            .foregroundStyle(tint)
            Slider(value: percentage, in: 0...100, step: 1)
                .tint(tint)
                .accessibilityLabel("Sound sensitivity")
                .accessibilityValue("\(Int(tuning.percent.rounded())) out of 100, \(tuning.label)")
            HStack {
                Text("Reject more noise")
                Spacer()
                Text("Hear softer hits")
            }
            .font(.caption2)
            .foregroundStyle(PCTheme.textSecondary)
            if value > 1 {
                Text("Boost picks up softer hits, but may also count more background sounds.")
                    .font(.caption)
                    .foregroundStyle(PCTheme.textSecondary)
            }
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
            .shadow(color: PCTheme.ink.opacity(0.14), radius: 14, y: 8)
    }
}

extension View {
    func pcCard() -> some View { modifier(PCCardModifier()) }
}
