# App Store screenshots

6.9-inch iPhone images are 1320 x 2868 portrait or 2868 x 1320 landscape.

- `01-setup` and `02-calibration`: captured directly from the app on the iPhone 17 Pro Max simulator, iOS 26.5.
- `03-live-counter-example`, `04-history-example`, `05-rhythm-example`: production SwiftUI views rendered on the same simulator with illustrative in-memory rally data by `AppStoreScreenshotTests`. These examples are not real-world accuracy measurements, and no sample data is shipped to users.
- `06-settings`: production settings view with default preferences, rendered by the same test.

The fixture test is in the test bundle only. Run it on the iPhone 17 Pro Max and export its image attachments with `xcresulttool export attachments` to reproduce these views. No generated mockup or image editing is used.
