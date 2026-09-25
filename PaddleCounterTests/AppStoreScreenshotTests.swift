import SwiftData
import SwiftUI
import XCTest
@testable import PaddleCounter

// Render the production SwiftUI views with illustrative, in-memory rally data.
// No fixtures, launch switches or sample records are added to the shipped app.
final class AppStoreScreenshotTests: XCTestCase {
    @MainActor
    func testStoreScreenshots() async throws {
        guard ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] == "iPhone18,2" else {
            throw XCTSkip("Store captures use the iPhone 17 Pro Max (6.9-inch) canvas.")
        }
        let schema = Schema([SessionRecord.self, RallyRecord.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = container.mainContext
        let detector = AudioDetector()
        let game = GameController()
        game.silenceSeconds = 60
        game.startSession(context: context)
        for index in 0..<24 {
            game.hit(confidence: 0.9, context: context, uptime: 100 + Double(index) * 0.65)
        }
        try await capture("03-live-counter-example", size: CGSize(width: 956, height: 440), view:
            PlayScreen(game: game, detector: detector, detectorIsReady: true,
                       onPrimaryAction: {}, onCalibration: {}, onSettings: {}))
        game.stop(context: context)

        let start = Date(timeIntervalSince1970: 1_790_323_200)
        let session = SessionRecord(startedAt: start)
        context.insert(session)
        for (index, count) in [24, 36, 18].enumerated() {
            var offsets = [0.0]
            for hit in 1..<count {
                let gap = 0.62 + sin(Double(hit) * 0.8) * 0.08 + Double(index) * 0.04
                offsets.append(offsets.last! + gap)
            }
            let rallyStart = start.addingTimeInterval(Double(index) * 40)
            let rally = RallyRecord(startedAt: rallyStart,
                                    endedAt: rallyStart.addingTimeInterval(offsets.last!),
                                    hits: count, averageConfidence: 0.9, minimumConfidence: 0.78,
                                    hitOffsets: offsets)
            context.insert(rally)
            rally.session = session
        }
        session.endedAt = start.addingTimeInterval(100)
        try context.save()
        XCTAssertEqual(session.rallies.count, 3)
        let portrait = CGSize(width: 440, height: 956)
        try await capture("04-history-example", size: portrait, view:
            HistoryScreen(sessions: [session]))
        let rally = try XCTUnwrap(session.rallies.sorted { $0.hits > $1.hits }.first)
        try await capture("05-rhythm-example", size: portrait, view:
            NavigationStack { RhythmScreen(rally: rally, number: 2) })
        try await capture("06-settings", size: portrait, view:
            SettingsView(detector: detector, silenceSeconds: .constant(3), minimumHits: .constant(1),
                         soundSensitivity: .constant(0.9), milestoneSoundsEnabled: .constant(true)))
    }

    @MainActor
    private func capture<V: View>(_ name: String, size: CGSize, view: V) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let originalWindow = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        let host = UIHostingController(rootView: view.preferredColorScheme(.dark))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            originalWindow?.makeKeyAndVisible()
        }
        try await Task.sleep(for: .milliseconds(600))
        host.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true) }
        XCTAssertEqual(image.cgImage?.width, Int(size.width * 3))
        XCTAssertEqual(image.cgImage?.height, Int(size.height * 3))
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
