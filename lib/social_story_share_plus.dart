import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// A Flutter plugin for sharing images and stickers to Instagram Stories,
/// Instagram Direct, Facebook Stories, WhatsApp Status, and the device gallery.
class SocialStorySharePlus {
  static const MethodChannel _channel = MethodChannel('social_story_share_plus');

  /// Shares a sticker image to Instagram Stories.
  ///
  /// [stickerPath] is the local file path to the sticker image (required).
  /// [backgroundImagePath] is an optional background image. If omitted,
  /// [backgroundTopColor] and [backgroundBottomColor] (hex strings like
  /// `"#RRGGBB"`) are used as a gradient background.
  ///
  /// Returns `true` if Instagram was opened successfully.
  static Future<bool> shareToInstagramStories({
    required String stickerPath,
    String? backgroundImagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'shareToInstagramStories',
        {
          'stickerPath': stickerPath,
          'backgroundImagePath': backgroundImagePath,
          'backgroundTopColor': backgroundTopColor,
          'backgroundBottomColor': backgroundBottomColor,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Shares [text] to Instagram Direct.
  ///
  /// On iOS, falls back to copying [text] to the clipboard and opening
  /// Instagram if the direct-share URL scheme is unsupported.
  static Future<bool> shareToInstagramDirect({required String text}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'shareToInstagramDirect',
        {'text': text},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Shares a sticker image to Facebook Stories.
  ///
  /// [appId] is your Facebook App ID and is **required** — without it,
  /// Facebook will reject the share. Register your app at
  /// https://developers.facebook.com/ to obtain one.
  ///
  /// [stickerPath] is the local file path to the sticker image (required).
  /// [backgroundImagePath] is optional; if omitted, [backgroundTopColor] and
  /// [backgroundBottomColor] (hex `"#RRGGBB"`) provide a gradient background.
  static Future<bool> shareToFacebookStories({
    required String stickerPath,
    required String appId,
    String? backgroundImagePath,
    String? backgroundTopColor,
    String? backgroundBottomColor,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'shareToFacebookStories',
        {
          'stickerPath': stickerPath,
          'appId': appId,
          'backgroundImagePath': backgroundImagePath,
          'backgroundTopColor': backgroundTopColor,
          'backgroundBottomColor': backgroundBottomColor,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Shares an image at [imagePath] to WhatsApp Status.
  static Future<bool> shareToWhatsAppStatus({required String imagePath}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'shareToWhatsAppStatus',
        {'imagePath': imagePath},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Saves [imageBytes] to the device gallery under [fileName].
  ///
  /// On iOS, requires `NSPhotoLibraryAddUsageDescription` in `Info.plist`.
  /// On Android API < 29, requires `WRITE_EXTERNAL_STORAGE` permission.
  static Future<bool> saveToGallery({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'saveToGallery',
        {'imageBytes': imageBytes, 'fileName': fileName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns `true` if the Instagram app is installed.
  static Future<bool> isInstagramInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isInstagramInstalled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns `true` if the Facebook app is installed.
  static Future<bool> isFacebookInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isFacebookInstalled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns `true` if the WhatsApp app is installed.
  static Future<bool> isWhatsAppInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isWhatsAppInstalled') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
