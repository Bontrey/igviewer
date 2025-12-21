import Foundation
import SwiftUI

@MainActor
class InstagramViewModel: ObservableObject {
    @Published var currentUser: InstagramUser?
    @Published var posts: [InstagramPost] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isPrivate: Bool = false
    @Published var savedUsers: [SavedUser] = []
    @Published var history: [SavedUser] = []
    @Published var isCurrentUserSaved: Bool = false

    init() {
        loadSavedUsers()
        loadHistory()
    }

    func loadSavedUsers() {
        savedUsers = SavedUsersManager.shared.getSavedUsers()
        loadHistory() // Reload history to filter out saved users
    }

    func loadHistory() {
        history = HistoryManager.shared.getHistory(excludingSavedUsers: savedUsers)
    }

    func fetchUserProfile(username: String) async {
        isLoading = true
        errorMessage = nil
        isPrivate = false

        do {
            let result = try await InstagramService.shared.fetchUserProfile(username: username)
            currentUser = result.user
            posts = result.posts
            isPrivate = result.user.isPrivate
            updateSavedStatus()

            // Add to history
            HistoryManager.shared.addToHistory(result.user)
            loadHistory()
        } catch let error as InstagramError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func toggleSaveUser() {
        guard let user = currentUser else { return }

        if isCurrentUserSaved {
            SavedUsersManager.shared.removeUser(withId: user.id)
        } else {
            SavedUsersManager.shared.saveUser(user)
        }

        loadSavedUsers()
        updateSavedStatus()
    }

    private func updateSavedStatus() {
        if let user = currentUser {
            isCurrentUserSaved = SavedUsersManager.shared.isUserSaved(user)
        } else {
            isCurrentUserSaved = false
        }
    }

    func reset() {
        currentUser = nil
        posts = []
        errorMessage = nil
        isPrivate = false
        isCurrentUserSaved = false
        loadSavedUsers()
        loadHistory()
    }
}
