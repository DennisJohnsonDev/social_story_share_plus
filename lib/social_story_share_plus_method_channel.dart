import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'social_story_share_plus_platform_interface.dart';

/// An implementation of [SocialStorySharePlusPlatform] that uses method channels.
class MethodChannelSocialStorySharePlus extends SocialStorySharePlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('social_story_share_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
