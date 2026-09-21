import AVFoundation
import UIKit

enum RallyCelebration: Equatable, Hashable, Sendable {
    case ten
    case twentyFive
    case fifty
    case century(Int)

    static func milestone(for hitCount: Int) -> RallyCelebration? {
        switch hitCount {
        case 10: .ten
        case 25: .twentyFive
        case 50: .fifty
        case 100: .century(100)
        case let count where count > 100 && count.isMultiple(of: 50): .century(count)
        default: nil
        }
    }

    var playbackSuppression: TimeInterval {
        switch self {
        case .ten: 0.14
        case .twentyFive: 0.16
        case .fifty: 0.18
        case .century: 0.22
        }
    }
}

@MainActor
final class MilestoneFeedback: ObservableObject {
    var isEnabled = true
    private var player: AVAudioPlayer?

    func play(_ celebration: RallyCelebration) {
        guard isEnabled else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try? session.setActive(true)

        let data = Self.makeSound(for: celebration)
        player = try? AVAudioPlayer(data: data)
        player?.volume = 0.48
        player?.prepareToPlay()
        player?.play()

        let style: UIImpactFeedbackGenerator.FeedbackStyle = switch celebration {
        case .ten: .light
        case .twentyFive: .medium
        case .fifty: .heavy
        case .century: .rigid
        }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private struct Tone {
        let start: Double
        let duration: Double
        let startFrequency: Double
        let endFrequency: Double
        let amplitude: Double
    }

    private static func makeSound(for celebration: RallyCelebration) -> Data {
        let tones: [Tone]
        let duration: Double

        switch celebration {
        case .ten:
            duration = 0.16
            tones = [Tone(start: 0, duration: 0.16, startFrequency: 880, endFrequency: 610, amplitude: 0.72)]
        case .twentyFive:
            duration = 0.22
            tones = [
                Tone(start: 0, duration: 0.10, startFrequency: 660, endFrequency: 790, amplitude: 0.62),
                Tone(start: 0.10, duration: 0.12, startFrequency: 900, endFrequency: 1_080, amplitude: 0.68)
            ]
        case .fifty:
            duration = 0.26
            tones = [
                Tone(start: 0, duration: 0.26, startFrequency: 820, endFrequency: 1_360, amplitude: 0.56),
                Tone(start: 0.04, duration: 0.20, startFrequency: 1_230, endFrequency: 1_720, amplitude: 0.28)
            ]
        case .century:
            duration = 0.34
            tones = [
                Tone(start: 0, duration: 0.11, startFrequency: 523, endFrequency: 523, amplitude: 0.58),
                Tone(start: 0.10, duration: 0.11, startFrequency: 659, endFrequency: 659, amplitude: 0.62),
                Tone(start: 0.20, duration: 0.14, startFrequency: 784, endFrequency: 1_046, amplitude: 0.68)
            ]
        }

        return wavData(tones: tones, duration: duration)
    }

    private static func wavData(tones: [Tone], duration: Double) -> Data {
        let sampleRate = 44_100
        let sampleCount = Int(duration * Double(sampleRate))
        var samples = [Int16](repeating: 0, count: sampleCount)

        for sampleIndex in 0..<sampleCount {
            let time = Double(sampleIndex) / Double(sampleRate)
            var value = 0.0

            for tone in tones where time >= tone.start && time < tone.start + tone.duration {
                let localTime = time - tone.start
                let progress = localTime / tone.duration
                let frequency = tone.startFrequency + (tone.endFrequency - tone.startFrequency) * progress
                let attack = min(localTime / 0.012, 1)
                let release = min((tone.duration - localTime) / 0.045, 1)
                let envelope = max(0, min(attack, release))
                value += sin(2 * .pi * frequency * localTime) * tone.amplitude * envelope
            }

            samples[sampleIndex] = Int16(max(-1, min(value, 1)) * Double(Int16.max))
        }

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        append(UInt32(36 + samples.count * 2), to: &data)
        data.append(contentsOf: "WAVEfmt ".utf8)
        append(UInt32(16), to: &data)
        append(UInt16(1), to: &data)
        append(UInt16(1), to: &data)
        append(UInt32(sampleRate), to: &data)
        append(UInt32(sampleRate * 2), to: &data)
        append(UInt16(2), to: &data)
        append(UInt16(16), to: &data)
        data.append(contentsOf: "data".utf8)
        append(UInt32(samples.count * 2), to: &data)
        for sample in samples { append(UInt16(bitPattern: sample), to: &data) }
        return data
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}
