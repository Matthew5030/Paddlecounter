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

Sensitivity uses a 0–100 control in one-point steps. The original tuning occupies the middle
third; Strict extends below it and Boost/Maximum extend above it. Saved settings keep their
original behavior (the prior 90% setting now displays as 63/100). Boost lowers both loudness
gates and relaxes profile matching, so it can detect softer impacts but may increase extra
counts. The transient requirement, standard noise filter and negative-example rejection
remain active. The displayed value is a control level, not a microphone gain or probability.

## Rally rhythm

Open History → session → rally to see pace over time, individual gaps, timing variation,
opening/closing pace change, alternating long/short gaps and the quickest sustained stretch.
The session chart compares each rally's average hits per minute.

New rallies store relative recognised-hit times from a monotonic clock; no audio is retained.
Average pace is `(hits - 1) × 60 / elapsed seconds`, excluding breaks between rallies.
The pace line uses up to five trailing intervals; the gap chart shows unsmoothed intervals.
Timing variation is the population standard deviation divided by the mean gap (at least
five hits). Under 10% is labelled Clockwork, under 25% Mostly steady, otherwise Changing rhythm.
Opening/closing comparisons require ten hits and compare the first and last thirds of the
intervals; changes above 15% receive a speeding-up/slowing-down label. Alternating patterns
require eight gaps, at least 25% contrast and 75% agreement across adjacent pairs.
These are descriptive heuristics, not calibrated skill or accuracy scores. The app cannot
attribute gaps to players or measure ball speed, and detection errors affect these statistics.

Existing rallies retain average pace from their saved start/end times. Detailed graphs are
only shown when a complete, strictly increasing list of hit timings is available.

## Build

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open PaddleCounter.xcodeproj
```

Select an Apple signing team and a physical iPhone. Microphone classification cannot be meaningfully evaluated in the simulator.

Run unit tests from Xcode with Product → Test. The test target covers positive matching, negative rejection, insufficient calibration and profile persistence.
