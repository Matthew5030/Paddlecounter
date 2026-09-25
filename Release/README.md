# App Store release

## Current status — submitted 25 September 2026

- Version **1.0 (build 2)** is **Waiting for Review**, confirmed in App Store Connect after final submission.
- Submission ID: `d039cf18-5f8f-4a63-b746-06ecf7daf49c`.
- [Review submission](https://appstoreconnect.apple.com/apps/6815980361/distribution/reviewsubmissions/details/d039cf18-5f8f-4a63-b746-06ecf7daf49c).
- Free pricing and 175-country/region availability are configured. Manual release after approval remains selected; the app is not publicly released yet.
- With user approval, website commit `9e74b1c7315c4f06aba4e11aa989705678253c5e` was pushed to the existing GitHub/Cloudflare production pipeline. Cloudflare Pages completed successfully (deployment `d287bbc9-2499-4e32-ae8e-0cdb4e7a5fbb`). The live privacy page and support redirect/FAQs were verified before final Apple submission:
  - https://bilellaworks.com/apps/paddlecounter/privacy/
  - https://bilellaworks.com/apps/paddlecounter/support/
- Private review contact details remain only in App Store Connect, not on the public website or in source control.
- Next release gate: Apple approval, then manual release. The entries below are historical preparation notes, not outstanding submission requirements.

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

## Original pre-submission checklist (historical)

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
- Build 2 archived, uploaded, processed and selected on 25 September 2026.
- All 18 existing unit tests pass on iPhone 17 Pro Max / iOS 26.5, plus the screenshot fixture test passes separately.
- Four 6.9-inch screenshots uploaded: counter, rhythm, calibration and sensitivity/settings. Counter and rhythm figures are illustrative fixture data, disclosed in App Review notes; no fixtures ship in the app.
- Content rights set to no third-party content; age rating calculated as 4+; worldwide availability configured. Untested Mac and Apple Vision Pro availability disabled.
- App Review contact details saved only in App Store Connect. Do not copy the private review phone into this repository, screenshots or public pages.
- No-data-collected privacy declaration is published. Policy, support and marketing URLs are saved in the next-version draft, but live route publication remains a submission gate.
- Apple accepted Add for Review with no validation errors. Version 1.0 is now Ready for Review with an Item Ready to Submit and a Submit for Review button. Final submission has NOT been clicked because the public policy/support routes are not yet live.
- The website task handed over its stable current snapshot; all its changes are preserved in site commit `9e74b1c7315c4f06aba4e11aa989705678253c5e`. Native Sites archive uploads still time out. Awaiting the user's answer about using the existing GitHub/Cloudflare production path instead. Do not deploy the obsolete `5f021bf` snapshot over the newer website.

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
