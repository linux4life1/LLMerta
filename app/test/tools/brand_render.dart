// Brand renderer — run by hand, never in CI:
//   flutter test tool_test/brand_render_test.dart
// Regenerates the app icon (macOS iconset, Windows .ico, Linux png) and the
// DMG background from one vector definition, with the bundled fonts loaded
// so text renders in Limelight/Libre Franklin instead of Ahem boxes.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _honey = Color(0xFFE9C46A);
const _bone = Color(0xFFEFE6D2);
const _boneDim = Color(0xFFC2B295);

Future<void> _loadFont(String family, String assetFile) async {
  final bytes = File('assets/fonts/$assetFile').readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

/// Icon A, "The Marquee": Limelight L under a honey ring on espresso,
/// one ivory seat at the bottom of the ring. 1024-unit canvas.
ui.Picture _drawIcon() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const body = Rect.fromLTWH(100, 100, 824, 824);
  final squircle = RRect.fromRectAndRadius(body, const Radius.circular(185));

  canvas.drawRRect(
    squircle,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, 0.55, 1],
        colors: [Color(0xFF33271A), Color(0xFF1E1813), Color(0xFF171310)],
      ).createShader(body),
  );
  canvas
    ..save()
    ..clipRRect(squircle)
    ..drawRect(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.78),
          radius: 0.85,
          colors: [_honey.withValues(alpha: 0.26), Colors.transparent],
        ).createShader(body),
    )
    ..restore()
    ..drawRRect(
      squircle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF4A3B28),
    )
    ..drawCircle(
      const Offset(512, 512),
      296,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = _honey.withValues(alpha: 0.55),
    )
    ..drawCircle(
      const Offset(512, 512),
      268,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = _honey.withValues(alpha: 0.22),
    );

  final l = TextPainter(
    text: const TextSpan(
      text: 'L',
      style: TextStyle(fontFamily: 'Limelight', fontSize: 400, color: _honey),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  l.paint(canvas, Offset(512 - l.width / 2, 512 - l.height / 2 - 8));

  canvas.drawCircle(const Offset(512, 808), 26, Paint()..color = _bone);
  return recorder.endRecording();
}

Future<Uint8List> _rasterizeIcon(ui.Picture icon, int size) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..scale(size / 1024)
    ..drawPicture(icon);
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// Minimal ICO container: PNG-compressed entries (Vista+).
Uint8List _buildIco(Map<int, Uint8List> pngBySize) {
  final sizes = pngBySize.keys.toList()..sort();
  final header = BytesBuilder()
    ..add([0, 0, 1, 0, sizes.length & 0xFF, sizes.length >> 8]);
  var offset = 6 + 16 * sizes.length;
  final blobs = BytesBuilder();
  for (final size in sizes) {
    final png = pngBySize[size]!;
    final dim = size >= 256 ? 0 : size;
    header.add([
      dim, dim, 0, 0, 1, 0, 32, 0, //
      png.length & 0xFF, (png.length >> 8) & 0xFF,
      (png.length >> 16) & 0xFF, (png.length >> 24) & 0xFF,
      offset & 0xFF, (offset >> 8) & 0xFF,
      (offset >> 16) & 0xFF, (offset >> 24) & 0xFF,
    ]);
    blobs.add(png);
    offset += png.length;
  }
  header.add(blobs.takeBytes());
  return header.takeBytes();
}

/// 660×420 window at 2× (1320×840). Icon slots at 165,220 and 495,220 are
/// left empty — create-dmg places the live icons there.
Future<Uint8List> _drawDmgBackground() async {
  const w = 1320.0, h = 840.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const rect = Rect.fromLTWH(0, 0, w, h);
  canvas
    ..drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1813), Color(0xFF171310)],
        ).createShader(rect),
    )
    ..drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.35),
          radius: 1.0,
          colors: [_honey.withValues(alpha: 0.14), Colors.transparent],
        ).createShader(rect),
    )
    ..drawCircle(
      const Offset(w / 2, 1120),
      660,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _honey.withValues(alpha: 0.10),
    )
    ..drawCircle(
      const Offset(w / 2, 1120),
      736,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _honey.withValues(alpha: 0.06),
    );

  void text(
    String value, {
    required double y,
    required TextStyle style,
    double letterSpacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: value,
        style: style.copyWith(letterSpacing: letterSpacing),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, y));
  }

  text(
    'LLMerta',
    y: 64,
    style: TextStyle(
      fontFamily: 'Limelight',
      fontSize: 92,
      color: _honey,
      shadows: [
        const Shadow(offset: Offset(0, 3), color: Colors.black87),
        Shadow(blurRadius: 60, color: _honey.withValues(alpha: 0.35)),
      ],
    ),
    letterSpacing: 4,
  );
  text(
    'SEVEN TO FOURTEEN SEATS  ·  ONE OF THEM IS HUMAN',
    y: 196,
    style: const TextStyle(
      fontFamily: 'LibreFranklin',
      fontSize: 23,
      color: _boneDim,
    ),
    letterSpacing: 5,
  );

  // Dashed arrow between the two icon wells (icons at 165,220 and 495,220
  // logical; 110pt icons → arrow spans x≈460..860 at y≈550 in 2× pixels).
  final dash = Paint()
    ..color = _honey.withValues(alpha: 0.85)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  for (var x = 480.0; x < 800; x += 26) {
    canvas.drawLine(Offset(x, 550), Offset(x + 3, 550), dash);
  }
  final arrowHead = Path()
    ..moveTo(812, 526)
    ..lineTo(856, 550)
    ..lineTo(812, 574)
    ..close();
  canvas.drawPath(arrowHead, Paint()..color = _honey.withValues(alpha: 0.9));

  text(
    'DRAG TO INSTALL',
    y: 774,
    style: const TextStyle(
      fontFamily: 'LibreFranklin',
      fontSize: 21,
      color: _boneDim,
    ),
    letterSpacing: 6,
  );

  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets('render brand assets', (tester) async {
    await tester.runAsync(() async {
      await _loadFont('Limelight', 'Limelight-Regular.ttf');
      await _loadFont('LibreFranklin', 'LibreFranklin.ttf');

      final icon = _drawIcon();
      final png = <int, Uint8List>{};
      for (final size in [16, 24, 32, 48, 64, 128, 256, 512, 1024]) {
        png[size] = await _rasterizeIcon(icon, size);
      }

      final iconset = Directory(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset',
      );
      for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
        File('${iconset.path}/app_icon_$size.png').writeAsBytesSync(png[size]!);
      }

      File('windows/runner/resources/app_icon.ico').writeAsBytesSync(
        _buildIco({
          for (final s in [16, 24, 32, 48, 64, 128, 256]) s: png[s]!,
        }),
      );

      File('../packaging/linux/llmerta.png').writeAsBytesSync(png[256]!);

      File(
        '../packaging/macos/dmg-background.png',
      ).writeAsBytesSync(await _drawDmgBackground());
    });
  });
}
