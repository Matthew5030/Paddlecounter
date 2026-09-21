import AVFoundation
import Accelerate
import Foundation

struct DetectionEvent: Identifiable, Equatable, Sendable {
    let id = UUID()
    let timestamp: Date
    let confidence: Float
    let accepted: Bool
    let reason: String
    let positiveDistance: Float
    let negativeDistance: Float?
}

@MainActor
final class AudioDetector: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var lastConfidence: Float = 0
    @Published private(set) var recentEvents: [DetectionEvent] = []
    @Published private(set) var positiveExamples = CalibrationStore.shared.profile.positiveCount
    @Published private(set) var negativeExamples = CalibrationStore.shared.profile.negativeCount
    @Published var calibrationLabel: CalibrationLabel?

    var onHit: ((Float) -> Void)?
    var sensitivity: Double = 0.5

    var classificationThreshold: Float {
        0.84 - Float(sensitivity) * 0.24
    }

    private let engine = AVAudioEngine()
    private var lastEvent = Date.distantPast
    private var noiseFloor: Float = 0.003
    private var previousRMS: Float = 0
    private var tapInstalled = false

    func start() async throws {
        guard !isRunning else { return }
        let permitted = await AVAudioApplication.requestRecordPermission()
        guard permitted else {
            throw NSError(
                domain: "PaddleCounter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Microphone permission is required to recognise paddle hits."]
            )
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [])
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true)
        lastEvent = .distantPast
        previousRMS = 0
        noiseFloor = 0.003

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        if tapInstalled {
            input.removeTap(onBus: 0)
            tapInstalled = false
        }
        input.installTap(onBus: 0, bufferSize: 2_048, format: format) { [weak self] buffer, _ in
            guard let features = Self.extractFeatures(from: buffer, sampleRate: Float(format.sampleRate)) else { return }
            Task { @MainActor in
                self?.consume(features)
            }
        }
        tapInstalled = true

        engine.prepare()
        do {
            try engine.start()
            isRunning = true
        } catch {
            input.removeTap(onBus: 0)
            tapInstalled = false
            try? session.setActive(false)
            throw error
        }
    }

    func stop() {
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        isRunning = false
        calibrationLabel = nil
    }

    func beginCalibration(_ label: CalibrationLabel) async throws {
        if isRunning { stop() }
        calibrationLabel = label
        try await start()
        calibrationLabel = label
    }

    func resetCalibration() {
        stop()
        CalibrationStore.shared.reset()
        positiveExamples = 0
        negativeExamples = 0
        recentEvents = []
        lastConfidence = 0
    }

    func clearRecentEvents() {
        recentEvents = []
        lastConfidence = 0
    }

    private func consume(_ features: AudioFeatures) {
        let now = Date()
        let label = calibrationLabel
        let minimumGap = label == .ignoredSound ? 0.20 : 0.12
        guard now.timeIntervalSince(lastEvent) >= minimumGap else {
            previousRMS = features.rms
            return
        }

        let onsetMultiplier = Float(3.15 - sensitivity * 1.25)
        let minimumPeakRatio = Float(2.45 - sensitivity * 0.70)
        let absoluteFloor = Float(0.009 - sensitivity * 0.004)
        let adaptiveFloor = max(absoluteFloor, noiseFloor * onsetMultiplier)
        let hasOnset = features.rms > adaptiveFloor &&
            features.peakToRMS > minimumPeakRatio &&
            features.rms > max(previousRMS * 1.12, 0.004)
        let usefulNegativeFrame = label == .ignoredSound && features.rms > max(0.005, noiseFloor * 1.35)

        if !hasOnset && !usefulNegativeFrame {
            let boundedRMS = min(features.rms, noiseFloor * 1.5)
            noiseFloor = noiseFloor * 0.985 + boundedRMS * 0.015
            previousRMS = features.rms
            return
        }

        lastEvent = now
        previousRMS = features.rms

        if let label {
            CalibrationStore.shared.add(features, label: label)
            let profile = CalibrationStore.shared.profile
            positiveExamples = profile.positiveCount
            negativeExamples = profile.negativeCount
            lastConfidence = 1
            return
        }

        if let rejection = StandardNoiseFilter.rejectionReason(for: features) {
            lastConfidence = 0
            recentEvents.insert(
                DetectionEvent(
                    timestamp: now,
                    confidence: 0,
                    accepted: false,
                    reason: rejection,
                    positiveDistance: .infinity,
                    negativeDistance: nil
                ),
                at: 0
            )
            recentEvents = Array(recentEvents.prefix(20))
            return
        }

        let classifier = SoundClassifier(threshold: classificationThreshold)
        let result = classifier.classify(features, using: CalibrationStore.shared.profile)
        lastConfidence = result.confidence
        let event = DetectionEvent(
            timestamp: now,
            confidence: result.confidence,
            accepted: result.accepted,
            reason: result.reason,
            positiveDistance: result.positiveDistance,
            negativeDistance: result.negativeDistance
        )
        recentEvents.insert(event, at: 0)
        recentEvents = Array(recentEvents.prefix(20))

        if result.accepted {
            onHit?(result.confidence)
        }
    }

    nonisolated static func extractFeatures(
        from buffer: AVAudioPCMBuffer,
        sampleRate: Float
    ) -> AudioFeatures? {
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let availableCount = Int(buffer.frameLength)
        let fftCount = 2_048
        guard availableCount >= 512 else { return nil }

        var samples = [Float](repeating: 0, count: fftCount)
        let copiedCount = min(availableCount, fftCount)
        samples.withUnsafeMutableBufferPointer { destination in
            destination.baseAddress?.update(from: channel, count: copiedCount)
        }

        var rms: Float = 0
        var peak: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(copiedCount))
        vDSP_maxmgv(samples, 1, &peak, vDSP_Length(copiedCount))

        var zeroCrossings = 0
        if copiedCount > 1 {
            for index in 1..<copiedCount where (samples[index - 1] >= 0) != (samples[index] >= 0) {
                zeroCrossings += 1
            }
        }

        let temporalEnvelope = envelope(from: samples, validCount: copiedCount, binCount: 6)
        var window = [Float](repeating: 0, count: fftCount)
        vDSP_hann_window(&window, vDSP_Length(fftCount), Int32(vDSP_HANN_NORM))
        vDSP_vmul(samples, 1, window, 1, &samples, 1, vDSP_Length(fftCount))

        let log2Count = vDSP_Length(log2(Float(fftCount)))
        guard let setup = vDSP_create_fftsetup(log2Count, FFTRadix(kFFTRadix2)) else { return nil }
        defer { vDSP_destroy_fftsetup(setup) }

        var real = [Float](repeating: 0, count: fftCount / 2)
        var imaginary = [Float](repeating: 0, count: fftCount / 2)
        samples.withUnsafeBufferPointer { source in
            source.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftCount / 2) { complex in
                real.withUnsafeMutableBufferPointer { realPointer in
                    imaginary.withUnsafeMutableBufferPointer { imaginaryPointer in
                        var split = DSPSplitComplex(
                            realp: realPointer.baseAddress!,
                            imagp: imaginaryPointer.baseAddress!
                        )
                        vDSP_ctoz(complex, 2, &split, 1, vDSP_Length(fftCount / 2))
                        vDSP_fft_zrip(setup, &split, 1, log2Count, FFTDirection(FFT_FORWARD))
                    }
                }
            }
        }

        var magnitudes = [Float](repeating: 0, count: fftCount / 2)
        real.withUnsafeMutableBufferPointer { realPointer in
            imaginary.withUnsafeMutableBufferPointer { imaginaryPointer in
                var split = DSPSplitComplex(
                    realp: realPointer.baseAddress!,
                    imagp: imaginaryPointer.baseAddress!
                )
                vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(fftCount / 2))
            }
        }

        var totalPower: Float = 0
        var weightedPower: Float = 0
        var highPower: Float = 0
        var logPowerSum: Float = 0
        var includedBins = 0
        let nyquist = sampleRate / 2
        let upperFrequency = min(12_000, nyquist)

        for index in 1..<magnitudes.count {
            let frequency = Float(index) * sampleRate / Float(fftCount)
            guard frequency <= upperFrequency else { break }
            let power = max(magnitudes[index], 1e-12)
            totalPower += power
            weightedPower += power * frequency
            if frequency >= 2_500 { highPower += power }
            logPowerSum += log(power)
            includedBins += 1
        }

        guard totalPower > 0, includedBins > 0 else { return nil }
        let arithmeticMean = totalPower / Float(includedBins)
        let geometricMean = exp(logPowerSum / Float(includedBins))
        let logMel = logMelBands(
            magnitudes: magnitudes,
            sampleRate: sampleRate,
            fftCount: fftCount,
            bandCount: 18,
            upperFrequency: upperFrequency
        )

        return AudioFeatures(
            embedding: normalise(logMel) + temporalEnvelope,
            centroid: weightedPower / totalPower,
            highFrequencyRatio: highPower / totalPower,
            peakToRMS: peak / max(rms, 0.0001),
            rms: rms,
            spectralFlatness: geometricMean / max(arithmeticMean, 1e-12),
            zeroCrossingRate: Float(zeroCrossings) / Float(max(copiedCount - 1, 1))
        )
    }

    nonisolated private static func envelope(
        from samples: [Float],
        validCount: Int,
        binCount: Int
    ) -> [Float] {
        let binSize = max(validCount / binCount, 1)
        var values = (0..<binCount).map { bin -> Float in
            let start = bin * binSize
            let end = bin == binCount - 1 ? validCount : min(start + binSize, validCount)
            guard end > start else { return 0 }
            var sum: Float = 0
            for index in start..<end { sum += samples[index] * samples[index] }
            return sqrt(sum / Float(end - start))
        }
        let maximum = max(values.max() ?? 0, 0.0001)
        values = values.map { sqrt($0 / maximum) }
        return values
    }

    nonisolated private static func logMelBands(
        magnitudes: [Float],
        sampleRate: Float,
        fftCount: Int,
        bandCount: Int,
        upperFrequency: Float
    ) -> [Float] {
        let lowerMel = mel(120)
        let upperMel = mel(upperFrequency)
        let points = (0..<(bandCount + 2)).map { index -> Float in
            let fraction = Float(index) / Float(bandCount + 1)
            return inverseMel(lowerMel + (upperMel - lowerMel) * fraction)
        }

        return (0..<bandCount).map { band -> Float in
            let left = points[band]
            let centre = points[band + 1]
            let right = points[band + 2]
            var energy: Float = 0
            for index in 1..<magnitudes.count {
                let frequency = Float(index) * sampleRate / Float(fftCount)
                if frequency < left { continue }
                if frequency > right { break }
                let weight: Float
                if frequency <= centre {
                    weight = (frequency - left) / max(centre - left, 1)
                } else {
                    weight = (right - frequency) / max(right - centre, 1)
                }
                energy += max(weight, 0) * magnitudes[index]
            }
            return log1p(energy)
        }
    }

    nonisolated private static func normalise(_ values: [Float]) -> [Float] {
        guard !values.isEmpty else { return [] }
        let mean = values.reduce(0, +) / Float(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Float(values.count)
        let deviation = max(sqrt(variance), 0.0001)
        return values.map { ($0 - mean) / deviation }
    }

    nonisolated private static func mel(_ frequency: Float) -> Float {
        2_595 * log10(1 + frequency / 700)
    }

    nonisolated private static func inverseMel(_ value: Float) -> Float {
        700 * (pow(10, value / 2_595) - 1)
    }
}
