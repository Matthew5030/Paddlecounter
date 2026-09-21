# PaddleCounter

PaddleCounter is a native iPhone app that learns the sound of a particular paddle, counts hits hands-free, closes each rally after a configurable quiet period, and keeps a permanent session history.

## Detection pipeline

The detector runs entirely on the iPhone:

1. An adaptive noise floor and onset gate find short, sharp candidate sounds.
2. Each candidate becomes a 30-value fingerprint: 18 log-mel spectral bands, a six-part temporal envelope, spectral centroid, high-frequency energy, peak/RMS, level, spectral flatness and zero-crossing rate.
3. Calibration stores multiple positive paddle-hit examples. Common speech and low indoor noise are rejected automatically by a standard on-device filter.
4. A locally trained, variance-normalised nearest-neighbour classifier learns the shape and natural variation of that paddle's sound. A smart sensitivity setting jointly adjusts the adaptive sound gate and match threshold.

Only feature vectors and detection metadata are retained. Raw microphone audio and conversations are not saved or uploaded.

## Calibration

- Record 15–30 representative paddle hits from the phone's normal playing position.
- Use the built-in test step to try real hits, speech, claps and other indoor sounds. No separate negative-sound training is required.
- Start a session and turn the phone to landscape. The rally count fills the screen for easy courtside visibility.
- Adjust Sound Sensitivity in Settings: lower it to reject more noises or raise it to hear quieter hits. The detector continues adapting automatically to the room's background level.

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
