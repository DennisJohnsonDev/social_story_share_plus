import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'social_story_share_plus_platform_interface.dart';
import 'src/social_story_share_exception.dart';

/// An implementation of [SocialStorySharePlusPlatform] that uses method channels.
class MethodChannelSocialStorySharePlus extends SocialStorySharePlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('social_story_share_plus');

  static const _errorCodes = {
    'APP_NOT_INSTALLED': SocialStoryShareErrorCode.appNotInstalled,
    'FILE_NOT_FOUND': SocialStoryShareErrorCode.fileNotFound,
    'INVALID_IMAGE': SocialStoryShareErrorCode.invalidImage,
    'INVALID_ARGUMENT': SocialStoryShareErrorCode.invalidArgument,
    'UI_UNAVAILABLE': SocialStoryShareErrorCode.uiUnavailable,
    'PERMISSION_DENIED': SocialStoryShareErrorCode.permissionDenied,
  };

  @override
  Future<bool> shareToInstagramStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) {
    return _invoke('shareToInstagramStories',
        _storyArguments(appId, stickerPath, backgroundImagePath, backgroundTopColor, backgroundBottomColor));
  }

  @override
  Future<bool> shareToFacebookStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) {
    return _invoke('shareToFacebookStories',
        _storyArguments(appId, stickerPath, backgroundImagePath, backgroundTopColor, backgroundBottomColor));
  }

  @override
  Future<bool> shareToInstagramDirect({required String text}) {
    return _invoke('shareToInstagramDirect', {'text': text});
  }

  @override
  Future<bool> shareToWhatsAppStatus({required String imagePath}) {
    return _invoke('shareToWhatsAppStatus', {'imagePath': imagePath});
  }

  @override
  Future<bool> saveToGallery({required Uint8List imageBytes, String? fileName, String? albumName}) {
    return _invoke('saveToGallery', {
      'imageBytes': imageBytes,
      if (fileName != null) 'fileName': fileName,
      if (albumName != null) 'albumName': albumName,
    });
  }

  @override
  Future<bool> isInstagramInstalled() => _invoke('isInstagramInstalled');

  @override
  Future<bool> isFacebookInstalled() => _invoke('isFacebookInstalled');

  @override
  Future<bool> isWhatsAppInstalled() => _invoke('isWhatsAppInstalled');

  Map<String, Object> _storyArguments(
      String appId, String? stickerPath, String? backgroundImagePath, Color? topColor, Color? bottomColor) {
    return {
      'appId': appId,
      if (stickerPath != null) 'stickerPath': stickerPath,
      if (backgroundImagePath != null) 'backgroundImagePath': backgroundImagePath,
      if (topColor != null) 'backgroundTopColor': _hex(topColor),
      if (bottomColor != null) 'backgroundBottomColor': _hex(bottomColor),
    };
  }

  // Instagram and Facebook only accept opaque #RRGGBB colours.
  String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<bool> _invoke(String method, [Map<String, Object>? arguments]) async {
    try {
      return await methodChannel.invokeMethod<bool>(method, arguments) ?? false;
    } on PlatformException catch (e) {
      throw SocialStoryShareException(_errorCodes[e.code] ?? SocialStoryShareErrorCode.failed, e.message);
    }
  }
}
