import Foundation

struct InstagramPost: Codable, Identifiable {
    let id: String
    let imageUrl: String
    let caption: String?
    let likesCount: Int?
    let commentsCount: Int?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "display_url"
        case caption
        case likesCount = "edge_liked_by"
        case commentsCount = "edge_media_to_comment"
        case timestamp = "taken_at_timestamp"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)

        if let edges = try? container.decode([String: [String: String]].self, forKey: .caption),
           let text = edges["edges"]?["text"] {
            caption = text
        } else {
            caption = nil
        }

        if let likesData = try? container.decode([String: Int].self, forKey: .likesCount) {
            likesCount = likesData["count"]
        } else {
            likesCount = nil
        }

        if let commentsData = try? container.decode([String: Int].self, forKey: .commentsCount) {
            commentsCount = commentsData["count"]
        } else {
            commentsCount = nil
        }

        if let timestampValue = try? container.decode(TimeInterval.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: timestampValue)
        } else {
            timestamp = nil
        }
    }
}
