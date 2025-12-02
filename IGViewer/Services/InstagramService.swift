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
                    return InstagramPost(
                        id: node.id,
                        imageUrl: node.displayUrl,
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

    enum CodingKeys: String, CodingKey {
        case id
        case displayUrl = "display_url"
        case edgeMediaToCaption = "edge_media_to_caption"
        case edgeLikedBy = "edge_liked_by"
        case edgeMediaToComment = "edge_media_to_comment"
        case takenAtTimestamp = "taken_at_timestamp"
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

extension InstagramPost {
    init(id: String, imageUrl: String, caption: String?, likesCount: Int?, commentsCount: Int?, timestamp: Date?) {
        self.id = id
        self.imageUrl = imageUrl
        self.caption = caption
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.timestamp = timestamp
    }
}
