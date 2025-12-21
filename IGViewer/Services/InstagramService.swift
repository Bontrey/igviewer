import Foundation

class InstagramService {
    static let shared = InstagramService()

    private init() {}

    func fetchUserProfile(username: String) async throws -> (user: InstagramUser, posts: [InstagramPost]) {
        let cleanUsername = username.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://www.instagram.com/", with: "")
            .replacingOccurrences(of: "https://instagram.com/", with: "")
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: "/", with: "")

        // Try the embed endpoint first - it's more reliable
        guard let url = URL(string: "https://www.instagram.com/api/v1/users/web_profile_info/?username=\(cleanUsername)") else {
            throw InstagramError.invalidUsername
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("https://www.instagram.com/\(cleanUsername)/", forHTTPHeaderField: "Referer")
        request.setValue("936619743392459", forHTTPHeaderField: "X-IG-App-ID")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InstagramError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw InstagramError.userNotFound
        }

        guard httpResponse.statusCode == 200 else {
            throw InstagramError.networkError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()

        do {
            let result = try decoder.decode(NewInstagramAPIResponse.self, from: data)

            guard let userData = result.data?.user else {
                throw InstagramError.parsingError
            }

            let user = InstagramUser(
                id: userData.id,
                username: userData.username,
                fullName: userData.fullName,
                biography: userData.biography,
                profilePicUrl: userData.profilePicUrl,
                isPrivate: userData.isPrivate,
                followersCount: userData.edgeFollowedBy?.count,
                followingCount: userData.edgeFollow?.count,
                postsCount: userData.edgeOwnerToTimelineMedia?.count
            )

            var posts: [InstagramPost] = []

            if !user.isPrivate, let edges = userData.edgeOwnerToTimelineMedia?.edges {
                posts = edges.compactMap { edge in
                    let node = edge.node

                    // Check if this is a carousel post
                    var imageUrls: [String] = []
                    if let sidecarChildren = node.edgeSidecarToChildren?.edges {
                        // Carousel post - extract all images
                        imageUrls = sidecarChildren.map { $0.node.displayUrl }
                    } else {
                        // Single image post
                        imageUrls = [node.displayUrl]
                    }

                    return InstagramPost(
                        id: node.id,
                        imageUrls: imageUrls,
                        caption: node.edgeMediaToCaption?.edges?.first?.node?.text,
                        likesCount: node.edgeLikedBy?.count,
                        commentsCount: node.edgeMediaToComment?.count,
                        timestamp: node.takenAtTimestamp != nil ? Date(timeIntervalSince1970: TimeInterval(node.takenAtTimestamp!)) : nil
                    )
                }
            }

            return (user, posts)
        } catch {
            throw InstagramError.parsingError
        }
    }
}

enum InstagramError: LocalizedError {
    case invalidUsername
    case userNotFound
    case networkError(statusCode: Int)
    case invalidResponse
    case parsingError
    case privateAccount

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Invalid Instagram username"
        case .userNotFound:
            return "User not found"
        case .networkError(let code):
            return "Network error (Status: \(code))"
        case .invalidResponse:
            return "Invalid response from Instagram"
        case .parsingError:
            return "Could not parse Instagram data"
        case .privateAccount:
            return "This account is private"
        }
    }
}

struct InstagramAPIResponse: Codable {
    let graphql: GraphQLWrapper?
}

struct NewInstagramAPIResponse: Codable {
    let data: DataWrapper?

    struct DataWrapper: Codable {
        let user: UserData?
    }
}

struct GraphQLWrapper: Codable {
    let user: UserData?
}

struct UserData: Codable {
    let id: String
    let username: String
    let fullName: String?
    let biography: String?
    let profilePicUrl: String?
    let isPrivate: Bool
    let edgeFollowedBy: EdgeCount?
    let edgeFollow: EdgeCount?
    let edgeOwnerToTimelineMedia: TimelineMedia?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case biography
        case profilePicUrl = "profile_pic_url"
        case isPrivate = "is_private"
        case edgeFollowedBy = "edge_followed_by"
        case edgeFollow = "edge_follow"
        case edgeOwnerToTimelineMedia = "edge_owner_to_timeline_media"
    }
}

struct EdgeCount: Codable {
    let count: Int
}

struct TimelineMedia: Codable {
    let count: Int
    let edges: [MediaEdge]?
}

struct MediaEdge: Codable {
    let node: MediaNode
}

