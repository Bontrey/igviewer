import SwiftUI

@MainActor
class ViewModelCache: ObservableObject {
    private var cache: [String: InstagramViewModel] = [:]

    func getViewModel(for username: String) -> InstagramViewModel {
        let normalizedUsername = username.lowercased()
        if let existing = cache[normalizedUsername] {
            return existing
        }
        let newViewModel = InstagramViewModel()
        cache[normalizedUsername] = newViewModel
        return newViewModel
    }
}

struct ContentView: View {
    @StateObject private var viewModel = InstagramViewModel()
    @StateObject private var viewModelCache = ViewModelCache()
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
                .onAppear {
                    // Refresh lists when returning from photo view
                    viewModel.loadSavedUsers()
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
        .environmentObject(viewModelCache)
    }
}

struct PhotosDestinationView: View {
    let username: String
    @EnvironmentObject var cache: ViewModelCache

    var body: some View {
        PhotosDestinationContent(
            username: username,
            viewModel: cache.getViewModel(for: username)
        )
    }
}

private struct PhotosDestinationContent: View {
    let username: String
    @ObservedObject var viewModel: InstagramViewModel

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
                PhotoGridView(posts: viewModel.posts, username: viewModel.currentUser?.username ?? username, profilePicUrl: viewModel.currentUser?.profilePicUrl, biography: viewModel.currentUser?.biography, viewModel: viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Only fetch if we don't have data yet (i.e., first visit)
            if viewModel.currentUser == nil {
                await viewModel.fetchUserProfile(username: username)
            }
        }
    }
}
