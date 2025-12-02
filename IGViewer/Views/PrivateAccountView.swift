import SwiftUI

struct PrivateAccountView: View {
    let username: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            Text("Private Account")
                .font(.title)
                .fontWeight(.bold)

            Text("@\(username)")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This account is private. You can only view photos from public Instagram accounts.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("To view this user's photos, they would need to accept your follow request on Instagram.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundColor(.purple)
                    Text("Private accounts protect their content from public viewers.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .padding(.top, 40)
    }
}
