import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';

// Replace with your own Facebook App ID from developers.facebook.com.
const facebookAppId = 'YOUR_FACEBOOK_APP_ID';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Story Share Plus',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const SharePage(),
    );
  }
}

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  bool? _instagramInstalled;
  bool? _facebookInstalled;
  bool? _whatsAppInstalled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _checkInstalledApps();
  }

  Future<void> _checkInstalledApps() async {
    final results = await Future.wait([
      SocialStorySharePlus.isInstagramInstalled(),
      SocialStorySharePlus.isFacebookInstalled(),
      SocialStorySharePlus.isWhatsAppInstalled(),
    ]);
    if (!mounted) return;
    setState(() {
      _instagramInstalled = results[0];
      _facebookInstalled = results[1];
      _whatsAppInstalled = results[2];
    });
  }

  Future<void> _run(String label, Future<bool> Function() share) async {
    setState(() => _busy = true);
    String message;
    try {
      message = await share() ? '$label: done' : '$label: could not open the app';
    } on SocialStoryShareException catch (e) {
      message = '$label: ${e.code.name}${e.message == null ? '' : ' (${e.message})'}';
    } on ArgumentError catch (e) {
      message = '$label: ${e.message}';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _shareToInstagramStories() async {
    final sticker = await _writeImage('sticker.png', _paintSticker, const Size(600, 600));
    await _run(
      'Instagram Stories',
      () => SocialStorySharePlus.shareToInstagramStories(
        appId: facebookAppId,
        stickerPath: sticker,
        backgroundTopColor: Colors.deepPurple,
        backgroundBottomColor: Colors.orange,
      ),
    );
  }

  Future<void> _shareToFacebookStories() async {
    final sticker = await _writeImage('sticker.png', _paintSticker, const Size(600, 600));
    final background = await _writeImage('background.png', _paintBackground, const Size(1080, 1920));
    await _run(
      'Facebook Stories',
      () => SocialStorySharePlus.shareToFacebookStories(
          appId: facebookAppId, stickerPath: sticker, backgroundImagePath: background),
    );
  }

  Future<void> _shareToInstagramDirect() {
    return _run('Instagram Direct',
        () => SocialStorySharePlus.shareToInstagramDirect(text: 'Shared with social_story_share_plus'));
  }

  Future<void> _shareToWhatsAppStatus() async {
    final poster = await _writeImage('poster.png', _paintPoster, const Size(1080, 1920));
    await _run('WhatsApp Status', () => SocialStorySharePlus.shareToWhatsAppStatus(imagePath: poster));
  }

  Future<void> _saveToGallery() async {
    final bytes = await _renderPng(_paintPoster, const Size(1080, 1920));
    await _run(
      'Save to gallery',
      () => SocialStorySharePlus.saveToGallery(
          imageBytes: bytes, fileName: 'social_story_share_plus', albumName: 'Social Story Share Plus'),
    );
  }

  Future<String> _writeImage(String name, void Function(Canvas, Size) paint, Size size) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name');
    await file.writeAsBytes(await _renderPng(paint, size));
    return file.path;
  }

  Future<Uint8List> _renderPng(void Function(Canvas, Size) paint, Size size) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), size);
    final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  void _paintSticker(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(48));
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    _paintLabel(canvas, size, 'Hello\nStories', Colors.deepPurple);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.indigo, Colors.pink],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = gradient);
  }

  void _paintPoster(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintLabel(canvas, size, 'social_story_share_plus', Colors.white);
  }

  void _paintLabel(Canvas canvas, Size size, String text, Color color) {
    final painter = TextPainter(
      text:
          TextSpan(text: text, style: TextStyle(color: color, fontSize: size.width / 10, fontWeight: FontWeight.bold)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);
    painter.paint(canvas, Offset((size.width - painter.width) / 2, (size.height - painter.height) / 2));
    painter.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        appBar: AppBar(title: const Text('Social Story Share Plus')),
        body: AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (facebookAppId == 'YOUR_FACEBOOK_APP_ID')
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Set facebookAppId in example/lib/main.dart to try Instagram and Facebook Stories.'),
                ),
              _ShareTile(title: 'Instagram Stories', installed: _instagramInstalled, onTap: _shareToInstagramStories),
              _ShareTile(title: 'Facebook Stories', installed: _facebookInstalled, onTap: _shareToFacebookStories),
              _ShareTile(title: 'Instagram Direct', installed: _instagramInstalled, onTap: _shareToInstagramDirect),
              _ShareTile(title: 'WhatsApp Status', installed: _whatsAppInstalled, onTap: _shareToWhatsAppStatus),
              _ShareTile(title: 'Save to gallery', installed: true, onTap: _saveToGallery),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.title, required this.installed, required this.onTap});

  final String title;
  final bool? installed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(switch (installed) {
        null => 'Checking…',
        true => 'Available',
        false => 'App not installed',
      }),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
