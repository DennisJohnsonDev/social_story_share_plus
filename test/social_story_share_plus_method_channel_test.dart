import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';
import 'package:social_story_share_plus/social_story_share_plus_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelSocialStorySharePlus();
  const channel = MethodChannel('social_story_share_plus');
  final calls = <MethodCall>[];
  Object? Function(MethodCall call) respond = (_) => true;

  setUp(() {
    calls.clear();
    respond = (_) => true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return respond(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('sends story arguments with colours as #RRGGBB and omits nulls', () async {
    final shared = await platform.shareToInstagramStories(
      appId: '123',
      stickerPath: '/tmp/sticker.png',
      backgroundTopColor: const Color(0x80FF8800),
      backgroundBottomColor: Colors.black,
    );

    expect(shared, isTrue);
    expect(calls.single.method, 'shareToInstagramStories');
    expect(calls.single.arguments, {
      'appId': '123',
      'stickerPath': '/tmp/sticker.png',
      'backgroundTopColor': '#FF8800',
      'backgroundBottomColor': '#000000',
    });
  });

  test('sends facebook stories to its own method', () async {
    await platform.shareToFacebookStories(appId: '123', backgroundImagePath: '/tmp/bg.png');

    expect(calls.single.method, 'shareToFacebookStories');
    expect(calls.single.arguments, {'appId': '123', 'backgroundImagePath': '/tmp/bg.png'});
  });

  test('sends gallery bytes and optional names', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    await platform.saveToGallery(imageBytes: bytes, fileName: 'poster.png');

    expect(calls.single.method, 'saveToGallery');
    expect(calls.single.arguments, {'imageBytes': bytes, 'fileName': 'poster.png'});
  });

  test('treats a null reply as false', () async {
    respond = (_) => null;

    expect(await platform.isWhatsAppInstalled(), isFalse);
  });

  test('maps platform error codes to SocialStoryShareException', () async {
    respond = (_) => throw PlatformException(code: 'APP_NOT_INSTALLED', message: 'WhatsApp is not installed');

    await expectLater(
      platform.shareToWhatsAppStatus(imagePath: '/tmp/poster.png'),
      throwsA(isA<SocialStoryShareException>()
          .having((e) => e.code, 'code', SocialStoryShareErrorCode.appNotInstalled)
          .having((e) => e.message, 'message', 'WhatsApp is not installed')),
    );
  });

  test('maps unknown platform error codes to failed', () async {
    respond = (_) => throw PlatformException(code: 'SOMETHING_NEW');

    await expectLater(
      platform.shareToInstagramDirect(text: 'hi'),
      throwsA(isA<SocialStoryShareException>().having((e) => e.code, 'code', SocialStoryShareErrorCode.failed)),
    );
  });
}
