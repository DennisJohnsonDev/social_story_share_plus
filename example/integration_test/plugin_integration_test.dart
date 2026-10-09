import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('installed checks answer without throwing', (WidgetTester tester) async {
    expect(await SocialStorySharePlus.isInstagramInstalled(), isA<bool>());
    expect(await SocialStorySharePlus.isFacebookInstalled(), isA<bool>());
    expect(await SocialStorySharePlus.isWhatsAppInstalled(), isA<bool>());
  });

  testWidgets('a missing file is reported as fileNotFound', (WidgetTester tester) async {
    if (!await SocialStorySharePlus.isWhatsAppInstalled()) return;

    await expectLater(
      SocialStorySharePlus.shareToWhatsAppStatus(imagePath: '/does/not/exist.png'),
      throwsA(isA<SocialStoryShareException>().having((e) => e.code, 'code', SocialStoryShareErrorCode.fileNotFound)),
    );
  });
}
