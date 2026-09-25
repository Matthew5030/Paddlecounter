import Charts
import SwiftUI

struct SessionPaceCard: View {
    let rallies: [RallyRecord]

    private var pacedRallies: [(index: Int, rate: Double)] {
        rallies.enumerated().compactMap { index, rally in
            rally.averageHitRate.map { (index + 1, $0) }
        }
    }

    var body: some View {
        if !pacedRallies.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Label("The pace of your session", systemImage: "speedometer")
                    .font(.headline)
                Text("Average hits per minute in each rally")
                    .font(.caption)
                    .foregroundStyle(PCTheme.textSecondary)
                Chart(pacedRallies, id: \.index) { rally in
                    BarMark(x: .value("Rally", String(rally.index)), y: .value("Hits/min", rally.rate))
                        .foregroundStyle(PCTheme.aqua.gradient)
                        .cornerRadius(4)
                }
                .chartXAxisLabel("Rally")
                .chartYAxisLabel("Hits/min")
                .frame(height: 175)
                Text("Breaks between rallies are excluded. Tap a rally below to explore its rhythm.")
                    .font(.caption)
                    .foregroundStyle(PCTheme.textSecondary)
            }
            .foregroundStyle(.white)
            .padding(20)
            .pcCard()
        }
    }
}

struct RhythmScreen: View {
    let rally: RallyRecord
    let number: Int
    @State private var selectedTime: Double?

