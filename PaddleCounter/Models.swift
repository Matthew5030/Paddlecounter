import Foundation
import SwiftData
@Model final class SessionRecord {
 var startedAt: Date; var endedAt: Date?
 @Relationship(deleteRule: .cascade, inverse: \RallyRecord.session) var rallies: [RallyRecord] = []
 init(startedAt: Date = .now) { self.startedAt = startedAt }
 var totalHits: Int { rallies.reduce(0) { $0 + $1.hits } }
 var best: Int { rallies.map(\.hits).max() ?? 0 }
}
@Model final class RallyRecord {
 var startedAt: Date; var endedAt: Date; var hits: Int; var session: SessionRecord?
 init(startedAt: Date, endedAt: Date, hits: Int) { self.startedAt=startedAt; self.endedAt=endedAt; self.hits=hits }
}
