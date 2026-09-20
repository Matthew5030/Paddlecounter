# PaddleCounter

Native iPhone MVP that learns a paddle-hit acoustic fingerprint, counts hits hands-free, closes a rally after 3 seconds without a recognised hit, resets automatically, and stores every rally.

## Run
Install XcodeGen (`brew install xcodegen`), run `xcodegen generate`, open `PaddleCounter.xcodeproj`, select your signing team and iPhone, then Run.

## Test
Calibrate with 10–20 representative hits from the phone's playing position, then start a session. The detector combines transient shape and spectral similarity rather than volume alone. Continuous audio is not stored.

This first detector is deliberately simple and inspectable so real-game recordings can guide the next classifier.
