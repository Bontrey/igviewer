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
                        // Save to shared UserDefaults using App Group
                        if let sharedDefaults = UserDefaults(suiteName: "group.com.igviewer.IGViewer") {
                            sharedDefaults.set(username, forKey: "pendingUsername")
                            sharedDefaults.set(Date(), forKey: "pendingUsernameTimestamp")
                            sharedDefaults.synchronize()

                            NSLog("✅ Share Extension: Saved username '\(username)' to shared storage")
                        }

                        // Show success message
                        DispatchQueue.main.async {
                            self.showSuccessMessage(username: username)
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

    private func showSuccessMessage(username: String) {
        let alert = UIAlertController(
            title: "Saved!",
            message: "@\(username)'s profile is ready to view.\nOpen IG Viewer to continue.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.completeRequest()
        })

        present(alert, animated: true)
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
