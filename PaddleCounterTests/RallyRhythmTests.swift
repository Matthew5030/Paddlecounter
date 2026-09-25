import SwiftData
import SwiftUI
import XCTest
@testable import PaddleCounter

final class RallyRhythmTests: XCTestCase {
    @MainActor
    func testRhythmLayoutSnapshots() async throws {
        let rhythm = try XCTUnwrap(makeRhythm(gaps: (0..<24).map { $0.isMultiple(of: 2) ? 0.4 : 0.7 }))
        let offsets = [0] + rhythm.samples.map(\.elapsed)
        let rally = RallyRecord(startedAt: .now, endedAt: .now, hits: offsets.count, hitOffsets: offsets)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previousWindow = scene.windows.first { $0.isKeyWindow }
        for width in [320.0, 430.0] {
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: width, height: 1600)
            let host = UIHostingController(rootView: NavigationStack { RhythmScreen(rally: rally, number: 1) })
            window.rootViewController = host
            window.makeKeyAndVisible()
            try await Task.sleep(for: .milliseconds(300))
            host.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: host.view.bounds)
            let image = renderer.image { _ in host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true) }
            let attachment = XCTAttachment(image: image)
            attachment.name = "Rhythm-\(Int(width))"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTAssertGreaterThan(host.view.bounds.width, 0)
            window.isHidden = true
        }
        previousWindow?.makeKeyAndVisible()
    }

    func testEvenRhythmUsesIntervalsAndIgnoresAbsoluteStartTime() throws {
        let rhythm = try XCTUnwrap(RallyRhythm(hitOffsets: (0...10).map { 40 + Double($0) * 0.5 }))
        XCTAssertEqual(rhythm.averageRate, 120, accuracy: 0.001)
        XCTAssertEqual(rhythm.duration, 5)
        XCTAssertEqual(rhythm.variation, 0)
        XCTAssertEqual(rhythm.paceChange, 0)
        XCTAssertEqual(rhythm.fastestFiveRate, 120)
        XCTAssertEqual(rhythm.samples.last?.elapsed, 5)
        XCTAssertNil(rhythm.alternatingGapContrast)
    }

    func testAlternatingGapsAreDetectedWithoutClaimingPlayers() throws {
        let rhythm = try XCTUnwrap(makeRhythm(gaps: [0.4, 0.8, 0.4, 0.8, 0.4, 0.8, 0.4, 0.8]))
        XCTAssertEqual(rhythm.averageRate, 100, accuracy: 0.001)
        XCTAssertGreaterThan(try XCTUnwrap(rhythm.alternatingGapContrast), 0.6)
        XCTAssertEqual(rhythm.rhythmLabel, "Changing rhythm")
    }

    func testTrendAndFastestStretchUseTimeWeightedRate() throws {
        let rhythm = try XCTUnwrap(makeRhythm(gaps: [1, 1, 1, 0.75, 0.75, 0.75, 0.5, 0.5, 0.5]))
        XCTAssertEqual(rhythm.paceChange, 1)
        XCTAssertEqual(rhythm.trendLabel, "Picking up speed")
        XCTAssertEqual(rhythm.averageRate, 80, accuracy: 0.001)
        XCTAssertEqual(rhythm.fastestFiveRate, 100)
        XCTAssertNil(rhythm.alternatingGapContrast)
    }

    func testShortAndInvalidRalliesDoNotInventInsights() throws {
        for invalid in [[], [0], [0, 0], [1, 0], [0, Double.nan], [0, Double.infinity], [-1, 0]] as [[Double]] {
            XCTAssertNil(RallyRhythm(hitOffsets: invalid))
        }
        let short = try XCTUnwrap(RallyRhythm(hitOffsets: [0, 1]))
        XCTAssertEqual(short.averageRate, 60)
        XCTAssertNil(short.variation)
        XCTAssertNil(short.paceChange)
        XCTAssertNil(short.fastestFiveRate)
        XCTAssertNil(short.alternatingGapContrast)
    }

    @MainActor
    func testLegacyRalliesKeepAveragePaceWithoutDetailedTiming() {
        let rally = RallyRecord(startedAt: Date(timeIntervalSince1970: 0), endedAt: Date(timeIntervalSince1970: 10), hits: 11)
        XCTAssertNil(rally.rhythm)
        XCTAssertEqual(rally.averageHitRate, 60)
    }

    @MainActor
    func testTimingSurvivesSaveAndResetsBetweenRallies() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("timing.store")
        let schema = Schema([SessionRecord.self, RallyRecord.self])
        let configuration = ModelConfiguration(schema: schema, url: url)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = container.mainContext
            let game = GameController()
            game.startSession(context: context)
            for time in [100.0, 100.5, 101.0] { game.hit(confidence: 0.9, context: context, uptime: time) }
            game.finishRally(context)
            for time in [110.0, 111.0] { game.hit(confidence: 0.9, context: context, uptime: time) }
            game.stop(context: context)
        }
        let reopened = try ModelContainer(for: schema, configurations: [configuration])
        let records = try reopened.mainContext.fetch(FetchDescriptor<RallyRecord>())
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.first { $0.hits == 3 }?.hitOffsets, [0, 0.5, 1])
        XCTAssertEqual(records.first { $0.hits == 2 }?.hitOffsets, [0, 1])
        XCTAssertEqual(records.first { $0.hits == 2 }?.averageHitRate, 60)
    }

    private func makeRhythm(gaps: [Double]) -> RallyRhythm? {
        var offsets = [0.0]
        for gap in gaps { offsets.append((offsets.last ?? 0) + gap) }
        return RallyRhythm(hitOffsets: offsets)
    }
}
