import SwiftUI

@main
struct SipApp: App {
    // This connects our AppDelegate to the SwiftUI app lifecycle
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use a dummy Settings scene just to satisfy SwiftUI since our actual window
        // is custom built in AppDelegate
        Settings { 
            EmptyView()
        }
    }
}
