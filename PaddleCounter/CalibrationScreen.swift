import SwiftUI

struct CalibrationScreen: View {
    enum Stage: Int, CaseIterable {
        case paddle = 0
        case test = 1
    }

    @ObservedObject var detector: AudioDetector
    let sessionIsActive: Bool
    @Binding var soundSensitivity: Double
    let onError: (String) -> Void

    @State private var stage: Stage = .paddle
    @State private var showingResetConfirmation = false

    var body: some View {
        ZStack {
            PCBackground(accent: stageColour)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    stepIndicator

                    if sessionIsActive {
                        activeSessionMessage
                    } else {
                        stageContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 110)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { chooseBestStage() }
        .confirmationDialog(
            "Reset calibration?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete learned sounds", role: .destructive) {
                detector.resetCalibration()
                stage = .paddle
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to teach PaddleCounter your paddle again.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CALIBRATION")
                    .font(.caption.bold())
                    .tracking(1.5)
                    .foregroundStyle(stageColour)
                Text("Teach the detector")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {
                showingResetConfirmation = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(PCTheme.border))
            }
            .accessibilityLabel("Reset calibration")
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Stage.allCases, id: \.rawValue) { item in
                VStack(alignment: .leading, spacing: 7) {
                    Capsule()
                        .fill(item.rawValue <= stage.rawValue ? stageColour : Color.white.opacity(0.12))
                        .frame(height: 4)
                    Text(stepName(item))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(item == stage ? .white : PCTheme.textSecondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { move(to: item) }
            }
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch stage {
        case .paddle:
            recordingStage(
                eyebrow: "STEP 1 OF 2",
                title: "Record paddle hits",
                explanation: "Make a mix of normal, soft and hard hits from where the phone will sit during play.",
                symbol: "figure.pickleball",
                count: detector.positiveExamples,
                target: 20,
                minimum: 8,
                label: .paddleHit,
                guidance: "Leave a small pause between each hit.",
                nextTitle: "Test the detector",
                nextStage: .test
            )
        case .test:
            testStage
        }
    }

    private func recordingStage(
        eyebrow: String,
        title: String,
        explanation: String,
        symbol: String,
        count: Int,
        target: Int,
        minimum: Int,
        label: CalibrationLabel,
        guidance: String,
        nextTitle: String,
        nextStage: Stage
    ) -> some View {
        let isRecording = detector.isRunning && detector.calibrationLabel == label

        return VStack(spacing: 22) {
            VStack(spacing: 9) {
                Text(eyebrow)
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundStyle(stageColour)
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(explanation)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PCTheme.textSecondary)
            }

            ZStack {
                Circle()
                    .stroke(stageColour.opacity(isRecording ? 0.16 : 0.07), lineWidth: 22)
                    .frame(width: 190, height: 190)
                    .scaleEffect(isRecording ? 1.06 : 1)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isRecording)
                Circle()
                    .fill(stageColour.opacity(0.12))
                    .frame(width: 152, height: 152)
                    .overlay(Circle().stroke(stageColour.opacity(0.32)))
                VStack(spacing: 7) {
                    Image(systemName: isRecording ? "waveform" : symbol)
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(stageColour)
                    Text("\(count)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(isRecording ? "LISTENING" : "EXAMPLES")
                        .font(.caption2.bold())
                        .tracking(1.1)
                        .foregroundStyle(PCTheme.textSecondary)
                }
            }

            VStack(spacing: 9) {
                ProgressView(value: Double(min(count, target)), total: Double(target))
                    .tint(stageColour)
                HStack {
                    Text(count >= target ? "Great variety" : "Aim for \(target)")
                    Spacer()
                    Text("Minimum \(minimum)")
                }
                .font(.caption)
                .foregroundStyle(PCTheme.textSecondary)
            }
            .padding(.horizontal, 6)

            Button { toggleRecording(label) } label: {
                Label(isRecording ? "Stop recording" : "Start recording", systemImage: isRecording ? "stop.fill" : "mic.fill")
                    .font(.headline)
                    .foregroundStyle(isRecording ? .white : PCTheme.ink)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(isRecording ? PCTheme.coral : stageColour, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)

            Label(guidance, systemImage: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(PCTheme.textSecondary)

            Button {
                move(to: nextStage)
            } label: {
                HStack {
                    Text(nextTitle)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(count >= minimum ? .white : PCTheme.textSecondary)
                .padding(17)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(count < minimum)
        }
        .padding(22)
        .pcCard()
    }

    private var testStage: some View {
        let testing = detector.isRunning && detector.calibrationLabel == nil
        let ready = detector.positiveExamples >= 8

        return VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(ready ? PCTheme.lime.opacity(0.14) : PCTheme.coral.opacity(0.14))
                    .frame(width: 104, height: 104)
                Image(systemName: ready ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(ready ? PCTheme.lime : PCTheme.coral)
            }

            VStack(spacing: 8) {
                Text(ready ? "Your detector is ready" : "A few more examples needed")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(ready ? "Try paddle hits, speech and other noises. Common indoor sounds are rejected automatically." : "Record at least eight paddle-hit examples first.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PCTheme.textSecondary)
            }

            calibrationTotal(title: "Paddle examples learned", count: detector.positiveExamples, colour: PCTheme.lime)

            VStack(spacing: 10) {
                HStack {
                    Label("Smart sensitivity", systemImage: "ear")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(sensitivityLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(PCTheme.lime)
                }
                Slider(value: $soundSensitivity, in: 0...1, step: 0.05)
                    .tint(PCTheme.lime)
                HStack {
                    Text("Reject more noise")
                    Spacer()
                    Text("Hear quieter hits")
                }
                .font(.caption2)
                .foregroundStyle(PCTheme.textSecondary)
            }
            .padding(15)
            .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))

            if ready {
                Button(action: toggleTest) {
                    Label(testing ? "Stop test" : "Test detector", systemImage: testing ? "stop.fill" : "waveform")
                        .font(.headline)
                        .foregroundStyle(testing ? .white : PCTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(testing ? PCTheme.coral : PCTheme.lime, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }

            if testing || !detector.recentEvents.isEmpty {
                compactResults
            }

            Label("Audio stays on this iPhone. Only small numerical fingerprints are saved.", systemImage: "lock.shield.fill")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(PCTheme.textSecondary)
        }
        .padding(22)
        .pcCard()
    }

    private var compactResults: some View {
        VStack(spacing: 10) {
            if detector.recentEvents.isEmpty {
                Text("Make a sound to see the result")
                    .font(.subheadline)
                    .foregroundStyle(PCTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(detector.recentEvents.prefix(4)) { event in
                    HStack(spacing: 10) {
                        Image(systemName: event.accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(event.accepted ? PCTheme.lime : PCTheme.coral)
                        Text(event.accepted ? "Paddle hit" : event.reason)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(event.confidence, format: .percent.precision(.fractionLength(0)))
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(PCTheme.textSecondary)
                    }
                }
            }
        }
        .padding(15)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
    }

    private var activeSessionMessage: some View {
        VStack(spacing: 17) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 58))
                .foregroundStyle(PCTheme.lime)
            Text("A session is running")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Finish the session from the Play tab before changing calibration.")
                .multilineTextAlignment(.center)
                .foregroundStyle(PCTheme.textSecondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .pcCard()
    }

    private func calibrationTotal(title: String, count: Int, colour: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(colour)
            Text(title)
                .font(.caption)
                .foregroundStyle(PCTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 15))
    }

    private var stageColour: Color {
        switch stage {
        case .paddle: PCTheme.lime
        case .test: PCTheme.aqua
        }
    }

    private var sensitivityLabel: String {
        switch soundSensitivity {
        case ..<0.25: "Quiet room"
        case 0.25..<0.65: "Smart"
        case 0.65..<0.85: "Sensitive"
        default: "Very sensitive"
        }
    }

    private func stepName(_ item: Stage) -> String {
        switch item {
        case .paddle: "Paddle"
        case .test: "Test"
        }
    }

    private func chooseBestStage() {
        if detector.positiveExamples < 8 {
            stage = .paddle
        } else {
            stage = .test
        }
    }

    private func move(to newStage: Stage) {
        if detector.isRunning { detector.stop() }
        withAnimation(.snappy) { stage = newStage }
    }

    private func toggleRecording(_ label: CalibrationLabel) {
        Task {
            if detector.isRunning {
                detector.stop()
                return
            }
            do {
                try await detector.beginCalibration(label)
            } catch {
                onError(error.localizedDescription)
            }
        }
    }

    private func toggleTest() {
        Task {
            if detector.isRunning {
                detector.stop()
                return
            }
            do {
                detector.clearRecentEvents()
                detector.calibrationLabel = nil
                try await detector.start()
            } catch {
                onError(error.localizedDescription)
            }
        }
    }
}
