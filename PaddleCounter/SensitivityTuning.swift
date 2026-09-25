import Foundation

/// Extends the original 0...1 setting at both ends, preserving saved tuning.
struct SensitivityTuning {
    static let range = -1.0...2.0
    let level: Double

    init(_ value: Double) {
        level = value.isFinite ? min(max(value, Self.range.lowerBound), Self.range.upperBound) : 0.9
    }

    var percent: Double { (level + 1) / 3 * 100 }
    var label: String {
        switch level {
        case ..<0: "Strict"
        case 0..<0.65: "Smart"
        case 0.65..<1: "Sensitive"
        case 1..<1.5: "Boost"
        default: "Maximum"
        }
    }

    var classificationThreshold: Float { interpolate(0.94, 0.70, 0.32, 0.20) }
    var distanceTolerance: Float { interpolate(1, 1.4, 3.4, 4.8) }
    var onsetMultiplier: Float { interpolate(4, 2, 1.2, 1.08) }
    var minimumPeakRatio: Float { interpolate(3, 1.9, 1.25, 1.10) }
    var absoluteFloor: Float { interpolate(0.018, 0.0045, 0.0015, 0.00035) }
    var riseMultiplier: Float { interpolate(1.20, 1.04, 1.01, 1.002) }
    var minimumRisingRMS: Float { interpolate(0.010, 0.0025, 0.0025, 0.00035) }

    func hasOnset(rms: Float, peakToRMS: Float, previousRMS: Float, noiseFloor: Float) -> Bool {
        rms > max(absoluteFloor, noiseFloor * onsetMultiplier) &&
            peakToRMS > minimumPeakRatio &&
            rms > max(previousRMS * riseMultiplier, minimumRisingRMS)
    }

    private func interpolate(_ strict: Float, _ originalLow: Float, _ originalHigh: Float, _ boost: Float) -> Float {
        if level < 0 { return originalLow + Float(-level) * (strict - originalLow) }
        if level <= 1 { return originalLow + Float(level) * (originalHigh - originalLow) }
        return originalHigh + Float(level - 1) * (boost - originalHigh)
    }
}
