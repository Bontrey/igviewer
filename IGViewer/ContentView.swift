import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = InstagramViewModel()
    @State private var username: String = ""
    @Binding var deepLinkUsername: String?

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.currentUser == nil {
                    UserInputView(
                        username: $username,
                        savedUsers: viewModel.savedUsers,
                        onSubmit: {
                            Task {
                                await viewModel.fetchUserProfile(username: username)
                            }
                        },
                        onSelectSavedUser: { selectedUsername in
                            username = selectedUsername
                            Task {
                                await viewModel.fetchUserProfile(username: selectedUsername)
                            }
                        }
                    )
                } else {
                    if viewModel.isPrivate {
                        PrivateAccountView(username: viewModel.currentUser?.username ?? username)
                    } else {
                        PhotoGridView(posts: viewModel.posts, username: viewModel.currentUser?.username ?? username)
                    }

                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.toggleSaveUser()
                        }) {
                            HStack {
                                Image(systemName: viewModel.isCurrentUserSaved ? "star.fill" : "star")
                                Text(viewModel.isCurrentUserSaved ? "Saved" : "Save User")
                            }
                            .foregroundColor(viewModel.isCurrentUserSaved ? .yellow : .purple)
                        }

                        Button("Search Another User") {
                            viewModel.reset()
                            username = ""
                        }
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
