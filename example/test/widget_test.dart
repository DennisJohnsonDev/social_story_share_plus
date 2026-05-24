// Basic widget test for the example app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_story_share_plus_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The example calls platform channels on startup to check installed apps.
  // Stub them so widget tests don't fail on missing platform plumbing.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('social_story_share_plus'),
      (_) async => false,
    );
  });

  testWidgets('Example app renders share buttons', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Share to Instagram Stories'), findsOneWidget);
    expect(find.text('Share to Facebook Stories'), findsOneWidget);
    expect(find.text('Share to WhatsApp Status'), findsOneWidget);
  });
}