    var body: some View {
        ZStack {
            PCBackground(accent: PCTheme.aqua)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    summary
                    if let rhythm = rally.rhythm {
                        rateChart(rhythm)
                        gapChart(rhythm)
                        insights(rhythm)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("More detail next time", systemImage: "waveform.path")
                                .font(.headline)
                            Text(rally.hits < 2
                                 ? "A second hit is needed to measure pace. Longer rallies reveal rhythm and changes in speed."
                                 : "This rally has no individual hit timings. New rallies will include pace and rhythm graphs automatically.")
                                .font(.subheadline)
                                .foregroundStyle(PCTheme.textSecondary)
                        }
                        .padding(20)
                        .pcCard()
                    }
                    Text("Based on recognised hits. Missed or extra detections can change the graphs. Pace describes the rally, not ball speed or either player's performance.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 4)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: PCTheme.contentWidth)
                .padding(PCTheme.pageInset)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Rally \(number) · Rhythm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(rally.rhythm?.rhythmLabel ?? "Your rally")
                .font(.system(.title2, design: .rounded, weight: .bold))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 18) {
                PCMetric(value: "\(rally.hits)", label: "Hits")
                PCMetric(value: rally.averageHitRate.map { format($0, digits: 0) } ?? "—", label: "Average hits/min")
                PCMetric(value: format(rally.rhythm?.duration ?? max(0, rally.endedAt.timeIntervalSince(rally.startedAt))) + "s", label: "Active rally")
                PCMetric(value: rally.rhythm.map { format($0.averageGap, digits: 2) + "s" } ?? "—", label: "Average gap")
            }
        }
        .padding(20)
        .pcCard()
    }

    private func rateChart(_ rhythm: RallyRhythm) -> some View {
        let selected = selectedTime.flatMap { time in
            rhythm.samples.min { abs($0.elapsed - time) < abs($1.elapsed - time) }
        }
        return VStack(alignment: .leading, spacing: 12) {
            Label("Find your flow", systemImage: "waveform.path")
                .font(.headline)
            Text(selected.map { "\(format($0.elapsed))s · \(format($0.rate, digits: 0)) hits/min" } ?? "Touch the graph to explore your pace")
                .font(.caption.monospacedDigit())
                .foregroundStyle(PCTheme.textSecondary)
            Chart {
                ForEach(rhythm.samples) { sample in
                    LineMark(x: .value("Seconds", sample.elapsed), y: .value("Hits/min", sample.rate))
                        .foregroundStyle(PCTheme.aqua)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    if rhythm.samples.count == 1 {
                        PointMark(x: .value("Seconds", sample.elapsed), y: .value("Hits/min", sample.rate))
                            .foregroundStyle(PCTheme.aqua)
                    }
                }
                RuleMark(y: .value("Average", rhythm.averageRate))
                    .foregroundStyle(PCTheme.lime.opacity(0.65))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                if let selected {
                    RuleMark(x: .value("Selected time", selected.elapsed))
                        .foregroundStyle(.white.opacity(0.4))
                    PointMark(x: .value("Seconds", selected.elapsed), y: .value("Hits/min", selected.rate))
                        .foregroundStyle(PCTheme.lime)
                }
            }
            .chartXScale(domain: 0...max(rhythm.duration, 1))
            .chartXSelection(value: $selectedTime)
            .chartXAxisLabel("Seconds into rally")
            .chartYAxisLabel("Hits/min")
            .frame(height: 200)
            Text("Pace is smoothed over up to 5 gaps. The dashed line is your rally average.")
                .font(.caption)
                .foregroundStyle(PCTheme.textSecondary)
        }
        .padding(20)
        .pcCard()
    }

    private func gapChart(_ rhythm: RallyRhythm) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Every beat", systemImage: "metronome")
                .font(.headline)
            Text("Equal-height bars mean evenly timed hits. Taller bars are longer waits.")
                .font(.caption)
                .foregroundStyle(PCTheme.textSecondary)
            Chart(rhythm.samples) { sample in
                BarMark(x: .value("Hit", sample.id), y: .value("Gap (s)", sample.gap))
                    .foregroundStyle(sample.id.isMultiple(of: 2) ? PCTheme.aqua : PCTheme.lime)
                    .cornerRadius(2)
            }
            .chartXAxisLabel("Hit number")
            .chartYAxisLabel("Gap in seconds")
            .frame(height: 175)
            Text("Colours alternate between consecutive gaps; they don't identify players.")
                .font(.caption)
                .foregroundStyle(PCTheme.textSecondary)
        }
        .padding(20)
        .pcCard()
    }

    private func insights(_ rhythm: RallyRhythm) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Rally personality", systemImage: "sparkles")
                .font(.headline)
            if let variation = rhythm.variation {
                insight(rhythm.rhythmLabel, detail: "Gap variation: \(format(variation * 100, digits: 0))%. Lower means more evenly spaced hits.")
            } else {
                insight("Keep it going", detail: "Five hits are needed for a rhythm summary.")
            }
            if let trend = rhythm.trendLabel, let change = rhythm.paceChange {
                insight(trend, detail: abs(change) < 0.005
                        ? "Opening and closing pace were the same. Compares the first and last thirds."
                        : "Closing pace was \(format(abs(change) * 100, digits: 0))% \(change >= 0 ? "faster" : "slower") than the opening. Compares the first and last thirds.")
            } else {
                insight("A longer rally tells more", detail: "Ten hits reveal whether you're speeding up or easing off.")
            }
            if let contrast = rhythm.alternatingGapContrast {
                insight("Long–short, long–short", detail: "Alternating gaps differed by \(format(contrast * 100, digits: 0))% of their average. Your back-and-forth timing was uneven.")
            }
            if let fastest = rhythm.fastestFiveRate {
                insight("Your quickest stretch", detail: "\(format(fastest, digits: 0)) hits/min across your fastest five consecutive gaps.")
            }
            insight("Room to breathe", detail: "Shortest gap \(format(rhythm.shortestGap, digits: 2))s · longest \(format(rhythm.longestGap, digits: 2))s.")
        }
        .padding(20)
        .pcCard()
    }

    private func insight(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.bold()).foregroundStyle(PCTheme.lime)
            Text(detail).font(.subheadline).foregroundStyle(PCTheme.textSecondary)
        }
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }
}
