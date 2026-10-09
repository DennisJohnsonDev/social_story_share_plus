import 'dart:typed_data';
import 'dart:ui' show Color;

import 'social_story_share_plus_platform_interface.dart';
import 'src/social_story_share_exception.dart';

export 'src/social_story_share_exception.dart';

/// Shares images to Instagram Stories, Facebook Stories and WhatsApp Status,
/// sends text to Instagram Direct and saves images to the device gallery.
///
/// Share methods return `true` once the content has been handed to the target
/// app and `false` when that app could not be opened. Every other failure
/// throws a [SocialStoryShareException] describing what went wrong.
///
/// Image arguments are local file paths, for example a PNG written to the
/// directory returned by `getTemporaryDirectory()` from `path_provider`.
class SocialStorySharePlus {
  SocialStorySharePlus._();

  static SocialStorySharePlusPlatform get _platform => SocialStorySharePlusPlatform.instance;

  /// Opens the Instagram story composer.
  ///
  /// [appId] is your Facebook App ID, which Meta requires to attribute the
  /// share. [stickerPath] is placed as a movable sticker and
  /// [backgroundImagePath] fills the whole story; at least one of them is
  /// required. Without a background image, the story is filled with a
  /// vertical gradient from [backgroundTopColor] to [backgroundBottomColor].
  ///
  /// Throws [SocialStoryShareException] with
  /// [SocialStoryShareErrorCode.appNotInstalled] when Instagram is missing.
  static Future<bool> shareToInstagramStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) {
    _checkStoryArguments(appId, stickerPath, backgroundImagePath);
    return _platform.shareToInstagramStories(
      appId: appId,
      stickerPath: stickerPath,
      backgroundImagePath: backgroundImagePath,
      backgroundTopColor: backgroundTopColor,
      backgroundBottomColor: backgroundBottomColor,
    );
  }

  /// Opens the Facebook story composer.
  ///
  /// Takes the same arguments as [shareToInstagramStories]. [appId] is your
  /// Facebook App ID and is required by Facebook.
  ///
  /// Throws [SocialStoryShareException] with
  /// [SocialStoryShareErrorCode.appNotInstalled] when Facebook is missing.
  static Future<bool> shareToFacebookStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) {
    _checkStoryArguments(appId, stickerPath, backgroundImagePath);
    return _platform.shareToFacebookStories(
      appId: appId,
      stickerPath: stickerPath,
      backgroundImagePath: backgroundImagePath,
      backgroundTopColor: backgroundTopColor,
      backgroundBottomColor: backgroundBottomColor,
    );
  }

  /// Opens Instagram with [text] ready to send as a direct message.
  ///
  /// On Android, Instagram's share screen opens with the text filled in.
  /// On iOS, Instagram may not prefill the text, so it is also copied to the
  /// clipboard for the user to paste.
  static Future<bool> shareToInstagramDirect({required String text}) {
    if (text.trim().isEmpty) throw ArgumentError.value(text, 'text', 'must not be empty');
    return _platform.shareToInstagramDirect(text: text);
  }

  /// Shares the image at [imagePath] to WhatsApp Status.
  ///
  /// On Android, WhatsApp opens straight to the status composer. On iOS,
  /// WhatsApp has no direct status entry point, so a share menu opens where
  /// the user picks WhatsApp and then "My Status". On iOS the future
  /// completes once that menu is shown.
  static Future<bool> shareToWhatsAppStatus({required String imagePath}) {
    if (imagePath.isEmpty) throw ArgumentError.value(imagePath, 'imagePath', 'must not be empty');
    return _platform.shareToWhatsAppStatus(imagePath: imagePath);
  }

  /// Saves [imageBytes] to the device photo gallery.
  ///
  /// The bytes must be an encoded image such as PNG or JPEG, and are stored
  /// as-is. [fileName] is used without its extension, which is set from the
  /// image format. [albumName] puts the image in its own folder under
  /// Pictures and is used on Android only.
  ///
  /// Asks for permission when needed and throws [SocialStoryShareException]
  /// with [SocialStoryShareErrorCode.permissionDenied] if it is refused.
  static Future<bool> saveToGallery({required Uint8List imageBytes, String? fileName, String? albumName}) {
    if (imageBytes.isEmpty) throw ArgumentError.value(imageBytes, 'imageBytes', 'must not be empty');
    return _platform.saveToGallery(imageBytes: imageBytes, fileName: fileName, albumName: albumName);
  }

  /// Whether Instagram is installed.
  static Future<bool> isInstagramInstalled() => _platform.isInstagramInstalled();

  /// Whether Facebook is installed.
  static Future<bool> isFacebookInstalled() => _platform.isFacebookInstalled();

  /// Whether WhatsApp is installed.
  static Future<bool> isWhatsAppInstalled() => _platform.isWhatsAppInstalled();

  static void _checkStoryArguments(String appId, String? stickerPath, String? backgroundImagePath) {
    if (appId.trim().isEmpty) throw ArgumentError.value(appId, 'appId', 'must be your Facebook App ID');
    if (stickerPath == null && backgroundImagePath == null) {
      throw ArgumentError('Provide a stickerPath, a backgroundImagePath, or both.');
    }
  }
}
