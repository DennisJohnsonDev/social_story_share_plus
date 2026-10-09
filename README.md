# social_story_share_plus

Share images to **Instagram Stories**, **Facebook Stories** and **WhatsApp Status**, send text to **Instagram Direct** and save images to the **photo gallery**, all from Flutter.

| Feature | Android | iOS |
| --- | :---: | :---: |
| Instagram Stories (sticker, background image or gradient) | ✅ | ✅ |
| Facebook Stories (sticker, background image or gradient) | ✅ | ✅ |
| WhatsApp Status | ✅ | ✅ |
| Instagram Direct (text) | ✅ | ✅ |
| Save to gallery | ✅ | ✅ |
| Check if Instagram / Facebook / WhatsApp is installed | ✅ | ✅ |

## Installation

```bash
flutter pub add social_story_share_plus
```

### Facebook App ID

Instagram and Facebook Stories require a [Facebook App ID](https://developers.facebook.com/docs/development/create-an-app/) to attribute shares to your app. Pass it as `appId` to the story methods. No other Facebook SDK setup is needed.

### iOS

Add the schemes you use to `ios/Runner/Info.plist`, so the plugin can check for and open the apps, along with the photo library descriptions if you save images:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>instagram-stories</string>
    <string>facebook-stories</string>
    <string>whatsapp</string>
</array>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Saves shared images to your photo library.</string>
<!-- Only needed when supporting iOS 13. -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Saves shared images to your photo library.</string>
```

Apps using the UIScene lifecycle are fully supported.

### Android

No setup is needed. The plugin brings its own `FileProvider`, declares the package visibility `<queries>` for Instagram, Facebook and WhatsApp, and declares `WRITE_EXTERNAL_STORAGE` for Android 9 and lower only, which is asked for at runtime when saving to the gallery.

## Usage

```dart
import 'package:social_story_share_plus/social_story_share_plus.dart';
```

All images are passed as local file paths. A common pattern is to render a widget or download an image, then write it to `getTemporaryDirectory()` from [`path_provider`](https://pub.dev/packages/path_provider).

### Instagram Stories

```dart
await SocialStorySharePlus.shareToInstagramStories(
  appId: 'YOUR_FACEBOOK_APP_ID',
  stickerPath: stickerFile.path,
  backgroundImagePath: backgroundFile.path,
);
```

Pass a `stickerPath`, a `backgroundImagePath`, or both. The sticker stays movable in the story editor. Without a background image, the story is filled with a gradient:

```dart
await SocialStorySharePlus.shareToInstagramStories(
  appId: 'YOUR_FACEBOOK_APP_ID',
  stickerPath: stickerFile.path,
  backgroundTopColor: Colors.indigo,
  backgroundBottomColor: Colors.pink,
);
```

### Facebook Stories

Same arguments as Instagram Stories:

```dart
await SocialStorySharePlus.shareToFacebookStories(
  appId: 'YOUR_FACEBOOK_APP_ID',
  stickerPath: stickerFile.path,
  backgroundTopColor: Colors.black,
  backgroundBottomColor: Colors.black,
);
```

### WhatsApp Status

```dart
await SocialStorySharePlus.shareToWhatsAppStatus(imagePath: posterFile.path);
```

### Instagram Direct

```dart
await SocialStorySharePlus.shareToInstagramDirect(text: 'See you there!');
```

### Save to gallery

```dart
await SocialStorySharePlus.saveToGallery(
  imageBytes: pngBytes,
  fileName: 'my_story',
  albumName: 'My App', // Android only
);
```

The bytes are stored exactly as given, and the file extension follows the image format.

### Check installed apps

```dart
final canShare = await SocialStorySharePlus.isInstagramInstalled();
```

`isFacebookInstalled()` and `isWhatsAppInstalled()` work the same way.

## Results and errors

Every share method returns a `Future<bool>`:

* `true` means the content was handed to the target app.
* `false` means the target app could not be opened.

Anything else throws a `SocialStoryShareException` with a `code` you can switch on:

```dart
try {
  await SocialStorySharePlus.shareToWhatsAppStatus(imagePath: path);
} on SocialStoryShareException catch (e) {
  switch (e.code) {
    case SocialStoryShareErrorCode.appNotInstalled:
      showMessage('WhatsApp is not installed');
    case SocialStoryShareErrorCode.permissionDenied:
      showMessage('Allow photo access in Settings');
    default:
      showMessage('Could not share: ${e.message}');
  }
}
```

| Code | Meaning |
| --- | --- |
| `appNotInstalled` | The target app is missing, or on iOS its scheme is not in `LSApplicationQueriesSchemes`. |
| `fileNotFound` | An image path does not exist. |
| `invalidImage` | A file or byte buffer is not a readable image. |
| `invalidArgument` | The platform rejected the arguments. |
| `uiUnavailable` | There is no foreground activity or view controller to share from. |
| `permissionDenied` | Photo library or storage permission was refused. |
| `failed` | Any other platform error; see `message`. |

Invalid arguments caught in Dart, such as an empty `appId` or a story with neither a sticker nor a background, throw an `ArgumentError` before reaching the platform.

## Platform notes

* **WhatsApp Status on iOS.** WhatsApp has no public entry point for Status on iOS. The plugin opens a share menu for the image, where the user picks WhatsApp and then **My Status**. The future completes once the menu is shown. On Android, WhatsApp opens straight to the status composer.
* **Instagram Direct on iOS.** Instagram may open without the text filled in, so the text is also copied to the clipboard for the user to paste.
* **Story images.** Use a 9:16 background, ideally 1080×1920, and a PNG sticker to keep its transparency.

## License

MIT. See [LICENSE](LICENSE).
