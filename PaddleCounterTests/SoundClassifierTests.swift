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

    func testProfileRoundTripsWithoutAudio() throws {
        let original = makeProfile()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SoundProfile.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertTrue(decoded.isReady)
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
