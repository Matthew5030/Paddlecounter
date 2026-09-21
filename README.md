# PaddleCounter

PaddleCounter is a native iPhone app that learns the sound of a particular paddle, counts hits hands-free, closes each rally after a configurable quiet period, and keeps a permanent session history.

## Detection pipeline

The detector runs entirely on the iPhone:

1. An adaptive noise floor and onset gate find short, sharp candidate sounds.
2. Each candidate becomes a 30-value fingerprint: 18 log-mel spectral bands, a six-part temporal envelope, spectral centroid, high-frequency energy, peak/RMS, level, spectral flatness and zero-crossing rate.
3. Calibration stores multiple positive paddle-hit examples and explicit negative examples such as speech, claps, footsteps and ball bounces.
4. A locally trained, variance-normalised nearest-neighbour classifier compares each candidate with both groups. It accepts a sound only when it resembles the paddle cluster and is clearly separated from ignored sounds.

Only feature vectors and detection metadata are retained. Raw microphone audio and conversations are not saved or uploaded.

## Calibration

- Record 15–30 representative paddle hits from the phone's normal playing position.
- Record at least 20 ignored sounds: both players talking, claps, footsteps, shoe squeaks, ball bounces and other indoor impacts.
- Start a session and watch the detector diagnostics. Each candidate shows its confidence, its distance from learned hits and ignored sounds, and the reason it was accepted or rejected.
- Adjust the confidence threshold in Settings if real hits are missed or false positives remain.

Changing the phone position or acoustic environment substantially should be followed by a new calibration.

## Build

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open PaddleCounter.xcodeproj
```

Select an Apple signing team and a physical iPhone. Microphone classification cannot be meaningfully evaluated in the simulator.

Run unit tests from Xcode with Product → Test. The test target covers positive matching, negative rejection, insufficient calibration and profile persistence.
