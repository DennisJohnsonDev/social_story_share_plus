import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'social_story_share_plus_method_channel.dart';

/// The interface that implementations of social_story_share_plus must extend.
///
/// Extend this class rather than implementing it, so that new methods added
/// here do not break existing implementations.
abstract class SocialStorySharePlusPlatform extends PlatformInterface {
  /// Constructs a [SocialStorySharePlusPlatform].
  SocialStorySharePlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static SocialStorySharePlusPlatform _instance = MethodChannelSocialStorySharePlus();

  /// The default instance of [SocialStorySharePlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelSocialStorySharePlus].
  static SocialStorySharePlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SocialStorySharePlusPlatform] when
  /// they register themselves.
  static set instance(SocialStorySharePlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Opens the Instagram story composer.
  Future<bool> shareToInstagramStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) {
    throw UnimplementedError('shareToInstagramStories() has not been implemented.');
  }

  /// Opens the Facebook story composer.
  Future<bool> shareToFacebookStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) {
    throw UnimplementedError('shareToFacebookStories() has not been implemented.');
  }

  /// Opens Instagram with [text] ready to send as a direct message.
  Future<bool> shareToInstagramDirect({required String text}) {
    throw UnimplementedError('shareToInstagramDirect() has not been implemented.');
  }

  /// Shares the image at [imagePath] to WhatsApp Status.
  Future<bool> shareToWhatsAppStatus({required String imagePath}) {
    throw UnimplementedError('shareToWhatsAppStatus() has not been implemented.');
  }

  /// Saves [imageBytes] to the device photo gallery.
  Future<bool> saveToGallery({required Uint8List imageBytes, String? fileName, String? albumName}) {
    throw UnimplementedError('saveToGallery() has not been implemented.');
  }

  /// Whether Instagram is installed.
  Future<bool> isInstagramInstalled() {
    throw UnimplementedError('isInstagramInstalled() has not been implemented.');
  }

  /// Whether Facebook is installed.
  Future<bool> isFacebookInstalled() {
    throw UnimplementedError('isFacebookInstalled() has not been implemented.');
  }

  /// Whether WhatsApp is installed.
  Future<bool> isWhatsAppInstalled() {
    throw UnimplementedError('isWhatsAppInstalled() has not been implemented.');
  }
}
