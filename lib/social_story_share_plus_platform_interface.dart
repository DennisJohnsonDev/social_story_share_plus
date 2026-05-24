import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'social_story_share_plus_method_channel.dart';

abstract class SocialStorySharePlusPlatform extends PlatformInterface {
  /// Constructs a SocialStorySharePlusPlatform.
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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
