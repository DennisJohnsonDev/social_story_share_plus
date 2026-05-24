import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_story_share_plus/social_story_share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'social_story_share_plus demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  bool _instagramInstalled = false;
  bool _facebookInstalled = false;
  bool _whatsappInstalled = false;

  String? _sampleImagePath;

  final _directTextController = TextEditingController(text: 'Hello from Flutter!');
  final _fbAppIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshInstalledStatus();
  }

  @override
  void dispose() {
    _directTextController.dispose();
    _fbAppIdController.dispose();
    super.dispose();
  }

  Future<void> _refreshInstalledStatus() async {
    final ig = await SocialStorySharePlus.isInstagramInstalled();
    final fb = await SocialStorySharePlus.isFacebookInstalled();
    final wa = await SocialStorySharePlus.isWhatsAppInstalled();
    if (!mounted) return;
    setState(() {
      _instagramInstalled = ig;
      _facebookInstalled = fb;
      _whatsappInstalled = wa;
    });
  }

  /// Renders a sample 1080x1920 sticker to a temp file. Real apps would use
  /// their own image — this just provides something to share without bundling
  /// an asset.
  Future<String> _ensureSampleImage() async {
    if (_sampleImagePath != null && File(_sampleImagePath!).existsSync()) {
      return _sampleImagePath!;
    }
    final bytes = await _renderSampleImage();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sample_sticker.png');
    await file.writeAsBytes(bytes);
    _sampleImagePath = file.path;
    return file.path;
  }

  Future<Uint8List> _renderSampleImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1080, 1920);

    final gradient = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      [const Color(0xFF7B61FF), const Color(0xFFFF61D2)],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'social_story_share_plus',
        style: TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 80);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _showResult(String label, bool ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label → ${ok ? "success" : "failed"}')),
    );
  }

  Future<void> _shareInstagramStories() async {
    final path = await _ensureSampleImage();
    final ok = await SocialStorySharePlus.shareToInstagramStories(
      stickerPath: path,
      backgroundTopColor: '#7B61FF',
      backgroundBottomColor: '#FF61D2',
    );
    _showResult('Instagram Stories', ok);
  }

  Future<void> _shareInstagramDirect() async {
    final ok = await SocialStorySharePlus.shareToInstagramDirect(
      text: _directTextController.text,
    );
    _showResult('Instagram Direct', ok);
  }

  Future<void> _shareFacebookStories() async {
    final appId = _fbAppIdController.text.trim();
    if (appId.isEmpty) {
      _showResult('Facebook Stories (missing appId)', false);
      return;
    }
    final path = await _ensureSampleImage();
    final ok = await SocialStorySharePlus.shareToFacebookStories(
      stickerPath: path,
      appId: appId,
      backgroundTopColor: '#7B61FF',
      backgroundBottomColor: '#FF61D2',
    );
    _showResult('Facebook Stories', ok);
  }

  Future<void> _shareWhatsApp() async {
    final path = await _ensureSampleImage();
    final ok = await SocialStorySharePlus.shareToWhatsAppStatus(imagePath: path);
    _showResult('WhatsApp Status', ok);
  }

  Future<void> _saveToGallery() async {
    final bytes = await _renderSampleImage();
    final ok = await SocialStorySharePlus.saveToGallery(
      imageBytes: bytes,
      fileName: 'sample_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    _showResult('Save to gallery', ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('social_story_share_plus'),
        actions: [
          IconButton(
            tooltip: 'Refresh installed apps',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInstalledStatus,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InstalledRow(
            instagram: _instagramInstalled,
            facebook: _facebookInstalled,
            whatsapp: _whatsappInstalled,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Share to Instagram Stories'),
            onPressed: _shareInstagramStories,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _directTextController,
            decoration: const InputDecoration(
              labelText: 'Instagram Direct message',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: const Text('Share to Instagram Direct'),
            onPressed: _shareInstagramDirect,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fbAppIdController,
            decoration: const InputDecoration(
              labelText: 'Facebook App ID (required for FB Stories)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.facebook_outlined),
            label: const Text('Share to Facebook Stories'),
            onPressed: _shareFacebookStories,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Share to WhatsApp Status'),
            onPressed: _shareWhatsApp,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.save_alt),
            label: const Text('Save sample to gallery'),
            onPressed: _saveToGallery,
          ),
        ],
      ),
    );
  }
}

class _InstalledRow extends StatelessWidget {
  const _InstalledRow({
    required this.instagram,
    required this.facebook,
    required this.whatsapp,
  });

  final bool instagram;
  final bool facebook;
  final bool whatsapp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _badge('Instagram', instagram),
        _badge('Facebook', facebook),
        _badge('WhatsApp', whatsapp),
      ],
    );
  }

  Widget _badge(String name, bool installed) {
    return Chip(
      avatar: Icon(
        installed ? Icons.check_circle : Icons.cancel,
        color: installed ? Colors.green : Colors.red,
        size: 18,
      ),
      label: Text(name),
    );
  }
}
