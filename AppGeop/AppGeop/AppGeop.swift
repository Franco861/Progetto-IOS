import SwiftUI
import SwiftData

@main
struct AppGeopApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: UserProfile.self)
    }
}
