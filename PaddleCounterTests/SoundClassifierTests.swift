import XCTest
@testable import PaddleCounter

final class SoundClassifierTests: XCTestCase {
    func testAcceptsCandidateNearPositiveExamples() {
        let profile = makeProfile()
        let result = SoundClassifier(threshold: 0.70).classify(
            makeFeatures(centre: 0.82, variation: 0.005),
            using: profile
        )

        XCTAssertTrue(result.accepted)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.70)
        XCTAssertLessThan(result.positiveDistance, result.negativeDistance ?? .infinity)
    }

    func testRejectsCandidateNearNegativeExamples() {
        let profile = makeProfile()
        let result = SoundClassifier(threshold: 0.70).classify(
            makeFeatures(centre: -0.72, variation: 0.01),
            using: profile
        )

        XCTAssertFalse(result.accepted)
        XCTAssertEqual(result.reason, "Closer to an ignored sound")
        XCTAssertGreaterThan(result.positiveDistance, result.negativeDistance ?? .infinity)
    }

    func testRequiresAtLeastFivePositiveExamples() {
        let profile = SoundProfile(
            positiveExamples: Array(repeating: makeFeatures(centre: 0.8), count: 4),
            negativeExamples: Array(repeating: makeFeatures(centre: -0.7), count: 8)
        )
        let result = SoundClassifier().classify(makeFeatures(centre: 0.8), using: profile)

        XCTAssertFalse(result.accepted)
        XCTAssertEqual(result.confidence, 0)
        XCTAssertEqual(result.reason, "More paddle-hit examples are needed")
    }

    func testPositiveOnlyProfileCanClassifyHits() {
        let profile = SoundProfile(
            positiveExamples: (0..<12).map {
                makeFeatures(centre: 0.82, variation: Float($0 - 6) * 0.004)
            },
            negativeExamples: []
        )
        let result = SoundClassifier(threshold: 0.70).classify(
            makeFeatures(centre: 0.82, variation: 0.004),
            using: profile
        )

        XCTAssertTrue(result.accepted)
        XCTAssertTrue(profile.isReady)
    }

    func testStandardNoiseFilterRejectsVoiceLikeSound() {
        let voice = AudioFeatures(
            embedding: Array(repeating: 0.1, count: AudioFeatures.expectedEmbeddingCount),
            centroid: 900,
            highFrequencyRatio: 0.06,
            peakToRMS: 2.8,
            rms: 0.09,
            spectralFlatness: 0.12,
            zeroCrossingRate: 0.05
        )

        XCTAssertEqual(StandardNoiseFilter.rejectionReason(for: voice), "Voice-like sound")
    }

    func testProfileRoundTripsWithoutAudio() throws {
        let original = makeProfile()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SoundProfile.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertTrue(decoded.isReady)
    }

    func testRallyMilestonesStaySparseAndGrowWithTheRally() {
        XCTAssertEqual(RallyCelebration.milestone(for: 10), .ten)
        XCTAssertEqual(RallyCelebration.milestone(for: 25), .twentyFive)
        XCTAssertEqual(RallyCelebration.milestone(for: 50), .fifty)
        XCTAssertEqual(RallyCelebration.milestone(for: 100), .century(100))
        XCTAssertEqual(RallyCelebration.milestone(for: 150), .century(150))
        XCTAssertNil(RallyCelebration.milestone(for: 11))
        XCTAssertNil(RallyCelebration.milestone(for: 125))
    }

    @MainActor
    func testSensitivityNowAllowsQuieterLowerConfidenceHits() {
        let detector = AudioDetector()

        detector.sensitivity = 0
        XCTAssertEqual(detector.classificationThreshold, 0.70, accuracy: 0.001)
        XCTAssertEqual(detector.profileDistanceTolerance, 1.4, accuracy: 0.001)

        detector.sensitivity = 0.7
        XCTAssertEqual(detector.classificationThreshold, 0.434, accuracy: 0.001)
        XCTAssertEqual(detector.profileDistanceTolerance, 2.8, accuracy: 0.001)

        detector.sensitivity = 1
        XCTAssertEqual(detector.classificationThreshold, 0.32, accuracy: 0.001)
        XCTAssertEqual(detector.profileDistanceTolerance, 3.4, accuracy: 0.001)
    }

    func testHighSensitivityAcceptsAQuieterProfileVariation() {
        let profile = SoundProfile(
            positiveExamples: (0..<12).map {
                makeFeatures(centre: 0.82, variation: Float($0 - 6) * 0.004)
            },
            negativeExamples: []
        )
        let quieterVariation = makeFeatures(centre: 0.70, variation: -0.02)

        let strict = SoundClassifier(threshold: 0.70).classify(quieterVariation, using: profile)
        let sensitive = SoundClassifier(threshold: 0.36, distanceTolerance: 3.2)
            .classify(quieterVariation, using: profile)

        XCTAssertFalse(strict.accepted)
        XCTAssertTrue(sensitive.accepted)
    }

    private func makeProfile() -> SoundProfile {
        SoundProfile(
            positiveExamples: (0..<12).map {
                makeFeatures(centre: 0.82, variation: Float($0 - 6) * 0.004)
            },
            negativeExamples: (0..<16).map {
                makeFeatures(centre: -0.72, variation: Float($0 - 8) * 0.005)
            }
        )
    }

    private func makeFeatures(centre: Float, variation: Float = 0) -> AudioFeatures {
        let spectrum = (0..<18).map { index in
            centre + variation + Float(index % 3) * 0.015
        }
        let envelope: [Float] = centre > 0
            ? [1, 0.82, 0.61, 0.43, 0.31, 0.22]
            : [0.45, 0.62, 0.81, 1, 0.88, 0.74]
        return AudioFeatures(
            embedding: spectrum + envelope,
            centroid: centre > 0 ? 4_200 : 1_500,
            highFrequencyRatio: centre > 0 ? 0.48 : 0.12,
            peakToRMS: centre > 0 ? 6.1 : 2.6,
            rms: 0.12,
            spectralFlatness: centre > 0 ? 0.26 : 0.62,
            zeroCrossingRate: centre > 0 ? 0.18 : 0.07
        )
    }
}
