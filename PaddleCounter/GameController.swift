import Foundation
import SwiftData

@MainActor
final class GameController: ObservableObject {
    @Published private(set) var currentHits = 0
    @Published private(set) var active = false
    @Published private(set) var sessionTotalHits = 0
    @Published private(set) var completedRallies = 0
    @Published private(set) var bestRally = 0

    var silenceSeconds: TimeInterval = 3
    var minimumHits = 1

    private var rallyStartedAt: Date?
    private var lastHitAt: Date?
    private var confidences: [Float] = []
    private var timer: Timer?
    private var session: SessionRecord?
    private var modelContext: ModelContext?

    func startSession(context: ModelContext) {
        guard !active else { return }
        let newSession = SessionRecord()
        context.insert(newSession)
        session = newSession
        modelContext = context
        currentHits = 0
        sessionTotalHits = 0
        completedRallies = 0
        bestRally = 0
        confidences = []
        active = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.20, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func hit(confidence: Float, context: ModelContext) {
        guard active else { return }
        if currentHits == 0 { rallyStartedAt = .now }
        currentHits += 1
        sessionTotalHits += 1
        confidences.append(confidence)
        lastHitAt = .now
    }

    private func tick() {
        guard currentHits > 0,
              let lastHitAt,
              let modelContext,
              Date().timeIntervalSince(lastHitAt) >= silenceSeconds else { return }
        finishRally(modelContext)
    }

    func finishRally(_ context: ModelContext) {
        guard currentHits > 0 else { return }
        if currentHits >= minimumHits, let startedAt = rallyStartedAt {
            let average = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Float(confidences.count)
            let rally = RallyRecord(
                startedAt: startedAt,
                endedAt: lastHitAt ?? .now,
                hits: currentHits,
                averageConfidence: Double(average),
                minimumConfidence: Double(confidences.min() ?? 0)
            )
            rally.session = session
            context.insert(rally)
            completedRallies += 1
            bestRally = max(bestRally, currentHits)
        }
        currentHits = 0
        rallyStartedAt = nil
        lastHitAt = nil
        confidences = []
        try? context.save()
    }

    func stop(context: ModelContext) {
        finishRally(context)
        session?.endedAt = .now
        active = false
        timer?.invalidate()
        timer = nil
        modelContext = nil
        try? context.save()
    }
}
