import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = InstagramViewModel()
    @State private var username: String = ""
    @Binding var deepLinkUsername: String?
    @State private var navigateToPhotos = false

    var body: some View {
        NavigationView {
            VStack {
                UserInputView(
                    username: $username,
                    savedUsers: viewModel.savedUsers,
                    history: viewModel.history,
                    onSubmit: {
                        Task {
                            await viewModel.fetchUserProfile(username: username)
                            if viewModel.currentUser != nil {
                                navigateToPhotos = true
                            }
                        }
                    },
                    onSelectSavedUser: { selectedUsername in
                        username = selectedUsername
                        Task {
                            await viewModel.fetchUserProfile(username: selectedUsername)
                            if viewModel.currentUser != nil {
                                navigateToPhotos = true
                            }
                        }
                    }
                )

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

                NavigationLink(destination: PhotosDestinationView(username: username), isActive: $navigateToPhotos) {
                    EmptyView()
                }
            }
            .onChange(of: deepLinkUsername) { newValue in
                if let username = newValue {
                    self.username = username
                    Task {
                        await viewModel.fetchUserProfile(username: username)
                        if viewModel.currentUser != nil {
                            navigateToPhotos = true
                        }
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

struct PhotosDestinationView: View {
    let username: String
    @StateObject private var viewModel = InstagramViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if viewModel.isPrivate {
                PrivateAccountView(username: viewModel.currentUser?.username ?? username)
            } else {
                PhotoGridView(posts: viewModel.posts, username: viewModel.currentUser?.username ?? username, profilePicUrl: viewModel.currentUser?.profilePicUrl, viewModel: viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserProfile(username: username)
        }
    }
}
