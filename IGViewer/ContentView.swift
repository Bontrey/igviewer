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

                NavigationLink(destination: PhotosDestinationView(viewModel: viewModel, username: username), isActive: $navigateToPhotos) {
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
    @ObservedObject var viewModel: InstagramViewModel
    let username: String

    var body: some View {
        VStack {
            if viewModel.isPrivate {
                PrivateAccountView(username: viewModel.currentUser?.username ?? username)
            } else {
                PhotoGridView(posts: viewModel.posts, username: viewModel.currentUser?.username ?? username, profilePicUrl: viewModel.currentUser?.profilePicUrl, viewModel: viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
