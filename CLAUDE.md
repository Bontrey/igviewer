# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run

```bash
# Build for simulator
xcodebuild -project IGViewer.xcodeproj -scheme IGViewer -destination 'platform=iOS Simulator,name=iPhone 17' build

# Launch on simulator (boot simulator first if needed)
xcrun simctl boot "778F760E-81A7-4AB6-88D9-B390108C3326"  # iPhone 17 UUID
open -a Simulator
xcrun simctl install "778F760E-81A7-4AB6-88D9-B390108C3326" "/path/to/DerivedData/.../IGViewer.app"
xcrun simctl launch "778F760E-81A7-4AB6-88D9-B390108C3326" com.igviewer.IGViewer

# Or use Xcode: Cmd+R to build and run
```

## Architecture Overview

This is a SwiftUI iOS app following MVVM architecture that fetches and displays public Instagram profile photos.

### Data Flow
1. **User Input** → `UserInputView` accepts username/URL
2. **ContentView** coordinates UI state via `@StateObject` binding to `InstagramViewModel`
3. **ViewModel** (`InstagramViewModel`) manages async fetch via `InstagramService.shared.fetchUserProfile()`
4. **Service Layer** (`InstagramService`) makes HTTP requests to Instagram's web API endpoint
5. **Models** (`InstagramUser`, `InstagramPost`) parse JSON responses
6. **Views** display results: `PhotoGridView` for public photos, `PrivateAccountView` for private accounts

### Critical Instagram API Details

**Current Endpoint**: `https://www.instagram.com/api/v1/users/web_profile_info/?username={username}`

**Required Headers** (InstagramService.swift:20-26):
- `User-Agent`: Mobile Safari user agent
- `X-IG-App-ID`: `936619743392459` (Instagram's app ID, may need updating)
- `Referer`: User's profile URL
- `Accept`: `application/json`

**Response Structure**: The API returns `NewInstagramAPIResponse` with structure:
```
data.user.{id, username, isPrivate, edgeOwnerToTimelineMedia.edges[].node.{displayUrl, ...}}
```

**Known Issues**:
- Instagram frequently changes web API endpoints and structure
- Status codes may vary (currently accepts 200)
- Rate limiting may occur without warning
- The `X-IG-App-ID` may expire and need updating from Instagram's web source

### State Management

`ContentView` conditionally renders based on `InstagramViewModel` state:
- `currentUser == nil` → Show `UserInputView`
- `isPrivate == true` → Show `PrivateAccountView`
- `posts.count > 0` → Show `PhotoGridView` with 3-column grid
- `isLoading == true` → Show loading spinner
- `errorMessage != nil` → Display error text

The ViewModel uses `@MainActor` to ensure UI updates happen on main thread.

### Username Parsing

`InstagramService.fetchUserProfile()` normalizes input by stripping:
- URL schemes (`https://www.instagram.com/`, `https://instagram.com/`)
- `@` prefix
- Trailing slashes

This allows flexible input: `@username`, `username`, or full URLs.

## Troubleshooting Instagram API Changes

When Instagram API breaks:

1. **Check response structure**: Add debug logging in `InstagramService.swift:45` to print raw JSON
2. **Update X-IG-App-ID**: Inspect network requests on instagram.com (browser DevTools) for current value
3. **Try alternative endpoints**: Instagram has multiple endpoints:
   - `/api/v1/users/web_profile_info/` (current)
   - `/?__a=1&__d=dis` (deprecated)
   - HTML scraping as last resort
4. **Add response models**: Create new `Codable` structs matching Instagram's response format in `InstagramService.swift`

## Key Files

- **IGViewer/Services/InstagramService.swift**: All Instagram API interaction, HTTP headers, response parsing
- **IGViewer/ViewModels/InstagramViewModel.swift**: UI state management, loading/error states
- **IGViewer/ContentView.swift**: Root view that orchestrates all UI states
- **IGViewer/Models/**: Data models with custom `Codable` init for Instagram's nested JSON structure

## Requirements

- iOS 15.0+ (deployment target)
- Swift 5.0+
- SwiftUI framework
- `Info.plist` must include `NSAppTransportSecurity` settings (already configured)
