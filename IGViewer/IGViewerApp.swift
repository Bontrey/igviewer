import SwiftUI

@main
struct IGViewerApp: App {
    @State private var deepLinkUsername: String?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkUsername: $deepLinkUsername)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
                .onAppear {
                    checkForSharedUsername()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                checkForSharedUsername()
            }
        }
    }

    private func handleDeepLink(url: URL) {
        // Handle custom scheme: igviewer://username or igviewer:///username
        // Also used by Share Extension to trigger opening the app

        if url.scheme == "igviewer" {
            // Check for shared username from Share Extension
            checkForSharedUsername()

            // Try host first (igviewer://username)
            if let host = url.host, !host.isEmpty, host != "open" {
                deepLinkUsername = host
            } else {
                // Try path if no host (igviewer:///username or igviewer://username/ style)
                let path = url.path
                let username = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if !username.isEmpty {
                    deepLinkUsername = username
                }
            }
        }
    }

    private func checkForSharedUsername() {
        // Check if Share Extension has shared a username via App Group
        if let sharedDefaults = UserDefaults(suiteName: "group.com.igviewer.IGViewer"),
           let username = sharedDefaults.string(forKey: "pendingUsername"),
           let timestamp = sharedDefaults.object(forKey: "pendingUsernameTimestamp") as? Date {

            // Only process if it's recent (within last 10 seconds)
            if Date().timeIntervalSince(timestamp) < 10 {
                deepLinkUsername = username

                // Clear the shared data
                sharedDefaults.removeObject(forKey: "pendingUsername")
                sharedDefaults.removeObject(forKey: "pendingUsernameTimestamp")
                sharedDefaults.synchronize()
            }
        }
    }
}
