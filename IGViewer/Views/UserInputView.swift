import SwiftUI

struct UserInputView: View {
    @Binding var username: String
    let onSubmit: () -> Void

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
