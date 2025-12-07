import SwiftUI

struct PhotoGridView: View {
    let posts: [InstagramPost]
    let username: String
    let profilePicUrl: String?

    @State private var headerIsVisible: Bool = true

    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header - scrolls with content
                    HStack {
                        if let profilePicUrl = profilePicUrl,
                           let url = URL(string: profilePicUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                        }

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
                    .background(Color(UIColor.systemBackground))
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) { newValue in
                                    // Header starts around y=100 (below nav bar)
                                    // When it scrolls up past y=50, it's mostly hidden
                                    headerIsVisible = newValue > 50
                                }
                        }
                    )

                    // Photo grid
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
                                        .frame(width: (geometry.size.width - 4) / 3, height: (geometry.size.width - 4) / 3)
                                        .clipped()
                                }
                            }
                        }
                        .padding(.horizontal, 0)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !headerIsVisible {
                    Text(username)
                        .font(.headline)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: headerIsVisible)
    }
}

struct PhotoDetailView: View {
    let post: InstagramPost
    @State private var currentPage = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image carousel
                if post.imageUrls.count > 1 {
                    VStack(spacing: 8) {
                        TabView(selection: $currentPage) {
                            ForEach(Array(post.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                AsyncImageView(url: imageUrl)
                                    .aspectRatio(contentMode: .fit)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 400)

                        // Page indicator text
                        Text("\(currentPage + 1) / \(post.imageUrls.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Single image
                    AsyncImageView(url: post.imageUrl)
                        .aspectRatio(contentMode: .fit)
                }

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
