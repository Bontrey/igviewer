import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = InstagramViewModel()
    @State private var username: String = ""
    @Binding var deepLinkUsername: String?

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.currentUser == nil {
                    UserInputView(username: $username, onSubmit: {
                        Task {
                            await viewModel.fetchUserProfile(username: username)
                        }
                    })
                } else {
                    if viewModel.isPrivate {
                        PrivateAccountView(username: viewModel.currentUser?.username ?? username)
                    } else {
                        PhotoGridView(posts: viewModel.posts, username: viewModel.currentUser?.username ?? username)
                    }

                    Button("Search Another User") {
                        viewModel.reset()
                        username = ""
                    }
                    .padding()
                }

                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("IG Viewer")
            .onChange(of: deepLinkUsername) { newValue in
                if let username = newValue {
                    self.username = username
                    Task {
                        await viewModel.fetchUserProfile(username: username)
                    }
                    // Clear the deep link after processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        deepLinkUsername = nil
                    }
                }
            }
        }
    }
}
