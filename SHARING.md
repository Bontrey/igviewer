# Sharing Instagram Profiles to IGViewer

## Using the Custom URL Scheme

IGViewer supports the `igviewer://` custom URL scheme. You can open Instagram profiles directly using:

```
igviewer://username
```

For example: `igviewer://aka_sk8simon`

## Setting Up an iOS Shortcut for Easy Sharing

Since iOS doesn't allow apps to claim other domains (like instagram.com) for Universal Links, the best way to share Instagram URLs from Safari or other apps is to create an iOS Shortcut.

### Step-by-Step Instructions:

1. **Open the Shortcuts app** on your iPhone

2. **Create a new Shortcut:**
   - Tap the "+" button
   - Search for and add the "Receive URLs from Share Sheet" action
   - This allows the shortcut to receive URLs when you tap Share

3. **Add URL processing:**
   - Add the "Get Component from URL" action
   - Set it to get the "Path"
   - This extracts the username from the Instagram URL

4. **Build the custom URL:**
   - Add the "Text" action
   - Enter: `igviewer://{Component from URL}`
   - Tap on "Component from URL" to insert it as a variable

5. **Open the URL:**
   - Add the "Open URLs" action
   - Set the input to the text you just created

6. **Name your Shortcut:**
   - Tap the icon at the top
   - Rename it to "Open in IG Viewer"
   - Tap "Done"

### Alternative Simpler Version:

1. **Open Shortcuts app**
2. **Create new shortcut**
3. Add these actions in order:
   - "Receive URLs from Share Sheet"
   - "Replace Text" (Find: `https://www.instagram.com/` | Replace with: `igviewer://`)
   - "Replace Text" (Find: `https://instagram.com/` | Replace with: `igviewer://`)
   - "Replace Text" (Find: `/` at the end | Replace with: empty)
   - "Open URLs"

### How to Use:

1. In Safari or Instagram web, navigate to a profile page
2. Tap the Share button
3. Scroll down and select "Open in IG Viewer" (your shortcut)
4. The IGViewer app will open automatically with that profile loaded

## Testing the URL Scheme (Simulator)

If you're testing on the simulator, you can use this command:

```bash
xcrun simctl openurl <device-id> "igviewer://username"
```

For example:
```bash
xcrun simctl openurl "778F760E-81A7-4AB6-88D9-B390108C3326" "igviewer://aka_sk8simon"
```

## Note on Share Sheet Integration

To make the app appear directly in Safari's share sheet without a Shortcut, you would need to implement a **Share Extension**, which is a more complex feature requiring an app extension target in Xcode. The Shortcut approach is simpler and works well for personal use.
