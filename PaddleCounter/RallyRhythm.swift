import Foundation

/// Describes recognised hit timing, not ball speed or an individual player's skill.
struct RallyRhythm {
    struct Sample: Identifiable {
        let id: Int
        let elapsed: Double
        let gap: Double
        let rate: Double
    }

    let gaps: [Double]
    let samples: [Sample]

    init?(hitOffsets: [Double]) {
        guard hitOffsets.count >= 2,
              hitOffsets.allSatisfy({ $0.isFinite && $0 >= 0 }) else { return nil }
        let gaps = zip(hitOffsets.dropFirst(), hitOffsets).map(-)
        guard gaps.allSatisfy({ $0 > 0 }) else { return nil }
        self.gaps = gaps
        self.samples = gaps.indices.map { index in
            // Smooth up to five intervals; never bridge a break between rallies.
            let window = gaps[max(0, index - 4)...index]
            return Sample(
                id: index + 2,
                elapsed: hitOffsets[index + 1] - hitOffsets[0],
                gap: gaps[index],
                rate: Double(window.count) * 60 / window.reduce(0, +)
            )
        }
    }

    var duration: Double { gaps.reduce(0, +) }
    var averageGap: Double { duration / Double(gaps.count) }
    var averageRate: Double { 60 / averageGap }
    var shortestGap: Double { gaps.min() ?? 0 }
    var longestGap: Double { gaps.max() ?? 0 }

    /// Coefficient of variation: 0 is perfectly regular. No bounded "skill score".
    var variation: Double? {
        guard gaps.count >= 4 else { return nil }
        let mean = averageGap
        let variance = gaps.reduce(0) { $0 + pow($1 - mean, 2) } / Double(gaps.count)
        return sqrt(variance) / mean
    }

    var rhythmLabel: String {
        guard let variation else { return "Finding your rhythm" }
        switch variation {
        case ..<0.10: return "Clockwork"
        case ..<0.25: return "Mostly steady"
        default: return "Changing rhythm"
        }
    }

    /// First and last thirds, with at least three intervals in each comparison.
    var paceChange: Double? {
        guard gaps.count >= 9 else { return nil }
        let count = gaps.count / 3
        let opening = gaps.prefix(count).reduce(0, +) / Double(count)
        let closing = gaps.suffix(count).reduce(0, +) / Double(count)
        return opening / closing - 1
    }

    var trendLabel: String? {
        guard let paceChange else { return nil }
        if paceChange > 0.15 { return "Picking up speed" }
        if paceChange < -0.15 { return "Easing off" }
        return "Holding the pace"
    }

    var fastestFiveRate: Double? {
        guard gaps.count >= 5 else { return nil }
        return (4..<gaps.count).map { end in
            300 / gaps[(end - 4)...end].reduce(0, +)
        }.max()
    }

    /// Alternating long/short intervals can suggest an uneven back-and-forth,
    /// but do not identify which player or stroke caused it.
    var alternatingGapContrast: Double? {
        guard gaps.count >= 8 else { return nil }
        let pairs = stride(from: 0, to: gaps.count - 1, by: 2).map { (gaps[$0], gaps[$0 + 1]) }
        let odd = pairs.map(\.0).reduce(0, +) / Double(pairs.count)
        let even = pairs.map(\.1).reduce(0, +) / Double(pairs.count)
        let contrast = abs(odd - even) / ((odd + even) / 2)
        let agreement = Double(pairs.filter { (odd > even) == ($0.0 > $0.1) }.count) / Double(pairs.count)
        guard contrast >= 0.25, agreement >= 0.75 else { return nil }
        return contrast
    }
}
