import UIKit
import Social

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set a simple background to make the extension visible
        view.backgroundColor = .systemBackground

        // Process the shared URL
        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
           let itemProvider = extensionItem.attachments?.first {

            if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
                itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (url, error) in
                    guard let self = self, let sharedURL = url as? URL else {
                        self?.completeRequest()
                        return
                    }

                    // Extract username from Instagram URL
                    if let username = self.extractUsername(from: sharedURL) {
                        // Save to shared UserDefaults using App Group as a fallback
                        if let sharedDefaults = UserDefaults(suiteName: "group.com.igviewer.IGViewer") {
                            sharedDefaults.set(username, forKey: "pendingUsername")
                            sharedDefaults.set(Date(), forKey: "pendingUsernameTimestamp")
                            sharedDefaults.synchronize()

                            NSLog("✅ Share Extension: Saved username '\(username)' to shared storage")
                        }

                        // Open main app with custom URL scheme
                        DispatchQueue.main.async {
                            self.openMainApp(with: username)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showError()
                        }
                    }
                }
            } else {
                completeRequest()
            }
        } else {
            completeRequest()
        }
    }

    private func extractUsername(from url: URL) -> String? {
        // Handle Instagram URLs: https://www.instagram.com/username/ or https://instagram.com/username/
        if url.host?.contains("instagram.com") == true {
            let path = url.path
            let components = path.split(separator: "/")
            if let username = components.first, !username.isEmpty {
                return String(username)
            }
        }
        return nil
    }

    private func openMainApp(with username: String) {
        // Create custom URL scheme to open the main app
        let urlString = "igviewer://\(username)"

        guard let url = URL(string: urlString) else {
            NSLog("❌ Share Extension: Failed to create URL from '\(urlString)'")
            completeRequest()
            return
        }

        // Use openURL to launch the main app
        // This requires using the extensionContext's open method
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:]) { [weak self] success in
                    NSLog("✅ Share Extension: Opened main app with URL '\(urlString)', success: \(success)")
                    self?.completeRequest()
                }
                return
            }
            responder = responder?.next
        }

        // Fallback: use the modern approach with extensionContext
        // Note: This is the recommended way for share extensions
        NSLog("✅ Share Extension: Opening URL '\(urlString)' via extensionContext")
        self.extensionContext?.open(url, completionHandler: { [weak self] success in
            NSLog("✅ Share Extension: URL opened, success: \(success)")
            self?.completeRequest()
        })
    }

    private func showError() {
        let alert = UIAlertController(
            title: "Invalid URL",
            message: "Please share a valid Instagram profile URL.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.completeRequest()
        })
        present(alert, animated: true)
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
