# Share Extension Setup Instructions

I've created all the necessary files for the Share Extension. Now you need to add the Share Extension target in Xcode. Follow these steps:

## Step 1: Open Project in Xcode

```bash
open IGViewer.xcodeproj
```

## Step 2: Add Share Extension Target

1. In Xcode, click on the **IGViewer** project in the navigator (blue icon at the top)
2. At the bottom of the targets list, click the **"+"** button
3. Search for **"Share Extension"**
4. Select **"Share Extension"** and click **Next**
5. Configure the extension:
   - **Product Name**: `IGViewerShareExtension`
   - **Team**: Select your development team
   - **Language**: Swift
   - **Project**: IGViewer
   - **Embed in Application**: IGViewer
6. Click **Finish**
7. When prompted "Activate IGViewerShareExtension scheme?", click **Cancel** (we'll use the main app scheme)

## Step 3: Replace Generated Files

Xcode will generate some default files. We need to replace them with our custom files:

1. In the Project Navigator, **delete** these generated files from the `IGViewerShareExtension` folder:
   - `ShareViewController.swift` (select "Move to Trash")
   - `Info.plist` (select "Move to Trash")

2. **Add our custom files**:
   - Right-click on the `IGViewerShareExtension` folder
   - Select **"Add Files to IGViewer..."**
   - Navigate to the `IGViewerShareExtension` folder in your project directory
   - Select these files:
     - `ShareViewController.swift`
     - `Info.plist`
   - Make sure **"Copy items if needed"** is UNCHECKED
   - Under **"Add to targets"**, check ONLY **IGViewerShareExtension**
   - Click **Add**

## Step 4: Add Entitlements Files

### For Main App:
1. Select the **IGViewer** target (main app)
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"**
4. Search for and add **"App Groups"**
5. Click the **"+"** under App Groups
6. Enter: `group.com.igviewer.IGViewer`
7. Click **OK**

### For Share Extension:
1. Select the **IGViewerShareExtension** target
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"**
4. Search for and add **"App Groups"**
5. Click the **"+"** under App Groups
6. Enter: `group.com.igviewer.IGViewer` (same as main app)
7. Click **OK**

## Step 5: Update Bundle Identifiers

1. Select the **IGViewerShareExtension** target
2. Go to **"General"** tab
3. Under **"Identity"**, set **Bundle Identifier** to: `com.igviewer.IGViewer.IGViewerShareExtension`

## Step 6: Set Deployment Target

1. Select the **IGViewerShareExtension** target
2. Go to **"General"** tab
3. Under **"Minimum Deployments"**, set **iOS** to: `15.0` (same as main app)

## Step 7: Build and Run

1. Select the **IGViewer** scheme (not the extension scheme)
2. Select your simulator or device
3. Press **Cmd+B** to build
4. If build succeeds, press **Cmd+R** to run

## Step 8: Test the Share Extension

1. Open **Safari** on your simulator/device
2. Navigate to an Instagram profile (e.g., `https://www.instagram.com/aka_sk8simon/`)
3. Tap the **Share button** (square with arrow)
4. Scroll down and you should see **"IGViewerShareExtension"** in the list
5. Tap it - it should open the IGViewer app and load that profile automatically

## Troubleshooting

### Share Extension doesn't appear in share sheet:
- Make sure both targets have the App Groups capability enabled
- Verify both use the same App Group identifier: `group.com.igviewer.IGViewer`
- Clean build folder (Cmd+Shift+K) and rebuild

### App doesn't open after sharing:
- Check that the custom URL scheme `igviewer` is still in the main app's Info.plist
- Verify the URL scheme is registered under the main app target

### Build errors:
- Make sure `ShareViewController.swift` is only added to the **IGViewerShareExtension** target
- Make sure the main app files are not added to the extension target
- Check that both entitlements files are properly configured

## What Happens When You Share

1. User taps Share on an Instagram URL in Safari
2. Share Extension appears in the share sheet
3. User taps "IGViewerShareExtension"
4. Extension extracts username from the URL
5. Extension saves username to shared UserDefaults (via App Group)
6. Extension opens main app using `igviewer://open`
7. Main app checks shared UserDefaults and finds the username
8. Main app automatically loads that user's profile

## Notes

- The Share Extension will appear as "IGViewerShareExtension" in the share sheet
- To customize the display name, edit the `CFBundleDisplayName` in the extension's Info.plist
- You can change it to something shorter like "IG Viewer" or "View in IGViewer"
