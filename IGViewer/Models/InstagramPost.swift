import Foundation

struct InstagramPost: Codable, Identifiable {
    let id: String
    let imageUrls: [String]  // Changed to array to support carousels
    let caption: String?
    let likesCount: Int?
    let commentsCount: Int?
    let timestamp: Date?

    // Convenience property for backward compatibility
    var imageUrl: String {
        return imageUrls.first ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id
        case imageUrls
        case caption
        case likesCount = "edge_liked_by"
        case commentsCount = "edge_media_to_comment"
        case timestamp = "taken_at_timestamp"
    }
}
