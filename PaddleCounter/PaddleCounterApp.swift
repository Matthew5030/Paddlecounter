import SwiftUI
import SwiftData
@main struct PaddleCounterApp: App { var body: some Scene { WindowGroup { ContentView() }.modelContainer(for: [SessionRecord.self, RallyRecord.self]) } }
