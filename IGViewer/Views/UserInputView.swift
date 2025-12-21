import SwiftUI

struct UserInputView: View {
    @Binding var username: String
    let savedUsers: [SavedUser]
    let history: [SavedUser]
    let onSubmit: () -> Void
    let onSelectSavedUser: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.purple)
                .padding(.top, 40)

            Text("Instagram Viewer")
                .font(.title)
                .fontWeight(.bold)

            Text("Enter an Instagram username or URL to view public photos")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Saved users section
            if !savedUsers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved Users")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(savedUsers) { savedUser in
                                SavedUserButton(savedUser: savedUser) {
                                    onSelectSavedUser(savedUser.username)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // History section
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recently Viewed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(history) { historyUser in
                                SavedUserButton(savedUser: historyUser) {
                                    onSelectSavedUser(historyUser.username)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("Username or URL", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                    .onSubmit {
                        if !username.isEmpty {
                            onSubmit()
                        }
                    }

                Text("Examples: @username, username, or instagram.com/username")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Button(action: {
                if !username.isEmpty {
                    onSubmit()
                }
            }) {
                Text("View Photos")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(username.isEmpty ? Color.gray : Color.purple)
                    .cornerRadius(10)
            }
            .disabled(username.isEmpty)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct SavedUserButton: View {
    let savedUser: SavedUser
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 6) {
                if let profilePicUrl = savedUser.profilePicUrl,
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
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 60, height: 60)
                }

                Text(savedUser.username)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
