import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/lobby/lobby.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:tts/tts.dart';

import '../support.dart';

class _FakeEngine implements TtsEngine {
  final spoken = <(String, String)>[];

  @override
  Future<TtsAudio> synthesize(
    String text,
    Voice voice, {
    double speed = 1.0,
  }) async {
    spoken.add((text, voice.label));
    return TtsAudio(
      wavBytes: Uint8List.fromList(text.codeUnits),
      sampleRate: 22050,
      duration: Duration.zero,
    );
  }
}

class _SilentPlayer implements WavPlayer {
  @override
  Future<void> play(Uint8List wavBytes) async {}

  @override
  void stop() {}
}

/// runWithDb's runAsync/unmount pattern, minus the db: settle() uses
/// real delays, which never fire outside runAsync (support.dart trap).
Future<void> runReal(WidgetTester tester, Future<void> Function() body) async {
  await tester.runAsync(() async {
    try {
      await body();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

void main() {
  Future<ProviderContainer> pump(WidgetTester tester, {TtsStack? stack}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ttsStackProvider.overrideWith((_) => stack)],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: VoicePickerButton(seat: 2))),
        ),
      ),
    );
    await settle(tester);
    return ProviderScope.containerOf(
      tester.element(find.byType(VoicePickerButton)),
    );
  }

  TtsStack stackWith(_FakeEngine engine) {
    final queue = SpeechQueue(engine: engine, player: _SilentPlayer());
    addTearDown(queue.dispose);
    return TtsStack(
      queue: queue,
      voices: kokoroSpeakers(
        VoiceBundle(kind: VoiceBundleKind.kokoro, dir: Directory('/tmp/k')),
        count: 3,
      ),
    );
  }

  testWidgets('picking a voice by ear casts it onto the seat', (tester) async {
    await runReal(tester, () async {
      final engine = _FakeEngine();
      final c = await pump(tester, stack: stackWith(engine));

      await tester.tap(find.byType(VoicePickerButton));
      await settle(tester);
      expect(find.text('Auto — rotate with the table'), findsOneWidget);

      // Hear one first, then choose it.
      await tester.tap(find.byTooltip('Hear this voice').at(1));
      await settle(tester);
      expect(engine.spoken, hasLength(1));

      await tester.tap(find.text('Kokoro 4'));
      await settle(tester);
      expect(c.read(lobbySetupControllerProvider).seats[2].voice, 'kokoro#4');

      // Auto clears the choice again.
      await tester.tap(find.byType(VoicePickerButton));
      await settle(tester);
      await tester.tap(find.text('Auto — rotate with the table'));
      await settle(tester);
      expect(c.read(lobbySetupControllerProvider).seats[2].voice, isNull);
    });
  });

  testWidgets('without bundles the picker points at the download', (
    tester,
  ) async {
    await runReal(tester, () async {
      await pump(tester);
      await tester.tap(find.byType(VoicePickerButton));
      await settle(tester);
      expect(
        find.textContaining('No voice bundles downloaded yet'),
        findsOneWidget,
      );
    });
  });
}
