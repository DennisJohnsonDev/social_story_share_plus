// Basic integration test for social_story_share_plus.
//
// Run from the example/ directory:
//   flutter test integration_test
//
// For more on Flutter integration tests, see:
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isInstalled checks return a bool from the host', (tester) async {
    // The actual value depends on whether the apps are installed on the host
    // device or simulator. We just verify the channel round-trips a bool.
    final ig = await SocialStorySharePlus.isInstagramInstalled();
    final fb = await SocialStorySharePlus.isFacebookInstalled();
    final wa = await SocialStorySharePlus.isWhatsAppInstalled();
    expect(ig, isA<bool>());
    expect(fb, isA<bool>());
    expect(wa, isA<bool>());
  });
}
