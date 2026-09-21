import Foundation

struct AudioFeatures: Codable, Equatable, Sendable {
    static let expectedEmbeddingCount = 24

    let embedding: [Float]
    let centroid: Float
    let highFrequencyRatio: Float
    let peakToRMS: Float
    let rms: Float
    let spectralFlatness: Float
    let zeroCrossingRate: Float

    var classifierValues: [Float] {
        embedding + [
            centroid / 12_000,
            highFrequencyRatio,
            min(peakToRMS / 10, 2),
            min(rms * 10, 2),
            spectralFlatness,
            zeroCrossingRate
        ]
    }

    var isValid: Bool {
        embedding.count == Self.expectedEmbeddingCount &&
        classifierValues.allSatisfy(\.isFinite)
    }
}

struct ClassificationResult: Equatable, Sendable {
    let confidence: Float
    let accepted: Bool
    let positiveDistance: Float
    let negativeDistance: Float?
    let reason: String
}

struct SoundClassifier: Sendable {
    var threshold: Float = 0.72

    func classify(_ candidate: AudioFeatures, using profile: SoundProfile) -> ClassificationResult {
        let positives = profile.positiveExamples.filter(\.isValid)
        let negatives = profile.negativeExamples.filter(\.isValid)

        guard candidate.isValid, positives.count >= 5 else {
            return ClassificationResult(
                confidence: 0,
                accepted: false,
                positiveDistance: .infinity,
                negativeDistance: nil,
                reason: "More paddle-hit examples are needed"
            )
        }

        let allExamples = positives + negatives
        let scales = featureScales(for: allExamples)
        let positiveDistance = nearestDistance(from: candidate, to: positives, scales: scales)
        let positiveRadius = learnedPositiveRadius(positives, scales: scales)
        let likeness = exp(-positiveDistance / max(positiveRadius, 0.18))

        let confidence: Float
        let negativeDistance: Float?
        var rejectionReason: String?

        if negatives.isEmpty {
            negativeDistance = nil
            confidence = likeness
            if positiveDistance > positiveRadius * 2.1 {
                rejectionReason = "Unlike the learned paddle hits"
            }
        } else {
            let nearestNegative = nearestDistance(from: candidate, to: negatives, scales: scales)
            negativeDistance = nearestNegative
            let separation = nearestNegative / max(positiveDistance + nearestNegative, 0.0001)
            let marginScore = clamp((separation - 0.42) / 0.36)
            confidence = clamp(0.72 * marginScore + 0.28 * likeness)

            if nearestNegative <= positiveDistance * 1.05 {
                rejectionReason = "Closer to an ignored sound"
            } else if positiveDistance > positiveRadius * 2.1 {
                rejectionReason = "Unlike the learned paddle hits"
            }
        }

        let accepted = rejectionReason == nil && confidence >= threshold
        let reason: String
        if accepted {
            reason = "Matched paddle hit"
        } else if let rejectionReason {
            reason = rejectionReason
        } else {
            reason = "Below the confidence threshold"
        }

        return ClassificationResult(
            confidence: confidence,
            accepted: accepted,
            positiveDistance: positiveDistance,
            negativeDistance: negativeDistance,
            reason: reason
        )
    }

    private func nearestDistance(
        from candidate: AudioFeatures,
        to examples: [AudioFeatures],
        scales: [Float]
    ) -> Float {
        let distances = examples
            .map { distance(candidate.classifierValues, $0.classifierValues, scales: scales) }
            .sorted()
        let neighbourCount = min(3, distances.count)
        return distances.prefix(neighbourCount).reduce(0, +) / Float(neighbourCount)
    }

    private func learnedPositiveRadius(_ positives: [AudioFeatures], scales: [Float]) -> Float {
        guard positives.count > 1 else { return 0.45 }
        let nearestNeighbours = positives.enumerated().compactMap { index, example -> Float? in
            let otherDistances = positives.enumerated().compactMap { otherIndex, other -> Float? in
                guard index != otherIndex else { return nil }
                return distance(example.classifierValues, other.classifierValues, scales: scales)
            }
            return otherDistances.min()
        }.sorted()
        return max(percentile(nearestNeighbours, at: 0.75) * 1.8, 0.22)
    }

    private func featureScales(for examples: [AudioFeatures]) -> [Float] {
        guard let first = examples.first else { return [] }
        let rows = examples.map(\.classifierValues)
        return first.classifierValues.indices.map { column in
            let values = rows.map { $0[column] }
            let mean = values.reduce(0, +) / Float(values.count)
            let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Float(values.count)
            return max(sqrt(variance), minimumScale(for: column))
        }
    }

    private func minimumScale(for index: Int) -> Float {
        if index < 18 { return 0.22 }
        if index < AudioFeatures.expectedEmbeddingCount { return 0.10 }
        return 0.08
    }

    private func distance(_ lhs: [Float], _ rhs: [Float], scales: [Float]) -> Float {
        guard lhs.count == rhs.count, lhs.count == scales.count else { return .infinity }
        var weightedSquares: Float = 0
        var totalWeight: Float = 0

        for index in lhs.indices {
            let weight: Float
            if index < 18 {
                weight = 1
            } else if index < AudioFeatures.expectedEmbeddingCount {
                weight = 0.7
            } else {
                let scalarIndex = index - AudioFeatures.expectedEmbeddingCount
                weight = [0.7, 0.8, 0.45, 0.12, 0.55, 0.45][scalarIndex]
            }
            let delta = (lhs[index] - rhs[index]) / scales[index]
            weightedSquares += weight * delta * delta
            totalWeight += weight
        }
        return sqrt(weightedSquares / max(totalWeight, 0.0001))
    }

    private func percentile(_ sortedValues: [Float], at percentile: Float) -> Float {
        guard !sortedValues.isEmpty else { return 0 }
        let position = Int((Float(sortedValues.count - 1) * percentile).rounded())
        return sortedValues[min(max(position, 0), sortedValues.count - 1)]
    }

    private func clamp(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}
