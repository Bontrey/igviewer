# IG Viewer - Instagram Photo Viewer iOS App

An iOS app that displays publicly viewable photos from any Instagram user. Simply enter a username or URL, and browse their public photos in a clean, native iOS interface.

## Features

- View public Instagram photos from any user
- Support for both usernames and Instagram URLs
- Clean, native SwiftUI interface
- Photo grid layout similar to Instagram
- Detailed photo view with captions, likes, and comments count
- Private account detection and handling
- Async image loading with caching

## Project Structure

```
IGViewer/
├── IGViewerApp.swift           # App entry point
├── ContentView.swift            # Main view controller
├── Models/
│   ├── InstagramUser.swift     # User data model
│   └── InstagramPost.swift     # Post data model
├── Services/
│   └── InstagramService.swift  # API service for fetching Instagram data
├── ViewModels/
│   └── InstagramViewModel.swift # ViewModel for managing state
├── Views/
│   ├── UserInputView.swift     # Username input screen
│   ├── PhotoGridView.swift     # Photo grid display
│   ├── PrivateAccountView.swift # Private account message
│   └── AsyncImageView.swift    # Async image loader component
└── Info.plist                   # App configuration
```

## Setup Instructions

### 1. Create a New Xcode Project

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "iOS" → "App"
4. Fill in the details:
   - Product Name: `IGViewer`
   - Team: Your development team
   - Organization Identifier: `com.yourname.igviewer`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None
5. Choose a location and create the project

### 2. Add the Source Files

1. Delete the default `ContentView.swift` and `IGViewerApp.swift` files that Xcode created
2. Copy all the Swift files from this project into your Xcode project:
   - Right-click on the project folder in Xcode
   - Select "Add Files to IGViewer"
   - Select all the `.swift` files and folders
   - Make sure "Copy items if needed" is checked
   - Click "Add"

### 3. Replace Info.plist

1. Replace the default `Info.plist` with the one provided in this project
2. Or manually add the `NSAppTransportSecurity` settings to allow Instagram API calls

### 4. Build and Run

1. Select your target device or simulator
2. Press Cmd+R to build and run
3. The app should launch and display the username input screen

## Usage

1. Launch the app
2. Enter an Instagram username or URL in one of these formats:
   - `username`
   - `@username`
   - `https://www.instagram.com/username/`
   - `https://instagram.com/username/`
3. Tap "View Photos" to fetch and display the user's public photos
4. Tap any photo to view it in detail with captions and engagement stats
5. If the account is private, you'll see a message indicating that
6. Tap "Search Another User" to search for a different account

## Requirements

- iOS 15.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later

## Important Notes

### Instagram API Limitations

This app uses Instagram's public web interface to fetch data. Please note:

- Only **public** accounts can be viewed
- Instagram may rate-limit requests
- The API endpoint (`?__a=1&__d=dis`) is unofficial and may change
- For production apps, consider using Instagram's official API

### Privacy & Terms

- This app only accesses publicly available data
- Users should respect Instagram's Terms of Service
- This is intended for educational purposes

## Troubleshooting

### "User not found" error
- Verify the username is correct
- Make sure the account exists
- Check your internet connection

### "Network error" or "Parsing error"
- Instagram may have changed their API structure
- Check if Instagram is blocking requests
- Try again after a few minutes

### Images not loading
- Verify your internet connection
- Instagram's CDN may be temporarily unavailable
- Try relaunching the app

## Future Enhancements

Possible improvements for this app:

- Add video support
- Implement proper caching for better performance
- Add support for viewing stories (requires authentication)
- Add share functionality
- Implement search history
- Add dark mode support
- Support for multiple accounts comparison

## License

This project is provided as-is for educational purposes.

## Disclaimer

This app is not affiliated with, endorsed by, or connected to Instagram or Meta Platforms, Inc. Instagram is a trademark of Meta Platforms, Inc.
