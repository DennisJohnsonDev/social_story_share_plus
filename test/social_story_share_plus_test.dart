import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('social_story_share_plus');
  final binding = TestDefaultBinaryMessengerBinding.instance;

  final calls = <MethodCall>[];

  void mockHandler(Object? response) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return response;
    });
  }

  setUp(() => calls.clear());

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  group('shareToInstagramStories', () {
    test('forwards arguments and returns native result', () async {
      mockHandler(true);
      final ok = await SocialStorySharePlus.shareToInstagramStories(
        stickerPath: '/tmp/s.png',
        backgroundTopColor: '#FF0000',
        backgroundBottomColor: '#00FF00',
      );
      expect(ok, isTrue);
      expect(calls.single.method, 'shareToInstagramStories');
      expect(calls.single.arguments['stickerPath'], '/tmp/s.png');
      expect(calls.single.arguments['backgroundTopColor'], '#FF0000');
    });

    test('returns false on PlatformException', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'BOOM');
      });
      final ok = await SocialStorySharePlus.shareToInstagramStories(stickerPath: '/x.png');
      expect(ok, isFalse);
    });
  });

  test('shareToInstagramDirect forwards text', () async {
    mockHandler(true);
    final ok = await SocialStorySharePlus.shareToInstagramDirect(text: 'hi');
    expect(ok, isTrue);
    expect(calls.single.method, 'shareToInstagramDirect');
    expect(calls.single.arguments, {'text': 'hi'});
  });

  test('shareToFacebookStories forwards appId', () async {
    mockHandler(true);
    final ok = await SocialStorySharePlus.shareToFacebookStories(
      stickerPath: '/s.png',
      appId: '123456',
    );
    expect(ok, isTrue);
    expect(calls.single.arguments['appId'], '123456');
  });

  test('shareToWhatsAppStatus forwards imagePath', () async {
    mockHandler(true);
    final ok = await SocialStorySharePlus.shareToWhatsAppStatus(imagePath: '/img.png');
    expect(ok, isTrue);
    expect(calls.single.arguments, {'imagePath': '/img.png'});
  });

  test('saveToGallery forwards bytes and filename', () async {
    mockHandler(true);
    final bytes = Uint8List.fromList([1, 2, 3]);
    final ok = await SocialStorySharePlus.saveToGallery(
      imageBytes: bytes,
      fileName: 'out.png',
    );
    expect(ok, isTrue);
    expect(calls.single.method, 'saveToGallery');
    expect(calls.single.arguments['imageBytes'], bytes);
    expect(calls.single.arguments['fileName'], 'out.png');
  });

  group('isInstalled checks', () {
    test('isInstagramInstalled returns native bool', () async {
      mockHandler(true);
      expect(await SocialStorySharePlus.isInstagramInstalled(), isTrue);
      expect(calls.single.method, 'isInstagramInstalled');
    });

    test('isFacebookInstalled returns native bool', () async {
      mockHandler(false);
      expect(await SocialStorySharePlus.isFacebookInstalled(), isFalse);
    });

    test('isWhatsAppInstalled returns native bool', () async {
      mockHandler(true);
      expect(await SocialStorySharePlus.isWhatsAppInstalled(), isTrue);
    });
  });
}
