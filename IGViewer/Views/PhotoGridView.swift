import SwiftUI

struct PhotoGridView: View {
    let posts: [InstagramPost]
    let username: String

    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading) {
                        Text("@\(username)")
                            .font(.headline)
                        Text("\(posts.count) photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()

                if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No photos available")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("This user hasn't posted any public photos yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(posts) { post in
                            NavigationLink(destination: PhotoDetailView(post: post)) {
                                AsyncImageView(url: post.imageUrl)
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PhotoDetailView: View {
    let post: InstagramPost

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImageView(url: post.imageUrl)
                    .aspectRatio(contentMode: .fit)

                if let caption = post.caption, !caption.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.headline)
                        Text(caption)
                            .font(.body)
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 24) {
                    if let likes = post.likesCount {
                        Label("\(likes)", systemImage: "heart.fill")
                            .foregroundColor(.red)
                    }

                    if let comments = post.commentsCount {
                        Label("\(comments)", systemImage: "message.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                if let timestamp = post.timestamp {
                    Text(timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                Spacer()
            }
        }
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
    }
}
