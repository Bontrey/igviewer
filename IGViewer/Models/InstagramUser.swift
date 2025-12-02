import Foundation

struct InstagramUser: Codable, Identifiable {
    let id: String
    let username: String
    let fullName: String?
    let biography: String?
    let profilePicUrl: String?
    let isPrivate: Bool
    let followersCount: Int?
    let followingCount: Int?
    let postsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case biography
        case profilePicUrl = "profile_pic_url"
        case isPrivate = "is_private"
        case followersCount = "edge_followed_by"
        case followingCount = "edge_follow"
        case postsCount = "edge_owner_to_timeline_media"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        fullName = try? container.decode(String.self, forKey: .fullName)
        biography = try? container.decode(String.self, forKey: .biography)
        profilePicUrl = try? container.decode(String.self, forKey: .profilePicUrl)
        isPrivate = try container.decode(Bool.self, forKey: .isPrivate)

        if let followersData = try? container.decode([String: Int].self, forKey: .followersCount) {
            followersCount = followersData["count"]
        } else {
            followersCount = nil
        }

        if let followingData = try? container.decode([String: Int].self, forKey: .followingCount) {
            followingCount = followingData["count"]
        } else {
            followingCount = nil
        }

        if let postsData = try? container.decode([String: Int].self, forKey: .postsCount) {
            postsCount = postsData["count"]
        } else {
            postsCount = nil
        }
    }
}
