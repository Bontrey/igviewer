import Foundation
import SwiftUI

@MainActor
class InstagramViewModel: ObservableObject {
    @Published var currentUser: InstagramUser?
    @Published var posts: [InstagramPost] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isPrivate: Bool = false

    func fetchUserProfile(username: String) async {
        isLoading = true
        errorMessage = nil
        isPrivate = false

        do {
            let result = try await InstagramService.shared.fetchUserProfile(username: username)
            currentUser = result.user
            posts = result.posts
            isPrivate = result.user.isPrivate
        } catch let error as InstagramError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func reset() {
        currentUser = nil
        posts = []
        errorMessage = nil
        isPrivate = false
    }
}
