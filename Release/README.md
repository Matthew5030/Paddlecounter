# App Store release

## Identity

- Bundle ID: `com.matthew5030.PaddleCounter` (explicit App ID registered).
- Team: `J8M4ND59V4`.
- App Store Connect app: [PaddleCounter](https://appstoreconnect.apple.com/apps/6815980361/distribution).
- Apple ID: `6815980361`.
- SKU: `PaddleCounter-iOS-001`.
- Primary language: English (U.K.). Category: Sports.

## 2026-09-25 preparation

- Version 1.0, build 1 archived, uploaded and processed by Apple. Build 1 is attached to the version 1.0 submission draft.
- All 18 unit tests passed on iPhone 17 / iOS 26.5 Simulator.
- Added the privacy manifest for app-only preferences/calibration (`CA92.1`) and elapsed hit timing (`35F9.1`). No tracking or off-device data collection.
- Declared no non-exempt encryption in the generated Info.plist.
- Saved draft listing text, keywords, subtitle, review instructions and a no-data-collection privacy response.
- Set manual release after review. No review submission or public release has occurred.
- Free pricing saved for 175 countries/regions; app availability territories are still unconfigured.
- PaddleCounter product, privacy and support pages prepared in the Bilella Works Web repository (commit `5f021bf552fbc4f9d961ea4070336bbf44b03fc0`). Static validation, 128 local link checks, desktop/mobile layout and support redirect/FAQ checks passed. Sites archive upload timed out twice, so publication is not confirmed and App Store support/privacy URL fields remain unset. Another task is editing that website checkout; preserve its concurrent changes.

## Still required before submission

- Confirm launch territories and configure availability (launch price is free).
- Supply and verify a public support URL and privacy-policy URL; add a privacy-policy link within the app.
- Capture representative App Store screenshots at accepted sizes, including the large counter and rhythm/history screens. Do not present fabricated performance claims or user results as real.
- Complete age ratings and content-rights information.
- Provide the app review contact details.
- Publish the completed privacy declaration, select the processed build, and resolve any App Store Connect validation issues.
- Final physical-device check of calibration, sensitivity, noise rejection, milestone audio feedback, interruption handling and session persistence.

## Build 2 submission preparation

- Added an accessible in-app Privacy screen, full privacy-policy link and support link in Settings.
- Fixed generated Info.plist configuration for the unit-test target so a fresh generated project runs its tests without command-line overrides.
- Build 2 archived and uploaded successfully on 25 September 2026; build selection and Apple processing still need checking.
- All 18 existing unit tests pass on iPhone 17 Pro Max / iOS 26.5, plus the screenshot fixture test passes separately.
- Four 6.9-inch screenshots uploaded: counter, rhythm, calibration and sensitivity/settings. Counter and rhythm figures are illustrative fixture data, disclosed in App Review notes; no fixtures ship in the app.
- Content rights set to no third-party content; age rating calculated as 4+; worldwide availability configured. Untested Mac and Apple Vision Pro availability disabled.
- App Review contact details saved only in App Store Connect. Do not copy the private review phone into this repository, screenshots or public pages.
- No-data-collected privacy declaration is published. Policy, support and marketing URLs are saved in the next-version draft, but live route publication remains a submission gate.

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
