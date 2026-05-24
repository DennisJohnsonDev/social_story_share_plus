
import 'social_story_share_plus_platform_interface.dart';

class SocialStorySharePlus {
  Future<String?> getPlatformVersion() {
    return SocialStorySharePlusPlatform.instance.getPlatformVersion();
  }
}