struct MediaNode: Codable {
    let id: String
    let displayUrl: String
    let edgeMediaToCaption: CaptionEdge?
    let edgeLikedBy: EdgeCount?
    let edgeMediaToComment: EdgeCount?
    let takenAtTimestamp: Int?
    let edgeSidecarToChildren: SidecarEdge?  // For carousel posts

    enum CodingKeys: String, CodingKey {
        case id
        case displayUrl = "display_url"
        case edgeMediaToCaption = "edge_media_to_caption"
        case edgeLikedBy = "edge_liked_by"
        case edgeMediaToComment = "edge_media_to_comment"
        case takenAtTimestamp = "taken_at_timestamp"
        case edgeSidecarToChildren = "edge_sidecar_to_children"
    }
}

struct CaptionEdge: Codable {
    let edges: [CaptionNode]?
}

struct CaptionNode: Codable {
    let node: CaptionText?
}

struct CaptionText: Codable {
    let text: String?
}

struct SidecarEdge: Codable {
    let edges: [SidecarMediaEdge]?
}

struct SidecarMediaEdge: Codable {
    let node: SidecarMediaNode
}

struct SidecarMediaNode: Codable {
    let displayUrl: String

    enum CodingKeys: String, CodingKey {
        case displayUrl = "display_url"
    }
}

extension InstagramUser {
    init(id: String, username: String, fullName: String?, biography: String?, profilePicUrl: String?, isPrivate: Bool, followersCount: Int?, followingCount: Int?, postsCount: Int?) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.biography = biography
        self.profilePicUrl = profilePicUrl
        self.isPrivate = isPrivate
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
    }
}

class SavedUsersManager {
    static let shared = SavedUsersManager()
    private let userDefaults = UserDefaults.standard
    private let savedUsersKey = "savedInstagramUsers"

    private init() {}

    func getSavedUsers() -> [SavedUser] {
        guard let data = userDefaults.data(forKey: savedUsersKey) else {
            return []
        }

        do {
            let users = try JSONDecoder().decode([SavedUser].self, from: data)
            return users.sorted { $0.savedDate > $1.savedDate }
        } catch {
            print("Error decoding saved users: \(error)")
            return []
        }
    }

    func saveUser(_ user: InstagramUser) {
        var savedUsers = getSavedUsers()

        // Check if user already exists
        if !savedUsers.contains(where: { $0.id == user.id }) {
            let savedUser = SavedUser(from: user)
            savedUsers.append(savedUser)

            do {
                let data = try JSONEncoder().encode(savedUsers)
                userDefaults.set(data, forKey: savedUsersKey)
            } catch {
                print("Error saving user: \(error)")
            }
        }
    }

    func removeUser(withId id: String) {
        var savedUsers = getSavedUsers()
        savedUsers.removeAll { $0.id == id }

        do {
            let data = try JSONEncoder().encode(savedUsers)
            userDefaults.set(data, forKey: savedUsersKey)
        } catch {
            print("Error removing user: \(error)")
        }
    }

    func isUserSaved(_ user: InstagramUser) -> Bool {
        return getSavedUsers().contains { $0.id == user.id }
    }
}

class HistoryManager {
    static let shared = HistoryManager()
    private let userDefaults = UserDefaults.standard
    private let historyKey = "viewedUsersHistory"
    private let maxHistoryCount = 7

    private init() {}

    func getHistory(excludingSavedUsers savedUsers: [SavedUser]) -> [SavedUser] {
        guard let data = userDefaults.data(forKey: historyKey) else {
            return []
        }

        do {
            let history = try JSONDecoder().decode([SavedUser].self, from: data)
            let savedUserIds = Set(savedUsers.map { $0.id })

            // Filter out saved users and return sorted by date
            return history
                .filter { !savedUserIds.contains($0.id) }
                .sorted { $0.savedDate > $1.savedDate }
        } catch {
            print("Error decoding history: \(error)")
            return []
        }
    }

    func addToHistory(_ user: InstagramUser) {
        var history = getAllHistory()

        // Remove if already exists (to avoid duplicates and update position)
        history.removeAll { $0.id == user.id }

        // Add to the front
        let historyUser = SavedUser(from: user)
        history.insert(historyUser, at: 0)

        // Keep only the most recent 7
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }

        saveHistory(history)
    }

    private func getAllHistory() -> [SavedUser] {
        guard let data = userDefaults.data(forKey: historyKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SavedUser].self, from: data)
        } catch {
            print("Error decoding history: \(error)")
            return []
        }
    }

    private func saveHistory(_ history: [SavedUser]) {
        do {
            let data = try JSONEncoder().encode(history)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("Error saving history: \(error)")
        }
    }
}

