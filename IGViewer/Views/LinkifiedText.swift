import SwiftUI
import UIKit
import Foundation
import SafariServices

// Make URL identifiable for .sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String {
        return absoluteString
    }
}

struct LinkifiedText: View {
    let text: String
    @Binding var selectedUsername: String?
    @Binding var isNavigating: Bool
    @State private var urlToOpen: URL?

    var body: some View {
        LinkifiedTextRepresentable(
            text: text,
            selectedUsername: $selectedUsername,
            isNavigating: $isNavigating,
            urlToOpen: $urlToOpen
        )
        .sheet(item: $urlToOpen) { url in
            SafariView(url: url)
        }
    }
}

// SafariView wrapper for SwiftUI
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

private struct LinkifiedTextRepresentable: UIViewRepresentable {
    let text: String
    @Binding var selectedUsername: String?
    @Binding var isNavigating: Bool
    @Binding var urlToOpen: URL?

    func makeUIView(context: Context) -> SelfSizingTextView {
        let textView = SelfSizingTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = false // Disable to prevent highlight overlay
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.font = .systemFont(ofSize: 18)
        textView.textColor = .label
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.dataDetectorTypes = [] // Disable data detectors to prevent interference
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // Add custom tap gesture recognizer to handle link taps
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        textView.addGestureRecognizer(tapGesture)

        return textView
    }

    func updateUIView(_ uiView: SelfSizingTextView, context: Context) {
        let attributedText = linkifyText(text)
        uiView.attributedText = attributedText
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            selectedUsername: $selectedUsername,
            isNavigating: $isNavigating,
            urlToOpen: $urlToOpen
        )
    }

    private func linkifyText(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)

        // Set font and color for the entire text
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 18), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)

        let nsString = text as NSString

        // 1. Linkify @mentions
        // Negative lookbehind to avoid matching email addresses (e.g., user@example.com)
        let mentionPattern = "(?<![A-Za-z0-9.])@([A-Za-z0-9._]+)"

        if let mentionRegex = try? NSRegularExpression(pattern: mentionPattern, options: []) {
            let matches = mentionRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let usernameRange = match.range(at: 1)
                let username = nsString.substring(with: usernameRange)

                // Create a custom URL scheme for username links
                if let url = URL(string: "igviewer://user/\(username)") {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                }
            }
        }

        // 2. Linkify URLs (with or without scheme)
        // Pattern matches:
        // - URLs with http:// or https://
        // - URLs starting with www.
        // - Domain-like patterns (e.g., example.com, sub.example.com/path)
        let urlPattern = "(?i)\\b(?:(?:https?://)|(?:www\\.))(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2,}(?:[/?#][^\\s]*)?|\\b(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2,}(?:/[^\\s]*)?"

        if let urlRegex = try? NSRegularExpression(pattern: urlPattern, options: []) {
            let matches = urlRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let urlString = nsString.substring(with: match.range)

                // Skip if this is part of an email address
                if match.range.location > 0 {
                    let previousChar = nsString.substring(with: NSRange(location: match.range.location - 1, length: 1))
                    if previousChar == "@" {
                        continue
                    }
                }

                // Add scheme if missing
                var fullURLString = urlString
                if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
                    fullURLString = "https://\(urlString)"
                }

                if let url = URL(string: fullURLString) {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                }
            }
        }

        return attributedString
    }

    class Coordinator: NSObject {
        @Binding var selectedUsername: String?
        @Binding var isNavigating: Bool
        @Binding var urlToOpen: URL?

        init(selectedUsername: Binding<String?>, isNavigating: Binding<Bool>, urlToOpen: Binding<URL?>) {
            self._selectedUsername = selectedUsername
            self._isNavigating = isNavigating
            self._urlToOpen = urlToOpen
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView,
                  let attributedText = textView.attributedText else {
                return
            }

            let location = gesture.location(in: textView)
            let textContainer = textView.textContainer
            let layoutManager = textView.layoutManager

            // Convert tap location to text index
            let characterIndex = layoutManager.characterIndex(
                for: location,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            // Check if tapped on a link
            if characterIndex < attributedText.length,
               let url = attributedText.attribute(.link, at: characterIndex, effectiveRange: nil) as? URL {

                // Handle @mentions with custom scheme
                if url.scheme == "igviewer", url.host == "user" {
                    let username = url.lastPathComponent
                    selectedUsername = username
                    isNavigating = true
                    return
                }

                // Handle regular URLs - open in SafariView
                if url.scheme == "http" || url.scheme == "https" {
                    DispatchQueue.main.async {
                        self.urlToOpen = url
                    }
                    return
                }
            }
        }
    }
}

// Custom UITextView that properly sizes itself
class SelfSizingTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}
