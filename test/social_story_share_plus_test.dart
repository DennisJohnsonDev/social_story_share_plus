import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';
import 'package:social_story_share_plus/social_story_share_plus_method_channel.dart';
import 'package:social_story_share_plus/social_story_share_plus_platform_interface.dart';

class FakeSocialStorySharePlusPlatform extends SocialStorySharePlusPlatform with MockPlatformInterfaceMixin {
  final calls = <String>[];

  @override
  Future<bool> shareToInstagramStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) async {
    calls.add('instagramStories:$appId:$stickerPath');
    return true;
  }

  @override
  Future<bool> shareToFacebookStories({
    required String appId,
    String? stickerPath,
    String? backgroundImagePath,
    Color? backgroundTopColor,
    Color? backgroundBottomColor,
  }) async {
    calls.add('facebookStories:$appId:$backgroundImagePath');
    return true;
  }

  @override
  Future<bool> shareToInstagramDirect({required String text}) async {
    calls.add('instagramDirect:$text');
    return true;
  }

  @override
  Future<bool> shareToWhatsAppStatus({required String imagePath}) async {
    calls.add('whatsAppStatus:$imagePath');
    return true;
  }

  @override
  Future<bool> saveToGallery({required Uint8List imageBytes, String? fileName, String? albumName}) async {
    calls.add('saveToGallery:${imageBytes.length}:$fileName:$albumName');
    return true;
  }

  @override
  Future<bool> isInstagramInstalled() async => true;

  @override
  Future<bool> isFacebookInstalled() async => false;

  @override
  Future<bool> isWhatsAppInstalled() async => true;
}

void main() {
  final initialPlatform = SocialStorySharePlusPlatform.instance;
  late FakeSocialStorySharePlusPlatform fakePlatform;

  setUp(() {
    fakePlatform = FakeSocialStorySharePlusPlatform();
    SocialStorySharePlusPlatform.instance = fakePlatform;
  });

  test('$MethodChannelSocialStorySharePlus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSocialStorySharePlus>());
  });

  test('delegates every call to the platform', () async {
    await SocialStorySharePlus.shareToInstagramStories(appId: '1', stickerPath: '/s.png');
    await SocialStorySharePlus.shareToFacebookStories(appId: '2', backgroundImagePath: '/b.png');
    await SocialStorySharePlus.shareToInstagramDirect(text: 'hello');
    await SocialStorySharePlus.shareToWhatsAppStatus(imagePath: '/w.png');
    await SocialStorySharePlus.saveToGallery(imageBytes: Uint8List(4), fileName: 'f', albumName: 'a');

    expect(fakePlatform.calls, [
      'instagramStories:1:/s.png',
      'facebookStories:2:/b.png',
      'instagramDirect:hello',
      'whatsAppStatus:/w.png',
      'saveToGallery:4:f:a',
    ]);
    expect(await SocialStorySharePlus.isInstagramInstalled(), isTrue);
    expect(await SocialStorySharePlus.isFacebookInstalled(), isFalse);
    expect(await SocialStorySharePlus.isWhatsAppInstalled(), isTrue);
  });

  test('stories need an app id', () {
    expect(() => SocialStorySharePlus.shareToInstagramStories(appId: ' ', stickerPath: '/s.png'), throwsArgumentError);
    expect(() => SocialStorySharePlus.shareToFacebookStories(appId: '', stickerPath: '/s.png'), throwsArgumentError);
  });

  test('stories need a sticker or a background', () {
    expect(() => SocialStorySharePlus.shareToInstagramStories(appId: '1'), throwsArgumentError);
    expect(() => SocialStorySharePlus.shareToFacebookStories(appId: '1'), throwsArgumentError);
  });

  test('rejects empty text, paths and bytes', () {
    expect(() => SocialStorySharePlus.shareToInstagramDirect(text: '  '), throwsArgumentError);
    expect(() => SocialStorySharePlus.shareToWhatsAppStatus(imagePath: ''), throwsArgumentError);
    expect(() => SocialStorySharePlus.saveToGallery(imageBytes: Uint8List(0)), throwsArgumentError);
    expect(fakePlatform.calls, isEmpty);
  });
}
