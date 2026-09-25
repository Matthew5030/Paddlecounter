import Foundation
import SwiftData
@Model
final class SessionRecord {
    var startedAt: Date
    var endedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \RallyRecord.session) var rallies: [RallyRecord] = []

    init(startedAt: Date = .now) {
        self.startedAt = startedAt
    }

    var totalHits: Int { rallies.reduce(0) { $0 + $1.hits } }
    var best: Int { rallies.map(\.hits).max() ?? 0 }
    var averageRally: Double {
        guard !rallies.isEmpty else { return 0 }
        return Double(totalHits) / Double(rallies.count)
    }
}

@Model
final class RallyRecord {
    var startedAt: Date
    var endedAt: Date
    var hits: Int
    var averageConfidence: Double = 0
    var minimumConfidence: Double = 0
    // Optional so existing rallies remain readable without invented timing data.
    var hitOffsets: [Double]? = nil
    var session: SessionRecord?

    init(
        startedAt: Date,
        endedAt: Date,
        hits: Int,
        averageConfidence: Double = 0,
        minimumConfidence: Double = 0,
        hitOffsets: [Double]? = nil
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.hits = hits
        self.averageConfidence = averageConfidence
        self.minimumConfidence = minimumConfidence
        self.hitOffsets = hitOffsets
    }

    var rhythm: RallyRhythm? {
        guard let hitOffsets, hitOffsets.count == hits else { return nil }
        return RallyRhythm(hitOffsets: hitOffsets)
    }

    var averageHitRate: Double? {
        if let rhythm { return rhythm.averageRate }
        let duration = endedAt.timeIntervalSince(startedAt)
        guard hits > 1, duration.isFinite, duration > 0 else { return nil }
        return Double(hits - 1) * 60 / duration
    }
}
