import 'dart:async';

import 'package:persistence/persistence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tts/tts.dart';

import '../services/services.dart';
import 'game_session.dart';
import 'paced_controller.dart';
import 'session_state.dart';
import 'ui_human_controller.dart';

part 'session_providers.g.dart';

/// Seam: tests zero the reading floor so stub games finish instantly.
@Riverpod(keepAlive: true)
TablePacer Function() tablePacerFactory(Ref ref) =>
    () => TablePacer(holdFor: (text) => speechHold(ref, text));

/// How long a speech holds the table. Voices on: until the TTS queue
/// reports that exact line spoken (or failed), capped so a skipped line
/// can never deadlock a game. Voices off: reading time.
Future<void> speechHold(Ref ref, String text) {
  final reading = TablePacer.defaultReadingTime(text);
  try {
    final stack = ref.read(ttsStackProvider);
    if (stack == null || !ref.read(ttsEnabledProvider)) {
      return Future<void>.delayed(reading);
    }
    final spoken = stack.queue.events
        .firstWhere(
          (e) =>
              (e is SpeakingEnded && e.text == text) ||
              (e is SpeechFailed && e.text == text),
          orElse: QueueDrained.new,
        )
        .then((_) {});
    return Future.any([
      spoken,
      Future<void>.delayed(reading + const Duration(seconds: 90)),
    ]);
  } on Exception {
    return Future<void>.delayed(reading);
  }
}

@riverpod
GameStage sessionStage(Ref ref) =>
    ref.watch(gameSessionControllerProvider).stage;

@riverpod
Stream<List<Game>> savedGames(Ref ref) =>
    ref.watch(appDatabaseProvider).watchGames();

@riverpod
Stream<HumanRequest?> humanRequest(Ref ref) {
  // Re-grab the stream whenever a new game (new controller) starts.
  ref.watch(sessionStageProvider);
  final controller = ref
      .watch(gameSessionControllerProvider.notifier)
      .humanController;
  if (controller == null) return Stream.value(null);
  return () async* {
    yield controller.current;
    yield* controller.requests;
  }();
}
