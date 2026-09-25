import Foundation

enum CalibrationLabel: String, Codable, Sendable {
    case paddleHit
    case ignoredSound
}

struct SoundProfile: Codable, Equatable {
    static let currentVersion = 2

    var version: Int = Self.currentVersion
    var positiveExamples: [AudioFeatures] = []
    var negativeExamples: [AudioFeatures] = []

    var positiveCount: Int { positiveExamples.count }
    var negativeCount: Int { negativeExamples.count }
    var isReady: Bool { positiveCount >= 8 }
}

final class CalibrationStore {
    static let shared = CalibrationStore()

    private let key = "paddleSoundProfileV2"
    private let legacyKey = "paddleSoundProfile"
    private let maximumExamplesPerClass = 80

    private init() {}

    var profile: SoundProfile {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let profile = try? JSONDecoder().decode(SoundProfile.self, from: data) else {
                return SoundProfile()
            }
            return profile
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var hasLegacyCalibration: Bool {
        UserDefaults.standard.data(forKey: legacyKey) != nil
    }

    func add(_ features: AudioFeatures, label: CalibrationLabel) {
        var updated = profile
        switch label {
        case .paddleHit:
            updated.positiveExamples.append(features)
            if updated.positiveExamples.count > maximumExamplesPerClass {
                updated.positiveExamples.removeFirst(updated.positiveExamples.count - maximumExamplesPerClass)
            }
        case .ignoredSound:
            updated.negativeExamples.append(features)
            if updated.negativeExamples.count > maximumExamplesPerClass {
                updated.negativeExamples.removeFirst(updated.negativeExamples.count - maximumExamplesPerClass)
            }
        }
        profile = updated
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
}
