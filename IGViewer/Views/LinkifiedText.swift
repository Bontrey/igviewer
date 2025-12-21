import SwiftUI
import UIKit
import Foundation

struct LinkifiedText: View {
    let text: String
    @ObservedObject var viewModel: InstagramViewModel
    @Binding var selectedUsername: String?
    @Binding var isNavigating: Bool

    var body: some View {
        LinkifiedTextRepresentable(
            text: text,
            viewModel: viewModel,
            selectedUsername: $selectedUsername,
            isNavigating: $isNavigating
        )
    }
}

private struct LinkifiedTextRepresentable: UIViewRepresentable {
    let text: String
    @ObservedObject var viewModel: InstagramViewModel
    @Binding var selectedUsername: String?
    @Binding var isNavigating: Bool

    func makeUIView(context: Context) -> SelfSizingTextView {
        let textView = SelfSizingTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: SelfSizingTextView, context: Context) {
        let attributedText = linkifyText(text)
        uiView.attributedText = attributedText
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, selectedUsername: $selectedUsername, isNavigating: $isNavigating)
    }

    private func linkifyText(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let pattern = "@([A-Za-z0-9._]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return attributedString
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            let usernameRange = match.range(at: 1)
            let username = nsString.substring(with: usernameRange)

            // Create a custom URL scheme for username links
            if let url = URL(string: "igviewer://user/\(username)") {
                attributedString.addAttribute(.link, value: url, range: match.range)
            }
        }

        return attributedString
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var viewModel: InstagramViewModel
        @Binding var selectedUsername: String?
        @Binding var isNavigating: Bool

        init(viewModel: InstagramViewModel, selectedUsername: Binding<String?>, isNavigating: Binding<Bool>) {
            self.viewModel = viewModel
            self._selectedUsername = selectedUsername
            self._isNavigating = isNavigating
        }

        @available(iOS 17.0, *)
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            if case .link(let url) = textItem.content {
                if url.scheme == "igviewer", url.host == "user" {
                    let username = url.lastPathComponent
                    selectedUsername = username

                    Task { @MainActor in
                        await viewModel.fetchUserProfile(username: username)
                        isNavigating = true
                    }

                    return nil
                }
            }
            return defaultAction
        }

        // Fallback for iOS 15-16
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            if URL.scheme == "igviewer", URL.host == "user" {
                let username = URL.lastPathComponent
                selectedUsername = username

                Task { @MainActor in
                    await viewModel.fetchUserProfile(username: username)
                    isNavigating = true
                }

                return false
            }
            return true
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
