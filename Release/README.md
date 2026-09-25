# App Store release

## Identity

- Bundle ID: `com.matthew5030.PaddleCounter` (explicit App ID registered).
- Team: `J8M4ND59V4`.
- App Store Connect app: [PaddleCounter](https://appstoreconnect.apple.com/apps/6815980361/distribution).
- Apple ID: `6815980361`.
- SKU: `PaddleCounter-iOS-001`.
- Primary language: English (U.K.). Category: Sports.

## 2026-09-25 preparation

- Version 1.0, build 1 archived and successfully uploaded to App Store Connect. Apple processing remains separate from upload success.
- All 18 unit tests passed on iPhone 17 / iOS 26.5 Simulator.
- Added the privacy manifest for app-only preferences/calibration (`CA92.1`) and elapsed hit timing (`35F9.1`). No tracking or off-device data collection.
- Declared no non-exempt encryption in the generated Info.plist.
- Saved draft listing text, keywords, subtitle, review instructions and a no-data-collection privacy response.
- Set manual release after review. No review submission or public release has occurred.

## Still required before submission

- Confirm launch pricing and territories.
- Supply and verify a public support URL and privacy-policy URL; add a privacy-policy link within the app.
- Capture representative App Store screenshots at accepted sizes, including the large counter and rhythm/history screens. Do not present fabricated performance claims or user results as real.
- Complete age ratings and content-rights information.
- Provide the app review contact details.
- Publish the completed privacy declaration, select the processed build, and resolve any App Store Connect validation issues.
- Final physical-device check of calibration, sensitivity, noise rejection, milestone audio feedback, interruption handling and session persistence.

## Reproducible upload

Increment `CURRENT_PROJECT_VERSION` in `project.yml` before a subsequent upload, then regenerate the Xcode project. Never reuse a build number already uploaded.

```sh
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project PaddleCounter.xcodeproj -scheme PaddleCounter \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /absolute/path/PaddleCounter.xcarchive \
  -allowProvisioningUpdates archive

# This command uploads to Apple; it does not merely export an IPA.
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -exportArchive -archivePath /absolute/path/PaddleCounter.xcarchive \
  -exportOptionsPlist Release/ExportOptions.plist \
  -exportPath /absolute/path/export -allowProvisioningUpdates
```

The first archive is available locally at `/Users/matthewbilella/Library/Developer/Xcode/Archives/2026-09-25/PaddleCounter 1.0.xcarchive`.
