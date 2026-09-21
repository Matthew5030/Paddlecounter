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
    var session: SessionRecord?

    init(
        startedAt: Date,
        endedAt: Date,
        hits: Int,
        averageConfidence: Double = 0,
        minimumConfidence: Double = 0
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.hits = hits
        self.averageConfidence = averageConfidence
        self.minimumConfidence = minimumConfidence
    }
}
