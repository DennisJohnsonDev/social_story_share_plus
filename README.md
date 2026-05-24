# social_story_share_plus

A Flutter plugin to share images and stickers directly to **Instagram Stories**,
**Instagram Direct**, **Facebook Stories**, **WhatsApp Status**, and save media
to the device gallery.

| Platform | Support |
| -------- | ------- |
| Android  | ✅ (API 21+) |
| iOS      | ✅ (iOS 12+) |

## Features

- Share a sticker + background (image or gradient) to **Instagram Stories**
- Share text to **Instagram Direct** (with clipboard fallback on iOS)
- Share a sticker + background to **Facebook Stories**
- Share an image to **WhatsApp Status**
- Save an in-memory image to the device gallery
- Check whether Instagram, Facebook, or WhatsApp are installed

## Installation

Add the dependency:

```yaml
dependencies:
  social_story_share_plus: ^0.0.1
```

Then:

```sh
flutter pub get
```

## Platform setup

### iOS

Add the following to your app's `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>instagram-stories</string>
    <string>facebook-stories</string>
    <string>whatsapp</string>
</array>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to your photo library to save shared images.</string>
```

`LSApplicationQueriesSchemes` is required for the `isXInstalled` checks and
for opening each app via URL scheme. `NSPhotoLibraryAddUsageDescription` is
required for `saveToGallery`.

### Android

#### 1. FileProvider

The plugin shares images using `FileProvider`. Declare it in your
`android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

Then create `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <cache-path name="cache" path="." />
    <files-path name="files" path="." />
    <external-files-path name="external_files" path="." />
    <external-cache-path name="external_cache" path="." />
    <external-path name="external" path="." />
</paths>
```

#### 2. Package visibility (Android 11+)

Package visibility queries for Instagram, Facebook, and WhatsApp are merged in
automatically from the plugin's manifest — you don't need to add them yourself.

## Usage

```dart
import 'package:social_story_share_plus/social_story_share_plus.dart';
```

### Instagram Stories

```dart
await SocialStorySharePlus.shareToInstagramStories(
  stickerPath: '/path/to/sticker.png',
  // Optional gradient background (used if no backgroundImagePath is supplied):
  backgroundTopColor: '#7B61FF',
  backgroundBottomColor: '#FF61D2',
  // Or use a background image:
  // backgroundImagePath: '/path/to/background.png',
);
```

### Instagram Direct

```dart
await SocialStorySharePlus.shareToInstagramDirect(
  text: 'Check out this cool thing!',
);
```

### Facebook Stories

> **Facebook App ID is required.** You must register your app at
> [developers.facebook.com](https://developers.facebook.com/) and pass the
> resulting App ID. Without it, the share will be rejected.

```dart
await SocialStorySharePlus.shareToFacebookStories(
  stickerPath: '/path/to/sticker.png',
  appId: 'YOUR_FACEBOOK_APP_ID',
  backgroundTopColor: '#7B61FF',
  backgroundBottomColor: '#FF61D2',
);
```

### WhatsApp Status

```dart
await SocialStorySharePlus.shareToWhatsAppStatus(
  imagePath: '/path/to/image.png',
);
```

### Save to gallery

```dart
final Uint8List bytes = await renderImage();
await SocialStorySharePlus.saveToGallery(
  imageBytes: bytes,
  fileName: 'my_image.png',
);
```

### Installed checks

```dart
final hasIg = await SocialStorySharePlus.isInstagramInstalled();
final hasFb = await SocialStorySharePlus.isFacebookInstalled();
final hasWa = await SocialStorySharePlus.isWhatsAppInstalled();
```

## Example

See the [`example/`](./example) directory for a complete runnable demo.

## License

See [LICENSE](./LICENSE).
