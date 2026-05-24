import 'package:flutter_test/flutter_test.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';
import 'package:social_story_share_plus/social_story_share_plus_platform_interface.dart';
import 'package:social_story_share_plus/social_story_share_plus_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSocialStorySharePlusPlatform
    with MockPlatformInterfaceMixin
    implements SocialStorySharePlusPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SocialStorySharePlusPlatform initialPlatform = SocialStorySharePlusPlatform.instance;

  test('$MethodChannelSocialStorySharePlus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSocialStorySharePlus>());
  });

  test('getPlatformVersion', () async {
    SocialStorySharePlus socialStorySharePlusPlugin = SocialStorySharePlus();
    MockSocialStorySharePlusPlatform fakePlatform = MockSocialStorySharePlusPlatform();
    SocialStorySharePlusPlatform.instance = fakePlatform;

    expect(await socialStorySharePlusPlugin.getPlatformVersion(), '42');
  });
}
